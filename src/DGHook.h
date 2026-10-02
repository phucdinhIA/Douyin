#import <Foundation/Foundation.h>
typedef BOOL (^DGEnabled)(void);
typedef void (^DGRecord)(NSString *event, NSUInteger count);
BOOL DGInstallHook(NSDictionary *spec, DGEnabled enabled, DGRecord record);
BOOL DGInstallLocalizedHook(NSDictionary *spec, DGEnabled enabled, DGRecord record,
                            NSDictionary<NSString *, NSString *> *translations);
NSDictionary *DGSearchAdapterSnapshot(void);
