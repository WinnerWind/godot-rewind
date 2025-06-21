extends Control

@export var import_button:Button
@export var start_button:Button
@export var first_scene:PackedScene
@export_group("Years Nodes")
@export var years_display_label:Label
@export var years_display_spinbox:SpinBox
@export var year_remove_checkbox:CheckBox
var years_array:Array[int] = [Time.get_datetime_dict_from_system()["year"]]

func _ready():
	ScrobbleAnalyzer.invalid_file_type.connect(_on_file_type_invalid)
	ScrobbleAnalyzer.corrupt_data.connect(_on_corrupt_data)
	ScrobbleAnalyzer.finished_read_data.connect(finished_reading_data)
	ScrobbleAnalyzer.work_status.connect(_work_status)
	years_display_spinbox.get_line_edit().text_submitted.connect(add_year)
	set_years_display_label(years_array)
	

#region Years
func set_years_display_label(array_of_years:Array[int]):
	years_display_label.text = "Years to Scrobble: "+str(array_of_years).trim_prefix("[").trim_suffix("]")

func add_year(year_name:String):
	var year = int(year_name)
	if not year_remove_checkbox.button_pressed: #Must be set to add year instead
		if not years_array.has(year):
			years_array.append(year)
	else: #remove year
		years_array.erase(year)
	set_years_display_label(years_array)

func add_year_button():
	var year = int(years_display_spinbox.get_line_edit().text)
	if not year_remove_checkbox.button_pressed: #Must be set to add year instead
		if not years_array.has(year):
			years_array.append(year)
	else: #remove year
		years_array.erase(year)
	set_years_display_label(years_array)
#endregion
#region Data
func _on_file_dialog_file_selected(path):
	ScrobbleAnalyzer.year_range = years_array #Sets the year range
	var time_start = Time.get_unix_time_from_system()
	ScrobbleAnalyzer.raw_user_scrobble_data = load(path)
	print("Loaded file at %s seconds from path selected"%[Time.get_unix_time_from_system()-time_start])
	await ScrobbleAnalyzer.calculate_all()

func finished_reading_data():
	import_button.text = "Finished reading your data."
	%AnimationPlayer.play("finished_import")

func _on_file_type_invalid():
	import_button.text = "Invalid File!"
	await get_tree().create_timer(5.0).timeout
	import_button.text = "Import JSON"

func _on_corrupt_data():
	import_button.text = "Corrupt Data!"
	await get_tree().create_timer(5.0).timeout
	import_button.text = "Import JSON"

func _work_status(status:int):
	pass
#endregion
#region Start
func start_pressed():
	if not ScrobbleAnalyzer.raw_user_scrobble_data == null: #Has data
		get_tree().change_scene_to_packed(first_scene)
	else:
		start_button.text = "You need to import data!"
		await get_tree().create_timer(5.0).timeout
		start_button.text = "Start Rewind"
