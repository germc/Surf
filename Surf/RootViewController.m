//
//  RootViewController.m
//  Surf
//
//  Created by Sapan Bhuta on 5/30/14.
//  Copyright (c) 2014 SapanBhuta. All rights reserved.
//

#import "RootViewController.h"
#import "Tab.h"
#import "ReadingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SBCollectionViewCell.h"
#import "PocketAPI.h"
#import "MLPAutoCompleteTextField.h"
#import "MLPAutoCompleteTextFieldDelegate.h"
#import "OmnibarDataSource.h"
#import "HTAutocompleteTextField.h"
#import "HTAutocompleteManager.h"
@import Twitter;

@interface RootViewController () <UITextFieldDelegate,
                                    UIWebViewDelegate,
                                    UIGestureRecognizerDelegate,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout,
                                    MLPAutoCompleteTextFieldDelegate>
@property UIButton *circleButton;
@property UIPanGestureRecognizer *panCircle;
@property UIDynamicAnimator *dynamicAnimator;
@property UIPushBehavior *pushBehavior;
@property UICollisionBehavior *collisionBehavior;
@property UIDynamicItemBehavior *circleButtonDynamicBehavior;
@property UIView *toolsView;
@property UICollectionView *tabsCollectionView;
@property OmnibarDataSource *omnibarDataSource;
//@property MLPAutoCompleteTextField *omnibar;
@property HTAutocompleteTextField *omnibar;
@property UIProgressView *progressBar;
@property NSMutableArray *tabs;
@property int currentTabIndex;
@property CGRect omnnibarFrame;
@property UISwipeGestureRecognizer *swipeUp;
@property UISwipeGestureRecognizer *swipeDown;
@property UISwipeGestureRecognizer *swipeFromRight;
@property UISwipeGestureRecognizer *swipeFromLeft;
@property UIScreenEdgePanGestureRecognizer *edgeSwipeFromRight;
@property UIScreenEdgePanGestureRecognizer *edgeswipeFromLeft;
@property UILongPressGestureRecognizer *longPressOnPocket;
@property UILongPressGestureRecognizer *longPressOnStar;
@property BOOL showingTools;
@property BOOL doneLoading;
@property NSTimer *loadTimer;
@property NSTimer *borderTimer;
@property Tab *thisWebView;
@property Tab *rightWebView;
@property Tab *leftWebView;
@property NSTimer *delayTimer;
@property UIButton *stopButton;
@property UIButton *refreshButton;
@property UIButton *readButton;
@property UIButton *addButton;
@property UIButton *backButton;
@property UIButton *forwardButton;
@property UIButton *shareButton;
@property UIButton *saveButton;
@property UIButton *starButton;
@property UIButton *twitterButton;
@property UIButton *facebookButton;
@property UIButton *mailButton;
@property UIButton *pocketButton;
@property UIButton *instapaperButton;
@property UIButton *readabilityButton;
@property ReadingViewController *readingViewController;
@property UINavigationController *readingNavController;
@property UIPageControl *pageControl;
@end

@implementation RootViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self editView];
    [self createToolsView];
    [self createCircleButton];
    [self createCollectionView];
    [self createButtons];
    [self createOmnibar];
    [self createProgressBar];
    [self createGestures];
    [self loadTabs];
    [self createPageControl];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFromReadVC:) name:@"BackFromReadVC" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTab:) name:@"RemoveTab" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentURL) name:@"CurrentURL" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.showingTools)
    {
        [self.omnibar becomeFirstResponder];
    }
    [[UIApplication sharedApplication]setStatusBarHidden:!self.showingTools withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self saveTabs];
}

#pragma mark - Setup Scene
- (void)editView
{
    [self.view addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back"]]];
}

- (void)createCircleButton
{
    self.circleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.circleButton addTarget:self action:@selector(toggleCircle) forControlEvents:UIControlEventTouchUpInside];
    [self.circleButton setImage:[UIImage imageNamed:@"circle-full"] forState:UIControlStateNormal];
    self.circleButton.frame = CGRectMake(20, 20, 32, 32);
    self.circleButton.center = CGPointMake(50, self.view.frame.size.height -50);
    [self.view addSubview:self.circleButton];

    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.circleButton]];
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];
    self.circleButtonDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.circleButton]];
    self.circleButtonDynamicBehavior.allowsRotation = NO;
    self.circleButtonDynamicBehavior.elasticity = .1;
    self.circleButtonDynamicBehavior.friction = 0.9;
    self.circleButtonDynamicBehavior.resistance = 0.9;
    [self.dynamicAnimator addBehavior:self.circleButtonDynamicBehavior];

    self.panCircle = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.circleButton addGestureRecognizer:self.panCircle];
    self.panCircle.delegate = self;
}

