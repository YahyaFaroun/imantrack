#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "sujud_icon" asset catalog image resource.
static NSString * const ACImageNameSujudIcon AC_SWIFT_PRIVATE = @"sujud_icon";

#undef AC_SWIFT_PRIVATE
