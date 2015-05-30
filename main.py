import rnn
import numpy as np

# parameters
TERRAIN_SIDE = 1000
POPULATION_SIZE = 100
FOOD_LOCATIONS = 20
INPUTS = 5
HIDDENS = 20
OUTPUTS = 2

# constants
FOOD = -1

# a 1000x1000 grid containing informations about
# food and individuals locations
terrain = [[0] * TERRAIN_SIDE] * TERRAIN_SIDE

# place food sources in random points on the terrain
food_locations = [np.floor(np.random.rand(2) * TERRAIN_SIDE) for x in range(0, FOOD_LOCATIONS)]
for x in food_locations:
	terrain[x[0]][x[1]] = FOOD

# populate our world!
population = [rnn.RNN() for x in range(0, POPULATION_SIZE)]
# initialize the individuals
population = map(lambda x: x.init(INPUTS, HIDDENS, OUTPUTS), population)
