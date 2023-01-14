extends AudioStreamPlayer


func _ready():
	var _err = connect("finished", self, "queue_free")
