cimport cython

cimport numpy as np
import numpy as np

from rnn cimport RNN
from rnn import RNN

cdef extern from "math.h":
	float sin(float) nogil
	float cos(float) nogil
	float fabs(float) nogil
	float atan2(float, float) nogil
	float asin(float) nogil
	float sqrt(float) nogil
	float pow(float, int) nogil

# morphology
DEF EYES = 5

# rnn layers
DEF INPUT_LAYER_SIZE = EYES
DEF HIDDEN_LAYERS = 2
DEF HIDDEN_LAYERS_SIZE = 10
DEF OUTPUT_LAYER_SIZE = 3
# number of chromosome pairs
DEF CHROMOSOME_LENGTH = HIDDEN_LAYERS_SIZE
DEF APLOID_NUMBER = INPUT_LAYER_SIZE + HIDDEN_LAYERS_SIZE * (2 * HIDDEN_LAYERS - 1) + OUTPUT_LAYER_SIZE
# probability of mutation events during mating
DEF CROSSING_OVER_RATE = 0.5
DEF MUTATION_RATE = 0.15

# constants
cdef float TURN = 2 * np.pi
cdef float FIELD_OF_VIEW = TURN / (2 * EYES)
EYES_VECTOR_SHAPE = (EYES, 1)
cdef float[:] EYE_ANGLES = ((2 * np.arange(EYES).reshape(EYES_VECTOR_SHAPE) + 1) * FIELD_OF_VIEW / 2).astype(np.float32)[:, 0]
DEF LIGHT_INTENSITY = 1024

cdef float DEG = 180 / np.pi

# get the angle of incidence of light at angle phi
cdef float get_theta(float x, float y, float phi) nogil:
	return fabs(atan2(y - sin(phi), x - cos(phi)) + phi)

cdef class individual:
	def __init__(self, np.ndarray[np.float32_t, ndim = 2] _f_chrom, np.ndarray[np.float32_t, ndim = 2] _m_chrom):
		self.fitness = 0
		# stores the chromosomes
		self.f_chrom = _f_chrom
		self.m_chrom = _m_chrom
		# rebuild the weights from genes
		cdef np.ndarray[np.float32_t, ndim = 2] fusion = (self.f_chrom + self.m_chrom) / 2
		# split indexes
		cdef int recurrences = HIDDEN_LAYERS_SIZE * HIDDEN_LAYERS
		cdef int inputs = recurrences + INPUT_LAYER_SIZE
		cdef int hiddens = inputs + recurrences - HIDDEN_LAYERS_SIZE
		self.brain = RNN(
			# recurrences
			fusion[:recurrences, :].reshape(HIDDEN_LAYERS, HIDDEN_LAYERS_SIZE, HIDDEN_LAYERS_SIZE),
			# input -> hiddens
			[fusion[recurrences:inputs, :].T] +
			# hiddens -> hiddens
			np.vsplit(fusion[inputs:hiddens, :], HIDDEN_LAYERS - 1) +
			# hiddens -> output
			[fusion[hiddens:, :]]
		)
		self.reset()

	cpdef reset(self):
		self.position_x = 0
		self.position_y = 0
		self.rotation = TURN / 8
		self.brain.reset()

	cpdef tick(self, float food_x, float food_y):
		# outputs are changes to position and orientation
		cdef float delta_x, delta_y, delta_rot
		cdef float[:] output = self.brain.forward(self.visibility(food_x, food_y))[0]
		delta_x = output[0]
		delta_y = output[1]
		delta_rot = output[2]
		# rotates displacement
		cdef float sin_rot = sin(self.rotation)
		cdef float cos_rot = cos(self.rotation)
		self.position_x += delta_x * cos_rot + delta_y * sin_rot
		self.position_y += delta_x * -sin_rot + delta_y * cos_rot
		self.rotation = (self.rotation + delta_rot * TURN) % TURN

	cdef np.ndarray[np.float32_t, ndim = 2] visibility(self, float food_x, float food_y):
		# C-fast loop counter
		cdef int i
		cdef float y_dist, x_dist
		cdef float angle, d_squared, intensity
		cdef float theta_min, theta_max, phi
		cdef float[EYES] result
		with nogil:
			# find inclination of the point (angle of the line between origin and point)
			x_dist = food_x - self.position_x
			y_dist = food_y - self.position_y
			angle = atan2(y_dist, x_dist)
			# intensity dimishes with the square of the distance... or so
			d_squared = pow(y_dist, 2) + pow(x_dist, 2)
			intensity =  2 * LIGHT_INTENSITY / d_squared
			# max and min angle from which you can see 'point'
			theta_min = asin(1 / sqrt(d_squared))
			theta_max = TURN / 4 - 2 * theta_min
			# rotate wrt the point inclination
			theta_min += angle - TURN / 4
			theta_max += angle
			for i in range(EYES):
				# rotate the eyes wrt animal orientation
				phi = EYE_ANGLES[i] - self.rotation
				if theta_min < phi < theta_max:
					# compute incidence on the eyes
					result[i] = intensity * sin(get_theta(food_x, food_y, phi))
				else:
					result[i] = 0

		return np.asarray(result, dtype = np.float32).reshape(EYES_VECTOR_SHAPE)

	cdef np.ndarray[np.float32_t, ndim = 2] gamete(self):
		cdef np.ndarray[np.float32_t, ndim = 2] gamete
		# C-fast loop counter
		cdef int i
		# random variables
		cdef float m_or_f
		cdef int split_loc, mutation_loc
		# allocate the gamete
		gamete = np.empty((APLOID_NUMBER, CHROMOSOME_LENGTH), dtype = np.float32)

		for i in range(APLOID_NUMBER):
			# toss a coin to choose wheter use a chromosome
			# from the father genes or the mother's as the main one
			m_or_f = np.random.rand() < 0.5

			# sometimes, crossing over happens
			if np.random.rand() < CROSSING_OVER_RATE:
				# draw the locus where to split
				split_loc = np.random.randint(CHROMOSOME_LENGTH)
				gamete[i, :split_loc] = (self.f_chrom if m_or_f else self.m_chrom)[i, :split_loc]
				gamete[i, split_loc:] = (self.m_chrom if not m_or_f else self.f_chrom)[i, split_loc:]
			else:
				gamete[i] = (self.f_chrom if m_or_f else self.m_chrom)[i]

			# sometimes, mutate a gene
			if np.random.rand() < MUTATION_RATE:
				# mutate a randomly drawn gene
				mutation_loc = np.random.randint(CHROMOSOME_LENGTH)
				gamete[i, mutation_loc] = np.random.rand()

		return gamete

	cpdef individual mate(self, individual partner):
		return individual(self.gamete(), partner.gamete())

cdef inline np.ndarray[np.float32_t, ndim = 2] rand_chr():
	# generates APLOID_NUMBER random chromosomes (with genes in the interval [-1, +1]
	return np.random.rand(APLOID_NUMBER, CHROMOSOME_LENGTH).astype(np.float32) * 2 - 1

cpdef individual create_indiv():
	# yield an individual with random genes
	return individual(rand_chr(), rand_chr())
