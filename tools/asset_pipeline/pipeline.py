#!/usr/bin/env python3
"""Rend&Run delivery gate. Python stdlib only; never edits gameplay or activates versions."""
import argparse, hashlib, json, os, re, shutil, struct, subprocess, sys, tempfile
from pathlib import Path, PurePosixPath

HERE = Path(__file__).resolve().parent
class Invalid(ValueError): pass

def read(path):
    return json.loads(Path(path).read_text())

def write(path, data):
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')

def digest(path):
    with open(path, 'rb') as f: return hashlib.file_digest(f, 'sha256').hexdigest()

def safe(root, name):
    p = PurePosixPath(name)
    if not name or '\\' in name or p.is_absolute() or any(x in ('.', '..') for x in name.split('/')):
        raise Invalid('Unsafe relative path: ' + name)
    dest = root.joinpath(*p.parts)
    for part in [dest, *dest.parents]:
        if part == root.parent: break
        if part.is_symlink(): raise Invalid('Symlink rejected: ' + str(part))
    return dest

def glb_check(path):
    data = path.read_bytes()
    if len(data) < 20: raise Invalid('Truncated GLB')
    magic, version, size = struct.unpack_from('<4sII', data)
    if magic != b'glTF' or version != 2 or size != len(data): raise Invalid('Invalid GLB header')
    offset = 12; chunks = []
    while offset < size:
        if offset + 8 > size: raise Invalid('Truncated chunk header')
        length, kind = struct.unpack_from('<II', data, offset); offset += 8
        if length % 4 or offset + length > size: raise Invalid('Invalid chunk size')
        chunks.append((kind, data[offset:offset+length])); offset += length
    if not chunks or chunks[0][0] != 0x4E4F534A: raise Invalid('Missing GLB JSON')
    doc = json.loads(chunks[0][1]); binary = next((b for k,b in chunks if k == 0x004E4942), b'')
    for b in doc.get('buffers', []):
        if 'uri' in b or b['byteLength'] > len(binary): raise Invalid('External or missing buffer')
    for view in doc.get('bufferViews', []):
        if view.get('buffer', 0) != 0 or view.get('byteOffset',0) + view['byteLength'] > len(binary):
            raise Invalid('Buffer view outside binary')
    for image in doc.get('images', []):
        if 'uri' in image or 'bufferView' not in image: raise Invalid('Image must be embedded in GLB')
        if not 0 <= image['bufferView'] < len(doc.get('bufferViews', [])): raise Invalid('Missing image buffer')
    for tex in doc.get('textures', []):
        if not 0 <= tex.get('source', -1) < len(doc.get('images', [])): raise Invalid('Missing texture image')
    for mat in doc.get('materials', []):
        for ref in [mat.get('normalTexture'),mat.get('occlusionTexture'),mat.get('emissiveTexture'),
                    mat.get('pbrMetallicRoughness',{}).get('baseColorTexture'),mat.get('pbrMetallicRoughness',{}).get('metallicRoughnessTexture')]:
            if ref and not 0 <= ref.get('index',-1) < len(doc.get('textures',[])): raise Invalid('Missing material texture')
    return {'meshes':len(doc.get('meshes',[])), 'materials':len(doc.get('materials',[])), 'embedded_images':len(doc.get('images',[]))}

def verify(root):
    root = Path(root).absolute(); manifest = read(safe(root, 'delivery.json'))
    if manifest.get('schema') != 1 or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,79}', manifest.get('delivery_id','')):
        raise Invalid('Expected schema=1 and safe delivery_id')
    files = manifest.get('files')
    if not isinstance(files, dict) or not files: raise Invalid('Missing file checksums; seal legacy delivery explicitly')
    for name, meta in files.items():
        file = safe(root, name)
        if name == 'delivery.json' or not file.is_file(): raise Invalid('Missing/invalid file: '+name)
        if not re.fullmatch('[0-9a-f]{64}',meta.get('sha256','')): raise Invalid('Missing sha256: '+name)
        if file.stat().st_size != meta.get('bytes') or digest(file) != meta['sha256']: raise Invalid('Hash/size mismatch: '+name)
    assets = manifest.get('assets', [])
    if not assets: raise Invalid('No asset contracts')
    for asset in assets:
        if asset['path'] not in files or asset['contract'] not in files: raise Invalid('Asset/contract not covered by hashes')
        if not asset['path'].endswith('.glb'): raise Invalid('Only GLB assets supported')
        glb_check(safe(root,asset['path']))
    return manifest

def seal(source, dest, delivery_id, assets):
    """Explicitly establish a NEW baseline; never pretends to authenticate historic files."""
    source, dest = Path(source).absolute(), Path(dest).absolute()
    if dest.exists(): raise Invalid('Seal destination must not exist')
    dest.mkdir(parents=True)
    try:
        manifest={'schema':1,'delivery_id':delivery_id,'provenance':'Explicit new baseline from local files; not historic verification', 'assets':[], 'files':{}}
        for index,(name, contract) in enumerate(assets):
            src=safe(source,name); out=safe(dest,name); out.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(src,out)
            c=f'contracts/{index}.json'; safe(dest,c).parent.mkdir(exist_ok=True); shutil.copyfile(contract,safe(dest,c))
            manifest['assets'].append({'path':name,'contract':c})
        for file in sorted(dest.rglob('*')):
            if file.is_file(): manifest['files'][file.relative_to(dest).as_posix()]={'bytes':file.stat().st_size,'sha256':digest(file)}
        write(dest/'delivery.json',manifest); verify(dest)
    except Exception:
        shutil.rmtree(dest); raise

