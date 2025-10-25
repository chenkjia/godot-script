extends Control

@onready var card: TextureRect = $CardTexture
@onready var blur: ColorRect = $Blur
@onready var shadow: TextureRect = $Shadow

@export var pick_up_card_scale: Vector2 = Vector2(1.12, 1.12)
@export var pick_up_shadow_scale: Vector2 = Vector2(1.08, 1.08)
@export var pick_up_speed: float = 0.12
@export var pick_up_sigma: float = 2.0

var tween: Tween

func _ready() -> void:
	# 初始：Card 缩放为 1，模糊 sigma 为 0.1；以中心点为基准缩放
	card.scale = Vector2.ONE
	card.pivot_offset = card.size * 0.5
	_set_blur_sigma(0.1)
	# 连接鼠标进入/退出事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	pick_up_card()

func _on_mouse_exited() -> void:
	put_down_card()

# 独立函数：拿起卡片（Card 从 1 动画到 1.2；blur 的 sigma 从 0.1 动画到 2）
func pick_up_card() -> void:
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(card, "scale", pick_up_card_scale, pick_up_speed)
	tween.tween_property(shadow, "scale", pick_up_shadow_scale, pick_up_speed)
	tween.tween_method(_set_blur_sigma, 0.1, pick_up_sigma, pick_up_speed)

# 独立函数：放下卡片（Card 从 1.2 动画回 1；blur 的 sigma 从 2 动画回 0.1）
func put_down_card() -> void:
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, pick_up_speed)
	tween.tween_property(shadow, "scale", Vector2.ONE, pick_up_speed)
	tween.tween_method(_set_blur_sigma, pick_up_sigma, 0.1, pick_up_speed)

# tween_method 用的回调：安全设置 blur 的 shader 参数
func _set_blur_sigma(value: float) -> void:
	var m := blur.material as ShaderMaterial
	if m:
		m.set_shader_parameter("sigma", value)