- (void)toggleCircle
{
    if (!self.showingTools)
    {
        [self showTools];
    }
    else if ([self.tabs[self.currentTabIndex] request])
    {
        [self showWeb];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender
{

//    if (sender.state == UIGestureRecognizerStateBegan)
//    {
//        [self.circleButtonDynamicBehavior addLinearVelocity:[self.circleButtonDynamicBehavior linearVelocityForItem:sender.view] forItem:sender.view];
//    }

    self.circleButton.center = [sender locationInView:self.view];

    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGRect bottom50 = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height - 200, self.view.frame.size.width, 200);
        if (CGRectContainsPoint(bottom50, self.circleButton.center))
        {
            UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:sender.view snapToPoint:CGPointMake(50, self.view.frame.size.height -50)];
            [self.dynamicAnimator addBehavior:snap];
            return;
        }
    }

//    if (sender.state == UIGestureRecognizerStateEnded)
//    {
//        [self.circleButtonDynamicBehavior addLinearVelocity:[sender velocityInView:self.view] forItem:sender.view];
//        [self.dynamicAnimator updateItemUsingCurrentState:self.circleButton];
//    }
}

- (void)createToolsView
{
    self.toolsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                              self.view.frame.origin.y,
                                                              self.view.frame.size.width,
                                                              self.view.frame.size.height)];
    self.toolsView.backgroundColor = [UIColor blackColor];
    self.toolsView.alpha = .85;
    self.showingTools = true;
    [self.view addSubview:self.toolsView];
}

- (void)createOmnibar
{
    self.omnibar = [[HTAutocompleteTextField alloc] initWithFrame:CGRectMake(self.toolsView.frame.origin.x+20,           //20
                                                                              self.toolsView.frame.size.height/2,        //284
                                                                              self.toolsView.frame.size.width-(2*20),    //280
                                                                              2*20)];
    self.omnibar.delegate = self;
    self.omnibar.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.omnibar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.omnibar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.omnibar.keyboardType = UIKeyboardTypeEmailAddress;
    self.omnibar.returnKeyType = UIReturnKeyGo;
    self.omnibar.placeholder = @"search";
    self.omnibar.textColor = [UIColor lightGrayColor];
    self.omnibar.adjustsFontSizeToFitWidth = YES;
    self.omnibar.textAlignment = NSTextAlignmentLeft;
    self.omnibar.font = [UIFont systemFontOfSize:32];
    [self.toolsView addSubview:self.omnibar];
    [self.omnibar becomeFirstResponder];

    self.omnibarDataSource = [OmnibarDataSource new];
    self.omnibar.autocompleteDataSource = [HTAutocompleteManager sharedManager];
    self.omnibar.autocompleteType = HTAutocompleteTypeWebSearch;

//    self.omnibar = [[MLPAutoCompleteTextField alloc] initWithFrame:CGRectMake(self.toolsView.frame.origin.x+20,          //20
//                                                                              self.toolsView.frame.size.height/2,        //284
//                                                                              self.toolsView.frame.size.width-(2*20),    //280
//                                                                              2*20)];
//    self.omnibar.delegate = self;
//    self.omnibar.clearButtonMode = UITextFieldViewModeWhileEditing;
//    self.omnibar.autocapitalizationType = UITextAutocapitalizationTypeNone;
//    self.omnibar.autocorrectionType = UITextAutocorrectionTypeNo;
//    self.omnibar.keyboardType = UIKeyboardTypeEmailAddress;
//    self.omnibar.returnKeyType = UIReturnKeyGo;
//    self.omnibar.placeholder = @"search";
//    self.omnibar.textColor = [UIColor lightGrayColor];
//    self.omnibar.adjustsFontSizeToFitWidth = YES;
//    self.omnibar.textAlignment = NSTextAlignmentCenter;
//    self.omnibar.font = [UIFont systemFontOfSize:32];
//    [self.toolsView addSubview:self.omnibar];
//    [self.omnibar becomeFirstResponder];
//
//    self.omnibarDataSource = [OmnibarDataSource new];
//    self.omnibar.autoCompleteDataSource = self.omnibarDataSource;
//    self.omnibar.autoCompleteDelegate = self;
//    self.omnibar.autoCompleteTableViewHidden = ![[[NSUserDefaults standardUserDefaults] objectForKey:@"MLPAutoComplete"] boolValue];
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
  didSelectAutoCompleteString:(NSString *)selectedString
       withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject
            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tab *tab = self.tabs[self.currentTabIndex];
    tab.urlString = [self searchOrLoad:selectedString];
    self.omnibar.text = @"";
    [self loadPage:tab];
}

- (void)createProgressBar
{
    self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                       self.view.frame.origin.y,
                                                                       320,
                                                                       2)];
    self.progressBar.progress = 0;
    self.progressBar.progressTintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    self.progressBar.tintColor = [UIColor grayColor];
    self.progressBar.hidden = YES;
    [self.view addSubview:self.progressBar];
    [self.view bringSubviewToFront:self.progressBar];
}

- (void)createCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.tabsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                                 40,
                                                                                 self.view.frame.size.width,
                                                                                 148)
                                                 collectionViewLayout:flowLayout];
    self.tabsCollectionView.dataSource = self;
    self.tabsCollectionView.delegate = self;
    self.tabsCollectionView.backgroundColor = [UIColor blackColor];
    [self.tabsCollectionView registerClass:[SBCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.toolsView addSubview:self.tabsCollectionView];
}

