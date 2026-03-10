extends Node

var githubapi := "https://api.github.com/repos/Us3ful-dev/LCE-Launcher/releases/latest"
var requestedfilename := "LCE-Launcher.zip"
var requestnode # this is the node that requested te check (can return the completion)
var downloadpath :String # LCE-Launcher/requestedfilename.zip

# own vars:
var headers := ["User-Agent: LCE-Launcher-Installer-gitchecker"]
var newupdatetag :String # the new version / update time

# HTTPRequesters:
var checkrequester :HTTPRequest
var downloadrequester :HTTPRequest

func _ready() -> void:
	checkrequester = HTTPRequest.new()
	add_child(checkrequester)
	checkrequester.use_threads = true
	checkrequester.request_completed.connect(on_request_completed)
	
	downloadrequester = HTTPRequest.new()
	add_child(downloadrequester)
	downloadrequester.use_threads = true
	downloadrequester.request_completed.connect(on_download_completed)

func install_from_github() -> void:
	checkrequester.request(githubapi, headers)

func on_request_completed(result, response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Body: ", body.get_string_from_utf8())
		print("Failed to check for updates: ", response_code)
		return
	
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data :Dictionary = json.get_data()
	
	download_release(data["assets"])

func download_release(assets: Array) -> void:
	#find the required .zip
	var downloadurl = ""
	for asset in assets: #all posible downloads
		if asset["name"] == requestedfilename: #find correct download
			downloadurl = asset["browser_download_url"]
			break
	
	if downloadurl == "":
		print("No matching asset found")
		return
	
	downloadrequester.download_file = downloadpath + "/" + requestedfilename
	downloadrequester.request(downloadurl, headers)
	print("Downloading update")

func on_download_completed(result, response_code, _headers, _body):
	if result == HTTPRequest.RESULT_SUCCESS:
		print("Download complete: ", downloadpath + "/" + requestedfilename)
		
		extract_zip(downloadpath + "/" + requestedfilename, downloadpath)
		
		requestnode.update_finished()
	else:
		print("Download failed: ", response_code)

func extract_zip(filepath :String, outputpath :String):
	var zip = ZIPReader.new()
	var err = zip.open(filepath)
	if err != OK:
		push_error("failed to open zip: ", err)
		return
	
	var files = zip.get_files()
	for file in files:
		var fulloutpath :String = outputpath + "/" + file
		# Write the file
		var data = zip.read_file(file)
		var f = FileAccess.open(fulloutpath, FileAccess.WRITE)
		if f:
			f.store_buffer(data)
			f.close()
		else:
			push_error("failed to write: ", fulloutpath)
	
	zip.close()
	print_rich("[color=green]extraction complete")
