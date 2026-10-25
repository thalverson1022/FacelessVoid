class_name StrictSaveJson
extends RefCounted
## JSON reader retaining integer tokens and rejecting duplicate keys at every depth.
var source := ""
var offset := 0
var error := ""

static func read(text: String) -> Dictionary:
	var reader := StrictSaveJson.new()
	reader.source = text
	var value: Variant = reader._value(0)
	reader._space()
	if reader.offset != text.length():
		reader.error = "Trailing JSON data."
	return {"data": value, "error": reader.error}

func _space() -> void:
	while offset < source.length() and source[offset] in [" ", "\t", "\r", "\n"]:
		offset += 1

func _value(depth: int) -> Variant:
	_space()
	if depth > 64 or offset >= source.length():
		error = "Incomplete or excessively nested JSON."
		return null
	var c := source[offset]
	if c == '"':
		return _string()
	if c in ["{", "["]:
		offset += 1
		var object := {}
		var array := []
		var close := "}" if c == "{" else "]"
		_space()
		if offset < source.length() and source[offset] == close:
			offset += 1
			return object if c == "{" else array
		while error == "":
			var key: Variant = null
			if c == "{":
				_space()
				if offset >= source.length() or source[offset] != '"':
					break
				key = _string()
				if object.has(key):
					error = "Duplicate JSON key: %s" % str(key)
					return null
				_space()
				if offset >= source.length() or source[offset] != ":":
					break
				offset += 1
			var item: Variant = _value(depth + 1)
			if c == "{":
				object[key] = item
			else:
				array.append(item)
			_space()
			if offset >= source.length():
				break
			var delimiter := source[offset]
			offset += 1
			if delimiter == close:
				return object if c == "{" else array
			if delimiter != ",":
				break
		error = error if error != "" else "Malformed JSON container."
		return null
	var start := offset
	while offset < source.length() and source[offset] not in [",", "}", "]", " ", "\t", "\r", "\n"]:
		offset += 1
	var token := source.substr(start, offset - start)
	var number := RegEx.new()
	number.compile("^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?$")
	if token not in ["true", "false", "null"] and number.search(token) == null:
		error = "Invalid JSON token."
		return null
	var json := JSON.new()
	if token == "" or json.parse(token) != OK:
		error = "Invalid JSON value."
		return null
	var result: Variant = json.data
	if typeof(result) == TYPE_FLOAT:
		if not is_finite(result):
			error = "Non-finite JSON number."
		elif token.is_valid_int():
			# Reject integer overflow instead of silently saturating.
			var digits := token.trim_prefix("-")
			var bound := "9223372036854775808" if token.begins_with("-") else "9223372036854775807"
			if digits.length() > 19 or (digits.length() == 19 and digits > bound):
				error = "Integer outside supported range."
				return null
			var integer := token.to_int()
			if str(integer) != token and token != "-0":
				error = "Integer outside supported range."
			return integer
	return result

func _string() -> Variant:
	var start := offset
	offset += 1
	while offset < source.length():
		var c := source[offset]
		if source.unicode_at(offset) < 32:
			error = "Unescaped control character in JSON string."
			return ""
		offset += 1
		if c == "\\":
			offset += 1
		elif c == '"':
			var json := JSON.new()
			if json.parse(source.substr(start, offset - start)) == OK:
				return json.data
			break
	error = "Invalid JSON string."
	return ""
