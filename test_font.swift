import Cocoa
import CoreText

let fontURL = URL(fileURLWithPath: "/Users/princepalestine/Desktop/ImanTrack/ImanTrack/ImanTrack/Fonts/uthmanic-shuba-v20.ttf")
var error: Unmanaged<CFError>?
if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
    let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
    for descriptor in fontDescriptors {
        let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as! String
        let family = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as! String
        print("PostScript Name: \(name)")
        print("Family Name: \(family)")
    }
} else {
    print("Failed to register font: \(error!.takeRetainedValue())")
}
