#include <iostream>
#include <fstream>

#include "random.cpp"
#include "individual.cpp"

#define ROOT "D:" // "/media/mattecapu/Data"

int main(int argc, char* argv[]) {
	if (argc < 4) {
		std::cout << "please provide run, epoch and iterations" << std::endl;
		return EXIT_FAILURE;
	}
	std::string run(argv[1]);
	std::string epoch(argv[2]);
	std::string root(ROOT);
	long ITERATIONS = std::atol(argv[3]);
	double* weights = new double[GENOME_SIZE];

	if (system(("mkdir " + root + "\\www\\darwin\\data\\behaviours\\" + run).c_str())) {
		// prevent compiler warning, ah-ah!
	}
	std::ifstream weights_file(root + "/www/darwin/data/weights/" + run + "/" + epoch + ".dat");
	std::ofstream log_file(root + "/www/darwin/data/behaviours/" + run + "/" + epoch + ".dat");

	for (int i = 0; i < GENOME_SIZE; ++i) {
		weights_file >> weights[i];
	}

	double food[] = {24 / sqrt(2), 24 / sqrt(2)};
	Individual subject(weights);

	for (int i = 0; i < ITERATIONS; ++i) {
		log_file << i << " "
				 << subject.position[0] << " "
				 << subject.position[1] << " "
				 << subject.rotation << std::endl;
		subject.tick(food);
	}

	return EXIT_SUCCESS;
}
