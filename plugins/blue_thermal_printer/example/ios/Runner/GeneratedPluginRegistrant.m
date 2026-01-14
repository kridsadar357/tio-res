//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<blue_thermal_printer/BlueThermalPrinterPlugin.h>)
#import <blue_thermal_printer/BlueThermalPrinterPlugin.h>
#else
@import blue_thermal_printer;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [BlueThermalPrinterPlugin registerWithRegistrar:[registry registrarForPlugin:@"BlueThermalPrinterPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
}

@end
