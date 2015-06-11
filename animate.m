function animate(run, epoch)
	% needed for drawing arrows
	pkg load geometry
	data = load(["data/rnns/behaviours/run" int2str(run) "_iter" int2str(epoch) ".dat"]);
	dir_name = [int2str(run) "_" int2str(epoch)];
	mkdir("data/plots", dir_name);

	padding = 10
	food = [50 50]
	bounds = [
		min([data(:, 2); food(1)]) - padding
		max([data(:, 2); food(1)]) + padding
		min([data(:, 3); food(2)]) - padding
		max([data(:, 3); food(2)]) + padding
	];

	% multiply by 2pi to get angles
	data(:, 4) *= 2 * pi;

	% disable plotting on screen
	figure("visible", "off")

	disp(["will plot " int2str(length(data)) " frames"])

	for i = 1:length(data)
		clf()
		newplot()
		axis(bounds, "image", "manual")
		hold on
		title(["iteration " int2str(i)])
		p = plot(food(1), food(2), "dg");
		set(p, "markerfacecolor", "g")
		p = scatter(data(i, 2), data(i, 3), 15);
		set(p, "markerfacecolor", "b")
		% draw orientation marker
		drawArrow(data(i, 2), data(i, 3), data(i, 2) + 2.5 * cos(data(i, 4)), data(i, 3) + 2.5 * sin(data(i, 4)), 0.6, 0.5)
		filename = ["data/plots/" dir_name "/" int2str(i) ".png"];
		print(filename, "-Ggs.cmd")
		disp(i)
	end
end
