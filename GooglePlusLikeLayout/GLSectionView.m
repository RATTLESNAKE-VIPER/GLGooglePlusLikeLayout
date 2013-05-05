//
//  GLSectionView.m
//  GooglePlusLikeLayout
//
//  Created by Gautam Lodhiya on 05/05/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import "GLSectionView.h"

@interface GLSectionView ()

@end

@implementation GLSectionView

#pragma mark - Accessors
- (UILabel *)displayLabel
{
    if (!_displayLabel) {
        _displayLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _displayLabel.font = [UIFont boldSystemFontOfSize:14];
        _displayLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _displayLabel.backgroundColor = [UIColor clearColor];
        _displayLabel.textColor = [UIColor grayColor];
        _displayLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _displayLabel;
}

- (void)setDisplayString:(NSString *)displayString
{
    if (![_displayString isEqualToString:displayString]) {
        _displayString = [displayString copy];
        self.displayLabel.text = _displayString;
    }
}

#pragma mark - Life Cycle
- (void)dealloc
{
    [_displayLabel removeFromSuperview];
    _displayLabel = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self addSubview:self.displayLabel];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
