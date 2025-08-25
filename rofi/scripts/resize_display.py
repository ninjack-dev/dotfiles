#!/usr/bin/env python3

import os
import socket
import json
import math
import fractions
import bisect

from sys import argv
from typing import Dict, List, TypedDict, Union

import numpy

sock_path = os.path.join(
    os.environ["XDG_RUNTIME_DIR"],
    "hypr",
    os.environ["HYPRLAND_INSTANCE_SIGNATURE"],
    ".socket.sock",
)

class ActiveWorkspaceOrSpecialWorkspace:
    id: int
    name: str

class MonitorInfo(TypedDict):
    id: int
    name: str
    description: str
    make: str
    model: str
    serial: str
    width: int
    height: int
    refreshRate: float
    x: int
    y: int
    activeWorkspace: ActiveWorkspaceOrSpecialWorkspace
    specialWorkspace: ActiveWorkspaceOrSpecialWorkspace
    reserved: List[int]
    scale: str # Would be float, don't trust the cast though
    transform: int
    focused: bool
    dpmsStatus: bool
    vrr: bool
    solitary: str
    activelyTearing: bool
    directScanoutTo: str
    disabled: bool
    currentFormat: str
    mirrorOf: str
    availableModes: List[str]

def hyprctl(command: str):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(sock_path)
        client.sendall(command.encode("utf-8"))
        data = b""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            data += chunk
        return data.decode("utf-8")


def get_monitor_info() -> List[MonitorInfo]:
    raw = hyprctl("-j/monitors")
    parsed : List[MonitorInfo] = json.loads(raw)
    return parsed


def get_active_monitor() -> MonitorInfo:
    raw = hyprctl("-j/activeworkspace")
    parsed = json.loads(raw)

    return next(filter((lambda m: m["id"] == parsed["monitorID"]),get_monitor_info()))


def set_monitor_info(monitor_info: MonitorInfo):
    control_string = "keyword monitor {},{}x{}@{},{}x{},{},transform,{}".format(
        monitor_info["name"],
        monitor_info["width"],
        monitor_info["height"],
        monitor_info["refreshRate"],
        monitor_info["x"],
        monitor_info["y"],
        monitor_info["scale"],
        monitor_info["transform"]
    )
    hyprctl(control_string)

class RofiGlobalOptions(TypedDict, total=False):
    prompt: str          
    """Update the prompt text"""
    message: str         
    """Update the message text"""
    markup_rows: bool    
    """If true, renders markup in the row"""
    urgent: str          
    """Mark rows as urgent (see dmenu mode)"""
    active: str
    """Mark rows as active (see dmenu mode)"""
    delim: str           
    """Set delimiter for next rows (default '\n')"""
    no_custom: bool      
    """Only accept listed entries, no custom input"""
    use_hot_keys: bool   
    """Enable custom keybindings (breaks normal flow)"""
    keep_selection: bool 
    """Keep current selection after filtering"""
    keep_filter: bool    
    """Keep filter text after selection"""
    new_selection: int   
    """Absolute index of selected entry"""
    data: str            
    """Data passed via ROFI_DATA"""
    theme: str           
    """Theme snippet"""

class RofiRowOptions(TypedDict, total=False):
    icon: str
    """Set the icon for that row."""
    display: str
    """Replace the displayed string. (Original string will still be used for filtering)"""
    meta: str
    """Specify invisible search terms used for filtering."""
    nonselectable: bool
    """If true the row cannot activated."""
    permanent: bool
    """If true the row always shows, independent of filter."""
    info: str
    """Info that, on selection, gets placed in the ROFI_INFO environment variable. This entry does not get searched for filtering."""
    urgent: bool
    """Set urgent flag on entry (true/false)"""
    active: bool
    """Set active flag on entry (true/false)"""

def add_rofi_row(label: str, options: RofiRowOptions = {}):
    parts = []
    for key, value in options.items():
        parts.append(f"{key.replace("_", "-")}\x1f{value.__str__().lower()}")

    if parts:
        print(f"{label}\0" + "\x1f".join(parts))
    else:
        print(f"{label}")

def set_global_rofi_option(options: RofiGlobalOptions):
    option_pairs = []
    for key, value in options.items():
        if isinstance(value, bool):
            value_str = "true" if value else "false"
        else:
            value_str = str(value)
        option_pairs.append(f"\0{key.replace("_", "-")}\x1f{value_str}")
    print(*option_pairs, sep='\n', end=None)

