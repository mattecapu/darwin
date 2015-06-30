cimport cython

cimport numpy as np
import numpy as np

cdef class RNN:
	# transitions -> list of weight matrices of the synapses between layer n-1 and n
	# recurrences -> weights tensor of the recurrence synapses
	def __init__(self, np.ndarray[np.float32_t, ndim = 3] recurrences, list transitions):
		self.recurrences = recurrences
		self.transitions = transitions
		(self.hidden_layers, self.layers_size) = self.recurrences.shape[:2]
		self.hiddens = np.zeros((self.hidden_layers, self.layers_size, 1))

	cdef reset(self):
		# set to zero in-place
		self.hiddens *= 0

	cdef np.ndarray[np.float32_t, ndim = 2] forward(self, np.ndarray[np.float32_t, ndim = 2] x):
		cdef np.ndarray[np.float32_t, ndim = 2] prev_output = x
		cdef int i
		for i in xrange(self.hidden_layers):
			# update the hidden state
			self.hiddens[i] = np.tanh(np.dot(self.recurrences[i], self.hiddens[i]) + np.dot(self.transitions[i], prev_output), dtype = np.float32)
			# computes the layer output
			prev_output = np.tanh(np.dot(self.transitions[i + 1], self.hiddens[i]), dtype = np.float32)

		return prev_output
