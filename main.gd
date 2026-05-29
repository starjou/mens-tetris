extends Node2D

const BUFFER_ROWS = 4
const COLS = 10
const ROWS = 20
const CELL_SIZE = 32

var board = []

var lock_timer = 0.0
var lock_delay = 0.5
var is_landing = false

var rotate_pressed = false

var visual_pos = Vector2(3, 0)

var next_piece = null
var next_color = null

var score = 0
var level = 1
var total_lines = 0

const TETROMINOES = [
	[[1, 1, 1, 1]],
	[[1, 1], [1, 1]],
	[[0, 1, 0], [1, 1, 1]],
	[[0, 0, 1], [1, 1, 1]],
	[[1, 1, 1], [0, 0, 1]],
	[[0, 1, 1], [1, 1, 0]],
	[[1, 1, 0], [0, 1, 1]],
]

const COLORS = [
	Color.CYAN,
	Color.YELLOW,
	Color.PURPLE,
	Color.ORANGE,
	Color.BLUE,
	Color.GREEN,
	Color.RED,
]

var current_piece = null
var current_color = null
var current_pos = Vector2(3, 0)
var fall_timer = 0.0
var fall_speed = 0.5

var touch_left = false
var touch_right = false
var touch_down = false
var touch_timer = 0.0
var touch_delay = 0.1

func _ready():
	init_board()
	next_piece = null
	spawn_piece()
	$UI/GameOverScreen.visible = false
	$UI/GameOverScreen/VBoxContainer/Button.pressed.connect(restart)

	$UI/TouchControls/BtnLeft.button_down.connect(_on_btn_left_down)
	$UI/TouchControls/BtnLeft.button_up.connect(_on_btn_left_up)
	$UI/TouchControls/BtnRight.button_down.connect(_on_btn_right_down)
	$UI/TouchControls/BtnRight.button_up.connect(_on_btn_right_up)
	$UI/TouchControls/BtnDown.button_down.connect(_on_btn_down_down)
	$UI/TouchControls/BtnDown.button_up.connect(_on_btn_down_up)
	$UI/TouchControls/BtnRotate.pressed.connect(_on_btn_rotate)

	$BGM.finished.connect(func(): $BGM.play())


func _on_btn_left_down(): touch_left = true
func _on_btn_left_up(): touch_left = false
func _on_btn_right_down(): touch_right = true
func _on_btn_right_up(): touch_right = false
func _on_btn_down_down(): touch_down = true
func _on_btn_down_up(): touch_down = false
func _on_btn_rotate(): rotate_piece()

func init_board():
	for row in range(ROWS + BUFFER_ROWS):
		board.append([])
		for col in range(COLS):
			board[row].append(0)

func spawn_piece():
	if next_piece == null:
		var idx = randi() % TETROMINOES.size()
		next_piece = TETROMINOES[idx]
		next_color = COLORS[idx]

	current_piece = next_piece
	current_color = next_color
	current_pos = Vector2(3, BUFFER_ROWS - current_piece.size())
	fall_timer = fall_speed
	visual_pos = Vector2(3, BUFFER_ROWS - current_piece.size())

	# 產生下一個
	var next_idx = randi() % TETROMINOES.size()
	next_piece = TETROMINOES[next_idx]
	next_color = COLORS[next_idx]

	if not is_valid_position(current_piece, current_pos):
		current_piece = null
		game_over()

func game_over():
	if not $SoundGameOver.playing:
		$SoundGameOver.play()
	current_piece = null
	set_process(false)
	$UI/GameOverScreen.visible = true

func _process(delta):
	if current_piece == null:
		return

	visual_pos = visual_pos.lerp(current_pos, delta * 20)
	visual_pos.y = min(visual_pos.y, current_pos.y)

	if is_landing:
		lock_timer += delta
		if lock_timer >= lock_delay:
			lock_timer = 0.0
			is_landing = false
			visual_pos = current_pos
			lock_piece()
			spawn_piece()
	else:
		fall_timer += delta
		if fall_timer >= fall_speed:
			fall_timer = 0.0
			move_down()

	if touch_left or touch_right or touch_down:
		touch_timer += delta
		if touch_timer >= touch_delay:
			touch_timer = 0.0
			if touch_left:
				var new_pos = Vector2(current_pos.x - 1, current_pos.y)
				if is_valid_position(current_piece, new_pos):
					current_pos = new_pos
					$SoundMove.play()
			if touch_right:
				var new_pos = Vector2(current_pos.x + 1, current_pos.y)
				if is_valid_position(current_piece, new_pos):
					current_pos = new_pos
					$SoundMove.play()
			if touch_down:
				if not is_landing:
					move_down()
					$SoundMove.play()
	else:
		touch_timer = touch_delay

	queue_redraw()

