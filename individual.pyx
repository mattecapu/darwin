cimport cython

cimport numpy as np
import numpy as np

from rnn cimport RNN
from rnn import RNN

cdef extern from "math.h":
	float sin(float)
	float cos(float)
	float abs(float)
	float atan2(float, float)
	float asin(float)
	float sqrt(float)

from load_config import load_config
config = load_config()

# morphology
cdef int EYES = config["eyes"]

# rnn layers
cdef int INPUT_LAYER_SIZE = EYES
cdef int HIDDEN_LAYERS = config["hidden_layers"]
cdef int HIDDEN_LAYERS_SIZE = config["hidden_layers_size"]
cdef int OUTPUT_LAYER_SIZE = config["output_layer_size"]
# number of chromosome pairs
cdef int CHROMOSOME_LENGTH = HIDDEN_LAYERS_SIZE
cdef int APLOID_NUMBER = INPUT_LAYER_SIZE + HIDDEN_LAYERS_SIZE * (2 * HIDDEN_LAYERS - 1) + OUTPUT_LAYER_SIZE
# probability of mutation events during mating
cdef float CROSSING_OVER_RATE = config["crossing_over_rate"]
cdef float MUTATION_RATE = config["mutation_rate"]

# constants
cdef float TURN = 2 * np.pi
cdef float FIELD_OF_VIEW = TURN / (2 * EYES)
EYES_VECTOR_SHAPE = (EYES, 1)
cdef float[:] EYE_ANGLES = ((2 * np.arange(EYES).reshape(EYES_VECTOR_SHAPE) + 1) * FIELD_OF_VIEW / 2).astype(np.float32)[:, 0]
cdef float LIGHT_INTENSITY = config["light_intensity"]

cdef float DEG = 180 / np.pi

# get the angle of incidence of light at angle phi
cdef float get_theta(float x, float y, float phi):
	return abs(atan2(x - sin(phi), y - cos(phi)) + phi)

cdef class individual:
	cdef public float position_x
	cdef public float position_y
	cdef public float fitness
	cdef public float rotation
	cdef public np.ndarray f_chrom
	cdef public np.ndarray m_chrom
	cdef public RNN brain

	@staticmethod
	def create():
		# generates APLOID_NUMBER random chromosomes
		cdef np.ndarray[np.float32_t, ndim = 2] gamete1 = np.random.randn(APLOID_NUMBER, CHROMOSOME_LENGTH).astype(np.float32)
		cdef np.ndarray[np.float32_t, ndim = 2] gamete2 = np.random.randn(APLOID_NUMBER, CHROMOSOME_LENGTH).astype(np.float32)
		return individual(gamete1, gamete2)

	@cython.boundscheck(False)
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

	def reset(self):
		self.position_x = 0
		self.position_y = 0
		self.rotation = TURN / 8
		self.brain.reset()

	@cython.boundscheck(False)
	def tick(self, food_x, food_y):
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

	@cython.boundscheck(False)
	cdef np.ndarray[np.float32_t, ndim = 2] visibility(self, float food_x, float food_y):
		# C-fast loop counter
		cdef int i
		# find inclination of the point (angle of the line between origin and point)
		cdef float y_dist, x_dist
		x_dist = food_x - self.position_x
		y_dist = food_y - self.position_y
		cdef float angle = atan2(y_dist, x_dist)
		# intensity dimishes with the square of the distance... or so
		cdef float d_squared = y_dist ** 2 + x_dist ** 2
		cdef float intensity = LIGHT_INTENSITY / (d_squared / 2)
		# max and min angle from which you can see 'point'
		cdef float theta_min = asin(1 / sqrt(d_squared))
		cdef float theta_max = TURN / 4 - 2 * theta_min
		# rotate wrt the point inclination
		theta_min += angle - TURN / 4
		theta_max += angle
		cdef np.ndarray[np.float32_t, ndim = 2] result = np.zeros(EYES_VECTOR_SHAPE, dtype = np.float32)
		cdef float phi
		for i in range(EYES):
			# rotate the eyes wrt animal orientation
			phi = EYE_ANGLES[i] - self.rotation
			if theta_min < phi < theta_max:
				# compute incidence on the eyes
				result[i, 0] = intensity * sin(get_theta(food_x, food_y, phi))

		return result

	@cython.boundscheck(False)
	def gamete(self):
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
				gamete[i, mutation_loc] = np.random.randn() * gamete[i, mutation_loc]

		return gamete

	def mate(self, partner):
		return individual(self.gamete(), partner.gamete())
