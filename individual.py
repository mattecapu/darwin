import numpy as np
import rnn
from util import rotate, pos_or_zero

# morphology
EYES = 5

# layers size
INPUTS = EYES
HIDDENS = 20
OUTPUTS = 3

# costants
MOTION_MULTIPLIER = 3
TURN = 2 * np.pi
FIELD_OF_VIEW = (TURN / 2) / EYES

class individual:
	def __init__(self):
		self.fitness = 0
		self.nn = rnn.RNN(INPUTS, HIDDENS, OUTPUTS)
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
		