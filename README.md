# 3DR-Internship
Work Done at 3DR over two months

**About:**

This was a low-resolution stitching algorithm developed over the course of 2 1/2 months at 3DR in Berkeley. The project was 
meant to act similar to DroneDeploy's live map feature. Essentially the drone would fly over a given area and from the live
video stream we would take images which would be processed and stitched together using Computer Vision algorithms. I experimented with many techniques of aligning the images, mostly using native iOS libraries. While this project worked quite 
well there were some issues with Memory usage/ CPU usage and Apple's intergration of OpenCV in Swift turned out not to be the 
solution. We concluded that more robust tools would be needed for editing the images themselves using Homography/ Perspective Warping rather than basic affine translations. This is all my work over those couple months. 

**How it works (OrthoMap):**

- Images paths are loaded from a folder
- An OrthoImageBuilder class is initialized with a certain amount of images
  ° OrthoImage objects are created as a result. These objects take the location, rotation, and image data from the path.
  ° The OrthoImageBuilder checks if the images are in proper rotation, if not it does not add them to the allData array, which is a public variable of the class.
  ° There is a cap that defines how many images are loaded before they can actually be added to create an image
  ° This cap is used for finding the GPS to Image point ratio before images are merged
  ° Once over images are added as usual
- The timer adds images periodically to simulate a live feed



![alt text](https://i.imgur.com/5ArZ85I.gif[/img])
