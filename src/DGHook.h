#import <Foundation/Foundation.h>
typedef BOOL (^DGEnabled)(void);
typedef void (^DGRecord)(NSString *event, NSUInteger count);
BOOL DGInstallHook(NSDictionary *spec, DGEnabled enabled, DGRecord record);
NSDictionary *DGSearchAdapterSnapshot(void);
