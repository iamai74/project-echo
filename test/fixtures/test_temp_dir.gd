## Shared helper for temporary test directories.
extends RefCounted


static func remove(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if entry != "." and entry != "..":
				var entry_path := path.path_join(entry)
				if dir.current_is_dir():
					remove(entry_path)
				else:
					DirAccess.remove_absolute(entry_path)
			entry = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(path)


static func create(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
