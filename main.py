import numpy as np

import sys
import time

from load_config import load_config
from simulation import simulation

config = load_config()
ITERATIONS = (config["iterations"] if len(sys.argv) < 2 else int(sys.argv[1])) + 1
# flag to disable logging for quick test runs
DRY_RUN = len(sys.argv) > 2 and sys.argv[2] == "dry"

# id of this simulation
RUN_PREFIX = str(np.random.randint(2 ** 12))

print "## simulation", RUN_PREFIX
print "##", ITERATIONS, " iterations\n"

start = time.clock()
simulation(ITERATIONS, RUN_PREFIX, DRY_RUN)
end = time.clock()

print "\n## simulation", RUN_PREFIX, "ended"
print "## total time:", (end - start), "seconds"
print "## time per iteration:", (end - start) / ITERATIONS, "seconds"
