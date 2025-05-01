extends Object
class_name AdjucencyMatrixGraph


static func get_delaunay_edges(vertexes: PackedVector2Array) -> PackedInt32Array:
	return Geometry2D.triangulate_delaunay(vertexes)

static func get_empty_adjucency_matrix(vertexes: PackedVector2Array) -> Array:
	var adjucency_matrix = range(vertexes.size())
	for i in adjucency_matrix:
		adjucency_matrix[i] = range(vertexes.size()).map(func (i): return 0)
	
	return adjucency_matrix

static func get_weighted_adjucency_matrix(vertexes: PackedVector2Array, delaunay_edges: PackedInt32Array):
	var adjucency_matrix = get_empty_adjucency_matrix(vertexes)
	
	for i in range(delaunay_edges.size() / 3):
		var index = i * 3

		var first = delaunay_edges[index]
		var second = delaunay_edges[index + 1]
		var third = delaunay_edges[index + 2]
		
		adjucency_matrix[first][second] = vertexes[first].distance_squared_to(vertexes[second])
		adjucency_matrix[first][third] = vertexes[first].distance_squared_to(vertexes[third])
		
		adjucency_matrix[second][first] = vertexes[second].distance_squared_to(vertexes[first])
		adjucency_matrix[second][third] = vertexes[second].distance_squared_to(vertexes[third])
		
		adjucency_matrix[third][first] = vertexes[third].distance_squared_to(vertexes[first])
		adjucency_matrix[third][second] = vertexes[third].distance_squared_to(vertexes[second])
	
	return adjucency_matrix


# Prims Algorithm 
static func get_minimum_spanning_tree(rng: RandomNumberGenerator, vertexes: PackedVector2Array, weighted_adjucency_matrix: Array) -> Array:
	var minimum_spanning_tree = get_empty_adjucency_matrix(vertexes)
	var fringe_vertexes = range(vertexes.size())
	var opened_vertexes = []
	
	var first_vertex = rng.randi_range(0, minimum_spanning_tree.size() - 1)
	fringe_vertexes.erase(first_vertex)
	opened_vertexes.append(first_vertex)
	
	while fringe_vertexes.size() > 0:
		var best_edge
		
		for opened_vertex in opened_vertexes:
			var opened_vertex_edges : Array = weighted_adjucency_matrix[opened_vertex]
			for vertex_index in range(opened_vertex_edges.size()):
				var vertex_weight = opened_vertex_edges[vertex_index]
				if vertex_weight == 0 or not fringe_vertexes.has(vertex_index):
					continue
					
				if best_edge == null or vertex_weight < best_edge.weight:
					best_edge = {
						"opened": opened_vertex,
						"fringe": vertex_index,
						"weight": vertex_weight
					}
					
		if best_edge == null:
			break
		
		fringe_vertexes.erase(best_edge.fringe)
		opened_vertexes.append(best_edge.fringe)
		
		minimum_spanning_tree[best_edge.opened][best_edge.fringe] = 1
		minimum_spanning_tree[best_edge.fringe][best_edge.opened] = 1
	
	return minimum_spanning_tree
