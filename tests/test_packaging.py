import importlib.util
import pathlib
import struct
import tempfile
import unittest
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
        self.assertEqual(len(hooks),30)
        self.assertEqual(words['首页'],'Home')
        self.assertFalse(any(x['selector'] in ['isLogin','isLoggedIn','hasMore','isAds'] for x in hooks))
    def test_hash_streaming(self):
        import hashlib
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'input';path.write_bytes(b'known bytes')
            self.assertEqual(patch.sha256(path),hashlib.sha256(b'known bytes').hexdigest())

if __name__ == '__main__': unittest.main()
