extends RefCounted
class_name TavernSafe
## House rule: the consecutive digits 6-6-6 must never appear in a label,
## score, tile display, or file. This helper builds display text so that
## string never shows up. The forbidden run is built at runtime on purpose,
## so this source file does not contain it either.

static func _forbidden() -> String:
	return "6".repeat(3)


static func number_text(n: int) -> String:
	var raw := str(n)
	var bad := _forbidden()
	if raw.find(bad) == -1:
		return raw
	# Split the run with spaces so the digits are still readable.
	return raw.replace(bad, "6 6 6")


static func contains_forbidden(s: String) -> bool:
	return s.find(_forbidden()) != -1
