//
//  HelpCarouselViewController.m
//  iosfx
//
//  Created by Johnny Li on 12-10-16.
//  Copyright (c) 2012 OANDA Corp. All rights reserved.
//

#import "HCViewController.h"

#define IMAGE_WIDTH_SCALE 0.69  //Image size, in % of view size
#define TRANSITION_SCALE 0.5    //Pan multiplier

@interface HCViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    UIUserInterfaceIdiom currentDeviceInterface;
    NSUInteger lastPage;
    BOOL pageControlBeingUsed;
    int count;
    CGPoint lastScrollViewContentOffset;
}

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *scrollViewPageControl;
@property (nonatomic, strong) NSString *imagePlistFilePath;
@property (nonatomic, strong) NSArray *contentArray;
@property (nonatomic) NSUInteger currentPage;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (nonatomic, strong) UIPanGestureRecognizer *swipeGR;


@end

@implementation HCViewController
@synthesize titleLabel = _titleLabel;
@synthesize detailLabel = _detailLabel;
@synthesize imageScrollView = _imageScrollView;
@synthesize scrollViewPageControl = _scrollViewPageControl;
@synthesize currentPage = _currentPage;
@synthesize swipeGR = _swipeGR;

- (IBAction)skipHelp:(UIButton *)sender {
    return;
}

//////////////////////////////////////
//      Delegate Methods
//////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlBeingUsed = NO;
    [self gestureRecognizer:self.swipeGR shouldRecognizeSimultaneouslyWithGestureRecognizer:[self.scrollViewPageControl.gestureRecognizers objectAtIndex:0]];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if(self.currentPage != lastPage) {
        lastPage = self.currentPage;
        self.titleLabel.text = [[self.contentArray objectAtIndex:self.currentPage] valueForKey:@"imageTitle"];
        self.detailLabel.text = [[self.contentArray objectAtIndex:self.currentPage] valueForKey:@"imageDescription"];
        
        if(self.imageScrollView.contentOffset.x == ([self.contentArray count] - 1) * self.imageScrollView.bounds.size.width) {
            self.skipButton.enabled = YES;
        } else {
            self.skipButton.enabled = NO;
        }
    }
    
    pageControlBeingUsed = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float pageWidth = self.imageScrollView.frame.size.width;
    
    // Change page once scrolling has passed half way across the screen
    self.scrollViewPageControl.currentPage = floor((self.imageScrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1;
    self.currentPage = floor((self.imageScrollView.contentOffset.x - pageWidth/2) / pageWidth) + 1;
    
    if(self.imageScrollView.contentOffset.x == (count - 1) * self.imageScrollView.bounds.size.width) {
        //On the last page
        [self.imageScrollView addGestureRecognizer:self.swipeGR];
        if(lastScrollViewContentOffset.x < self.imageScrollView.contentOffset.x) {
        }
        self.swipeGR.enabled = YES;
    } else {
        self.swipeGR.enabled = NO;
    }
    
    lastScrollViewContentOffset = scrollView.contentOffset;
}

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


- (NSArray *)contentArray {
    if(!_contentArray) {
        _contentArray = [[NSArray alloc] initWithContentsOfFile:self.imagePlistFilePath];
    }
    
    return _contentArray;
}

- (void)setupNib {
    currentDeviceInterface = [[UIDevice currentDevice] userInterfaceIdiom];
    
    self.swipeGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:self.swipeGR];
    self.swipeGR.enabled = NO;
    self.swipeGR.delegate = self;
}

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
}

- (NSString *)imagePlistFilePath {
    if(!_imagePlistFilePath) {
        _imagePlistFilePath = [[NSBundle mainBundle] pathForResource:@"helpCarousel" ofType:@"plist"];
    }
    
    return _imagePlistFilePath;
}


//////////////////////////////////////
//      UIPageControll Action
//////////////////////////////////////
- (IBAction)changePage {
    // update the scroll view to the appropriate page
    CGRect frame;
    frame.origin.x = self.imageScrollView.frame.size.width * self.scrollViewPageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.imageScrollView.frame.size;
    [self.imageScrollView scrollRectToVisible:frame animated:YES];
    pageControlBeingUsed = YES;
}

//////////////////////////////////////
//              MISC
//////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNib];
    [self addImagesFromPlistToScrollView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSkipButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if(currentDeviceInterface == UIUserInterfaceIdiomPhone) {
        return NO;
    }
    return YES;
}

@end