extends Resource
class_name Scrobble
## An object that can store all the required data for a scrobble.

@export var title:String
@export var icon_link:String
@export var album:String
@export var artist:String
@export var unix_time:int
var smart_album_name:
	get:
		return "%s|%s"%[album,artist]
var month:int:
	get:
		return Time.get_datetime_dict_from_unix_time(unix_time)["month"]
var year:int:
	get:
		return Time.get_datetime_dict_from_unix_time(unix_time)["year"]
var day:int:
	get:
		return Time.get_datetime_dict_from_unix_time(unix_time)["day"]
var date:StringName:
	get:
		return &"%s-%s-%s"%[str(year),str(month),str(day)]

var uid:StringName:
	get:
		return "%s|%s|%s"%[title,album,artist]
