import numpy as np
from multiprocessing import Pool
import sys

from individual import individual
from serialize import dump
from load_config import load_config

config = load_config()

# parameters
ITERATIONS = (config["iterations"] if len(sys.argv) < 2 else int(sys.argv[1])) + 1
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
	for (food_x, food_y) in food_locs:
		for i in xrange(FITNESS_COMPUTING_ITERATIONS): indiv.tick(food_x, food_y)
		# the fitness is computed as the fraction of the distance traveled towards the food
		# but because fitness should be maximized and not minimized, we use the shifted reciprocal
		# (1 / (1 + x)) of this quantity, where the shift avoid a vertical asymptote at 0,
		# and the reciprocal invert the trend from descending to ascending
		fitness += 1 / (1 + np.sqrt((indiv.position_x - food_x) ** 2 + (indiv.position_y - food_y) ** 2))
		indiv.reset()
	return fitness / FOOD_LOCATIONS

def sex((partner_1, partner_2)):
	return partner_1.mate(partner_2)

if __name__ == "__main__":
	# flag to disable logging for quick test runs
	DRY_RUN = len(sys.argv) > 2 and sys.argv[2] == "dry"
	# flag to disable parallelization for better testing
	# (error reporting from parallel process is quite shitty)
	PARALLEL = len(sys.argv) > 3 and not sys.argv[3] == "nopar"

	if not DRY_RUN:
		# id of this simulation
		RUN_PREFIX = str(np.random.randint(2 ** 12))

	# place food sources at random points
	# along a circumference with radius FOOD_DISTANCE
	food_locations_x = np.random.rand(1, FOOD_LOCATIONS * ITERATIONS).astype(np.float32) * 2 - 1
	food_locations = zip(
		(food_locations_x * FOOD_DISTANCE)[0],
		(np.random.choice([+1, -1], FOOD_LOCATIONS * ITERATIONS) * np.sqrt(1 - food_locations_x ** 2) * FOOD_DISTANCE).astype(np.float32)[0]
	)

	# let's populate our world!
	population = [individual.create() for x in xrange(POPULATION_SIZE)]

	if not DRY_RUN:
		history = open("data/fitness/run" + str(RUN_PREFIX) + ".m", "w")
		print "simulation", RUN_PREFIX
		print ITERATIONS, " iterations (" + str(ITERATIONS * POPULATION_SIZE * FOOD_LOCATIONS * FITNESS_COMPUTING_ITERATIONS), "cycles)"
		print "\n"

	if PARALLEL:
		# parallel processes pool
		pool = Pool(processes = 4)
		parallelize = pool.map
	else:
		parallelize = map

	for epoch in xrange(ITERATIONS):
		# compute fitness of every individual
		food_locs = food_locations[(epoch * FOOD_LOCATIONS):((epoch + 1)* FOOD_LOCATIONS)]
		fitnesses = parallelize(calc_fitness, [(population[i], food_locs) for i in xrange(POPULATION_SIZE)])
		for i in xrange(POPULATION_SIZE):
			population[i].fitness = fitnesses[i]

		# sort by best fitness (descendent order)
		population.sort(key = lambda x: -x.fitness)

		if not DRY_RUN:
			# log the best fitness
			history.write(str(epoch) + ' ' + str(population[0].fitness) + '\n')
			# dump weights of the best
			if (epoch % (ITERATIONS / DUMPS)) == 0 or epoch == 0:
				dump(RUN_PREFIX, epoch, population[0])
				# log to console
				print epoch, "-> dump at fitness", population[0].fitness
			elif epoch % (ITERATIONS / (DUMPS * 10)) == 0:
				print epoch, "fitness is", population[0].fitness

		# skew to increase mating success for high fitness individuals
		skewed_fitnesses = np.array(fitnesses[:POPULATION_SIZE / 2]) ** 10
		skewed_prob = skewed_fitnesses / sum(skewed_fitnesses)
		matings = zip(*[np.random.choice(POPULATION_SIZE / 2, POPULATION_SIZE, p = skewed_prob) for i in xrange(2)])
		# mates
		children = parallelize(sex, [(population[p1], population[p2]) for (p1, p2) in matings])

		# move on!
		population = children

	if PARALLEL:
		# close the child processes
		pool.close()
		pool.join()

	if not DRY_RUN:
		# don't leave an opened file pointer!
		history.close()

		print "\n", "simulation", RUN_PREFIX, "ended"
