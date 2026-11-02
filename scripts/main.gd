extends Node2D

# Gramado Lendário — protótipo 2D de futebol com visão superior.
# Controles: toque em companheiro para passar; deslize para chutar;
# toque em espaço livre para movimentar o jogador selecionado.

const FIELD := Rect2(90, 55, 1100, 610)
const CENTER := Vector2(640, 360)
const PLAYER_RADIUS := 17.0
const BALL_RADIUS := 8.0
const PLAYER_SPEED := 245.0
const BALL_FRICTION := 0.986

var home := [
    Vector2(250, 360), Vector2(390, 205), Vector2(390, 515),
    Vector2(545, 275), Vector2(545, 445)
]
var away := [
    Vector2(1030, 360), Vector2(890, 205), Vector2(890, 515),
    Vector2(735, 275), Vector2(735, 445)
]
var home_velocity: Array[Vector2] = []
var away_velocity: Array[Vector2] = []
var selected := 0
var ball_position := Vector2(270, 360)
var ball_velocity := Vector2.ZERO
var ball_owner := 0 # índice do jogador da casa; -1 livre; -2 adversário
var away_owner := -1
var target_position := Vector2.ZERO
var has_target := false
var gesture_start := Vector2.ZERO
var gesture_current := Vector2.ZERO
var gesture_active := false
var score_home := 0
var score_away := 0
var elapsed := 0.0
var message := "TOQUE EM UM COMPANHEIRO PARA PASSAR"
var match_running := true
var kickoff_timer := 0.0

func _ready() -> void:
    for i in range(home.size()):
        home_velocity.append(Vector2.ZERO)
        away_velocity.append(Vector2.ZERO)
    ball_owner = 0
    ball_position = home[0] + Vector2(18, 0)
    queue_redraw()

func _process(delta: float) -> void:
    if not match_running:
        return
    elapsed += delta
    kickoff_timer = maxf(0.0, kickoff_timer - delta)
    _update_home(delta)
    _update_away(delta)
    _update_ball(delta)
    _check_goal()
    queue_redraw()

func _update_home(delta: float) -> void:
    for i in range(home.size()):
        var destination := _home_formation(i)
        if i == selected and has_target and ball_owner != -2:
            destination = target_position
        elif ball_owner == i:
            destination = ball_position
        elif ball_owner == -2:
            destination = _home_formation(i) + (ball_position - CENTER) * 0.12
        var difference := destination - home[i]
        var max_step := PLAYER_SPEED * delta
        if difference.length() > 3.0:
            var step := difference.normalized() * minf(max_step, difference.length())
            home[i] += step
            home_velocity[i] = step / maxf(delta, 0.001)
        else:
            home_velocity[i] = Vector2.ZERO
    if ball_owner >= 0:
        ball_position = home[ball_owner] + Vector2(18, 0)

func _update_away(delta: float) -> void:
    for i in range(away.size()):
        var destination := _away_formation(i)
        if away_owner == i:
            destination = ball_position
        elif ball_owner >= 0:
            var pressure_target := ball_position + Vector2(35, 0)
            if i == 0:
                destination = pressure_target
        else:
            destination = _away_formation(i) + (ball_position - CENTER) * 0.10
        var difference := destination - away[i]
        var step_limit := 190.0 * delta
        if difference.length() > 2.0:
            var step := difference.normalized() * minf(step_limit, difference.length())
            away[i] += step
            away_velocity[i] = step / maxf(delta, 0.001)
        else:
            away_velocity[i] = Vector2.ZERO
    if away_owner >= 0:
        ball_position = away[away_owner] + Vector2(-18, 0)
    elif ball_owner == -1:
        # Adversário mais próximo tenta disputar a bola.
        var nearest := 0
        var nearest_distance := INF
        for i in range(away.size()):
            var d := away[i].distance_to(ball_position)
            if d < nearest_distance:
                nearest_distance = d
                nearest = i
        if nearest_distance < 27.0 and ball_velocity.length() < 90.0:
            away_owner = nearest
            ball_owner = -2
            message = "O ADVERSÁRIO FICOU COM A BOLA!"

