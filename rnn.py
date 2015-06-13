import numpy as np

class RNN:
	def __init__(self, (hh, xh, hy)):
		self.W_hh = hh
		self.W_xh = xh
		self.W_hy = hy
		self.reset()

	def reset(self):
		self.h = np.zeros((self.W_hh.shape[0], 1))

	def step(self, x):
		# update the hidden state
		self.h = np.tanh(np.dot(self.W_hh, self.h) + np.dot(self.W_xh, x))
		# compute the output vector
		return np.tanh(np.dot(self.W_hy, self.h));
