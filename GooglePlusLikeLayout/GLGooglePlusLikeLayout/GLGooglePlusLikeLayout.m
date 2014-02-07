//
//  GLGooglePlusLikeLayout.m
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import "GLGooglePlusLikeLayout.h"

static NSString * const CellSizeKey = @"cell_size";
static NSString * const CellStyleKey = @"cell_type";
static NSString * const CellRowIndexKey = @"cell_row_index";
static NSString * const CellColumnIndexKey = @"cell_column_index";
static NSString * const CellRowItemIndexKey = @"cell_row_item_index";
static NSString * const ChangeRowKey = @"change_row";


@interface GLGooglePlusLikeLayout() {
}

@property (nonatomic) NSUInteger numberOfColumns; // currently only 2 columns are supported (fixed 2 cols)

@property(nonatomic, strong) NSMutableArray *columnHeights; // height for each column
@property(nonatomic, strong) NSDictionary *layoutInfo;
@property(nonatomic, strong) NSMutableDictionary *cellAttributes;
@property(nonatomic, assign) NSInteger currentRow;
@property(nonatomic, assign) NSInteger rowItem;

@property(nonatomic, assign) CGFloat maxRowHeight;
@property(nonatomic, strong) NSMutableArray *sizeSetForCellStyles;

@end


@implementation GLGooglePlusLikeLayout

#pragma mark - Properties (Getters and Setters)

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    if (UIEdgeInsetsEqualToEdgeInsets(_edgeInsets, edgeInsets)) return;
    _edgeInsets = edgeInsets;
    
    [self invalidateLayout];
}

- (void)setInteritemSpacing:(CGFloat)interitemSpacing
{
    if (_interitemSpacing == interitemSpacing) return;
    _interitemSpacing = interitemSpacing;
    
    [self invalidateLayout];
}

- (void)setInterSectionSpacing:(CGFloat)interSectionSpacing
{
    if (_interSectionSpacing == interSectionSpacing) return;
    _interSectionSpacing = interSectionSpacing;
    
    [self invalidateLayout];
}

-(void)setNumberOfColumns:(NSUInteger)numberOfColumns
{
    if (_numberOfColumns == numberOfColumns) return;
    _numberOfColumns = numberOfColumns;
    
    [self invalidateLayout];
}

- (void)setMinimumItemSize:(CGSize)minimumItemSize
{
    if (CGSizeEqualToSize(_minimumItemSize, minimumItemSize)) return;
    minimumItemSize.width = floorf(minimumItemSize.width - ((self.edgeInsets.left + self.interitemSpacing + self.edgeInsets.right) / 2));
    minimumItemSize.height = floorf(minimumItemSize.height - ((self.edgeInsets.top + self.interitemSpacing + self.edgeInsets.bottom) / 2));
    _minimumItemSize = minimumItemSize;
    
    self.maxRowHeight = (2 * _minimumItemSize.height);
    
    
    self.sizeSetForCellStyles = [[NSMutableArray alloc] initWithCapacity:6];
    [self.sizeSetForCellStyles addObject:[NSValue valueWithCGSize:CGSizeMake(minimumItemSize.width, minimumItemSize.height / 2)]];
    [self.sizeSetForCellStyles addObject:[NSValue valueWithCGSize:minimumItemSize]];
    [self.sizeSetForCellStyles addObject:[NSValue valueWithCGSize:CGSizeMake(minimumItemSize.width, minimumItemSize.height + (minimumItemSize.height / 2))]];
    [self.sizeSetForCellStyles addObject:[NSValue valueWithCGSize:CGSizeMake(minimumItemSize.width, 2 * minimumItemSize.height)]];
    
    
    [self invalidateLayout];
}



#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if(self)
        [self setup];
    
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)dealloc
{
    [self.columnHeights removeAllObjects];
    self.columnHeights = nil;
    self.layoutInfo = nil;
    [self.cellAttributes removeAllObjects];
    self.cellAttributes = nil;
}



