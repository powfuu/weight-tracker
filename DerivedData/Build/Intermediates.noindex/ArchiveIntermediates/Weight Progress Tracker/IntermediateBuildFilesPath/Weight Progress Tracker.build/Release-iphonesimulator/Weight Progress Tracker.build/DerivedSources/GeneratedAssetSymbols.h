#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "weight_ico_transparent" asset catalog image resource.
static NSString * const ACImageNameWeightIcoTransparent AC_SWIFT_PRIVATE = @"weight_ico_transparent";

#undef AC_SWIFT_PRIVATE