- (void)createPageControl
{
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                       188,
                                                                       self.view.frame.size.width,
                                                                       20)];
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    self.pageControl.backgroundColor = [UIColor blackColor];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = self.tabs.count;
    [self.toolsView addSubview:self.pageControl];
}

#pragma mark - TwitterViewController Handling

- (void)showReadingLinks
{
    [self.omnibar resignFirstResponder]; //makes keyboard pop backup faster for some reason when returning from twitterVC
    if (!self.readingNavController)
    {
        self.readingViewController = [[ReadingViewController alloc] init];
        self.readingNavController = [[UINavigationController alloc] initWithRootViewController:self.readingViewController];
    }
    [self presentViewController:self.readingNavController animated:YES completion:nil];
}

- (void)backFromReadVC:(NSNotification *)notification
{
    NSString *urlString = notification.object;
    if (urlString)
    {
        if ([self.tabs.lastObject request])
        {
            [self addTab:urlString];
        }
        else
        {
            [self switchToTab:(int)self.tabs.count-1];
            [self.tabs.lastObject setUrlString:urlString];
            [self loadPage:self.tabs.lastObject];
        }
    }
}

#pragma mark - Gestures

- (void)createGestures
{
    self.swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    self.swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.toolsView addGestureRecognizer:self.swipeUp];
    self.swipeUp.delegate = self;

    self.swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    self.swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.toolsView addGestureRecognizer:self.swipeDown];
    self.swipeDown.delegate = self;

    self.swipeFromRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
    self.swipeFromRight.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.swipeFromRight];
    self.swipeFromRight.delegate = self;

    self.swipeFromLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
    self.swipeFromLeft.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.swipeFromLeft];
    self.swipeFromLeft.delegate = self;

    self.edgeSwipeFromRight = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleEdgeSwipeFromRight:)];
    [self.edgeSwipeFromRight setEdges:UIRectEdgeRight];
    [self.edgeSwipeFromRight setDelegate:self];
    [self.view addGestureRecognizer:self.edgeSwipeFromRight];
    
    self.edgeswipeFromLeft = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(handleEdgeSwipeFromLeft:)];
    [self.edgeswipeFromLeft setEdges:UIRectEdgeLeft];
    [self.edgeswipeFromLeft setDelegate:self];
    [self.view addGestureRecognizer:self.edgeswipeFromLeft];

    self.longPressOnPocket = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pocketAll:)];
    self.longPressOnPocket.delegate = self;
    [self.pocketButton addGestureRecognizer:self.longPressOnPocket];

    self.longPressOnStar = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bookmarkAll:)];
    self.longPressOnStar.delegate = self;
    [self.starButton addGestureRecognizer:self.longPressOnStar];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)sender
{
    [self.omnibar becomeFirstResponder];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)sender
{
    [self.omnibar resignFirstResponder];
}

- (void)handleSwipeFromRight:(UISwipeGestureRecognizer *)sender
{
    if (!self.showingTools)
    {
        [self showTools];
    }
}

- (void)handleSwipeFromLeft:(UISwipeGestureRecognizer *)sender
{
    if (!self.showingTools)
    {
        [self showReadingLinks];
    }

    if (self.showingTools && [self.tabs[self.currentTabIndex] request] &&
        [sender locationInView:self.view].y > self.tabsCollectionView.frame.size.height + self.tabsCollectionView.frame.origin.y)
    {
        [self showWeb];
    }
}

- (void)handleEdgeSwipeFromRight:(UIScreenEdgePanGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self.view];

    if (!self.showingTools && self.tabs.count > (self.currentTabIndex+1) && [self.tabs[self.currentTabIndex+1] request])
    {
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            self.thisWebView = self.tabs[self.currentTabIndex];
            self.rightWebView = self.tabs[self.currentTabIndex+1];

            self.view.userInteractionEnabled = NO;
            [self.view addSubview:self.rightWebView];
        }

        self.thisWebView.transform = CGAffineTransformMakeTranslation(-320+point.x, 0);
        self.rightWebView.transform = CGAffineTransformMakeTranslation(point.x+20, 0);

        if (sender.state == UIGestureRecognizerStateEnded)
        {
            if (point.x < self.view.frame.size.width/2)
            {
                [UIView animateWithDuration:.1 animations:^{
                    self.thisWebView.transform = CGAffineTransformMakeTranslation(-340, 0);
                    self.rightWebView.transform = CGAffineTransformMakeTranslation(0, 0);
                }];

                self.currentTabIndex++;
                [self.thisWebView removeFromSuperview];
                self.thisWebView = nil;
                self.rightWebView = nil;
            }
            else
            {
                [UIView animateWithDuration:.1 animations:^{
                    self.thisWebView.transform = CGAffineTransformMakeTranslation(0, 0);
                    self.rightWebView.transform = CGAffineTransformMakeTranslation(340, 0);
                }];
                [self.rightWebView removeFromSuperview];
                self.thisWebView = nil;
                self.rightWebView = nil;
            }
            self.view.userInteractionEnabled = YES;
        }
    }
}

