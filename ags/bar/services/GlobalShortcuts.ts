import GObject, { register, property } from "astal/gobject"
import { readFile } from "astal/file"
import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"

// The GlobalShortcuts interface XML can be found at https://github.com/flatpak/xdg-desktop-portal/blob/main/data/org.freedesktop.portal.GlobalShortcuts.xml
const SHORTCUT_INTERFACE_XML = readFile('./services/org.freedesktop.portal.GlobalShortcuts.xml');
const globalShortcutProxyWrapper = Gio.DBusProxy.makeProxyWrapper(SHORTCUT_INTERFACE_XML);

// interface GlobalShortcut {
//   id: string,
//   description?: string, // Make sure to wrap this in a GLib.Variant.new_string
//   preferred_trigger?: string, // Make sure to wrap this in a GLib.Variant.new_string
// }

function packShortcuts(shortcuts: GlobalShortcut[]): [string, Record<string, GLib.Variant>][] {
  return shortcuts.map(shortcut => {
    const packed: Record<string, GLib.Variant> = {};

    if (shortcut.description) {
      packed.description = GLib.Variant.new_string(shortcut.description);
    }

    if (shortcut.preferred_trigger) {
      packed.preferred_trigger = GLib.Variant.new_string(shortcut.preferred_trigger);
    }

    return [shortcut.id, packed];
  });
}

@register({ GTypeName: "Shortcut" })
export class GlobalShortcut extends GObject.Object {
  id: string
  description?: string
  preferred_trigger?: string

  #activated: boolean;

  @property(Boolean)
  get activated() {
    return this.#activated;
  }

  set activated(value) {
    this.#activated = value;
    this.notify("activated");
  }

  // constructor(shortcut: GlobalShortcut) {
  //   super()
  //
  //   this.id = shortcut.id;
  //   this.description = shortcut.description;
  //   this.preferred_trigger = shortcut.preferred_trigger;
  // }
  constructor(id: string, description?: string, preferred_trigger?: string) {
    super()
    this.id = id;
    this.description = description;
    this.preferred_trigger = preferred_trigger;
  }
}

export default class GlobalShortcuts {
  static instance: GlobalShortcuts;

  #shortcuts: GlobalShortcut[] = []
  #shortcutProxy: Gio.DBusProxy & {
    connectSignal: (x: unknown, y: unknown, ...other: unknown[]) => void
  }
  #sessionHandle: Promise<string>
  #sessionName: string

  async bindShortcuts(...shortcuts: GlobalShortcut[]) {
    this.#shortcuts.push(...shortcuts);
    this.#shortcutProxy.BindShortcutsSync(
      await this.#sessionHandle,
      [ // Top level array packer needed for DBus/GJS communication
        ...packShortcuts(shortcuts)
      ],
      '', // Hyprland doesn't have a shortcut registration popup for us to take advantage of, so we pass no window handle
      {
        handle_token: GLib.Variant.new_string(this.#sessionName),
      });
  }

  getShortcut(shortcut: string | GlobalShortcut): GlobalShortcut | undefined {
    const keyToMatch = typeof shortcut === "string" ? shortcut : shortcut.id;
    return this.#shortcuts.find(s => s.id === keyToMatch);
  }

  #createSession(sessionName?: string): Promise<string> {
    return new Promise((resolve, _) => {
      this.#shortcutProxy = globalShortcutProxyWrapper(
        Gio.DBus.session,
        'org.freedesktop.portal.Desktop',
        '/org/freedesktop/portal/desktop');

      let requestPath: string

      const requestSignalHandler = Gio.DBus.session.signal_subscribe(
        null,
        'org.freedesktop.portal.Request',
        'Response',
        null, // Normally, the requestPath would go here, but we have to subscribe before it's ever actually set.
        null,
        Gio.DBusSignalFlags.NONE,
        (_connection, _sender, path, _iface, _signal, params) => {
          if (path === requestPath) {
            try {
              const response = params.get_child_value(1).recursiveUnpack();
              Gio.DBus.session.signal_unsubscribe(requestSignalHandler);
              resolve(response.session_handle);
            } catch (e) { print(e); }
          }
        })

      requestPath = this.#shortcutProxy.CreateSessionSync({
        'handle_token': GLib.Variant.new_string(this.#sessionName),
        'session_handle_token': GLib.Variant.new_string(this.#sessionName)
      })[0];
    });
  }

  async init() {
    try {
      this.#sessionHandle = this.#createSession();
    }
    catch (e) {
      print(e);
    }

    let sessionHandle = await this.#sessionHandle

    this.#shortcutProxy.connectSignal('Activated', (_proxy, _nameOwner, args) => {
      const keyEvent = {
        session_handle: args[0],
        shortcut_id: args[1],
        timestamp: args[2],
        options: args[3],
      }
      if (keyEvent.session_handle == sessionHandle) {
        this.#shortcuts.find((shortcut) => shortcut.id == keyEvent.shortcut_id).activated = true;
      }
    });

    this.#shortcutProxy.connectSignal('Deactivated', (_proxy, _nameOwner, args) => {
      const keyEvent = {
        session_handle: args[0],
        shortcut_id: args[1],
        timestamp: args[2],
        options: args[3],
      }

      if (keyEvent.session_handle == sessionHandle) {
        this.#shortcuts.find((shortcut) => shortcut.id == keyEvent.shortcut_id).activated = false;
      }
    });
  }

  static get_session(sessionName?: string) {
    if (!this.instance) {
      this.instance = new GlobalShortcuts();
      this.instance.#sessionName = sessionName ?? 'astal';
      try {
        this.instance.init();
      }
      catch (e) { print(e) };
    }
    return this.instance;
  }
}
