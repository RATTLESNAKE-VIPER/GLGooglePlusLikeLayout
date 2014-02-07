//
//  GLGooglePlusLikeLayout.h
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLFlowLayout.h"

typedef NS_ENUM(NSInteger, CellStyle) {
    CellStyleSmall, // currently only supported in LayoutStyleCompact
    CellStyleNormal,
    CellStyleLargeVerticalMini, // currently only supported in LayoutStyleCompact
    CellStyleLargeVertical,
    CellStyleLargeHorizontal,
    CellStyleLargeVerticalAndHorizontal,
};

typedef NS_ENUM(NSInteger, LayoutStyle) {
    LayoutStyleExpanded,
    LayoutStyleCompact,
};

static NSString * const ContentCellKind = @"content_cell";


@interface GLGooglePlusLikeLayout : GLFlowLayout

@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) CGFloat interitemSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGSize minimumItemSize;
@property (nonatomic) LayoutStyle layoutStyle;

- (CellStyle)cellStyleForIndexPath:(NSIndexPath*)indePath;

@end
