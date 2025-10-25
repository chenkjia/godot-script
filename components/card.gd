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
var original_position: Vector2 = Vector2.ZERO  # 记录原始位置
var original_rotation: float = 0.0  # 记录原始旋转
var original_index: int = 0  # 记录原始层级索引
var tween_rot: Tween
@export var follow_speed: float = 1.0
@export var rotation_factor: float = 0.03
@export var return_speed: float = 0.3  # 返回原位的速度

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
				# 通知管理器：开始散开效果
				notify_begin_drag_spread()
			else:
					if dragging:
						dragging = false
						# 检查是否在垃圾桶区域内
						if not check_trash_area():
							# 如果不在垃圾桶区域，返回原位置（在返回动画完成后再恢复布局）
							return_to_original_position()
						else:
							# 如果在垃圾桶区域，停止旋转动画并归零，并立即恢复布局
							if tween_rot: 
								tween_rot.kill()
								tween_rot = create_tween().set_parallel(true)
								tween_rot.tween_property(self, "rotation_degrees", 0.0, 0.15)
								notify_end_drag_spread()
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

# 返回到原始位置
func return_to_original_position() -> void:
	# 创建返回动画
	var return_tween = create_tween().set_parallel(true)
	# 平滑移动到原始位置
	return_tween.tween_property(self, "global_position", original_position, return_speed)
	# 平滑旋转到原始角度
	return_tween.tween_property(self, "rotation_degrees", original_rotation, return_speed)
	# 恢复原始层级索引
	get_parent().move_child(self, original_index)
	# 返回动画完成后再恢复整体布局
	return_tween.finished.connect(func():
		notify_end_drag_spread()
	)

# 通知管理器：开始散开效果
func notify_begin_drag_spread() -> void:
	var managers = get_tree().get_nodes_in_group("card_manager")
	if managers.size() > 0:
		var m = managers[0]
		if m.has_method("begin_drag_spread"):
			m.begin_drag_spread(self)

# 通知管理器：结束散开效果
func notify_end_drag_spread() -> void:
	var managers = get_tree().get_nodes_in_group("card_manager")
	if managers.size() > 0:
		var m = managers[0]
		if m.has_method("end_drag_spread"):
			m.end_drag_spread()
