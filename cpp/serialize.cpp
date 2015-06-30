#include <iostream>

#include <string>
#include <fstream>
#include <sstream>

#define FITNESS_BUFFER_SIZE 1024
#define ROOT "D:" // "/media/mattecapu/Data"

double fitness_buffer[FITNESS_BUFFER_SIZE][2];
int buffer_index = 0;
bool dir_created = false;

void log_weights(int run, int epoch, Individual* indiv) {
	std::stringstream filename;
	filename << ROOT << "\\www\\darwin\\data\\weights\\" << run;
	if (!dir_created) {
		if (system(("mkdir " + filename.str()).c_str())) {
			std::cout << "warning! weights dir not created" << std::endl;
		}
		dir_created = true;
	}
	filename << "/" <<epoch << ".dat";
	std::ofstream dump_file(filename.str());
	for (int i = 0; i < GENOME_SIZE; ++i) {
		dump_file << indiv->expressed_genes[i] << ' ';
	}
	dump_file.close();
}

void flush_fitness(int run) {
	std::stringstream filename;
	filename << ROOT << "/www/darwin/data/fitness/run" << run << ".m";
	std::ofstream history(filename.str(), std::ios::app);
	#pragma noparallel
	for (int i = 0; i < buffer_index; ++i) {
		history << fitness_buffer[i][0] << " " << fitness_buffer[i][1] << std::endl;
	}
	// just to be sure (read it like a homie)
	history.close();
	buffer_index = 0;
}

void log_fitness(int run, int epoch, double fitness) {
	fitness_buffer[buffer_index][0] = epoch;
	fitness_buffer[buffer_index][1] = fitness;
	++buffer_index;
	if (buffer_index >= FITNESS_BUFFER_SIZE) {
		flush_fitness(run);
	}
}