- (void)handleEdgeSwipeFromLeft:(UIScreenEdgePanGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self.view];

    if (!self.showingTools && (self.currentTabIndex-1) >= 0 && [self.tabs[self.currentTabIndex-1] request])
    {
        if (sender.state == UIGestureRecognizerStateBegan)
        {
            self.thisWebView = self.tabs[self.currentTabIndex];
            self.leftWebView = self.tabs[self.currentTabIndex-1];

            self.view.userInteractionEnabled = NO;
            [self.view addSubview:self.leftWebView];
        }

        self.thisWebView.transform = CGAffineTransformMakeTranslation(point.x, 0);
        self.leftWebView.transform = CGAffineTransformMakeTranslation(point.x-340, 0);

        if (sender.state == UIGestureRecognizerStateEnded)
        {
            if (point.x > self.view.frame.size.width/2)
            {
                [UIView animateWithDuration:.1 animations:^{
                    self.thisWebView.transform = CGAffineTransformMakeTranslation(340, 0);
                    self.leftWebView.transform = CGAffineTransformMakeTranslation(0, 0);
                }];

                self.currentTabIndex--;
                [self.thisWebView removeFromSuperview];
                self.thisWebView = nil;
                self.leftWebView = nil;
            }
            else
            {
                [UIView animateWithDuration:.1 animations:^{
                    self.thisWebView.transform = CGAffineTransformMakeTranslation(0, 0);
                    self.leftWebView.transform = CGAffineTransformMakeTranslation(-340, 0);
                }];
                [self.leftWebView removeFromSuperview];
                self.thisWebView = nil;
                self.leftWebView = nil;
            }
            self.view.userInteractionEnabled = YES;
        }
    }
}

#pragma mark - Tabs

- (void)loadTabs
{
    self.tabs = [[NSMutableArray alloc] init];

    NSArray *savedUrlStrings = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedTabs"];
    BOOL reloadOldTabsOnStart = [[[NSUserDefaults standardUserDefaults] objectForKey:@"reloadOldTabsOnStart"] boolValue];

    if (reloadOldTabsOnStart && savedUrlStrings && savedUrlStrings.count>0)
    {
        for (NSString *urlString in savedUrlStrings)
        {
            [self addTab:urlString];
        }
        [self showTools];
    }
    else
    {
        [self addTab:nil];
    }
}

- (void)saveTabs
{
    NSMutableArray *tempArrayOfUrlStrings = [[NSMutableArray alloc] init];

    for (Tab *tab in self.tabs)
    {
        if (tab.request.URL)
        {
            [tempArrayOfUrlStrings addObject:tab.request.URL.absoluteString];
        }
    }

    [[NSUserDefaults standardUserDefaults] setObject:tempArrayOfUrlStrings forKey:@"savedTabs"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)addTab:(NSString *)urlString
{
    Tab *newTab = [[Tab alloc] init];
    newTab.delegate = self;
    newTab.scalesPageToFit = YES;
    [self.tabs addObject:newTab];
    self.pageControl.numberOfPages = self.tabs.count;
    self.refreshButton.enabled = NO;
    [self.tabsCollectionView reloadData];

    [self switchToTab:(int)self.tabs.count-1];

    if([urlString isKindOfClass:[NSString class]])
    {
        newTab.urlString = [self searchOrLoad:urlString];
        [self loadPage:newTab];
    }
}

- (void)switchToTab:(int)newTabIndex
{
    for (UIView *view in self.view.subviews)
    {
        if ([view isKindOfClass:[UIWebView class]] && ![view isEqual:self.tabs[newTabIndex]])
        {
            [view removeFromSuperview];
        }
    }

    Tab *newTab = self.tabs[newTabIndex];
    [self.view insertSubview:newTab belowSubview:self.toolsView];

    self.currentTabIndex = newTabIndex;

    self.borderTimer = [NSTimer scheduledTimerWithTimeInterval:.05
                                                        target:self
                                                      selector:@selector(pingBorderControl)
                                                      userInfo:nil
                                                       repeats:NO];
    [self pingPageControlIndexPath:nil];
    [self checkBackForwardButtons];

    if (newTab.request.URL)
    {
        [self showWeb];
    }
}

- (void)removeTab:(NSNotification *)notification
{
    [self endLoadingUI];

    UICollectionViewCell *cell = notification.object;
    NSIndexPath *path = [self.tabsCollectionView indexPathForCell:cell];
    Tab *tab = self.tabs[path.item];

    [tab removeFromSuperview];
    [self.tabs removeObject:tab];
    [cell removeFromSuperview];
    [self.tabsCollectionView deleteItemsAtIndexPaths:@[path]];
    self.currentTabIndex = 0;
    [self pingBorderControl];
    [self pingPageControlIndexPath:nil];
    self.pageControl.numberOfPages = self.tabs.count;

    if (self.tabs.count == 0)
    {
        [self addTab:nil];
    }
}

#pragma mark - UICollectionView DataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self pingTabsCollectionFrame];
    return self.tabs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SBCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    if ([self.tabs[indexPath.item] request])
    {
        cell.backgroundView = [self.tabs[indexPath.item] screenshot];
    }
    else
    {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back"]];
    }

    [self pingBorderControl];
    [self pingPageControlIndexPath:indexPath];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 148);
}

