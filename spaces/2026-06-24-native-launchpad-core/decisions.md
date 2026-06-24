# Decisions

## 1. Real Apps Before Demo Polish

The launcher must use real installed applications. Static sample icons are misleading and should not remain in the product surface.

## 2. Standard Application Locations First

Scan `/Applications`, `/System/Applications`, `/System/Applications/Utilities`, and the user's `~/Applications` folder. Broader Spotlight-based discovery can be added after the basic launcher works.

## 3. Launch Through NSWorkspace

Opening apps should use `NSWorkspace` instead of shelling out to `open`. This keeps behavior inside native macOS APIs.

## 4. Overlay Instead of Normal Document Window

The launcher should configure its window as a borderless full-screen overlay. It is still not final Launchpad parity, but it matches the product requirement much better than a normal titled window.
