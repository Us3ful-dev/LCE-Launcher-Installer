extends Control

var os := OS.get_name().to_lower()
var path :String
var installing := false

func _ready() -> void:
	Git.requestnode = self
	if os == "windows":
		path = OS.get_environment("APPDATA")
	else:
		path = OS.get_user_data_dir()
	
	if "--isautoupdate" in OS.get_cmdline_args():
		remove_file(path + "/LCE-Launcher.exe")
		remove_file(path + "/LCE-Launcher.pck")
		Git.extract_zip(path + "/LCE-Launcher.zip", path)
	else:
		$Path.text = path

func remove_file(file :String):
	DirAccess.remove_absolute(file)

func update_finished():
	var args = ["--noupdatecheck"]
	var pid = OS.create_process(path + "/LCE-Launcher.exe", args)
	if pid == -1:
		printerr("Failed to launch: ", get_parent().filename)

func _on_select_folder_button_down() -> void:
	if !installing:
		$FileDialog.popup_centered()

func _on_install_button_down() -> void:
	installing = true
	make_dirs(["/LCE-Launcher"])
	Git.downloadpath = path + "/LCE-Launcher"
	Git.install_from_github()

func _on_file_dialog_dir_selected(dir: String) -> void:
	$Path.text = "Current folder: " + dir
	path = dir

func make_dirs(dirs :Array) -> void:
	for dir in dirs:
		var fullpath = path + dir
		if DirAccess.dir_exists_absolute(fullpath):
			if dir == "":
				dir = "/LCE-loader"
			print_rich("[color=green]dir [color=lightgreen]",dir, "[color=green] was already created")
		else:
			var error = DirAccess.make_dir_absolute(fullpath)
			if error == OK:
				print_rich("[color=green]Successfully created folder: [color=lightgreen]", fullpath)
			else:
				push_error("Error creating folder: ", fullpath, " with error: ", error)