func _input(event):
	if current_piece == null or not event is InputEventKey:
		return
	# print("BGM volume on input: ", $BGM.volume_db)
	if event.pressed:
		match event.keycode:
			KEY_LEFT:
				var new_pos = Vector2(current_pos.x - 1, current_pos.y)
				if is_valid_position(current_piece, new_pos):
					current_pos = new_pos
					$SoundMove.play()
					if is_landing:
						lock_timer = 0.0
						# 檢查新位置下方還有沒有空間
						if is_valid_position(current_piece, Vector2(current_pos.x, current_pos.y + 1)):
							is_landing = false
			KEY_RIGHT:
				var new_pos = Vector2(current_pos.x + 1, current_pos.y)
				if is_valid_position(current_piece, new_pos):
					current_pos = new_pos
					$SoundMove.play()
					if is_landing:
						lock_timer = 0.0
						if is_valid_position(current_piece, Vector2(current_pos.x, current_pos.y + 1)):
							is_landing = false
			KEY_DOWN:
				if not is_landing:
					$SoundMove.play()
					move_down()
			KEY_UP:
				if not rotate_pressed:
					rotate_piece()
					if is_landing:
						lock_timer = 0.0
						if is_valid_position(current_piece, Vector2(current_pos.x, current_pos.y + 1)):
							is_landing = false
					rotate_pressed = true

	else:
		match event.keycode:
			KEY_UP:
				rotate_pressed = false

func rotate_piece():
	var rotated = []
	var rows = current_piece.size()
	var cols = current_piece[0].size()
	for col in range(cols - 1, -1, -1):
		rotated.append([])
		for row in range(rows):
			rotated[cols - 1 - col].append(current_piece[row][col])
	if is_valid_position(rotated, current_pos):
		current_piece = rotated
		$SoundMove.play()
		if is_landing:
			lock_timer = 0.0
			if is_valid_position(current_piece, Vector2(current_pos.x, current_pos.y + 1)):
				is_landing = false

func move_down():
	current_pos.y += 1
	if not is_valid_position(current_piece, current_pos):
		current_pos.y -= 1
		is_landing = true
		lock_timer = 0.0
	else:
		is_landing = false
		lock_timer = 0.0

func is_valid_position(piece, pos):
	for row in range(piece.size()):
		for col in range(piece[row].size()):
			if piece[row][col] == 1:
				var new_x = pos.x + col
				var new_y = pos.y + row
				if new_x < 0 or new_x >= COLS:
					return false
				if new_y >= ROWS + BUFFER_ROWS:
					return false
				if new_y >= 0 and board[new_y][new_x] is Color:
					return false
	return true

func lock_piece():
	$SoundLock.play()
	for row in range(current_piece.size()):
		for col in range(current_piece[row].size()):
			if current_piece[row][col] == 1:
				board[current_pos.y + row][current_pos.x + col] = current_color
	clear_lines()

func clear_lines():
	var lines_cleared = 0
	var row = ROWS + BUFFER_ROWS - 1
	while row >= 0:
		var full = true
		for col in range(COLS):
			if not (board[row][col] is Color):
				full = false
				break
		if full:
			board.remove_at(row)
			board.insert(0, [])
			for col in range(COLS):
				board[0].append(0)
			lines_cleared += 1
		else:
			row -= 1

	if lines_cleared > 0:
		if not $SoundClear.playing:
			$SoundClear.play()
		total_lines += lines_cleared
		score += lines_cleared * 100 * level
		level = int(score / float(500)) + 1
		fall_speed = max(0.05, 0.5 * pow(0.85, level - 1))

	return lines_cleared

func restart():
	$UI/GameOverScreen.visible = false
	$UI/GameOverScreen/VBoxContainer/Button.release_focus()
	board.clear()
	init_board()
	score = 0
	level = 1
	total_lines = 0
	fall_speed = 0.5
	fall_timer = 0.0
	lock_timer = 0.0
	is_landing = false
	next_piece = null
	set_process(true)
	spawn_piece()

func _draw():
	for row in range(ROWS):
		var board_row = row + BUFFER_ROWS
		for col in range(COLS):
			var rect = Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE - 1, CELL_SIZE - 1)
			if board[board_row][col] is Color:
				draw_rect(rect, board[board_row][col])
			else:
				draw_rect(rect, Color(0.2, 0.2, 0.2, 0.7))

	if current_piece:
		for row in range(current_piece.size()):
			for col in range(current_piece[row].size()):
				if current_piece[row][col] == 1:
					var draw_y = visual_pos.y + row - BUFFER_ROWS
					if draw_y >= -1:
						var rect = Rect2(
							(visual_pos.x + col) * CELL_SIZE,
							draw_y * CELL_SIZE,
							CELL_SIZE - 1,
							CELL_SIZE - 1
						)
						draw_rect(rect, current_color)

	# 畫預覽
	if next_piece:
		# 畫預覽框
		var preview_offset_x = (COLS + 1) * CELL_SIZE - 16
		var preview_offset_y = 1 * CELL_SIZE - 48
		var piece_width = next_piece[0].size()
		var piece_height = next_piece.size()
		var offset_x = (4 - piece_width) / 2.0
		var offset_y = (4 - piece_height) / 2.0

		for row in range(piece_height):
			for col in range(piece_width):
				if next_piece[row][col] == 1:
					var rect = Rect2(
						preview_offset_x  + (col + offset_x) * CELL_SIZE,
						preview_offset_y + (row + offset_y) * CELL_SIZE,
						CELL_SIZE - 1,
						CELL_SIZE - 1
					)
					draw_rect(rect, next_color)

	# 畫分數和等級
	$UI/ScorePanel/LabelScore.text = "SCORE\n" + str(score)
	$UI/ScorePanel/LabelLevel.text = "LEVEL\n" + str(level)
	$UI/ScorePanel/LabelLines.text = "LINES\n" + str(total_lines)