#pragma mark - Layout
- (void)prepareLayout
{
    [super resetAll];
    [self.cellAttributes removeAllObjects];
    
    
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    newLayoutInfo[ContentCellKind] = cellLayoutInfo;
    self.layoutInfo = newLayoutInfo;
    self.currentRow = 1;
    self.rowItem = 1;
    
    
    id<GLFlowLayoutDelegate> delegate = (id<GLFlowLayoutDelegate>)self.collectionView.delegate;
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    self.columnHeights = [NSMutableArray arrayWithCapacity:self.numberOfColumns];
    for (NSInteger idx = 0; idx < self.numberOfColumns; idx++) {
        [self.columnHeights addObject:@(self.edgeInsets.top)];
    }
    
    
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemCount; item++) {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            // set header
            if (indexPath.item == 0) {
                if (self.hasHeaders) {
                    float heightDiff = ABS(([self.columnHeights[0] floatValue]) - ([self.columnHeights[1] floatValue]));
                    if (heightDiff > 0) {
                        NSUInteger columnIndex = [self shortestColumnIndex];
                        self.columnHeights[columnIndex] = @([self.columnHeights[columnIndex] floatValue] + heightDiff);
                    }
                    
                    for (NSInteger idx = 0; idx < self.numberOfColumns; idx++) {
                        self.columnHeights[idx] = @([self.columnHeights[idx] floatValue] - self.interitemSpacing);
                    }
                    
                    [super prepareSupplementaryHeaderLayoutAtIndexPath:indexPath];
                }
            }
            
            
            NSMutableDictionary *cellProperties = [NSMutableDictionary new];
            self.cellAttributes[indexPath] = cellProperties;
            
            
            
            // set default item size, then optionally override it
            CGSize intrinsicContentSize = self.minimumItemSize;
            if(delegate && [delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)])
            {
                intrinsicContentSize = [delegate collectionView:(UICollectionView*)self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
            }
            
            // Identify cell style
            CellStyle cellStyle = [self cellStyleForSize:intrinsicContentSize];
            
            if (self.layoutStyle == LayoutStyleExpanded) {
                // Adjust layout
                [self adjustLayoutByExpadingForCellStyle:cellStyle atIndexPath:indexPath];
                
                // Identify cell column index (Item will be put into shortest column)
                NSUInteger columnIndex = [self shortestColumnIndex];
                
                // Prepare item
                [self prepareItemWithIntrinsicContentSize:intrinsicContentSize withStyle:cellStyle atColumn:columnIndex atIndexPath:indexPath];
                
            } else if (self.layoutStyle == LayoutStyleCompact) {
                [self adjustLayoutByCompactingForCellStyle:cellStyle atIndexPath:indexPath withIntrinsicSize:intrinsicContentSize];
            }
        }
    }
    
    
    //    [super prepareLayout];
}

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = self.collectionView.frame.size;
    NSUInteger columnIndex = [self longestColumnIndex];
    CGFloat height = [self.columnHeights[columnIndex] floatValue];
    contentSize.height = MAX(height - self.interitemSpacing + self.edgeInsets.bottom, CGRectGetHeight(self.collectionView.frame));
    return contentSize;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray new];
    
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                         NSDictionary *elementsInfo,
                                                         BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                          UICollectionViewLayoutAttributes *attributes,
                                                          BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    if (self.hasHeaders || self.hasFooters) {
        [allAttributes addObjectsFromArray:[super layoutAttributesForElementsInRect:rect]];
    }
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[ContentCellKind][indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return (UICollectionViewLayoutAttributes *)[super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
}

- (CGRect)frameForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    id<GLFlowLayoutDelegate> delegate = (id<GLFlowLayoutDelegate>)self.collectionView.delegate;
    CGRect frame = CGRectZero;
    
    
    CGFloat interSectionSpacing = self.interSectionSpacing;
    if(delegate && [delegate respondsToSelector:@selector(collectionView:layout:interSectionSpacingForSupplementaryViewOfKind:atIndexPath:)])
    {
        interSectionSpacing = [delegate collectionView:(UICollectionView*)self.collectionView layout:self interSectionSpacingForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    }
    CGFloat yOffset = floor([(self.columnHeights[0]) floatValue]);
    yOffset += interSectionSpacing;
    
    
    CGSize suppSize = CGSizeZero;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        suppSize = [super sizeForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        suppSize = [super sizeForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
    }
    
    
    frame = CGRectMake(0, yOffset, suppSize.width, suppSize.height);
    for (NSInteger idx = 0; idx < self.numberOfColumns; idx++) {
        self.columnHeights[idx] = @([self.columnHeights[idx] floatValue] + suppSize.height + (2 * interSectionSpacing));
    }
    
    
    return frame;
}

- (void)finalizeCollectionViewUpdates
{
    [super finalizeCollectionViewUpdates];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return NO;
}



#pragma mark - Private Methods

- (void)adjustLayoutByExpadingForCellStyle:(CellStyle)cellStyle atIndexPath:(NSIndexPath *)indexPath
{
    if (self.cellAttributes && self.cellAttributes.count > 0) {
        if (indexPath.item > 0) {
            NSIndexPath *prevIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
            prevIndexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
            NSDictionary *itemProperties = self.cellAttributes[prevIndexPath];
            BOOL isNewLayout = [itemProperties[ChangeRowKey] boolValue];
            //NSInteger prevCellRow = [itemProperties[CellRowIndexKey] integerValue];
            
            
            if (!isNewLayout) {
                NSInteger prevCellColumn = [itemProperties[CellColumnIndexKey] integerValue];
                CellStyle prevCellStyle = [itemProperties[CellStyleKey] integerValue];
                
                NSMutableDictionary *cellLayoutInfo = self.layoutInfo[ContentCellKind];
                UICollectionViewLayoutAttributes* prevCellLayoutAttributes = cellLayoutInfo[prevIndexPath];
                
                if (prevCellColumn == 0) {
                    if (prevCellStyle == CellStyleNormal || prevCellStyle == CellStyleLargeVertical) {
                        if (cellStyle == CellStyleLargeHorizontal || cellStyle == CellStyleLargeVerticalAndHorizontal) {
                            CGFloat height = [self.columnHeights[prevCellColumn] floatValue];
                            self.columnHeights[prevCellColumn] = @(height - (CGRectGetHeight(prevCellLayoutAttributes.frame) + self.interitemSpacing));
                            
                            CGSize intrinsicContentSize = CGSizeMake(floorf(CGRectGetWidth(prevCellLayoutAttributes.frame) + CGRectGetWidth(prevCellLayoutAttributes.frame)), floorf(CGRectGetHeight(prevCellLayoutAttributes.frame)));
                            [self prepareItemWithIntrinsicContentSize:intrinsicContentSize withStyle:prevCellStyle atColumn:prevCellColumn atIndexPath:prevIndexPath];
                        }
                    }
                    
                } else if (prevCellColumn == 1) {
                    if (prevCellStyle == CellStyleNormal) {
                        if (indexPath.item > 1) {
                            NSIndexPath *prevIndexPath2 = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
                            prevIndexPath2 = [NSIndexPath indexPathForItem:(indexPath.item - 2) inSection:indexPath.section];
                            NSDictionary *itemProperties2 = self.cellAttributes[prevIndexPath2];
                            BOOL isNewLayout2 = [itemProperties2[ChangeRowKey] boolValue];
                            
                            if (!isNewLayout2) {
                                CellStyle prevCellStyle2 = [itemProperties2[CellStyleKey] integerValue];
                                if (prevCellStyle2 == CellStyleLargeVertical) {
                                    CGFloat height = [self.columnHeights[prevCellColumn] floatValue];
                                    self.columnHeights[prevCellColumn] = @(height - (CGRectGetHeight(prevCellLayoutAttributes.frame) + self.interitemSpacing));
                                    
                                    CGSize intrinsicContentSize = CGSizeMake(floorf(CGRectGetWidth(prevCellLayoutAttributes.frame)), floorf(CGRectGetHeight(prevCellLayoutAttributes.frame) + CGRectGetHeight(prevCellLayoutAttributes.frame)));
                                    [self prepareItemWithIntrinsicContentSize:intrinsicContentSize withStyle:prevCellStyle atColumn:prevCellColumn atIndexPath:prevIndexPath];
                                }
                            }
                        }
                        
                    } else if (prevCellStyle == CellStyleLargeVertical) {
                        if (indexPath.item > 1) {
                            NSIndexPath *prevIndexPath2 = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
                            prevIndexPath2 = [NSIndexPath indexPathForItem:(indexPath.item - 2) inSection:indexPath.section];
                            NSDictionary *itemProperties2 = self.cellAttributes[prevIndexPath2];
                            BOOL isNewLayout2 = [itemProperties2[ChangeRowKey] boolValue];
                            
                            if (!isNewLayout2) {
                                NSInteger prevCellColumn2 = [itemProperties2[CellColumnIndexKey] integerValue];
                                CellStyle prevCellStyle2 = [itemProperties2[CellStyleKey] integerValue];
                                UICollectionViewLayoutAttributes* prevCellLayoutAttributes2 = cellLayoutInfo[prevIndexPath2];
                                
                                if (prevCellStyle2 == CellStyleNormal) {
                                    CGFloat height = [self.columnHeights[prevCellColumn2] floatValue];
                                    self.columnHeights[prevCellColumn2] = @(height - (CGRectGetHeight(prevCellLayoutAttributes2.frame) + self.interitemSpacing));
                                    
                                    CGSize intrinsicContentSize = CGSizeMake(floorf(CGRectGetWidth(prevCellLayoutAttributes2.frame)), floorf(CGRectGetHeight(prevCellLayoutAttributes2.frame) + CGRectGetHeight(prevCellLayoutAttributes2.frame)));
                                    [self prepareItemWithIntrinsicContentSize:intrinsicContentSize withStyle:prevCellStyle2 atColumn:prevCellColumn2 atIndexPath:prevIndexPath2];
                                }
                            }
                        }
                    }
                }
            } //end condition: isNewLayout
        } //end condition: indexPath.item > 0
    }
}

- (void)adjustLayoutByCompactingForCellStyle:(CellStyle)cellStyle atIndexPath:(NSIndexPath *)indexPath withIntrinsicSize:(CGSize)size
{
    // Identify cell column index (Item will be put into shortest column)
    NSUInteger columnIndex = [self shortestColumnIndex];
    
    if (self.cellAttributes && self.cellAttributes.count > 0) {
        BOOL execute = TRUE;
        NSIndexPath *prevIndexPath = [self previousIndexPathAtPath:indexPath];
        
        do {
            if (cellStyle == CellStyleLargeVerticalAndHorizontal || cellStyle == CellStyleLargeHorizontal) {
                if (self.rowItem == 1) {
                    size.width = (2 * self.minimumItemSize.width);
                } else {
                    size.width = self.minimumItemSize.width;
                }
            }
            
            if (prevIndexPath.item == 0) {
                execute = FALSE;
                continue;
            }
            NSDictionary *prevItemProperties = self.cellAttributes[prevIndexPath];
            execute = [prevItemProperties[ChangeRowKey] boolValue] == FALSE ? TRUE : FALSE;
            if (!execute)
                continue;
            
            CGFloat currentRowHeight = [self rowHeightForColumn:columnIndex atIndexPath:indexPath];
            if (currentRowHeight < self.maxRowHeight) {
                
                
                float heightDiff = ABS(self.maxRowHeight - currentRowHeight) - (self.edgeInsets.top + self.edgeInsets.bottom);
                CGSize placeholderCellSize = CGSizeMake(self.minimumItemSize.width, heightDiff);
                CellStyle placeholderCellStyle = [self cellStyleForSize:placeholderCellSize];
                
                if (size.height > placeholderCellSize.height) {
                    if (placeholderCellStyle == CellStyleSmall && cellStyle != CellStyleSmall) {
                        NSIndexPath *changedIndexPath = [self adjustPreviousCellInColumn:columnIndex atIndexPath:indexPath withHeight:heightDiff];
                        
                        if (cellStyle != CellStyleSmall && cellStyle != CellStyleNormal) {
                            NSDictionary *changedItemProperties = self.cellAttributes[changedIndexPath];
                            CellStyle changedCellStyle = [changedItemProperties[CellStyleKey] integerValue];
                            if (changedCellStyle == CellStyleNormal) {
                                size = self.minimumItemSize;
                                cellStyle = [self cellStyleForSize:size];
                                columnIndex = [self shortestColumnIndex];
                                [self prepareItemWithIntrinsicContentSize:size withStyle:cellStyle atColumn:columnIndex atIndexPath:indexPath];
                                return;
                            }
                        }
                        
                    } else {
                        size = placeholderCellSize;
                        cellStyle = placeholderCellStyle;
                    }
                }
            }
            
            
            prevIndexPath = [self previousIndexPathAtPath:prevIndexPath];
            
        } while (execute);
    }
    
    // ----set current cell only if not set in the above conditions----
    columnIndex = [self shortestColumnIndex];
    [self prepareItemWithIntrinsicContentSize:size withStyle:cellStyle atColumn:columnIndex atIndexPath:indexPath];
}



- (void)prepareItemWithIntrinsicContentSize:(CGSize)intrinsicContentSize withStyle:(CellStyle)cellStyle atColumn:(NSInteger)columnIndex atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *cellLayoutInfo = self.layoutInfo[ContentCellKind];
    NSMutableDictionary *cellProperties = self.cellAttributes[indexPath];
    
    
    // Re-Identify cell style
    cellStyle = [self cellStyleForSize:intrinsicContentSize];
    
    // Re-Adjust cell size
    intrinsicContentSize = [self adjustItemSize:intrinsicContentSize forCellStyle:cellStyle];
    
    
    // Set cell attributes
    cellProperties[CellSizeKey] = [NSValue valueWithCGSize:intrinsicContentSize];
    cellProperties[CellStyleKey] = @(cellStyle);
    cellProperties[CellRowIndexKey] = @(self.currentRow);
    cellProperties[CellColumnIndexKey] = @(columnIndex);
    cellProperties[CellRowItemIndexKey] = @(self.rowItem);
    cellProperties[ChangeRowKey] = @(FALSE);
    
    
    // Set layout attributes
    UICollectionViewLayoutAttributes* cellLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    cellLayoutAttributes.frame = [self frameForCellAtColumn:columnIndex withIntinsicContentSize:intrinsicContentSize];
    cellLayoutInfo[indexPath] = cellLayoutAttributes;
    
    
    self.columnHeights[columnIndex] = @(CGRectGetMaxY(cellLayoutAttributes.frame) + self.interitemSpacing);
    
    
    if (columnIndex == 0) {
        if (self.rowItem == 1) {
            if (cellStyle == CellStyleLargeVerticalAndHorizontal || cellStyle == CellStyleLargeHorizontal) {
                self.columnHeights[1] = @(CGRectGetMaxY(cellLayoutAttributes.frame) + self.interitemSpacing);
            }
        }
    }
    
    
    // Adjust height between 2 columns
    float diff = ABS(([self.columnHeights[0] floatValue]) - ([self.columnHeights[1] floatValue]));
    if (diff == 1 || diff == 2) {
        if (([self.columnHeights[0] floatValue]) > ([self.columnHeights[1] floatValue])) {
            self.columnHeights[0] = @([self.columnHeights[0] floatValue] - diff);
        } else if (([self.columnHeights[0] floatValue]) < ([self.columnHeights[1] floatValue])) {
            self.columnHeights[1] = @([self.columnHeights[1] floatValue] - diff);
        }
    }
    
    
    if (([self.columnHeights[0] floatValue]) == ([self.columnHeights[1] floatValue])) {
        NSIndexPath *nextIndexPath = [self lastCellIndexPathInRow:indexPath];
        
        if (indexPath == nextIndexPath) {
            cellProperties[ChangeRowKey] = @(TRUE);
            
            // set rowID
            if ([cellProperties[ChangeRowKey] boolValue]) {
                self.currentRow++;
                self.rowItem = 0;
            }
            self.rowItem++;
            
        } else {
            NSMutableDictionary *nextItemProperties = self.cellAttributes[nextIndexPath];
            
            if (nextItemProperties && nextItemProperties.allKeys.count > 0) {
                cellProperties[ChangeRowKey] = @(FALSE);
                nextItemProperties[ChangeRowKey] = @(TRUE);
                
                // set rowID
                if ([nextItemProperties[ChangeRowKey] boolValue]) {
                    self.currentRow++;
                    self.rowItem = 0;
                }
                self.rowItem++;
                
            } else {
                cellProperties[ChangeRowKey] = @(TRUE);
                
                // set rowID
                if ([cellProperties[ChangeRowKey] boolValue]) {
                    self.currentRow++;
                    self.rowItem = 0;
                }
                self.rowItem++;
            }
        }
    } else {
        // set rowID
        if ([cellProperties[ChangeRowKey] boolValue]) {
            self.currentRow++;
            self.rowItem = 0;
        }
        self.rowItem++;
    }
}






// Identify cell style
- (CellStyle)cellStyleForSize:(CGSize)cellSize
{
    CGSize constraintSize = CGSizeMake(self.minimumItemSize.width + self.edgeInsets.left + self.edgeInsets.right, self.minimumItemSize.height + self.edgeInsets.top + self.edgeInsets.bottom);
    
    if (cellSize.width <= constraintSize.width) {
        cellSize = [self closestSize:cellSize inSet:self.sizeSetForCellStyles];
        
        if (cellSize.height <= constraintSize.height) {
            if (self.layoutStyle == LayoutStyleCompact) {
                if (cellSize.height <= (constraintSize.height / 2)) {
                    return CellStyleSmall;
                }
            }
            return CellStyleNormal;
        } else {
            if (cellSize.height <= (2 * self.minimumItemSize.height) - (self.minimumItemSize.height / 2)) {
                return CellStyleLargeVerticalMini;
            }
            return CellStyleLargeVertical;
        }
    } else if (cellSize.height <= constraintSize.height) {
        return CellStyleLargeHorizontal;
    }
    
    return CellStyleLargeVerticalAndHorizontal;
}

// Adjust cell size
- (CGSize)adjustItemSize:(CGSize)itemSize forCellStyle:(CellStyle)cellStyle
{
    CGSize newSize = CGSizeMake(floorf(itemSize.width), floorf(itemSize.height));
    
    if (cellStyle == CellStyleSmall) {
        newSize.width = floorf(self.minimumItemSize.width);
        newSize.height = floorf((self.minimumItemSize.height / 2) - (self.interitemSpacing / 2));
        
    } else if (cellStyle == CellStyleNormal) {
        newSize = CGSizeMake(floorf(self.minimumItemSize.width), floorf(self.minimumItemSize.height));
        
    } else if (cellStyle == CellStyleLargeVerticalMini) {
        newSize.width = floorf(self.minimumItemSize.width);
        newSize.height = floorf((2 * self.minimumItemSize.height) - (self.minimumItemSize.height / 2) + (self.interitemSpacing / 2));
        
    } else if (cellStyle == CellStyleLargeVertical) {
        newSize.width = floorf(self.minimumItemSize.width);
        newSize.height = floorf((2 * self.minimumItemSize.height) + self.interitemSpacing);
        
    } else if (cellStyle == CellStyleLargeHorizontal) {
        newSize.width = floorf((2 * self.minimumItemSize.width) + self.interitemSpacing);
        newSize.height = floorf(MAX(self.minimumItemSize.height, newSize.height));
        
    } else if (cellStyle == CellStyleLargeVerticalAndHorizontal) {
        newSize.width = floorf((2 * self.minimumItemSize.width) + self.interitemSpacing);
        newSize.height = floorf(MAX(self.minimumItemSize.height, newSize.height));
        
    }
    
    return newSize;
}

- (CGRect)frameForCellAtColumn:(NSInteger)columnIndex withIntinsicContentSize:(CGSize)intrinsicContentSize
{
    CGFloat xOffset = self.edgeInsets.left + (intrinsicContentSize.width + self.interitemSpacing) * columnIndex;
    CGFloat yOffset = floor([(self.columnHeights[columnIndex]) floatValue]);
    return CGRectMake(xOffset, yOffset, intrinsicContentSize.width, intrinsicContentSize.height);
}


// Find out shortest column.
- (NSUInteger)shortestColumnIndex
{
    __block NSUInteger index = 0;
    __block CGFloat shortestHeight = MAXFLOAT;
    
    [self.columnHeights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height < shortestHeight) {
            shortestHeight = height;
            index = idx;
        }
    }];
    
    return index;
}

