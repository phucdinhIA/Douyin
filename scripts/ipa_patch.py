"""Stream a version-locked IPA patch; never execute or extract archive content."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
import os
import pathlib
import plistlib
import shutil
import struct
import tempfile
import zipfile

SOURCE_SHA256 = '3444d6045147b772e8f5e7e844c38a0f72464f34a4eb1af5c5df5f9433d706af'
APP = 'Payload/Aweme.app/'
LOAD_PATH = '@executable_path/Frameworks/DouyinGuest.dylib'
ROOT = pathlib.Path(__file__).resolve().parents[1]
OPERATIONS = {
    'false0': 'B16@0:8', 'true0': 'B16@0:8',
    'falseObject1': 'B24@0:8@16', 'falseObject2': 'B32@0:8@16@24',
    'falseBool1': 'B20@0:8B16', 'falseBool2': 'B24@0:8B16B20',
    'noop0': 'v16@0:8', 'filterGetter': '@16@0:8', 'filterSetter': 'v24@0:8@16',
    'observeFeedCompletion2': 'v32@0:8@16@24', 'observeFeedCompletion2Bool': 'v36@0:8@16@24B32',
    'observeSearchAdapter': '#16@0:8', 'observeSearchStatus': 'B32@0:8@16@24',
    'translateGetter': '@16@0:8', 'translateRichGetter': '@16@0:8',
    'translateSurveyGetter': '@16@0:8', 'translateConfig1': 'v24@0:8@16',
    'observeFeedRequest': 'v40@0:8Q16@24@32', 'observeError1': 'v24@0:8@16',
    'observeImageFinish': 'v56@0:8@16@24@32@40q48', 'observeListGetter': '@16@0:8',
    'backgroundSwitch': 'B16@0:8', 'backgroundState': 'q16@0:8',
    'observeBool0': 'B16@0:8', 'observeVoid0': 'v16@0:8',
    'observeJSONResponse4': '@48@0:8@16@24@32^@40',
    'preferStandardFeed': 'B16@0:8',
    'standardFeedFormat': 'B16@0:8',
    'normalFeedBody': 'v24@0:8@16',
    'backgroundNotification': 'B16@0:8',
}

def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(4*1024*1024), b''):
            digest.update(block)
    return digest.hexdigest()

def commands(data: bytes):
    if len(data) < 32 or struct.unpack_from('<I', data)[0] != 0xfeedfacf:
        raise ValueError('Expected a thin little-endian Mach-O 64 binary')
    cpu, subtype, filetype, count, size = struct.unpack_from('<5I', data, 4)
    if cpu != 0x100000c or subtype & 0xffffff != 0:
        raise ValueError('Expected arm64 (not arm64e)')
    if count > 4096 or size > len(data)-32:
        raise ValueError('Invalid Mach-O command bounds')
    position = 32
    result = []
    for _ in range(count):
        if position+8 > 32+size:
            raise ValueError('Truncated Mach-O command')
        command, length = struct.unpack_from('<II', data, position)
        if length < 8 or length % 8 or position+length > 32+size:
            raise ValueError('Invalid Mach-O command length')
        result.append((command, position, length))
        position += length
    if position != 32+size:
        raise ValueError('Mach-O command sizes disagree')
    return filetype, result

def dylib_name(data: bytes, position: int, length: int) -> str:
    if length < 24:
        raise ValueError('Truncated dylib command')
    offset = struct.unpack_from('<I', data, position+8)[0]
    if offset < 24 or offset >= length:
        raise ValueError('Invalid dylib name offset')
    end = data.find(b'\0', position+offset, position+length)
    if end < 0:
        raise ValueError('Unterminated dylib name')
    return data[position+offset:end].decode('utf-8')

def inject_load_command(data: bytes, load_path: str = LOAD_PATH) -> bytes:
    filetype, cmds = commands(data)
    if filetype != 2:
        raise ValueError('Expected an executable')
    end = 32+struct.unpack_from('<I', data, 20)[0]
    section_offsets = []
    for cmd, pos, length in cmds:
        if cmd in (0xc, 0x80000018, 0x8000001f) and dylib_name(data, pos, length) == load_path:
            raise ValueError('Library is already injected')
        if cmd == 0x2c:
            if length < 24 or struct.unpack_from('<I', data, pos+16)[0] != 0:
                raise ValueError('Executable is still FairPlay encrypted')
        if cmd == 0x19:
            if length < 72:
                raise ValueError('Truncated segment')
            count = struct.unpack_from('<I', data, pos+64)[0]
            if 72+count*80 != length:
                raise ValueError('Invalid segment section table')
            for index in range(count):
                section = pos+72+index*80
                section_size = struct.unpack_from('<Q', data, section+40)[0]
                offset = struct.unpack_from('<I', data, section+48)[0]
                if offset and section_size:
                    section_offsets.append(offset)
    name = load_path.encode('utf-8') + b'\0'
    size = (24+len(name)+7)&~7
    if not section_offsets or end+size > min(section_offsets) or end+size > len(data):
        raise ValueError('Insufficient header padding; refusing to shift code')
    if any(data[end:end+size]):
        raise ValueError('Header padding contains data; refusing to overwrite')
    payload = struct.pack('<6I', 0xc, size, 24, 0, 0, 0)+name
    payload += b'\0'*(size-len(payload))
    result = bytearray(data)
    result[end:end+size] = payload
    count, oldsize = struct.unpack_from('<II', data, 16)
    struct.pack_into('<II', result, 16, count+1, oldsize+size)
    assert len(result) == len(data)
    assert result[:16] == data[:16] and result[24:end] == data[24:end]
    assert result[end+size:] == data[end+size:]
    commands(result)
    return bytes(result)

def validate_library(data: bytes):
    filetype, cmds = commands(data)
    if filetype != 6:
        raise ValueError('Expected a dynamic library')
    allowed = {
        '/usr/lib/libobjc.A.dylib', '/usr/lib/libSystem.B.dylib',
        '/System/Library/Frameworks/Foundation.framework/Foundation',
        '/System/Library/Frameworks/UIKit.framework/UIKit',
        '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
        '/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics',
        '/System/Library/Frameworks/AVFoundation.framework/AVFoundation',
        '/System/Library/Frameworks/CoreMedia.framework/CoreMedia',
        '/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer',
    }
    dependencies = []
    identifiers = []
    versions = []
    for cmd, pos, length in cmds:
        if cmd in (0xc, 0x80000018, 0x8000001f):
            name = dylib_name(data, pos, length)
            if name not in allowed:
                raise ValueError('Unexpected library dependency: '+name)
            dependencies.append(name)
        if cmd == 0xd:
            identifiers.append(dylib_name(data, pos, length))
        if cmd == 0x32:
            if length < 24: raise ValueError('Truncated build version')
            platform, minimum = struct.unpack_from('<II', data, pos+8)
            if platform != 2 or minimum > 0xf0000:
                raise ValueError('Library must target iOS 15.0 or earlier')
            versions.append(minimum)
        if cmd == 0x25:
            minimum = struct.unpack_from('<I', data, pos+8)[0]
            if minimum > 0xf0000: raise ValueError('iOS target is too recent')
            versions.append(minimum)
        if cmd == 0x2c and struct.unpack_from('<I', data, pos+16)[0]:
            raise ValueError('Library is encrypted')
    if identifiers != ['@rpath/DouyinGuest.dylib'] or not versions:
        raise ValueError('Library ID or iOS deployment target missing')
    return dependencies

def normalized_name(info: zipfile.ZipInfo) -> str:
    if '\\' in info.orig_filename:
        raise ValueError('Unsafe ZIP path')
    name = info.filename
    if not info.flag_bits & 0x800:
        try:
            recovered = name.encode('cp437').decode('utf-8')
            if recovered != name: name = recovered
        except (UnicodeEncodeError, UnicodeDecodeError): pass
    if '\\' in name or '\x00' in name or name.startswith('/'):
        raise ValueError('Unsafe ZIP path')
    parts = name.split('/')
    if any(part in ('..', '.') or ':' in part for part in parts):
        raise ValueError('Unsafe ZIP path')
    return name

def validate_resources(resource_dir: pathlib.Path):
    hooks = json.loads((resource_dir/'hooks.json').read_text(encoding='utf-8'))
    translations = json.loads((resource_dir/'translations.json').read_text(encoding='utf-8'))
    if not isinstance(hooks, list) or not hooks or not isinstance(translations, dict):
        raise ValueError('Invalid resources')
    seen = set()
    for spec in hooks:
        key = (spec['class'], spec['selector'], spec['class_method'])
        sdk_hooks = {
            ('DUXToastViewConfig','text',False):('translateGetter','english'),
            **{('IESLiveMoreToolsSettingItem',selector,False):('translateGetter','english')
               for selector in ['title','buttonTitle','sectionTitle','toolbarItemTitle']},
            ('BDWebImageRequest','failedWithError:',False):('observeError1','diagnostics'),
            ('BDWebImageRequest','finishWithImage:data:savePath:url:from:',False):('observeImageFinish','diagnostics'),
        }
        if key in seen or (not spec['class'].startswith('AWE') and
                           sdk_hooks.get(key) != (spec['operation'],spec['feature'])):
            raise ValueError('Duplicate or out-of-scope hook')
        seen.add(key)
        if spec['feature'] not in ('guest', 'ads', 'diagnostics', 'search', 'english', 'background', 'feed_compat') or spec['types'] != OPERATIONS.get(spec['operation']):
            raise ValueError('Invalid hook operation/type')
        if not isinstance(spec['class_method'], bool): raise ValueError('Invalid method kind')
        if spec['operation'] in ('backgroundSwitch','backgroundState'):
            expected={'switchState':'backgroundSwitch','audioSwitchState':'backgroundState','audioSceneState':'backgroundState'}
            component=(spec['class']=='AWEFeedBGPlaySettings' and spec['class_method'] and spec['selector']=='enableBGPlayComponent' and spec['operation']=='backgroundSwitch')
            store=(spec['class']=='AWEAwemeBackgroundPlayStoreService' and not spec['class_method'] and expected.get(spec['selector'])==spec['operation'])
            if spec['feature']!='background' or not (component or store):
                raise ValueError('Background preference hook outside verified local store')
        if spec['operation']=='backgroundNotification' or (spec['class'],spec['selector'])==('AWEAwemeBackgroundPlayModule','shouldResponseNotification'):
            if (spec['class'],spec['selector'],spec['class_method'],spec['feature'],spec['operation'])!=('AWEAwemeBackgroundPlayModule','shouldResponseNotification',False,'background','backgroundNotification'):
                raise ValueError('Background notification hook outside verified lifecycle gate')
        if spec['operation']=='observeJSONResponse4' and (spec['class'],spec['selector'],spec['class_method'],spec['feature'])!=('AWEJSONResponseSerializer','responseObjectForResponse:jsonObj:responseError:resultError:',False,'diagnostics'):
            raise ValueError('JSON observer outside verified serializer')
        if spec['operation'] in ('preferStandardFeed','standardFeedFormat','normalFeedBody') or spec['feature']=='feed_compat':
            verified={('AWEDCFeedListDataManager','shouldRequestWithChunk',False,'feed_compat','preferStandardFeed'),
                      ('AWEFeedDoubleColumnListDataController','enableChunkRequest',False,'feed_compat','standardFeedFormat'),
                      ('AWESearchCachalotDCFeedDataController','enableChunkRequest',False,'feed_compat','standardFeedFormat'),
                      ('AWEDCFeedDefaultDataController','buildRequestParams:',False,'feed_compat','normalFeedBody')}
            if (spec['class'],spec['selector'],spec['class_method'],spec['feature'],spec['operation']) not in verified:
                raise ValueError('Feed transport hook outside verified native selector')
    for key, value in translations.items():
        if not isinstance(key, str) or not isinstance(value, str) or not key or not value:
            raise ValueError('Invalid translation')
    return hooks, translations

def clone_info(info: zipfile.ZipInfo, name: str) -> zipfile.ZipInfo:
    result = copy.copy(info)
    result.filename = result.orig_filename = name
    # Old Unicode path extras and ZIP64 sizes would describe the original entry.
    result.extra = b''
    result.compress_type = zipfile.ZIP_DEFLATED
    result._compresslevel = 1
    return result

def private_gemini_payload(path: pathlib.Path):
    config = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(config, dict) or set(config) != {'api_key'} or not isinstance(config['api_key'], str) or not 1 <= len(config['api_key']) <= 512 or any(c.isspace() for c in config['api_key']):
        raise ValueError('Invalid personal Gemini config')
    return json.dumps(config, ensure_ascii=True).encode('utf-8')

def private_media_payload(path: pathlib.Path):
    config = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(config, dict) or set(config) != {'apify_api_key','deepgram_api_key','apify_actor'}:
        raise ValueError('Invalid personal media config')
    if config['apify_actor'] != 'apple_yang~douyin-video-audio-downloader':
        raise ValueError('Unsupported media actor')
    for field in ('apify_api_key','deepgram_api_key'):
        key = config[field]
        if not isinstance(key,str) or not 1 <= len(key) <= 512 or any(c.isspace() for c in key):
            raise ValueError('Invalid personal media credential')
    return json.dumps(config,ensure_ascii=True).encode('utf-8')


def private_vbee_payload(path: pathlib.Path):
    import uuid
    config=json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(config,dict) or set(config)!={'app_id','token','voice_code'}:
        raise ValueError('Invalid personal Vbee config')
    if config['voice_code']!='hn_male_manhdung_news_48k-fhg':
        raise ValueError('Unsupported Vbee voice')
    uuid.UUID(config['app_id'])
    token=config['token']
    if not isinstance(token,str) or not 1<=len(token)<=1024 or any(c.isspace() for c in token):
        raise ValueError('Invalid personal Vbee token')
    return json.dumps(config,ensure_ascii=True).encode('utf-8')


def build(source: pathlib.Path, library: pathlib.Path, output: pathlib.Path,
          library_sha256: str, resource_dir: pathlib.Path = ROOT/'resources', gemini_config: pathlib.Path = None, media_config: pathlib.Path = None, vbee_config: pathlib.Path = None):
    source, library, output = source.resolve(), library.resolve(), output.resolve()
    if output == source or output == library or output.exists() or output.with_suffix('.validation.json').exists():
        raise ValueError('Output must be a new file distinct from inputs')
    if sha256(source) != SOURCE_SHA256:
        raise ValueError('Source hash mismatch; this patch is only for the audited IPA')
    if sha256(library) != library_sha256.lower():
        raise ValueError('Library hash mismatch')
    library_data = library.read_bytes()
    dependencies = validate_library(library_data)
    hooks, words = validate_resources(resource_dir)
    private_payload = None
    if gemini_config is not None:
        private_payload = private_gemini_payload(gemini_config)
    media_payload = private_media_payload(media_config) if media_config is not None else None
    vbee_payload = private_vbee_payload(vbee_config) if vbee_config is not None else None
    changes, removals, corrections, hashes = [], [], [], {}
    thinning_allowlists = []
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix='guest-', suffix='.ipa.tmp', dir=output.parent)
    os.close(descriptor)
    temporary = pathlib.Path(temporary)
    try:
        with zipfile.ZipFile(source) as original, zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=1, allowZip64=True) as target:
            names = [normalized_name(info) for info in original.infolist()]
            if len(names) != len(set(names)): raise ValueError('Duplicate normalized ZIP paths')
            info = plistlib.loads(original.read(APP+'Info.plist'))
            if (info.get('CFBundleIdentifier'), info.get('CFBundleShortVersionString'), info.get('CFBundleVersion')) != ('com.ss.iphone.ugc.Aweme','40.6.0','406019'):
                raise ValueError('App identity mismatch')
            injected = inject_load_command(original.read(APP+'Aweme'))
            english_info = plistlib.loads(original.read(APP+'en.lproj/InfoPlist.strings'))
            info.update(english_info)
            info['CFBundleDisplayName'] = 'Douyin'
            info['CFBundleName'] = 'Douyin'
            info['CFBundleDevelopmentRegion'] = 'en'
            info['DGSourceSHA256'] = SOURCE_SHA256
            # Allow the existing native full-screen controllers to request landscape.
            # Their controller/delegate policies still decide when rotation occurs.
            info['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationPortrait',
                'UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']
            # App Store thinning leaves an exact-model allowlist. It can reject
            # newer arm64 phones before launch; retain family/capability/minimum OS checks.
            if 'UISupportedDevices' in info:
                thinning_allowlists.append({'path': APP+'Info.plist', 'previous': info.pop('UISupportedDevices')})
            modified = {APP+'Aweme': injected, APP+'Info.plist': plistlib.dumps(info, fmt=plistlib.FMT_BINARY)}
            for entry, name in zip(original.infolist(), names):
                if name != entry.filename: corrections.append(name)
                if '/_CodeSignature/' in name or name.endswith('/embedded.mobileprovision'):
                    removals.append(name); continue
                if name.startswith(APP+'DouyinGuest.bundle/') or name == APP+'Frameworks/DouyinGuest.dylib':
                    raise ValueError('Input already contains the patch')
                if name.startswith(APP+'PlugIns/') and name.endswith('.appex/Info.plist'):
                    extension_info = plistlib.loads(original.read(entry))
                    if 'UISupportedDevices' in extension_info:
                        thinning_allowlists.append({'path': name, 'previous': extension_info.pop('UISupportedDevices')})
                        modified[name] = plistlib.dumps(extension_info, fmt=plistlib.FMT_BINARY)
                if name.startswith(APP) and name.count('/') == 3 and name.endswith('.lproj/InfoPlist.strings'):
                    localized = plistlib.loads(original.read(entry))
                    localized.update(english_info)
                    localized['CFBundleDisplayName'] = 'Douyin'
                    localized['CFBundleName'] = 'Douyin'
                    modified[name] = plistlib.dumps(localized, fmt=plistlib.FMT_BINARY)
                digest = hashlib.sha256()
                with target.open(clone_info(entry, name), 'w', force_zip64=entry.file_size >= 2**31) as destination:
                    if name in modified:
                        payload = modified[name]; destination.write(payload); digest.update(payload); changes.append(name)
                    else:
                        with original.open(entry) as stream:
                            for chunk in iter(lambda:stream.read(4*1024*1024), b''):
                                destination.write(chunk); digest.update(chunk)
                hashes[name] = digest.hexdigest()
            additions = {
                APP+'Frameworks/DouyinGuest.dylib': library_data,
                APP+'DouyinGuest.bundle/hooks.json': (resource_dir/'hooks.json').read_bytes(),
                APP+'DouyinGuest.bundle/translations.json': (resource_dir/'translations.json').read_bytes(),
                APP+'DouyinGuest.bundle/Info.plist': plistlib.dumps({'CFBundleIdentifier':'local.douyin.guest.resources','CFBundleName':'DouyinGuest','CFBundleVersion':'1','CFBundlePackageType':'BNDL'},fmt=plistlib.FMT_BINARY),
            }
            if private_payload is not None:
                additions[APP+'DouyinGuest.bundle/gemini-private.json'] = private_payload
            if media_payload is not None:
                additions[APP+'DouyinGuest.bundle/media-private.json'] = media_payload
            if vbee_payload is not None:
                additions[APP+'DouyinGuest.bundle/vbee-private.json'] = vbee_payload
            for name, payload in additions.items():
                entry = zipfile.ZipInfo(name, date_time=(2026,10,1,0,0,0))
                entry.external_attr = (0o100755 if name.endswith('.dylib') else 0o100644)<<16
                target.writestr(clone_info(entry,name),payload)
                hashes[name] = hashlib.sha256(payload).hexdigest()
        # Re-read every resulting entry and compare its bytes with the build manifest.
        with zipfile.ZipFile(temporary) as result:
            if set(result.namelist()) != set(hashes): raise ValueError('Output inventory mismatch')
            for entry in result.infolist():
                digest = hashlib.sha256()
                with result.open(entry) as stream:
                    for chunk in iter(lambda:stream.read(4*1024*1024), b''): digest.update(chunk)
                if digest.hexdigest() != hashes[entry.filename]: raise ValueError('Output hash mismatch: '+entry.filename)
        if sha256(source) != SOURCE_SHA256: raise ValueError('Source changed during build')
        # Exclusive publication protects an existing file even if created during the build.
        with output.open('xb') as destination, temporary.open('rb') as stream:
            shutil.copyfileobj(stream, destination, 4*1024*1024)
        report = {'source_sha256':SOURCE_SHA256,'output_sha256':sha256(output),
                  'library_sha256':library_sha256,'size':output.stat().st_size,
                  'modified':changes,'added':list(additions),'removed_signature_entries':removals,
                  'utf8_filename_corrections':corrections,'entry_count':len(hashes),
                  'removed_thinning_allowlists':thinning_allowlists,
                  'all_output_entry_hashes_verified':True,'source_unchanged':True,
                  'library_dependencies':dependencies,'native_hooks':len(hooks),'translation_entries':len(words),
                  'runtime_tested':False,'status':'test candidate; re-sign required', 'entry_sha256':hashes}
        report_path = output.with_suffix('.validation.json')
        with report_path.open('x', encoding='utf-8') as stream: json.dump(report,stream,ensure_ascii=False,indent=2)
        print(json.dumps({k:v for k,v in report.items() if k != 'entry_sha256'},ensure_ascii=True,indent=2))
        return report
    finally:
        temporary.unlink(missing_ok=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=pathlib.Path)
    parser.add_argument('library',type=pathlib.Path)
    parser.add_argument('output',type=pathlib.Path)
    parser.add_argument('--library-sha256',required=True)
    parser.add_argument('--gemini-config',type=pathlib.Path,help='Local personal config, excluded from source and CI')
    parser.add_argument('--media-config',type=pathlib.Path,help='Local Apify/Deepgram credentials, excluded from source and CI')
    parser.add_argument('--vbee-config',type=pathlib.Path,help='Local personal Vbee credentials, excluded from source and CI')
    args = parser.parse_args()
    build(args.source,args.library,args.output,args.library_sha256,gemini_config=args.gemini_config,media_config=args.media_config,vbee_config=args.vbee_config)
