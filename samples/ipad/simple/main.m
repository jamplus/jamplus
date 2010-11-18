#import <UIKit/UIKit.h>

// Application delegate
@interface Simple : NSObject <UIApplicationDelegate>
{
}

@end

@implementation Simple

- (void)applicationDidFinishLaunching: (UIApplication*)application
{
    UIWindow* window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    [window setBackgroundColor: [UIColor yellowColor]];
                        
    [window makeKeyAndVisible];
}

@end


int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"Simple");
    [pool release];
    return retVal;
}
