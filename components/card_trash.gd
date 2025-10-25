extends Control

# 垃圾桶区域
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# 导出参数
@export var trash_color: Color = Color(0.8, 0.2, 0.2, 0.7)  # 垃圾桶背景颜色
@export var highlight_color: Color = Color(1.0, 0.3, 0.3, 0.9)  # 高亮颜色
@export var trash_size: Vector2 = Vector2(300, 440)  # 垃圾桶大小

# 状态变量
var is_highlighted: bool = false
var cards_in_area: Array[Node] = []

func _ready() -> void:
	# 设置垃圾桶大小和颜色
	setup_trash_area()
	
	# 只连接area信号，因为卡片是Control类型，不是物理体
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.area_exited.connect(_on_area_exited)

func setup_trash_area() -> void:
	# 设置碰撞区域大小
	var shape = collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = trash_size
	
	# 设置初始颜色
	modulate = trash_color
	
	# 设置最小尺寸
	custom_minimum_size = trash_size

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("get_script") and parent.get_script() != null:
		var script_path = parent.get_script().resource_path
		if "card.gd" in script_path:
			cards_in_area.append(parent)
			highlight_trash()

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in cards_in_area:
		cards_in_area.erase(parent)
		if cards_in_area.is_empty():
			unhighlight_trash()

func highlight_trash() -> void:
	if not is_highlighted:
		is_highlighted = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", highlight_color, 0.2)

func unhighlight_trash() -> void:
	if is_highlighted:
		is_highlighted = false
		var tween = create_tween()
		tween.tween_property(self, "modulate", trash_color, 0.2)

# 检查卡片是否在垃圾桶区域内
func is_card_in_trash_area(card: Node) -> bool:
	return card in cards_in_area

# 销毁卡片
func destroy_card(card: Node) -> void:
	if card in cards_in_area:
		cards_in_area.erase(card)
		
		# 播放销毁动画
		var tween = create_tween()
		tween.parallel().tween_property(card, "scale", Vector2.ZERO, 0.3)
		tween.parallel().tween_property(card, "modulate:a", 0.0, 0.3)
		
		# 动画完成后销毁节点
		await tween.finished
		
		# 通知卡片管理器移除卡片
		var card_manager = get_tree().get_first_node_in_group("card_manager")
		if card_manager and card_manager.has_method("remove_card"):
			card_manager.remove_card(card)
		
		card.queue_free()
		
		# 如果没有卡片了，取消高亮
		if cards_in_area.is_empty():
			unhighlight_trash()

func _draw() -> void:
	# 绘制垃圾桶背景
	var rect = Rect2(Vector2.ZERO, trash_size)
	draw_rect(rect, modulate, true)
	
	# 绘制边框
	draw_rect(rect, Color.WHITE, false, 2.0)