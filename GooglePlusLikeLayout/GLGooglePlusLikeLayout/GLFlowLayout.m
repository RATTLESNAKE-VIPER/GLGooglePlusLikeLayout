//
//  GLFlowLayout.m
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import "GLFlowLayout.h"

@interface GLFlowLayout()
@property (nonatomic, strong)NSMutableDictionary * supplementaryViewHeaderLayoutInfo;
@property (nonatomic, strong)NSMutableDictionary * supplementaryViewFooterLayoutInfo;
@end

@implementation GLFlowLayout

- (id)init
{
    self = [super init];
    if(self) {
        self.supplementaryViewHeaderLayoutInfo = [NSMutableDictionary dictionary];
        self.supplementaryViewFooterLayoutInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)dealloc {
    [self resetAll];
    self.cellKind = nil;
    self.supplementaryViewHeaderLayoutInfo = nil;
    self.supplementaryViewFooterLayoutInfo = nil;
}

-(void)resetAll {
    self.itemLayoutInfo = nil;
    [self.supplementaryViewHeaderLayoutInfo removeAllObjects];
    [self.supplementaryViewFooterLayoutInfo removeAllObjects];
    self.supplementaryLayoutInfo = nil;
}

-(NSMutableDictionary *)itemLayoutInfo {
    if (!_itemLayoutInfo)
        _itemLayoutInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    return _itemLayoutInfo;
}

-(NSString *)cellKind {
    if (!_cellKind)
        _cellKind = [@"DefaultCellKind" copy];
    return _cellKind;
}

-(NSMutableDictionary *)supplementaryLayoutInfo {
    if (!_supplementaryLayoutInfo) {
        _supplementaryLayoutInfo = [[NSMutableDictionary alloc] init];
    }
    return _supplementaryLayoutInfo;
}



-(void)prepareItemLayout {
    id<GLFlowLayoutDelegate> delegate = (id<GLFlowLayoutDelegate>)self.collectionView.delegate;
    
    NSMutableDictionary * layoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary * itemLayoutInfo = [NSMutableDictionary dictionary];
    layoutInfo[self.cellKind] = itemLayoutInfo;
    [self.itemLayoutInfo addEntriesFromDictionary:layoutInfo];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    for (int section = 0; section < sectionCount;section ++) {
        int itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (int item = 0; item < itemCount; item++) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            NSMutableDictionary *valueInfo = [[NSMutableDictionary alloc] init];
            itemLayoutInfo[indexPath] = valueInfo;
            
            
            // set default item size, then optionally override it
            CGSize size = self.itemSize;
            if(delegate && [delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)])
            {
                size = [delegate collectionView:(UICollectionView*)self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
            }
            [valueInfo setObject:[NSValue valueWithCGSize:size] forKey:kItemSizesKey];
            
            
            UICollectionViewLayoutAttributes * itemAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForItemAtIndexPath:indexPath];
            [valueInfo setObject:itemAttributes forKey:kItemAttributesKey];
        }
    }
}

- (void)prepareSupplementaryHeaderLayoutAtIndexPath:(NSIndexPath *)indexPath
{
    id<GLFlowLayoutDelegate> delegate = (id<GLFlowLayoutDelegate>)self.collectionView.delegate;
    NSMutableDictionary *valueInfo = [[NSMutableDictionary alloc] init];
    self.supplementaryViewHeaderLayoutInfo[indexPath] = valueInfo;
    
    [self.supplementaryLayoutInfo removeAllObjects];
    [self.supplementaryLayoutInfo setObject:[NSDictionary dictionaryWithDictionary:self.supplementaryViewHeaderLayoutInfo]
                                     forKey:UICollectionElementKindSectionHeader];
    
    
    // set default item size, then optionally override it
    CGSize size = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.headerReferenceSize.height);
    if(delegate && [delegate respondsToSelector:@selector(collectionView:layout:heightForSupplementaryViewOfKind:atIndexPath:)])
    {
        CGFloat height = [delegate collectionView:(UICollectionView*)self.collectionView layout:self heightForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        size.height = height;
    }
    [valueInfo setObject:[NSValue valueWithCGSize:size] forKey:kItemSizesKey];
    
    
    UICollectionViewLayoutAttributes * supplementaryAttributes =
    [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                     withIndexPath:indexPath];
    supplementaryAttributes.frame = [self frameForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                              atIndexPath:indexPath];
    [valueInfo setObject:supplementaryAttributes forKey:kItemAttributesKey];
}