func _update_ball(delta: float) -> void:
    if ball_owner != -1:
        return
    ball_position += ball_velocity * delta
    ball_velocity *= pow(BALL_FRICTION, delta * 60.0)
    if ball_velocity.length() < 7.0:
        ball_velocity = Vector2.ZERO
    if ball_position.y < FIELD.position.y + 12 or ball_position.y > FIELD.end.y - 12:
        ball_velocity.y *= -0.78
        ball_position.y = clampf(ball_position.y, FIELD.position.y + 12, FIELD.end.y - 12)
    if ball_position.x < FIELD.position.x + 10 or ball_position.x > FIELD.end.x - 10:
        ball_velocity.x *= -0.78
        ball_position.x = clampf(ball_position.x, FIELD.position.x + 10, FIELD.end.x - 10)
    # Jogador da casa recupera a bola quando chega perto.
    for i in range(home.size()):
        if home[i].distance_to(ball_position) < 25.0 and ball_velocity.length() < 115.0:
            ball_owner = i
            selected = i
            has_target = false
            message = "VOCÊ RECUPEROU A BOLA!"
            break

func _home_formation(i: int) -> Vector2:
    var positions := [
        Vector2(250, 360), Vector2(390, 205), Vector2(390, 515),
        Vector2(545, 275), Vector2(545, 445)
    ]
    return positions[i]

func _away_formation(i: int) -> Vector2:
    var positions := [
        Vector2(1030, 360), Vector2(890, 205), Vector2(890, 515),
        Vector2(735, 275), Vector2(735, 445)
    ]
    return positions[i]

func _pass_to(index: int) -> void:
    if ball_owner < 0:
        return
    var origin := ball_position
    var destination := home[index]
    var direction := destination - origin
    if direction.length() < 1.0:
        return
    ball_owner = -1
    away_owner = -1
    ball_velocity = direction.normalized() * 500.0
    selected = index
    has_target = false
    message = "PASSE! RECEBA A BOLA"

func _shoot(direction: Vector2) -> void:
    if ball_owner < 0 or direction.length() < 0.1:
        return
    ball_owner = -1
    away_owner = -1
    has_target = false
    ball_velocity = direction.normalized() * 760.0
    message = "CHUTE A GOL!"

func _handle_press(position: Vector2) -> void:
    gesture_start = position
    gesture_current = position
    gesture_active = true

func _handle_release(position: Vector2) -> void:
    if not gesture_active:
        return
    gesture_current = position
    gesture_active = false
    var swipe := position - gesture_start
    if swipe.length() > 38.0 and ball_owner >= 0:
        _shoot(swipe)
        return
    # Toque em companheiro: passe direto para ele.
    if ball_owner >= 0:
        var nearest_index := -1
        var nearest_distance := 48.0
        for i in range(home.size()):
            if i == ball_owner:
                continue
            var d := home[i].distance_to(position)
            if d < nearest_distance:
                nearest_distance = d
                nearest_index = i
        if nearest_index >= 0:
            _pass_to(nearest_index)
            return
    # Toque em jogador da casa: seleciona para controlar.
    for i in range(home.size()):
        if home[i].distance_to(position) < 34.0:
            selected = i
            has_target = false
            if ball_owner == -1 and home[i].distance_to(ball_position) < 42.0:
                ball_owner = i
            message = "JOGADOR %d SELECIONADO" % (i + 1)
            return
    # Toque no campo: jogador selecionado corre até o local.
    if FIELD.has_point(position):
        target_position = Vector2(
            clampf(position.x, FIELD.position.x + 24, FIELD.end.x - 24),
            clampf(position.y, FIELD.position.y + 24, FIELD.end.y - 24)
        )
        has_target = true
        message = "MOVIMENTE-SE PARA RECEBER OU MARCAR"

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_press(event.position)
        else:
            _handle_release(event.position)
    elif event is InputEventScreenDrag:
        if gesture_active:
            gesture_current = event.position
            queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _handle_press(event.position)
        else:
            _handle_release(event.position)
    elif event is InputEventMouseMotion and gesture_active:
        gesture_current = event.position
        queue_redraw()

func _check_goal() -> void:
    if ball_position.x > FIELD.end.x - 5 and absf(ball_position.y - CENTER.y) < 82.0:
        score_home += 1
        _restart_after_goal("GOOOOOOL! GRAMADO LENDÁRIO!")
    elif ball_position.x < FIELD.position.x + 5 and absf(ball_position.y - CENTER.y) < 82.0:
        score_away += 1
        _restart_after_goal("GOL DO ADVERSÁRIO!")
        
