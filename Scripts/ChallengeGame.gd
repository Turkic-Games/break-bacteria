extends Node2D

enum State {
	ACTION,
	DELETED_ITEM_CLEAR,
	ERASE
	ROW_DOWN,
	ADD_ROW,
	IDLE
}



signal screen_clear()
signal turn_completed()
signal challenge_failed()
signal ball_plus()
signal coins_updated()
signal balls_updated()
signal ground_collision(pos)
signal collision_lines(points)

const Ball = preload("res://Scenes/Ball.tscn")

onready var score_label:Label = $HUD/Top/MarginContainer2/ScoreLabel
onready var coins_label:Label = $HUD/Top/MarginContainer3/HBoxContainer/CoinsLabel
onready var bricketgrid := $BricketGridChallenge

onready var spawn:Position2D = $Spawn
onready var new_spawn:Position2D = $NewSpawn
onready var first_line:Line2D = $Spawn/FirstLine
onready var end_line:Line2D = $Spawn/EndLine
onready var booster_line:Line2D = $Spawn/BoosterLine
onready var balls_count:Label = $Spawn/BallsCount
onready var timer:Timer = $Timer
onready var speed_timer:Timer = $SpeedTimer
onready var tween:Tween = $Tween
onready var animation:AnimationPlayer = $AnimationPlayer
onready var test_ball = preload("res://Scenes/TestBall.tscn")

var is_angle_valid:bool
var angle:float
var thrown_balls:int
var falling_balls:int
var turn_complete:bool = true
var first_ball:bool = false
var total_balls:int
var ball_enhancer:int
var level:int
var is_extra50:bool
var is_aiming:bool

func _ready() -> void:
	LocalSettings.load()
	level = LocalSettings.get_setting("challenge_checkpoints", 1)
	total_balls = level
	score_label.text = str(level)
	coins_label.text = str(LocalSettings.get_setting("coins", 0))
	balls_count.text = "x%d"%(total_balls)
	
	animation.play("turn_completed")
	bricketgrid.draw_update(level)
	
	timer.connect("timeout", self, "_on_Ball_Shooting")
	speed_timer.connect("timeout", self, "_on_engine_speed")
	connect("challenge_failed", self, "_on_challenge_failed")
	connect("screen_clear", self, "_on_screen_clear")
	connect("ball_plus", self, "_on_ball_plus")
	connect("coins_updated", self, "_on_coins_updated")
	connect("balls_updated", self, "_on_balls_updated")
	connect("ground_collision", self, "_on_Ground_Collision")
	connect("turn_completed", self, "_on_Turn_Completed")
	connect("collision_lines", self, "_on_collision_lines")


func _process(delta: float) -> void:
	pass
	

func _input(event: InputEvent) -> void:
	if turn_complete and event.position.y > 180 and event.position.y < $Spawn.position.y:
		if event is InputEventScreenDrag or event is InputEventScreenTouch and event.pressed:
#			first_line.visible = true
#			end_line.visible = true
			if is_aiming: 
				booster_line.visible = true
			if has_node("Tutorial"):
				$Tutorial.queue_free()
			var direction = event.position - $Spawn.position

			is_angle_valid = direction.angle() < -0.1 and direction.angle() > -3.04
			
			var tball = test_ball.instance()
			spawn.add_child(tball)
			tball.start(direction.angle())


		if event is InputEventScreenTouch and not event.pressed and is_angle_valid:
			first_line.visible = false
			end_line.visible = false
			booster_line.visible = false
			angle = (get_global_mouse_position() - $Spawn.position).angle()
			timer.start()
			turn_complete = false
			is_aiming = false
			animation.play("turn")
			speed_timer.start()

func _on_collision_lines(points:PoolVector2Array):
	if is_angle_valid:
		first_line.visible = true
		end_line.visible = true
		first_line.points[0] = Vector2.ZERO
		first_line.points[1] = points[0] - spawn.global_position
		end_line.points[0] = first_line.points[1]
		end_line.points[1] = points[1] - spawn.global_position
		booster_line.points[0] = end_line.points[1]
		booster_line.points[1] = points[2] - spawn.global_position
	else:
		first_line.visible = false
		end_line.visible = false
		
func _on_Ball_Shooting() -> void:
	thrown_balls += 1
	var ball = Ball.instance()
	$Balls.add_child(ball)
	ball.position = $Spawn.position
	ball.start(angle)
	balls_count.text = "x%d"%(total_balls-thrown_balls)
	
	if thrown_balls >= total_balls:
		balls_count.visible = false
		timer.stop()

