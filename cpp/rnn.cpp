#include <iostream>

#include <Eigen/Dense>
#include <cmath>

using namespace Eigen;

// weights containers
typedef Matrix<double, HIDDEN_SIZE, INPUTS + 1> input_weights_matrix_t;
typedef Matrix<double, HIDDEN_SIZE, HIDDEN_SIZE + 1> hidden_weights_matrix_t;
typedef Matrix<double, OUTPUTS, HIDDEN_SIZE + 1> output_weights_matrix_t;

// input/output vectors
typedef Matrix<double, INPUTS, 1> input_vector_t;
typedef Matrix<double, OUTPUTS, 1> output_vector_t;

// using hyperbolic tangent as activation function
// to have both negative and positive values
std::pointer_to_unary_function<double, double> activation_func(tanh);

class NeuralNetwork {
	Map<input_weights_matrix_t> *input_weights;
	Map<hidden_weights_matrix_t> *hidden_weights[HIDDEN_LAYERS - 1];
	Map<output_weights_matrix_t> *output_weights;

	public:
		NeuralNetwork (double *raw_weights) {
			// maps the memory in raw_weights to Eigen matrices
			this->input_weights = new Map<input_weights_matrix_t>(raw_weights, HIDDEN_SIZE, INPUTS + 1);
			for (int i = 0; i < HIDDEN_LAYERS - 1; ++i) {
				this->hidden_weights[i] =
					new Map<hidden_weights_matrix_t>(raw_weights + (INPUTS + 1 + (i - 1) * (HIDDEN_SIZE + 1)) * HIDDEN_SIZE, HIDDEN_SIZE, HIDDEN_SIZE + 1);
			}
			this->output_weights = new Map<output_weights_matrix_t>(raw_weights + (INPUTS + 1 + (HIDDEN_LAYERS - 1) * (HIDDEN_SIZE + 1)) * HIDDEN_SIZE, OUTPUTS, HIDDEN_SIZE + 1);
		}

		output_vector_t forward(input_vector_t input) {
			//std::cout << "### fw pass" << std::endl;
			Matrix<double, HIDDEN_SIZE + 1, 1> output_with_bias;
			// fill with bias values
			output_with_bias.setOnes();

			// put net input in the vector
			output_with_bias.block<INPUTS, 1>(0, 0) = input;

			// propagate through input layer
			output_with_bias.block<HIDDEN_SIZE, 1>(0, 0) = (*(this->input_weights) * output_with_bias.block<INPUTS + 1, 1>(0, 0)).unaryExpr(activation_func);
			//std::cout << "after input l" << std::endl << output_with_bias << std::endl;

			// propagate through hidden layers
			for (int i = 0; i < HIDDEN_LAYERS - 1; ++i) {
				output_with_bias.block<HIDDEN_SIZE, 1>(0, 0) =
					(*(this->hidden_weights[i]) * output_with_bias.block<HIDDEN_SIZE + 1, 1>(0, 0)).unaryExpr(activation_func);
				//std::cout << "hidden passage no. " << i << std::endl << output_with_bias << std::endl;
			}

			// compute output
			auto xx = (*(this->output_weights) * output_with_bias.block<HIDDEN_SIZE + 1, 1>(0, 0)).unaryExpr(activation_func);
			//std::cout << "output" << std::endl << xx << std::endl;
			if (std::isnan(xx(0))) {
				std::cout << "bad things";
			}
			return xx;
		}

		~NeuralNetwork() {
			delete this->input_weights;
			for (int i = 0; i < HIDDEN_LAYERS - 1; ++i) {
				delete this->hidden_weights[i];
			}
			delete this->output_weights;
		}
};
