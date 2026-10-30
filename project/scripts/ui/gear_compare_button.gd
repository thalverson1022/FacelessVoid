class_name GearCompareButton
extends Button
## Custom item hover control shared by shop, inventory, rewards and Practice.
## The owning screen supplies a single-item tooltip through tooltip_builder.
## This subclass hosts Control's virtual override so dynamically built Buttons
## can return an arbitrary tooltip Control without duplicating gear formatting.

var tooltip_builder: Callable


func _make_custom_tooltip(_for_text: String) -> Object:
	if tooltip_builder.is_valid():
		return tooltip_builder.call()
	return null
