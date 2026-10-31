extends Node2D

var speed = 200
var direction = Vector2(1,0)
var WindowsSize = Vector2(200,200)
var ScreenSize = Vector2()
var is_idling = true
var IdleTime = 0
var LuckyIdle = 0

@onready var animated_sprite = $AnimatedSprite2D

var is_dragging = false
var drag_offset = Vector2()

# Variables pour détecter un clic simple par rapport à un glissement
var click_start_pos = Vector2i()
var mouse_moved_significantly = false

func _ready() -> void:
	ScreenSize = Vector2(DisplayServer.screen_get_size())
	animated_sprite.play("Walk")

func _physics_process(delta: float) -> void:
	if is_dragging:
		var mouse_pos = Vector2i(DisplayServer.mouse_get_position())
		
		# Si la souris a bougé depuis le clic, on considère que c'est un drag
		if mouse_pos.distance_to(click_start_pos) > 5:
			mouse_moved_significantly = true
			
		var New_Win_pos = mouse_pos - drag_offset
		DisplayServer.window_set_position(Vector2i(New_Win_pos))
		return

	if is_idling == false:
		return
		
	animated_sprite.play("Walk")
	var windows_position = Vector2(DisplayServer.window_get_position())
	windows_position = windows_position + (direction * speed * delta)
	windows_position.x = clamp(windows_position.x, 0, ScreenSize.x - WindowsSize.x)
	windows_position.y = clamp(windows_position.y, 0, ScreenSize.y - WindowsSize.y)
	DisplayServer.window_set_position(Vector2i(windows_position))
	
	if windows_position.x == 0 or windows_position.x >= ScreenSize.x - WindowsSize.x:
		direction.x = direction.x * -1
		animated_sprite.flip_h = !animated_sprite.flip_h
		Idle()
		return
		
	if windows_position.y == 0 or windows_position.y >= ScreenSize.y - WindowsSize.y:
		direction.y = direction.y * -1
		Idle()
		return

func Idle() -> void :
	LuckyIdle = randi_range(0, 3)
	if LuckyIdle == 2:
		is_idling = false
	animated_sprite.play("Idle")
	IdleTime = randi_range(1, 5)
	await get_tree().create_timer(IdleTime).timeout
	is_idling = true
	return

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_screen_pos = DisplayServer.mouse_get_position()
		var win_pos = DisplayServer.window_get_position()
		var win_rect = Rect2(win_pos, WindowsSize)
		
		if event.pressed:
			if win_rect.has_point(mouse_screen_pos):
				is_dragging = true
				click_start_pos = mouse_screen_pos
				mouse_moved_significantly = false
				drag_offset = mouse_screen_pos - Vector2i(win_pos)
		else:
			if is_dragging:
				is_dragging = false
				# Si on a relâché le clic sans vraiment bouger la fenêtre, c'est un clic (un p'tit hop !)
				if not mouse_moved_significantly and win_rect.has_point(mouse_screen_pos):
					trigger_hop()

func trigger_hop() -> void:
	var tween = create_tween()
	tween.tween_property(animated_sprite, "offset:y", -30.0, 0.15)
	tween.tween_property(animated_sprite, "offset:y", 0.0, 0.15)
