extends Control

# 卡片场景预制体
@export var card_scene: PackedScene = preload("res://components/Card.tscn")

# 卡片容器和布局参数
var cards: Array[Control] = []
@export var card_spacing: float = 20.0
@export var bottom_margin: float = 50.0

func _ready() -> void:
	# 连接窗口大小改变信号
	resized.connect(_on_resized)
	# 加载三张卡片到页面底部
	load_cards(3)

# 加载指定数量的卡片
func load_cards(count: int) -> void:
	# 清除现有卡片
	clear_cards()
	
	# 创建新卡片
	for i in range(count):
		var card_instance = card_scene.instantiate()
		add_child(card_instance)
		cards.append(card_instance)
	
	# 布局卡片到底部
	arrange_cards_at_bottom()

# 将卡片排列在页面底部
func arrange_cards_at_bottom() -> void:
	if cards.is_empty():
		return
	
	var card_count = cards.size()
	var card_width = 300.0  # Card.tscn中定义的宽度
	var total_width = card_count * card_width + (card_count - 1) * card_spacing
	
	# 计算起始X位置（居中）
	var start_x = (size.x - total_width) / 2.0
	var y_position = size.y - 440.0 - bottom_margin  # 440是卡片高度
	
	# 设置每张卡片的位置
	for i in range(card_count):
		var card = cards[i]
		var x_position = start_x + i * (card_width + card_spacing)
		card.position = Vector2(x_position, y_position)

# 清除所有卡片
func clear_cards() -> void:
	for card in cards:
		if is_instance_valid(card):
			card.queue_free()
	cards.clear()

# 当窗口大小改变时重新布局
func _on_resized() -> void:
	arrange_cards_at_bottom()