// Find out longest column.
- (NSUInteger)longestColumnIndex
{
    __block NSUInteger index = 0;
    __block CGFloat longestHeight = 0;
    
    [self.columnHeights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height > longestHeight) {
            longestHeight = height;
            index = idx;
        }
    }];
    
    return index;
}




- (NSIndexPath *)lastCellIndexPathInRow:(NSIndexPath *)indexPath
{
    NSIndexPath *lastIndexPath = indexPath;
    
    BOOL execute = TRUE;
    NSIndexPath *nextIndexPath = indexPath;
    
    do {
        if ((nextIndexPath.item + 1) < self.cellAttributes.allKeys.count - 1) {
            nextIndexPath = [NSIndexPath indexPathForItem:(nextIndexPath.item + 1) inSection:nextIndexPath.section];
        } else {
            execute = FALSE;
        }
        
        if ((nextIndexPath.item) < self.cellAttributes.allKeys.count - 1) {
            nextIndexPath = [NSIndexPath indexPathForItem:(nextIndexPath.item) inSection:nextIndexPath.section];
        }
        lastIndexPath = nextIndexPath;
        
    } while (execute);
    
    
    return lastIndexPath;
}

- (void)setLastCellRow:(NSIndexPath *)indexPath
{
    BOOL execute = TRUE;
    NSIndexPath *nextIndexPath = indexPath;
    
    do {
        if ((nextIndexPath.item + 1) < self.cellAttributes.allKeys.count - 1) {
            nextIndexPath = [NSIndexPath indexPathForItem:(nextIndexPath.item + 1) inSection:nextIndexPath.section];
        } else {
            execute = FALSE;
        }
        
        if ((nextIndexPath.item) < self.cellAttributes.allKeys.count - 1) {
            nextIndexPath = [NSIndexPath indexPathForItem:(nextIndexPath.item) inSection:nextIndexPath.section];
        }
        self.rowItem++;
        
    } while (execute);
}

