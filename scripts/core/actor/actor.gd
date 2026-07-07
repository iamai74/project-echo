class_name Actor
extends CharacterBody2D

@export var data: ActorData

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var weapon_component: WeaponComponent = get_node_or_null("WeaponComponent")

var facing_direction: Vector2 = Vector2.RIGHT
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
	health.take_damage(attack)
	_knockback_reaction(attack)
	if not health.is_alive():
		return
	state_machine.start("Hurt")

func _on_died():
	state_machine.start("Dead")

func die():
	queue_free()

func move(direction: float):
	velocity.x = (direction *data.move_speed)

func jump() -> void:
	velocity.y = data.jump_velocity
	
func attack(type: AttackType.Type) -> void:
	if weapon_component:
		weapon_component.start_attack(type)
	
func light_attack() -> void:
	if weapon_component:
		attack(AttackType.Type.LIGHT)
	
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
		facing_direction = Vector2(velocity.x, 0)
		if sprite:
			sprite.flip_h = (sign(velocity.x) == -1)
			
func _knockback_reaction(attack: AttackData) -> void:
	if attack.knockback_force > 0:
		velocity += attack.direction * attack.knockback_force

func set_invulnerable(value: bool) -> void:
	hurtbox.set_invulnerable(value)
