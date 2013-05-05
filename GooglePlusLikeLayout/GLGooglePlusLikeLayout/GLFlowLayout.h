//
//  GLFlowLayout.h
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kItemAttributesKey = @"item_attr";
static NSString * const kItemSizesKey = @"item_size";


@protocol GLFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>
@optional
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout heightForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout interSectionSpacingForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
@end



@interface GLFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, copy) NSString * cellKind;
@property (nonatomic, assign) BOOL hasHeaders;
@property (nonatomic, assign) BOOL hasFooters;
@property (nonatomic, assign) BOOL shouldPerformItemLayout;
@property (nonatomic,retain) NSMutableDictionary * itemLayoutInfo;
@property (nonatomic, strong) NSMutableDictionary * supplementaryLayoutInfo;


-(void)resetAll;
-(CGSize)sizeForItemViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath*)indexPath;
-(CGSize)sizeForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath*)indexPath;
-(void)prepareSupplementaryViewLayout;
-(void)prepareSupplementaryHeaderLayoutAtIndexPath:(NSIndexPath *)indexPath;
-(void)prepareSupplementaryFooterLayoutAtIndexPath:(NSIndexPath *)indexPath;

// This method need to be subclassed for layout to work
-(CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath;

// This method need to be subclassed for layout to work
// This will be called only if hasHeaders or hasFooters value will be set to YES
-(CGRect)frameForSupplementaryViewOfKind:(NSString *)kind
                             atIndexPath:(NSIndexPath *)indexPath;

// This method need to be subclassed for layout to work
-(CGSize)collectionViewContentSize;

@end