- (NSIndexPath *)previousIndexPathAtPath:(NSIndexPath *)indexPath
{
    NSIndexPath *prevIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
    if (indexPath.item > 0) {
        prevIndexPath = [NSIndexPath indexPathForItem:(indexPath.item - 1) inSection:indexPath.section];
    }
    return prevIndexPath;
}



- (NSIndexPath *)adjustPreviousCellInColumn:(NSInteger)columnIndex atIndexPath:(NSIndexPath *)indexPath withHeight:(CGFloat)heightToIncrease
{
    NSIndexPath *changedIndexPath;
    BOOL execute = TRUE;
    NSIndexPath *prevIndexPath = [self previousIndexPathAtPath:indexPath];
    
    do {
        if (prevIndexPath.item == 0) {
            execute = FALSE;
            //continue;
        }
        
        NSDictionary *prevItemProperties = self.cellAttributes[prevIndexPath];
        execute = [prevItemProperties[ChangeRowKey] boolValue] == FALSE ? TRUE : FALSE;
        if (!execute)
            continue;
        
        NSInteger prevCellColumn = [prevItemProperties[CellColumnIndexKey] integerValue];
        if (prevCellColumn == columnIndex) {
            execute = FALSE;
            self.rowItem = [prevItemProperties[CellRowItemIndexKey] integerValue];
            changedIndexPath = prevIndexPath;
            
            NSMutableDictionary *cellLayoutInfo = self.layoutInfo[ContentCellKind];
            UICollectionViewLayoutAttributes* prevCellLayoutAttributes = cellLayoutInfo[prevIndexPath];
            
            NSInteger prevCellColumn = [prevItemProperties[CellColumnIndexKey] integerValue];
            CellStyle prevCellStyle = [prevItemProperties[CellStyleKey] integerValue];
            CGFloat height = [self.columnHeights[prevCellColumn] floatValue];
            self.columnHeights[prevCellColumn] = @(height - (CGRectGetHeight(prevCellLayoutAttributes.frame) + self.interitemSpacing));
            
            CGSize placeholderCellSize = CGSizeMake(self.minimumItemSize.width, floorf(CGRectGetHeight(prevCellLayoutAttributes.frame) + heightToIncrease));
            CellStyle placeholderCellStyle = [self cellStyleForSize:placeholderCellSize];
            if (prevCellStyle == CellStyleLargeVertical || prevCellStyle == CellStyleLargeVerticalMini) {
                placeholderCellSize = CGSizeMake(self.minimumItemSize.width, floorf(self.minimumItemSize.height));
                placeholderCellStyle = [self cellStyleForSize:placeholderCellSize];
            }
            [self prepareItemWithIntrinsicContentSize:placeholderCellSize withStyle:placeholderCellStyle atColumn:prevCellColumn atIndexPath:prevIndexPath];
        }
        
        prevIndexPath = [self previousIndexPathAtPath:prevIndexPath];
        
    } while (execute);
    
    [self setLastCellRow:indexPath];
    return changedIndexPath;
}

