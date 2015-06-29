#include <iostream>
#include <cmath>

#ifndef M_2_PI
	#define M_2_PI 6.2832
#endif
#ifndef M_PI_2
	#define M_PI_2 1.5708
#endif
#ifndef M_PI_4
	#define M_PI_4 0.78540
#endif

// morphology
#define EYES 5

// neural network layers size
#define INPUTS EYES
#define HIDDEN_SIZE 6
#define HIDDEN_LAYERS 2
#define OUTPUTS 3

// number of chromosome pairs
#define GENOME_SIZE (HIDDEN_SIZE * (INPUTS + 1) + (HIDDEN_LAYERS - 1) * (HIDDEN_SIZE * (HIDDEN_SIZE + 1)) + OUTPUTS * (HIDDEN_SIZE + 1))
// probability of mutation events
#define CROSSING_OVER_RATE 0.1
#define MUTATION_RATE 0.2

// weights interval
#define INTERVAL 1.0

#include "rnn.cpp"

// constants
#define LIGHT_INTENSITY 1024.0

struct gene {
	double value;
	bool dominant;
};

bool cache_eye_angles = false;
double EYE_ANGLES[EYES];
int CHROMOSOME_LENGTHS[] = {INPUTS + 1, HIDDEN_SIZE + 1, OUTPUTS};
int CHROMOSOME_NUMBER[] = {HIDDEN_SIZE, HIDDEN_SIZE, HIDDEN_SIZE + 1};

class Individual {
	public:
		double fitness = 0.0;
		double rotation;
		double position[2];
		NeuralNetwork* brain;
		gene* mother_genes = nullptr;
		gene* father_genes = nullptr;
		double* expressed_genes;

		static void gen_angles() {
			// generate EYE_ANGLES if not done before
			if (!cache_eye_angles) {
				for (int i = 0; i < EYES; ++i) {
					EYE_ANGLES[i] = (2 * i + 1) * (M_PI_2 / (double)EYES);
				}
				cache_eye_angles = true;
			}
		}

		static Individual* create() {
			gen_angles();
			// creates two random gametes
			gene* gametes[2];
			gametes[0] = new gene[GENOME_SIZE];
			gametes[1] = new gene[GENOME_SIZE];

			for (int i = 0; i < 2; ++i) {
				for (int g = 0; g < GENOME_SIZE; ++g) {
					gametes[i][g].value = fuzzy_rand();
					gametes[i][g].dominant = fuzzy_rand() < 0.0;
				}
			}
			return new Individual(gametes[0], gametes[1]);
		}

		Individual(gene* gamete1, gene* gamete2) {
			this->mother_genes = gamete1;
			this->father_genes = gamete2;
			double* genome = new double[GENOME_SIZE];
			// simulates dominance/recessivity
			#pragma ivdep
			for (int i = 0; i < GENOME_SIZE; ++i) {
				genome[i] =  this->mother_genes[i].dominant ? this->mother_genes[i].value : this->father_genes[i].value;
				genome[i] += this->father_genes[i].dominant ? this->father_genes[i].value : this->mother_genes[i].value;
				genome[i] *= INTERVAL / 2.0;
			}
			setup(genome);
		}
		Individual(double* genome) {
			gen_angles();
			setup(genome);
		}
		void setup(double* genome) {
			this->expressed_genes = genome;
			this->brain = new NeuralNetwork(this->expressed_genes);
			this->reset();
		}

		void reset() {
			this->position[0] = this->position[1] = 0.0;
			this->rotation = M_PI_4;
		}

		void tick(double* food) {
			// outputs are changes to position and orientation
			double delta_x, delta_y, delta_rot;
			auto output = this->brain->forward(this->visibility(food));
			delta_x = output(0);
			delta_y = output(1);
			delta_rot = output(2);
			// rotates displacement
			double sin_rot = sin(this->rotation);
			double cos_rot = cos(this->rotation);
			this->position[0] += delta_x *  cos_rot + delta_y * sin_rot;
			this->position[1] += delta_x * -sin_rot + delta_y * cos_rot;
			this->rotation = fmod(this->rotation + delta_rot * M_2_PI, M_2_PI);
		}

