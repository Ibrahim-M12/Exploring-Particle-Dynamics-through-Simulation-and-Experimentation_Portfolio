% List of video file paths
videos = {
    "C:\Users\ibrah\Downloads\Hard&Carpet(1).mp4",
    "C:\Users\ibrah\Downloads\Soft&Carpet.mp4",
    "C:\Users\ibrah\Downloads\Hard&Slab(1).mp4",
    "C:\Users\ibrah\Downloads\Soft&Slab.mp4"
};

% Initialize arrays to store results
meanCoeffsRestitution = zeros(length(videos), 1);
videoNames = cell(length(videos), 1);

% Process each video
for v = 1:length(videos)
    % Import video
    vid = VideoReader(videos{v});
    videoNames{v} = vid.Name; % Store the name for labeling

    % Convert each frame into individual images and save as a "stack"
    frames = read(vid);

    % Size and length of video
    numFrames = size(frames, 4); % Get the number of frames

    % Create a vector to store the particle's position as it travels
    posVec = zeros(numFrames, 2); % Preallocate for efficiency
    posCount = 0; % To track the number of detected positions

    % Create a figure for displaying the processed video
    figure('Name', ['Processed Video: ', vid.Name], 'NumberTitle', 'off');

    % Process each frame
    for i = 1:numFrames  % Loop through available frames
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
        
        % Display the binarized and noise-removed frame
        imshow(frameNoisyRemoved); 
        
        % Overlay detected circles onto the image
        if ~isempty(pos)
            hold on;
            viscircles(pos, ones(size(pos, 1), 1), 'EdgeColor', 'b');
            hold off;
        end
        % Adjust playback speed to match video frame rate
        pause(1 / vid.FrameRate); 
    end

    % Trim posVec to actual size
    posVec = posVec(1:posCount, :);

    % Invert Y-coordinates to allow for obvious context
    posVec(:, 2) = max(posVec(:, 2)) - posVec(:, 2);

    % Find peaks 
    diffVec = diff(posVec(:, 2));   
    peaks = find(diffVec(1:end-1) < 0 & diffVec(2:end) > 0) + 1; % Find local maxima (peaks)

    % Check if any peaks were found
    if isempty(peaks)
        error(['No peaks found in the particle trajectory for video: ', vid.Name]);
    end

    % Heights of the peaks
    peakHeights = posVec(peaks, 2); % Y-values of the peaks

    % Calculate the Coefficient of Restitution
    coeffRestitution = zeros(length(peakHeights)-1, 1); 
    for j = 1:length(peakHeights)-1
        heightDropped = peakHeights(j) - peakHeights(j+1);
        if heightDropped > 0
            coeffRestitution(j) = sqrt(peakHeights(j+1) / peakHeights(j));
        end
    end

    % Calculate mean Coefficient of Restitution from the multiple bounces
    meanCoeffsRestitution(v) = mean(coeffRestitution(coeffRestitution > 0));

    % Display the mean Coefficients of Restitution
    disp(['Mean Coefficient of Restitution for ', vid.Name, ': ', num2str(meanCoeffsRestitution(v))]);
    
    % Plot particle positions against frame number
    figure; % Create a new figure for the plot
    scatter(1:posCount, posVec(:, 2)); % X-axis: frame number, Y-axis: Y-coordinate
    title(['Particle Trajectory for ', vid.Name]);
    xlabel('Frame Number');
    ylabel('Height');
    axis([1 posCount 0 max(posVec(:,2))]); % Adjusted to reflect the inverted Y-axis
    set(gca, 'YDir', 'normal'); % Set Y-axis direction to normal
end

% Display mean coefficients for all videos
disp('Mean Coefficient of Restitution for all videos:');
for v = 1:length(videos)
    disp([videoNames{v}, ': ', num2str(meanCoeffsRestitution(v))]);
end