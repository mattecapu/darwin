#include <iostream>
#inlcude <fstream>

#include <Eigen\Dense>
#include <algorithm>

#include <individual.cpp>

using namespace std;
using namespace Eigen;

// parameters
#define ALG_ITERATIONS 100 //1024
#define POPULATION_SIZE 32 //64
// a lower value should improve the
// signal-to-noise ratio in the vision system
#define FOOD_SPREADING 32
// fitness accuracy
#define FOOD_LOCATIONS 8
#define FITNESS_COMPUTING_ITERATIONS 16

bool fitness_compare(Individual a, Individual b) {
	return a.fitness < b.fitness;
}

ofstream history("fitness.m" ofstream::app)

int main() {
	// generates FOOD_LOCATIONS random points where
	// collocate the food the creatures should reach
	RowVector2d food_locations[FOOD_LOCATIONS];
	double food_distances[FOOD_LOCATIONS];
	double food_max_distance = INT_MAX

	for (int i = 0; i < FOOD_LOCATIONS; ++i) {
		food_locations[i] = (1 + RowVector2d::Random()) * FOOD_SPREADING;
		food_distances[i] = food_locations[i].squaredNorm()
		if (food_max_distance > food_distances[i]) {
			food_max_distance = food_distances[i];
		}
	}

	// allocate memory for the genetic pool
	Individual population[2][POPULATION_SIZE];
	Individual* generation = population[0];
	Individual* next_generation = population[1];

	for (int i = 0; i < POPULATION_SIZE; ++i) {
		generation[i] = Individual::create();
	}

	double final_food_distance;
	// random variables which drive mating
	Matrix<double, 1, POPULATION_SIZE> god, cupid;
	double mate;
	for (int epoch = 0; epoch < ALG_ITERATIONS; ++epoch) {
		for (auto it: generation) {
			it.fitness = 0;
			for (int f = 0; f < FOOD_LOCATIONS; ++f) {
				for (int j = 0; j < FITNESS_COMPUTING_ITERATIONS; ++J) {
					it.tick(it.visibility(food_locations[f]))
				}
				// fitness is what fraction of the distance to food it traveled
				final_food_distance = RowVector2d(
					it.position[0] - food_locations[f][0],
					it.position[1] - food_locations[f][1]
				).norm();
				it.fitness += (final_food_distance * food_max_distance) / food_distances_sq[food_i];
				it.reset();
			}
			it.fitness /= FOOD_LOCATIONS;
		}

		// in place population sorting
		sort(generation, generation + POPULATION_SIZE, fitness_compare);
		// log the best fitness
		history<<epoch<<" "<<generation[0].fitness<<endl;

		god   = .5 + Matrix<double, 1, POPULATION_SIZE>::Random() / 2
		cupid = (.5 + Matrix<double, 1, POPULATION_SIZE>::Random() / 2) * POPULATION_SIZE / 10
		for (int i = 0; i < POPULATION_SIZE; ++i) {
			if (god[i] > 0.1) {
				// mate with one of the best 10% individuals
				mate = (int)(cupid[i])
			} else {
				// mate with one of the best 55% individuals
				mate = (int)(cupid[i] * 5)
			}
			// dirty things...
			next_generation[i] = generation[i].mate(generation[mate]);
		}

		// switch array
		generation = next_generation;
		next_generation = population[generation == population[0] ? 1 : 0];
	}

	history.close();

	return EXIT_SUCCESS;
}
