extends RefCounted
## Preserve one exact pre-prefix save before upgrading it. Not a backup chain.
const WRITER := preload("res://modules/persistence/atomic_json_writer.gd")
static func write_json(path: String, data: Dictionary) -> Error:
	if FileAccess.file_exists(path):
		var original := FileAccess.get_file_as_bytes(path)
		var parser := JSON.new()
		if parser.parse(original.get_string_from_utf8()) != OK: return ERR_FILE_CORRUPT
		var parsed: Variant = parser.data
		# Never silently overwrite an unreadable existing save during migration.
		if not parsed is Dictionary: return ERR_FILE_CORRUPT
		var equipment: Variant = parsed.get("equipment", {})
		var version: Variant = equipment.get("loadout_version", 1) if equipment is Dictionary else 1
		if not (version is int or version is float): return ERR_FILE_CORRUPT
		if not is_finite(float(version)) or float(version) != floorf(float(version)): return ERR_FILE_CORRUPT
		if float(version) > 3.0: return ERR_UNAVAILABLE
		if float(version) < 3.0:
			var backup := path + ".before-prefix-v3.bak"
			if FileAccess.file_exists(backup):
				# A different existing backup must never be silently replaced.
				if FileAccess.get_file_as_bytes(backup) != original: return ERR_ALREADY_EXISTS
			else:
				var result := DirAccess.copy_absolute(path, backup)
				if result != OK: return result
				if FileAccess.get_file_as_bytes(backup) != original: return ERR_FILE_CORRUPT
	return WRITER.write_json(path, data)
