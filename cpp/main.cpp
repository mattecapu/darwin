#include <iostream>

#include <algorithm>
#include <random>
#include <cmath>
#include <chrono>
#include <string>

// parameters
#define POPULATION_SIZE 5 //100
// should be integer divisor of POPULATION_SIZE
#define MATING_POPULATION 1 //10
// a lower value should improve the
// signal-to-noise ratio in the vision system
#define FOOD_DISTANCE 24
// fitness accuracy
#define FOOD_LOCATIONS 2 //8
#define FITNESS_COMPUTING_ITERATIONS 4 //40

#define DUMPS 10

#include "random.cpp"
#include "individual.cpp"
#include "serialize.cpp"

inline double diff_norm(double* b, double* a) {
	return sqrt(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2));
}

int main(int argc, char* argv[]) {
	// parse command line arguments
	const long ITERATIONS = argc < 2 ? 200 : std::atol(argv[1]);
	const bool DRY_RUN = argc > 2 && std::string("dry").compare(argv[2]) == 0;

	// draws a random identifier for this run
	const int RUN_PREFIX = std::uniform_int_distribution<int>(1, 1 << 12)(rand_gen);

	std::cout << "## simulation " << RUN_PREFIX << std::endl;
	std::cout << "## " << ITERATIONS << " iterations" << std::endl;
	std::cout << "## " << (DRY_RUN ? "won't" : "will") << " log data" << std::endl;
	std::cout << std::endl;

	auto start_time = std::chrono::system_clock::now();

	// generates FOOD_LOCATIONS random points for each iteration
	// where collocate the food the creatures should reach
	double food_angle;
	double *food_locations = new double[2 * FOOD_LOCATIONS];

	for (int i = 0; i < FOOD_LOCATIONS; ++i) {
		// spread uniformly angles around pi / 4
		food_angle = M_PI_4 * (1 + 2 * fuzzy_rand());
		food_locations[2 * i] = cos(food_angle) * FOOD_DISTANCE;
		food_locations[2 * i + 1] = sin(food_angle) * FOOD_DISTANCE;
	}

	// allocate memory for the population pool
	Individual* population[2][POPULATION_SIZE];
	Individual** generation = population[0];
	Individual** next_generation = population[1];

	// mating stuff
	double draw;
	double mating_chance[MATING_POPULATION];
	double sum;
	int partner1, partner2;

	for (int i = 0; i < POPULATION_SIZE; ++i) {
		generation[i] = Individual::create();
	}

	for (int iter = 0; iter < ITERATIONS; ++iter) {
		#pragma parallel always
		/*_Cilk_*/for (int i = 0; i < POPULATION_SIZE; ++i) {
			for (int f = 0; f < FOOD_LOCATIONS; ++f) {
				for (int j = 0; j < FITNESS_COMPUTING_ITERATIONS; ++j) {
					generation[i]->tick(food_locations + 2 * f);
				}
				// fitness is what fraction of the distance to food it traveled
				generation[i]->fitness += 1 / (1 + diff_norm(generation[i]->position, food_locations + 2 * f));
				generation[i]->reset();
			}
			// mean of all the tests
			generation[i]->fitness /= FOOD_LOCATIONS;
		}

		// sort population by fitness
		std::sort(generation, generation + POPULATION_SIZE, [](Individual* a, Individual* b) {return a->fitness > b->fitness;});

		if (!DRY_RUN) {
			// log the best fitness
			/*_Cilk_spawn*/ log_fitness(RUN_PREFIX, iter, generation[0]->fitness);
			// dump weights of the best
			if (fmod(iter, ITERATIONS / (1.0 * DUMPS)) < 1 || iter == 0) {
				/*_Cilk_spawn*/ log_weights(RUN_PREFIX, iter, generation[0]);
				std::cout << iter << " -> dump at fitness " << generation[0]->fitness << std::endl;
			}
		} else if (fmod(iter, ITERATIONS / (5.0 * DUMPS)) < 1) {
			std::cout << iter << " fitness is " << generation[0]->fitness << std::endl;
		}

		if (iter != ITERATIONS - 1) {
			for (int i = 0; i < MATING_POPULATION; ++i) {
				// skew the distribution
				mating_chance[i] = pow(generation[i]->fitness, 10);
			}
			sum = 0;
			for (int i = 0; i < MATING_POPULATION; ++i) {
				sum += mating_chance[i];
			}
			for (int i = 0; i < MATING_POPULATION; ++i) {
				// get the percentage of contribution to total fitness
				mating_chance[i] /= sum;
			}
			for (int i = 1; i < MATING_POPULATION; ++i) {
				// cumulate the percentages
				mating_chance[i] += mating_chance[i - 1];
			}

			// find the partners from the cumulated probability
			// draw is a number in the interval [0, 1]
			for (int i = 0; i < POPULATION_SIZE; ++i) {
				partner1 = partner2 = 0;
				draw = (fuzzy_rand() + 1) / 2;
				while(mating_chance[partner1] <= draw && partner1 < MATING_POPULATION) ++partner1;
				draw = (fuzzy_rand() + 1) / 2;
				while(mating_chance[partner2] <= draw && partner2 < MATING_POPULATION) ++partner2;
				// dirty things...
				next_generation[i] = generation[partner1]->mate(generation[partner2]);
			}
		}

		// wait for spawned logging operations
		//if (!DRY_RUN) _Cilk_sync;

		// free the memory allocated by the old generation
		for (int i = 0; i < POPULATION_SIZE; ++i) {
			delete generation[i];
		}

		// switch array
		generation = next_generation;
		next_generation = population[iter % 2 == 0 ? 0 : 1];
	}

	flush_fitness(RUN_PREFIX);

	// stop the stopwatch (lol!!1!1!!)
	auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now() - start_time).count();

	std::cout << std::endl;
	std::cout << "## simulation " << RUN_PREFIX << " ended succesfully" << std::endl;
	std::cout << "## total time: " << total_time / 1000.0 << " seconds" << std::endl;
	std::cout << "## time per iteration: " << total_time / (1000.0 * ITERATIONS) << " seconds" << std::endl;
	std::cout << std::endl << std::endl;

	return EXIT_SUCCESS;
}
