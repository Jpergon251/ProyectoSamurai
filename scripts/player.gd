extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attacking_collision = $AttackArea/AttackingCollision



const SPEED = 125.0
const JUMP_VELOCITY = -350.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var attacking = false


func _ready():
	# Conectar la señal `animation_finished` a la función `_on_animated_sprite_2d_animation_finished`.
	animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	
	# Ocultar el cursor al iniciar el juego.
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	

func _process(delta):
	# Detectar la pulsación de la tecla Escape.
	if Input.is_action_just_pressed("ui_cancel"):  # "ui_cancel" es la acción por defecto para Escape.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("enterMouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = Input.get_axis("left", "right")
	
	# Flip the Sprite.
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		
	# Play appropriate animation.
	if is_on_floor() and not attacking:
		if direction == 0:
			animated_sprite_2d.play("Idle")
		else:
			animated_sprite_2d.play("Run")
	elif not is_on_floor() and not attacking:
		animated_sprite_2d.play("Jump")
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not attacking:
		velocity.y = JUMP_VELOCITY

	# Handle attack.
	if Input.is_action_just_pressed("attack") and is_on_floor() and not attacking:
		velocity.x = 0
		attacking = true
		attacking_collision.disabled = false
		animated_sprite_2d.play("Attack")
	
	# Handle movement.
	if not attacking:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	# Establecer `attacking` a `false` solo si la animación de ataque ha terminado.
	if animated_sprite_2d.animation == "Attack":
		attacking = false
		attacking_collision.disabled = true



func _on_area_2d_body_entered(body):
	if body.name == "Enemy":
		body.take_damage(10)  # Llama a la función take_damage en el enemigo
