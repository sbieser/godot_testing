extends KinematicBody2D

#if anything outside of this class needs to know if the player was hit, it could connect to this
signal hit

#export (int) var walk_speed

export (int) var jump_speed = -200
export (int) var gravity = 500
export (int) var run_speed = 100
export (int) var walk_speed = 85

#TODO: We need to have states to show which direction the player is facing, left or right
enum {IDLE, JUMP, ATTACK, WALK, ROLL, RUN, CROUCH, CROUCH_WALK, STUNNED, STUNNED_IDLE}
enum {RIGHT_FACING, LEFT_FACING}
var velocity = Vector2()
var state
var facing
var crouching
var attacking = false
var anim
var new_anim

var hit_bodies = [] #array of bodies bit by the current attack


#new better variables?
#var prev_velocity #not working very well, will have to come back to this
var cur_speed

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	facing = RIGHT_FACING
	$AttackArea.visible = false
	crouching = false
	change_state(IDLE)

func change_direction():
	if velocity.x < 0:
		facing = LEFT_FACING
	else:
		facing = RIGHT_FACING

func change_state(new_state):
	#print(str(new_state))
	$AttackArea.visible = false
	state = new_state
	match state:
		IDLE:
			new_anim = "idle"
			crouching = false
			attacking = false
		ATTACK:
			if crouching:
				new_anim = "crouch_attack"
			else:
				new_anim = "attack"
			attacking = true
			$AttackArea.visible = true
			get_node("AttackArea/AttackTimer").start()
		WALK:
			new_anim = "walk"
			crouching = false
			change_direction()
		CROUCH:
			new_anim = "crouch"     
			crouching = true
		CROUCH_WALK:
			new_anim = "crouch_walk"
			crouching = true
			change_direction()
		STUNNED:
			#some stunned animation or something should play
			pass
		STUNNED_IDLE:
			velocity.x = 0
			$StunIdleTimer.start()
		RUN:
			new_anim = "run"
			change_direction()
		ROLL:
			new_anim = "roll"
			$RollTimer.start()
			change_direction()
	
	if crouching == true:
		$CollisionShape2D.shape.set_extents(Vector2(16,16))
		$CollisionShape2D.position = Vector2(0,16)
		$AnimatedSprite.position = Vector2(0,16)
	else:
		$CollisionShape2D.shape.set_extents(Vector2(16,32))
		$CollisionShape2D.position = Vector2(0,0)
		$AnimatedSprite.position = Vector2(0,0)
	
	if facing == LEFT_FACING:
		$AnimatedSprite.flip_h = true
		if crouching:
			get_node("AttackArea/CollisionShape2D").position = Vector2(-33,16)
		else:
			get_node("AttackArea/CollisionShape2D").position = Vector2(-33,-16)
	else:
		$AnimatedSprite.flip_h = false
		if crouching:
			get_node("AttackArea/CollisionShape2D").position = Vector2(33,16)
		else:
			get_node("AttackArea/CollisionShape2D").position = Vector2(33,-16)
			




func handle_input():
	print(str(state))
	#set velocity to 0 initially
	velocity.x = 0
	
	#Left/Right - Move
	#Up         - Look up / Climb
	#Down       - Look down / Crouch / Climb / Run (If down-for-running is enabled)
	#X          - Action
	#Z          - Jump
	#C          - Cycle held item, Bombs, Rope
	#Shift      - Run
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")
	var x = Input.is_action_pressed("ui_x") # 
	var z = Input.is_action_pressed("ui_z") # a button for run
	var shift = Input.is_action_pressed("ui_shift")
	
	match state:
		IDLE:
			if right:
				velocity.x += cur_speed
				state = WALK
				#change_direction()
				#change_state(WALK)
			if left:
				velocity.x -= cur_speed
				state = WALK
				#change_direction()
				#change_state(WALK)
			if z:
				state = JUMP 
				velocity.y = jump_speed
		WALK:
			if shift:
				state = RUN
				#continue
			if right:
				velocity.x += cur_speed
			if left:
				velocity.x -= cur_speed
			if z:
				state = JUMP
				velocity.y = jump_speed
			if velocity.x == 0:
				state = IDLE
		JUMP:
			if right:
				velocity.x += cur_speed
			elif left:
				velocity.x -= cur_speed
		RUN:
			if right:
				velocity.x += cur_speed
			if left:
				velocity.x -= cur_speed
			if !shift:
				#state = WALK
				if velocity.x != 0:
					state = WALK
				else:
					state = IDLE
			if z:
				state = JUMP
				velocity.y = jump_speed
	
func get_input():
	if attacking || state == STUNNED || state == STUNNED_IDLE:
		return
	
	velocity.x = 0
	var right = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")
	var jump = Input.is_action_just_pressed("ui_select")
	var attack = Input.is_action_just_pressed("ui_attack")
	var down = Input.is_action_pressed("ui_down")
	var run = Input.is_action_pressed("ui_run")
	var block = Input.is_action_pressed("ui_block")
	
	if not attacking and attack:
		change_state(ATTACK)
		return
		
	if attack:
		change_state(ATTACK)
		return
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	
	var speed = walk_speed
	if run:
		speed = run_speed
	
	if right:
		velocity.x += speed
	if left:
		velocity.x -= speed
	
	if down:
		if velocity.x != 0:
			change_state(CROUCH_WALK)
		else:
			change_state(CROUCH)
	elif velocity.x != 0:
		if run and is_on_floor():
			if state != RUN and state != ROLL:
				change_state(ROLL)
		else:
			change_state(WALK)
	elif state == WALK or state == CROUCH or state == CROUCH_WALK or state == RUN:
		change_state(IDLE)
	
func handle_speed():
	var shift = Input.is_action_pressed("ui_shift")
	
	if shift:
		cur_speed = run_speed
	else:
		cur_speed = walk_speed
	
func _process(delta):
	#get_input()
	handle_speed()
	handle_input()
	if new_anim != anim:
		anim = new_anim
		$AnimatedSprite.play(anim)
	
func _physics_process(delta):
	velocity.y += gravity * delta
	
	match state:
		JUMP:
			if is_on_floor():
				state = IDLE
	
	#if attacking:
	#	var bodies = $AttackArea.get_overlapping_bodies()
	#	for body in bodies:
	#		if body.is_in_group("enemies") and not hit_bodies.has(body):
	#			hit_bodies.append(body)
	#			body._takeDamage(5)
	#
	#velocity.y += gravity * delta
	#if state == JUMP:
	#	if is_on_floor():
	#		change_state(IDLE)
	#
	#trigger the stun timer when the player has hit the floor
	#if state == STUNNED:
	#	if is_on_floor():
	#		change_state(STUNNED_IDLE)
	#		#$StunIdleTimer.start()
	#	
	#var collision_count = get_slide_count()
	#if collision_count > 0:
	#	for i in range(collision_count):
	#		var collision = get_slide_collision(i)
	#		if collision.collider.is_in_group("enemies"):
	#			change_state(STUNNED)
	#			#print("we have been hit by: " + collision.collider.name)
	#			velocity.y = jump_speed
	#			velocity.x = -velocity.x
	#			
	velocity = move_and_slide(velocity, Vector2(0,-1))
	
func _on_AttackTimer_timeout():
	hit_bodies.clear()
	get_node("AttackArea/AttackTimer").stop()
	change_state(IDLE)

func _on_StunTimer_timeout():
	#pass # replace with function body
	$StunIdleTimer.stop()
	change_state(IDLE)

func _on_RollTimer_timeout():
	#pass # replace with function body
	print("_on_RollTimer_timeout")
	$RollTimer.stop()
	change_state(RUN)
