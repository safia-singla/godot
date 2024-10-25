class_name Hilbert

extends Node2D

var curve: PackedVector2Array

func _init(x:int, y:int, maxlvl:int):
	self.curve = PackedVector2Array()
	_hilbert_step(x, y, 1, maxlvl)

func _hilbert_step(height: float, width: float, level: int, maxlvl: int):
	
# Instructions for drawing the base shape
	if(level == 1):
		self.curve.append(Vector2(height/4.0,3*width/4.0))
		self.curve.append(Vector2(height/4.0,width/4.0))
		self.curve.append(Vector2(3*height/4.0,width/4.0))
		self.curve.append(Vector2(3*height/4.0,3*width/4.0))
	else:
# Create a 2x2 grid of 0.5x size curves, scaling and rotating to create a hilbert curve
		self.curve *= Transform2D().scaled(Vector2(0.5, 0.5))

		var curve1 = self.curve.duplicate()
		
		var curve2 = self.curve.duplicate()
		curve2 *= Transform2D(0, Vector2(-height/2.0, 0))
		
		var curve3 = self.curve.duplicate()
		curve3.reverse()
		curve3 *= Transform2D(PI/2, Vector2(height, -width/2.0))
		
		self.curve.reverse()
		self.curve *= Transform2D(-PI/2, Vector2(-height/2.0, width/2.0))
		
		self.curve.append_array(curve1)
		self.curve.append_array(curve2)
		self.curve.append_array(curve3)

# Recurse if not at requested level
	if level < maxlvl:
		_hilbert_step(height, width, level + 1, maxlvl)

# Draw the 2d space filling curve on the screen:
#func _draw():
	#draw_polyline(curve, Color.RED)
