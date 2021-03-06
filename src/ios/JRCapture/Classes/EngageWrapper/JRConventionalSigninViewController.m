/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright (c) 2010, Janrain, Inc.

 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.
 * Neither the name of the Janrain, Inc. nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 File:   EmbeddedNativeSignInViewController.m
 Author: Lilli Szafranski - lilli@janrain.com, lillialexis@gmail.com
 Date:   Tuesday, June 1, 2010
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(...)
#endif

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#import "JRConventionalSignInViewController.h"
#import "JREngageWrapper.h"
#import "JRUserInterfaceMaestro.h"

@interface JREngageWrapper (JREngageWrapper_InternalMethods)
- (void)authenticationDidReachTokenUrl:(NSString *)tokenUrl withResponse:(NSURLResponse *)response andPayload:(NSData *)tokenUrlPayload forProvider:(NSString *)provider;
@end

@interface JRConventionalSignInViewController ()
@property (retain) NSString *titleString;
@property (retain) UIView   *titleView;
@property JRConventionalSigninType signInType;
@property (retain) JREngageWrapper *wrapper;
@end

@implementation JRConventionalSignInViewController
@synthesize signInType;
@synthesize titleString;
@synthesize titleView;
@synthesize wrapper;
@synthesize delegate;
@synthesize firstResponder;


- (id)initWithConventionalSignInType:(JRConventionalSigninType)theSignInType titleString:(NSString *)theTitleString
                                                                               titleView:(UIView *)theTitleView
                                                                           engageWrapper:(JREngageWrapper *)theWrapper
{
    if ((self = [super init]))
    {
        signInType = theSignInType;
        titleString = [theTitleString retain];
        titleView = [theTitleView retain];
        wrapper = [theWrapper retain];
    }

    return self;
}

+ (id)conventionalSignInViewController:(JRConventionalSigninType)theSignInType titleString:(NSString *)theTitleString
                             titleView:(UIView *)theTitleView engageWrapper:(JREngageWrapper *)theWrapper
{
    return [[[JRConventionalSignInViewController alloc]
            initWithConventionalSignInType:theSignInType
                               titleString:theTitleString
                                 titleView:theTitleView engageWrapper:theWrapper] autorelease];
}

- (void)loadView
{
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 170) style:UITableViewStyleGrouped];
    myTableView.backgroundColor = [UIColor clearColor];
    myTableView.scrollEnabled   = NO;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];

    [button setFrame:CGRectMake(10, 2, 300, 40)];
    [button setBackgroundImage:[UIImage imageNamed:@"button_janrain_280x40.png"]
                      forState:UIControlStateNormal];

    [button setTitle:@"Sign In" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];

    button.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];

    [button addTarget:self
               action:@selector(signInButtonTouchUpInside:)
     forControlEvents:UIControlEventTouchUpInside];

    UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)] autorelease];
    [footerView addSubview:button];

    myTableView.tableFooterView = footerView;
    myTableView.dataSource = self;
    myTableView.delegate = self;

    self.view = myTableView;

    [self.view setClipsToBounds:NO];

//    [self createLoadingView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [myTableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.titleView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.titleString;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (titleView)
        return titleView.frame.size.height;

    return 40;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

#define  NAME_TEXTFIELD_TAG 1000
#define  PWD_TEXTFIELD_TAG 2000

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"Cell";
    UITextField *textField;

    NSString *const cellId = indexPath.row == 0 ? @"cellForName" : @"cellForPwd";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];

        textField = [[[UITextField alloc] initWithFrame:CGRectMake(10, 7, 280, 26)] autorelease];

        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.returnKeyType = UIReturnKeyDone;
        textField.delegate = self;

        [cell.contentView addSubview:textField];

        if (indexPath.row == 0)
        {
            NSString *const placedHolder = self.signInType == JRConventionalSigninEmailPassword ?
                    @"Enter your email" :
                    @"Enter your username";
            textField.placeholder = placedHolder;
            textField.delegate = self;
            textField.tag = NAME_TEXTFIELD_TAG;
        }
        else
        {
            textField.placeholder = @"Enter your password";
            textField.secureTextEntry = YES;

            textField.delegate = self;
            textField.tag = PWD_TEXTFIELD_TAG;
        }
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.firstResponder = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.firstResponder = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)signInButtonTouchUpInside:(UIButton*)button
{
    UITableViewCell *nameCell = [myTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *pwdCell  = [myTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *nameOrEmail = ((UITextField *) [nameCell viewWithTag:NAME_TEXTFIELD_TAG]).text;
    NSString *password = ((UITextField *) [pwdCell viewWithTag:PWD_TEXTFIELD_TAG]).text;
    if (!nameOrEmail) nameOrEmail = @"";
    if (!password) password = @"";

    //    NSMutableString *errorMessage = [NSMutableString stringWithString:@"Please enter your "];
//
//    if (!nameTextField.text || [nameTextField.text isEqualToString:@""])
//        [errorMessage appendString:self.signinType == JRConventionalSigninEmailPassword ? @"email address " : "username"];
//
//    if (!pwdTextField.text || [pwdTextField.text isEqualToString:@""])
//        [errorMessage appendString:@"password"];

    NSString *const signInTypeString = (self.signInType == JRConventionalSigninEmailPassword) ? @"email" : @"username";
    [JRCaptureApidInterface signinCaptureUserWithCredentials:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                   nameOrEmail, signInTypeString,
                                                                                   password, @"password", nil]
                                                      ofType:signInTypeString
                                                 forDelegate:self
                                                 withContext:nil];

    [self.firstResponder resignFirstResponder];
    [self setFirstResponder:nil];

    [delegate showLoading];
}

- (void)signinCaptureUserDidSucceedWithResult:(NSString *)result context:(NSObject *)context
{
    [delegate hideLoading];

    [wrapper authenticationDidReachTokenUrl:@"/oath/mobile_signin_username_password"
                               withResponse:nil
                                 andPayload:[result dataUsingEncoding:NSUTF8StringEncoding]
                                forProvider:nil];

    [delegate authenticationDidComplete];
}

- (void)signinCaptureUserDidFailWithResult:(NSDictionary *)result context:(NSObject *)context
{

    DLog(@"result: %@", [result description]);
    NSString const *type = self.signInType == JRConventionalSigninEmailPassword ? @"Email" : @"Username";
    NSString *title = [NSString stringWithFormat:@"Incorrect %@ or Password", type];
    NSString *const message = [result objectForKey:@"error"];
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Dismiss"
                                               otherButtonTitles:nil] autorelease];
    [alertView show];

    [delegate hideLoading];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [myTableView release];
    [delegate release];
    [titleView release];
    [titleString release];
    [firstResponder release];

    [wrapper release];
    [super dealloc];
}
@end

