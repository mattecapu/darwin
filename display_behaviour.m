function display_behaviour(run, epoch)
	% needed for drawing arrows
	pkg load geometry
	data = load(["data/behaviours/run" int2str(run) "_iter" int2str(epoch) ".dat"]);
	config = load("config.m");
	dir_name = [int2str(run) "/" int2str(epoch)];
	mkdir("data/plots", int2str(run));
	mkdir(["data/plots/" int2str(run)], int2str(epoch));
	mkdir(["data/plots/" dir_name], "frames");

	padding = 10;
	food = [config(3) config(3)] * sqrt(2);
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

	% print each frame... sloooowly!
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
		print(["data/plots/" dir_name "/frames/" int2str(i) ".png"], "-Ggs.cmd")
		disp(i)
	end
	% creates the movie
	system(["ffmpeg -f image2 -framerate 25 -start_number 1 -framerate 8 -i \"data/plots/" dir_name "/frames/%d.png\" -c:v libx264 data/plots/" dir_name "/" dir_name ".mp4"])
end
