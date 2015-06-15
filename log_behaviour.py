import sys
import os
import numpy as np

from individual import individual
from serialize import dedump
from load_config import load_config

config = load_config()

# get parameters of the simulation
RUN_PREFIX = sys.argv[1]
EPOCH = sys.argv[2]
ITERATIONS = config["behaviour_logging_iterations"] if len(sys.argv) < 4 else int(sys.argv[3])

food_x = config["food_distance"] / np.sqrt(2)
# load genes
subject = dedump(RUN_PREFIX, EPOCH)
if not os.path.exists("data/behaviours/" + str(RUN_PREFIX)):
	os.makedirs("data/behaviours/" + str(RUN_PREFIX))
log = open("data/behaviours/" + str(RUN_PREFIX) + "/" + str(EPOCH) + ".dat", "w")

for epoch in xrange(ITERATIONS):
	# data about the subject
	data = [
		epoch,
		subject.position_x,
		subject.position_y,
		subject.rotation
	]
	log.write(" ".join(map(str, data)) + "\n")
	subject.tick(food_x, food_x)