func _restart_after_goal(text_message: String) -> void:
    message = text_message
    ball_position = Vector2(270, 360)
    ball_velocity = Vector2.ZERO
    ball_owner = 0
    away_owner = -1
    selected = 0
    has_target = false
    home = [
        Vector2(250, 360), Vector2(390, 205), Vector2(390, 515),
        Vector2(545, 275), Vector2(545, 445)
    ]
    away = [
        Vector2(1030, 360), Vector2(890, 205), Vector2(890, 515),
        Vector2(735, 275), Vector2(735, 445)
    ]
    kickoff_timer = 1.0

func _draw() -> void:
    # Fundo e campo
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#102a22"))
    draw_rect(FIELD, Color("#287b43"))
    for i in range(10):
        var stripe := Rect2(FIELD.position + Vector2(i * 110, 0), Vector2(55, FIELD.size.y))
        if i % 2 == 0:
            draw_rect(stripe, Color(1, 1, 1, 0.035))
    var white := Color(0.94, 0.96, 0.91)
    draw_rect(FIELD, white, false, 4.0)
    draw_line(Vector2(CENTER.x, FIELD.position.y), Vector2(CENTER.x, FIELD.end.y), white, 3.0)
    draw_arc(CENTER, 82.0, 0, TAU, 80, white, 3.0)
    draw_circle(CENTER, 5.0, white)
    # Áreas e gols
    draw_rect(Rect2(FIELD.position + Vector2(0, 190), Vector2(150, 230)), white, false, 3.0)
    draw_rect(Rect2(Vector2(FIELD.end.x - 150, FIELD.position.y + 190), Vector2(150, 230)), white, false, 3.0)
    draw_rect(Rect2(FIELD.position + Vector2(0, 260), Vector2(55, 90)), white, false, 3.0)
    draw_rect(Rect2(Vector2(FIELD.end.x - 55, FIELD.position.y + 260), Vector2(55, 90)), white, false, 3.0)
    draw_rect(Rect2(Vector2(FIELD.position.x - 15, CENTER.y - 70), Vector2(15, 140)), Color("#dce8e3"), false, 4.0)
    draw_rect(Rect2(Vector2(FIELD.end.x, CENTER.y - 70), Vector2(15, 140)), Color("#dce8e3"), false, 4.0)
    # HUD
    draw_rect(Rect2(455, 10, 370, 38), Color(0.025, 0.08, 0.07, 0.94))
    draw_string(ThemeDB.fallback_font, Vector2(485, 36), "CASA   %d  x  %d   VISITANTE" % [score_home, score_away], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, white)
    draw_rect(Rect2(270, 675, 740, 32), Color(0.02, 0.06, 0.055, 0.9))
    draw_string(ThemeDB.fallback_font, Vector2(290, 697), message, HORIZONTAL_ALIGNMENT_CENTER, 700, 17, Color("#fff1b8"))
    draw_string(ThemeDB.fallback_font, Vector2(20, 35), "GRAMADO LENDÁRIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f2d16b"))
    # Jogadores visitantes e da casa
    for i in range(away.size()):
        _draw_player(away[i], Color("#d94343"), false, false)
    for i in range(home.size()):
        _draw_player(home[i], Color("#2875e8"), true, i == selected)
    # Bola
    draw_circle(ball_position + Vector2(2, 3), BALL_RADIUS + 1, Color(0, 0, 0, 0.28))
    draw_circle(ball_position, BALL_RADIUS, Color("#fffdf1"))
    draw_arc(ball_position, BALL_RADIUS - 2, 0, TAU, 20, Color("#252525"), 1.4)
    if gesture_active and ball_owner >= 0:
        draw_line(ball_position, gesture_current, Color("#ffe27a"), 4.0)
        draw_circle(gesture_current, 7, Color("#ffe27a"))

func _draw_player(pos: Vector2, color: Color, is_home: bool, is_selected: bool) -> void:
    draw_circle(pos + Vector2(2, 4), PLAYER_RADIUS + 2, Color(0, 0, 0, 0.25))
    draw_circle(pos, PLAYER_RADIUS + (4 if is_selected else 0), Color("#ffe16b") if is_selected else Color("#f2f2ed"))
    draw_circle(pos, PLAYER_RADIUS - 3, color)
    draw_circle(pos + Vector2(-4, -5), 4, Color(1, 1, 1, 0.55))
    if is_selected:
        draw_arc(pos, PLAYER_RADIUS + 8, 0, TAU, 36, Color("#ffe16b"), 3.0)
