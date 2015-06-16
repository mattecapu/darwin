import numpy as np

def load_config():
	# the format should be compatible with Octave, thus we set % as comment char
	config = np.loadtxt("config.m", comments = "%", dtype = np.float32)
	return {
		"iterations": int(config[0]),
		"population_size": int(config[1]),
		"food_distance": config[2],
		"food_locations": int(config[3]),
		"fitness_computing_iterations": int(config[4]),
		"dumps": int(config[5]),
		"behaviour_logging_iterations": int(config[6]),
		"eyes": int(config[7]),
		"hidden_layers": int(config[8]),
		"hidden_layers_size": int(config[9]),
		"output_layer_size": int(config[10]),
		"light_intensity": config[11],
		"mutation_rate": config[12],
		"crossing_over_rate": config[13],
		"mating_fraction": config[14]
	}
