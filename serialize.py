import numpy as np
import os

from individual import individual

def filename(run, epoch):
	if not os.path.exists("data/weights/" + str(run)):
		os.makedirs("data/weights/" + str(run))
	return "data/weights/" + str(run) + "/" + str(epoch) + ".dat"

def dump(run, epoch, indiv):
	np.savetxt(filename(run, epoch), np.concatenate((indiv.f_chrom[:, 0, :], indiv.m_chrom[:, 0, :])))

def dedump(run, epoch):
	chromosomes = np.loadtxt(filename(run, epoch))
	n = chromosomes.shape[0] / 2
	chr_length = chromosomes.shape[1]
	return individual(chromosomes[:n].reshape((n, 1, chr_length)), chromosomes[n:].reshape((n, 1, chr_length)))
