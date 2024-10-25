extends Node3D

@onready var glider = $glider2
@onready var cam = $Camera3D
@onready var marker = $marker

var path : Path3D
var pfollow : PathFollow3D
var n : int
var t : float
var pts : PackedVector3Array
var curr : Vector3
var next : Vector3
var forward : Vector3
var skip : int

# New variables for interpolation and rolling
var tangent_curr : Vector3
var tangent_next : Vector3
var roll_angle : float = 0.0

func _ready():
	skip = 0
	_setup_path()
	pfollow.loop = true     #enable looping for the glider path
	pass
#
func _setup_path():
	path = Path3D.new()
	path.transform = Transform3D.IDENTITY
	var curve := Curve3D.new()
	var N = 8
	var r = 50
	var origin = Vector3(0, 70, 0)
	for k in range(N+1):
		var x = cos(k * 2*PI/float(N))
		var z = sin(k * 2*PI/float(N))
		var pt = r * Vector3(x, 0, z) + origin
		curve.add_point( pt )
	
	for k in range(N):
		var x = cos(k * 2*PI/float(N))
		var z = sin(k * 2*PI/float(N))
		var pt_out = r * (2.0/N)*Vector3(x, 0, z).rotated(Vector3.UP, -PI/2)
		curve.set_point_out(k, pt_out)
		x = cos((k+1) * 2*PI/float(N))
		z = sin((k+1) * 2*PI/float(N))
		var pt_in  = r * (2.0/N)*Vector3(x, 0, z).rotated(Vector3.UP, PI/2)
		curve.set_point_in(k+1, pt_in)
	
	pts = curve.get_baked_points()
	n = len(pts)-1
	for k in range(len(pts)):
		var new_marker = marker.duplicate()
		new_marker.transform *= 0.05
		new_marker.position =  pts[k]
		add_child(new_marker)
	
	path.curve = curve
	pfollow = PathFollow3D.new()
	glider.transform = Transform3D.IDENTITY
	cam.transform = Transform3D.IDENTITY
	cam.position = Vector3(4, 8, -12)
	cam.look_at(glider.position)
	cam.reparent(glider)
	glider.rotate_y(PI)
	glider.reparent(pfollow)
	path.add_child(pfollow)
	pfollow.transform = Transform3D.IDENTITY
	add_child(path)
	marker.transform = Transform3D.IDENTITY
	
	pass

func _process(delta):
	t = fmod(t + delta, 10)  # Keep increasing t with time, looping it between 0 and 10.
	pfollow.progress_ratio = t / 10.0  # Set how far the glider has moved along the path (0 is the start, 1 is the end).

	skip += 1  # Increase the skip counter every frame.
	var roll_amount = 0.0  # Start with no rolling for the glider.

	if (skip % 10 == 0):  # Only do the following every 10 frames to save processing time.
		var k = int(n * t / 10.0)  # Calculate which section of the path the glider is currently in.
		curr = pts[pts.size() - 1] if k > pts.size() - 2 else pts[k]  # Get the current position.
		next = pts[0] if k > pts.size() - 2 else pts[k + 1]  # Get the next position on the path.
		forward = (next - curr).normalized()  # Find the direction from the current point to the next.

		# Calculate the direction (tangent) between the current and next points.
		var tangent_curr = (pts[k + 1] - pts[k]).normalized() if k < pts.size() - 1 else forward
		var tangent_next = (pts[k + 2] - pts[k + 1]).normalized() if k < pts.size() - 2 else forward

		# Find how far along the current section of the path the glider is.
		var percent_traveled = fposmod(pfollow.progress_ratio * n, 1.0)
		# Smoothly blend (interpolate) between the current and next direction based on how far we are.
		var interpolated_tangent = tangent_curr.lerp(tangent_next, percent_traveled)

		# Calculate how far apart the current point and the next are.
		var handle_length_curr = (pts[k + 1] - pts[k]).length()
		# Calculate the distance between the next two points.
		var handle_length_next = (pts[k + 2] - pts[k + 1]).length() if k < pts.size() - 2 else handle_length_curr

		# Find the cross product of these two distances. It helps determine how much to roll the glider.
		var handle_cross = Vector3(handle_length_curr, 0, 0).cross(Vector3(handle_length_next, 0, 0))

		# Multiply the cross product’s length by 0.1 to get the amount of rolling.
		roll_amount = handle_cross.length() * 0.1  # (0.1 is just a factor to scale the effect).

		# Make the roll amount depend on how far along the section the glider has moved.
		var roll_adjustment = interpolated_tangent.length() * 0.1  # Use the tangent’s length to scale it.
		roll_amount = roll_amount * roll_adjustment  # Adjust the roll based on this scaling factor.

	# Apply the rolling effect to the glider:
	var roll_angle = roll_amount * sin(t * 2 * PI / 5)  # Calculate the roll angle, making it oscillate with time.
	var rolling_axis = forward  # The glider will roll around its forward direction.
	glider.rotate_object_local(rolling_axis, roll_angle)  # Apply the rotation (roll) to the glider.

	# Move the marker to follow the glider along the path, keeping it slightly ahead.
	marker.position = lerp(marker.position, pfollow.position + 20 * forward, 0.05)

	# Adjust the glider's orientation (basis) for its rolling motion.
	glider.basis = Basis(Vector3.UP, PI) * Transform3D.IDENTITY.basis  # Reset and rotate around the UP axis.
	glider.basis = Basis(Vector3(0, 0, 1), sin(t * 2 * PI / 5) * -PI / 8.0) * glider.basis  # Add a rotation around Z-axis.
	pass
