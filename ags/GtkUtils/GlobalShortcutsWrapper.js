import Gio from "gi://Gio"
import GLib from "gi://GLib"

function readXmlFile(filePath) {
  try {
    // Create a Gio.File instance for the file path
    let file = Gio.File.new_for_path(filePath);

    // Read the contents of the file
    let [success, contents, etag] = file.load_contents(null);

    if (success) {
      // Convert the contents (a GLib.Bytes) to a string
      let xmlString = imports.byteArray.toString(contents);
      return xmlString;
    } else {
      throw new Error("Failed to read the file contents.");
    }
  } catch (e) {
    logError(e, "Error reading XML file");
    return null;
  }
}

const SHORTCUT_INTERFACE_XML = readXmlFile('./org.freedesktop.portal.GlobalShortcuts.xml')

const globalShortcutProxyWrapper = Gio.DBusProxy.makeProxyWrapper(SHORTCUT_INTERFACE_XML);

let shortcutProxy
try {
  shortcutProxy = globalShortcutProxyWrapper(
    Gio.DBus.session, 
    'org.freedesktop.portal.Desktop', 
    '/org/freedesktop/portal/desktop');
} catch (e) { console.log(e) }

const sessionValues = new GLib.Variant('(a{sv})', [{
  handle_token: GLib.Variant.new_string('Astal'),
  session_handle_token: GLib.Variant.new_string('Astal1'),
}]);

//for (let method in shortcutProxy) {
//    print(method);
//}

//try {
//  // Use the async version first to see if there's a difference
//  let a = await shortcutProxy.CreateSessionAsync(sessionValues, (proxy, result) => {
//    try {
//      let response = proxy.call_finish(result);
//      console.log('Session created successfully:', response);
//    } catch (e) {
//      console.log('Error creating session:', e);
//    }
//  });
//} catch (e) {
//  console.log('Error in CreateSession call:', e);
//}

for (let method in sessionValues) { console.log(method); }

let a
try {
  a = shortcutProxy.CreateSessionSync(sessionValues.get_byte());
} catch (e) { console.log(e); }
console.log(a)
