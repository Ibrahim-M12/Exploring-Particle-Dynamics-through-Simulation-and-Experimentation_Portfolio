% List of video file paths
videos = {
    "C:/Users/ibrah/Downloads/Hard&Carpet(1).mp4",
    "C:/Users/ibrah/Downloads/Soft&Carpet.mp4",
    "C:/Users/ibrah/Downloads/Hard&Slab(1).mp4",
    "C:/Users/ibrah/Downloads/Soft&Slab.mp4"
};

% Initialize arrays to store results
meanCoeffsRestitution = zeros(length(videos), 1);
videoNames = cell(length(videos), 1);
allTrajectories = cell(length(videos), 1); % Store trajectories

% Process each video
for v = 1:length(videos)
    % Import video
    vid = VideoReader(videos{v});
    videoNames{v} = vid.Name; % Store the name for labeling

    % Convert each frame into individual images and save as a "stack"
    frames = read(vid);
    numFrames = size(frames, 4); % Get the number of frames

    % Create a vector to store the particle's position as it travels
    posVec = zeros(numFrames, 2); 
    posCount = 0; 

    % Process each frame
    for i = 1:numFrames
        % Access the ith frame from the frames array
        frame = frames(:,:,:,i);
        
        % Convert frame to greyscale
        frameGray = rgb2gray(frame);
        
        % Binarize the frame
        frameBinarized = imbinarize(frameGray, 0.6);
        
        % Remove bright spots (noise) 
        frameNoisyRemoved = imopen(frameBinarized, strel('disk', 3));
        
        % Find the particle as a circle
        [pos, ~] = imfindcircles(frameNoisyRemoved, [10 200], 'Sensitivity', 0.95);
        
        % Store the position in posVec if detected
        if ~isempty(pos)
            posCount = posCount + 1;
            posVec(posCount, :) = pos(1, :); % Store only the first detected position
        end
    end

    % Trim posVec to actual size
    posVec = posVec(1:posCount, :);

    % Invert Y-coordinates
    posVec(:, 2) = max(posVec(:, 2)) - posVec(:, 2);

    % Find peaks 
    diffVec = diff(posVec(:, 2));   
    peaks = find(diffVec(1:end-1) < 0 & diffVec(2:end) > 0) + 1;

    % Check if any peaks were found
    if isempty(peaks)
        warning(['No peaks found in the particle trajectory for video: ', vid.Name]);
        continue; % Skip to the next video
    end

    % Heights of the peaks
    peakHeights = posVec(peaks, 2);

    % Calculate the Coefficient of Restitution
    coeffRestitution = zeros(length(peakHeights)-1, 1); 
    for j = 1:length(peakHeights)-1
        heightDropped = peakHeights(j) - peakHeights(j+1);
        if heightDropped > 0
            coeffRestitution(j) = sqrt(peakHeights(j+1) / peakHeights(j));
        end
    end

    % Calculate mean Coefficient of Restitution
    meanCoeffsRestitution(v) = mean(coeffRestitution(coeffRestitution > 0));

    % Store the trajectory for plotting later
    allTrajectories{v} = posVec(:, 2);

    % Display the mean Coefficients of Restitution
    disp(['Mean Coefficient of Restitution for ', vid.Name, ': ', num2str(meanCoeffsRestitution(v))]);
end

% Plot all trajectories on the same graph
figure; % Create a new figure for the combined plot
hold on; % Hold on to overlay plots
for v = 1:length(videos)
    scatter(1:length(allTrajectories{v}), allTrajectories{v}, 'DisplayName', videoNames{v});
end
hold off;
title('Particle Trajectories for All Videos');
xlabel('Frame Number');
ylabel('Height');
legend('show'); % Show legend for different videos

% Display mean coefficients for all videos
disp('Mean Coefficient of Restitution for all videos:');
for v = 1:length(videos)
    disp([videoNames{v}, ': ', num2str(meanCoeffsRestitution(v))]);
end