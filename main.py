import rnn
import numpy as np

TERRAIN_SIDE = 1000
POPULATION_SIZE = 100
INPUTS = 17
HIDDENS = 60
OUTPUTS = 5

# a 1000x1000 grid containing informations about
# food and individuals locations
terrain = [[0] * TERRAIN_SIDE] * TERRAIN_SIDE

# populate our world!
population = [rnn.RNN() for x in range(0, POPULATION_SIZE)]
# initialize the individuals
population = map(lambda x: x.init(INPUTS, HIDDENS, OUTPUTS), population)
