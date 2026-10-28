"""Real Godot regression: explicit asset sources, temporary versions only."""
import argparse, importlib.util, json, tempfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('pipeline',Path(__file__).resolve().parents[1]/'pipeline.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
a=argparse.ArgumentParser();a.add_argument('--hero',required=True);a.add_argument('--chaser',required=True);a.add_argument('--report',required=True);args=a.parse_args()
results=[]
with tempfile.TemporaryDirectory(prefix='p03-integration-') as tmp:
    root=Path(tmp)
    for kind,source in [('hero_v05',args.hero),('chaser_v01',args.chaser)]:
        source=Path(source).resolve();delivery=root/kind
        p.seal(source.parent,delivery,kind,[(source.name,p.HERE/'contracts'/f'{kind}.json')])
        r=p.publish(delivery,root/'versions');results.append({'test':kind+' real import','result':'PASS','qa':r['qa']})
        assert p.publish(delivery,root/'versions')['status']=='already_present'
    for field,value in [('required_meshes',['missing_mesh']),('sockets',['missing_socket']),('clips',['missing_clip']),('height_m',8.0),('front_bones',['mixamorig_headfront','mixamorig_Head'])]:
        contract=p.read(p.HERE/'contracts/hero_v05.json');contract[field]=value;cp=root/f'{field}.json';p.write(cp,contract)
        source=Path(args.hero).resolve();delivery=root/('bad_'+field)
        p.seal(source.parent,delivery,'bad_'+field,[(source.name,cp)])
        try:p.publish(delivery,root/'versions')
        except p.Invalid as e:
            assert not (root/'versions'/('bad_'+field)).exists()
            results.append({'test':'Reject '+field,'result':'PASS','rejection':str(e)[:400]})
        else:raise AssertionError('Invalid contract published: '+field)
p.write(args.report,{'result':'PASS','tests':results,'ssh_transport':'Not tested here; gufo owns existing desktop SSH connection','game_integration':'Pending Hermie pull, repo commit and live project import'})
print('PASS: real hero/chaser imports, idempotency, five real Godot rejection cases')
