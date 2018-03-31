extends KinematicBody2D

signal died
signal hit

export (int) var health = 10
export (int) var gravity

enum {IDLE, JUMP}

var velocity = Vector2()
var state

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	change_state(IDLE)
	$JumpTimer.wait_time = rand_range(3,10)
	add_to_group("enemies") #this is an enemie, add it to the enemies group

func change_state(new_state):
	state = new_state
	
#this thing runs by itself!

func _process(delta):
	print(str(health))
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	# we probably only want to initiate a jump if the enemy is_on_floor() == true
	pass
	

func _physics_process(delta):
	velocity.y += gravity * delta
	if state == JUMP:
		if is_on_floor():
			change_state(IDLE)
			$JumpTimer.wait_time = rand_range(3,10)
			$JumpTimer.start()
	velocity = move_and_slide(velocity, Vector2(0,-1))


func _on_Timer_timeout():
	$JumpTimer.stop()
	change_state(JUMP)
	velocity.y = rand_range(-200,-100)
	
func _takeDamage(damage):
	print("_takeDamage")
	emit_signal("hit")
	health -= damage
	if health <= 0:
		emit_signal("died")
		queue_free()
		
