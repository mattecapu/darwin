from individual import individual
import numpy as np
from serialize import dump
from load_config import load_config

config = load_config()

# parameters
ITERATIONS = config["iterations"]
POPULATION_SIZE = config["population_size"]
# a lower value should improve the
# signal-to-noise ratio in the vision system
FOOD_DISTANCE = config["food_distance"]
# fitness accuracy
FOOD_LOCATIONS = config["food_locations"]
FITNESS_COMPUTING_ITERATIONS = config["fitness_computing_iterations"]

# number of weights dumps to take
DUMPS = config["dumps"]
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

history = open("data/fitness/run" + str(RUN_PREFIX) + "_" + str(ITERATIONS) + ".m", "w")

print "simulation", RUN_PREFIX
print ITERATIONS, " iterations (" + str(ITERATIONS * POPULATION_SIZE * FOOD_LOCATIONS * FITNESS_COMPUTING_ITERATIONS), "cycles)"
print "\n"

for epoch in xrange(ITERATIONS):
	for nn in population:
		nn.fitness = 0
		for f in xrange(FOOD_LOCATIONS):
			food = food_locations[epoch * FOOD_LOCATIONS + f]
			for i in xrange(FITNESS_COMPUTING_ITERATIONS): nn.tick(nn.visibility(food))
			# the fitness is computed as the fraction of the distance traveled towards the food
			# but because fitness should be maximized and not minimized, we use the shifted reciprocal
			# (1 / (1 + x)) of this quantity, where the shift avoid a vertical asymptote at 0,
			# and the reciprocal invert the trend from descending to ascending
			nn.fitness += FOOD_DISTANCE / (1 + np.linalg.norm((nn.position[0] - food[0], nn.position[1] - food[1])))
			nn.reset()
		nn.fitness /= FOOD_LOCATIONS

	# sort by best fitness
	population.sort(key = lambda x: x.fitness)
	
	history.write(str(epoch) + ' ' + str(population[0].fitness) + '\n')
	# dump weights of the best
	if (epoch % (ITERATIONS / DUMPS)) == 0 or epoch == 0:
		dump(RUN_PREFIX, epoch, population[0])
		# log to console
		print "iteration ", epoch, "-> dump at fitness", population[0].fitness

	children = []
	for nn in population:
		god = np.random.choice(2, p = [0.9, 0.1])
		if god == 0:
			# mate with one of the top 10% of the population
			cupid = np.random.randint(POPULATION_SIZE / 10)
		else:
			# mate with one of the bottom 50% of the population
			cupid = np.int32(POPULATION_SIZE / 10 * (1 + 5 * np.random.rand()))
		children += [nn.mate(population[cupid])]

	# move on!
	population = children

# don't leave a dangling file pointer!
history.close()
