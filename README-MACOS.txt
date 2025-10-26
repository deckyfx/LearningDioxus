macOS Security - "App is damaged" Error Fix
============================================

If you see "app is damaged and should be moved to trash":

REQUIRED FIX (Terminal):
1. Open Terminal
2. Navigate to the folder containing Dxrc.app
3. Run this command:
   xattr -cr Dxrc.app
4. Now double-click Dxrc.app to open

This happens because macOS quarantines downloaded apps.
The xattr command removes the quarantine flag.

Quick command if app is in Downloads:
  cd ~/Downloads && xattr -cr Dxrc.app && open Dxrc.app

Right-click → Open will NOT work for this error!
You MUST use the xattr command above.