func _on_Ground_Collision(pos) -> void:
	falling_balls += 1
	if !first_ball:
		new_spawn.position.x = pos.x
		new_spawn.visible = true
		first_ball = true
	
	if falling_balls >= total_balls:
		tween.interpolate_property(spawn, "position", spawn.position, new_spawn.position, 0.3,
					Tween.TRANS_SINE, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		emit_signal("turn_completed")

func _on_Turn_Completed() -> void:
	if is_extra50:
		total_balls -= 50
		is_extra50 = false
	animation.play("turn_completed")
	speed_timer.stop()
	Engine.time_scale = 1
	$HUD/Speed.visible = false
	new_spawn.visible = false
	thrown_balls = 0
	falling_balls = 0
	first_ball = false
	
	level += 1
	score_label.text = str(level)
	total_balls += ball_enhancer
	ball_enhancer = 0
	balls_count.text = "x%d"%(total_balls)
	balls_count.visible = true
	turn_complete = true
	bricketgrid.draw_update(level)
	
func _on_ball_plus() -> void:
	ball_enhancer += 1

func _on_balls_updated() -> void:
	balls_count.text = "x%d"%total_balls

func _on_screen_clear() -> void:
	$HUD/Center.visible = true
	LocalSettings.set_setting("challenge_checkpoints", level)
	var best_score = LocalSettings.get_setting("best_challenge_level", 0)
	if level > best_score:
		LocalSettings.set_setting("best_challenge_level", level)
	
	yield(get_tree().create_timer(2), "timeout")
	$HUD/Center.visible = false

func _on_challenge_failed() -> void:
	print("oyun bittiiii!!!")
	get_tree().paused = true

func _on_coins_updated() -> void:
	var up_coins = LocalSettings.get_setting("coins", 0)
	coins_label.text = str(up_coins)

func _on_engine_speed() -> void:
	Engine.time_scale *= 2
	$HUD/Speed.visible = true

func _on_ChallengeGame_tree_exited() -> void:
	LocalSettings.load()
	var checkpoint = LocalSettings.get_setting("challenge_checkpoints", 1)
	if level != checkpoint:
		LocalSettings.set_setting("challenge_checkpoints", 1)


func _on_TakeButton_pressed() -> void:
	timer.stop()
	for ball in $Balls.get_children():
		ball.go_home()
	
	falling_balls += total_balls - thrown_balls
	if Engine.time_scale > 1:
		Engine.time_scale = 1
		$HUD/Speed.visible = false

func _on_PauseButton_pressed() -> void:
	var popup = preload("res://Scenes/UI/PausePopup.tscn").instance()
	$HUD.add_child(popup)
	get_tree().paused = true
	yield(popup, "ok")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().paused = false
	emit_signal("coins_updated")
	emit_signal("balls_updated")


func _on_AimingButton_pressed() -> void:
	var coins =  LocalSettings.get_setting("coins", 0)
	if coins > 10:
		var popup = preload("res://Scenes/UI/SingleBoostBuy.tscn").instance()
		popup._subtitle = "Gold Aiming!"
		popup.coin = 10
		$HUD.add_child(popup)
		get_tree().paused = true
		yield(popup, "ok")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		get_tree().paused = false
		LocalSettings.set_setting("coins", LocalSettings.get_setting("coins", 0) - 10)
		emit_signal("coins_updated")
		emit_signal("balls_updated")
		is_aiming = true
	else:
		pass
	print("aiming")


func _on_Extra50Button_pressed() -> void:
	var coins =  LocalSettings.get_setting("coins", 0)
	if coins > 20:
		var popup = preload("res://Scenes/UI/SingleBoostBuy.tscn").instance()
		popup.coin = 20
		$HUD.add_child(popup)
		get_tree().paused = true
		yield(popup, "ok")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		get_tree().paused = false
		LocalSettings.set_setting("coins", LocalSettings.get_setting("coins", 0) - 20)
		total_balls += 50
		is_extra50 = true
		emit_signal("coins_updated")
		emit_signal("balls_updated")
	else:
		pass
	print("extra")
	


func _on_BreakBottomButton_pressed() -> void:
	var coins =  LocalSettings.get_setting("coins", 0)
	if coins > 30:
		var popup = preload("res://Scenes/UI/SingleBoostBuy.tscn").instance()
		popup.coin = 30
		popup._subtitle = "Break Bottom Bricks!"
#		popup.rect_position = Vector2(540, 960)
		$HUD.add_child(popup)
		get_tree().paused = true
		yield(popup, "ok")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		get_tree().paused = false
		LocalSettings.set_setting("coins", LocalSettings.get_setting("coins", 0) - 30)
		emit_signal("coins_updated")
		emit_signal("balls_updated")
		bricketgrid.end_row_bricks_kills()
	else:
		pass
	print("break")


func _on_HalveButton_pressed() -> void:
	var coins =  LocalSettings.get_setting("coins", 0)
	if coins > 50:
		var popup = preload("res://Scenes/UI/SingleBoostBuy.tscn").instance()
		popup._subtitle = "Halve Bricks Level!"
		popup.coin = 50
		$HUD.add_child(popup)
		get_tree().paused = true
		yield(popup, "ok")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		get_tree().paused = false
		LocalSettings.set_setting("coins", LocalSettings.get_setting("coins", 0) - 50)
		emit_signal("coins_updated")
		emit_signal("balls_updated")
		bricketgrid.all_bricks_halved()
	else:
		pass
	print("halve")

func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			self._on_PauseButton_pressed()
			
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			self._on_PauseButton_pressed()