		input_vector_t visibility(double* food) {
			// find inclination of the point (angle of the line between origin and point)
			double x_dist = food[0] - this->position[0];
			double y_dist = food[1] - this->position[1];
			double angle = atan2(y_dist, x_dist);
			// intensity dimishes with the square of the distance... or so
			double d_squared = pow(y_dist, 2) + pow(x_dist, 2);
			double intensity = 2.0 * LIGHT_INTENSITY / d_squared;
			// max and min angle from which you can see 'food'
			double theta_min = asin(1.0 / sqrt(d_squared));
			double theta_max = M_PI_2 - 2.0 * theta_min;
			// rotate wrt the point inclination
			theta_min += angle - M_PI_2;
			theta_max += angle;

			// compute visibility of food for every eye
			double phi[EYES];
			input_vector_t visibility;
			double *raw = &(visibility(0));

			for (int i = 0; i < EYES; ++i) {
				phi[i] = EYE_ANGLES[i] - this->rotation;
			}

			#pragma ivdep
			for (int i = 0; i < EYES; ++i) {
				raw[i] = (theta_min < phi[i]) * (phi[i] < theta_max) * intensity * sin(fabs(atan2(food[1] - sin(phi[i]), food[0] - cos(phi[i])) + phi[i]));
			}

			return visibility;
		}

		void chr_mitosis(gene* gamete, int offset, int chr_length) {
			bool m_or_f;
			int split_loc, mutation_loc;
			// alias for parents genes
			gene* m = this->mother_genes;
			gene* f = this->father_genes;

			// shift to offset
			gamete += offset;

			// toss a coin to choose wheter use a chromosome
			// from the father genes or the mother's as the "main" one
			m_or_f = fuzzy_rand() < 0.0;

			// sometimes, crossing over happens
			if (fuzzy_rand() < (CROSSING_OVER_RATE * 2 - 1)) {
				// draw the locus where to split
				split_loc = floor(chr_length * (fuzzy_rand() + 1) / 2);
				std::memcpy(gamete, (m_or_f ? m : f) + offset, split_loc * sizeof(gene));
				std::memcpy(gamete + split_loc, (m_or_f ? f : m) + offset + split_loc, (chr_length - split_loc) * sizeof(gene));
			} else {
				std::memcpy(gamete, (m_or_f ? m : f) + offset, chr_length * sizeof(gene));
			}

			// sometimes, mutate a gene
			if (fuzzy_rand() < (MUTATION_RATE * 2 - 1)) {
				// mutate a randomly drawn gene
				mutation_loc = floor(chr_length * (fuzzy_rand() + 1) / 2);
				gamete[mutation_loc].value = fuzzy_rand();
				gamete[mutation_loc].dominant = fuzzy_rand() < 0.0;
			}
		}

		gene* gamete() {
			// new genes
			gene *gamete = new gene[GENOME_SIZE];
			int offset = 0;

			for (int c = 0; c < 3; ++c) {
				for (int i = 0; i < CHROMOSOME_NUMBER[c]; i += CHROMOSOME_LENGTHS[c]) {
					this->chr_mitosis(gamete, offset, CHROMOSOME_LENGTHS[c]);
					offset += CHROMOSOME_LENGTHS[c];
				}
			}
			return gamete;
		}

		Individual* mate(Individual* partner) {
			return new Individual(this->gamete(), partner->gamete());
		}

		~Individual() {
			// free allocated memory
			if (this->father_genes != nullptr) delete [] this->father_genes;
			if (this->mother_genes != nullptr) delete [] this->mother_genes;
			delete [] this->expressed_genes;
			delete this->brain;
		}
};
