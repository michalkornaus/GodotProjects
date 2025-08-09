extends Node

enum activation {ON_HIT, ON_KILL, BUFF, FLAT, AURA, ON_DEATH}
enum mob_race {HUMAN_KINGDOM, OUTLAWS, MOUNTAIN_CLAN, FOREST_ORCS, BLOOD_BROTHERHOOD, UNDEAD_PACT, MOON_ELVES, SUN_ELVES, BEAST}
enum mob_class {MELEE, RANGED, MAGE}
enum mob_sub_class {ASSASSIN, BANDIT, BLOOD_SUCKER, BRAWLER, DEATH, DEMON, DIVINE, ELEMENTALIST, EVOKER, HAND_OF_JUSTICE, HEALER,
HUNTER, RANGER, SIEDGE, SUPPORT, TANK, WARLOCK, WARRIOR, VETERAN, WIZARD}
enum card_tier {COMMON, RARE, EPIC, LEGENDARY}

var player_stats: Array[PlayerStats]
var wave_time: int = 45
var start_delay_time: int = 15
var winner: String

#static percentages for different barrack levels and card tiers
var common_0: int = 80
var common_1: int = 65
var common_2: int = 50
var common_3: int = 30
var common_4: int = 20

var rare_0: int = 20
var rare_1: int = 30
var rare_2: int = 35
var rare_3: int = 40
var rare_4: int = 40

var epic_0: int = 0
var epic_1: int = 5
var epic_2: int = 13
var epic_3: int = 25
var epic_4: int = 31

var legendary_0: int = 0
var legendary_1: int = 0
var legendary_2: int = 2
var legendary_3: int = 5
var legendary_4: int = 9

#static values
const shop_roll: int = 25
const base_mob_value: int = 3
const base_tower_value: int = 50
const base_barrack_value: int = 100
const base_nexus_value: int = 200

func setup_players(amount: int):
	if !player_stats.is_empty():
		player_stats.clear()
	for index in amount:
		var new_player: PlayerStats = PlayerStats.new() 
		new_player.player_name = "Player" + str(index + 1)
		new_player.gold = 100
		player_stats.append(new_player)
		
func return_tier(level: int):
	var rand_value = randi_range(0, 100)
	if rand_value <= get("common_"+str(level)):
		return 0
	elif rand_value <= (get("common_"+str(level)) + get("rare_"+str(level))):
		return 1
	elif rand_value <= (get("common_"+str(level)) + get("rare_"+str(level)) + get("epic_"+str(level))):
		return 2
	elif rand_value <= (get("common_"+str(level)) + get("rare_"+str(level)) + get("epic_"+str(level)) + get("legendary_"+str(level))):
		return 3
		
var human_kingdom_cards_array: Array
var outlaws_cards_array: Array
var mountain_clan_cards_array: Array
var forest_orcs_cards_array: Array
var blood_brotherhood_cards_array: Array
var undead_pact_cards_array: Array
var moon_elves_cards_array: Array
var sun_elves_cards_array: Array
var beast_cards_array: Array
var test_cards_array: Array

var lolcammove: bool = true

#custom cursors resources
var cursor_default_gold = load("res://Resources/Cursors/DefaultGold.png")
var cursor_circle_black = load("res://Resources/Cursors/CircleBlack.png")
var cursor_circle_green = load("res://Resources/Cursors/CircleGreen.png")
var cursor_circle_red = load("res://Resources/Cursors/CircleRed.png")
var cursors_array: Array = [cursor_default_gold, cursor_circle_black, cursor_circle_green, cursor_circle_red]
var current_cursor = "default"

#static variables for different colors in game
var blue_color: Color = Color.CORNFLOWER_BLUE
var red_color: Color = Color(1, 0.4, 0.3)
var green_color: Color = Color.FOREST_GREEN
var yellow_color: Color = Color(0.7, 0.65, 0.08)
var colors_array: Array = [green_color, red_color, blue_color, yellow_color]

#colors for building teams
var dark_blue_color: Color = Color(0.138, 0.382, 0.586)
var light_blue_color: Color = Color(0.388, 0.702, 0.91)
var dark_red_color: Color = Color(0.824, 0.302, 0.188)
var light_red_color: Color = Color(0.882, 0.435, 0.451)
var dark_green_color: Color = Color(0.188, 0.494, 0.286)
var light_green_color: Color = Color(0.50, 0.91, 0.52)
var dark_yellow_color: Color = Color(0.7, 0.65, 0.08)
var light_yellow_color: Color = Color(0.75, 0.75, 0.1)
var building_colors_array: Array = [dark_green_color, light_green_color, dark_red_color, light_red_color, \
dark_blue_color, light_blue_color, dark_yellow_color, light_yellow_color]

#colors for card's tier
var common_color: Color = Color(0.89, 0.89, 0.89)
var rare_color: Color = Color(0.50, 0.77, 1)
var epic_color: Color = Color.MEDIUM_ORCHID
var legendary_color: Color = Color.DARK_ORANGE

#background colors for card's races
var human_kingdom_color = Color.ROYAL_BLUE
var outlaws_color = Color.DARK_SLATE_BLUE
var mountain_clan_color = Color(0.243, 0.529, 0.427)
var forest_orcs_color = Color(0.244, 0.473, 0.266)
var blood_brotherhood_color = Color(0.314, 0.1, 0.1)
var undead_pact_color = Color(0.357, 0.11, 0.584)
var moon_elves_color = Color(0.75, 0.73, 0.55)
var sun_elves_color = Color(0.75, 0.40, 0)
var beast_color = Color.DARK_SLATE_GRAY

#major versions 0 - alpha, beta | 1 - release
var major_version: int = 0
#minor versions - milestones
var minor_version: int = 2
#commits count - number of commits from github
var commits_count: int = 267
var change_list: int = 136 + commits_count
var current_version: String = "v"+str(major_version)+"."+str(minor_version)+"."+str(change_list)

func dir_contents(path):
	var cards_array: Array[Resource]
	for file_name in DirAccess.get_files_at(path):
		if file_name.get_extension() == "remap":
			file_name = file_name.replace('.remap', '')
		if file_name.get_extension() == "tres":
			var resource = ResourceLoader.load(path+file_name)
			cards_array.append(resource)
	return cards_array
	
func setup_arrays():
	human_kingdom_cards_array = dir_contents("res://Resources/Cards/Human Kingdom/")
	outlaws_cards_array = dir_contents("res://Resources/Cards/Outlaws/")
	mountain_clan_cards_array = dir_contents("res://Resources/Cards/Mountain Clan/")
	forest_orcs_cards_array = dir_contents("res://Resources/Cards/Forest Orcs/")
	blood_brotherhood_cards_array = dir_contents("res://Resources/Cards/Blood Brotherhood/")
	undead_pact_cards_array = dir_contents("res://Resources/Cards/Undead Pact/")
	moon_elves_cards_array = dir_contents("res://Resources/Cards/Moon Elves/")
	sun_elves_cards_array = dir_contents("res://Resources/Cards/Sun Elves/")
	beast_cards_array = dir_contents("res://Resources/Cards/Beast/")
	if OS.is_debug_build():
		test_cards_array = dir_contents("res://Resources/Cards/Test Cards/")

func _ready():
	setup_arrays()
	var version_label: Label = Label.new()
	version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 5)
	version_label.text = "Minion Commander "+current_version
	if OS.is_debug_build():
		version_label.text += " Test build"
	else:
		version_label.text += " Release build"
	add_child(version_label)
