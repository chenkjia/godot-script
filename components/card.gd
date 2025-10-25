extends Control

@onready var card: Control = self
@onready var card_texture: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow

@export var pick_up_card_scale: Vector2 = Vector2(1.12, 1.12)
@export var pick_up_shadow_scale: Vector2 = Vector2(1.08, 1.08)
@export var pick_up_speed: float = 0.12

# 拖动相关变量
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var tween_rot: Tween
@export var follow_speed: float = 1.0
@export var rotation_factor: float = 0.03

var tween: Tween

func _ready() -> void:
	# 初始：Card 缩放为 1，模糊 sigma 为 0.1；以中心点为基准缩放
	card_texture.scale = Vector2.ONE
	card.pivot_offset = card.size * 0.5
	# 连接鼠标进入/退出事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	pick_up_card()

func _on_mouse_exited() -> void:
	put_down_card()

# 独立函数：拿起卡片
func pick_up_card() -> void:
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(card_texture, "scale", pick_up_card_scale, pick_up_speed)
	tween.tween_property(shadow, "scale", pick_up_shadow_scale, pick_up_speed)

# 独立函数：放下卡片
func put_down_card() -> void:
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(card_texture, "scale", Vector2.ONE, pick_up_speed)
	tween.tween_property(shadow, "scale", Vector2.ONE, pick_up_speed)


# 输入事件处理：处理拖动开始和结束
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# 直接开始拖动，因为事件已经在卡片范围内
				dragging = true
				drag_offset = global_position - get_global_mouse_position()
				# 将卡片移到最前面
				get_parent().move_child(self, -1)
			else:
				if dragging:
					dragging = false
					# 停止旋转动画并归零（卡片和阴影同步）
					if tween_rot: 
						tween_rot.kill()
					tween_rot = create_tween().set_parallel(true)
					tween_rot.tween_property(self, "rotation_degrees", 0.0, 0.15)
					tween_rot.tween_property(shadow, "rotation_degrees", 0.0, 0.15)
	elif dragging and event is InputEventMouseMotion:
		drag_card_motion(event as InputEventMouseMotion)

# 独立的拖动卡片函数（小丑牌效果）
func drag_card_motion(motion_event: InputEventMouseMotion) -> void:
	# 位置跟随：平滑跟随鼠标位置
	var mouse_pos: Vector2 = get_global_mouse_position()
	var target_pos: Vector2 = mouse_pos + drag_offset
	global_position = global_position.lerp(target_pos, follow_speed)
	# 阴影跟随卡片位置
	shadow.global_position = shadow.global_position.lerp(target_pos, follow_speed)
	
	# 旋转效果：根据水平移动速度产生Z轴旋转（小丑牌摆动效果）
	var velocity: Vector2 = motion_event.velocity
	var target_rotation: float = clamp(velocity.x * rotation_factor, -10.0, 10.0)
	
	# 平滑旋转到目标角度（卡片和阴影同步旋转）
	if tween_rot: 
		tween_rot.kill()
	tween_rot = create_tween()
	tween_rot.tween_property(card, "rotation_degrees", target_rotation, 0.08)
