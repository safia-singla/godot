extends Path2D

# Number of points for the spline
const NUM_POINTS = 10

# Radius for random point generation
const RADIUS = 200

func _ready():
	# Generate random points
	var points = generate_random_points(NUM_POINTS)
	
	# Add points to the curve
	for point in points:
		curve.add_point(point)
	
	curve.add_point(points[0])
	
	self.curve = curve
	# Visualize path
	draw_path()

# Function to generate random points in a circular area
func generate_random_points(num_points: int) -> Array:
	var points = []
	for i in range(num_points):
		var angle = randf() * TAU  # Random angle 
		var x = cos(angle) * RADIUS + RADIUS
		var y = sin(angle) * RADIUS + RADIUS
		points.append(Vector2(x, y))
	return points

func draw_path():
	var line = Line2D.new()
	add_child(line)
	for i in range(curve.get_point_count()):
		line.add_point(curve.get_point_position(i))
	
	
	line.width = 2
	line.default_color = Color(0.5, 0.8, 1)