def get_parent_executable_name():
    ppid = os.getppid()
    try:
        with open(f"/proc/{ppid}/comm", "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        return None

def is_scale_valid(gcd: int, scale: float | fractions.Fraction) -> bool:
  """Uses logic from Hyprland's `Monitor.cpp` to determine if a given scale is usable.
  https://github.com/hyprwm/Hyprland/blob/ced38b1b0f46f9fbdf9d37644d27bdbd2a29af1d/src/helpers/Monitor.cpp#L862"""
  scale_f32 = numpy.float32(scale)
  gcd_f64 = numpy.float64(gcd)
  logical_gcd = gcd_f64 / scale_f32

  if logical_gcd != logical_gcd.round():
    search_scale = round(scale_f32 * 120.0)
    scale_zero = search_scale / 120
    logical_zero = gcd_f64 / scale_zero
    return logical_zero == logical_zero.round()
  return True
    
monitor_info = get_active_monitor()

if len(argv) > 1:
    scale = os.environ["ROFI_INFO"]
    if not scale:
        exit(1)
    monitor_info["scale"] = scale
    set_monitor_info(monitor_info)

set_global_rofi_option(options={"no_custom": True, "prompt": "Set Display Scale"})
gcd = math.gcd(monitor_info["width"], monitor_info["height"])
scales: List[fractions.Fraction] = []

current_scale_str = str(monitor_info["scale"])

for denominator in range(3, 10):
    for numerator in range(0, denominator + 1):
        scale = fractions.Fraction(denominator + numerator, denominator)
        if scale not in scales and is_scale_valid(gcd, scale):
            bisect.insort(scales, scale)

for index, scale in enumerate(scales):
    options : RofiRowOptions = {"info": scale.__float__().__str__()}
    add_rofi_row("{:.0%}".format(scale), options)
    if current_scale_str == scale.__float__().__str__()[:4]: # Truncate to 4 characters (i.e. 1.33) for comparison, may be stupid, not sure if number can be bigger 
        # Consider padding with 0s on current_scale_str

        # This does not affect initial invocation. The only way to change the initial row, as far as I can tell,
        # is with the -selected-row parameter. The invocation time of this script is too long
        # to justify calling a second time to get that parameter, in my opinion.
        set_global_rofi_option({"keep_selection": True, "new_selection": index})

# This is WIP logic for moving monitors whose positions would be affected by this monitor being resized
# In this scenario, only the bottom and right edges are the ones we care about
# 1) Determine if monitor is:
#   a) Primary monitor, i.e. x, y = 0, 0. If it is, all displays to the bottom/right get moved
#   b) Up/left of primary monitor. If it is, move it and all monitors adjacent to it up/left
#   c) Down/right of primary monitor
#   d) In a configuration sans-primary monitor. If it is, resize all bottom/right monitors
# 2) Determine size delta, i.e. current_position - (current_dimensions - (current_dimensions * scale))
# 3) Apply size delta on a shared-side basis, i.e. if they share right or left edge, modify X position
#    Apply as needed for above scenarios:
#   a, c, d) Resize display, moving only bottom/right displays by delta
#   b) Resize display, move up/left by size delta, and move all up/left adjacent displays by size delta
# Right now, this logic implies a rather simple layout where displays do not share more one edge with two or more displays. 
# May need to rework in future.
type MonitorDirections = Dict[int, Dict[str, List[MonitorInfo]]]
def move_adjacent_monitors(modified_monitor: MonitorInfo, monitors: List[MonitorInfo], new_scale: float):
    directions: MonitorDirections = { m["id"]: { "left": [], "right": [], "down": [], "up": [] } for m in monitors }    
    def fill_monitor_dict(monitor: MonitorInfo, monitors: List[MonitorInfo], directions: MonitorDirections):
        for neighbor in monitors:
            if monitor["x"] + monitor["width"] / float(monitor["scale"]) == neighbor["x"]:
                directions[monitor["id"]]["left"].append(neighbor)
                directions[neighbor["id"]]["right"].append(neighbor)
                fill_monitor_dict(neighbor, monitors, directions)
            if monitor["y"] + monitor["height"] / float(monitor["scale"]) == neighbor["y"]:
                directions[monitor["id"]]["up"].append(neighbor)
                directions[neighbor["id"]]["down"].append(neighbor)
                fill_monitor_dict(neighbor, monitors, directions)
    fill_monitor_dict(modified_monitor, monitors, directions)

    primary_monitor_key = next(filter(lambda m: m["x"] == 0 and m["y"] == 0, monitors), modified_monitor)["id"]
    # TODO: See if following cases can be generically included in other checks
    # Case: No monitors left or upward from modified_monitor, we scale and shift upwards by delta
    if not directions[modified_monitor["id"]]["left"] \
        and not directions[modified_monitor["id"]]["up"] \
        and modified_monitor["id"] != primary_monitor_key:

        old_x = modified_monitor["x"]
        old_y = modified_monitor["y"]

        old_width = modified_monitor["width"]
        old_height = modified_monitor["height"]

        # This cast is technically not safe; however, we've already determined that it is by the time it gets called
        modified_monitor["height"] = int(modified_monitor["height"] * new_scale) 
        modified_monitor["width"] = int(modified_monitor["width"] * new_scale)

        x_delta = modified_monitor["width"] - old_width
        y_delta = modified_monitor["height"] - old_height

        modified_monitor["x"] += x_delta
        modified_monitor["y"] += y_delta


        print(f"Old X: {old_x}, new X: {modified_monitor["x"]}")
        print(f"Old Y: {old_y}, new Y: {modified_monitor["y"]}")

    # Case: No monitors right or downward from modified_monitor, we scale like normal

    # Start at "primary" monitor. Does not account for multiple displays in the same location. Might not need to
    # key = primary_monitor_key = next(filter(lambda m: m["x"] == 0 and m["y"] == 0, monitors), modified_monitor)["id"]
    # First check up and left
    # def check_up_left(monitor: MonitorInfo):
    #     while directions[key]["left"] != [] and directions[key]["up"] != []:
    #         if modified_monitor in directions[key]["left"] \
    #             or modified_monitor in directions[key]["up"]:
    #                 break
    #         check_up_left(directions[key]["left"])
    #         check_up_left(directions[key]["up"])
    #         key = 

    # visited_map = { m["id"]: False  for m in monitors}
    return directions

# print(find_shared_edges(get_monitor_info()[0], get_monitor_info(), 1.0)[get_monitor_info()[0]["id"]])
move_adjacent_monitors(get_active_monitor(), get_monitor_info(), 1.2)
