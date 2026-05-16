extends CanvasLayer

@onready var item_list: VBoxContainer = %ItemList
@onready var item_title: Label = %ItemTitle
@onready var item_icon: TextureRect = %ItemIcon
@onready var item_description: Label = %ItemDescription
@onready var use_button: Button = %UseButton
@onready var close_button: Button = $MainPanel/CloseButton

var _selected_item_id: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_refresh_list()
	_clear_detail_panel()
	use_button.pressed.connect(_on_use_pressed)
	close_button.pressed.connect(_on_close_pressed)
	if has_node("/root/InventoryManager"):
		InventoryManager.item_added.connect(_on_inventory_changed)
		InventoryManager.item_removed.connect(_on_inventory_changed)

func _on_inventory_changed(_item_id: String, _count: int) -> void:
	_refresh_list()
	if _selected_item_id.is_empty() or not InventoryManager.has_item(_selected_item_id):
		_clear_detail_panel()
	else:
		_update_detail_panel(_selected_item_id)

func _refresh_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if not has_node("/root/InventoryManager"):
		return
	var items := InventoryManager.get_all_items()
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "소지품이 없습니다."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(empty_label)
		return

	for item_id in items.keys():
		var entry: Dictionary = items[item_id]
		var def := ItemRegistry.get_item(item_id)
		var display_name: String = def.get("display_name", item_id)
		var count: int = entry.get("count", 0)
		var equipped: bool = entry.get("equipped", false)
		var label_text := display_name
		if count > 1:
			label_text += " x%d" % count
		if equipped:
			label_text += " [E]"

		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_item_selected.bind(item_id))
		item_list.add_child(btn)

func _on_item_selected(item_id: String) -> void:
	_selected_item_id = item_id
	_update_detail_panel(item_id)

func _update_detail_panel(item_id: String) -> void:
	var def := ItemRegistry.get_item(item_id)
	if def.is_empty():
		_clear_detail_panel()
		return

	item_title.text = def.get("display_name", item_id)
	item_description.text = def.get("description", "")

	var icon_path: String = def.get("icon_path", "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)
	else:
		item_icon.texture = null

	var category: String = def.get("category", "")
	var equipped := InventoryManager.is_equipped(item_id)
	match category:
		"weapon", "armor":
			use_button.text = "해제" if equipped else "장착"
		"consumable":
			use_button.text = "사용"
		_:
			use_button.text = "확인"
	use_button.disabled = false

func _clear_detail_panel() -> void:
	_selected_item_id = ""
	item_title.text = ""
	item_description.text = "아이템을 선택하세요."
	item_icon.texture = null
	use_button.text = "사용"
	use_button.disabled = true

func _on_use_pressed() -> void:
	if _selected_item_id.is_empty():
		return
	if not has_node("/root/InventoryManager"):
		return

	var def := ItemRegistry.get_item(_selected_item_id)
	var category: String = def.get("category", "")
	var equipped := InventoryManager.is_equipped(_selected_item_id)

	match category:
		"weapon", "armor":
			if equipped:
				InventoryManager.unequip_item(_selected_item_id)
			else:
				InventoryManager.equip_item(_selected_item_id)
		"consumable":
			_apply_effects(def.get("effects", []))
			InventoryManager.remove_item(_selected_item_id, 1)
		_:
			pass

	_refresh_list()
	if InventoryManager.has_item(_selected_item_id):
		_update_detail_panel(_selected_item_id)
	else:
		_clear_detail_panel()

func _apply_effects(effects: Array) -> void:
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var effect_dict: Dictionary = effect
		var effect_type: String = effect_dict.get("type", "")
		match effect_type:
			"heal":
				var key: String = effect_dict.get("metric_key", "player.hp")
				var amount: int = effect_dict.get("amount", 0)
				MetricStore.change_metric(key, amount)
			"buff":
				var key: String = effect_dict.get("metric_key", "player.attack")
				var amount: int = effect_dict.get("amount", 0)
				MetricStore.change_metric(key, amount)

func _on_close_pressed() -> void:
	queue_free()
