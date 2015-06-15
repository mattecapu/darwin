import numpy as np

class RNN:
	# transitions -> list of weight matrices of the synapses between layer n-1 and n
	# recurrences -> weights tensor of the recurrence synapses
	def __init__(self, recurrences, transitions):
		self.recurrences = recurrences
		self.transitions = transitions
		(self.hidden_layers, self.layers_size) = self.recurrences.shape[:2]
		self.hiddens = np.zeros((self.hidden_layers, self.layers_size, 1))

	def reset(self):
		# set to zero in-place
		self.hiddens *= 0

	def forward(self, x):
		prev_output = x
		for i in xrange(self.hidden_layers):
			# update the hidden state
			self.hiddens[i] = np.tanh(np.dot(self.recurrences[i], self.hiddens[i]) + np.dot(self.transitions[i], prev_output))
			# computes the layer output
			prev_output = np.tanh(np.dot(self.transitions[i + 1], self.hiddens[i]))

		return prev_output
