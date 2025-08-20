extends ScrollContainer
class_name AutoScrollContainer

@export var horizontal_scroll_time:float

func begin_scroll():
	var tween:Tween = create_tween()
	if horizontal_scroll_time: tween.tween_property(self, "scroll_horizontal", self.get_h_scroll_bar().max_value, horizontal_scroll_time)
