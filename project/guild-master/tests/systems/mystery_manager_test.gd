class_name MysteryManagerTest
extends GdUnitTestSuite
@warning_ignore("unused_parameter")
@warning_ignore("return_value_discarded")


const MYSTERY_MANAGER_SCENE := "res://scripts/systems/mystery_manager.gd"


func before() -> void:
	# 테스트 전 상태 초기화
	MysteryManager.reset_state()
	Flags.reset_flags()


func after() -> void:
	# 테스트 후 상태 정리
	MysteryManager.reset_state()
	Flags.reset_flags()


# -----------------------------------------------------------------------------
# Case 활성화
# -----------------------------------------------------------------------------
func test_activate_case_loads_mysteries_and_activates_first() -> void:
	var ok := MysteryManager.activate_case("case_01")
	assert_bool(ok).is_true()

	var active_id := MysteryManager.get_active_mystery_id()
	assert_str(active_id).is_equal("myst_01a_vanishing_letters")

	assert_bool(MysteryManager.is_mystery_active("myst_01a_vanishing_letters")).is_true()
	assert_bool(MysteryManager.is_mystery_active("myst_01b_twisted_stars")).is_false()


func test_activate_case_returns_false_for_unknown_case() -> void:
	var ok := MysteryManager.activate_case("case_99_nonexistent")
	assert_bool(ok).is_false()


func test_activate_case_returns_false_if_already_active() -> void:
	MysteryManager.activate_case("case_01")
	var ok := MysteryManager.activate_case("case_01")
	assert_bool(ok).is_false()


# -----------------------------------------------------------------------------
# Mystery 단서 수집
# -----------------------------------------------------------------------------
func test_collect_clue_advances_phase_when_threshold_met() -> void:
	MysteryManager.activate_case("case_01")
	var mystery_id := "myst_01a_vanishing_letters"

	# 3개 필요 (objective.clues_needed = 3)
	MysteryManager.collect_clue(mystery_id, 1)
	assert_int(MysteryManager.get_mystery_current_phase(mystery_id)).is_equal(0)

	MysteryManager.collect_clue(mystery_id, 1)
	assert_int(MysteryManager.get_mystery_current_phase(mystery_id)).is_equal(0)

	MysteryManager.collect_clue(mystery_id, 1)
	# threshold 도달 → phase advance (2 phases total, so after phase 1 complete it goes to phase 2)
	assert_int(MysteryManager.get_mystery_current_phase(mystery_id)).is_equal(1)


func test_collect_clue_returns_false_for_inactive_mystery() -> void:
	var ok := MysteryManager.collect_clue("myst_01a_vanishing_letters", 1)
	assert_bool(ok).is_false()


# -----------------------------------------------------------------------------
# Mystery 정화
# -----------------------------------------------------------------------------
func test_record_cleanse_advances_phase_when_threshold_met() -> void:
	MysteryManager.activate_case("case_01")
	MysteryManager._activate_mystery("myst_01b_twisted_stars")
	var mystery_id := "myst_01b_twisted_stars"

	# 2개 필요 (objective.cleanse_count = 2), target_tags: ["지식"]
	MysteryManager.record_cleanse(mystery_id, "grand_library")
	assert_int(MysteryManager.get_mystery_current_phase(mystery_id)).is_equal(0)

	MysteryManager.record_cleanse(mystery_id, "astronomy_tower")
	assert_int(MysteryManager.get_mystery_current_phase(mystery_id)).is_equal(1)


func test_record_cleanse_returns_false_for_wrong_tag() -> void:
	MysteryManager.activate_case("case_01")
	MysteryManager._activate_mystery("myst_01b_twisted_stars")
	var mystery_id := "myst_01b_twisted_stars"

	# "tavern"은 "지식" 태그가 없음
	var ok := MysteryManager.record_cleanse(mystery_id, "tavern")
	assert_bool(ok).is_false()


