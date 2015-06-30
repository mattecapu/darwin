function display_behaviour(run, epoch)
	% root = "/media/mattecapu/Data/www/darwin/";
	root = "D:/";

	dir_name = [int2str(run) "/" int2str(epoch)];
	try
		data = load([root "data/behaviours/" dir_name ".dat"]);
	catch
		system(["/home/mattecapu/Desktop/log_b " int2str(run) " " int2str(epoch) " 200"]);
		data = load([root "data/behaviours/" dir_name ".dat"]);
	end
	try
		fitness = load([root "data/fitness/run" int2str(run) ".m"])(epoch + 1, 2);
	catch
		fitness = NaN;
	end
	mkdir([root "data/plots"], int2str(run));
	mkdir([root "data/plots/" int2str(run)], int2str(epoch));
	mkdir([root "data/plots/" dir_name], "frames");

	padding = 10;
	food = [24 24] / sqrt(2);
	bounds = [
		min([data(:, 2); food(1)]) - padding
		max([data(:, 2); food(1)]) + padding
		min([data(:, 3); food(2)]) - padding
		max([data(:, 3); food(2)]) + padding
	];

	% preprocess arrow points
	arrow_point = 3.5 * [cos(data(:, 4)) sin(data(:, 4))];

	% force plotting with GNU Plot
	graphics_toolkit("gnuplot");

	% disable plotting on screen
	figure("visible", "off")

	disp(["will plot " int2str(length(data)) " frames"])

	% generate plot template
	clf()
	newplot()
	axis(bounds, "image", "manual")
	hold on
	title_plot = title(["fitness " num2str(fitness) " - 1"]);
	xlabel("x")
	ylabel("y")
	food_plot = plot(food(1), food(2), "dg");
	set(food_plot, "markerfacecolor", "g")
	creature_plot = stem(data(1, 2), data(1, 3), "filled");
	set(creature_plot, "linestyle", "none")
	set(creature_plot, "showbaseline", "off")
	arrow_plot = quiver(data(1, 2), data(1, 3), arrow_point(1, 1), arrow_point(1, 2), 0);

	% print each frame... sloooowly!
	for i = 1:length(data)
		set(title_plot, "string",["fitness " num2str(fitness) " - " int2str(i)]);
		set(creature_plot, "xdata", data(i, 2))
		set(creature_plot, "ydata", data(i, 3))
		set(arrow_plot, "xdata", data(i, 2))
		set(arrow_plot, "ydata", data(i, 3))
		set(arrow_plot, "udata", arrow_point(i, 1))
		set(arrow_plot, "vdata", arrow_point(i, 2))
		print([root "data/plots/" dir_name "/frames/" int2str(i) ".png"], "-dpng")
	end
	% creates the movie
	system(["ffmpeg -f image2 -framerate 25 -start_number 1 -framerate 8 -i \"" root "data/plots/" dir_name "/frames/%d.png\" -c:v libx264 -y " root "data/plots/" dir_name "/movie.mp4"]);
end
