extends Control

@export var debug:bool

var replacements = {
	"most_listened_to_song_listens" : ScrobbleAnalyzer.most_listened_to_song_listens,
	"most_listened_to_day" : ScrobbleAnalyzer.most_listened_to_day,
	"most_listened_to_month" : ScrobbleAnalyzer.most_listened_to_month_name,
	"most_listened_to_month_count" : ScrobbleAnalyzer.most_listened_to_month_count,
	"most_listened_to_artist_name" : ScrobbleAnalyzer.most_listened_to_artist,
	"most_listened_to_artist_listens" : ScrobbleAnalyzer.most_listened_to_artist_listens,
	"most_listened_to_song_name": ScrobbleAnalyzer.most_listened_to_song.title,
	"most_listened_to_song_album" : ScrobbleAnalyzer.most_listened_to_song.album,
	"most_listened_to_song_artist" : ScrobbleAnalyzer.most_listened_to_song.artist,
	"most_listened_to_song_icon_url" : ScrobbleAnalyzer.most_listened_to_song.icon_link,
}

@export var labels_to_replace_in:Array[Label]
@export var rtl_to_replace_in:Array[RichTextLabel]
@export var icons_to_replace:Array[TextureRect]

func _ready() -> void:
	if labels_to_replace_in: for label in labels_to_replace_in: label.text = label.text.format(replacements)
	if rtl_to_replace_in: for rtl in rtl_to_replace_in: rtl.text = rtl.text.format(replacements)
	# Fetches the image based on the name of the icon used as a shortcode
	if icons_to_replace: for icon in icons_to_replace: icon.texture = await ScrobbleAnalyzer.fetch_image(("{%s}"%icon.name).format(replacements))
