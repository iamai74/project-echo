class_name Actor
extends CharacterBody2D

@export var data: ActorData

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var facing_direction: int = 1
var coyote_timer: float = 0.0
var jump_count: int = 0


func _ready():
	_initialize_components()
	_connect_signals()
	_setup_state_machine()

func _setup_state_machine():
	for state in state_machine.get_children():
		if state is State:
			state.actor = self

func _physics_process(delta: float) -> void:
	_update_coyote_timer(delta)
	_apply_gravity(delta)

	state_machine.physics_update(delta)

	move_and_slide()
	_update_facing_direction()

func _initialize_components():
	health.initialize(data.max_health)

func _connect_signals():
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	
func _on_hit_received(attack: AttackData):
	health.take_damage(attack.damage)
	print(name, " received ", attack.damage, " damage")
	if attack.knockback_force > 0:
		velocity += attack.direction * attack.knockback_force

func _on_died():
	die()

func die():
	queue_free()

func move(direction: float):
	velocity.x = (direction *data.move_speed)

func jump() -> void:
	velocity.y = data.jump_velocity

func _update_coyote_timer(delta: float) -> void:
	if is_on_floor():
		coyote_timer = data.coyote_time
		jump_count = data.max_jumps
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += data.gravity * delta

func _update_facing_direction() -> void:
	if velocity.x != 0:
		facing_direction = sign(velocity.x)
		if sprite:
			sprite.flip_h = (facing_direction == -1)
