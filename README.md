# Darwin
Darwin is an evolutionary process simulation. Originally written in Python, I translated it to Cython and then to C++ to improve performance.

The project goal is to simulate a population of "individuals" (which are no more than neural networks), whose inputs are their own state (energy, growth, position, sight info) and whose outputs are movements and signals to other individuals, all in a virtual environment where food spawns regularly. When an individual has eaten enough, it become sexually mature and it can reproduce simply by meeting with another mature individual.

The actual simulation is very simpler. The individuals are treaten singularly and evaluated on their ability to reach food. Their inputs are only sight information from 5 eyes, and mating is handled by the program.

The simulations logs data about population fitness and behaviour, that can be translated at later time to meaningful data visualization using GNU Plot and Octave.

This project constitutes the thesis for my final exam on July, 1st.