- (CGFloat)rowHeightForColumn:(NSInteger)columnIndex atIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 0;
    BOOL execute = TRUE;
    NSIndexPath *prevIndexPath = [self previousIndexPathAtPath:indexPath];
    
    do {
        NSDictionary *prevItemProperties = self.cellAttributes[prevIndexPath];
        execute = [prevItemProperties[ChangeRowKey] boolValue] == FALSE ? TRUE : FALSE;
        if (!execute)
            continue;
        
        if (prevIndexPath.item == 0) {
            execute = FALSE;
        }
        
        NSMutableDictionary *cellLayoutInfo = self.layoutInfo[ContentCellKind];
        UICollectionViewLayoutAttributes* prevCellLayoutAttributes = cellLayoutInfo[prevIndexPath];
        if ([prevItemProperties[CellColumnIndexKey] integerValue] == columnIndex) {
            rowHeight += prevCellLayoutAttributes.size.height;
        }
        
        prevIndexPath = [self previousIndexPathAtPath:prevIndexPath];
    } while (execute);
    
    return rowHeight;
}



- (CGSize)closestSize:(CGSize)size inSet:(NSArray*)set
{
    CGSize closest = [[set objectAtIndex:0] CGSizeValue];
    CGFloat prev = ABS(closest.height - size.height);
    
    for (int i = 1; i < set.count; i++) {
        CGSize temp = [[set objectAtIndex:i] CGSizeValue];
        CGFloat diff = ABS(temp.height - size.height);
        
        if (diff < prev) {
            prev = diff;
            closest = temp;
        }
    }
    
    return closest;
}



- (void)setup
{
    // set default values for all properties
    self.edgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    self.interitemSpacing = 15.0f;
    self.interSectionSpacing = 15.0f;
    self.numberOfColumns = 2;
    self.minimumItemSize = CGSizeMake(350.0f, 350.0f);
    self.cellAttributes = [NSMutableDictionary new];
    self.layoutStyle = LayoutStyleCompact;
}


#pragma mark - Public Methods

- (CellStyle)cellStyleForIndexPath:(NSIndexPath *)indexPath
{
    if (self.cellAttributes && self.cellAttributes.count > 0) {
        NSDictionary *itemProperties = self.cellAttributes[indexPath];
        CellStyle cellStyle = [itemProperties[CellStyleKey] integerValue];
        return cellStyle;
    }
    
    return CellStyleNormal;
}


@end
