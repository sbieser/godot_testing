extends KinematicBody2D

#if anything outside of this class needs to know if the player was hit, it could connect to this
signal hit

#export (int) var walk_speed

export (int) var jump_speed = -200
export (int) var gravity = 500
export (int) var run_speed = 100
export (int) var walk_speed = 85

#TODO: We need to have states to show which direction the player is facing, left or right
enum {IDLE, JUMP, ATTACK, WALK, CROUCH_IDLE, CROUCH_WALK, CROUCH_ATTACK}
enum {RIGHT_FACING, LEFT_FACING}
var velocity = Vector2()
var state
var facing
var anim
var new_anim

var hit_bodies = [] #array of bodies bit by the current attack

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	$AttackArea.visible = false
	facing = RIGHT_FACING
	change_state(IDLE)

func change_direction():
	if velocity.x < 0:
		facing = LEFT_FACING
	else:
		facing = RIGHT_FACING

func change_state(new_state):
	if new_state != state:
		state = new_state
		match state:
			IDLE:
				new_anim = "idle"
			CROUCH_IDLE:
				new_anim = "crouch"
			WALK:
				new_anim = "walk"
			CROUCH_WALK:
				new_anim = "crouch_walk"
			ATTACK:
				new_anim = "attack"
				$AttackArea.visible = true
				get_node("AttackArea/AttackTimer").start()
			CROUCH_ATTACK:
				new_anim = "crouch_attack"
				$AttackArea.visible = true
				get_node("AttackArea/AttackTimer").start()
			JUMP:
				new_anim = "jump"
	
	if state == WALK or state == CROUCH_WALK:
		change_direction()
	
	#change player size based on standing or crouching
	if state == CROUCH_IDLE or state == CROUCH_WALK or state == CROUCH_ATTACK:
		$CollisionShape2D.shape.set_extents(Vector2(16,16))
		$CollisionShape2D.position = Vector2(0,16)
		$AnimatedSprite.position = Vector2(0,16)
	else:
		$CollisionShape2D.shape.set_extents(Vector2(16,32))
		$CollisionShape2D.position = Vector2(0,0)
		$AnimatedSprite.position = Vector2(0,0)
	
	if facing == LEFT_FACING:
		$AnimatedSprite.flip_h = true
		if state == CROUCH_WALK or state == CROUCH_IDLE or state == CROUCH_ATTACK:
			get_node("AttackArea/CollisionShape2D").position = Vector2(-33,16)
		else:
			get_node("AttackArea/CollisionShape2D").position = Vector2(-33,-16)
	else:
		$AnimatedSprite.flip_h = false
		if state == CROUCH_WALK or state == CROUCH_IDLE or state == CROUCH_ATTACK:
			get_node("AttackArea/CollisionShape2D").position = Vector2(33,16)
		else:
			get_node("AttackArea/CollisionShape2D").position = Vector2(33,-16)
	
	#$AttackArea.visible = false
	#state = new_state
	#match state:
#		IDLE:
#			new_anim = "idle"
#			crouching = false
#			attacking = false
#		ATTACK:
#			if crouching:
#				new_anim = "crouch_attack"
#			else:
#				new_anim = "attack"
#			attacking = true
#			$AttackArea.visible = true
#			get_node("AttackArea/AttackTimer").start()
#		WALK:
#			new_anim = "walk"
#			crouching = false
#			change_direction()
#		CROUCH:
#			new_anim = "crouch"     
#			crouching = true
#		CROUCH_WALK:
#			new_anim = "crouch_walk"
#			crouching = true
#			change_direction()
#		STUNNED:
#			#some stunned animation or something should play
#			pass
#		STUNNED_IDLE:
#			velocity.x = 0
#			$StunIdleTimer.start()
#		RUN:
#			new_anim = "run"
#			change_direction()
#		ROLL:
#			new_anim = "roll"
#			$RollTimer.start()
#			change_direction()
#	
#	if crouching == true:
#		$CollisionShape2D.shape.set_extents(Vector2(16,16))
#		$CollisionShape2D.position = Vector2(0,16)
#		$AnimatedSprite.position = Vector2(0,16)
#	else:
#		$CollisionShape2D.shape.set_extents(Vector2(16,32))
#		$CollisionShape2D.position = Vector2(0,0)
#		$AnimatedSprite.position = Vector2(0,0)

func handle_horizontal_movement():
	var right = Input.is_action_pressed("ui_right") #movement right
	var left = Input.is_action_pressed("ui_left") # movement left
	var down = Input.is_action_pressed("ui_down") # crouch button
	
	var cur_speed = walk_speed
	if down:
		cur_speed = walk_speed / 2
	if right:
		velocity.x += cur_speed
	if left:
		velocity.x -= cur_speed

