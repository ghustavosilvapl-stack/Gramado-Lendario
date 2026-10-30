extends Node3D

const FIELD_X := 34.0
const FIELD_Z := 54.0
var player: CharacterBody3D
var ball: RigidBody3D
var camera: Camera3D
var hud: CanvasLayer
var score_home := 0
var score_away := 0
var seconds := 0.0
var match_time := 0.0
var move_touch := Vector2.ZERO
var pass_requested := false
var shoot_requested := false
var quality_high := true
var opponent: CharacterBody3D
var teammates: Array[CharacterBody3D] = []
var enemies: Array[CharacterBody3D] = []
var score_label: Label
var message_label: Label

func _ready() -> void:
	build_stadium()
	build_players()
	build_ball()
	build_camera()
	build_hud()
	set_quality(true)

func mat(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node

func build_stadium() -> void:
	var grass := mat(Color(0.075, 0.38, 0.16))
	var line := mat(Color(0.92, 0.95, 0.88))
	var dark := mat(Color(0.10, 0.12, 0.14))
	var stand := mat(Color(0.20, 0.24, 0.29))
	box(self, Vector3(FIELD_X, 0.3, FIELD_Z), Vector3(0, -0.2, 0), grass)
	box(self, Vector3(FIELD_X, 0.035, 0.12), Vector3(0, -0.025, 0), line)
	box(self, Vector3(0.12, 0.035, FIELD_Z), Vector3(-FIELD_X/2, -0.025, 0), line)
	box(self, Vector3(0.12, 0.035, FIELD_Z), Vector3(FIELD_X/2, -0.025, 0), line)
	box(self, Vector3(FIELD_X, 0.035, 0.12), Vector3(0, -0.025, -FIELD_Z/2), line)
	box(self, Vector3(FIELD_X, 0.035, 0.12), Vector3(0, -0.025, FIELD_Z/2), line)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 9.0
	torus.outer_radius = 9.12
	ring.mesh = torus
	ring.material_override = line
	ring.position.y = 0.0
	add_child(ring)
	box(self, Vector3(16, 0.035, 0.12), Vector3(0, -0.02, -FIELD_Z/2+11), line)
	box(self, Vector3(16, 0.035, 0.12), Vector3(0, -0.02, FIELD_Z/2-11), line)
	for side in [-1, 1]:
		box(self, Vector3(FIELD_X+10, 5, 5), Vector3(0, 2.2, side*32), stand)
		box(self, Vector3(5, 5, FIELD_Z+10), Vector3(side*22, 2.2, 0), stand)
		box(self, Vector3(3.2, 2.5, 0.25), Vector3(0, 1.25, side*FIELD_Z/2), mat(Color(0.88,0.88,0.82)))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.65,0.72,0.82)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)

func make_player(pos: Vector3, color: Color, is_user := false) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.position = pos
	body.floor_snap_length = 0.4
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = 0.95
	body.add_child(shape)
	var torso := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.48
	cm.height = 1.9
	torso.mesh = cm
	torso.material_override = mat(color)
	torso.position.y = 0.95
	body.add_child(torso)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	head.mesh = sm
	head.material_override = mat(Color(0.72,0.52,0.38))
	head.position.y = 2.0
	body.add_child(head)
	add_child(body)
	return body

func build_players() -> void:
	player = make_player(Vector3(0,0,10), Color(0.08,0.25,0.95))
	teammates.append(player)
	for p in [Vector3(-7,0,5), Vector3(7,0,5), Vector3(-5,0,-5), Vector3(5,0,-5)]:
		teammates.append(make_player(p, Color(0.08,0.25,0.95)))
	opponent = make_player(Vector3(0,0,-8), Color(0.85,0.10,0.12))
	enemies.append(opponent)
	for p in [Vector3(-7,0,-4), Vector3(7,0,-4), Vector3(-5,0,9), Vector3(5,0,9)]:
		enemies.append(make_player(p, Color(0.85,0.10,0.12)))

func build_ball() -> void:
	ball = RigidBody3D.new()
	ball.mass = 0.45
	ball.linear_damp = 0.65
	ball.angular_damp = 0.4
	ball.position = Vector3(0,0.65,7)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.32
	shape.shape = sphere
	ball.add_child(shape)
	var visual := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.64
	visual.mesh = sm
	visual.material_override = mat(Color(0.95,0.95,0.9),0.35)
	ball.add_child(visual)
	add_child(ball)

func build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 70
	add_child(camera)
	camera.global_position = Vector3(0, 11, 23)
	camera.look_at(Vector3(0,0,0), Vector3.UP)

