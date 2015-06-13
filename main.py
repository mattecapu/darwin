import numpy as np
from multiprocessing import Pool

from individual import individual
from serialize import dump
from load_config import load_config

config = load_config()

# parameters
ITERATIONS = config["iterations"] + 1
POPULATION_SIZE = config["population_size"]
# a lower value should improve the
# signal-to-noise ratio in the vision system
FOOD_DISTANCE = config["food_distance"]
# fitness accuracy
FOOD_LOCATIONS = config["food_locations"]
FITNESS_COMPUTING_ITERATIONS = config["fitness_computing_iterations"]

# number of weights dumps to take
DUMPS = config["dumps"]

def calc_fitness((indiv, food_locs)):
	fitness = 0
	for food in food_locs:
		for i in xrange(FITNESS_COMPUTING_ITERATIONS): indiv.tick(indiv.visibility(food))
		# the fitness is computed as the fraction of the distance traveled towards the food
		# but because fitness should be maximized and not minimized, we use the shifted reciprocal
		# (1 / (1 + x)) of this quantity, where the shift avoid a vertical asymptote at 0,
		# and the reciprocal invert the trend from descending to ascending
		fitness += 1 / (1 + np.linalg.norm(indiv.position - food))
		indiv.reset()
	return fitness / FOOD_LOCATIONS

def sex((partner_1, partner_2)):
	return partner_1.mate(partner_2)

if __name__ == "__main__":
	# id of this simulation
	RUN_PREFIX = str(np.random.randint(2 ** 12))

	# place food sources at random points
	# along a circumference with radius FOOD_DISTANCE
	food_locations_x = np.random.rand(1, FOOD_LOCATIONS * ITERATIONS) * 2 - 1
	food_locations = np.vstack([
		food_locations_x,
		np.random.choice([+1, -1], FOOD_LOCATIONS * ITERATIONS) * np.sqrt(1 - food_locations_x ** 2)
	]).T * FOOD_DISTANCE

	# let's populate our world!
	population = [individual.create() for x in xrange(POPULATION_SIZE)]

	history = open("data/fitness/run" + str(RUN_PREFIX) + ".m", "w")

	print "simulation", RUN_PREFIX
	print ITERATIONS, " iterations (" + str(ITERATIONS * POPULATION_SIZE * FOOD_LOCATIONS * FITNESS_COMPUTING_ITERATIONS), "cycles)"
	print "\n"

	# generate in advance the matings (e.g. pairs of index biased with fitness)
	best_bias = np.random.choice(2, ITERATIONS * POPULATION_SIZE, p = [0.9, 0.1])
	top10 = np.random.randint(-POPULATION_SIZE / 2, 0, size = ITERATIONS * POPULATION_SIZE)
	top50 = np.random.randint(POPULATION_SIZE / 10, size = ITERATIONS * POPULATION_SIZE)
	matings = (top10 * (best_bias - 1)) + (top50 * best_bias)

	# parallel process pool
	pool = Pool(processes = 4)

	for epoch in xrange(ITERATIONS):
		# compute fitness of every individual
		fitnesses = pool.map(calc_fitness, [(population[i], food_locations[(epoch * FOOD_LOCATIONS):((epoch + 1)* FOOD_LOCATIONS)]) for i in xrange(POPULATION_SIZE)])
		for i in xrange(POPULATION_SIZE):
			population[i].fitness = fitnesses[i]

		# sort by best fitness (descendent order)
		population.sort(key = lambda x: -x.fitness)

		# log the best fitness
		history.write(str(epoch) + ' ' + str(population[0].fitness) + '\n')

		# dump weights of the best
		if (epoch % (ITERATIONS / DUMPS)) == 0 or epoch == 0:
			dump(RUN_PREFIX, epoch, population[0])
			# log to console
			print epoch, "-> dump at fitness", population[0].fitness
		elif epoch % (ITERATIONS / (DUMPS * 10)) == 0:
			print epoch, "fitness is", population[0].fitness

		# process the matings
		children = pool.map(sex, [(population[matings[epoch * POPULATION_SIZE + i]], population[i]) for i in xrange(POPULATION_SIZE)])

		# move on!
		population = children

	pool.join()
	pool.close()

	# don't leave an opened file pointer!
	history.close()
