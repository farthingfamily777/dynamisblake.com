extends RefCounted
## World clock for Casa O'Faydin. Settings live in res://data/world_clock.json.
## Blake's speed: 1 game hour = 20 real minutes (a full day = 8 real hours).

var real_seconds_per_hour := 1200.0
var days_per_season := 7
var seasons: Array = ["Spring", "Summer", "Harvest", "Winter"]
var wait_hours := 1.0
var wake_hour := 6.0
var hour := 7.2      # 0..24
var day := 1         # day 1 is the first day of the game


func load_config(path := "res://data/world_clock.json") -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	real_seconds_per_hour = float(d.get("real_seconds_per_game_hour", real_seconds_per_hour))
	days_per_season = maxi(1, int(d.get("days_per_season", days_per_season)))
	seasons = d.get("seasons", seasons)
	wait_hours = float(d.get("wait_hours", wait_hours))
	wake_hour = float(d.get("sleep_wake_hour", wake_hour))
	hour = float(d.get("start_hour", hour))


func season_ordinal() -> int:
	return (day - 1) / days_per_season


func season_name() -> String:
	return str(seasons[season_ordinal() % seasons.size()])


func year() -> int:
	return season_ordinal() / seasons.size() + 1


func days_to_next_season() -> int:
	return days_per_season - ((day - 1) % days_per_season)


func time_of_day() -> float:
	return hour / 24.0


## Real-time tick. Returns how many seasons began during this tick.
func tick(delta: float) -> int:
	return advance_hours(delta / real_seconds_per_hour)


## Skip ahead. Returns how many seasons began.
func advance_hours(h: float) -> int:
	var before := season_ordinal()
	hour += h
	while hour >= 24.0:
		hour -= 24.0
		day += 1
	return season_ordinal() - before


func wait() -> int:
	return advance_hours(wait_hours)


## Sleep until the next morning.
func sleep() -> int:
	var h := wake_hour - hour
	if h <= 0.5:
		h += 24.0
	return advance_hours(h)


func clock_text() -> String:
	var mins := int(hour * 60.0)
	return "%02d:%02d" % [mins / 60, mins % 60]


func to_dict() -> Dictionary:
	return {"hour": hour, "day": day}


func from_dict(d: Dictionary) -> void:
	hour = clampf(float(d.get("hour", hour)), 0.0, 23.99)
	day = maxi(1, int(d.get("day", day)))
