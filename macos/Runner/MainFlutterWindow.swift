import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Set static 10.1 inch tablet size (typical 1280x800)
    let targetSize = NSSize(width: 1280, height: 800)
    self.setContentSize(targetSize)
    
    // Lock the window size
    let frameSize = self.frame.size
    self.minSize = frameSize
    self.maxSize = frameSize
    
    // Center window
    self.center()

    super.awakeFromNib()
  }
}
