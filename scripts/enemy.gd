extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var ray_cast_2d_right = $RayCast2DRight
@onready var ray_cast_2d_left = $RayCast2DLeft

@export var speed: float = 40.0
@export var patrol_distance: float = 100.0  # Distancia que el enemigo recorre antes de detenerse.
@export var attack_range: float = 100.0  # Distancia de ataque
@export var blink_time: float = 0.1  # Tiempo de parpadeo al morir

enum State {
	IDLE,
	WALKING,
	ATTACKING,
	HURT,
	DEAD
}

var current_state = State.WALKING  # Estado inicial del enemigo
var target_position: Vector2
var direction = 1  # 1 para la derecha, -1 para la izquierda.
var idle_timer: float = 0.0  # Temporizador para controlar el estado idle

var health = 100  # Salud inicial del enemigo

func _ready():
	# Define la posición inicial del objetivo.
	target_position = global_position + Vector2(direction * patrol_distance, 0)
	animated_sprite.play("Walk")

func _physics_process(delta):
	# Comprobar si el jugador está en rango para atacar.
	if current_state != State.ATTACKING and current_state != State.HURT and current_state != State.DEAD:
		check_for_player()

	# Mover al personaje hacia el punto objetivo si no está atacando.
	if current_state == State.WALKING:
		move_towards_target(delta)

	# Comprobar si hay un obstáculo.
	if current_state != State.ATTACKING and current_state != State.HURT and current_state != State.DEAD:
		check_for_obstacles()

	# Aplicar el movimiento.
	move_and_slide()

func move_towards_target(delta: float):
	var direction_vector = (target_position - global_position).normalized()
	velocity.x = direction_vector.x * speed

	# Cambiar la animación a 'Idle' si el personaje ha llegado al punto objetivo.
	if global_position.distance_to(target_position) < 10.0:  # Aumentar el límite de distancia
		velocity.x = 0
		animated_sprite.play("Idle")
		idle_timer += delta

		if idle_timer >= 1.0:  # Esperar un segundo antes de cambiar
			change_direction()
			idle_timer = 0.0  # Reiniciar el temporizador

	# Cambiar el flip del sprite según la dirección.
	animated_sprite.flip_h = direction < 0

func change_direction():
	print("Cambiando direccion. Dirección anterior: ", direction)

	# Cambiar la dirección (-1 si era 1, 1 si era -1).
	direction *= -1
	# Activar el raycast correspondiente según la dirección.
	ray_cast_2d_left.enabled = direction < 0
	ray_cast_2d_right.enabled = direction > 0
	
	# Actualizar la posición objetivo para moverse en la nueva dirección.
	target_position = global_position + Vector2(direction * patrol_distance, 0)
	animated_sprite.play("Walk")

func check_for_obstacles():
	# Comprobar colisiones con el límite del mundo (o puedes usar otro método para esto).
	if ray_cast_2d_left.is_colliding():
		print("Obstáculo detectado a la izquierda. Cambiando de dirección.")
		change_direction()
		
	if ray_cast_2d_right.is_colliding():
		print("Obstáculo detectado a la derecha. Cambiando de dirección.")
		change_direction()

func check_for_player():
	# Aquí puedes usar una distancia para comprobar si el jugador está cerca.
	var player = get_parent().get_node("Player")  # Asegúrate de que la ruta sea correcta
	if global_position.distance_to(player.global_position) < attack_range:
		attack()

func attack():
	# Cambiar a la animación de ataque y establecer el estado de ataque
	current_state = State.ATTACKING
	animated_sprite.play("Attack")
	
	# Desactivar el movimiento
	velocity.x = 0
	
	# Lógica para infligir daño al jugador podría ir aquí (ejemplo).
	# Si deseas infligir daño solo si el jugador está en contacto, usa el área de ataque.
	await get_tree().create_timer(1.0).timeout  # Esperar el tiempo de la animación
	current_state = State.WALKING  # Volver al estado de caminar

func take_damage(amount: int):
	if current_state == State.DEAD:
		return  # No hacer nada si el enemigo ya está muerto

	health -= amount
	print("Enemy took damage! Current health: ", health)

	animated_sprite.play("WhiteHit")  # Reproducir la animación de daño
	current_state = State.HURT  # Cambiar al estado de herido

	# Esperar un momento en el estado de herido
	await get_tree().create_timer(0.5).timeout  # Espera un tiempo corto
	current_state = State.WALKING  # Volver al estado de caminar si está vivo

	if health <= 0:
		die()
		
func die():
	print("Enemy died")
	animated_sprite.play("Death")  # Reproducir la animación de muerte
	current_state = State.DEAD  # Cambiar al estado de muerto
	await get_tree().create_timer(1.0).timeout  # Esperar un tiempo para parpadeo

	# Parpadeo antes de eliminar el enemigo
	for i in range(5):  # Número de parpadeos
		visible = !visible
		await get_tree().create_timer(blink_time).timeout
	queue_free()  # Eliminar el enemigo de la escena