func build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,14)
	panel.size = Vector2(260,56)
	hud.add_child(panel)
	score_label = Label.new()
	score_label.text = "CASA  0  x  0  VISITANTE     00:00"
	score_label.add_theme_font_size_override("font_size",20)
	panel.add_child(score_label)
	message_label = Label.new()
	message_label.text = "GRAMADO LENDÁRIO • AMISTOSO"
	message_label.position = Vector2(16,78)
	hud.add_child(message_label)
	var joystick_script = load("res://scripts/virtual_joystick.gd")
	var joystick = Control.new()
	joystick.set_script(joystick_script)
	joystick.position = Vector2(35, 455)
	joystick.size = Vector2(190, 190)
	joystick.moved.connect(func(v: Vector2): move_touch = v)
	hud.add_child(joystick)
	make_button("PASSE", Vector2(1050,520), func(): pass_requested = true)
	make_button("CHUTE", Vector2(1135,440), func(): shoot_requested = true)
	make_button("QUALIDADE", Vector2(16,650), func(): set_quality(not quality_high))
	make_button("CORRER", Vector2(1050,610), func(): sprint_touch = true)

var sprint_touch := false
func make_button(label_text: String, pos: Vector2, callback: Callable) -> void:
	var b := Button.new()
	b.text = label_text
	b.position = pos
	b.size = Vector2(112,62)
	b.add_theme_font_size_override("font_size",17)
	b.pressed.connect(callback)
	hud.add_child(b)

func set_quality(high: bool) -> void:
	quality_high = high
	if not is_inside_tree(): return
	if high:
		RenderingServer.set_default_clear_color(Color(0.08,0.13,0.10))
		Engine.max_fps = 60
	else:
		Engine.max_fps = 30
	message_label.text = "GRÁFICOS: REALISTA" if high else "GRÁFICOS: OTIMIZADO"

func _physics_process(delta: float) -> void:
	seconds += delta
	match_time += delta
	var mins := int(match_time) / 60
	var secs := int(match_time) % 60
	score_label.text = "CASA  %d  x  %d  VISITANTE     %02d:%02d" % [score_home, score_away, mins, secs]
	var dir := Vector3.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	if dir.length() < 0.1:
		dir.x = move_touch.x
		dir.z = move_touch.y
	dir = dir.normalized()
	var speed := 8.0 if Input.is_action_pressed("sprint") or sprint_touch else 5.5
	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed
	player.velocity.y -= 22.0 * delta
	player.move_and_slide()
	if dir.length() > 0.1:
		player.rotation.y = atan2(dir.x, dir.z)
	var to_ball := ball.global_position - player.global_position
	if to_ball.length() < 2.1 and (Input.is_action_just_pressed("pass_ball") or pass_requested):
		kick_ball(Vector3(0.2,0.12,-1.0), 10.0)
	if to_ball.length() < 2.2 and (Input.is_action_just_pressed("shoot_ball") or shoot_requested):
		kick_ball(Vector3(0,0.16,-1), 18.0)
	pass_requested = false
	shoot_requested = false
	sprint_touch = false
	ai_update(delta)
	camera_update(delta)
	if ball.global_position.y < -5 or abs(ball.global_position.x) > 28 or abs(ball.global_position.z) > 42:
		reset_ball()

func kick_ball(direction: Vector3, power: float) -> void:
	ball.apply_central_impulse(direction.normalized() * power)

func ai_update(delta: float) -> void:
	for i in range(enemies.size()):
		var bot := enemies[i]
		var target := ball.global_position if i == 0 else Vector3((i-2)*4,0,-12 + i*3)
		var d := target - bot.global_position
		d.y = 0
		if d.length() > 1.2:
			bot.velocity.x = d.normalized().x * 3.2
			bot.velocity.z = d.normalized().z * 3.2
		else:
			bot.velocity.x = 0
			bot.velocity.z = 0
		bot.velocity.y -= 22*delta
		bot.move_and_slide()
		if i == 0 and (ball.global_position - bot.global_position).length() < 1.5:
			var toward_goal := Vector3(0,0,1)
			ball.apply_central_impulse(toward_goal * 5.0)
	for i in range(1, teammates.size()):
		var mate := teammates[i]
		var home := [Vector3(-7,0,5),Vector3(7,0,5),Vector3(-5,0,-5),Vector3(5,0,-5)][i-1]
		var delta_pos := home - mate.global_position
		mate.velocity.x = clamp(delta_pos.x * 1.4, -2.0, 2.0)
		mate.velocity.z = clamp(delta_pos.z * 1.4, -2.0, 2.0)
		mate.velocity.y -= 22*delta
		mate.move_and_slide()

func camera_update(delta: float) -> void:
	var desired := player.global_position + Vector3(0, 10, 15)
	camera.global_position = camera.global_position.lerp(desired, 3.0 * delta)
	camera.look_at(player.global_position + Vector3(0,0,-4), Vector3.UP)

func reset_ball() -> void:
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = Vector3(0,0.65,7)
