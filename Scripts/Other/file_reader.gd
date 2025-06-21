extends Control
class_name DataParser

@export var raw_user_scrobble_data:JSON
@export var year_range:Array[int]

var scrobbles:Array[Scrobble] #All songs listened to
var song_listen_counts:Array #Also serves as number of songs uniquely listened to
var artist_listen_counts:Array #Also serves as number of artists uniquely listened to
var album_listen_counts:Array #also serves as number of albums uniquely listened to
var fully_listened_to_albums:Array #Better way of album_listen_counts
var listening_days:Array #Also serves as days uniquely listened to

var songs_in_albums:Dictionary #Tells us the songs in an album in the format album: [songuid,songuid]

var most_listened_to_song:Scrobble:
	get:
		var most_listened_to_song_uid:String = song_listen_counts[0][1]
		return get_song_from_uid(most_listened_to_song_uid)

var most_listened_to_song_listens:int:
	get:
		return song_listen_counts[0][0]

var most_listened_to_artist:String:
	get:
		return artist_listen_counts[0][1]

var most_listened_to_artist_listens:int:
	get:
		return artist_listen_counts[0][0]

var most_listened_to_day:StringName:
	get:
		return listening_days[0][1]

var songs_listened_on_most_listened_to_day:Array:
	get:
		return listening_days[0][0]

