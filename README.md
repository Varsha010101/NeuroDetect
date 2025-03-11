# Brain Tumor Detection App (GNU Octave)

This is a **Brain Tumor Detection** tool developed for **GNU Octave**, using **image processing techniques** to analyze MRI scans and detect potential tumor regions.

---

## Features

- **Load MRI Images** (JPG, PNG, BMP, TIF)
- **Preprocessing Steps:**
  - Convert to grayscale
  - Apply histogram equalization for contrast enhancement
  - Gaussian filtering for noise reduction
- **Edge Detection using Sobel**
- **Morphological Processing to Enhance Tumor Regions**
- **Region Analysis:**
  - Identifies tumor candidates based on size and shape
  - Eliminates false detections
- **Final Tumor Detection:**
  - Highlights tumor region with red overlay
  - Displays tumor boundary and bounding box
  - Provides an estimate of the tumor’s size relative to the brain area

---

## Requirements

### 1. GNU Octave Installation
Download and install GNU Octave from:  
[https://www.gnu.org/software/octave/download.html](https://www.gnu.org/software/octave/download.html)

### 2. Required Octave Package
The app requires the **Image Processing** package. If not installed, run the following command in the Octave terminal:

```octave
pkg install -forge image
pkg load image
```

## Output Details

- **Original Image:** Displays the loaded MRI scan for analysis.
- **Grayscale Image:** Converts the image to grayscale for better processing.
- **Gaussian Filtered:** Reduces noise and smooths the image using a Gaussian filter.
- **Edge Detection:** Highlights high-intensity variations using the Sobel edge detection method.
- **Morphological Processing:** Enhances tumor-like structures by applying morphological operations.
- **Final Detection:** The detected tumor region is highlighted in **red** with a bounding box for clear visualization.

---

If you would like to contribute, feel free to fork the repository and suggest improvements!