- (void)prepareSupplementaryFooterLayoutAtIndexPath:(NSIndexPath *)indexPath
{
    id<GLFlowLayoutDelegate> delegate = (id<GLFlowLayoutDelegate>)self.collectionView.delegate;
    NSMutableDictionary *valueInfo = [[NSMutableDictionary alloc] init];
    self.supplementaryViewFooterLayoutInfo[indexPath] = valueInfo;
    
    [self.supplementaryLayoutInfo removeAllObjects];
    [self.supplementaryLayoutInfo setObject:[NSDictionary dictionaryWithDictionary:self.supplementaryViewFooterLayoutInfo]
                                     forKey:UICollectionElementKindSectionFooter];
    
    // set default item size, then optionally override it
    CGSize size = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.headerReferenceSize.height);
    if(delegate && [delegate respondsToSelector:@selector(collectionView:layout:heightForSupplementaryViewOfKind:atIndexPath:)])
    {
        CGFloat height = [delegate collectionView:(UICollectionView*)self.collectionView layout:self heightForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
        size.height = height;
    }
    [valueInfo setObject:[NSValue valueWithCGSize:size] forKey:kItemSizesKey];
    
    
    UICollectionViewLayoutAttributes * supplementaryAttributes =
    [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                     withIndexPath:indexPath];
    supplementaryAttributes.frame = [self frameForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                              atIndexPath:indexPath];
    [valueInfo setObject:supplementaryAttributes forKey:kItemAttributesKey];
}


- (void)prepareSupplementaryViewLayout {
    int sectionCount = [self.collectionView numberOfSections];
    
    for (int section = 0; section < sectionCount; section ++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        if (self.hasHeaders) {
            [self prepareSupplementaryHeaderLayoutAtIndexPath:indexPath];
        }
        
        if (self.hasFooters) {
            [self prepareSupplementaryFooterLayoutAtIndexPath:indexPath];
        }
    }
}


-(void)prepareLayout {
    if (self.shouldPerformItemLayout) {
        [self prepareItemLayout];
    }
    
    if (self.hasHeaders || self.hasFooters) {
        [self prepareSupplementaryViewLayout];
    }
}

-(CGSize)sizeForItemViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath*)indexPath;
{
    NSDictionary *valueInfo = self.itemLayoutInfo[kind][indexPath]; //self.cellKind
    return [valueInfo[kItemSizesKey] CGSizeValue];
}

-(CGSize)sizeForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary *valueInfo = self.supplementaryLayoutInfo[kind][indexPath];
    return [valueInfo[kItemSizesKey] CGSizeValue];
}

-(CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath {
    // This method is meant to be subclassed
    return CGRectZero;
}

-(CGRect)frameForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    // This method is meant to be subclassed
    return CGRectZero;
}

-(CGSize)collectionViewContentSize {
    // this method is meant to be subclassed
    return CGSizeZero;
}


-(NSArray *)layoutAttributesForLayoutDictionary:(NSDictionary *)dictionary andRect:(CGRect)rect {
    
    NSMutableArray *allAttributes = [NSMutableArray array];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                    NSDictionary *elementsInfo,
                                                    BOOL *stop)
     {
         [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                           NSDictionary *valueInfo,
                                                           BOOL *innerStop)
          {
              UICollectionViewLayoutAttributes *attributes = valueInfo[kItemAttributesKey];
              if (CGRectIntersectsRect(rect, attributes.frame)) {
                  [allAttributes addObject:attributes];
              }
          }];
     }];
    
    return allAttributes;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray * layoutAttributes = [[NSMutableArray alloc] init];
    if (self.shouldPerformItemLayout) {
        [layoutAttributes addObjectsFromArray:[self layoutAttributesForLayoutDictionary:self.itemLayoutInfo
                                                                                andRect:rect]];
    }
    
    if (self.hasHeaders || self.hasFooters)
    {
        [layoutAttributes addObjectsFromArray:[self layoutAttributesForLayoutDictionary:self.supplementaryLayoutInfo
                                                                                andRect:rect]];
    }
    return layoutAttributes;
}

-(UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *valueInfo = self.itemLayoutInfo[self.cellKind][indexPath];
    return valueInfo[kItemAttributesKey];
}

-(UICollectionViewLayoutAttributes *) layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        NSDictionary *valueInfo = self.supplementaryLayoutInfo[UICollectionElementKindSectionHeader][indexPath];
        return valueInfo[kItemAttributesKey];
    }
    if ([kind isEqualToString:UICollectionElementKindSectionFooter])
    {
        NSDictionary *valueInfo = self.supplementaryLayoutInfo[UICollectionElementKindSectionFooter][indexPath];
        return valueInfo[kItemAttributesKey];
    }
    
    return nil;
}

@end
