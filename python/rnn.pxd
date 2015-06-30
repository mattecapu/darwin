cimport numpy as np

cdef class RNN:
	cdef np.ndarray recurrences
	cdef list transitions
	cdef np.ndarray hiddens
	cdef int hidden_layers, layers_size

	cdef reset(self)
	cdef np.ndarray[np.float32_t, ndim = 2] forward(self, np.ndarray[np.float32_t, ndim = 2] x)
