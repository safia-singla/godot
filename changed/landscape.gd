@tool

extends Node3D
func _ready():
	var land = MeshInstance3D.new()
	
	var noise = _heightmap(256, 256)
	var st = _quadgrid(10, 10, noise)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(noise)
	
	st.generate_normals() # normals point perpendicular up from each face
	var mesh = st.commit() # arranges mesh data structures into arrays for us
	land.mesh = mesh
	land.material_override = material
	add_child(land)
	
	var curve = Hilbert.new(512, 512, 4)
	add_child(curve)
	
	#land.owner = get_tree().edited_scene_root

func _quad(st : SurfaceTool, pt : Vector3, count : Array[int], uvpt: Vector2, uvlen: Vector2, noise):
	st.set_uv( Vector2(uvpt[0], uvpt[1]) )
	st.add_vertex( pt + Vector3(0, (_getHeight(uvpt[0]*(noise.get_height()), uvpt[1]*(noise.get_width()),noise)), 0) ) # vertex 0
	count[0] += 1
	st.set_uv( Vector2(uvpt[0] + uvlen[0], uvpt[1]) )
	st.add_vertex( pt + Vector3(1, (_getHeight((uvpt[0]+uvlen[0])*(noise.get_height()), uvpt[1]*(noise.get_width()),noise)), 0) ) # vertex 1
	count[0] += 1
	st.set_uv( Vector2(uvpt[0] + uvlen[0], uvpt[1] + uvlen[1]) )
	st.add_vertex( pt + Vector3(1, (_getHeight((uvpt[0]+uvlen[0])*(noise.get_height()), (uvpt[1]+uvlen[1])*(noise.get_width()),noise)), 1) ) # vertex 2
	count[0] += 1
	st.set_uv( Vector2(uvpt[0], uvpt[1] + uvlen[1]) )
	st.add_vertex( pt + Vector3(0, (_getHeight(uvpt[0]*(noise.get_height()), (uvpt[1]+uvlen[1])*(noise.get_width()),noise)), 1) ) # vertex 3
	count[0] += 1
	
	st.add_index(count[0] - 4) # make the first triangle
	st.add_index(count[0] - 3)
	st.add_index(count[0] - 2)
	
	st.add_index(count[0] - 4) # make the second triangle
	st.add_index(count[0] - 2)
	st.add_index(count[0] - 1)

func _heightmap(x: int, y: int) -> Image:
# return image of noise with dimensions (x, y)
	var noise = FastNoiseLite.new()
	noise.noise_type = 2
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5  # Higher for more detail
	noise.fractal_gain = 0.9   # Controls the amplitude of each octave
	noise.frequency = 0.01  # Lower frequency for larger, smoother hills
	noise.domain_warp_enabled = true
	noise.domain_warp_frequency = 0.05
	noise.domain_warp_amplitude = 30
	
	return noise.get_image(x, y)
	
func _quadgrid(x: int, z: int, noise: Image) -> SurfaceTool:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES) # mode controls kind of geometry
	var count : Array[int] = [0]
	
	for u in range(x): # corner of grid is at x, z
		for v in range(z):
			_quad(st, Vector3(u, 0, v), count, Vector2(float(u)/x, float(v)/z), Vector2(1.0/x, 1.0/z), noise)
	return st

func _getHeight(x, z, noise:Image) -> float:
	var lightness = noise.get_pixel(floor(x),floor(z)).r
	return lightness
