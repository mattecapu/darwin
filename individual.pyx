import numpy as np
import rnn
from load_config import load_config

config = load_config()

# morphology
EYES = config["eyes"]

# rnn layers
INPUT_LAYER_SIZE = EYES
HIDDEN_LAYERS = config["hidden_layers"]
HIDDEN_LAYERS_SIZE = config["hidden_layers_size"]
OUTPUT_LAYER_SIZE = config["output_layer_size"]
# number of chromosome pairs
CHROMOSOME_LENGTH = HIDDEN_LAYERS_SIZE
APLOID_NUMBER = INPUT_LAYER_SIZE + HIDDEN_LAYERS_SIZE * (2 * HIDDEN_LAYERS - 1) + OUTPUT_LAYER_SIZE

# constants
TURN = 2 * np.pi
FIELD_OF_VIEW = TURN / (2 * EYES)
EYE_ANGLES = (2 * np.arange(EYES).reshape((EYES, 1)) + 1) * FIELD_OF_VIEW / 2
LIGHT_INTENSITY = config["light_intensity"]

DEG = 180 / np.pi

class individual:
	@staticmethod
	def create():
		# generates APLOID_NUMBER random chromosomes
		return individual(np.random.randn(APLOID_NUMBER, 1, CHROMOSOME_LENGTH), np.random.randn(APLOID_NUMBER, 1, CHROMOSOME_LENGTH))

	def __init__(self, f_chrom, m_chrom):
		self.fitness = 0
		# stores the chromosomes
		self.f_chrom = f_chrom
		self.m_chrom = m_chrom
		# rebuild the weights from genes
		fusion = (self.f_chrom + self.m_chrom) / 2
		# split indexes
		recurrences = HIDDEN_LAYERS_SIZE * HIDDEN_LAYERS
		inputs = recurrences + INPUT_LAYER_SIZE
		hiddens = inputs + recurrences - HIDDEN_LAYERS_SIZE
		self.brain = rnn.RNN(
			# recurrences
			fusion[:recurrences, 0, :].reshape(HIDDEN_LAYERS, HIDDEN_LAYERS_SIZE, HIDDEN_LAYERS_SIZE),
			# input -> hiddens
			[fusion[recurrences:inputs, 0, :].T] +
			# hiddens -> hiddens
			map(np.squeeze, np.vsplit(fusion[inputs:hiddens, 0, :], HIDDEN_LAYERS - 1)) +
			# hiddens -> output
			[fusion[hiddens:, 0, :]]
		)
		self.reset()

	def reset(self):
		self.position = np.zeros((1, 2))
		self.rotation = TURN / 8
		self.brain.reset()

	def tick(self, input):
		# outputs are changes to position and orientation
		[[delta_x], [delta_y], [delta_theta]] = self.brain.forward(input)
		# rotates displacement
		sin_rot = np.sin(self.rotation)
		cos_rot = np.cos(self.rotation)
		self.position += np.dot([[delta_x, delta_y]], [[cos_rot, sin_rot], [-sin_rot, cos_rot]])
		self.rotation = (self.rotation + delta_theta * TURN) % TURN

	def visibility(self, point):
		(x, y) = point
		# find inclination of the point (angle of the line between origin and point)
		y_dist = y - self.position[0, 1]
		x_dist = x - self.position[0, 0]
		angle = np.arctan2(y_dist, x_dist)
		# intensity dimishes with the square of the distance... or so
		d_squared = y_dist ** 2 + x_dist ** 2
		intensity = LIGHT_INTENSITY / (d_squared / 2)
		# max and min angle from which you can see 'point'
		theta_min = np.arcsin(1 / np.sqrt(d_squared))
		theta_max = TURN / 4 - 2 * theta_min
		# rotate wrt the point inclination
		theta_min += angle - TURN / 4
		theta_max += angle
		# get the angle of incidence of light at angle phi
		get_theta = lambda phi: np.abs(np.arctan2(x - np.sin(phi), y - np.cos(phi)) + phi)
		# rotate the eyes wrt animal orientation
		phis = EYE_ANGLES - self.rotation
		# compute incidence on the eyes
		return (intensity * np.sin(get_theta(phis))) * (phis > theta_min) * (phis < theta_max)

	def gamete(self):
		gamete = np.empty((APLOID_NUMBER, 1, CHROMOSOME_LENGTH))
		for i in xrange(APLOID_NUMBER):
			# toss a coin to choose wheter use a chromosome
			# from the father genes or the mother's as the main one
			m_or_f = np.random.rand() < 0.5

			# sometimes crossing over happens
			r = np.random.rand()
			if r < config["crossing_over_rate"]:
				# draw the locus where to split
				r = np.random.randint(CHROMOSOME_LENGTH)
				gamete[i, 0, 0:r] = (self.f_chrom if m_or_f else self.m_chrom)[i, 0, :r]
				gamete[i, 0, r:] = (self.m_chrom if not m_or_f else self.f_chrom)[i, 0, r:]
			else:
				r = np.random.rand()
				gamete[i] = (self.f_chrom if m_or_f else self.m_chrom)[i, 0]

			# sometimes, mutate a gene
			r = np.random.rand()
			if r < config["mutation_rate"]:
				# draw the gene to mutate
				r = np.random.randint(CHROMOSOME_LENGTH)
				gamete[i, 0, r] = np.random.randn() * gamete[i, 0, r]

		return gamete

	def mate(self, partner):
		return individual(self.gamete(), partner.gamete())
