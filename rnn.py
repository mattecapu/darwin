import numpy as np

class RNN:
	def init(self, input_size, hidden_size, output_size):
		self.W_hh = np.random.randn(hidden_size, hidden_size)
		self.W_xh = np.random.randn(hidden_size, input_size)
		self.W_hy = np.random.randn(output_size, hidden_size)
		self.h = np.zeros((hidden_size, 1))
		return

	def step(self, x):
		# update the hidden state
		self.h = np.tanh(np.dot(self.W_hh, self.h) + np.dot(self.W_xh, x))
		# compute the output vector
		y = np.tanh(np.dot(self.W_hy, self.h));
		return y