#pragma mark - UICollectionView Delegate Methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self switchToTab:(int)indexPath.item];
}

#pragma mark - Border Control

- (void)pingBorderControl
{
    for (UICollectionViewCell *cell in [self.tabsCollectionView visibleCells])
    {
        cell.backgroundView.layer.borderWidth = 1.0f;
        if (self.currentTabIndex == [self.tabsCollectionView indexPathForCell:cell].item)
        {
            cell.backgroundView.layer.borderColor = [UIColor blueColor].CGColor;
        }
        else
        {
            cell.backgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        }
    }
}

#pragma mark - Page Control

- (void)pingPageControlIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        self.pageControl.currentPage = indexPath.item;
    }
    else
    {
        self.pageControl.currentPage = self.currentTabIndex;
    }
}

#pragma mark - UITextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.omnibar resignFirstResponder];
    Tab *tab = self.tabs[self.currentTabIndex];
    tab.urlString = [self searchOrLoad:textField.text];
    self.omnibar.text = @"";
    [self loadPage:tab];
    return true;
}

#pragma mark - Handling User Search Query

-(NSString *)searchOrLoad:(NSString *)userInput
{
    NSString *checkedURL = [self isURL:userInput];
    return checkedURL ? checkedURL : [self googleSearchString:userInput];
}

-(NSString *)isURL:(NSString *)userInput
{
    NSArray *urlEndings = @[@".com",@".co",@".net",@".io",@".org",@".edu",@".to",@".ly",@".gov",@".eu",@".cn"];

    NSString *workingInput = @"";

    if ([userInput hasPrefix:@"http://"] || [userInput hasPrefix:@"https://"])
    {
        workingInput = userInput;
    }
    else if ([userInput hasPrefix:@"www."])
    {
        workingInput = [@"http://" stringByAppendingString:userInput];
    }
    else if ([userInput hasPrefix:@"m."])
    {
        workingInput = [@"http://" stringByAppendingString:userInput];
    }
    else if ([userInput hasPrefix:@"mobile."])
    {
        workingInput = [@"http://" stringByAppendingString:userInput];
    }
    else
    {
        workingInput = [@"http://www." stringByAppendingString:userInput];
    }

    NSURL *url = [NSURL URLWithString:workingInput];

    for (NSString *extension in urlEndings)
    {
        if ([url.host hasSuffix:extension])
        {
            return workingInput;
        }
    }
    return nil;
}

-(NSString *)googleSearchString:(NSString *)userInput
{
    NSString *noSpaces = [self urlEncode:userInput];
    NSString *searchUrl = [NSString stringWithFormat:@"https://www.google.com/search?q=%@&cad=h", noSpaces];
    return searchUrl;
}

- (NSString *)urlEncode:(NSString *)unencodedString
{
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)unencodedString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    return encodedString;
}

#pragma mark - Loading Web Page & Hiding/Showing Views

- (void)loadPage:(Tab *)tab
{
    [tab loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:tab.urlString]]];
    [self showWeb];
}

- (void)showWeb
{
    [[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    self.showingTools = false;
    self.toolsView.hidden = YES;

    [self.omnibar resignFirstResponder];

    Tab *tab = self.tabs[self.currentTabIndex];

    tab.frame = CGRectMake(self.view.frame.origin.x,
                                   self.view.frame.origin.y,
                                   self.view.frame.size.width,
                                   self.view.frame.size.height);

    [self.view insertSubview:tab aboveSubview:self.toolsView];
    [self.view bringSubviewToFront:self.circleButton];
}

- (void)showTools
{
    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    self.showingTools = true;
    self.toolsView.hidden = NO;

    Tab *tab = self.tabs[self.currentTabIndex];
    NSIndexPath *path = [NSIndexPath indexPathForItem:self.currentTabIndex inSection:0];
    UICollectionViewCell *cell = [self.tabsCollectionView cellForItemAtIndexPath:path];
    tab.screenshot = [tab snapshotViewAfterScreenUpdates:YES];
    cell.backgroundView = tab.screenshot;
    [self.tabsCollectionView reloadData];

    [self pingPageControlIndexPath:[NSIndexPath indexPathForItem:self.currentTabIndex inSection:0]];
    [self pingBorderControl];
    [self checkBackForwardButtons];
    [self.view insertSubview:self.tabs[self.currentTabIndex] belowSubview:self.toolsView];
    [self.omnibar becomeFirstResponder];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake)
    {
        [self showTools]; //or can use [self cancelRefreshSwitch];
    }
}


#pragma mark - UIWebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.progressBar.hidden = NO;
    self.progressBar.progress = 0;
    self.doneLoading = false;
    self.loadTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                      target:self
                                                    selector:@selector(timerCallback)
                                                    userInfo:nil
                                                     repeats:YES];
    [self enableShare:YES Refresh:NO Stop:YES  Save:YES];
    [self checkBackForwardButtons];
}

- (void)timerCallback
{
    if (self.doneLoading)
    {
        self.progressBar.progress = 1;
    }
    else if (self.progressBar.progress < 0.75)
    {
        self.progressBar.progress += 0.01;
    }
}