#region Calculation
func calculate_all():
	var time_start = Time.get_unix_time_from_system()
	await read_data()
	print("Read Data at %s seconds from file loaded"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(0)
	await calculate_number_of_listens_song()
	print("Number of Lstens by Song at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(1)
	await calculate_number_of_listens_artist()
	print("Number of listens by artist at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(2)
	await calculate_most_listened_to_days()
	print("most listened to days at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(3)
	await calculate_most_listened_to_albums()
	print("most listened to albums at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(4)
	await calculate_songs_in_album()
	print("calculate songs in albums at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(5)
	await calculate_fully_listened_to_albums()
	print("calculate fully listened to albums at %s seconds"%[Time.get_unix_time_from_system()-time_start])
	work_status.emit(6)

signal corrupt_data
signal invalid_file_type
signal finished_read_data
signal work_status(id:int)

func read_data():
	if not raw_user_scrobble_data is JSON: #User put some sketchy data in that isn't json
		invalid_file_type.emit()
		return
	if not raw_user_scrobble_data.data is Array: #Data must be wrong
		corrupt_data.emit()
		return 
	for page:Dictionary in raw_user_scrobble_data.data:
		if page.get("track",[]) == []:
			corrupt_data.emit()
			return
		for song:Dictionary in page["track"]:
			var new_scrobble = Scrobble.new()
			new_scrobble.title = song["name"]
			new_scrobble.icon_link = song["image"][3]["#text"] #gets back the XL Image
			new_scrobble.album = song["album"]["#text"]
			new_scrobble.artist = song["artist"]["#text"]
			if song.has("date"): #Safety check to ensure that we don't try adding a song that was currently being scrobbled
				new_scrobble.unix_time = song["date"]["uts"]
			else: #Song was being scrobbled at the time of the JSON being made
				new_scrobble.unix_time = page["track"][1]["date"]["uts"] #Just add the time of the previous song, because little inconsistencies don't matter.
			
			#If not part of current year, or year range, then just ignore it
			if year_range.has(new_scrobble.year):
				scrobbles.append(new_scrobble)
	
	finished_read_data.emit()
	
func calculate_number_of_listens_song():
	# Function to calculate the number of listens, completely sorted, so value [0][1] is the UID for the most listened to song.
	var number_of_listens:Dictionary
	for song in scrobbles:
		var song_uid = song.uid
		number_of_listens[song_uid] = number_of_listens.get(song_uid,0)+1 #adds +1 listen if the song exists, or sets it to 1 if it never existed in the dictionary.
	#for song in scrobbles:
		#number_of_listens[song.uid] = 0 #Populate by making them all 0 before we start checking
	#for song in scrobbles:
		#number_of_listens[song.uid] += 1 #Adds one count for every song.
	
	# Below line of code returns an array of from the number_of_listens dictionary, in the format int,uid so that we can sort it.
	var listen_count_pairs:Array = number_of_listens.keys().map(func(key): return [number_of_listens[key],key])
	
	# Returns array in decending order.
	listen_count_pairs.sort_custom(func(value1,value2): return value1>value2)
	song_listen_counts = listen_count_pairs

func calculate_number_of_listens_artist():
	var number_of_artist_listens:Dictionary
	for song in scrobbles:
		var artist = song.artist
		number_of_artist_listens[artist] = number_of_artist_listens.get(artist, 0) + 1
		
	#for song in scrobbles:
		#number_of_artist_listens[song.artist] = 0 #populate data
	#for song in scrobbles:
		#number_of_artist_listens[song.artist] += 1 #count
	
	var listen_count_pairs:Array = number_of_artist_listens.keys().map(func(key): return [number_of_artist_listens[key],key])
	
	listen_count_pairs.sort_custom(func(value1,value2): return value1>value2)
	artist_listen_counts = listen_count_pairs

func calculate_most_listened_to_days():
	# Dictionary stores date: [song1,song2]
	var songs_listened_on_day:Dictionary
	
	for song in scrobbles:
		var date = song.date
		if not songs_listened_on_day.has(date):
			songs_listened_on_day[date] = []
		else:
			songs_listened_on_day[date].append(song) #We have a list of all songs.
	
	# Makes an array that looks like [[song1, song2], date]
	var day_listen_pairs:Array = songs_listened_on_day.keys().map(func(key): return [songs_listened_on_day[key],key])
	
	# Sort by number of songs, which is in day_listen_pairs[0]
	day_listen_pairs.sort_custom(func(value1,value2): return value1[0].size()>value2[0].size())
	
	listening_days = day_listen_pairs

func calculate_most_listened_to_albums():
	var number_of_album_listens:Dictionary
	for song in scrobbles:
		var album = song.smart_album_name
		number_of_album_listens[album] = number_of_album_listens.get(album, 0) + 1
	var listen_count_pairs:Array = number_of_album_listens.keys().map(func(key): return [number_of_album_listens[key],key])
	
	listen_count_pairs.sort_custom(func(value1,value2): return value1>value2)
	album_listen_counts = listen_count_pairs

func calculate_songs_in_album():
	for song in song_listen_counts: #Use this instead of Scrobbles to only get unique entries.
		var uid:StringName = song[1]
		var smart_album = uid.split("|",true,1)[1]
		if not songs_in_albums.has(smart_album): 
			songs_in_albums[smart_album] = [uid]
		else:
			songs_in_albums[smart_album].append(uid)

func calculate_fully_listened_to_albums():
	for smart_album in songs_in_albums.keys():
		var number_of_times_album_has_been_fully_listened_to:int = 99999999 #Start by assuming that the entire album has been listened to infinite times
		var song_uids:Array = songs_in_albums[smart_album]
		for uid in song_uids:
			#Checks that the song UID matches and also if it is less than whatever value has been set previously
			for song in song_listen_counts:
				if song[1] == uid and song[0] < number_of_times_album_has_been_fully_listened_to:
					number_of_times_album_has_been_fully_listened_to = song[0]
		if not songs_in_albums[smart_album].size() == 1:
			fully_listened_to_albums.append([number_of_times_album_has_been_fully_listened_to,smart_album])
	
	#Sort it
	fully_listened_to_albums.sort_custom(func(value1,value2): return value1[0]>value2[0])
#endregion

#region Lists
func list_of_most_listened_to_songs(count:int):
	var list_most_listened_to_songs:Array
	for number in count:
		list_most_listened_to_songs.append(song_listen_counts[number][1])
	return list_most_listened_to_songs

func list_of_most_listened_to_songs_times(count:int):
	var list_most_listened_to_songs:Array
	for number in count:
		list_most_listened_to_songs.append(song_listen_counts[number][0])
	return list_most_listened_to_songs

func list_of_most_listened_to_artists(count:int):
	var list_most_listened_to_artists:Array
	for number in count:
		list_most_listened_to_artists.append(artist_listen_counts[number][1])
	return list_most_listened_to_artists

func list_of_most_listened_to_artists_times(count:int):
	var list_most_listened_to_artists:Array
	for number in count:
		list_most_listened_to_artists.append(artist_listen_counts[number][0])
	return list_most_listened_to_artists

func list_of_most_listened_to_albums(count:int):
	var list_most_listened_to_albums:Array
	for number in count:
		list_most_listened_to_albums.append(album_listen_counts[number][1])
	return list_most_listened_to_albums
	
func list_of_most_listened_to_albums_times(count:int):
	var list_most_listened_to_albums:Array
	for number in count:

		list_most_listened_to_albums.append(album_listen_counts[number][0])
	return list_most_listened_to_albums

#endregion
func check_uid(uid1:String,uid2:String)->bool:
	# Function returns true if inputUID = input2UID
	return uid1==uid2

func get_song_from_uid(uid:StringName):
	for song in scrobbles:
		if song.uid == uid:
			return song
	push_error("UID not found!")
	return

func get_song_from_album(smart_album:String):
	for song in scrobbles:
		if song.uid.split("|",true,1)[1] == smart_album:
			return song

func get_album_from_smart_album(smart_album:String):
	return smart_album.get_slice("|",0)

func fetch_image(url:String,path:String = "user://image.jpeg") -> ImageTexture:
	if get_node_or_null("HTTPRequest") == null:
		add_child(HTTPRequest.new(),true)
	$HTTPRequest.download_file = path
	$HTTPRequest.request(url)
	await $HTTPRequest.request_completed
	var image = Image.new()
	var error = image.load(path)
	if error == OK:
		return ImageTexture.create_from_image(image)
	else:
		return
