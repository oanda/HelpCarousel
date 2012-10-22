HelpCarousel
=====================

HelpCarousel is an open source UIScrollView based fully functional carousel-style information presenter.

 
Screenshots
-------------------------
![Page 1](./Resources/page1.png)
![Page 2](./Resources/page2.png)
![Page 3](./Resources/page3.png)

Features
--------------------------
- Supports all iOS devices.
- Fully animated.
- Shows the current page via UIPageControl.
- Automatically sets the number of pages.
- Customizable by simply editing a Property List file.
- Easily integrates with any project.
- Automatically removes itself when the end has been reached.

Customization
---------------------------
You can customize the image, image title, or image description via a single Property List file.

<h4>How to make modifications</h4>
1. Open HelpCarousel.plist under HelpCarousel > Supporting Files
2. Change the value for "imageName", the value should be the image file name.
3. Change the value for "imageTitle", the value should be what you want to display on top of the image.
4. Change the value for "imageDescription", the value should be what you want to display below the image.
5. Save, done.

<h4>How to integrate into existing projects</h4>
1. In your project, select "Add files to existing project" by right clicking in the File Navigation panel.
2. Add the following files
	1. HelpCarouselViewController.h
	2. HelpCarouselViewController.m
	3. HelpCarouselViewController_iPhone.xib
	4. HelpCarouselViewController_iPad.xib
3. Insert the following code at where you would like HelpCarousel to appear.
![How to create a HelpCarouselViewController](./Resources/createNibs.png)
4. Done.

Questions
------------------------
Please feel free to contact me by sending me an <a href="mail-to:info@znli.ca" />email</a>.

Image Sources
-----------------------
Image courtesy goes to the following websites:

1. http://youchew.net
2. http://seo-hacker.com
3. http://recoveringyou.com/