- (void)animateProgressBarHide
{
    self.progressBar.progress = 1;
    [UIView transitionWithView:self.progressBar
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.progressBar.hidden = YES;
    self.doneLoading = true;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self endLoadingUI];
    [self pingHistory:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self endLoadingUI];
}

- (void)endLoadingUI
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self animateProgressBarHide];
    [self enableShare:YES Refresh:YES Stop:NO Save:YES];
}

#pragma mark - Landscape Layout Adjust

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        self.omnibar.frame = self.omnnibarFrame;
        self.toolsView.frame = CGRectMake(self.view.frame.origin.x,
                                          self.view.frame.origin.y,
                                          self.view.frame.size.width,
                                          self.view.frame.size.height);

        [self pingTabsCollectionFrame];

        self.pageControl.frame = CGRectMake(self.view.frame.origin.x, 188, self.view.frame.size.width, 20);

        [self.tabs[self.currentTabIndex] setFrame:CGRectMake(self.view.frame.origin.x,
                                                             self.view.frame.origin.y,
                                                             self.view.frame.size.width,
                                                             self.view.frame.size.height)];
    }
    else    //landscape
    {
        self.omnibar.frame = CGRectMake((self.view.frame.size.height-self.omnibar.frame.size.width)/2,
                                        self.view.frame.origin.y+100,
                                        self.omnibar.frame.size.width,
                                        self.omnibar.frame.size.height);

        self.toolsView.frame = CGRectMake(self.view.frame.origin.x,
                                          self.view.frame.origin.y,
                                          self.view.frame.size.height,
                                          self.view.frame.size.width);

        [self pingTabsCollectionFrameLandscape];

        self.pageControl.frame = CGRectMake(self.view.frame.origin.x,
                                            self.view.frame.size.width-168,
                                            self.view.frame.size.height,
                                            20);

        [self.tabs[self.currentTabIndex] setFrame:CGRectMake(self.view.frame.origin.x,
                                                             self.view.frame.origin.y,
                                                             self.view.frame.size.height,
                                                             self.view.frame.size.width)];
    }
}


- (void)pingTabsCollectionFrame
{
    if (self.tabs.count*80 < self.view.frame.size.width)
    {
        self.tabsCollectionView.frame = CGRectMake(self.view.frame.size.width/2-(45*self.tabs.count)+5,
                                                   40,
                                                   self.view.frame.size.width,
                                                   148);
    }
    else
    {
        self.tabsCollectionView.frame = CGRectMake(self.view.frame.origin.x,
                                                   40,
                                                   self.view.frame.size.width,
                                                   148);
    }
}

- (void)pingTabsCollectionFrameLandscape
{
    if (self.tabs.count*80 < self.view.frame.size.height)
    {
        self.tabsCollectionView.frame = CGRectMake(self.view.frame.size.height/2-(45*self.tabs.count)+5,
                                                   self.view.frame.size.width - 148,
                                                   self.view.frame.size.height,
                                                   148);
    }
    else
    {
        self.tabsCollectionView.frame = CGRectMake(self.view.frame.origin.x,
                                                   self.view.frame.size.width - 148,
                                                   self.view.frame.size.height,
                                                   148);
    }
}

#pragma mark - Buttons

- (void)createButtons
{
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.refreshButton addTarget:self action:@selector(refreshPage) forControlEvents:UIControlEventTouchUpInside];
    [self.refreshButton setImage:[UIImage imageNamed:@"refresh"] forState:UIControlStateNormal];
    self.refreshButton.frame = CGRectMake(77, 17, 38, 38);
    self.refreshButton.center = CGPointMake(self.view.frame.size.width/2+50, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.refreshButton];

    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stopButton addTarget:self action:@selector(cancelPage) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    self.stopButton.frame = CGRectMake(80, 20, 32, 32);
    self.stopButton.center = CGPointMake(self.view.frame.size.width/2+50, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.stopButton];

    self.readButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.readButton addTarget:self action:@selector(showReadingLinks) forControlEvents:UIControlEventTouchUpInside];
    [self.readButton setImage:[UIImage imageNamed:@"read"] forState:UIControlStateNormal];
    self.readButton.frame = CGRectMake(20, 20, 48, 48);
    self.readButton.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.readButton];

    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addButton addTarget:self action:@selector(addTab:) forControlEvents:UIControlEventTouchUpInside];
    [self.addButton setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    self.addButton.frame = CGRectMake(20, 20, 32, 32);
    self.addButton.center = CGPointMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.addButton];

    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setImage:[UIImage imageNamed:@"goBack"] forState:UIControlStateNormal];
    self.backButton.frame = CGRectMake(20, 20, 32, 32);
    self.backButton.center = CGPointMake(self.view.frame.size.width/2-90, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.backButton];

    self.forwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.forwardButton addTarget:self action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    [self.forwardButton setImage:[UIImage imageNamed:@"goForward"] forState:UIControlStateNormal];
    self.forwardButton.frame = CGRectMake(20, 20, 32, 32);
    self.forwardButton.center = CGPointMake(self.view.frame.size.width/2+90, self.view.frame.size.height/2-30);
    [self.toolsView addSubview:self.forwardButton];

    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    self.shareButton.frame = CGRectMake(20, 20, 32, 32);
