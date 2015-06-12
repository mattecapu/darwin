import numpy as np

def load_config():
	# the format should be compatible with Octave
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
		"hidden_layer_size": int(config[8]),
		"output_layer_size": int(config[9]),
		"light_intensity": config[10],
		"motion_multiplier": config[11],
		"mutation_rate": config[12],
		"crossing_over_rate": config[13]
	}