def godot_validate(root, manifest, godot='godot'):
    reports=[]
    with tempfile.TemporaryDirectory(prefix='rendrun-qa-') as tmp:
        report=Path(tmp)/'result.json'
        for asset in manifest['assets']:
            report.unlink(missing_ok=True)
            cmd=[godot,'--headless','--path',str(HERE/'godot'),'--script',str(HERE/'godot/validate.gd'),'--',str(safe(root,asset['path'])),str(safe(root,asset['contract'])),str(report)]
            env=dict(os.environ, XDG_DATA_HOME=str(Path(tmp)/'userdata'))
            run=subprocess.run(cmd,capture_output=True,text=True,timeout=180,env=env)
            if run.returncode or not report.exists() or 'ERROR:' in run.stderr or 'SCRIPT ERROR:' in run.stdout: raise Invalid('Godot validation failed: '+ (json.dumps(read(report).get('errors',[])) if report.exists() else run.stdout[-3000:]) +run.stderr[-3000:])
            result=read(report)
            if result.get('result')!='PASS': raise Invalid(json.dumps(result))
            reports.append({'path':asset['path'],'checks':result})
    return reports

def publish(source, target, godot='godot'):
    source, target=Path(source).absolute(),Path(target).absolute()
    initial=verify(source)
    target.mkdir(parents=True,exist_ok=True)
    # Hidden staging is a sibling of final version: rename is atomic on this filesystem.
    with tempfile.TemporaryDirectory(prefix='.staging-',dir=target) as tmp:
        stage=Path(tmp)/'payload'; stage.mkdir()
        for name in ['delivery.json',*initial['files']]:
            out=safe(stage,name); out.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(safe(source,name),out)
        manifest=verify(stage)
        if manifest!=initial: raise Invalid('Manifest changed during staging')
        reports=godot_validate(stage,manifest,godot)
        verify(stage)
        write(stage/'qa-report.json',{'result':'PASS','assets':reports,'manual_review':['Visual style, animation quality and gameplay acceptance remain human review']})
        final=target/manifest['delivery_id']
        # Serialize publishers without clobbering old versions.
        lock=target/'.publish.lock'
        try: fd=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
        except FileExistsError: raise Invalid('Another publish is active (or stale .publish.lock needs inspection)')
        try:
            os.close(fd)
            if final.exists():
                if verify(final)!=manifest: raise Invalid('Version collision; choose a new delivery_id')
                return {'status':'already_present','path':str(final)}
            stage.rename(final)
            return {'status':'published','path':str(final),'qa':reports}
        finally: lock.unlink()

def pull(host, remote, dest):
    """SFTP through existing SSH trust; no remote shell, no archive extraction."""
    if not re.fullmatch(r'[A-Za-z0-9_.@-]+',host) or host.startswith('-'): raise Invalid('Invalid SSH host')
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+',remote) or '..' in remote.split('/'): raise Invalid('Use a simple absolute remote path')
    dest=Path(dest).absolute()
    if dest.exists(): raise Invalid('Pull destination must not exist')
    dest.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.pull-',dir=dest.parent) as tmp:
        root=Path(tmp)/'payload'; root.mkdir()
        def get(name):
            out=safe(root,name); out.parent.mkdir(parents=True,exist_ok=True)
            # SFTP path quoting; local temp paths may contain spaces.
            if any(x in str(out) for x in ['"','\n','\\']): raise Invalid('Unsupported local path')
            batch=f'get "{remote}/{name}" "{out}"\n'
            run=subprocess.run(['sftp','-q','-oBatchMode=yes','-oStrictHostKeyChecking=yes','-b','-',host],input=batch,text=True,capture_output=True,timeout=180)
            if run.returncode: raise Invalid('SFTP pull failed: '+run.stderr)
        get('delivery.json'); manifest=read(root/'delivery.json')
        for name in manifest.get('files',{}):
            safe(root,name)
            if not re.fullmatch(r'[A-Za-z0-9_./-]+',name): raise Invalid('Unsupported remote filename')
            get(name)
        verify(root); root.rename(dest)
    return {'status':'staged','path':str(dest)}

def main():
    p=argparse.ArgumentParser(description=__doc__); sub=p.add_subparsers(dest='cmd',required=True)
    s=sub.add_parser('seal');s.add_argument('source');s.add_argument('dest');s.add_argument('id');s.add_argument('--asset',nargs=2,action='append',required=True,metavar=('PATH','CONTRACT'))
    s=sub.add_parser('verify');s.add_argument('source')
    s=sub.add_parser('publish');s.add_argument('source');s.add_argument('target');s.add_argument('--godot',default='godot')
    s=sub.add_parser('pull');s.add_argument('host');s.add_argument('remote');s.add_argument('dest')
    a=p.parse_args()
    try:
        if a.cmd=='seal': seal(a.source,a.dest,a.id,a.asset);result={'status':'sealed','path':a.dest}
        elif a.cmd=='verify': result=verify(a.source)
        elif a.cmd=='publish': result=publish(a.source,a.target,a.godot)
        else: result=pull(a.host,a.remote,a.dest)
        print(json.dumps(result,indent=2))
    except (ValueError,KeyError,TypeError,OSError,subprocess.SubprocessError) as e:
        print('REJECTED: '+str(e),file=sys.stderr);return 1
    return 0
if __name__=='__main__':sys.exit(main())
