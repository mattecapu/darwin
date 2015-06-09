from individual import individual
import numpy as np

# parameters
ALG_ITERATIONS = 100 #1024
POPULATION_SIZE = 32 # 64
# a lower value should improve the
# signal-to-noise ratio in the vision system
FOOD_SPREADING = 32
# fitness accuracy
FOOD_LOCATIONS = 16
TRAINING_ITERATIONS = 16

# constants
FOOD = -1

# place food sources in random points on the terrain
food_locations = [tuple(np.int32(np.floor(np.random.rand(2) * FOOD_SPREADING))) for x in xrange(FOOD_LOCATIONS)]
food_distances = map(lambda x: x[0] ** 2 + x[1] ** 2, food_locations)
food_max_distance = np.sqrt(np.amax(food_distances))

for x in food_locations:
	print x, np.linalg.norm(x)

# let's populate our world!
population = [individual.create() for x in xrange(POPULATION_SIZE)]

for epoch in xrange(ALG_ITERATIONS):
	for nn in population:
		nn.fitness = 0
		for food_i in xrange(FOOD_LOCATIONS):
			food = food_locations[food_i]
			for i in xrange(TRAINING_ITERATIONS): nn.tick(nn.visibility(food))
			final_food_distance = np.linalg.norm((nn.position[0] - food[0], nn.position[1] - food[1]))
			nn.fitness += (final_food_distance * food_max_distance) / food_distances[food_i]
			nn.reset()
		nn.fitness /= FOOD_LOCATIONS

	population.sort(key = lambda x: x.fitness)
	print epoch, "top fitness", population[0].fitness

	children = []
	for nn in population:
		god = np.random.rand()
		if god > 0.1:
			# mate with one of the top 10% of the population
			cupid = np.int32(np.random.rand() * POPULATION_SIZE / 10)
		else:
			# mate with one of the bottom 50% of the population
			cupid = np.int32(POPULATION_SIZE / 10 * (1 + 5 * np.random.rand()))
		children += [nn.mate(population[cupid])]

	# move on!
	population = children
