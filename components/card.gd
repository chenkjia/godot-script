extends Control

@onready var card: Control = self
@onready var card_texture: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow

# 事件信号（由管理器接入并处理）
signal card_start_play(card)
signal card_cancel_play(card)
signal card_destroyed(card)

@export var pick_up_card_scale: Vector2 = Vector2(1.12, 1.12)
@export var pick_up_shadow_scale: Vector2 = Vector2(1.08, 1.08)
@export var pick_up_speed: float = 0.12
@export var pick_up_lift_offset: float = -460.0  # 拿起时向上提升的距离

# 拖动相关变量
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO  # 记录原始位置
var original_rotation: float = 0.0  # 记录原始旋转
var original_index: int = 0  # 记录原始层级索引
var original_y_offset: float = 0.0  # 记录原始Y偏移
var tween_rot: Tween
@export var follow_speed: float = 1.0
@export var rotation_factor: float = 0.03
@export var return_speed: float = 0.3  # 返回原位的速度

var tween: Tween

func _ready() -> void:
	# 初始：Card 缩放为 1，模糊 sigma 为 0.1；以中心点为基准缩放
	card_texture.scale = Vector2.ONE
	card.pivot_offset = card.size * 0.5
	# 记录原始Y偏移
	original_y_offset = position.y
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
	# 拿起时将角度归零
	tween.tween_property(self, "rotation", 0.0, pick_up_speed)
	# 拿起时向上提升
	tween.tween_property(self, "position:y", original_y_offset + pick_up_lift_offset, pick_up_speed)
	emit_signal("card_start_play", self)

# 独立函数：放下卡片
func put_down_card() -> void:
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(card_texture, "scale", Vector2.ONE, pick_up_speed)
	tween.tween_property(shadow, "scale", Vector2.ONE, pick_up_speed)
	# 放下时恢复原始角度
	tween.tween_property(self, "rotation", original_rotation, pick_up_speed)
	# 放下时恢复原始Y位置
	tween.tween_property(self, "position:y", original_y_offset, pick_up_speed)
	emit_signal("card_cancel_play", self)

# 输入事件处理：处理拖动开始和结束
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# 记录拖动开始时的原始位置和旋转
				original_position = global_position
				original_rotation = rotation_degrees
				# 记录原始层级索引
				original_index = get_index()
				# 直接开始拖动，因为事件已经在卡片范围内
				dragging = true
				drag_offset = global_position - get_global_mouse_position()
				# 将卡片移到最前面
				get_parent().move_child(self, -1)
				# 发送拖动开始信号
				emit_signal("card_start_play", self)
			else:
					if dragging:
						dragging = false
						# 检查是否在垃圾桶区域内
						if not check_trash_area():
							get_parent().move_child(self, original_index)
							put_down_card()
						else:
							# 如果在垃圾桶区域，停止旋转动画并归零，并发出销毁信号
							if tween_rot: 
								tween_rot.kill()
								tween_rot = create_tween().set_parallel(true)
								tween_rot.tween_property(self, "rotation_degrees", 0.0, 0.15)
								emit_signal("card_destroyed", self)
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

# 检查卡片是否在垃圾桶区域内
func check_trash_area() -> bool:
	# 查找垃圾桶节点
	var trash_nodes = get_tree().get_nodes_in_group("card_trash")
	if trash_nodes.is_empty():
		# 如果没有找到组，尝试通过类型查找
		trash_nodes = []
		var all_nodes = get_tree().get_nodes_in_group("card_trash")
		if all_nodes.is_empty():
			# 遍历场景查找垃圾桶
			var root = get_tree().current_scene
			trash_nodes = find_trash_nodes(root)
	
	for trash in trash_nodes:
		if trash.has_method("is_card_in_trash_area") and trash.is_card_in_trash_area(self):
			# 卡片在垃圾桶区域内，销毁卡片
			trash.destroy_card(self)
			return true
	
	return false  # 卡片不在垃圾桶区域内

# 递归查找垃圾桶节点
func find_trash_nodes(node: Node) -> Array:
	var trash_nodes = []
	
	# 检查当前节点是否是垃圾桶
	if node.has_method("is_card_in_trash_area"):
		trash_nodes.append(node)
	
	# 递归检查子节点
	for child in node.get_children():
		trash_nodes.append_array(find_trash_nodes(child))
	
	return trash_nodes
