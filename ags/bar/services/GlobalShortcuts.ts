import GObject, { register } from "ags/gobject"
import { getter } from "ags/gobject"
import { readFile } from "ags/file"
import Gio from "gi://Gio"
import GLib from "gi://GLib?version=2.0"

// GlobalShortcuts Documentation: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.GlobalShortcuts.html
// Interface XML: https://github.com/flatpak/xdg-desktop-portal/blob/main/data/org.freedesktop.portal.GlobalShortcuts.xml
// TODO 
// - Truncate the XML file and pull it in as an inline string.
const SHORTCUT_INTERFACE_XML = readFile('./services/org.freedesktop.portal.GlobalShortcuts.xml');
const globalShortcutProxyWrapper = Gio.DBusProxy.makeProxyWrapper(SHORTCUT_INTERFACE_XML);

@register({ GTypeName: "Shortcut" })
export class GlobalShortcut extends GObject.Object {
  id: string
  description?: string
  preferred_trigger?: string

  #activated: boolean = false;

  @getter(Boolean)
  get activated() {
    return this.#activated;
  }

  /* TODO
   * - Limit accesss to the setter to the GlobalShortcuts singleton.
   */
  set activated(value) {
    this.#activated = value;
    this.notify("activated");
  }

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
  #shortcutProxy!: Gio.DBusProxy & {
    connectSignal: (x: unknown, y: unknown, ...other: unknown[]) => void
  };
  // #shortcutProxy!: Gio.DBusProxy;
  #sessionHandle!: Promise<string>;
  #sessionName!: string;

  /**
   * Bind one or more shortcuts asynchronously.
   * Note that for now, `await` should be used so that the shortcuts are pushed and bound before being accessed. 
   * Otherwise, `getShortcut()` will return `undefined`.
   *
   * @param shortcuts - One or more `GlobalShortcut`s
   */
  async bindShortcuts(...shortcuts: GlobalShortcut[]) {
    this.#shortcuts.push(...shortcuts);

    /* See https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Request.html#org-freedesktop-portal-request
     * In essence, to guarantee that the bind happened, we'll want to subscribe to the Request::Response signal and include tie the promise resolution to that. For now, it works perfectly, so I will ignore for now.
     */
    this.#shortcutProxy.BindShortcutsSync(
      await this.#sessionHandle,
      [ // Top level array packer needed for DBus/GJS communication
        ...shortcuts.map(shortcut => {
          const options: Record<string, GLib.Variant> = {};
          if (shortcut.description)
            options.description = GLib.Variant.new_string(shortcut.description);
          if (shortcut.preferred_trigger)
            options.preferred_trigger = GLib.Variant.new_string(shortcut.preferred_trigger);
          return [shortcut.id, options];
        })
      ],
      '', // Hyprland doesn't have a shortcut registration popup for us to take advantage of, so we pass no window handle
      {
        handle_token: GLib.Variant.new_string(this.#sessionName),
      });
  }

  /**
   *
   * @returns The GlobalShortcut or undefined if it hasn't been bound; make sure to call `bindShortcuts()` with `await`.
   * (See `bindShortcuts` implementation to see caveat)
   */
  getShortcut(shortcut: string | GlobalShortcut): GlobalShortcut | undefined {
    const keyToMatch = typeof shortcut === "string" ? shortcut : shortcut.id;
    return this.#shortcuts.find(s => s.id === keyToMatch);
  }

  #createSession(): Promise<string> {
    return new Promise((resolve, _) => { // Not using reject() for now since it hasn't failed before. I'm such a good programmer.
      this.#shortcutProxy = globalShortcutProxyWrapper(
        Gio.DBus.session,
        'org.freedesktop.portal.Desktop',
        '/org/freedesktop/portal/desktop'
      ) as Gio.DBusProxy & {
        connectSignal: (x: unknown, y: unknown, ...other: unknown[]) => void
      };

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
        });

      requestPath = this.#shortcutProxy.CreateSessionSync({
        'handle_token': GLib.Variant.new_string(this.#sessionName),
        'session_handle_token': GLib.Variant.new_string(this.#sessionName)
      })[0];
    });
  }

  // TODO
  // - Bring the activation signal logic into the CreateSession callback in an attempt to reduce the necessity for await.
  async #init() {
    try {
      this.#sessionHandle = this.#createSession();
    }
    catch (e) {
      print(e);
    }

    let sessionHandle = await this.#sessionHandle

    this.#shortcutProxy.connectSignal(this.#shortcutProxy, 'Activated', (_proxy: any, _nameOwner: any, args: any) => {
      const keyEvent = {
        session_handle: args[0],
        shortcut_id: args[1],
        timestamp: args[2],
        options: args[3],
      }
      if (keyEvent.session_handle == sessionHandle) {
        this.#shortcuts.find((shortcut) => shortcut.id == keyEvent.shortcut_id)!.activated = true;
      }
    });

    this.#shortcutProxy.connectSignal('Deactivated', (_proxy: any, _nameOwner: any, args: any) => {
      const keyEvent = {
        session_handle: args[0],
        shortcut_id: args[1],
        timestamp: args[2],
        options: args[3],
      }

      if (keyEvent.session_handle == sessionHandle) {
        this.#shortcuts.find((shortcut) => shortcut.id == keyEvent.shortcut_id)!.activated = false;
      }
    });
  }

  /**
   * Returns the singleton instance of the `GlobalShortcuts` session.
   *
   * If the singleton instance does not already exist, the first invocation of this method initializes it.
   * The optional `sessionName` parameter is used as the D-Bus session name for the new instance.
   * If no name is provided, `'astal'` is used as the default.
   *
   * @param sessionName - Optional string to specify the session name used for D-Bus registration.
   * @returns The instance of `GlobalShortcuts`.
   */
  static get_session(sessionName?: string) {
    if (!this.instance) {
      this.instance = new GlobalShortcuts();
      this.instance.#sessionName = sessionName ?? 'astal';
      try {
        this.instance.#init();
      }
      catch (e) { print(e) };
    }
    return this.instance;
  }
}