//    self.shareButton.center = CGPointMake(self.view.frame.size.width/2-130, self.view.frame.size.height/2-30);
    self.shareButton.center = CGPointMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2+100);
    [self.toolsView addSubview:self.shareButton];

//    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.saveButton addTarget:self action:@selector(saveToCloud) forControlEvents:UIControlEventTouchUpInside];
//    [self.saveButton setImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
//    self.saveButton.frame = CGRectMake(20, 20, 32, 32);
////    self.saveButton.center = CGPointMake(self.view.frame.size.width/2+130, self.view.frame.size.height/2-30);
//    self.saveButton.center = CGPointMake(self.view.frame.size.width/2+50, self.view.frame.size.height/2+100);
//    [self.toolsView addSubview:self.saveButton];

    self.starButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.starButton addTarget:self action:@selector(bookmark) forControlEvents:UIControlEventTouchUpInside];
    [self.starButton setImage:[UIImage imageNamed:@"star-1"] forState:UIControlStateNormal];
    self.starButton.frame = CGRectMake(20, 20, 32, 32);
    self.starButton.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2+100);
    [self.toolsView addSubview:self.starButton];

    self.pocketButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pocketButton addTarget:self action:@selector(pocket) forControlEvents:UIControlEventTouchUpInside];
    [self.pocketButton setImage:[UIImage imageNamed:@"pocket"] forState:UIControlStateNormal];
    self.pocketButton.frame = CGRectMake(20, 20, 32, 32);
    self.pocketButton.center = CGPointMake(self.view.frame.size.width/2+50, self.view.frame.size.height/2+100);
    [self.toolsView addSubview:self.pocketButton];

    self.facebookButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.facebookButton addTarget:self action:@selector(facebook) forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton setImage:[UIImage imageNamed:@"facebook"] forState:UIControlStateNormal];
    self.facebookButton.frame = CGRectMake(20, 20, 32, 32);
    self.facebookButton.center = CGPointMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2+150);
    [self.toolsView addSubview:self.facebookButton];

    self.twitterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.twitterButton addTarget:self action:@selector(tweet) forControlEvents:UIControlEventTouchUpInside];
    [self.twitterButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
    self.twitterButton.frame = CGRectMake(20, 20, 32, 32);
    self.twitterButton.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2+150);
    [self.toolsView addSubview:self.twitterButton];

    self.mailButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.mailButton addTarget:self action:@selector(mail) forControlEvents:UIControlEventTouchUpInside];
    [self.mailButton setImage:[UIImage imageNamed:@"mail"] forState:UIControlStateNormal];
    self.mailButton.frame = CGRectMake(20, 20, 32, 32);
    self.mailButton.center = CGPointMake(self.view.frame.size.width/2+50, self.view.frame.size.height/2+150);
    [self.toolsView addSubview:self.mailButton];

    [self enableShare:NO Refresh:NO Stop:NO Save:NO];
    self.refreshButton.hidden = NO;
    self.starButton.enabled = YES;
}

- (void)enableShare:(BOOL)B1 Refresh:(BOOL)B2 Stop:(BOOL)B3 Save:(BOOL)B4
{
    self.shareButton.enabled = B1;
    self.saveButton.enabled = B4;

    self.refreshButton.enabled = B2;
    self.refreshButton.hidden = !B2;
    self.stopButton.enabled = B3;
    self.stopButton.hidden = !B3;
}

- (void)checkBackForwardButtons
{
    Tab *tab = self.tabs[self.currentTabIndex];
    self.backButton.enabled = [tab canGoBack];
    self.forwardButton.enabled = [tab canGoForward];
}

- (void)goBack
{
    [self.tabs[self.currentTabIndex] goBack];
}

- (void)goForward
{
    [self.tabs[self.currentTabIndex] goForward];
}

- (void)refreshPage
{
    [self.tabs[self.currentTabIndex] reload];
}

- (void)cancelPage
{
    [self.tabs[self.currentTabIndex] stopLoading];
}

- (void)pingHistory:(UIWebView *)webView
{
    NSArray *history = [[NSUserDefaults standardUserDefaults] objectForKey:@"history"];
    NSMutableArray *historyM = [NSMutableArray arrayWithArray:history];
    if (![history.lastObject[@"url"] isEqualToString:webView.request.URL.absoluteString])
    {
        [historyM addObject:@{@"url":webView.request.URL.absoluteString,
                              @"title":[webView stringByEvaluatingJavaScriptFromString:@"document.title"]}];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:historyM] forKey:@"history"];
}

#pragma mark - Tab Saving

- (void)pocket
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"pocketLoggedIn"])
    {
        [[PocketAPI sharedAPI] loginWithHandler:^(PocketAPI *api, NSError *error)
         {
             if (!error)
             {
                 [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"pocketLoggedIn"];
                 [self pocket2:[self.tabs[self.currentTabIndex] request].URL];
             }
         }];
    }
    else
    {
        [self pocket2:[self.tabs[self.currentTabIndex] request].URL];
    }
}

