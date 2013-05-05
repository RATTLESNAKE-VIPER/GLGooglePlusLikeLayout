//
//  GLCell.m
//  GLGooglePlusLayout
//
//  Created by Gautam Lodhiya on 21/04/13.
//  Copyright (c) 2013 Gautam Lodhiya. All rights reserved.
//

#import "GLCell.h"

@interface GLCell()
@property (nonatomic, strong) UILabel *displayLabel;
@end

@implementation GLCell

#pragma mark - Accessors
- (UILabel *)displayLabel
{
    if (!_displayLabel) {
        _displayLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _displayLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _displayLabel.backgroundColor = [UIColor lightGrayColor];
        _displayLabel.textColor = [UIColor whiteColor];
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
        [self.contentView addSubview:self.displayLabel];
    }
    return self;
}

@end
