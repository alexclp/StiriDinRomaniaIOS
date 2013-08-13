//
//  AllGroupsViewController.m
//  Stiri
//
//  Created by Stoica Vlad on 7/24/13.
//  Copyright (c) 2013 Stoica Vlad. All rights reserved.
//

#import "NewsGroupViewController.h"
#import "NewsDataSource.h"
#import "AFNetworking.h"
#import "SVProgressHud.h"
#import "NewsGroup.h"
#import "NewsSourceViewController.h"
#import "ECSlidingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MenuViewController.h"
#import "SideSwipeTableViewCell.h"

#define DATA_CHANGED_EVENT @"data_changed"
#define BUTTON_LEFT_MARGIN 10.0
#define BUTTON_SPACING 25.0

@interface NewsGroupViewController ()

@property (strong, nonatomic) NewsDataSource *newsDataSource;
@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) BOOL isDataLoading;
@property (nonatomic) int userId;

@end

@implementation NewsGroupViewController

- (UIRefreshControl *) refreshControl{
    if(!_refreshControl) _refreshControl = [[UIRefreshControl alloc] init];
    return _refreshControl;
}

- (NewsDataSource *) newsDataSource{
    if(!_newsDataSource) _newsDataSource = [NewsDataSource newsDataSource];
    return _newsDataSource;
}

- (NSArray *) groups{
    _groups = [self.newsDataSource allGroups];
    return _groups;
}

- (IBAction)addItem:(id)sender{
    [self performSegueWithIdentifier:@"showAddTabController" sender:self];

}

- (IBAction)openMenu:(id)sender{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (IBAction) touchUpInsideAction:(UIButton*)button
{
	NSIndexPath* indexPath = [tableView indexPathForCell:sideSwipeCell];
	
	NSUInteger index = [self.buttons indexOfObject:button];
	NSDictionary* buttonInfo = [self.buttonData objectAtIndex:index];
	[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat: @"%@ on cell %d", [buttonInfo objectForKey:@"title"], indexPath.row]
								 message:nil
								delegate:nil
					   cancelButtonTitle:nil
					   otherButtonTitles:@"OK", nil] show];
	
	[self removeSideSwipeView:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [super setTitle:@"Grupurile tale"];
    self.navigationItem.hidesBackButton = true;
    self.isDataLoading = YES;
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataChanged:) name:DATA_CHANGED_EVENT object:nil];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    [self.refreshControl beginRefreshing];
	
	self.buttonData = [NSArray arrayWithObjects:
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Reply", @"title", @"reply.png", @"image", nil],
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Retweet", @"title", @"retweet-outline-button-item.png", @"image", nil],
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Favorite", @"title", @"star-hollow.png", @"image", nil],
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Profile", @"title", @"person.png", @"image", nil],
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Links", @"title", @"paperclip.png", @"image", nil],
				   [NSDictionary dictionaryWithObjectsAndKeys:@"Action", @"title", @"action.png", @"image", nil],
                   nil];
	self.buttons = [[NSMutableArray alloc] initWithCapacity:self.buttonData.count];
	
	self.sideSwipeView = [[UIView alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.rowHeight)];
	[self setupSideSwipeView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self.slidingViewController setAnchorRightRevealAmount:200.0f];
    self.navigationController.view.layer.shadowOpacity = 0.75f;
    self.navigationController.view.layer.shadowRadius = 10.0f;
    self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    UIBarButtonItem *barBtnItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem:)];
    self.navigationItem.rightBarButtonItem=barBtnItem;
    
}

