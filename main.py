from individual import individual
import numpy as np

# parameters
TERRAIN_SIDE = 1000
POPULATION_SIZE = 50
# fitness accuracy
FOOD_LOCATIONS = 10
TRAINING_ITERATIONS = 500

# constants
FOOD = -1

# place food sources in random points on the terrain
food_locations = [tuple(np.int32(np.floor(np.random.rand(2) * TERRAIN_SIDE))) for x in range(0, FOOD_LOCATIONS)]
food_distances = map(lambda x: np.linalg.norm(x), food_locations)
food_max_distance = np.amax(food_distances)

for x in food_locations:
	print x, np.linalg.norm(x)

# let's populate our world!
population = [individual() for x in range(0, POPULATION_SIZE)]

for nn in population:
	nn.fitness = 0
	for food_i in xrange(0, FOOD_LOCATIONS):
		food = food_locations[food_i]
		for i in xrange(0, TRAINING_ITERATIONS): nn.tick(nn.visibility(food))
		final_food_distance = np.linalg.norm((nn.position[0] - food[0], nn.position[1] - food[1]))
		nn.fitness += (final_food_distance * food_max_distance) / (food_distances[food_i] ** 2)
		nn.reset()
	nn.fitness /= FOOD_LOCATIONS
	print nn.fitness

population.sort(key = lambda x: x.fitness)
print map(lambda x: x.fitness, population)
