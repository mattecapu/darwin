function [fixed] = plot_freq(run)
	genome_length = 99;
	population_size = 100;

	% root = "/media/mattecapu/Data/www/darwin/";
	root = "D:/www/darwin/";

	colors{1} = "k";
	colors{2} = "r";
	colors{3} = "g";
	colors{4} = "b";
	colors{5} = "m";
	colors{6} = "c";

	data = load([root "data/genotypes/run" int2str(run) ".m"]);
	iterations = size(data, 1);
	lower = min(data(:));
	higher = max(data(:));
	count = zeros((higher - lower), iterations + 1);
	for i = 1:iterations
		for j = 1:(2 * genome_length * population_size)
			count(data(i, j) - lower + 1, 1) = data(i, j);
			count(data(i, j) - lower + 1, i + 1) += 1;
		end
	end

	fixed = zeros(iterations, 1);
	cum_x = sum(count(:, 2:end)');
	for i = 0:(iterations - 1)
		fixed(i + 1) = sum(cum_x == i);
	end

	clf(); newplot();
	stem(1:iterations, fixed);

	% sorted = [count(:, 1) sum(count(:, 2:end)')'];
	% sorted = sortrows(sorted, 2)(end - 6 : end, :);
	% freq = [count(:, 1) count(:, 2:end) ./ (population_size * 2)];

	% clf(); newplot();
	% hold on;
	% for i = 1:6
		% scatter(1:iterations, freq(sorted(i, 1) - lower + 1, 2:end), colors{i}, ".");
	% end
	% xlim([0 iterations+1]);
	% hold off;
end
