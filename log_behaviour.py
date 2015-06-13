import sys
import numpy as np
from individual import individual
from serialize import dedump
from load_config import load_config

config = load_config()

# get parameters of the simulation
RUN_PREFIX = sys.argv[1]
EPOCH = sys.argv[2]
ITERATIONS = config["behaviour_logging_iterations"] if len(sys.argv) < 4 else sys.argv[3]

food = [np.sqrt(2) * config["food_distance"]] * 2
# load genes
subject = dedump(RUN_PREFIX, EPOCH)
log = open("data/behaviours/run" + str(RUN_PREFIX) + "_iter" + str(EPOCH) + ".dat", "w")

for epoch in xrange(ITERATIONS):
	# data about the subject
	data = [
		epoch,
		subject.position[0, 0],
		subject.position[0, 1],
		subject.rotation
	]
	log.write(" ".join(map(str, data)) + "\n")
	subject.tick(subject.visibility(food))
