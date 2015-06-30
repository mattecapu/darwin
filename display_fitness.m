function display_fitness(run)
	% root = "/media/mattecapu/Data/www/darwin/";
	root = "D:/";

	data = load([root "data/fitness/run" int2str(run) ".m"]);
	figure("visible", "off")
	clf()
	newplot()
	scatter(data(:, 1), data(:, 2), 2, "b", ".")
	ylim([0 1])
	title("population fitness")
	ylabel("fitness")
	xlabel("iteration")
	mkdir("data/plots", int2str(run));
	set(gcf(), "paperposition", [0 0 11 6])
	print([root "data/plots/" int2str(run) "/fitness.png"], "-r100")
end
