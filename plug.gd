extends "res://addons/gd-plug/plug.gd"

func _plugging():
	plug("imjp94/gd-plug-ui", {"dev": true})
	plug("nuevocharrua/beautify-code-on-save", {"dev": true})
	plug("godot-gdunit-labs/gdUnit4", {"dev": true, "tag": "v6.2.3"})
