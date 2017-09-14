//
//  PushConfigView.m
//  PAPushSDKDemo
//
//  Created by Derek Lix on 21/06/2017.
//  Copyright © 2017 Derek Lix. All rights reserved.
//

#import "PushConfigView.h"

#define  IA_RtmpField_UrlKey  @"IA_RtmpField_UrlKey"


@interface PushConfigView () <UITextFieldDelegate>

@property (strong, nonatomic) UILabel *urlLabel;
@property (strong, nonatomic) UITextField *pushUrlField;
@property (strong, nonatomic) UISegmentedControl *definitionSWitch;
@property (strong, nonatomic) UISegmentedControl *resolutionSwitch;
@property (strong, nonatomic) NSString* resolution;
@property (strong, nonatomic) NSString* definition;
@property (copy, nonatomic) ConfigViewHandler handler;
@property (strong, nonatomic) UIButton* sureBtn;
@property (strong, nonatomic) UIButton* cancelBtn;
@property (strong, nonatomic) NSString* pushUrl;

@end

@implementation PushConfigView

- (instancetype)initWithFrame:(CGRect)frame configViewHandler:(ConfigViewHandler)configViewHandler{
    if (self = [super initWithFrame:frame]) {
        [self configViews];
        self.handler = configViewHandler;
        [self setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.3f]];
    }
    return self;
}

- (void)configViews{
    
    CGFloat xx = 10;
    //add label
    self.urlLabel = [[UILabel alloc] initWithFrame:CGRectMake(xx, 10, 50, 20)];
    [self.urlLabel setText:@"url: "];
    [self addSubview:self.urlLabel];
    
    //add pushUrlField
    CGFloat fieldX = self.urlLabel.frame.origin.x+self.urlLabel.frame.size.width;
    CGFloat fieldWidth = [UIScreen mainScreen].bounds.size.width - fieldX-20;
    self.pushUrlField = [[UITextField alloc] initWithFrame:CGRectMake(fieldX, self.urlLabel.origin.y,fieldWidth, 30)];
    self.pushUrlField.delegate = self;
    [self.pushUrlField setBackgroundColor:[UIColor darkGrayColor]];
    [self.pushUrlField.layer setBorderWidth:1.f];
    [self.pushUrlField.layer setBorderColor:[UIColor darkGrayColor].CGColor];
    [self addSubview:self.pushUrlField];
    
    NSString* rtmpUrlStr = [[NSUserDefaults standardUserDefaults] objectForKey:IA_RtmpField_UrlKey];
    if (!rtmpUrlStr||([rtmpUrlStr length]<=0)) {
        [self.pushUrlField setText:IA_DefaultRtmpUrl];
    }else
        [self.pushUrlField setText:rtmpUrlStr];
    
    [[NSUserDefaults standardUserDefaults] setObject:rtmpUrlStr forKey:IA_RtmpField_UrlKey];
    self.pushUrl = self.pushUrlField.text;
    
    CGFloat definitionSwitchY = self.pushUrlField.origin.y+ self.pushUrlField.frame.size.height+20;
    self.definitionSWitch = [[UISegmentedControl alloc] initWithFrame:CGRectMake(self.urlLabel.frame.origin.x, definitionSwitchY, fieldWidth, 40)];
    [self addSubview:self.definitionSWitch];
    [self.definitionSWitch removeAllSegments];
    [self.definitionSWitch insertSegmentWithTitle:@"512" atIndex:0 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"768" atIndex:1 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"1M" atIndex:2 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"1.5M" atIndex:3 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"2M" atIndex:4 animated:NO];
    [self.definitionSWitch setSelectedSegmentIndex:3];
    self.definition = @"1.5M";
    
    
    CGFloat resolutionSwitchY = self.definitionSWitch.origin.y+ self.definitionSWitch.frame.size.height+20;
    self.resolutionSwitch = [[UISegmentedControl alloc] initWithFrame:CGRectMake(self.urlLabel.frame.origin.x, resolutionSwitchY, fieldWidth, 40)];
    [self addSubview:self.resolutionSwitch];
    
    [self.resolutionSwitch removeAllSegments];
    [self.resolutionSwitch insertSegmentWithTitle:@"480p" atIndex:0 animated:NO];
    [self.resolutionSwitch insertSegmentWithTitle:@"540p" atIndex:1 animated:NO];
    [self.resolutionSwitch insertSegmentWithTitle:@"720p" atIndex:2 animated:NO];
    [self.resolutionSwitch setSelectedSegmentIndex:1];
    self.resolution = @"540p";
    
    CGFloat sureBtnY = self.resolutionSwitch.origin.y+ self.resolutionSwitch.frame.size.height+20;
    CGFloat sureBtnW = 100;
    CGFloat sureBtnH = 30;
    self.sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.urlLabel.frame.origin.x, sureBtnY, sureBtnW, sureBtnH)];
    [self.sureBtn setTitle:@"确认" forState:UIControlStateNormal];
    [self.sureBtn addTarget:self action:@selector(sureBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.sureBtn setBackgroundColor:[UIColor darkGrayColor]];
    [self.sureBtn setBackgroundColor:[UIColor blueColor]];
    self.sureBtn.alpha = 0.3f;
    [self.sureBtn.layer setCornerRadius:10.f];
    [self.sureBtn.layer setBorderWidth:1];
    [self.sureBtn.layer setBorderColor:[UIColor blueColor].CGColor];
    [self addSubview:self.sureBtn];
    
    CGFloat cancelBtnX = self.sureBtn.frame.origin.x + self.sureBtn.frame.size.width + 20;
    self.cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(cancelBtnX, sureBtnY, sureBtnW, sureBtnH)];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(cancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelBtn setBackgroundColor:[UIColor blueColor]];
    self.cancelBtn.alpha = 0.3f;
    [self.cancelBtn.layer setCornerRadius:10.f];
    [self.cancelBtn.layer setBorderWidth:1];
    [self.cancelBtn.layer setBorderColor:[UIColor blueColor].CGColor];
    [self addSubview:self.cancelBtn];
}

- (void)sureBtnClick:(id)sender{
    
    NSString* url =self.pushUrlField.text;
    if ([url length]==0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"url为空" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:IA_RtmpField_UrlKey];
    self.pushUrl = url;
    
    if (self.handler) {
        self.handler(YES,self.definition,self.resolution,self.pushUrl);
    }
}
- (void)cancelBtnClick:(id)sender{
    if (self.handler) {
        self.handler(NO,self.definition,self.resolution,self.pushUrl);
    }
}

- (IBAction)resolutionSwitchSender:(id)sender {
    
    NSInteger index = ((UISegmentedControl*)sender).selectedSegmentIndex;
    switch (index) {
        case 0:
            self.resolution = @"480p";
            break;
        case 1:
            self.resolution = @"540p";
            break;
        case 2:
            self.resolution = @"720p";
            break;
        default:
            break;
    }
}
- (IBAction)definitionSwitch:(id)sender {
    NSInteger index = ((UISegmentedControl*)sender).selectedSegmentIndex;
    switch (index) {
        case 0:
            self.definition = @"512";
            break;
        case 1:
            self.definition = @"768";
            break;
        case 2:
            self.definition = @"1M";
            break;
        case 3:
            self.definition = @"1.5M";
            break;
        case 4:
            self.definition = @"2M";
            break;
        default:
            break;
    }
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"textField :%@",textField.text);
    self.pushUrl = textField.text;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