func handle_action():
	pass
	
	
func print_state():
	#enum {IDLE, JUMP, ATTACK, WALK, CROUCH_IDLE, CROUCH_WALK, CROUCH_ATTACK}
	match state:
		IDLE:
			print("IDLE")
		JUMP:
			print("JUMP")
		ATTACK:
			print("ATTACK")
		WALK:
			print("WALK")
		CROUCH_IDLE:
			print("CROUCH_IDLE")
		CROUCH_WALK:
			print("CROUCH_WALK")
		CROUCH_ATTACK:
			print("CROUCH_ATTAK")

func handle_input():
	print_state()
	
	if state == ATTACK or state == CROUCH_ATTACK:
		return
	
	#Left/Right - Move
	#Up         - Look up / Climb
	#Down       - Look down / Crouch / Climb / Run (If down-for-running is enabled)
	#X          - Action
	#Z          - Jump
	var right = Input.is_action_pressed("ui_right") #movement right
	var left = Input.is_action_pressed("ui_left") # movement left
	var down = Input.is_action_pressed("ui_down") # crouch button
	var x = Input.is_action_pressed("ui_x") # action / attack button
	var z = Input.is_action_pressed("ui_z") # jump button
	
	#set velocity to 0 initially
	velocity.x = 0
	handle_horizontal_movement() #find horizontal movememnt through left and right inputs
	
	match state:
		IDLE:
			if velocity.x != 0:
				change_state(WALK)
			elif z and is_on_floor():
				velocity.y = jump_speed
				change_state(JUMP)
			elif down:
				change_state(CROUCH_IDLE)
			elif x:
				change_state(ATTACK)
		CROUCH_IDLE:
			if velocity.x != 0:
				change_state(CROUCH_WALK)
			elif x:
				change_state(CROUCH_ATTACK)
			elif z and is_on_floor():
				velocity.y = jump_speed
				change_state(JUMP)
			elif not down:
				if velocity.x != 0:
					change_state(WALK)
				else:
					change_state(IDLE)
		CROUCH_WALK:
			if not down:
				if velocity.x != 0:
					change_state(WALK)
				else:
					change_state(IDLE)
			elif velocity.x == 0:
				change_state(CROUCH_IDLE)
			elif z and is_on_floor():
				velocity.y = jump_speed
				change_state(JUMP)
		WALK:
			if down:
				if velocity.x != 0:
					change_state(CROUCH_WALK)
				else:
					change_state(CROUCH_IDLE)
			elif z and is_on_floor():
				velocity.y = jump_speed
				change_state(JUMP)
			elif velocity.x == 0:
				change_state(IDLE)
		JUMP:
			pass
		ATTACK:
			pass
	
func _process(delta):
	handle_input()
	if new_anim != anim:
		anim = new_anim
		$AnimatedSprite.play(anim)
	
func _physics_process(delta):
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0,-1))
	
	match state:
		JUMP:
			if is_on_floor():
				if velocity.x != 0:
					change_state(WALK)
				else:
					change_state(IDLE)
	
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
	
func _on_AttackTimer_timeout():
	#hit_bodies.clear()
	get_node("AttackArea/AttackTimer").stop()
	$AttackArea.visible = false
	change_state(IDLE)


#func _on_StunTimer_timeout():
#	#pass # replace with function body
#	$StunIdleTimer.stop()
#	change_state(IDLE)
		
#func get_input():
#	if attacking || state == STUNNED || state == STUNNED_IDLE:
#		return
#
#	velocity.x = 0
#	var right = Input.is_action_pressed("ui_right")
#	var left = Input.is_action_pressed("ui_left")
#	var jump = Input.is_action_just_pressed("ui_select")
#	var attack = Input.is_action_just_pressed("ui_attack")
#	var down = Input.is_action_pressed("ui_down")
#	var run = Input.is_action_pressed("ui_run")
#	var block = Input.is_action_pressed("ui_block")
#
#	if not attacking and attack:
#		change_state(ATTACK)
#		return
#
#	if attack:
#		change_state(ATTACK)
#		return
#	if jump and is_on_floor():
#		change_state(JUMP)
#		velocity.y = jump_speed
#
#	var speed = walk_speed
#	if run:
#		speed = run_speed
#
#	if right:
#		velocity.x += speed
#	if left:
#		velocity.x -= speed
#
#	if down:
#		if velocity.x != 0:
#			change_state(CROUCH_WALK)
#		else:
#			change_state(CROUCH)
#	elif velocity.x != 0:
#		if run and is_on_floor():
#			if state != RUN and state != ROLL:
#				change_state(ROLL)
#		else:
#			change_state(WALK)
#	elif state == WALK or state == CROUCH or state == CROUCH_WALK or state == RUN:
#		change_state(IDLE)
