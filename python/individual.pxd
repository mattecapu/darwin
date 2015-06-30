cimport numpy as np
from rnn cimport RNN

cdef class individual:
	cdef public float position_x
	cdef public float position_y
	cdef public float fitness
	cdef public float rotation
	cdef public np.ndarray f_chrom
	cdef public np.ndarray m_chrom
	cdef public RNN brain

	cpdef reset(self)
	cpdef tick(self, float, float)
	cdef np.ndarray[np.float32_t, ndim = 2] visibility(self, float food_x, float food_y)
	cdef np.ndarray[np.float32_t, ndim = 2] gamete(self)
	cpdef individual mate(self, individual partner)

cpdef individual create_indiv()
