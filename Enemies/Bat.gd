extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var acceleration = 300
export var max_speed = 50
export var friction = 200
export var wander_target_range = 4

enum { IDLE, WANDER, CHASE }

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var state = IDLE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var player_detection_zone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController
onready var animation_player = $AnimationPlayer


func _ready():
	state = pick_random_state([IDLE, WANDER])


func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, friction * delta)
	knockback = move_and_slide(knockback)

	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()

		WANDER:
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander()

			accelerate_towards_point(wander_controller.target_position, delta)

			if global_position.distance_to(wander_controller.target_position) <= wander_target_range:
				update_wander()

		CHASE:
			var player = player_detection_zone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE

	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 400

	velocity = move_and_slide(velocity)


func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	sprite.flip_h = velocity.x < 0


func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wander_controller.start_wander_timer(rand_range(1, 3))


func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE


func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)


func _on_Stats_no_health():
	queue_free()
	var enemy_death_effect = EnemyDeathEffect.instance()
	get_parent().add_child(enemy_death_effect)
	enemy_death_effect.global_position = global_position


func _on_Hurtbox_invincibility_started():
	animation_player.play("Start")
	

func _on_Hurtbox_invincibility_ended():
	animation_player.play("Stop")
