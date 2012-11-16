//
//  HelpCarouselViewController.m
//  iosfx
//
//  Created by Johnny Li on 12-10-16.
//  Copyright (c) 2012 OANDA Corp. All rights reserved.
//

#import "HCViewController.h"

#define IMAGE_WIDTH_SCALE 0.70  //Image size (width), in % of view size (width)
#define TRANSITION_SCALE 0.50   //Pan multiplier

@interface HCViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate> {

    UIUserInterfaceIdiom currentDeviceInterface;
    NSUInteger lastPage;
    CGPoint lastScrollViewContentOffset;
    int count;
    BOOL pageControlBeingUsed;
    
}

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *scrollViewPageControl;
@property (nonatomic, strong) NSString *imagePlistFilePath;
@property (nonatomic, strong) NSArray *contentArray;
@property (nonatomic) NSUInteger currentPage;
@property (nonatomic, strong) UIPanGestureRecognizer *swipeGR;

@end

@implementation HCViewController
@synthesize titleLabel = _titleLabel;
@synthesize detailLabel = _detailLabel;
@synthesize imageScrollView = _imageScrollView;
@synthesize scrollViewPageControl = _scrollViewPageControl;
@synthesize currentPage = _currentPage;
@synthesize swipeGR = _swipeGR;


#pragma mark - Initializer
// Default initializer
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setupNib];
    }
    return self;
}

#pragma mark - Delegate Methods

// Allow simultaneous gesture recognition for custom gesture recognizer compatibility
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// pageControl flickering fix and adds simultaneous gesture recognition
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlBeingUsed = NO;
    [self gestureRecognizer:self.swipeGR shouldRecognizeSimultaneouslyWithGestureRecognizer:[self.scrollViewPageControl.gestureRecognizers objectAtIndex:0]];
}

// Display the approporiate title and description based on scrolled to page
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if(self.currentPage != lastPage) {
        lastPage = self.currentPage;
        self.titleLabel.text = [[self.contentArray objectAtIndex:self.currentPage] valueForKey:@"imageTitle"];
        self.detailLabel.text = [[self.contentArray objectAtIndex:self.currentPage] valueForKey:@"imageDescription"];
    }
    
    pageControlBeingUsed = NO;
}

