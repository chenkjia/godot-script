extends Control

# 卡片场景预制体
@export var card_scene: PackedScene = preload("res://components/Card.tscn")

# 卡片容器和布局参数
var cards: Array[Control] = []
@export var card_spacing: float = 20.0
@export var bottom_margin: float = 50.0

# 扇形布局参数
@export var fan_angle: float = 60.0  # 扇形总角度（度）
@export var fan_radius: float = 800.0  # 扇形半径
@export var card_lift: float = 30.0  # 卡片向上抬起的距离

func _ready() -> void:
	# 将卡片管理器添加到组中，方便垃圾桶找到
	add_to_group("card_manager")
	
	# 连接窗口大小改变信号
	resized.connect(_on_resized)
	# 加载九张卡片到页面底部
	load_cards(9)

# 加载指定数量的卡片
func load_cards(count: int) -> void:
	# 清除现有卡片
	clear_cards()
	
	# 创建新卡片
	for i in range(count):
		var card_instance = card_scene.instantiate()
		add_child(card_instance)
		cards.append(card_instance)
	
	# 扇形布局卡片到底部
	arrange_cards_in_fan()

# 将卡片排列成扇形
func arrange_cards_in_fan() -> void:
	if cards.is_empty():
		return
	
	var card_count = cards.size()
	
	# 计算扇形中心点（屏幕底部中央）
	var center_x = size.x / 2.0
	var center_y = size.y + fan_radius - bottom_margin
	
	# 计算每张卡片的角度间隔
	var angle_step = 0.0
	if card_count > 1:
		angle_step = deg_to_rad(fan_angle) / (card_count - 1)
	
	# 起始角度（从左到右）
	var start_angle = deg_to_rad(-fan_angle / 2.0)
	
	# 设置每张卡片的位置和旋转
	for i in range(card_count):
		var card = cards[i]
		
		# 计算当前卡片的角度
		var current_angle = start_angle + i * angle_step
		
		# 计算卡片位置（圆弧上的点）
		var x = center_x + fan_radius * sin(current_angle)
		var y = center_y - fan_radius * cos(current_angle) - card_lift
		
		# 设置卡片位置
		card.position = Vector2(x - 150, y - 220)  # 150和220是卡片的一半尺寸
		
		# 设置卡片旋转角度（朝向扇形中心）
		card.rotation = current_angle
		
		# 设置卡片层级（从左到右按顺序叠放，右边的卡片在上层）
		card.z_index = i

# 清除所有卡片
func clear_cards() -> void:
	for card in cards:
		if is_instance_valid(card):
			card.queue_free()
	cards.clear()

# 窗口大小改变时重新布局
func _on_resized() -> void:
	arrange_cards_in_fan()

# 移除卡片并重新布局
func remove_card(card: Node) -> void:
	if card in cards:
		cards.erase(card)
		# 重新布局剩余卡片
		arrange_cards_in_fan()