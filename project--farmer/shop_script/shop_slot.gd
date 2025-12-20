extends PanelContainer

signal buy_clicked(item: ItemData, price: int)

@onready var icon: TextureRect = $HBoxContainer/TextureRect
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var price_label: Label =$HBoxContainer/HBoxContainer/PriceLabel
@onready var buy_button: Button = $HBoxContainer/HBoxContainer/Button

var current_item: ItemData
var current_price: int

func _ready():
	print("✅Slot!")
	buy_button.pressed.connect(func():
		if current_item:
			buy_clicked.emit(current_item, current_price)
	)

func set_shop_item(item: ItemData, price: int = 0):
	current_item = item
	
	current_price = price
	
	icon.texture = item.texture
	name_label.text = item.name
	price_label.text = str(price) + " G"
