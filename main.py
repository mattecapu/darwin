from individual import individual
import numpy as np

# parameters
ALG_ITERATIONS = 10000
POPULATION_SIZE = 32 # 64
# a lower value should improve the
# signal-to-noise ratio in the vision system
FOOD_SPREADING = 16
# fitness accuracy
FOOD_LOCATIONS = 8
FITNESS_COMPUTING_ITERATIONS = 32

def further(p):
	if abs(p[0]) < 0.5: p[0] += 0.5
	if abs(p[1]) < 0.5: p[1] += 0.5
	return p

# place food sources in random points on the terrain
food_locations = np.random.rand(FOOD_LOCATIONS, 2) * 2 - 1
food_locations = [further(x)  * FOOD_SPREADING for x in food_locations]
food_distances_sq = [x[0] ** 2 + x[1] ** 2 for x in food_locations]
food_max_distance = np.sqrt(np.amax(food_distances_sq))

# let's populate our world!
population = [individual.create() for x in xrange(POPULATION_SIZE)]

history = open("fitness.m", "a")

for epoch in xrange(ALG_ITERATIONS):
	for nn in population:
		nn.fitness = 0
		for food_i in xrange(FOOD_LOCATIONS):
			food = food_locations[food_i]
			for i in xrange(FITNESS_COMPUTING_ITERATIONS): nn.tick(nn.visibility(food))
			final_food_distance = np.linalg.norm((nn.position[0] - food[0], nn.position[1] - food[1]))
			nn.fitness += (final_food_distance * food_max_distance) / food_distances_sq[food_i]
			nn.reset()
		nn.fitness /= FOOD_LOCATIONS

	population.sort(key = lambda x: x.fitness)
	history.write(str(epoch) + ' ' + str(population[0].fitness) + '\n')

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