- (void)pocket2:(NSURL *)url
{
    [[PocketAPI sharedAPI] saveURL:url
                           handler:^(PocketAPI *API, NSURL *URL, NSError *error)
    {
        if(!error)
        {
            [self showStatusBarMessage:@"Saved to Pocket" hideAfter:1];
//            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Saved to Pocket!"
//                                                              message:nil
//                                                             delegate:nil
//                                                    cancelButtonTitle:@"Dismiss"
//                                                    otherButtonTitles:nil];
//            [message show];
        }
        else
        {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error connecting to Pocket"
                                                              message:nil
                                                             delegate:nil
                                                    cancelButtonTitle:@"Dismiss"
                                                    otherButtonTitles:nil];
            [message show];
        }
    }];
}

- (void)pocketAll:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        for (Tab *tab in self.tabs)
        {
            [self pocket2:tab.request.URL];
        }

        self.tabs = [NSMutableArray new];
        [self.tabsCollectionView reloadData];

        for (UIView *view in self.view.subviews)
        {
            if ([view isKindOfClass:[UIWebView class]])
            {
                [view removeFromSuperview];
            }
        }
        self.currentTabIndex = 0;
        [self addTab:nil];
    }
}

- (void)facebook
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        Tab *tab = self.tabs[self.currentTabIndex];
        NSString *title = [tab stringByEvaluatingJavaScriptFromString:@"document.title"];
        NSString *text = [@"Check out: " stringByAppendingString:title];
        NSURL *url = tab.request.URL;

        if (url)
        {
            SLComposeViewController *fbSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [fbSheet setInitialText:text];
            [fbSheet addURL:url];
            [self presentViewController:fbSheet animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)tweet
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        Tab *tab = self.tabs[self.currentTabIndex];
        NSString *title = [tab stringByEvaluatingJavaScriptFromString:@"document.title"];
        NSString *text = [@"Check out: " stringByAppendingString:title];
        NSURL *url = tab.request.URL;

        if (url)
        {
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:text];
            [tweetSheet addURL:url];
            [self presentViewController:tweetSheet animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)mail
{

}

- (void)bookmark
{
    Tab *tab = self.tabs[self.currentTabIndex];
    NSString *url = tab.request.URL.absoluteString;
    NSString *title = [tab stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (url)
    {
        NSArray *bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"bookmarks"];
        NSMutableArray *bookmarksM = [NSMutableArray arrayWithArray:bookmarks];
        [bookmarksM addObject:@{@"url":url,
                                @"title":title}];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:bookmarksM] forKey:@"bookmarks"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self.starButton setImage:[UIImage imageNamed:@"star-2"] forState:UIControlStateNormal];
    }
}

- (void)bookmarkAll:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        for (Tab *tab in self.tabs)
        {
            NSString *url = tab.request.URL.absoluteString;
            NSString *title = [tab stringByEvaluatingJavaScriptFromString:@"document.title"];
            if (url)
            {
                NSArray *bookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"bookmarks"];
                NSMutableArray *bookmarksM = [NSMutableArray arrayWithArray:bookmarks];
                [bookmarksM addObject:@{@"url":url,
                                        @"title":title}];
                [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:bookmarksM] forKey:@"bookmarks"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [self.starButton setImage:[UIImage imageNamed:@"star-2"] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)share
{
    Tab *tab = self.tabs[self.currentTabIndex];
    NSString *title = [tab stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSString *text = [@"Check out: " stringByAppendingString:title];
    NSURL *url = tab.request.URL;

    if (url)
    {
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[text, url]
                                                                                 applicationActivities:nil];

        controller.excludedActivityTypes = @[UIActivityTypeAddToReadingList,
                                             UIActivityTypeAssignToContact,
                                             UIActivityTypeSaveToCameraRoll,
                                             UIActivityTypePostToFlickr,
                                             UIActivityTypePostToVimeo];

        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)currentURL
{
    NSString *url = [self.tabs[self.currentTabIndex] request].URL.absoluteString;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"url" object:url];
}

-(void)showStatusBarMessage:(NSString *)message hideAfter:(NSTimeInterval)delay
{
    __block UIWindow *statusWindow = [[UIWindow alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
    statusWindow.windowLevel = UIWindowLevelStatusBar + 1;
    UILabel *label = [[UILabel alloc] initWithFrame:statusWindow.bounds];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.text = message;
    [statusWindow addSubview:label];
    [statusWindow makeKeyAndVisible];
    label.layer.transform = CATransform3DMakeRotation(M_PI * 0.5, 1, 0, 0);
    [UIView animateWithDuration:0.7 animations:^{
        label.layer.transform = CATransform3DIdentity;
    }completion:^(BOOL finished){
        double delayInSeconds = delay;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.5 animations:^{
                label.layer.transform = CATransform3DMakeRotation(M_PI * 0.5, -1, 0, 0);
            }completion:^(BOOL finished){
                statusWindow = nil;
                [[[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
            }];
        });
    }];
}

@end