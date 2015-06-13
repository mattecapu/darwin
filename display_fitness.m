function display_fitness(run)
	data = load(["data/fitness/run" int2str(run) ".m"]);
	figure("visible", "off")
	clf()
	newplot()
	ylim([0 1])
	scatter(data(:, 1), data(:, 2), 2, "b", ".")
	title("population fitness")
	ylabel("fitness")
	xlabel("iteration")
	mkdir("data/plots", int2str(run));
	set(gcf(), "paperposition", [0 0 11 6])
	print(["data/plots/" int2str(run) "/fitness.png"], "-r100", "-Ggs.cmd")
end
