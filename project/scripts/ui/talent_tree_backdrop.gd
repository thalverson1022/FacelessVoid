extends Node2D
## Decorative canvas item, deliberately not a Control: never enters Container sizing/input.
const PATHS := {
	"tree.assassin":"res://assets/ui/tree_backgrounds/assassin.jpg",
	"tree.bladedancer":"res://assets/ui/tree_backgrounds/bladedancer.jpg",
	"tree.shadow":"res://assets/ui/tree_backgrounds/shadow.jpg",
	"tree.thief":"res://assets/ui/tree_backgrounds/thief.jpg",
}
const DARKNESS := {"tree.assassin":0.65,"tree.bladedancer":0.65,"tree.shadow":0.65,"tree.thief":0.65}
var tree_id := ""
var texture: Texture2D
var interior := Rect2()
var source_rect := Rect2()
func _ready() -> void:
	name="TalentTreeBackdrop"
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	texture=load(PATHS[tree_id])
	var shading:=ShaderMaterial.new()
	shading.shader=preload("res://scripts/ui/talent_tree_backdrop.gdshader")
	material=shading
	get_parent().resized.connect(_sync)
	get_parent().theme_changed.connect(_sync)
	_sync()
static func cover_source(image_size: Vector2,destination_size: Vector2) -> Rect2:
	var scale:=maxf(destination_size.x/image_size.x,destination_size.y/image_size.y)
	var visible_size:=destination_size/scale
	return Rect2((image_size-visible_size)*0.5,visible_size)
func _sync() -> void:
	var frame: PanelContainer=get_parent()
	var style: StyleBoxFlat=frame.get_theme_stylebox("panel")
	var left:=float(style.border_width_left)
	var top:=float(style.border_width_top)
	var right:=float(style.border_width_right)
	var bottom:=float(style.border_width_bottom)
	interior=Rect2(Vector2(left,top),Vector2(maxf(0,frame.size.x-left-right),maxf(0,frame.size.y-top-bottom)))
	if texture!=null and interior.size.x>0 and interior.size.y>0:
		source_rect=cover_source(texture.get_size(),interior.size)
	var shading: ShaderMaterial=material
	shading.set_shader_parameter("rect_origin",interior.position)
	shading.set_shader_parameter("rect_size",interior.size)
	shading.set_shader_parameter("radii",Vector4(maxf(0,style.corner_radius_top_left-maxf(left,top)),maxf(0,style.corner_radius_top_right-maxf(right,top)),maxf(0,style.corner_radius_bottom_left-maxf(left,bottom)),maxf(0,style.corner_radius_bottom_right-maxf(right,bottom))))
	shading.set_shader_parameter("darkness",DARKNESS[tree_id])
	queue_redraw()
func _draw() -> void:
	if texture!=null and interior.size.x>0 and interior.size.y>0:
		draw_texture_rect_region(texture,interior,source_rect)
