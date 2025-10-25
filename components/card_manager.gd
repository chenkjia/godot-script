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

# 拖动散开效果参数
var dragging_card: Control = null
@export var spread_strength: float = 40.0  # 拿起时两侧卡片横向散开的强度（像素）
@export var spread_falloff: float = 0.35   # 距离选中卡片越远，散开越小（每隔一张乘以这个系数）

func _ready() -> void:
	# 将卡片管理器添加到组中，方便垃圾桶找到
	add_to_group("card_manager")
	
	# 连接窗口大小改变信号
	resized.connect(_on_resized)
	# 加载三张卡片到页面底部（测试少量卡片的集中效果）
	load_cards(10)

# 加载指定数量的卡片
func load_cards(count: int) -> void:
	clear_cards()
	for i in range(count):
		var c := card_scene.instantiate()
		add_child(c)
		cards.append(c)
		# 连接卡片的交互信号
		c.drag_started.connect(_on_card_drag_started)
		c.card_cancel_play.connect(_on_card_cancel_play)
		c.card_destroyed.connect(_on_card_destroyed)
	arrange_cards_in_fan()

# 将卡片排列成扇形
func arrange_cards_in_fan() -> void:
	var n := cards.size()
	if n == 0:
		return
	var center := Vector2(size.x * 0.5, size.y + fan_radius - bottom_margin)
	var total := calculate_dynamic_fan_angle(n)
	var start := -deg_to_rad(total) * 0.5
	var step := deg_to_rad(total) / (n - 1) if n > 1 else 0.0
	var di := cards.find(dragging_card) if dragging_card and dragging_card in cards else -1
	for i in range(n):
		var a := start + i * step
		var card := cards[i]
		if di == i:
			card.z_index = i
			continue
		var pos := Vector2(
			center.x + fan_radius * sin(a) - 150,
			center.y - fan_radius * cos(a) - card_lift - 220
		)
		if di != -1:
			pos.x += (-1 if i < di else 1) * spread_strength * pow(1.0 - spread_falloff, abs(i - di) - 1)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(card, "position", pos, 0.12)
		tw.tween_property(card, "rotation", a, 0.12)
		card.z_index = i

# 动态计算扇形角度的算法
func calculate_dynamic_fan_angle(card_count: int) -> float:
	# 基础参数
	var min_angle = 0.0  # 单张卡片时的角度
	var max_angle = fan_angle  # 最大扇形角度
	var optimal_card_count = 8.0  # 达到最大角度的理想卡片数量
	
	# 使用平滑曲线算法：基于反比例函数的变体
	# 公式：angle = max_angle * (1 - e^(-k * count))
	# 其中 k 是控制曲线陡峭程度的参数
	var k = 2.0 / optimal_card_count  # 调节参数，控制增长速度
	var normalized_angle = 1.0 - exp(-k * card_count)
	
	# 应用最小角度限制和平滑过渡
	var calculated_angle = max_angle * normalized_angle
	
	# 对于极少数卡片，应用额外的压缩
	if card_count <= 2:
		calculated_angle *= 0.3  # 1-2张卡片时进一步压缩
	
	return max(min_angle, calculated_angle)

# 开始拖动时，让其他卡片轻微散开
func begin_drag_spread(card: Control) -> void:
	dragging_card = card
	arrange_cards_in_fan()

# 结束拖动或卡片销毁后，恢复布局
func end_drag_spread() -> void:
	dragging_card = null
	arrange_cards_in_fan()

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

func _on_card_drag_started(card: Control) -> void:
	dragging_card = card
	arrange_cards_in_fan()

func _on_card_cancel_play(card: Control) -> void:
	if dragging_card == card:
		dragging_card = null
	arrange_cards_in_fan()

func _on_card_destroyed(card: Control) -> void:
	if dragging_card == card:
		dragging_card = null
	arrange_cards_in_fan()