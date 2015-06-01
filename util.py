import numpy as np

# angle is scalar
# vector2 is a vector of shape (2, 1)
def rotate(angle, vector2):
	return np.dot([[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]], vector2)

def pos_or_zero(x):
	return x if x > 0 else 0
	