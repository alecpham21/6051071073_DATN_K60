extends LimboHSM
class_name LimboPrimeHSM

@export var character : Character
@export var state_set : Dictionary[StringName, StateSet]
@export var idle_aniset:AnimationSet
@export var walk_aniset:AnimationSet

var ani_set : AnimationSet
var states : Dictionary[StringName, CharacterState]
var prev:CharacterState


func _ready() -> void:
# 1. Gán AnimationSet và tham chiếu cho các state
	#_binding_setup()
	
	# 2. Khởi tạo FSM
	initialize(character)
	
	# 3. Set state bắt đầu (rất quan trọng)
	#if initial_state:
		#set_initial_state(initial_state)
	#else:
		#push_error("LimboPrimeHSM: Chưa gán 'Initial State' trong Inspector!")
		#return
		
	# 4. Kích hoạt FSM
	#set_active(true)
	
	# 5. (Giống code cũ) Dùng để theo dõi state trước đó
	#var map1:= func(cur, _prev): prev = _prev
	#active_state_changed.connect(map1)



func _binding_setup():
	for i : StateSet in state_set.values():
		var key : StringName = state_set.find_key(i)
		
		# Lấy node state từ đường dẫn (path)
		var state : CharacterState = get_node(i.state_path) as CharacterState
		
		# Báo lỗi nếu gõ sai đường dẫn
		if not state:
			push_error("LimboPrimeHSM: state_path wrong in StateSet '%s'" % key)
			continue
		
		if state.play_default_ani: 
			state.ani_set = i.ani_set
		
		# 2. Rất quan trọng: Báo cho state biết "sếp" của nó là ai
		state.limbo_hsm = self 
		
		# 3. Thêm state vào 'từ điển' để dễ tra cứu (nếu cần)
		states.get_or_add(key, state)