- (void)setupSideSwipeView
{
	// Add the background pattern
	self.sideSwipeView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"dotted-pattern.png"]];
	
	// Overlay a shadow image that adds a subtle darker drop shadow around the edges
	UIImage* shadow = [[UIImage imageNamed:@"inner-shadow.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
	UIImageView* shadowImageView = [[UIImageView alloc] initWithFrame:self.sideSwipeView.frame];
	shadowImageView.alpha = 0.6;
	shadowImageView.image = shadow;
	shadowImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.sideSwipeView addSubview:shadowImageView];
	
	// Iterate through the button data and create a button for each entry
	CGFloat leftEdge = BUTTON_LEFT_MARGIN;
	for (NSDictionary* buttonInfo in _buttonData)
	{
		// Create the button
		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
		
		// Make sure the button ends up in the right place when the cell is resized
		button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
		
		// Get the button image
		UIImage* buttonImage = [UIImage imageNamed:[buttonInfo objectForKey:@"image"]];
		
		// Set the button's frame
		button.frame = CGRectMake(leftEdge, sideSwipeView.center.y - buttonImage.size.height/2.0, buttonImage.size.width, buttonImage.size.height);
		
		// Add the image as the button's background image
		// [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
		UIImage *grayImage = [self imageFilledWith:[UIColor colorWithWhite:0.9 alpha:1.0] using:buttonImage];
		[button setImage:grayImage forState:UIControlStateNormal];
		
		// Add a touch up inside action
		[button addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
		
		// Keep track of the buttons so we know the proper text to display in the touch up inside action
		[self.buttons addObject:button];
		
		// Add the button to the side swipe view
		[self.sideSwipeView addSubview:button];
		
		// Move the left edge in prepartion for the next button
		leftEdge = leftEdge + buttonImage.size.width + BUTTON_SPACING;
	}

}

- (UIImage *)imageFilledWith:(UIColor*)color using:(UIImage*)startImage
{
	// Create the proper sized rect
	CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
	
	// Create a new bitmap context
	CGContextRef context = CGBitmapContextCreate(NULL, imageRect.size.width, imageRect.size.height, 8, 0, CGImageGetColorSpace(startImage.CGImage), kCGImageAlphaPremultipliedLast);
	
	// Use the passed in image as a clipping mask
	CGContextClipToMask(context, imageRect, startImage.CGImage);
	// Set the fill color
	CGContextSetFillColorWithColor(context, color.CGColor);
	// Fill with color
	CGContextFillRect(context, imageRect);
	
	// Generate a new image
	CGImageRef newCGImage = CGBitmapContextCreateImage(context);
	UIImage* newImage = [UIImage imageWithCGImage:newCGImage scale:startImage.scale orientation:startImage.imageOrientation];
	
	// Cleanup
	CGContextRelease(context);
	CGImageRelease(newCGImage);
	
	return newImage;
}

- (void) refresh {
    if(self.isDataLoading == NO){
        [[NewsDataSource newsDataSource]loadData];
        self.isDataLoading = YES;
    }
}

- (void) dataChanged:(NSNotification*) event{
    self.isDataLoading=NO;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *subtitleTableIdentifier = @"subtitleViewCellGroup";
    SideSwipeTableViewCell *cell = (SideSwipeTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:subtitleTableIdentifier];
    if (cell == nil) {
        cell = [[SideSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:subtitleTableIdentifier];
    }
    NewsGroup *ng = (self.groups)[indexPath.row];
    cell.textLabel.text = ng.title;
    NSUInteger numberOfNewSources = ng.newsSources.count;
    NSString *surseDeStiriString = [NSString stringWithFormat:@"%d surse de stiri",numberOfNewSources];
    if(numberOfNewSources == 1 ){
        surseDeStiriString = [NSString stringWithFormat:@"o sursă de știri"];
    }
    cell.detailTextLabel.text = surseDeStiriString;
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if( [segue.identifier isEqualToString:@"showNewsSourceForGroup"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NewsSourceViewController *destViewController = segue.destinationViewController;
        NewsGroup *selectedNewsGroup = [self.groups objectAtIndex:indexPath.row];
        destViewController.groupId = selectedNewsGroup.groupId;
        [self.tableView deselectRowAtIndexPath:indexPath animated:false];
    }
}
@end
