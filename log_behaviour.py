import sys
import numpy as np
from individual import individual
from serialize import dedump

# get parameters of the simulation
RUN_PREFIX = sys.argv[1]
EPOCH = sys.argv[2]
ITERATIONS = 256 if len(sys.argv) < 4 else sys.argv[3]

food = [32, 32]
# load genes
subject = dedump(RUN_PREFIX, EPOCH)
log = open("data/rnns/behaviours/run" + str(RUN_PREFIX) + "_iter" + str(EPOCH) + ".dat", "w")

for epoch in xrange(ITERATIONS):
	# data about the subject
	data = [
		epoch,
		subject.position[0],
		subject.position[1],
		subject.rotation
	]
	log.write(" ".join(map(str, data)) + "\n")
	subject.tick(subject.visibility(food))
