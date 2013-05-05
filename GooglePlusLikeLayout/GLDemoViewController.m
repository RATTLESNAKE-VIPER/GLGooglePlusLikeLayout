//
//  GLDemoViewController.m
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import "GLDemoViewController.h"
#import "SVPullToRefresh.h"
#import "GLGooglePlusLikeLayout.h"
#import "GLSectionView.h"
#import "GLCell.h"

#define DATA_TO_ADD 30
#define SECTION_IDENTIFIER @"section"
#define CELL_IDENTIFIER @"cell"

@interface GLDemoViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation GLDemoViewController

#pragma mark -
#pragma mark - Accessors

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        GLGooglePlusLikeLayout* layout = [[GLGooglePlusLikeLayout alloc] init];
        CGFloat width = floorf((CGRectGetWidth(self.view.bounds) / 2));
        layout.minimumItemSize = CGSizeMake(width, width);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        [_collectionView setDelegate:self];
        [_collectionView setDataSource:self];
        _collectionView.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
        [_collectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    }
    return _collectionView;
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

#pragma mark -
#pragma mark - Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self commonInit];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    [self.view addSubview:self.collectionView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // configure views
    GLGooglePlusLikeLayout *layout = (GLGooglePlusLikeLayout *)[self.collectionView collectionViewLayout];
    [layout setHasHeaders:YES];
    
    [self.collectionView registerClass:[GLSectionView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:SECTION_IDENTIFIER];
    [self.collectionView registerClass:[GLCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];
    
    
    // load data
    [self configurePullToRefresh];
    [self.collectionView triggerPullToRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self.dataSource removeAllObjects];
    self.dataSource = nil;
}

- (void)dealloc
{
    [self.dataSource removeAllObjects];
    self.dataSource = nil;
    
    [self.collectionView removeFromSuperview];
    self.collectionView = nil;
}



#pragma mark -
#pragma mark - Orientation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                            duration:duration];
    [self updateLayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}


#pragma mark - UICollectionView Stuff

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *suppView;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if (indexPath.section == 0) {
            GLSectionView *sectionView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:SECTION_IDENTIFIER forIndexPath:indexPath];
            [sectionView setBackgroundColor:[UIColor darkGrayColor]];
            [sectionView setDisplayString:@"Section 1"];
            suppView = sectionView;
        }
    }
    
    return suppView;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout heightForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
{
    return 30;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GLCell *cell = (GLCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    cell.displayString = [NSString stringWithFormat:@"%d", indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeZero;
    
    if (indexPath.item <= (self.dataSource.count - 1)) {
        NSValue *sizeValue = self.dataSource[indexPath.item];
        size = [sizeValue CGSizeValue];
        return size;
    }
    
    return size;
}



#pragma mark -
#pragma mark - Private methods

- (void)commonInit
{
    self.view.backgroundColor = [UIColor grayColor];
}

- (void)updateLayout
{
    GLGooglePlusLikeLayout *layout = (GLGooglePlusLikeLayout *)[self.collectionView collectionViewLayout];
    CGFloat width = floorf((CGRectGetWidth(self.view.bounds) / 2));
    layout.minimumItemSize = CGSizeMake(width, width);
}

- (CGSize)randomSize
{
    CGFloat width = (CGFloat) (arc4random() % (int) self.view.bounds.size.width * 0.7);
    CGFloat heigth = (CGFloat) (arc4random() % (int) self.view.bounds.size.height * 0.7);
    CGSize randomSize = CGSizeMake(width, heigth);
    return randomSize;
}

-(void)configurePullToRefresh
{
    __weak GLDemoViewController *weakSelf = self;
    
    // setup pull-to-refresh
    [self.collectionView addPullToRefreshWithActionHandler:^{
        // add random sizes for demo (NB: You need to add actual content size you want here or at sizeForItemAtIndexPath delegate method as per your needs)
        NSMutableArray* tmp = [[NSMutableArray alloc] initWithCapacity:DATA_TO_ADD];
        for (int i = 0; i < DATA_TO_ADD; i++) {
            [tmp addObject:[NSValue valueWithCGSize:[weakSelf randomSize]]];
        }
        
        
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.dataSource removeAllObjects];
            [weakSelf.dataSource addObjectsFromArray:tmp];
            [weakSelf.collectionView reloadData];
            [weakSelf.collectionView.pullToRefreshView stopAnimating];
        });
    }];
    
    // setup infinite scrolling
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        // add random sizes for demo (NB: You need to add actual content size you want here or at sizeForItemAtIndexPath delegate method as per your needs)
        NSUInteger dataSourceCount = weakSelf.dataSource.count;
        NSMutableArray* tmp = [[NSMutableArray alloc] initWithCapacity:DATA_TO_ADD];
        NSMutableArray* indexPaths = [[NSMutableArray alloc] initWithCapacity:DATA_TO_ADD];
        
        for (int i = 0; i < DATA_TO_ADD; i++) {
            [tmp addObject:[NSValue valueWithCGSize:[weakSelf randomSize]]];
            [indexPaths addObject:[NSIndexPath indexPathForItem:(dataSourceCount + i) inSection:0]];
        }
        
        
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [weakSelf.dataSource addObjectsFromArray:tmp];
            [weakSelf.collectionView performBatchUpdates:^{
                [weakSelf.collectionView insertItemsAtIndexPaths:(NSArray*)indexPaths];
                
            } completion:nil];
            [weakSelf.collectionView.infiniteScrollingView stopAnimating];
        });
    }];
}

@end
