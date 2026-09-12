# Fix wine/yabridge floating menus in sway, drop TTY2 openbox

## Context

REAPER + yabridge-hosted Windows VST/CLAP plugins work fine under sway except for
one bug: some plugin popup/hover menus render in the wrong place (or don't work)
under Wayland. This is why TTY2 still runs a plain Xorg + Openbox + tint2 session
(started via `startx`/`.xinitrc`, packages from pacman, see
`/home/magnus/.scripts/postinstall/1_system.sh`) as a fallback for serious plugin
work, alongside sway on TTY1 for everything else.

Git history (see `896c9256`, `4adf750e`, `dd04fdb7`, `79adbb7b`) shows two earlier
attempts at fixing this without a second X session, both abandoned:

- **Xephyr + Openbox** — rejected before real use: Xephyr has no GL/Vulkan
  passthrough, and software Vulkan (Lavapipe) under it crashed at least one plugin
  outright.
- **xpra desktop + nested Openbox + software Vulkan** (`start-reaper-xpra.sh`) —
  worked (fixed the menu bug and Vulkan), but was dropped after 3 days for
  noticeable GUI latency/CPU overhead from xpra's remoting protocol plus running
  everything through software Vulkan.
- Wine's built-in **virtual desktop** mode was only ever mentioned in a README
  note ("fixed when enabling wine virtual desktop") — it was never actually
  implemented as a registry setting anywhere in history. This is the one avenue
  not yet properly tried.
- A plain sway `for_window ... floating enable` rule on
  `yabridge-host.exe.so` was also tried directly (`c79ad56b`) and explicitly
  marked as not fixing the focus/menu bug.

The likely root cause of misplaced popups is a known class of bug where
override-redirect X11 popup windows (context menus, dropdowns) from wine apps get
mispositioned by Xwayland/wlroots' coordinate translation under a Wayland
compositor. Wine's virtual desktop mode sidesteps this entirely: it makes wine
manage all of its own window positioning internally (as one single embedded X11
surface), so popups never depend on the compositor's XWayland translation at all.
The user recalls that virtual desktop menus previously appeared far from the
owning window — consistent with the desktop-container window not being pinned to
an exact, undecorated, non-scaled geometry by the WM (any size/position mismatch
between wine's internal virtual screen and the real on-screen window breaks its
offset math).

Since `/home/magnus/.wine-audio` (the WINEPREFIX yabridge bridges plugins into) is
*only* ever used for yabridge-hosted plugin processes — never anything else —
enabling virtual desktop mode prefix-wide already gives "plugins only" scoping for
free, no per-plugin machinery needed.

`REAPER`'s own GUI (SWELL, X11-only) and wine itself (X11-only build in nixpkgs)
already run through XWayland today regardless of anything we do — there is no
Wayland-native code path for either to opt out of, so "force XWayland for REAPER"
is expected to be a no-op. Confirm this cheaply before ruling it out for good.

Nested-compositor approaches (retrying Xephyr/xpra with hardware GPU passthrough
via VirtualGL instead of software Vulkan) are being held off for now — Xephyr/xpra's
virtual framebuffers generally lack the DRI3/Present support needed for real
hardware-accelerated Vulkan surfaces, so success there is unverified and would need
its own live experimentation. Revisit only if the virtual desktop route below
doesn't fully fix things.

## Approach

### Step 1 — Diagnostic (no config change, do this first live)

Confirm REAPER/yabridge plugin windows are already XWayland clients, to close off
the "force xwayland" avenue with evidence rather than assumption:

```sh
swaymsg -t get_tree | grep -B5 '"shell": "xwayland"' | grep -i -E 'name|app_id|class'
```

Windows with `class = "REAPER"` / `class = "yabridge-host.exe.so"` should show up
under `"shell": "xwayland"` nodes already. If confirmed, no further action needed
on that avenue.

### Step 2 — Enable wine virtual desktop for the audio wineprefix

Edit `home.file."Shared/Audio/win-plugins/custom.reg".text` in
`/home/magnus/flake.nix` (~line 2071) to add:

```reg
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="<WIDTH>x<HEIGHT>"
```

`custom.reg` is already applied on every `home-manager switch` via
`wine regedit "$winplugins/custom.reg"` inside the existing
`home.activation.audioWinePrefix` script (`flake.nix` ~line 755) — no new
activation logic needed. Get `<WIDTH>x<HEIGHT>` from the real output resolution
via `swaymsg -t get_outputs` at implementation time (match it exactly — a mismatch
between the wine virtual screen size and its container window's real size is the
likely cause of the old "menu appears far away" bug).

### Step 3 — Pin the virtual-desktop container window's geometry in sway

Once virtual desktop mode is on, the yabridge/wine windows stop being individual
X11 top-levels and become children of a single wine "desktop" container window
(class typically `explorer.exe`, confirm via `swaymsg -t get_tree` after Step 2).
Add a `window.commands` entry for it in the `wayland.windowManager.sway.config`
block (`flake.nix` ~line 1351, alongside the existing `REAPER` /
`yabridge-host.exe.so` rules):

```nix
{
  criteria.class = "explorer.exe"; # confirm actual class/title first
  command = "border none, floating disable, fullscreen enable";
}
```

Goal: no borders, no gaps, no floating/resize interference — an exact 1:1
pixel-for-pixel container so wine's internal absolute-coordinate popup placement
matches reality. Adjust criteria/command once the real window identity is known
from live testing. The existing `REAPER` window rule (top-level app window,
unaffected by virtual desktop mode) stays as-is.

### Step 4 — Live verification

After `home-manager switch`:
1. Launch REAPER, load a plugin known to have the broken hover/context menu.
2. Confirm the wine desktop container window is fullscreen/borderless per Step 3.
3. Open the previously-broken menu and confirm it renders in the correct position
   and is clickable.
4. Spot-check a handful of other plugins (not just one) for regressions — virtual
   desktop mode is being enabled prefix-wide, so anything relying on real-screen
   coordinates (e.g. multi-monitor-aware plugin UIs) could behave differently now.
5. Check for any change in GUI responsiveness/latency (virtual desktop mode adds
   an internal compositing step even without xpra's network protocol overhead).

### Step 5 — Only after Step 4 passes for real workloads

Keep the TTY2 openbox/Xorg/tint2 fallback in place until virtual desktop mode has
been used for actual production sessions across the plugin catalog, not just a
quick test. Removing TTY2 (`.xinitrc`, `~/.config/openbox/*`, `~/.config/tint2/*`,
the pacman `xorg-server`/`xorg-xinit`/`openbox`/`tint2` block in
`postinstall/1_system.sh`, and the TTY2 branch in `programs.bash.profileExtra`,
`flake.nix` ~line 912) is a separate follow-up, not part of this change.

## Rollback

Everything here is additive and reversible: delete the two registry keys from
`custom.reg` (they won't be reapplied and existing HKCU values can be cleared with
`wine regedit /d` or simply by keys not being reset — since this only edits HKCU
registry state, worst case is deleting `~/.wine-audio` and letting activation
recreate it), and remove the new `window.commands` entry from the sway config.
No packages, services, or the TTY2 fallback are touched.

## Result: virtual desktop mode ruled out (2026-09-07)

Implemented Steps 1-4 live. Findings:

- **Step 1 diagnostic was skipped** (not re-run before proceeding — should have
  been done first per the plan, but the outcome below makes it moot).
- **Step 2/3 config applied and confirmed correctly wired**: `custom.reg` set
  `HKCU\Software\Wine\Explorer\Desktop=Default` at `1920x1080` (matching the real
  output resolution), and the sway `window.commands` rule matched
  `class = "explorer.exe"` correctly — confirmed via
  `swaymsg -t get_tree` showing `fullscreen_mode: 1` on the `explorer.exe` node,
  output `eDP-1`. The geometry pin was not the problem.
- **Live test result — still broken, and for a different reason than
  anticipated**: enabling virtual desktop mode spawns a separate, visible blue
  "wine desktop" window (`explorer.exe`). The plugin's actual GUI stays exactly
  where it was before (its own independent sway window) — it does **not** move
  into the virtual desktop surface. When a plugin's context/hover menu is opened,
  it renders *inside the blue explorer.exe window*, disconnected from the visible
  plugin window's position — unusable, same practical failure as before, just
  relocated to a different (also wrong) window.
- **Root cause**: yabridge doesn't run the plugin GUI as a wine top-level managed
  by wine's own desktop/window manager — it XEmbeds the plugin's HWND directly
  into REAPER's process as a real Xwayland top-level (reparented into REAPER's
  window). That path never touches wine's internal virtual-desktop coordinate
  space at all. But native Win32 popups (`TrackPopupMenu` etc.) are positioned by
  USER32 relative to whatever screen wine *thinks* it owns — which, once virtual
  desktop mode is on, is the internal virtual screen represented by the
  `explorer.exe` window, not the real display. Two disjoint coordinate spaces:
  one for the plugin's visible GUI (real XWayland geometry), one for its popups
  (wine's internal virtual screen). No sway rule can reconcile that — it isn't a
  geometry/pinning problem, it's an architectural mismatch between yabridge's
  XEmbed model and wine's virtual-desktop model. **This avenue is closed.**
- Config fully rolled back (see git diff / `Stash virtual desktop` commit on this
  branch, which this session's working-tree changes revert).

**Next**: per the "Nested-compositor approaches" note above, the remaining
untried avenue is retrying Xephyr or xpra with hardware GPU passthrough via
VirtualGL instead of software Vulkan — previously the xpra attempt worked
functionally (fixed the menu bug) but was dropped for latency/CPU overhead from
xpra's remoting protocol *and* software Vulkan; VirtualGL would remove the
software-Vulkan half of that cost, and is worth a fresh, focused try before
resigning to keeping the TTY2 Xorg/Openbox fallback indefinitely.

## Research: xpra + VirtualGL ruled out too (2026-09-07)

Before implementing, researched whether VirtualGL actually fixes the Vulkan half
of the old xpra overhead. It doesn't, and there's no drop-in substitute:

- **VirtualGL has no Vulkan support at all** — only intercepts GLX/OpenGL.
  [virtualgl/virtualgl#37](https://github.com/VirtualGL/virtualgl/issues/37)
  ("Investigate the need for a VirtualVulkan interposer") is open/unresolved as
  of the 3.1.4 release.
- **xpra's virtual display (Xvfb/Xdummy-based) has no DRI3** by default, so
  hardware Vulkan surfaces can't be created on it regardless of VirtualGL —
  confirmed by multiple users hitting "vulkan: no DRI3 support detected" on
  xpra virtual displays. This is *why* the original script used Lavapipe.
- `xpra --use-display` (attach to the real sway/XWayland display instead of a
  virtual one) would have real DRI3, but that's just re-exposing the exact
  XWayland popup bug this whole effort exists to avoid.
- The one credible real-world precedent for hardware-accelerated Vulkan in a
  headless/virtual setup is **KasmVNC**, which uses **VKMS or EVDI** (kernel
  virtual display connectors) so a *real* Xorg with the *real* GPU driver
  (`amdgpu`, not `dummy`) thinks it's driving an actual monitor — the same
  "PRIME render offload" split used for hybrid-graphics (Optimus) laptops.

Followed up researching that VKMS/PRIME path directly against this machine's
hardware (AMD Vega/Cezanne APU, single GPU, `amdgpu`, real output `eDP-1`):

- **Simpler mechanism exists than VKMS**: `amdgpu` has a native
  `amdgpu.virtual_display=<PCI addr>,<num_crtcs>` kernel parameter that adds
  extra GPU-accelerated virtual CRTCs directly on the *real* GPU — no fake KMS
  device, no PRIME split needed (single-GPU machine). A second Xorg bound to
  that `Virtual-1` output would get the native amdgpu driver with full
  DRI3/GLX/RADV Vulkan. Confirmed via
  [kernel docs](https://docs.kernel.org/gpu/amdgpu/module-parameters.html) and
  an [Arch forum thread](https://bbs.archlinux.org/viewtopic.php?id=297503); a
  [blog writeup](https://simonredman.wordpress.com/2026/02/04/fully-headless-linux-gaming-vm-with-amdgpu/)
  confirms the param works in practice, though that setup drove the virtual
  output with Sway/Wayland, not X11, so it doesn't confirm the X11 half.
  Requires `boot.kernelParams = [ "amdgpu.virtual_display=0000:05:00.0,1" ]`
  (this machine's PCI address) and a reboot — not runtime-toggleable.
- **Unresolved blocker: concurrent DRM master.** Linux DRM allows only one
  master per `/dev/dri/cardN` at a time. Sway already holds master for
  `eDP-1`. A second Xorg opening the same device for `Virtual-1` would need
  either a VT switch (logind arbitrates master handoff — which is *exactly*
  what TTY2 already does today, on the real output) or DRM leasing
  (`drmModeCreateLease`), which is documented almost exclusively for
  VR-headset-to-compositor use
  ([wlroots#1723](https://github.com/swaywm/wlroots/issues/1723)), not
  compositor-to-second-Xorg. **No precedent found for running a second Xorg
  concurrently with sway on the same GPU without a VT switch.**

**Conclusion**: if this route also needs a VT switch to get DRM master
(likely, per the above), it doesn't actually improve on TTY2 — TTY2's plain
Xorg already gets full native hardware Vulkan on the real `eDP-1` output
today, at zero extra complexity, precisely *because* it VT-switches away from
sway to get master. The only way `amdgpu.virtual_display` + a second Xorg
would be worth the added complexity (kernel param + reboot + custom Xorg
config + xpra capture) is if it turns out DRM leasing *can* avoid the VT
switch — which is unverified and can only be resolved by live testing, with
real risk (a failed DRM master grab can hang or crash the graphical session,
needing a hard reset). Not attempted yet — decision pending on whether that
risk is worth taking versus accepting TTY2 as the permanent answer.

## Re-check with 2026-current versions (2026-09-09): still no Wayland-native fix

Revisited after upgrading to wine 11.16 and yabridge git (built from latest
master, not a tagged release) — bug still reproduces on current sway.
Researched whether anything moved upstream since the sessions above. It
hasn't; TTY2 Xorg remains correct. Three fronts checked:

- **Xwayland/wlroots override-redirect popup coordinate bug — still open,
  not sway-specific.** The exact symptom (yabridge/REAPER VST menus
  rendering centered instead of positioned as popups) is independently
  reported in late 2025 against `xwayland-satellite`, the newer rootless-
  Xwayland integration also used by Hyprland
  ([Supreeeme/xwayland-satellite#293](https://github.com/Supreeeme/xwayland-satellite/issues/293),
  open/unresolved, plus related #306, #326). This confirms it's a
  structural mismatch between how wine/yabridge position override-redirect
  popups and how *any* current Wayland↔X11 bridge translates coordinates —
  not sway/wlroots plumbing that a version bump would fix.
- **winewayland.drv (wine's native Wayland driver) — matured, but
  architecturally irrelevant.** Real progress recently (fractional scaling
  merged before 11.12, DMA-BUF child-window rendering, per-process driver
  selection via `WINE_GRAPHICS_DRIVER`). Doesn't help here: yabridge embeds
  plugin GUIs via **XEmbed**, which is inherently X11-only (a real X11
  window ID reparented into REAPER's X11 window) — switching wine's display
  driver away from X11 wouldn't change that embedding mechanism at all, and
  there is no Wayland equivalent of XEmbed for yabridge to move to. Notably,
  winewayland.drv's own native tray-icon context menus hit the identical
  "can't anchor popup to effective parent across process boundaries"
  failure mode natively — same bug class, no Xwayland even involved.
- **yabridge itself — explicitly no Wayland plan.**
  [robbert-vdh/yabridge#459](https://github.com/robbert-vdh/yabridge/issues/459)
  (Nov 2025): user asks about Wayland viability as GNOME/KDE deprecate X11;
  maintainer response is "yabridge can't provide Wayland support because of
  missing features." No roadmap, no workaround, no activity since.

**Conclusion**: this isn't a "not upgraded yet" situation — none of the
three components involved (Xwayland's popup coordinate translation, wine's
Wayland driver, yabridge's XEmbed-based embedding model) has moved in a
direction that fixes it, and yabridge has ruled out being the one to fix it.
TTY2 Xorg/Openbox/tint2 stays the permanent answer. Revisit only if yabridge
ever adopts a non-XEmbed plugin-window embedding path, or if a general fix
for override-redirect popup coordinate translation lands in Xwayland/wlroots
upstream (watch the xwayland-satellite issues above for movement).

## Correction (2026-09-09): a real fix exists — xwayland-satellite, not sway's built-in XWayland

Follow-up research compiling every upstream issue tracking this bug class
(wine, wlroots, sway, Xwayland, yabridge, and related compositors/toolkits)
turned up a fix that **overturns the "no viable fix" conclusion above**.

**The exact bug has a shipped fix, just not where we were looking.**
[`Supreeeme/xwayland-satellite`](https://github.com/Supreeeme/xwayland-satellite)
is a standalone rootless-Xwayland implementation usable as a drop-in
replacement for a compositor's built-in XWayland integration (only needs
`xdg_wm_base` + `wp_viewporter`, which sway already provides).
[Issue #293](https://github.com/Supreeeme/xwayland-satellite/issues/293)
("REAPER + Yabridge + VST menus dont show as popups", opened 2025-12-02) is
this exact bug, root-caused by the maintainer to ICCCM giving no reliable way
to distinguish popup vs. toplevel override-redirect windows — same
diagnosis as the yabridge-XEmbed analysis above, but on the compositor's
XWayland-integration side rather than yabridge's side. **Fixed in v0.8.1
(released 2026-02-17)** by detecting `_NET_WM_STATE_SKIP_TASKBAR` +
`_NET_WM_STATE_ABOVE` together to identify true popups. One residual edge
case remains open in
[#326](https://github.com/Supreeeme/xwayland-satellite/issues/326):
JUCE-framework menus with drop-shadow child windows can still arrive in the
wrong stacking order (partially addressed in v0.8.2, 2026-07-22, not fully
closed).

Corroborating evidence this is a general Wayland-ecosystem architecture gap
(not sway-specific), and that this specific fix approach works elsewhere:

- **sway's own built-in XWayland integration** has a related but distinct
  fix history: [#6324](https://github.com/swaywm/sway/issues/6324) (the 2022
  REAPER dropdown fix already referenced above) and
  [#7608](https://github.com/swaywm/sway/issues/7608) ("stacking order wrong
  for override redirect windows", closed 2026-06-03 via wlroots MR
  [`!4052`](https://gitlab.freedesktop.org/wlroots/wlroots/-/merge_requests/4052)).
  Neither of these fully closed the yabridge/REAPER menu bug in sway's own
  XWayland path — hence why it still reproduced on current sway/wine
  11.16/yabridge git.
- **Hyprland** (an independent wlroots-based compositor) has the identical
  REAPER symptom reported against its own built-in XWayland handling
  ([#7157](https://github.com/hyprwm/Hyprland/issues/7157), closed
  not_planned; [#6921](https://github.com/hyprwm/Hyprland/issues/6921) /
  [discussion #6896](https://github.com/hyprwm/Hyprland/discussions/6896)),
  and a user in
  [discussion #9993](https://github.com/hyprwm/Hyprland/discussions/9993)
  reports switching to xwayland-satellite as the working fix there too.
- **KDE/KWin** confirms the architectural root cause independently:
  [bug 454358](https://bugs.kde.org/show_bug.cgi?id=454358) was resolved
  **INTENTIONAL**, with a KWin developer stating XWayland override-redirect
  popups carry insufficient ICCCM metadata to stay reliably attached to a
  moving/reparenting parent — this is a structural gap in every
  compositor's built-in XWayland integration, not an oversight specific to
  sway/wlroots.

**Revised next step**: try running `xwayland-satellite` in place of sway's
built-in XWayland for the audio/REAPER session (sway supports this — it
just needs the compositor to expose `xdg_wm_base` + `wp_viewporter` and for
sway to be told to use the external XWayland instance rather than spawning
its own). This is a genuinely new, previously-untried avenue — distinct from
every approach ruled out earlier in this document (virtual desktop, Xephyr,
xpra, amdgpu.virtual_display) since it fixes the actual root cause in the
XWayland-integration layer rather than working around it. Live-test needed
before declaring success: confirm nixpkgs packages `xwayland-satellite`,
confirm sway config wiring to use it, confirm v0.8.1+ (or whatever is
current) is what's packaged, and repeat the Step 4 live-verification
checklist from the original plan above (multiple plugins, not just one;
check for regressions/latency). Keep TTY2 in place until this has been
proven on real production sessions.

## Implementation (2026-09-09): xwayland-satellite wired in, menu bug fixed, new Vulkan regression found

Implemented and live-tested the xwayland-satellite avenue from the
correction above. Two commits on `master`:

- `ee28e82` - `reaperNoNet`'s wrapper (`nix/audio/flake.nix`, the
  `reaper` launcher installed via `home.packages`) now starts a private
  `xwayland-satellite` instance on a free X display
  (`find_free_display`, probing `/tmp/.X11-unix/X$n`) before exec'ing
  REAPER, exports `DISPLAY` to that display for REAPER's process tree
  only, and kills the satellite process on exit (`trap ... EXIT`).
  Scopes the fix to REAPER/yabridge - every other sway app keeps using
  sway's own built-in XWayland untouched. `xwayland-satellite` also
  added to `home.packages` directly for manual debugging.
- `059ea66` - pinned `xwayland-satellite` to 0.8.1 instead of nixpkgs'
  0.8.2, overriding both `src` and `cargoDeps` (plain `cargoHash`
  override doesn't propagate through `buildRustPackage`'s
  `overrideAttrs` - the vendor derivation stays bound to the
  *original* `finalAttrs.cargoHash*; had to override `cargoDeps`
  directly via a fresh `rustPlatform.fetchCargoVendor` call). Hashes
  taken from nixpkgs' own pre-bump commit (`84702aa153`). Turned out to
  be insufficient by itself (see below) but is still correct to keep,
  since 0.8.2 has its own confirmed-separate regression
  ([#468](https://github.com/Supreeeme/xwayland-satellite/issues/468)).

**Live result, mixed**:

- **Menu-positioning bug: confirmed fixed.** This was the original
  goal and it works. Win32 popup/context menus (`TrackPopupMenu` etc.)
  are override-redirect windows parented directly to the X11 root, a
  code path xwayland-satellite handles correctly (this is exactly the
  upstream fix in
  [#293](https://github.com/Supreeeme/xwayland-satellite/issues/293)
  discussed above) - independent of the new regression below.
- **New regression found**: Vulkan/DXVK-rendered plugin GUIs (e.g.
  Xfer OTT) render as a solid black window. Most plugins (GDI/Direct2D
  software-rendered ones) work correctly - this is specific to
  hardware-accelerated (DRI3/Present/dmabuf) rendering, not a general
  XEmbed/reparenting problem as first suspected.
- Pinning to 0.8.1 (commit `059ea66` above) did **not** fix this -
  confirmed live, ruling out the 0.8.2-specific popup regression
  (#468) as the cause. The bug is present in both 0.8.1 and 0.8.2.

### Root cause: xwayland-satellite has no concept of a Wayland subsurface

Confirmed via cross-referencing wine's actual source with satellite's
actual source (present on satellite's `main` branch too, not
version-specific):

- Wine's X11 driver (`dlls/winex11.drv/window.c`,
  `create_client_window`/`attach_client_window`) creates a **separate,
  nested child window** - the "client window" - as a child of the
  app's real embedded HWND, specifically to host GPU rendering
  surfaces. This backs both OpenGL and Vulkan -
  `winex11.drv/vulkan.c`'s `X11DRV_vulkan_surface_create` points
  `VkXlibSurfaceCreateInfoKHR.window` at exactly this `client_window`.
  GDI/Direct2D content paints directly onto the real embedded HWND
  instead - a window xwayland-satellite already tracks and composites
  fine, which is why most plugins work.
- xwayland-satellite's Wayland-surface architecture
  (`src/server/dispatch.rs`) only ever creates two kinds of tracked,
  independently-composited surfaces: `xdg_toplevel` or `xdg_popup`,
  assigned via the `xwayland_surface_v1` protocol's serial-based
  association (`SetSerial` handler). There is **no subsurface / "child
  of another tracked surface" role anywhere in the codebase**
  (`create_role_window` only ever picks Popup or Toplevel). Wine's
  nested Vulkan `client_window` - a plain child window one level
  deeper than the already-tracked embedded HWND, never itself a
  root-level top-level - never gets an `xwayland_surface_v1`
  association and thus never gets a Wayland surface at all. Its
  Present/DRI3/dmabuf buffer commits have nowhere to go: the window
  exists, resizes, and takes input, but never gets composited. Real
  Xwayland-integrated compositors (sway's built-in one) handle this
  generically via the X Composite extension's recursive subwindow
  redirection; xwayland-satellite's from-scratch reimplementation
  doesn't replicate that.
- An earlier theory (that satellite's `ReparentNotify` handler in
  `src/xstate/mod.rs` destroys tracking for *any* window reparented to
  a non-root parent, i.e. any XEmbed at all) was investigated and
  ruled out by live testing - it predicted ALL yabridge plugin GUIs
  would go black regardless of rendering backend, which is false (most
  work fine). That handler only strips window metadata for the
  reparented window itself, not the wl_surface already linked to the
  embedded HWND one level up - irrelevant to this bug.
- **Independent corroboration**: satellite issue
  [#225](https://github.com/Supreeeme/xwayland-satellite/issues/225)
  (open, duplicate of
  [#150](https://github.com/Supreeeme/xwayland-satellite/issues/150))
  is the same bug class - Chromium/CEF's GPU-accelerated compositing
  (also child-window-based) breaks identically under satellite.
  Workarounds there are all "disable GPU acceleration for that
  content" (`-system-composer` etc.), never a satellite-side fix.
  Upstream has not connected this to wine/DXVK specifically as of this
  writing, and there is no open PR touching subsurface/child-window
  support.
- Switching DXVK to a software Vulkan ICD (lavapipe) would **not**
  help either - the Vulkan surface still targets the same untracked
  `client_window` regardless of which physical device renders it; the
  break happens before any pixel is produced.

**Fix feasibility**: not a small patch. It requires satellite to gain
a new capability - treating certain child windows as `wl_subsurface`s
of their parent's already-tracked surface - touching window
classification (`ReparentNotify`/`CreateNotify` in `xstate/mod.rs`),
role assignment (`create_role_window`), and the compositor-protocol
surface bundle (`event.rs`'s `SurfaceBundle`). Core-architecture work,
not a config tweak or env var; too risky/time-consuming to
self-maintain as a patch without deep prior familiarity with the
codebase and XCB/Wayland protocol internals.

**Current state / next steps** (superseded by the resolution below -
kept for the historical trail): a detailed upstream issue report was
drafted (citing #225/#150 as the same underlying gap) but never filed,
since the bug was fixed upstream before filing became necessary. See
below.

## Resolved (2026-09-09): both bugs fixed by tracking xwayland-satellite's post-0.8.2 main branch

Commit `1984ae8` moved `xwaylandSatelliteStable`
(`nix/audio/flake.nix`) from the 0.8.1 pin to a specific unreleased
commit past 0.8.2 -
[`add2795`](https://github.com/Supreeeme/xwayland-satellite/commit/add2795134593faafce60e404a0a75df68e9ee0c)
("fix: never focus override-redirect popups; offer WM_TAKE_FOCUS when
advertised", fixing upstream issues #468 and #278) - after it landed
on upstream `main`. This pulls in every commit between the `v0.8.2`
tag and that one, not just the tip commit itself:

```
3bc915f09 server: track global scale to initialize new surfaces correctly
48f136d91 tests: assert new X window scales at creation
3b9b294f3 fix: use saturating add in min/max height calcs
d1e22091e fix: don't shrink windows with CSDs on 0-height configure
6d0de1ced re: merge size hint setters into function
17d4e805d feat: send logs to syslog when integrated
f3487d14d feat: write panic location/reason to syslog
896a3e92f docs: restructure README, be more verbose in issue template
78e4e01ea Drop the parent's copy of the Xwayland WM socket
ea474b95a fix: manpage missing paragraph for -help
7f848f502 fix: classify resizable DIALOG windows as toplevel, not popup
324ef5d18 feat: sync Xft.dpi through RESOURCE_MANAGER (#477)
add279513 fix: never focus override-redirect popups; offer WM_TAKE_FOCUS when advertised (#494)
```

**Live result: both bugs confirmed fixed.** The original menu-position
bug stayed fixed (expected - unrelated to this range), and
**the Vulkan/DXVK black-window regression is also gone** - confirmed
live with OTT and other previously-black plugins.

This directly contradicts the root-cause analysis two sections above
(the "no subsurface role in xwayland-satellite's surface model" theory
for the Vulkan bug), which predicted none of the commits in this range
would fix it, since none of them touch `create_role_window` or add a
subsurface role to the codebase. That analysis was either wrong, or
incomplete in a way not yet understood - most likely candidates in the
range above, unconfirmed:

- `3bc915f09` ("track global scale to initialize new surfaces
  correctly") - touches new-surface initialization directly, plausible
  if the Vulkan child window's surface was previously being
  initialized with wrong/stale scale state and never actually
  recovering, rather than never getting a surface at all as theorized.
- `7f848f502` (DIALOG window classification fix) - touches
  `WindowRoleHeuristics`, the same toplevel/popup classification logic
  discussed in the root-cause writeup, though the specific DIALOG/
  Motif-hints case it fixes doesn't obviously match wine's Vulkan
  client window's window-type hints.

Given both real bugs are fixed and the underlying "why" doesn't matter
for the day-to-day fix, this wasn't investigated further - noting the
discrepancy here rather than confidently asserting either commit as
*the* fix, since neither was actually verified in isolation (the range
was taken as a whole, as pulled in by tracking `main`).

**Final state**:

- `nix/audio/flake.nix`'s `reaperNoNet` launcher runs REAPER through a
  private `xwayland-satellite` instance (built from the commit above),
  scoped to REAPER's process tree only via `$DISPLAY`. Both the
  popup-menu-positioning bug and the Vulkan/DXVK black-window
  regression are fixed as of this commit.
- No upstream issue was filed - unnecessary now that the bug is fixed.
  `xwayland-satellite-vulkan-issue.md` (the drafted report) has been
  deleted from this directory.
- The `--no-satellite` escape-hatch idea (proposed above, for sessions
  needing Vulkan plugins while the bug was still open) is no longer
  needed and was not implemented.
- TTY2 Xorg/Openbox/tint2 fallback stays in place as a safety net, but
  is no longer expected to be needed for REAPER/yabridge work now that
  both sway-XWayland bugs this whole investigation exists for
  (`refactor.md`'s original goal) are fixed via xwayland-satellite.
  Revisit removing it (see the original plan's Step 5) only after
  real production sessions across the full plugin catalog confirm no
  further regressions.
- **Maintenance note**: `xwaylandSatelliteSrc`/`xwaylandSatelliteStable`
  in `nix/audio/flake.nix` track a specific unreleased commit, not a
  tagged release - re-pin to a proper tagged release once one exists
  past this commit, same caveat as `yabridgeGitMaster`'s pin comment
  elsewhere in the same file.

## Recurrence (2026-09-10): the "Resolved" fix above was a false positive - real root cause found, local patch written

The Vulkan/DXVK black-window bug (OTT and friends) came back the day after the
previous section declared it fixed. This section is the live-debugging trail
that led to a real fix.

### Ruled out: the nix/audio → separate repo move

Between the "Resolved" entry above and this recurrence,
`nix/audio` was extracted into its own flake
(`github:mgnsk/nix-audio-production`, commits `d4b7784`/`a77099c`) via `git
subtree split`. Suspected this broke something in the move. It didn't:

- `diff`ing `nix/audio/flake.nix` and `flake.lock` from immediately before the
  split against the new repo's HEAD (at the exact commit `flake.lock` pins) is
  byte-for-byte **identical**, including the `xwaylandSatelliteSrc`/
  `xwaylandSatellite` pin at `add2795` from the "Resolved" section. No content
  drift at all.
- The currently-active home-manager generation's `reaper` wrapper already
  referenced `xwayland-satellite-unstable-2026-09-09` (the patched-pin build) -
  confirmed by reading the actual store path's script content. The fixed
  binary was genuinely wired in and running.

### Ruled out: a system mesa/vulkan-radeon update

`mesa`/`vulkan-radeon` have been on `1:26.2.2-1` since 2026-09-06
(`pacman.log`), unchanged through both the "confirmed fixed" session
(2026-09-09) and this recurrence (2026-09-10). Not the variable either.

### Ruled out (or at least not a single reliable lever): timing/prefix state

Empirically tested across several relaunches:

| Prefix state | Waited before adding plugin | Result |
|---|---|---|
| Fresh (recreated) | no | worked |
| Same (reused) | no | black |
| Fresh (recreated) | no | black |
| Fresh (recreated) | yes | worked |

No single variable (prefix freshness, a fixed delay, `wineserver` being
pre-killed before every launch - tested explicitly, no difference) reliably
predicted the outcome. One qualitative, unmeasured observation: successful
launches seemed to bring OTT's window up *faster* than failing ones. All of
this is consistent with a genuine timing race, not a deterministic
regression - see root cause below.

Note on why "wait a bit in REAPER before adding the plugin" doesn't touch
this at all: REAPER itself is a native Linux binary. Wine only starts when
yabridge actually spawns `yabridge-host.exe` for a specific plugin instance -
idling in REAPER's UI never touches wine/wineserver.

### Actual root cause, confirmed via `RUST_LOG=debug` on the private xwayland-satellite instance

Reproduced a failing launch with the `reaper` wrapper's private
`xwayland-satellite` instance running at debug level (temporarily added
`RUST_LOG=debug ... > ~/.cache/xwayland-satellite-debug.log` to the launcher
in `nix/audio/flake.nix`, since iterating against a local `path:` input is
much faster than round-tripping through the separate GitHub repo - the same
approach is available any time `nix/audio` needs live debugging: point
`flake.nix`'s `audio.url` at `path:./nix/audio` temporarily).

The log shows exactly this, for the window matching OTT's DXVK swapchain
size (`310x440`, confirmed against the "Buffer size: 310x440" line in
REAPER's own log from the same failing session):

```
new window: ... window: Window { res_id: 16777216 }, ... 310x440, override_redirect: false
reparent event: ... window: Window { res_id: 16777216 }, parent: Window { res_id: 4194873 } ...
destroying window since its parent is no longer root!
new window: ... window: Window { res_id: 14680067 }, ... 310x440, override_redirect: true
reparent event: ... window: Window { res_id: 14680067 }, parent: Window { res_id: 16777216 } ...
destroying window since its parent is no longer root!
```

...followed, ~300ms later, by the *outer* embedded window (`4194873`)
finally getting reparented into REAPER's own tracked floating container
(`4194874`) - by which point its Vulkan child has already been destroyed.

This is **exactly** the mechanism theorized in the "Root cause" subsection
under the 2026-09-09 "Implementation" entry above (wine's nested Vulkan
`client_window`, reparented one level below the tracked embedded HWND, never
gets a Wayland surface) - the same theory that section says was
"investigated and ruled out by live testing" because it predicted *all*
yabridge plugin GUIs would go black, which is false (most work fine, since
most plugins paint directly onto the outer embedded HWND and never create
this extra nested child window at all - only GPU/DXVK-rendered ones do).
That "ruling out" was itself wrong, or at least incomplete: the destroy-on-
reparent behavior in `src/xstate/mod.rs`'s `ReparentNotify` handler is
**unconditional** in the source (confirmed by reading it directly, at the
exact `add2795` commit that was pinned - which is also upstream `main`'s
current tip, nothing has landed since). It destroys tracking for *any*
window reparented to a non-root parent, full stop - there was never a
subsurface exception carved out.

**Why did the 2026-09-09 "Resolved" section see it as fixed, then?** Almost
certainly a false positive from event-ordering luck, not an actual fix in
that commit range. The race is: does wine's nested Vulkan child window get
reparented into its (not-yet-embedded) plugin-GUI ancestor *before or after*
that ancestor itself gets reparented into REAPER's tracked container? If the
ancestor wins the race, the child's later reparent lands under an
already-tracked window and (per the pre-patch code) would still incorrectly
get destroyed too - but empirically, most of the time in that order, OTT
rendered fine, suggesting REAPER's container embed frequently completes
before wine's nested child gets created in practice, and only sometimes
loses that race. None of the commits in the "Resolved" section's pulled-in
range (`3bc915f09` through `add279513`) touch `ReparentNotify` handling or
add any subsurface concept - re-confirmed now by diffing that exact commit
range against `src/xstate/mod.rs`. The 2026-09-09 test session most likely
just got lucky timing across however many plugins it spot-checked.

### Fix: `SurfaceRole::Subsurface`, a local patch (not yet upstreamed)

Rather than chase the race with timing hacks, patched
`xwayland-satellite` itself (`nix/audio/patches/xwayland-satellite-subsurface-embed.patch`,
applied via the existing `xwaylandSatellite = audiopkgs.xwayland-satellite.overrideAttrs
{ ... patches = [ ... ]; }` in `nix/audio/flake.nix`, on top of the existing
`add2795` src pin - no `cargoHash`/vendor changes needed since it adds no new
dependencies, only uses `wl_subcompositor`/`wl_subsurface`, both already
linked in for the decoration titlebar's own subsurface use).

What it does: adds a proper `SurfaceRole::Subsurface` role. When a window is
reparented to a non-root parent, instead of unconditionally destroying it:

- If that parent is already a tracked, rendered window, the child is
  immediately given a real `wl_subsurface` of the parent's surface
  (position computed the same way `create_popup` already computes popup
  offsets), desynced from the parent's own commit cadence so DXVK's
  independent Present-driven rendering isn't gated on REAPER's frame
  timing.
- If the parent isn't tracked/rendered yet (the actual failure case above),
  the child is marked pending (`SurfaceRole::Subsurface(None)`) instead of
  destroyed. Any buffer attach that arrives in the meantime is queued
  (mirroring the existing pre-configure buffering xdg toplevels/popups
  already use), not dropped. Once the parent itself finishes getting *any*
  role (subsurface, toplevel, or popup), pending children waiting on it are
  promoted - recursively, so multi-level chains like the real
  `4194873 → 16777216 → 14680067` case above resolve correctly regardless of
  which order the levels become ready in.

This is exactly the fix the 2026-09-09 "Root cause" subsection assessed as
"not a small patch... core-architecture work" and declined to attempt live -
turned out to be a contained, well-scoped change (~180 lines in
`src/server/mod.rs`, ~10 in `src/xstate/mod.rs`, ~10 in
`src/server/dispatch.rs`) once the actual reparent ordering was confirmed via
debug logging rather than theorized.

**Verification so far** (2026-09-10, not yet a live production test):

- Two new unit tests added directly to `xwayland-satellite`'s own test suite
  (`embedded_child_reparented_before_parent_ready`,
  `embedded_child_parent_already_ready`, in `src/server/tests.rs`, using the
  project's own `testwl` mock-compositor harness), reproducing the exact
  event ordering from the failing session's debug log. Both pass.
- All 83 pre-existing upstream tests still pass - nothing else regressed.
- The patch applies and the whole crate builds cleanly through the actual
  nix derivation (`nix build .#homeConfigurations.magnus.activationPackage`
  with `audio.url` pointed at `path:./nix/audio`), not just a standalone
  `cargo check`.
- **Not yet confirmed against a real REAPER/OTT session** - that's the next
  step, after a `home-manager switch` picks up the patched build.

**Current state**: `flake.nix`'s `audio.url` is temporarily pointed at
`path:./nix/audio` (was `github:mgnsk/nix-audio-production`) so this could be
iterated on without round-tripping through GitHub. **Revert this** once the
patch is confirmed working live: point `audio.url` back at
`github:mgnsk/nix-audio-production`, push the equivalent change (updated
`xwaylandSatellite` derivation + the new patch file) to that repo, and update
`flake.lock` accordingly. The private `xwayland-satellite` instance's
`RUST_LOG=debug` logging (added to `nix/audio/flake.nix`'s `reaper` wrapper
for this investigation, writing to `~/.cache/xwayland-satellite-debug.log`)
is harmless to leave in place but is debug-only noise now that the root
cause is known - remove it once the fix is confirmed, or keep it if ongoing
visibility into this class of bug seems worth the log noise.

**If this patch doesn't hold up in real use**: the TTY2 Xorg/Openbox/tint2
fallback (see the top of this document) remains available and untouched by
any of this - it never depended on `xwayland-satellite` at all. Also worth
considering, if the local patch proves fragile to maintain: upstreaming it
properly (file an issue/PR against `Supreeeme/xwayland-satellite` with the
debug log evidence above, which is considerably more concrete than what was
available when the "drafted but never filed" report from the 2026-09-09
"Root cause" section would have contained).

## Correction (2026-09-10, later same day): the subsurface patch doesn't fix it either - root cause is inside Xwayland itself

The `SurfaceRole::Subsurface` patch above (committed, built, verified via unit
tests against the exact reparent ordering from the original bug report) does
**not** reliably fix OTT in practice - still intermittent after switching to
it. This section is the live-debugging trail that pinned down why, using
matched fail/success log pairs (same build, same patch, run back to back,
each log copied out immediately after the run so they could be compared
directly).

### Ruled out, in order

- **The repo split** (`nix/audio` → `github:mgnsk/nix-audio-production`):
  byte-identical content before/after, confirmed by diff.
- **A system mesa/vulkan-radeon update**: unchanged (`1:26.2.2-1`) since
  before the bug was last "confirmed fixed".
- **Prefix freshness, a fixed delay before adding the plugin, `wineserver`
  persistence**: tested explicitly (including killing `wineserver` before
  every launch); none reliably predicted the outcome. One anecdotal
  observation (successful launches seemed to bring OTT's window up faster)
  fit a race but wasn't independently actionable.
- **Suspend/resume**: worked for the first 3-4 attempts, then stopped -
  not a reliable lever either, despite initially looking like one.
- **A GPU/DRM-level leak or corruption that suspend clears**: `journalctl -k
  -b | grep amdgpu` across many suspend/resume cycles shows completely clean
  resumes, no reset/timeout/VRAM warnings. Ruled out.
- **The subsurface race itself**: confirmed via `RUST_LOG=debug` on the
  patched build that the new `SurfaceRole::Subsurface` code path *does* run
  correctly (windows get marked "tracking as subsurface candidate" instead
  of destroyed, exactly as designed) - but this happens identically in
  matched fail/success pairs. The patch's own log lines prove it isn't the
  differentiator.

### Matched log-pair comparison: three independent layers, zero difference

Three separate diagnostic angles were tried, each on a fail/success pair
captured back-to-back with the log copied out immediately after each run
(since the `reaper` wrapper overwrites `~/.cache/xwayland-satellite-debug.log`
on every launch):

1. **`xwayland-satellite`'s own `RUST_LOG=debug` event trace.** The nested
   Vulkan/DRI3 child window chain (`16777216` → `14680067`, matching DXVK's
   reported `310x440` swapchain size) never gets a `wl_surface` association
   in *either* the failing or the successful run - confirmed across three
   independent test pairs. Whatever decides the outcome isn't reflected in
   satellite's own window-tracking at all.
2. **`DXVK_LOG_LEVEL=debug`, captured to a file alongside the satellite log.**
   Byte-for-byte identical structure in both runs: same swapchain creation
   at `310x440`, same benign EDID/colorimetry errors (present in both), same
   ongoing Direct2D draw-call traffic, no Vulkan errors, no crashes. DXVK
   genuinely believes it presented successfully either way.
3. **Xwayland's own `-verbose 10`** (wired into the `reaper` wrapper's
   `xwayland-satellite` invocation, forwarded to the actual `Xwayland`
   process it spawns) **and `WAYLAND_DEBUG=1`** (logs every Wayland protocol
   message Xwayland itself sends/receives as a Wayland client of the private
   satellite instance). `-verbose 10` added only static extension-init
   messages, identical between runs. `WAYLAND_DEBUG=1` was far more
   revealing structurally (see below) but showed no *differing* protocol
   traffic between the fail and success cases either.

### The actual finding: the visible OTT window isn't the DRI3 child at all

Reading the `WAYLAND_DEBUG=1` trace closely reframed the whole
investigation. The window previously assumed to be "REAPER's generic
floating FX container" (`4194654` / `4194899` / etc. in various runs, the
one the nested Vulkan child gets reparented into) is not generic - it gets
titled `"VST3: OTT (Xfer Records) - Master Track"` and becomes a completely
normal `xdg_toplevel`: `xdg_wm_base.get_xdg_surface` → `get_toplevel` →
`set_title` → buffer `attach`/`commit`, the standard path, succeeding
identically in both logs.

**This is the window that's actually shown on screen.** The nested
`16777216`/`14680067` chain (which never gets an explicit `wl_surface`
association, in any captured run, success or fail) is wine's internal
DRI3/Vulkan rendering target, not a surface Wayland ever composites
directly. Under plain X11, a child window's content is simply visible
within its parent by ordinary window-stacking - no protocol-level tracking
needed. Xwayland has to replicate that for Wayland by having its *own*
internal compositing manager (the X Composite extension + glamor's
presentation code, not `xwayland-satellite`, not visible in the Wayland
protocol trace) flatten the whole window subtree - ancestor plus the
DRI3-rendered nested child - into the single buffer it hands over for the
ancestor's `wl_surface`.

**Conclusion**: the actual bug is a timing race entirely inside Xwayland's
own C code, between DRI3/Present frame-readiness on the nested child window
and whenever Xwayland's internal compositor takes its snapshot to build the
ancestor's presented frame. This is consistent with every piece of evidence
gathered: `xwayland-satellite`'s tracking, DXVK's log, and Xwayland's own
extension/protocol-level logging all show success in both cases, because
each of those layers *does* succeed regardless of the outcome - the failure
happens one level lower, in glamor/Composite's own buffer-flattening, which
none of the available logging surfaces at all.

**This is out of scope for `xwayland-satellite`.** The subsurface patch
(`nix/audio/patches/xwayland-satellite-subsurface-embed.patch`) is a real,
tested fix for a real bug (satellite's own destroy-on-reparent race) - kept
in place since it's harmless and may matter for some other case - but it
was never going to fix this, since satellite never gets a chance to act on
the nested child window either way.

**Next step** (in progress): digging into Xwayland's own C source (the
`composite` extension and glamor's Present/DRI3 integration in `xserver`)
to find and potentially patch the actual race. This is a materially bigger
undertaking than anything above - an unfamiliar, large C codebase, with no
guarantee of a fixable result in reasonable time. TTY2 Xorg/Openbox/tint2
(see the top of this document) remains the fallback if this doesn't pan
out; it sidesteps the problem entirely since it has no Xwayland/Wayland
bridging layer at all.

## Update (2026-09-10): the tooling bug that hid all evidence, and the real conclusion

**Tooling bug found and fixed first.** Every previous attempt to get
`ErrorF`-based tracing (`XWLTRACE`) out of a custom-patched Xwayland
produced zero output, no matter what: `fflush`, an unconditional
`block_handler` probe, checking for stale processes, all ruled out one at
a time. The actual cause: nixpkgs' own `xwayland-satellite` package.nix has
a `postFixup` that runs `wrapProgram $out/bin/xwayland-satellite --prefix
PATH : "${xwayland}/bin"` (stock, unpatched xwayland) - and `wrapProgram`'s
`--prefix PATH` always wins over whatever `PATH=` the launching wrapper
script set, because it's baked into the wrapper binary itself and applied
after exec. So every custom `PATH=$traced:...` prefix in the `reaper`
launcher script was silently discarded at the last possible moment - the
running `Xwayland` binary was always the stock one, confirmed via
`readlink -f /proc/<pid>/exe` returning the stock store path and via
`/proc/<pid>/environ` showing stock ahead of traced in `PATH`.

Fix (`nix/audio/flake.nix`, commit `9464814`): override `postFixup` in the
`xwaylandSatellite` derivation itself to wrap with `xwaylandTraced` instead
of stock `xwayland`, and remove the now-redundant `PATH=` prefix hack from
the `reaper` wrapper. Verified via `strings` on the rebuilt binary that its
own baked-in `--prefix PATH` argument now points at the traced store path.

**With real `XWLTRACE` data finally in hand, the previous C-level race
theory is wrong.** A matched fail/success log pair
(`xwayland-satellite-debug-{fail,success}.log`,
`dxvk-debug-{fail,success}.log`, all four from the same test round) shows:

- The OTT GUI window is trivially identifiable in both logs by its
  `region=(0,28)-(310,468)` size (`window=0x400229` in the fail run,
  `window=0x4004d7` in the success run - IDs differ because each is a
  fresh Xwayland/satellite instance, but the size match is exact and
  unambiguous).
- In **both** the fail and success run, this window receives a steady,
  uninterrupted stream of `damage_report` -> `post_damage` ->
  `swap_pixmap copy_pixmap_area` events (the ordinary frame_callback-gated
  Composite damage-copy path - not the Present flip/copy path at all,
  which is only ever used by the REAPER main toplevel). Activity continues
  right up to the last line of each log, which ends only because the test
  was terminated (reaper closed) - there is no stall, no gap, no divergence
  between the two runs at this level.
- The `dxvk-debug-{fail,success}.log` pair is functionally byte-identical
  once timestamps, session IDs, and ASLR'd pointer addresses are stripped
  (`diff` shows only those cosmetic differences). Wine/DXVK/Direct2D issue
  the exact same sequence of calls in both cases.

**Conclusion: Xwayland's and xwayland-satellite's compositing pipeline are
functioning correctly and identically in both the fail and success case.**
Every `Damage` region generated by the client is faithfully copied into the
Wayland surface, frame after frame, whether or not the user perceives the
window as black. This exonerates the entire Xwayland C-level Present/
Composite/glamor path that was the target of the previous theory - there is
nothing to patch there. The only remaining explanation is that **the pixmap
content itself is black** - i.e. wine/DXVK/Direct2D (the OTT GUI appears to
render via Direct2D on top of DXVK/D3D11, based on the volume of
`d2d:d2d_device_context_*` "fixme"/stub log lines - a known-incomplete Wine
component) is sometimes producing genuinely black frames, which Xwayland
then correctly and dutifully displays.

**This reorients the investigation away from Xwayland/xwayland-satellite
entirely** and toward wine's Direct2D implementation / DXVK swapchain
content, which is a different and probably much harder problem to chase
(would need to inspect actual pixel content, e.g. via a Vulkan validation
layer or capturing the DXVK swapchain image at the moment of failure -
neither Xwayland's nor xwayland-satellite's logs can show pixel content).
Given the new user-observed trigger pattern - "OTT window content briefly
showed and as I clicked on another window/terminal to focus it, it went
black" - a focus-loss-triggered redraw producing a black frame in wine's
Direct2D stub implementation is the leading candidate, but unconfirmed.
TTY2 Xorg/Openbox/tint2 remains the pragmatic fallback and sidesteps the
problem entirely, since it has no Xwayland/Wayland bridging layer and no
Direct2D wine peculiarities have ever been reported to cause black windows
there.

## Update (2026-09-10, later): matches a known, well-documented upstream Wine issue

Web research confirms this is a known, already-solved-elsewhere problem, not
something specific to this setup: JUCE plugins render their GUI via
Direct2D + DirectComposition, but stock Wine (staging included) only
implements Direct2D up to feature level 1.2 and doesn't implement
`DCompositionCreateDevice` at all (`E_NOTIMPL`, `0x80004001`). JUCE 8
requires 1.3 unconditionally; some older JUCE plugins (Xfer OTT's JUCE
version predates 8, but our `dxvk-debug-fail.log` shows hundreds of
`d2d:d2d_device_context_*` "fixme"/stub lines - it's clearly exercising the
same incomplete Direct2D code, just via an older/narrower entry point) hit
the same class of stubbed-out rendering path. The result in every reported
case: audio/MIDI/automation work fine, GUI renders as a solid black window.
This exactly matches every symptom gathered in this document, including the
newly-observed focus-change trigger.

**Fix applied**: `giang17/wine` (https://github.com/giang17/wine) maintains
a Direct2D 1.3 + DirectComposition implementation on top of Wine, tracked
per-Wine-version as branches (`d2d1-dcomp-11.0`, `-11.16`, etc; packaged
for Arch/CachyOS as `mklnln/wine-d2d1-dcomp`). `nix/audio/flake.nix`'s
`bitbridgeWine` - the single Wine build wired into every yabridge/REAPER
plugin-hosting path in this setup, not staging-specific - now builds from
`giang17/wine` branch `d2d1-dcomp-11.16` (pinned to commit `a893414`,
2026-09-04) instead of nixpkgs' own wine-staging source, via the same
`overrideAttrs`-swaps-`src` pattern used earlier in this document for
`xwaylandTraced`/`xwaylandSatellite`. Staging patches are dropped (giang17's
tree is a full modified source, not a patch layered on top of nixpkgs'
own staging application), since none of the staging patchset touches
d2d1/dcomp and version-matching them against a different tree wasn't worth
the risk. Build succeeded (~25 minutes, full wineWow 32+64 split with the
same mingw cross toolchains and support flags nixpkgs already uses for
bitbridgeWine): `wine --version` reports `wine-11.16` as expected, and
`d2d1.dll`/`dcomp.dll` are meaningfully different in size from stock
(patched d2d1.dll 1.35MB vs stock 1.2MB, dcomp.dll 283KB vs 327KB) -
consistent with a real reimplementation rather than a no-op swap.

**Not yet verified**: only a static build check has been done (this
sandbox has no display). Next step is for the user to run `./nix/switch.sh`
and actually test OTT (and other previously-black Direct2D-based plugins)
live.

## Update (2026-09-11): confirmed live - and a separate, pre-existing bug resurfaces

**The giang17/wine fix works.** Confirmed live by the user: OTT and other
previously-black Vulkan/DXVK/Direct2D plugin GUIs now render reliably.
This closes out the black-window investigation - it was never an
Xwayland/xwayland-satellite bug at all, just wine's own incomplete
Direct2D/DirectComposition implementation, as this document's
2026-09-10 updates concluded.

**New, separate finding**: a different plugin - Northern Artillery's
Drums - has a menu that flickers and mispositions, "similar symptoms as
if we didn't use xwayland-satellite" (the user's words). This is telling:
it means the *original* bug xwayland-satellite exists to work around here
(sway's own built-in XWayland override-redirect popup-positioning bug,
github.com/Supreeeme/xwayland-satellite issue #293) is resurfacing for
this specific plugin's menu, despite xwayland-satellite being active and
routing REAPER's X11 traffic through it as designed. This was true even
with the pinned unstable commit + the local subsurface-tracking patch
from the black-window investigation in place - so those changes were
never masking or interacting with it either way; it's an independent gap.

**Action taken**: with the black-window bug now conclusively traced to
wine rather than Xwayland/xwayland-satellite, there was no more reason to
carry the custom-pinned `xwaylandSatelliteSrc`/`xwaylandSatellite`
(unstable commit + `xwayland-satellite-subsurface-embed.patch`) or the
`xwaylandTraced` (ErrorF-instrumented Xwayland,
`xwayland-present-trace.patch`) builds from earlier in this document.
Both were reverted back to plain, unmodified nixpkgs packages -
`xwaylandSatellite = audiopkgs.xwayland-satellite;` (currently 0.8.2) and
whatever `audiopkgs.xwayland` resolves to - confirmed via a real build
(`nix build .#default`) and `strings` on the resulting binary showing
xwayland-satellite's own `postFixup` now points at plain upstream
`xwayland-24.1.13`, not any custom-patched store path. This gives a clean,
unmodified baseline to debug the Northern Artillery Drums menu bug
against, so any fix found won't be tangled up with leftover
black-window-investigation scaffolding.

**Next step**: diagnose the Northern Artillery Drums menu flicker/
positioning bug fresh, against the clean upstream xwayland-satellite/
xwayland baseline above. Not yet started.

## Update (2026-09-11): Northern Artillery Drums menu - root cause found, upstream limitation

Root cause: **xwayland-satellite has no X11-popup-grab handling at all.**
`grep -rn "grab\b"` on its actual source (0.8.2) returns nothing - it
never issues an `xdg_popup.grab()` request when creating a popup.
Pointer-grab emulation for X11 clients is normally Xwayland's own job
(`maybe_fake_grab_devices()`, which tries a `zwp_pointer_constraints_v1`
pointer lock) - and a live `RUST_LOG=debug WAYLAND_DEBUG=1` trace of 12
dropdown-open attempts (`menu.log`, `.scripts/`) shows that protocol is
bound at startup but never actually used. Without a real grab, whether
the dropdown survives depends on winning a race against the
compositor's ordinary (non-grab) pointer-focus reassignment logic.

Evidence from the trace: every failed attempt creates the identical
5-window group (a combo-box dropdown + 2 scrollbars: 1x1, 153x12,
12x226 x2, 153x202 - `window_role_heuristics` classifies all of them
"Popup" correctly, every time, so classification isn't the issue) and
then unmaps+destroys all 5 within 15-45ms of creation - never
actually rendered long enough to be seen. The one success (a 12th
attempt) created the identical window group and it survived 3.5
seconds before a normal close. Checked and ruled out two timing
theories against the actual `wl_pointer.button` events: press-to-
release click duration doesn't correlate (the successful click's 90ms
duration was shorter than several failed ones' 97-174ms), and neither
does the gap between retries (the successful retry had the *shortest*
gap of the whole sequence). The user's own follow-up testing narrowed
it further and matches the grab-race theory exactly: clicking fast
reliably works, clicking slow reliably opens-then-closes.

This is a known, currently-open class of upstream bug, not something
introduced by this setup's configuration: xwayland-satellite issues
**#293** ("REAPER + Yabridge + VST menus don't show as popups" - the
original issue this setup adopted xwayland-satellite to fix in the
first place), **#221** ("REAPER + ValhallaPlate dropdowns are not
treated as popups"), and **#326** ("Menus that spawn multiple menus
misbehave... may not spawn at all and auto-close" - this exact
symptom). Unlike the wine/Direct2D case, there is no mature third-party
fork already solving this - it would need a new upstream-style fix
(implementing popup grab handling in xwayland-satellite itself) rather
than adopting an existing patch.

**Current status**: workaround only (click fast). Not yet decided
whether to attempt an upstream-style fix or accept the workaround / fall
back to TTY2 Xorg for cases where this matters.

## Update (2026-09-12): TTY2 Xorg restored, decision made - two prefixes, not one

The "not yet decided" above is now decided: TTY2 Xorg + Openbox + tint2 (deleted
in `e866303`, "no xorg session is needed anymore now that sway is the only
desktop") is back, and is now the reliable environment rather than a rare
fallback. `nix/audio/flake.nix` was restructured around two separate wine
prefixes/REAPER binaries instead of the single `~/.wine-audio` setup this whole
document was written against:

- **`reaper-stable`** (TTY2, Xorg/Openbox, `~/.wine-stable`) - nixpkgs' own
  `wineRelease = "yabridge"` source (wine 9.21 + wine-staging, the pairing
  nixpkgs curates specifically for building yabridge's 32-bit bitbridge on a
  modern toolchain), DXVK via winetricks' `dxvk` verb. Real X11, no
  xwayland-satellite involved at all - the popup-grab bug documented above
  doesn't apply here, there's no Wayland bridging in the loop to have the bug.
- **`reaper-experimental`** (TTY1, sway/Wayland, `~/.wine-experimental`) -
  unchanged from the rest of this document: giang17's Direct2D/DirectComposition
  wine fork, DXVK deliberately not installed (conflicts with the fork's own
  composition-swapchain path), REAPER launched via a private xwayland-satellite
  instance per the fix earlier in this document.

Confirmed by real use since the restructure:

- **TTY2/`reaper-stable` works for everything tried so far**, including Ozone
  (the plugin whose Direct2D-dependent GUI motivated giang17's fork in the first
  place) and DXVK-dependent plugins - stock/staging wine's ordinary Direct3D
  path plus a real X11 session sidesteps both the black-window bug (Ozone here
  isn't relying on the incomplete Direct2D/DirectComposition code paths stock
  wine has, since standard Direct3D via DXVK is a different, complete code path)
  and the popup-grab bug (no Wayland bridging at all).
- **TTY1/`reaper-experimental` still can't run Ozone** - consistent with this
  document's own root-cause finding above (xwayland-satellite has no X11
  popup-grab handling), Ozone's menus are still affected there. Not re-diagnosed
  further here; Ozone work should go through TTY2/`reaper-stable` for now.
- **DXVK works on both prefixes** (winetricks' `dxvk` verb on stable, the
  giang17 fork's own composition path on experimental).
- **32-bit bitbridged plugins work on both prefixes** (both wine builds are
  `wineWow` classic split, both yabridge builds have `-Dbitbridge=true`).

Net effect: TTY2/Openbox/`reaper-stable` is now the environment to reach for
whenever a plugin's menus or GUI are in question, not just a fallback of last
resort; TTY1/sway/`reaper-experimental` remains the everyday environment for
everything else. The two prefixes are mutually exclusive at any one moment only
in the sense that yabridge's chainloaders for whichever prefix launches last
overwrite the shared `~/.vst3` discovery path - both `reaper-stable` and
`reaper-experimental` re-sync their own chainloaders on launch, so either one
is always correct to run regardless of which ran last.
