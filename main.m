function BrainTumorDetectionApp
    pkg load image; % Load Image Processing Package (Required for Octave)

    % Create a figure for the GUI
    fig = figure('Name', 'Brain Tumor Detection', 'NumberTitle', 'off', 'Position', [100 100 900 600], 'Color', [0.95 0.95 1]);
    movegui(fig, 'center');

    % UI components
    uicontrol('Style', 'pushbutton', 'String', 'Load Image', 'Position', [50 550 100 30], 'Callback', @loadImage);
    uicontrol('Style', 'pushbutton', 'String', 'Process Image', 'Position', [200 550 100 30], 'Callback', @processImage);

    % Axes for displaying images
    ax1 = axes('Units', 'pixels', 'Position', [50 300 250 200]);   % Original Image
    ax2 = axes('Units', 'pixels', 'Position', [300 300 250 200]);  % Grayscale
    ax3 = axes('Units', 'pixels', 'Position', [550 300 250 200]);  % Gaussian Filtered
    ax4 = axes('Units', 'pixels', 'Position', [50 50 250 200]);    % Edge Detection
    ax5 = axes('Units', 'pixels', 'Position', [300 50 250 200]);   % Morphological Processing
    ax6 = axes('Units', 'pixels', 'Position', [550 50 250 200]);   % Final Detection

    img = []; % Store image globally

    % Function to load the image
    function loadImage(~, ~)
        [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif'}, 'Select an Image');
        if isequal(file, 0)
            return;
        end
        img = imread(fullfile(path, file));
        imshow(img, 'Parent', ax1);
        title(ax1, 'Original Image');
    end

    % Function to process the image
    function processImage(~, ~)
        try
            if isempty(img)
                errordlg('Please load an image first!', 'Error');
                return;
            end

            % Convert to grayscale
            grayImg = img;
            if size(img, 3) == 3
                grayImg = rgb2gray(img);
            end
            imshow(grayImg, 'Parent', ax2);
            title(ax2, 'Grayscale Image');
            drawnow;

            % Step 1: Check if image is a valid medical scan
            if isInvalidImage(grayImg)
                msgbox('This does not appear to be a valid brain scan. Please load a proper medical image.', 'Error', 'error');
                return;
            end

            % Step 2: Apply Gaussian filtering
            h = exp(-([-2:2].^2) / (2*2^2));
            h = h' * h;
            h = h / sum(h(:));
            filteredImg = imfilter(grayImg, h, 'same');

            imshow(filteredImg, 'Parent', ax3);
            title(ax3, 'Gaussian Filtered');
            drawnow;

            % Step 3: Edge detection using Canny
            edges = edge(filteredImg, 'Canny');
            imshow(edges, 'Parent', ax4);
            title(ax4, 'Edge Detection');
            drawnow;

            % Step 4: Morphological operations
            se = ones(5);
            morphImg = imclose(edges, se);
            morphImg = imfill(morphImg, 4);
            imshow(morphImg, 'Parent', ax5);
            title(ax5, 'Morphological Processing');
            drawnow;

            % Step 5: Find potential tumor regions
            labeledRegions = bwconncomp(morphImg);
            stats = regionprops(labeledRegions, 'Area', 'BoundingBox', 'PixelIdxList', 'Eccentricity', 'Perimeter');

            % Step 6: Filter out non-tumor regions
            tumorCandidates = filterTumorCandidates(stats, size(morphImg));

            if isempty(tumorCandidates)
                msgbox('No Tumor Detected!', 'Result');
                return;
            end

            % Get the largest tumor-like region
            areas = [tumorCandidates.Area];
            [~, maxIndex] = max(areas);
            tumorRegion = false(size(morphImg));
            tumorRegion(tumorCandidates(maxIndex).PixelIdxList) = true;

            % Overlay result
            imgOverlay = createOverlay(img, tumorCandidates(maxIndex).PixelIdxList, [255 0 0]);
            imshow(imgOverlay, 'Parent', ax6);
            title(ax6, 'Detection Result');
            drawnow;

            msgbox('Tumor Detected!', 'Result');

        catch e
            errordlg(['Error: ' e.message], 'Processing Error');
            disp(['Error in processing: ' e.message]);
            disp(getReport(e));
        end
    end

    % Function to check if an image is valid (rejects non-brain scans)
    function isInvalid = isInvalidImage(image)
        % 1. Compute Edge Density
        edges = edge(image, 'Canny');
        edgeDensity = sum(edges(:)) / numel(image);

        % 2. Compute Contrast
        contrastLevel = std(double(image(:)));

        % Brain scans typically have:
        % - Edge density between 0.01 to 0.15
        % - Contrast > 20
        isInvalid = (edgeDensity < 0.01 || edgeDensity > 0.15) || (contrastLevel < 20);
    end

    % Function to filter tumor-like candidates
    function validStats = filterTumorCandidates(stats, imgSize)
        validStats = [];
        for i = 1:length(stats)
            % Aspect ratio check
            bbox = stats(i).BoundingBox;
            aspectRatio = bbox(3) / bbox(4);
            if aspectRatio < 0.5 || aspectRatio > 2
                continue;
            end

            % Circularity check (Perimeter² / Area should be around 12.5 for round objects)
            circularity = (stats(i).Perimeter^2) / (4 * pi * stats(i).Area);
            if circularity < 10 || circularity > 25
                continue;
            end

            % Eccentricity check (Tumors are usually irregular blobs, not perfect ellipses)
            if stats(i).Eccentricity > 0.9
                continue;
            end

            % Area check (should not be too large or too small)
            if stats(i).Area < 100 || stats(i).Area > 0.3 * (imgSize(1) * imgSize(2))
                continue;
            end

            validStats = [validStats, stats(i)];
        end
    end

    % Function to create overlay
    function overlaid = createOverlay(sourceImg, pixelIndices, colorRGB)
        if size(sourceImg, 3) == 1
            overlaid = cat(3, sourceImg, sourceImg, sourceImg);
        else
            overlaid = sourceImg;
        end

        [rows, cols, ~] = size(overlaid);
        [r, c] = ind2sub([rows, cols], pixelIndices);
        mask = false(rows, cols);
        for i = 1:length(r)
            if r(i) <= rows && c(i) <= cols && r(i) >= 1 && c(i) >= 1
                mask(r(i), c(i)) = true;
            end
        end

        redChannel = overlaid(:,:,1);
        greenChannel = overlaid(:,:,2);
        blueChannel = overlaid(:,:,3);

        redChannel(mask) = uint8(255);
        greenChannel(mask) = uint8(0);
        blueChannel(mask) = uint8(0);

        overlaid(:,:,1) = redChannel;
        overlaid(:,:,2) = greenChannel;
        overlaid(:,:,3) = blueChannel;
    end
end

