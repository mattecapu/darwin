function display_fitness(run)
	data = load(["data/fitness/run" int2str(run) ".m"]);
	clf()
	newplot()
	ylim([0 max(data(:, 2)) + 0.6])
	title("population fitness")
	ylabel("fitness")
	xlabel("iteration")
	scatter(data(:, 1), data(:, 2), 2, "b", ".")
	mkdir("data/plots", int2str(run));
	print(["data/plots/" int2str(run) "/fitness.png"], "-Ggs.cmd")
end
