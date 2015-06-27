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
#define FIELD_OF_VIEW M_PI_2 / EYES

// neural network layers size
#define INPUTS EYES
#define HIDDEN_SIZE 7
#define HIDDEN_LAYERS 3
#define OUTPUTS 3

// number of chromosome pairs
#define APLOID_NUMBER (INPUTS + HIDDEN_SIZE * (HIDDEN_LAYERS - 1) + OUTPUTS)
#define CHROMOSOME_LENGTH HIDDEN_SIZE
// probability of mutation events
#define CROSSING_OVER_RATE 0.1
#define MUTATION_RATE 0.2

#include "rnn.cpp"

// constants
#define LIGHT_INTENSITY 1024

struct gene {
	double value;
	bool dominant;
};

bool cache_eye_angles = false;
double EYE_ANGLES[EYES];

class Individual {
	public:
		double fitness = 0;
		double rotation = M_PI / 4;
		double position[2];
		NeuralNetwork* brain;
		gene* mother_genes;
		gene* father_genes;
		double* expressed_genes;

		static Individual* create(std::function<double()> fuzzy_rand) {
			// generate EYE_ANGLES if not done before
			if (!cache_eye_angles) {
				for (int i = 0; i < EYES; ++i) {
					EYE_ANGLES[i] = (2 * i + 1) * (M_PI_2 / EYES);
				}
				cache_eye_angles = true;
			}

			// creates two random gametes
			gene* gametes[2];
			gametes[0] = new gene[APLOID_NUMBER * CHROMOSOME_LENGTH];
			gametes[1] = new gene[APLOID_NUMBER * CHROMOSOME_LENGTH];

			for (int i = 0; i < 2; ++i) {
				for (int g = 0; g < APLOID_NUMBER * CHROMOSOME_LENGTH; ++g) {
					gametes[i][g].value = fuzzy_rand();
					gametes[i][g].dominant = fuzzy_rand() < 0.5;
				}
			}
			return new Individual(gametes[0], gametes[1]);
		}

		Individual(gene* gamete1, gene* gamete2) {
			this->mother_genes = gamete1;
			this->father_genes = gamete2;
			this->expressed_genes = new double[APLOID_NUMBER * CHROMOSOME_LENGTH];
			// simulates dominance/recessivity
			#pragma ivdep
			for (int g = 0; g < APLOID_NUMBER * CHROMOSOME_LENGTH; ++g) {
				this->expressed_genes[g] = 0;
				this->expressed_genes[g] += this->mother_genes[g].dominant ? this->mother_genes[g].value : this->father_genes[g].value;
				this->expressed_genes[g] += this->father_genes[g].dominant ? this->father_genes[g].value : this->mother_genes[g].value;
				this->expressed_genes[g] /= 2;
			}
			this->brain = new NeuralNetwork(this->expressed_genes);
			this->reset();
		}

		void reset() {
			this->position[0] = this->position[1] = 0;
			this->rotation = M_PI_4;
		}

		void tick(double *food) {
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

		input_t visibility(double *food) {
			// find inclination of the point (angle of the line between origin and point)
			double x_dist = food[0] - this->position[0];
			double y_dist = food[1] - this->position[1];
			double angle = atan2(y_dist, x_dist);
			// intensity dimishes with the square of the distance... or so
			double d_squared = pow(y_dist, 2) + pow(x_dist, 2);
			double intensity = 2 * LIGHT_INTENSITY / d_squared;
			// max and min angle from which you can see 'food'
			double theta_min = asin(1 / sqrt(d_squared));
			double theta_max = M_PI_2 - 2 * theta_min;
			// rotate wrt the point inclination
			theta_min += angle - M_PI_2;
			theta_max += angle;

			// compute visibility of food for every eye
			double phi;
			for (int i = 0; i < EYES; ++i) {
				phi = EYE_ANGLES[i] - this->rotation;
			}
			input_t visibility;
			double *raw = &(visibility(0));
			#pragma ivdep
			for (int i = 0; i < EYES; ++i) {
				raw[i] = (theta_min < phi) * (phi < theta_max) * intensity * sin(fabs(atan2(food[1] - sin(phi), food[0] - cos(phi)) + phi));
			}
			return visibility;
		}

		gene* gamete(std::function<double()> fuzzy_rand) {
			// new genes
			gene *gamete = new gene[APLOID_NUMBER * CHROMOSOME_LENGTH];
			// alias for parents genes
			gene* m = this->mother_genes;
			gene* f = this->father_genes;

			bool m_or_f;
			int split_loc, mutation_loc;

			for (int i = 0; i < APLOID_NUMBER * CHROMOSOME_LENGTH; i += CHROMOSOME_LENGTH) {
				// toss a coin to choose wheter use a chromosome
				// from the father genes or the mother's as the "main" one
				m_or_f = fuzzy_rand() < 0.5;

				// sometimes, crossing over happens
				if (fuzzy_rand() < CROSSING_OVER_RATE) {
					// draw the locus where to split
					split_loc = floor(CHROMOSOME_LENGTH * (fuzzy_rand() + 1) / 2);
					std::memcpy(gamete + i, (m_or_f ? m : f) + i, split_loc * sizeof(gene));
					std::memcpy(gamete + i + split_loc, (m_or_f ? f : m) + i + split_loc, (CHROMOSOME_LENGTH - split_loc) * sizeof(gene));
				} else {
					std::memcpy(gamete + i, (m_or_f ? m : f) + i, CHROMOSOME_LENGTH * sizeof(gene));
				}

				// sometimes, mutate a gene
				if (fuzzy_rand() < MUTATION_RATE) {
					// mutate a randomly drawn gene
					mutation_loc = floor(CHROMOSOME_LENGTH * (fuzzy_rand() + 1) / 2);
					gamete[i + mutation_loc].value = fuzzy_rand();
					gamete[i + mutation_loc].dominant = fuzzy_rand() < 0.5;
				}
			}
			return gamete;
		}

		Individual* mate(Individual* partner, std::function<double()> fuzzy_rand) {
			return new Individual(this->gamete(fuzzy_rand), partner->gamete(fuzzy_rand));
		}

		~Individual() {
			// free allocated memory
			delete [] this->father_genes;
			delete [] this->mother_genes;
			delete [] this->expressed_genes;
			delete this->brain;
		}
};
