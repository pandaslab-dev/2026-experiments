extends Node

@onready var game_manager = %GameManager
@onready var final_score = $"final-score"

var score = 0
func add_point():
	score += 1
	print(score)
	final_score.text = "you ate " + str(score) + "/31 cans"
