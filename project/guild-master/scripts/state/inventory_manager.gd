extends Node

## InventoryManager
## 플레이어의 아이템 소지, 장착 상태를 관리합니다.

signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_equipped(item_id: String)
signal item_unequipped(item_id: String)

var _inventory: Dictionary = {}  # item_id -> { count: int, equipped: bool }


func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not has_node("/root/ItemRegistry") or not ItemRegistry.has_method("has_item"):
		push_warning("InventoryManager: ItemRegistry is missing")
		return false
	if not ItemRegistry.has_item(item_id):
		push_warning("InventoryManager: unknown item_id: " + item_id)
		return false

	var def := ItemRegistry.get_item(item_id)
	var max_stack: int = def.get("max_stack", 99)

	if _inventory.has(item_id):
		var current: int = _inventory[item_id].get("count", 0)
		var new_count: int = mini(current + amount, max_stack)
		_inventory[item_id]["count"] = new_count
		item_added.emit(item_id, new_count - current)
	else:
		_inventory[item_id] = {
			"count": mini(amount, max_stack),
			"equipped": false
		}
		item_added.emit(item_id, amount)
	return true


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if not _inventory.has(item_id):
		return false

	var current: int = _inventory[item_id].get("count", 0)
	var new_count: int = maxi(current - amount, 0)
	_inventory[item_id]["count"] = new_count

	if new_count <= 0:
		_inventory.erase(item_id)
		item_removed.emit(item_id, amount)
	else:
		item_removed.emit(item_id, amount)
	return true


func has_item(item_id: String, amount: int = 1) -> bool:
	if not _inventory.has(item_id):
		return false
	return _inventory[item_id].get("count", 0) >= amount


func get_item_count(item_id: String) -> int:
	if not _inventory.has(item_id):
		return 0
	return _inventory[item_id].get("count", 0)


func equip_item(item_id: String) -> bool:
	if not _inventory.has(item_id):
		return false
	var def := ItemRegistry.get_item(item_id)
	var category: String = def.get("category", "")
	# 동일 카테고리의 다른 아이템 해제
	if category == "weapon" or category == "armor":
		for other_id in _inventory.keys():
			if other_id != item_id:
				var other_def := ItemRegistry.get_item(other_id)
				if other_def.get("category", "") == category and _inventory[other_id].get("equipped", false):
					_inventory[other_id]["equipped"] = false
					item_unequipped.emit(other_id)
	_inventory[item_id]["equipped"] = true
	item_equipped.emit(item_id)
	return true


func unequip_item(item_id: String) -> bool:
	if not _inventory.has(item_id):
		return false
	_inventory[item_id]["equipped"] = false
	item_unequipped.emit(item_id)
	return true


func is_equipped(item_id: String) -> bool:
	if not _inventory.has(item_id):
		return false
	return _inventory[item_id].get("equipped", false)


func get_inventory_data() -> Dictionary:
	return _inventory.duplicate(true)


func set_inventory_data(data: Dictionary) -> void:
	_inventory.clear()
	for item_id in data.keys():
		var entry = data[item_id]
		if typeof(entry) == TYPE_DICTIONARY:
			_inventory[item_id] = {
				"count": entry.get("count", 0),
				"equipped": entry.get("equipped", false)
			}
		else:
			# backward compat: plain int count
			_inventory[item_id] = { "count": int(entry), "equipped": false }


func clear_inventory() -> void:
	_inventory.clear()


func get_all_items() -> Dictionary:
	return _inventory.duplicate(true)
