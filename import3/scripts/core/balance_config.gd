extends Node
## BalanceConfig (Autoload: Config) 게임의 모든 밸런스 관련 수치를 중앙 제어합니다.
## 선생이 이 파일 하나만 수정해도 게임 전체의 난이도와 속도가 변합니다.

# [SMARTPHONE SYSTEM]
## 스마트폰 배터리가 1% 소모되는 주기 (단위: 게임 분)
const BATTERY_DRAIN_INTERVAL_MINUTES = 10 

# [GUEST COMPLAINT SYSTEM]
## 층별 패닉 수치가 얼마를 넘어야 민원이 발생하는가?
const COMPLAINT_THRESHOLD = 50.0
## 민원 발생 시 해당 층의 패닉 수치가 줄어드는 비율 (0.5 = 50% 감소)
const COMPLAINT_STRESS_REDUCTION_RATE = 0.5
## 민원 발생 간 최소 쿨다운 (단위: 게임 분)
const COMPLAINT_COOLDOWN_MIN = 30
## 민원 발생 간 최대 쿨다운 (단위: 게임 분)
const COMPLAINT_COOLDOWN_MAX = 60
## 쿨다운 랜덤 생성의 단위 (5분 단위면 35, 40, 45... 식으로 결정됨)
const COMPLAINT_COOLDOWN_STEP = 5

# [SANITY & SURVIVAL]
## 엔티티와 같은 층에 있을 때 10분당 누적되는 기본 스트레스
const ENTITY_FLOOR_STRESS_GAIN = 5.0
## 엔티티가 없는 조용한 층일 때 투숙객 스트레스 10분당 감쇄량
const GUEST_STRESS_DECAY_PER_10MIN = 2.0
## 엔티티와 같은 장소에 있을 때 10분당 깎이는 플레이어 정신력
const SANITY_DAMAGE_PER_10MIN = 5.0
## 정신력이 임계점 이하일 때 컴플레인 전화가 올 추가 확률 보정
const PHONE_CALL_CHANCE_MULT = 0.05

# [TIME SYSTEM]
## '기다리기' 액션 시 소모되는 시간 (단위: 분)
const WAIT_ACTION_TIME_COST = 10
## 장소 이동 시 소모되는 기본 시간 (단위: 분)
const MOVE_TIME_COST = 5
