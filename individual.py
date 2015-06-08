import numpy as np
import rnn
import itertools
from util import rotate, pos_or_zero

# morphology
EYES = 5

# layers size
INPUTS = EYES
HIDDENS = 20
OUTPUTS = 3
# number of chromosome pairs
N = INPUTS + HIDDENS + OUTPUTS

# costants
MOTION_MULTIPLIER = 3
TURN = 2 * np.pi
FIELD_OF_VIEW = (TURN / 2) / EYES
EYE_ANGLES = [(2 * eye + 1) * FIELD_OF_VIEW / 2 for eye in range(EYES)]
LIGHT_INTENSITY = 1024

DEG = 180 / np.pi

class individual:
	@staticmethod
	def create():
		# generates random chromosomes
		return individual(
			[list(np.random.randn(1, HIDDENS)[0]) for i in range(N)],
			[list(np.random.randn(1, HIDDENS)[0]) for i in range(N)]
		)

	def __init__(self, f_chrom, m_chrom):
		self.fitness = 0
		# stores the chromosomes
		self.f_chrom = f_chrom
		self.m_chrom = m_chrom
		# rebuild the weights from genes
		fusion = [[(f_chrom[i][j] + m_chrom[i][j]) / 2 for j in range(HIDDENS)] for i in range(N)]
		weights = reduce(
			lambda res, x: map(x, res),
			[itertools.chain, list, np.array],
			[fusion[0:HIDDENS], fusion[HIDDENS:(HIDDENS + INPUTS)],  fusion[(HIDDENS + INPUTS):]]
		)
		weights[1] = weights[1].T
		self.nn = rnn.RNN(tuple(weights))
		self.reset()

	def reset(self):
		self.position = (0, 0)
		self.rotation = TURN / 8
		self.nn.reset()

	def tick(self, input):
		# outputs are changes to position and orientation
		[[delta_x], [delta_y], [delta_theta]] = self.nn.step(input)
		displ = rotate(-self.rotation, (delta_x, delta_y))
		self.position = (self.position[0] + displ[0], self.position[1] + displ[1])
		self.rotation = self.rotation + delta_y * TURN

	def visibility(self, (x, y)):
		# find inclination of the point (angle of the line between origin and point)
		y_dist = y - self.position[1]
		x_dist = x - self.position[0]
		angle = np.arctan2(y_dist, x_dist)
		# intensity dimishes with the square of the distance... or so
		d_squared = y_dist ** 2 + x_dist ** 2
		intensity = LIGHT_INTENSITY / (d_squared / 2)
		# max and min angle from which you can see 'point'
		theta_min = np.arcsin(1 / np.sqrt(d_squared))
		theta_max = TURN / 2 - 2 * theta_min
		# rotate wrt the point inclination
		[theta_min, theta_max] = [th + angle - TURN / 4 for th in [theta_min, theta_max]]
		# get the angle of incidence of light at angle phi
		get_theta = lambda phi: np.abs(np.arctan2(x - np.sin(phi), y - np.sin(phi)) + phi)
		# rotate the eyes wrt animal orientation
		phis = [phi - self.rotation for phi in EYE_ANGLES]
		# compute incidence on the eyes
		return [[0 if not theta_min < phi < theta_max else intensity * np.sin(get_theta(phi))] for phi in PHIS]

	def gamete(self):
		gamete = []
		for i in xrange(0, N):
			# toss a coin to choose wheter use a chromosome
			# from the father genes or the mother's as the main one
			m_or_f = np.random.rand() < 0.5

			# 1 in 6 times crossing over happens
			r = np.random.rand()
			if r < 0.6:
				# draw the locus where to split
				r = np.int32(np.random.rand() * HIDDENS)
				chr = (self.f_chrom[i] if m_or_f else self.m_chrom[i])[0:r] + (self.m_chrom[i] if not m_or_f else self.f_chrom[i])[r:]
			else:
				r = np.random.rand()
				chr = self.f_chrom[i] if m_or_f else self.m_chrom[i]

			# 1 on 10 times, mutate a gene
			r = np.random.rand()
			if r < 0.1:
				# draw the gene to mutate
				r = np.int32(np.random.rand() * HIDDENS)
				chr[r] = np.random.randn() * chr[r]

			# add the new chromosome to the gamete
			gamete += [chr]

		return gamete
	
	def mate(self, partner):
		return individual(self.gamete(), partner.gamete())
