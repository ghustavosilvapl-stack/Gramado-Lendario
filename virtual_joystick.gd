extends Control

signal moved(value: Vector2)
var active := false
var knob := Vector2.ZERO
var pointer := -1
const RADIUS := 72.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS, Color(0.05,0.07,0.08,0.42))
	draw_arc(center, RADIUS, 0, TAU, 64, Color(0.85,0.9,0.95,0.75), 3.0)
	var k := center + knob * RADIUS
	draw_circle(k, 29, Color(0.8,0.88,0.98,0.72))
	draw_arc(k, 29, 0, TAU, 48, Color(1,1,1,0.9), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			pointer = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == pointer:
			active = false
			pointer = -1
			knob = Vector2.ZERO
			moved.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventScreenDrag and active and event.index == pointer:
		_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		active = event.pressed
		if active: _update_knob(event.position)
		else:
			knob = Vector2.ZERO
			moved.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventMouseMotion and active:
		_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var offset := (pos - size * 0.5) / RADIUS
	knob = offset.limit_length(1.0)
	moved.emit(Vector2(knob.x, knob.y))
	queue_redraw()
