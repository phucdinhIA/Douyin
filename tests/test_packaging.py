import importlib.util
import json
import contextlib
import io
import plistlib
import pathlib
import struct
import tempfile
import unittest
from unittest.mock import patch as mock_patch
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ipa_patch', ROOT/'scripts/ipa_patch.py')
patch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(patch)

def binary(encrypted=False, padding=True):
    segment = bytearray(152)
    struct.pack_into('<II', segment, 0, 0x19, 152)
    struct.pack_into('<I', segment, 64, 1)
    struct.pack_into('<Q', segment, 72+40, 4)
    struct.pack_into('<I', segment, 72+48, 512)
    crypt = struct.pack('<6I', 0x2c, 24, 512, 4, int(encrypted), 0)
    header = struct.pack('<8I',0xfeedfacf,0x100000c,0,2,2,len(segment)+len(crypt),0,0)
    data = bytearray(header+segment+crypt)
    data.extend(b'\0'*(512-len(data)))
    if not padding: data[208] = 0xff
    data.extend(b'CODE')
    return bytes(data)

class PackagingTests(unittest.TestCase):
    def test_runtime_guard_and_packager_target_the_same_original_build(self):
        source=(ROOT/'src/DouyinGuest.m').read_text(encoding='utf8')
        self.assertIn('objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqualToString:@"40.6.0"',source)
        self.assertIn('objectForInfoDictionaryKey:@"CFBundleVersion"] isEqualToString:@"406019"',source)
        self.assertIn('@"patch_version": @"0.17.0-test", @"app_version": @"40.6.0"',source)
    def test_injection_preserves_offsets_code_and_input(self):
        original = binary(); snapshot = bytes(original)
        modified = patch.inject_load_command(original)
        self.assertEqual(original,snapshot)
        self.assertEqual(len(original),len(modified))
        self.assertEqual(modified[512:],b'CODE')
        self.assertEqual(modified[32:208],original[32:208])
        self.assertEqual(struct.unpack_from('<I',modified,16)[0],3)
        _, commands = patch.commands(modified)
        c,p,n = commands[-1]
        self.assertEqual(c,0xc)
        self.assertEqual(patch.dylib_name(modified,p,n),patch.LOAD_PATH)
    def test_repeated_injection_rejected(self):
        with self.assertRaisesRegex(ValueError,'already injected'):
            patch.inject_load_command(patch.inject_load_command(binary()))
    def test_encryption_rejected(self):
        with self.assertRaisesRegex(ValueError,'encrypted'): patch.inject_load_command(binary(encrypted=True))
    def test_nonzero_padding_rejected(self):
        with self.assertRaisesRegex(ValueError,'padding contains'): patch.inject_load_command(binary(padding=False))
    def test_no_padding_rejected(self):
        with self.assertRaisesRegex(ValueError,'padding'): patch.inject_load_command(binary(), 'x'*500)
    def test_malformed_command_rejected(self):
        data = bytearray(binary()); struct.pack_into('<I',data,36,0)
        with self.assertRaises(ValueError): patch.commands(data)
    def test_wrong_architecture_rejected(self):
        data = bytearray(binary()); struct.pack_into('<I',data,4,0x1000007)
        with self.assertRaisesRegex(ValueError,'arm64'): patch.commands(data)
    def test_unsafe_paths_rejected(self):
        for name in ['../bad','Payload/../bad','/bad','C:/bad','Payload/./bad','Payload\\bad']:
            with self.subTest(name=name), self.assertRaises(ValueError): patch.normalized_name(zipfile.ZipInfo(name))
    def test_misflagged_utf8_filename_recovered(self):
        name='Payload/Aweme.app/图片.heic'
        info=zipfile.ZipInfo(name.encode('utf-8').decode('cp437'))
        self.assertEqual(patch.normalized_name(info),name)
    def test_valid_ascii_preserved(self):
        self.assertEqual(patch.normalized_name(zipfile.ZipInfo('Payload/Aweme.app/Aweme')),'Payload/Aweme.app/Aweme')
    def test_archive_preserves_symlink_metadata(self):
        entry=zipfile.ZipInfo('Payload/Aweme.app/link');entry.external_attr=0o120777<<16
        clone=patch.clone_info(entry,entry.filename)
        self.assertEqual(clone.external_attr,entry.external_attr)
        self.assertEqual(entry.compress_type,zipfile.ZIP_STORED)
    def test_resources_validate_and_no_identity_hooks(self):
        hooks,words=patch.validate_resources(ROOT/'resources')
        self.assertEqual(len(hooks),79)
        self.assertEqual(words['首页'],'Home')
        self.assertFalse(any(x['selector'] in ['isLogin','isLoggedIn','hasMore','isAds'] for x in hooks))
        self.assertEqual(sum(x['feature']=='search' for x in hooks),5)
        self.assertEqual({x['selector'] for x in hooks if x['feature']=='background'},
                         {'switchState','audioSwitchState','audioSceneState','enableBGPlayComponent','shouldResponseNotification'})
        self.assertFalse(any(x['selector'] in ['listenVideoStatus','setListenVideoStatus:',
            'isVIPSubscribeContentAllowedListenWithAwemeModel:','shouldEnterBackgroundPlayMode']
            and x['operation'] not in ('observeBool0',) for x in hooks))
        self.assertFalse(any(x['selector'] in ['needsLogin','shouldLoginLimit','checkHitLimitWithStatusCode:andStatusMsg:']
                             and x['feature']!='diagnostics' for x in hooks))
    def test_hash_streaming(self):
        import hashlib
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'input';path.write_bytes(b'known bytes')
            self.assertEqual(patch.sha256(path),hashlib.sha256(b'known bytes').hexdigest())
    def test_personal_gemini_config_has_only_explicit_credential(self):
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'gemini-private.json'
            path.write_text(json.dumps({'api_key':'synthetic-test-key'}),encoding='utf8')
            self.assertEqual(json.loads(patch.private_gemini_payload(path)),{'api_key':'synthetic-test-key'})
    def test_personal_config_rejects_headers_endpoints_and_invalid_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'gemini-private.json'
            for value in [[],{'api_key':''},{'api_key':'line\nbreak'},{'api_key':123},{'api_key':'x','endpoint':'https://other.example'},{'api_key':'x'*513}]:
                path.write_text(json.dumps(value),encoding='utf8')
                with self.subTest(value_type=type(value).__name__),self.assertRaises(ValueError):patch.private_gemini_payload(path)
    def test_media_config_validates_actor_and_separate_credentials(self):
        valid={'apify_api_key':'fixture-apify','deepgram_api_key':'fixture-deepgram','apify_actor':'apple_yang~douyin-video-audio-downloader'}
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'media.json'
            path.write_text(json.dumps(valid),encoding='utf8')
            self.assertEqual(json.loads(patch.private_media_payload(path)),valid)
            for value in [[],{},dict(valid,endpoint='https://other.example'),dict(valid,apify_actor='other'),dict(valid,deepgram_api_key='x\r\nCookie: y'),dict(valid,apify_api_key=''),dict(valid,deepgram_api_key=4)]:
                path.write_text(json.dumps(value),encoding='utf8')
                with self.subTest(value_type=type(value).__name__),self.assertRaises(ValueError):patch.private_media_payload(path)
    def test_transport_hook_rejects_out_of_scope_resources(self):
        hooks,words=patch.validate_resources(ROOT/'resources')
        transport=next(x for x in hooks if x['operation']=='preferStandardFeed')
        with tempfile.TemporaryDirectory() as directory:
            resource=pathlib.Path(directory)
            (resource/'translations.json').write_text(json.dumps(words),encoding='utf8')
            for changes in [{'class':'AWEUserService'},{'selector':'isLogin'},
                            {'class_method':True},{'operation':'false0'},{'feature':'guest'}]:
                invalid=[{**x,**changes} if x is transport else x for x in hooks]
                (resource/'hooks.json').write_text(json.dumps(invalid),encoding='utf8')
                with self.subTest(changes=changes),self.assertRaises(ValueError):
                    patch.validate_resources(resource)
    def test_format_hooks_are_locked_to_both_verified_controllers(self):
        hooks,words=patch.validate_resources(ROOT/'resources')
        formats=[x for x in hooks if x['operation']=='standardFeedFormat']
        self.assertEqual({x['class'] for x in formats},
            {'AWEFeedDoubleColumnListDataController','AWESearchCachalotDCFeedDataController'})
        with tempfile.TemporaryDirectory() as directory:
            resource=pathlib.Path(directory)
            (resource/'translations.json').write_text(json.dumps(words),encoding='utf8')
            for target in formats:
                for changes in [{'class':'AWEUserService'},{'selector':'isLogin'},
                        {'class_method':True},{'operation':'false0'},{'feature':'guest'},{'types':'q16@0:8'}]:
                    invalid=[{**x,**changes} if x is target else x for x in hooks]
                    (resource/'hooks.json').write_text(json.dumps(invalid),encoding='utf8')
                    with self.subTest(target=target['class'],changes=changes),self.assertRaises(ValueError):
                        patch.validate_resources(resource)
    def test_body_and_notification_hooks_reject_unverified_targets(self):
        hooks,words=patch.validate_resources(ROOT/'resources')
        targets=[x for x in hooks if x['operation'] in ('normalFeedBody','backgroundNotification')]
        self.assertEqual(len(targets),2)
        with tempfile.TemporaryDirectory() as directory:
            resource=pathlib.Path(directory)
            (resource/'translations.json').write_text(json.dumps(words),encoding='utf8')
            for target in targets:
                for changes in [{'class':'AWEUserService'},{'selector':'isLogin'},
                        {'class_method':True},{'operation':'false0'},{'feature':'guest'}]:
                    (resource/'hooks.json').write_text(json.dumps([{**x,**changes} if x is target else x for x in hooks]),encoding='utf8')
                    with self.subTest(target=target['operation'],changes=changes),self.assertRaises(ValueError):
                        patch.validate_resources(resource)
    def test_build_removes_device_thinning_without_weakening_capabilities(self):
        main = {'CFBundleIdentifier':'com.ss.iphone.ugc.Aweme', 'CFBundleShortVersionString':'40.6.0',
                'CFBundleVersion':'406019', 'UISupportedDevices':['iPhone9,1'],
                'UIDeviceFamily':[1,2], 'UIRequiredDeviceCapabilities':['arm64'], 'MinimumOSVersion':'15.0',
                'UIBackgroundModes':['audio','fetch','voip','remote-notification'],
                'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait'],
                'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
        extension = {'CFBundleIdentifier':'fixture.extension', 'UISupportedDevices':['iPhone9,1'],
                     'UIDeviceFamily':[1], 'UIRequiredDeviceCapabilities':{'arm64':True}, 'MinimumOSVersion':'15.0'}
        main_path=patch.APP+'Info.plist'
        extension_path=patch.APP+'PlugIns/Fixture.appex/Info.plist'
        untouched_path=patch.APP+'PlugIns/Other.appex/Info.plist'
        untouched=plistlib.dumps({'CFBundleIdentifier':'fixture.other','UIDeviceFamily':[1]})
        with tempfile.TemporaryDirectory() as directory:
            root=pathlib.Path(directory);source=root/'source.ipa';library=root/'fixture.dylib';output=root/'patched.ipa'
            library.write_bytes(b'Fixture only, not a real library')
            media=root/'media.json';media.write_text(json.dumps({'apify_api_key':'fixture-apify','deepgram_api_key':'fixture-deepgram','apify_actor':'apple_yang~douyin-video-audio-downloader'}),encoding='utf8')
            vbee=root/'vbee.json';vbee.write_text(json.dumps({'app_id':'00000000-0000-0000-0000-000000000001','token':'fixture-vbee','voice_code':'hn_male_manhdung_news_48k-fhg'}))
            with zipfile.ZipFile(source,'w') as archive:
                archive.writestr(main_path,plistlib.dumps(main))
                archive.writestr(extension_path,plistlib.dumps(extension))
                archive.writestr(untouched_path,untouched)
                archive.writestr(patch.APP+'Aweme',binary())
                archive.writestr(patch.APP+'en.lproj/InfoPlist.strings',plistlib.dumps({'CFBundleDisplayName':'Douyin'}))
            with mock_patch.object(patch,'SOURCE_SHA256',patch.sha256(source)), \
                 mock_patch.object(patch,'validate_library',return_value=[]), contextlib.redirect_stdout(io.StringIO()):
                report=patch.build(source,library,output,patch.sha256(library),media_config=media,vbee_config=vbee)
            with zipfile.ZipFile(source) as original, zipfile.ZipFile(output) as result:
                for path,expected in [(main_path,main),(extension_path,extension)]:
                    self.assertEqual(plistlib.loads(original.read(path)),expected)
                    actual=plistlib.loads(result.read(path))
                    self.assertNotIn('UISupportedDevices',actual)
                    for key in ['UIDeviceFamily','UIRequiredDeviceCapabilities','MinimumOSVersion']:
                        self.assertEqual(actual[key],expected[key])
                    if path==main_path:
                        self.assertEqual(actual['CFBundleDisplayName'],'Douyin')
                        self.assertEqual(actual['CFBundleName'],'Douyin')
                        self.assertEqual(actual['UIBackgroundModes'],expected['UIBackgroundModes'])
                        self.assertEqual(actual['UISupportedInterfaceOrientations'],['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'])
                        self.assertEqual(actual['UISupportedInterfaceOrientations~ipad'],expected['UISupportedInterfaceOrientations~ipad'])
                self.assertEqual(result.read(untouched_path),untouched)
                self.assertEqual(json.loads(result.read(patch.APP+'DouyinGuest.bundle/media-private.json')),json.loads(media.read_text()))
                self.assertEqual(json.loads(result.read(patch.APP+'DouyinGuest.bundle/vbee-private.json')),json.loads(vbee.read_text()))
                localized=plistlib.loads(result.read(patch.APP+'en.lproj/InfoPlist.strings'))
                self.assertEqual(localized['CFBundleDisplayName'],'Douyin')
                self.assertEqual(localized['CFBundleName'],'Douyin')
            self.assertEqual({x['path'] for x in report['removed_thinning_allowlists']},{main_path,extension_path})
            self.assertNotIn(untouched_path,report['modified'])

if __name__ == '__main__': unittest.main()
