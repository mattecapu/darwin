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

class individual:
	@staticmethod
	def create():
		# generates random chromosomes
		return individual(
			[list(np.random.randn(1, HIDDENS)[0]) for i in range(0, N)],
			[list(np.random.randn(1, HIDDENS)[0]) for i in range(0, N)]
		)

	def __init__(self, f_chrom, m_chrom):
		self.fitness = 0
		# stores the chromosomes
		self.f_chrom = f_chrom
		self.m_chrom = m_chrom
		# rebuild the weights from genes
		fusion = [[(f_chrom[i][j] + m_chrom[i][j]) / 2 for j in range(0, HIDDENS)] for i in range(0, N)]
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

	def visibility(self, point):
		visibility = [0] * EYES
		# rotate the point into the rotated frame of reference
		r_point = rotate(self.rotation, point)
		# manhattan distances
		x_dist = r_point[0] - self.position[0]
		y_dist = r_point[1] - self.position[1]
		# find angle wrt the orientation of the individual
		angle = np.arctan2(y_dist, x_dist)
		# if it's not behind, fire the light sensor
		# corresponding to the eye
		if angle >= 0 and angle < TURN / 2:
			perp_eye = np.int32(angle / FIELD_OF_VIEW)
			visibility[perp_eye] = np.sqrt(1 / np.linalg.norm((y_dist, x_dist)))
			eye = perp_eye + 1
			while eye < EYES:
				visibility[eye] = visibility[perp_eye] * pos_or_zero(np.sin(angle - (perp_eye - eye) * FIELD_OF_VIEW))
				eye += 1
			eye = perp_eye - 1
			while eye >= 0:
				visibility[eye] = visibility[perp_eye] * pos_or_zero(np.sin(angle - (perp_eye - eye) * FIELD_OF_VIEW))
				eye -= 1

		# convert to a column vector
		return np.array([visibility]).T

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
