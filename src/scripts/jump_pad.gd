extends Area2D

func _on_body_entered(body):
	print(owner.name)
	if owner.has_method("boost_up"):
		owner.boost_up()
