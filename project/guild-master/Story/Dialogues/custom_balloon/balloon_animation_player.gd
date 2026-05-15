extends AnimationPlayer

func _ready():
	animation_finished.connect(_animation_finished)
	
func _animation_finished(anim_name:StringName):
	print(anim_name)
	play("scg/after_appearance")
