extends Node2D


const Ball = preload("res://Scenes/Ball.tscn")
onready var spawn:Position2D = $Spawn
onready var new_spawn:Position2D = $NewSpawn
onready var first_line:Line2D = $Spawn/FirstLine
onready var end_line:Line2D = $Spawn/EndLine
onready var first_ray:RayCast2D = $Spawn/FirstRay
onready var end_ray:RayCast2D = $Spawn/EndRay
onready var timer:Timer = $Timer
onready var tween:Tween = $Tween

var is_angle_valid:bool
var angle
var fgfg = 0
var gfgf = 0
var turn_complete:bool = true
var first_ball:bool = false

signal level_started()
signal level_completed()
signal level_failed()
signal turn_completed()
signal ground_collision(position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	first_line.points[0] = first_line.position
	timer.connect("timeout", self, "_on_Ball_Shooting")
	self.connect("ground_collision", self, "_on_Ground_Collision")


func _process(delta:float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if turn_complete:
		if event is InputEventScreenDrag or event is InputEventScreenTouch:
			var direction = event.position - $Spawn.position
			first_ray.cast_to = direction.normalized() * 2000
			first_ray.force_raycast_update()
			end_ray.clear_exceptions()
			
			is_angle_valid = direction.angle() < -0.1 and direction.angle() > -3.04
	#		print(direction.angle())
			
			if first_ray.is_colliding() and is_angle_valid:
				first_line.visible = true
				var collider = first_ray.get_collider()
				if not collider.name == "Ceil":
					end_line.visible = true # tavana değen ilk line da end_line visible false olacağı için bunu yazdık.
					# line pointi yerel olduğundan global olarak nerede olacağının hesabını yapıyoruz
					first_line.points[1] = first_ray.get_collision_point() - first_line.global_position
					end_ray.global_position = first_ray.get_collision_point()
					end_ray.cast_to = first_ray.cast_to.bounce(first_ray.get_collision_normal())
					end_ray.add_exception(first_ray.get_collider())
					end_ray.force_raycast_update()
					
					end_line.points[0] = first_line.points[1]
					end_line.points[1] = end_ray.get_collision_point() - first_line.global_position
	#				print(end_ray.get_collision_point(), first_line.global_position, first_line.points[1])
				
				else:
					first_line.points[1] = first_ray.get_collision_point() - first_line.global_position
					end_line.visible = false
			
			else:
				first_line.visible = false
				end_line.visible = false
		
		if event is InputEventScreenTouch and not event.pressed and is_angle_valid:
			first_line.visible = false
			end_line.visible = false
			angle = (get_global_mouse_position() - $Spawn.position).angle()
			timer.start()
			turn_complete = false

func _on_Ball_Shooting() -> void:
	fgfg += 1
	var ball = Ball.instance()
	add_child(ball)
	ball.position = $Spawn.position
	ball.start(angle)
	$Spawn/BallCount.text = "x%d"%(30-fgfg)
	if fgfg >= 30:
		$Spawn/BallCount.visible = false
		timer.stop()

func _on_Ground_Collision(pos) -> void:
	gfgf += 1
	if !first_ball:
		print(pos)
		new_spawn.position = pos
		new_spawn.visible = true
		first_ball = true
	
	if gfgf >= 30:
		tween.interpolate_property(spawn, "position", spawn.position, new_spawn.position, 0.3,
		Tween.TRANS_SINE, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		new_spawn.visible = false
		turn_complete = true
		fgfg = 0
		gfgf = 0
		first_ball = false
		$Spawn/BallCount.text = "x%d"%(30-fgfg)
		$Spawn/BallCount.visible = true
		
