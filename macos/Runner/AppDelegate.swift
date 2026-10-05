import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // With the windowing API, Flutter creates and manages all windows itself,
  // so we start a headless engine instead of using a storyboard window.
  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    engine = FlutterEngine(name: "project", project: nil)
    engine?.run(withEntrypoint: nil)
  }
}
