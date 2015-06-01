from individual import individual
import numpy as np

# parameters
ALG_ITERATIONS = 1024
POPULATION_SIZE = 64
FOOD_SPREADING = 512
# fitness accuracy
FOOD_LOCATIONS = 16
TRAINING_ITERATIONS = 512

# constants
FOOD = -1

# place food sources in random points on the terrain
food_locations = [tuple(np.int32(np.floor(np.random.rand(2) * FOOD_SPREADING))) for x in range(0, FOOD_LOCATIONS)]
food_distances = map(lambda x: np.linalg.norm(x), food_locations)
food_max_distance = np.amax(food_distances)

for x in food_locations:
	print x, np.linalg.norm(x)

# let's populate our world!
population = [individual.create() for x in range(0, POPULATION_SIZE)]

for i in xrange(0, ALG_ITERATIONS):
	for nn in population:
		nn.fitness = 0
		for food_i in xrange(0, FOOD_LOCATIONS):
			food = food_locations[food_i]
			for i in xrange(0, TRAINING_ITERATIONS): nn.tick(nn.visibility(food))
			final_food_distance = np.linalg.norm((nn.position[0] - food[0], nn.position[1] - food[1]))
			nn.fitness += (final_food_distance * food_max_distance) / (food_distances[food_i] ** 2)
			nn.reset()
		nn.fitness /= FOOD_LOCATIONS

	population.sort(key = lambda x: x.fitness)
	print "top fitness", population[0].fitness

	children = []
	for nn in population:
		god = np.random.rand()
		if god > 0.1:
			# mate with one of the top 10% of the population
			cupid = np.int32(np.random.rand() * POPULATION_SIZE / 10)
		else:
			# mate with one of the bottom 90% of the population
			cupid = np.int32(POPULATION_SIZE / 10 * (1 + 9 * np.random.rand()))
		children += nn.mate(population[cupid])

	# move on!
	population = children