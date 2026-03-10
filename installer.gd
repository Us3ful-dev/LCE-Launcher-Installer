extends Control

var os := OS.get_name().to_lower()
var path :String
var installing := false
var openafterinstall := true

func _ready() -> void:
	Git.requestnode = self
	if os == "windows":
		path = OS.get_environment("APPDATA") + "/LCE-Launcher"
	else:
		path = OS.get_user_data_dir()
	
	if "--isautoupdate" in OS.get_cmdline_args():
		remove_file(path + "/LCE-Launcher.exe")
		remove_file(path + "/LCE-Launcher.pck")
		Git.extract_zip(path + "/LCE-Launcher.zip", path)
		DirAccess.remove_absolute(path + "/LCE-Launcher.zip")
	else:
		$Path.text = path

func remove_file(file :String):
	DirAccess.remove_absolute(file)

func update_finished():
	set_log_text("Creating shortcuts...")
	create_shortcuts()
	if openafterinstall:
		set_log_text("Succesfully installed")
		var args = ["--noupdatecheck"]
		var pid = OS.create_process(path + "/LCE-Launcher.exe", args)
		if pid == -1:
			printerr("Failed to launch: ", get_parent().filename)
	set_log_text("Closing (3)")
	await get_tree().create_timer(1).timeout
	set_log_text("Closing (2)")
	await get_tree().create_timer(1).timeout
	set_log_text("Closing (1)")
	await get_tree().create_timer(1).timeout
	set_log_text("Closing...")
	get_tree().quit()

func create_shortcuts():
	var exepath = path + "/LCE-Launcher.exe"
	var appname = "LCE Launcher"
	
	var script = """
		$WshShell = New-Object -comObject WScript.Shell
		
		$desktop = [System.Environment]::GetFolderPath('Desktop')
		$shortcut = $WshShell.CreateShortcut("$desktop\\{appname}.lnk")
		$shortcut.TargetPath = "{exepath}"
		$shortcut.IconLocation = "{exepath},0"
		$shortcut.Save()
		
		$startmenu = [System.Environment]::GetFolderPath('StartMenu') + '\\Programs'
		$shortcut2 = $WshShell.CreateShortcut("$startmenu\\{appname}.lnk")
		$shortcut2.TargetPath = "{exepath}"
		$shortcut2.IconLocation = "{exepath},0"
		$shortcut2.Save()
	""".format({"appname": appname, "exepath": exepath})
	
	var scriptpath = OS.get_user_data_dir() + "/create_shortcuts.ps1"
	var f = FileAccess.open(scriptpath, FileAccess.WRITE)
	f.store_string(script)
	f.close()
	
	OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", scriptpath])
	
	DirAccess.remove_absolute(scriptpath)

func _on_select_folder_button_down() -> void:
	if !installing:
		$FileDialog.popup_centered()

func _on_install_button_down() -> void:
	installing = true
	make_dirs(["/LCE-Launcher"])
	Git.downloadpath = path
	Git.install_from_github()

func _on_file_dialog_dir_selected(dir: String) -> void:
	$Path.text = "Current folder: " + dir + "/LCE-Launcher"
	path = dir + "/LCE-Launcher"

func _on_openafterinstall_toggled(toggled_on: bool) -> void:
	openafterinstall = toggled_on

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

func set_log_text(text :String):
	$Log.text = text
