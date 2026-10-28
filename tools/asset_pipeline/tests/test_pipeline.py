import importlib.util, json, os, struct, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('pipeline',Path(__file__).resolve().parents[1]/'pipeline.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)

def glb(doc):
    b=json.dumps(doc).encode();b+=b' '*((-len(b))%4)
    return struct.pack('<4sII',b'glTF',2,20+len(b))+struct.pack('<II',len(b),0x4e4f534a)+b

class GateTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);self.src=self.root/'src';self.src.mkdir()
        (self.src/'a.glb').write_bytes(glb({'asset':{'version':'2.0'}}))
        self.contract=self.root/'contract.json';p.write(self.contract,{})
        self.delivery=self.root/'delivery';p.seal(self.src,self.delivery,'v1',[('a.glb',self.contract)])
    def tearDown(self):self.tmp.cleanup()
    def test_verified_baseline(self):self.assertEqual(p.verify(self.delivery)['delivery_id'],'v1')
    def test_corrupt_bytes(self):
        f=self.delivery/'a.glb';f.write_bytes(f.read_bytes()+b'x')
        with self.assertRaises(p.Invalid):p.verify(self.delivery)
    def test_missing_hashes(self):
        p.write(self.delivery/'delivery.json',{'schema':1,'delivery_id':'v1'})
        with self.assertRaises(p.Invalid):p.verify(self.delivery)
    def test_path_traversal(self):
        for name in ['../outside','/etc/passwd','a/../../x','a\\b','a/./b']:
            with self.assertRaises(p.Invalid):p.safe(self.delivery,name)
    def test_symlink(self):
        (self.delivery/'link').symlink_to(self.src)
        with self.assertRaises(p.Invalid):p.safe(self.delivery,'link/a.glb')
    def test_missing_texture(self):
        f=self.root/'bad.glb';f.write_bytes(glb({'textures':[{'source':0}]}))
        with self.assertRaises(p.Invalid):p.glb_check(f)
    def test_external_image(self):
        f=self.root/'bad.glb';f.write_bytes(glb({'images':[{'uri':'outside.png'}]}))
        with self.assertRaises(p.Invalid):p.glb_check(f)
    def test_truncated_glb(self):
        f=self.root/'bad.glb';f.write_bytes(b'glTF')
        with self.assertRaises(p.Invalid):p.glb_check(f)
    @patch.object(p,'godot_validate',return_value=[])
    def test_atomic_publish_idempotent_and_collision(self,mock):
        target=self.root/'versions';self.assertEqual(p.publish(self.delivery,target)['status'],'published')
        self.assertEqual(p.publish(self.delivery,target)['status'],'already_present')
        p.write(self.contract,{'changed':True}); other=self.root/'other';p.seal(self.src,other,'v1',[('a.glb',self.contract)])
        before=(target/'v1/delivery.json').read_bytes()
        with self.assertRaises(p.Invalid):p.publish(other,target)
        self.assertEqual((target/'v1/delivery.json').read_bytes(),before)
    @patch.object(p,'godot_validate',side_effect=p.Invalid('Godot rejected'))
    def test_failed_gate_never_publishes(self,mock):
        target=self.root/'versions'
        with self.assertRaises(p.Invalid):p.publish(self.delivery,target)
        self.assertFalse((target/'v1').exists());self.assertEqual(list(target.iterdir()),[])
    @patch.object(p,'godot_validate',return_value=[])
    def test_lock_preserves_existing(self,mock):
        target=self.root/'versions';target.mkdir();(target/'.publish.lock').touch()
        with self.assertRaises(p.Invalid):p.publish(self.delivery,target)
        self.assertFalse((target/'v1').exists())
    def test_pull_rejects_shell_and_option_inputs(self):
        for host,remote in [('-oProxyCommand=x','/assets'),('a;id','/assets'),('gufo','/a/../b'),('gufo','/a"\n')]:
            with self.assertRaises(p.Invalid):p.pull(host,remote,self.root/'download')
if __name__=='__main__':unittest.main(verbosity=2)
