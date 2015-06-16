function display_evolutionary_progress(run)
	data = load(["data/fitness/run" int2str(run) ".m"]);
	evolution = [data(:, 1) zeros(length(data), 1)];
	e_i = 1;
	evolution(e_i, 2) = data(1, 2);
	for i = 1:length(data)
		if data(i, 2) >= evolution(e_i, 2)
			e_i += 1;
			evolution(e_i, 1) = i;
			evolution(e_i, 2) = data(i, 2);
		end
	end
	figure("visible", "off")
	clf()
	newplot()
	scatter(evolution(1:e_i, 1), evolution(1:e_i, 2))
	ylim([0 1])
	title("population evolution (shows only fitness better than all the previouses)")
	ylabel("fitness")
	xlabel("iteration")
	mkdir("data/plots", int2str(run));
	set(gcf(), "paperposition", [0 0 11 6])
	print(["data/plots/" int2str(run) "/evolution.png"], "-r100", "-Ggs.cmd")
end