// Enables custom gesture recognizer only on the last page
// On other pages, change the scrolling of images based on the user interactions
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float pageWidth = self.imageScrollView.frame.size.width;
    
    // Change page once scrolling has passed half way across the screen
    self.scrollViewPageControl.currentPage = floor((self.imageScrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1;
    self.currentPage = floor((self.imageScrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1;
    
    if(self.imageScrollView.contentOffset.x == (count - 1) * self.imageScrollView.bounds.size.width) {
        self.swipeGR.enabled = YES;
    } else {
        self.swipeGR.enabled = NO;
    }
    
    lastScrollViewContentOffset = scrollView.contentOffset;
}

// Returns the last page to its proper place in case user performs improper panning
- (void)handlePanGesture:(UIPanGestureRecognizer *)gr {
    
    if(gr.state == UIGestureRecognizerStatePossible || gr.state == UIGestureRecognizerStateFailed || gr.state == UIGestureRecognizerStateCancelled) {
        CGRect reset = self.view.frame;
        reset.origin.x = 0;
        
        self.view.frame = reset;
    }
    
    if(gr.state == UIGestureRecognizerStateChanged) {
        CGRect dragPos = self.view.frame;
        dragPos.origin.x = [gr translationInView:self.view].x / TRANSITION_SCALE;
        
        self.view.frame = dragPos;
    } else if(gr.state == UIGestureRecognizerStateEnded) {
        if(self.view.frame.origin.x < -self.view.frame.size.width / 2) {
            //User scrolls right and has passed the mid point
            CGFloat xPoints = self.view.frame.size.width + [gr translationInView:self.view].x;
            CGFloat velocityX = [gr velocityInView:self.view].x;
            NSTimeInterval duration = xPoints / velocityX;
            if(duration > 0.5) duration = 0.5;
            CGRect endPoint = self.view.frame;
            endPoint.origin.x = -self.view.frame.size.width;
            
            [UIView animateWithDuration:duration
                                  delay:0
                                options:UIViewAnimationCurveEaseOut
                             animations:^{
                                 self.view.frame = endPoint;
                             } completion:^(BOOL finished) {
                                 [self removeFromParentViewController];
                             }];
            
        } else {
            //User scrolls right and has not passed the mid point, animate back to origin
            CGFloat xPoints = -[gr translationInView:self.view].x / TRANSITION_SCALE;
            CGFloat velocityX = [gr velocityInView:self.view].x;
            NSTimeInterval duration = xPoints / velocityX;
            if(duration > 0.5) duration = 0.5;
            
            CGRect endPoint = self.view.frame;
            endPoint.origin.x = 0;
            
            [UIView animateWithDuration:duration
                                  delay:0
                                options:UIViewAnimationCurveEaseOut
                             animations:^{
                                 self.view.frame = endPoint;
                             } completion:^(BOOL finished) {
                             }];
        }
    }
}


#pragma mark - Help Methods

- (IBAction)changePage {
    // update the scroll view to the appropriate page
    CGRect frame;
    frame.origin.x = self.imageScrollView.frame.size.width * self.scrollViewPageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.imageScrollView.frame.size;
    [self.imageScrollView scrollRectToVisible:frame animated:YES];
    pageControlBeingUsed = YES;
}


- (void)setupNib {
    currentDeviceInterface = [[UIDevice currentDevice] userInterfaceIdiom];
    
    self.swipeGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:self.swipeGR];
    self.swipeGR.enabled = NO;
    self.swipeGR.delegate = self;
}


// Holds the contents of HelpCarousel.plist
- (NSArray *)contentArray {
    if(!_contentArray) {
        _contentArray = [[NSArray alloc] initWithContentsOfFile:self.imagePlistFilePath];
    }
    
    return _contentArray;
}


// Retrieves image names form HelpCarousel.plist file and adds the images to the UIScrollView
- (void)addImagesFromPlistToScrollView {
    count = [self.contentArray count];
    float windowWidth = self.imageScrollView.bounds.size.width;
    
    for(int i=0; i<count; i++) {
        // Adding the image in UIScrollView
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[[self.contentArray objectAtIndex:i] valueForKey:@"imageName"]]];
        
        [imgView setFrame:CGRectMake(windowWidth * i + (windowWidth * (1 - IMAGE_WIDTH_SCALE) / 2),
                                     0,
                                     windowWidth * IMAGE_WIDTH_SCALE,
                                     self.imageScrollView.bounds.size.height)];
        
        [self.imageScrollView addSubview:imgView];
        
        if(i == 0) {
            self.titleLabel.text = [[self.contentArray objectAtIndex:0] valueForKey:@"imageTitle"];
            self.detailLabel.text = [[self.contentArray objectAtIndex:0] valueForKey:@"imageDescription"];
        }
    }
    
    self.scrollViewPageControl.numberOfPages = count;
    self.imageScrollView.contentSize = CGSizeMake(count * windowWidth, self.imageScrollView.bounds.size.height);
    
    if(count == 1) {
        self.swipeGR.enabled = YES;
    } else {
        self.swipeGR.enabled = NO;
    }
}

- (NSString *)imagePlistFilePath {
    if(!_imagePlistFilePath) {
        _imagePlistFilePath = [[NSBundle mainBundle] pathForResource:@"helpCarousel" ofType:@"plist"];
    }
    
    return _imagePlistFilePath;
}


#pragma mark - View Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNib];
    [self.imageScrollView addGestureRecognizer:self.swipeGR];
    [self addImagesFromPlistToScrollView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return NO;
    } else {
        return YES;
    }
}

@end