class_name Actor
extends CharacterBody2D

@export var data: ActorData

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready():
	_initialize_components()
	_connect_signals()

func _initialize_components():
	health.initialize(data.max_health)
	hurtbox.health_component = health

func _connect_signals():
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	hurtbox.knockback_requested.connect(_on_knockback_requested)
	
func _on_hit_received(attack: AttackData):
	print(name, " received ", attack.damage, " damage")
	
func _on_knockback_requested(force: Vector2):
	velocity += force

func _on_died():
	die()

func die():
	queue_free()

func move(direction: float):
	velocity.x = (direction *data.move_speed)
