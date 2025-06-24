extends VBoxContainer

class_name Keypad

signal code_entered(code: String)

@onready var code = %CodeInput as LineEdit

func _ready() -> void:
	code.text_changed.connect(func(text: String):
		code.text = text.replace("-", "")
		if code.text.length() >= 4:
			code.text = code.text.insert(3, "-")

		code.caret_column = code.text.length()
		code.grab_focus()

		_update_ok_button_state(text))

	_update_ok_button_state(code.text)

	%X.pressed.connect(_on_delete_pressed)
	%OK.pressed.connect(_on_ok_pressed)

	%"0".pressed.connect(func():
		_on_number_pressed(0))
	%"1".pressed.connect(func():
		_on_number_pressed(1))
	%"2".pressed.connect(func():
		_on_number_pressed(2))
	%"3".pressed.connect(func():
		_on_number_pressed(3))
	%"4".pressed.connect(func():
		_on_number_pressed(4))
	%"5".pressed.connect(func():
		_on_number_pressed(5))
	%"6".pressed.connect(func():
		_on_number_pressed(6))
	%"7".pressed.connect(func():
		_on_number_pressed(7))
	%"8".pressed.connect(func():
		_on_number_pressed(8))
	%"9".pressed.connect(func():
		_on_number_pressed(9))


func _update_ok_button_state(text: String) -> void:
	%OK.disabled = text.length() < code.max_length

"""
Handle delete button press. Remove the last character from the code input.
"""
func _on_delete_pressed() -> void:
	code.text = code.text.replace("-", "")
	code.text = code.text.substr(0, code.text.length() - 1)
	code.text_changed.emit(code.text)


"""
Handle number button press. Append the pressed number to the code input.
"""
func _on_number_pressed(number: int) -> void:
	code.text = code.text + str(number)
	code.text_changed.emit(code.text)


"""
Handle OK button press. Emit signal with the entered code.
"""
func _on_ok_pressed() -> void:
	code_entered.emit(code.text.replace("-", ""))
