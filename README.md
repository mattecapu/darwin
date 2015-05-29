# Darwin
Darwin is an evolutionary process simulation written in Python with NumPy.

The simulations involves a population of "individuals" which are no more than a RNN, whose inputs are its own state (energy, growth, position, sight info) and whose outputs are movements. When the individual reaches food, it can reproduce.

The population is then *evolved* using an evolutionary algorithm, with whom I'd like to show an improvement of the mean fitness (time-to-food, time-to-mating in a next version) of the population.


This project constitutes my thesis for the final exam on June
