import numpy as np

def load_config():
	return {
		# the format should be compatible with Octave, thus we set % as comment char
		"food_distance": np.loadtxt("config.m", comments = "%", dtype = np.int32)
	}