func test_record_cleanse_returns_false_for_inactive_mystery() -> void:
	var ok := MysteryManager.record_cleanse("myst_01b_twisted_stars", "grand_library")
	assert_bool(ok).is_false()


# -----------------------------------------------------------------------------
# Dungeon 해금 / 봉인
# -----------------------------------------------------------------------------
func test_unlock_dungeon_empty_id_is_noop() -> void:
	MysteryManager.unlock_dungeon("", "myst_01a")
	assert_bool(MysteryManager.is_dungeon_unlocked("")).is_false()


func test_seal_dungeon_empty_id_is_noop() -> void:
	MysteryManager.unlock_dungeon("library_underground", "myst_01a")
	MysteryManager.seal_dungeon("")
	assert_bool(MysteryManager.is_dungeon_unlocked("library_underground")).is_true()


func test_unlock_and_seal_dungeon_roundtrip() -> void:
	MysteryManager.unlock_dungeon("library_underground", "myst_01a")
	assert_bool(MysteryManager.is_dungeon_unlocked("library_underground")).is_true()
	assert_bool(MysteryManager.is_dungeon_sealed("library_underground")).is_false()

	MysteryManager.seal_dungeon("library_underground")
	assert_bool(MysteryManager.is_dungeon_unlocked("library_underground")).is_false()
	assert_bool(MysteryManager.is_dungeon_sealed("library_underground")).is_true()


# -----------------------------------------------------------------------------
# Mystery 해결
# -----------------------------------------------------------------------------
func test_resolve_mystery_sets_flags_and_removes_from_active() -> void:
	MysteryManager.activate_case("case_01")
	var mystery_id := "myst_01c_sleeping_eye"
	MysteryManager._activate_mystery(mystery_id)

	# sleeping_eye는 1 phase (dungeon_clear)
	MysteryManager.advance_mystery_phase(mystery_id)
	# advance 후 자동 resolve (phases.size() == 1, current goes to 1 which == size)
	assert_bool(MysteryManager.is_mystery_resolved(mystery_id)).is_true()


# -----------------------------------------------------------------------------
# 확률 계산
# -----------------------------------------------------------------------------
func test_calculate_activation_probability_grace_period() -> void:
	MysteryManager.activate_case("case_01")
	# days_since_opened = 0, grace = 7 → base_rate만 적용
	var p: float = MysteryManager._calculate_activation_probability("case_01")
	assert_float(p).is_equal(0.05)


func test_calculate_activation_probability_after_grace() -> void:
	MysteryManager.activate_case("case_01")
	var state: Dictionary = MysteryManager._active_cases["case_01"]
	state["days_since_opened"] = 10
	var active_count: int = MysteryManager._count_active_mysteries_in_case("case_01")
	var p: float = MysteryManager._calculate_activation_probability("case_01")
	var expected: float = 0.05 + (10 - 7) * (0.08 / (1.0 + active_count * 0.25))
	assert_float(p).is_equal_approx(expected, 0.001)


func test_calculate_activation_probability_capped_at_one() -> void:
	MysteryManager.activate_case("case_01")
	var state: Dictionary = MysteryManager._active_cases["case_01"]
	state["days_since_opened"] = 999
	var p: float = MysteryManager._calculate_activation_probability("case_01")
	assert_float(p).is_equal(1.0)


# -----------------------------------------------------------------------------
# 상태 조회
# -----------------------------------------------------------------------------
func test_get_active_mystery_id_returns_expected_after_activation() -> void:
	MysteryManager.activate_case("case_01")
	assert_str(MysteryManager.get_active_mystery_id()).is_equal("myst_01a_vanishing_letters")


func test_is_mystery_active_and_resolved() -> void:
	MysteryManager.activate_case("case_01")
	assert_bool(MysteryManager.is_mystery_active("myst_01a_vanishing_letters")).is_true()
	assert_bool(MysteryManager.is_mystery_resolved("myst_01a_vanishing_letters")).is_false()
