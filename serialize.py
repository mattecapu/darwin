import numpy as np
import os

from individual import individual

def filename(run, epoch):
	if not os.path.exists("data/weights/" + str(run)):
		os.makedirs("data/weights/" + str(run))
	return "data/weights/" + str(run) + "/" + str(epoch) + ".dat"

def dump(run, epoch, indiv):
	np.savetxt(filename(run, epoch), np.concatenate((indiv.f_chrom[:, :], indiv.m_chrom[:, :])))

def dedump(run, epoch):
	chromosomes = np.loadtxt(filename(run, epoch)).astype(np.float32)
	n = chromosomes.shape[0] / 2
	return individual(chromosomes[:n], chromosomes[n:])
