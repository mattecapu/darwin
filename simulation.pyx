cimport cython

cimport numpy as np
import numpy as np

cdef extern from "math.h":
	float sin(float)
	float cos(float)
	float sqrt(float)
	float pow(float, int)

from cython.parallel import prange

cimport individual
import individual
from serialize import dump

# parameters
DEF POPULATION_SIZE = 40
DEF MATING_FRACTION = 0.125
cdef int MATING_POPULATION = <int>(POPULATION_SIZE * MATING_FRACTION)
DEF FOOD_DISTANCE = 24.0

# fitness accuracy
DEF FOOD_LOCATIONS = 8
DEF FITNESS_COMPUTING_ITERATIONS = 40

# number of weights dumps to take
DEF DUMPS = 10

def simulation(ITERATIONS, RUN_PREFIX, DRY_RUN):
	# place food sources at random points
	# along a circumference with radius FOOD_DISTANCE
	cdef int food_samples = FOOD_LOCATIONS * ITERATIONS
	cdef np.ndarray[np.float64_t, ndim = 1] food_locations_angle
	cdef float[:] food_locations_x
	cdef float[:] food_locations_y
	# the locations get farther from the central point as the iterations go
	food_locations_angle = np.pi / 4 * (1 + 2 * (np.random.rand(food_samples) * 2 - 1) * np.arange(1, food_samples + 1) / (food_samples))
	food_locations_x = (np.cos(food_locations_angle) * FOOD_DISTANCE).astype(np.float32)
	food_locations_y = (np.sin(food_locations_angle) * FOOD_DISTANCE).astype(np.float32)

	# let's populate our world!
	cdef list population, children
	population = [individual.create_indiv() for x in range(POPULATION_SIZE)]
	children = [None] * POPULATION_SIZE

	cdef float[1000][2] fitness_buffer
	if not DRY_RUN:
		history = open("data/fitness/run" + str(RUN_PREFIX) + ".m", "w")

	cdef int epoch, i, j, t, k, f
	cdef float food_x, food_y, top_fitness
	try:
		for epoch in range(ITERATIONS):
			# compute fitness of every individual
			for i in range(POPULATION_SIZE):
				for j in range(FOOD_LOCATIONS):
					food_x = food_locations_x[j]
					food_y = food_locations_y[j]
					for t in range(FITNESS_COMPUTING_ITERATIONS):
						population[i].tick(food_x, food_y)
					# the fitness is computed as the fraction of the distance traveled towards the food
					# but because fitness should be maximized and not minimized, we use the shifted reciprocal
					# (1 / (1 + x)) of this quantity, where the shift avoid a vertical asymptote at 0,
					# and the reciprocal invert the trend from descending to ascending
					population[i].fitness += 1 / (1 + sqrt(pow(population[i].position_x - food_x, 2) + pow(population[i].position_y - food_y, 2)))
					population[i].reset()
				population[i].fitness /= FOOD_LOCATIONS

			# sort by best fitness (descendent order)
			population.sort(key = lambda x: -x.fitness)

			if not DRY_RUN:
				top_fitness = population[0].fitness
				if (epoch % 1000) == 0 and not epoch == 0:
					# flush buffer
					for k in range(1000):
						history.write("%f %f\n" % (fitness_buffer[k][0], fitness_buffer[k][1]))
				fitness_buffer[epoch % 1000][0] = <float>epoch
				fitness_buffer[epoch % 1000][1] = top_fitness
				# dump weights of the best
				if (epoch % (ITERATIONS / DUMPS)) == 0 or epoch == 0:
					dump(RUN_PREFIX, epoch, population[0])
					# log to console
					print epoch, "-> dump at fitness", top_fitness
				elif epoch % (ITERATIONS / (DUMPS * 10)) == 0:
					print epoch, "fitness is", top_fitness

			# skew to increase mating success for high fitness individuals
			skewed_fitnesses = np.array([pow(population[i].fitness, 10) for i in range(MATING_POPULATION)])
			skewed_prob = skewed_fitnesses / sum(skewed_fitnesses)
			partners1 = np.random.choice(MATING_POPULATION, POPULATION_SIZE, p = skewed_prob)
			partners2 = np.random.choice(MATING_POPULATION, POPULATION_SIZE, p = skewed_prob)
			# mates
			#for i in prange(POPULATION_SIZE, schedule = "static"):
			for i in range(POPULATION_SIZE):
				children[i] = population[partners1[i]].mate(population[partners2[i]])

			# move on!
			population = children
	finally:
		if not DRY_RUN:
			# flush the remaining data in buffers
			for f in range(epoch % 1000):
				history.write("%f %f\n" % (fitness_buffer[f][0], fitness_buffer[f][1]))
			# close the file
			history.close()
