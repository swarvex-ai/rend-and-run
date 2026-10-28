extends RefCounted
const LAYOUT=preload("res://modules/world/notstrom_layout.gd")
static func migrate(source:Dictionary) -> Dictionary:
 var result:=source.duplicate(true)
 if result.get("layout_revision",1)==LAYOUT.REVISION:return result
 # Only migrate the known old layout; do not repeatedly move future-version saves.
 if result.get("layout_revision",1)!=1:return result
 var cache=preload("res://modules/loot/death_cache.gd").new()
 if cache.import_state(result.get("death_cache",{})) and cache.is_active():
  var at:Vector3=cache.position()
  if at.x< -3 or at.x>58 or at.y<-.1 or at.y>6 or absf(at.z)>=.1:
   cache.reset();result.death_cache=cache.export_state()
  elif at.x>=46:
   at.x+=24;cache.replace(cache.amount(),at);result.death_cache=cache.export_state()
 if result.get("completed",false)==true:
  var cleared:Array=result.get("cleared",[]).duplicate() if result.get("cleared") is Array else []
  # Preserve the existing legacy economy migration without paying for new rooms.
  if result.get("economy_revision",0)!=1:
   var old_count:=0
   for id in ["first","duelist","guard","brute"]:
    if id in cleared:old_count+=1
   var wallet=result.get("shards",0)
   var amount:int=clampi(int(wallet),0,999999) if wallet is int or wallet is float else 0
   result.shards=mini(999999,amount+3*old_count);result.economy_revision=1
  for id in LAYOUT.NEW_IDS:
   if not id in cleared:cleared.append(id)
  result.cleared=cleared
 result.layout_revision=LAYOUT.REVISION
 return result
