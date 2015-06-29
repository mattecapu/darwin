#include <iostream>

#include <random>
#include <chrono>


const unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
std::default_random_engine rand_gen(seed);
std::uniform_real_distribution<double> rand_reals(-1, 1);

double fuzzy_rand() {
	return rand_reals(rand_gen);
}

