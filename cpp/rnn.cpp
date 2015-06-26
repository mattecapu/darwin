#include <iostream>

#include <Eigen/Dense>
#include <cmath>

using namespace Eigen;

typedef Matrix<double, HIDDEN_SIZE, Dynamic> transition_t;
typedef Matrix<double, INPUTS, 1> input_t;
typedef Matrix<double, OUTPUTS, 1> output_t;

std::pointer_to_unary_function<double, double> activation_func(tanh);

class NeuralNetwork {
	Map<transition_t> *transition[HIDDEN_LAYERS + 1];

	public:
		NeuralNetwork (double *transition_data) {
			this->transition[0] = new Map<transition_t>(transition_data, HIDDEN_SIZE, INPUTS);
			for (int i = 1; i < HIDDEN_LAYERS; ++i) {
				this->transition[i] = new Map<transition_t>(transition_data + (INPUTS + (i - 1) * HIDDEN_SIZE) * HIDDEN_SIZE, HIDDEN_SIZE, HIDDEN_SIZE);
			}
			this->transition[HIDDEN_LAYERS] = new Map<transition_t>(transition_data + (INPUTS + (HIDDEN_LAYERS - 1) * HIDDEN_SIZE) * HIDDEN_SIZE, HIDDEN_SIZE, OUTPUTS);
		}

		output_t forward(input_t input) {
			Matrix<double, Dynamic, 1> output = input;
			for (int i = 0; i < HIDDEN_LAYERS; ++i) {
				output = (*(this->transition[i]) * output).unaryExpr(activation_func);
			}
			return (this->transition[HIDDEN_LAYERS]->transpose() * output).unaryExpr(activation_func);
		}
};
