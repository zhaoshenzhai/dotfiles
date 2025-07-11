-- Core
import XMonad

-- Window stack manipulation and map creation
import Data.Tree
import Data.Maybe (fromJust)
import Control.Monad (liftM2)
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

-- System
import System.Exit (exitSuccess)
import System.IO (hPutStrLn)

-- Hooks
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog(dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.WorkspaceHistory

-- Layout
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.Renamed
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.LayoutModifier(ModifiedLayout)
import XMonad.Layout.WindowNavigation

-- Actions
import XMonad.Actions.CopyWindow(copy, kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.Submap(submap)
import XMonad.Actions.SpawnOn
import XMonad.Actions.OnScreen

-- Utils
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.NamedScratchpad
import XMonad.Util.EZConfig
import XMonad.Util.SpawnOnce
import XMonad.Util.Dmenu
import XMonad.Util.WorkspaceCompare

-- Keys
import Graphics.X11.ExtraTypes.XF86

---------------------------------------------------------------------------------------------------------------------

myTerminal                                   = "kitty"                           :: String
myBorderWidth                                = 2                                 :: Dimension
myWindowGap                                  = 0                                 :: Integer
myModMask                                    = mod1Mask                          :: KeyMask
myFocusedBorderColor                         = "#5C6370"                         :: String
myUnFocusedBorderColor                       = "#1E2127"                         :: String
myFocusFollowsMouse                          = True                              :: Bool
myClickJustFocuses                           = False                             :: Bool

---------------------------------------------------------------------------------------------------------------------

mySpacing :: Integer -> l a -> ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border 0 i 0 i) True (Border i 0 i 0) True

tall = renamed [Replace "Tall"]
    $ mySpacing myWindowGap
    $ ResizableTall 1 (3/100) (1/2) []

full = renamed [Replace "Full"]
    $ mySpacing myWindowGap
    $ Full

myLayoutHook =
    avoidStruts $ smartBorders myLayout
    where
        myLayout = full ||| tall

---------------------------------------------------------------------------------------------------------------------

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        -- Base
        ((modm, xK_backslash), spawn myTerminal                                     ),
        ((modm, xK_Return   ), spawn "$DOTFILES_DIR/scripts/dmenuOpenFile.sh"       ),
        ((modm, xK_e        ), spawn "kitty -e vifm ~/ ~/Dropbox -c normal\\ ggvGgA"),

        -- Browser
        ((modm,               xK_w), spawn "$DOTFILES_DIR/scripts/openQute.sh -Z"),
        ((modm .|. shiftMask, xK_w), spawn "$DOTFILES_DIR/scripts/openQute.sh -P"),

        -- Scripts
        ((modm, xK_g), spawn "kitty $DOTFILES_DIR/scripts/gitCommit.sh"),

        -- Screenshot
        ((modm .|. shiftMask, xK_p), spawn "cd ~/Downloads; scrot 'Scrot_%Y_%m_%d_%H%M%S.png'"),

        -- Applications
        ((modm,               xK_o), spawn "obsidian"                  ),
        ((modm,               xK_z), spawn "zoom"                      ),
        ((modm,               xK_s), spawn "spotify"                   ),
        ((modm .|. shiftMask, xK_d), spawn "discord"                   ),
        ((modm .|. shiftMask, xK_g), spawn "chromium --force-dark-mode"),

        -- Windows
        ((modm              , xK_f     ), sendMessage NextLayout  ),
        ((modm              , xK_grave ), sendMessage ToggleStruts),
        ((modm              , xK_Tab   ), windows W.focusDown     ),
        ((modm              , xK_h     ), windows W.swapUp        ),
        ((modm              , xK_l     ), windows W.swapDown      ),
        ((modm              , xK_j     ), sendMessage Shrink      ),
        ((modm              , xK_k     ), sendMessage Expand      ),
        ((modm .|. shiftMask, xK_Escape), kill                    ),

        -- Audio
        ((modm,               xK_F1), spawn "$DOTFILES_DIR/scripts/audioControl.sh -t"  ),
        ((modm,               xK_F2), spawn "$DOTFILES_DIR/scripts/audioControl.sh -d 5"),
        ((modm,               xK_F3), spawn "$DOTFILES_DIR/scripts/audioControl.sh -i 5"),
        ((modm .|. shiftMask, xK_F2), spawn "$DOTFILES_DIR/scripts/audioControl.sh -d 1"),
        ((modm .|. shiftMask, xK_F3), spawn "$DOTFILES_DIR/scripts/audioControl.sh -i 1"),
        ((modm,               xK_F4), spawn "$DOTFILES_DIR/scripts/audioControl.sh -b"  ),
        ((modm,               xK_F5), spawn "$DOTFILES_DIR/scripts/audioControl.sh -p"  ),
        ((modm,               xK_F6), spawn "$DOTFILES_DIR/scripts/audioControl.sh -n"  ),
        ((modm,               xK_c ), spawn "$DOTFILES_DIR/scripts/audioControl.sh -c"  ),
        ((modm,               xK_d ), spawn "$DOTFILES_DIR/scripts/audioControl.sh -x"  ),

        -- Brightness
        ((modm,               xK_F7), spawn "sudo lux -s 5%"),
        ((modm,               xK_F8), spawn "sudo lux -a 5%"),
        ((modm .|. shiftMask, xK_F7), spawn "sudo lux -s 1%"),
        ((modm .|. shiftMask, xK_F8), spawn "sudo lux -a 1%"),

        -- Info
        ((modm, xK_t), spawn "kitty --class sys,sys -e htop"            ),
        ((modm, xK_p), spawn "pavucontrol"                              ),
        ((modm, xK_b), spawn "kitty bluetoothctl; bluetoothctl power on"),

        -- Xmonad
        ((modm, xK_r), spawn "killall xmobar; xmonad --restart; $DOTFILES_DIR/scripts/initX.sh"),
        ((modm .|. shiftMask, xK_r), spawn "sudo ghc --make $DOTFILES_DIR/config/xmonad.hs -i -ilib -fforce-recomp -main-is main -dynamic -v0 -outputdir /home/zhao/.config/xmonad/build-x86_64-linux -o /home/zhao/.config/xmonad/xmonad-x86_64-linux; killall xmobar; xmonad --restart"),
        ((modm .|. shiftMask, xK_q), io exitSuccess)
    ]

    ++[((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]

---------------------------------------------------------------------------------------------------------------------

myWorkspaces = [
    "<fn=3>\xf303  </fn>",  -- Arch
    "<fn=3>\xf268  </fn>",  -- Browser
    "<fn=3>\xf040  </fn>",  -- Write
    "<fn=3>\xf02d  </fn>",  -- Book1
    "<fn=3>\xf05da  </fn>", -- Book2
    "<fn=2>\xe0bb   </fn>", -- Book3
    "<fn=3>\xf0254  </fn>", -- Media
    "<fn=3>\xf1bc  </fn>",  -- Spotify
    "<fn=3>\xf013 </fn>"    -- Config
    ]

myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..]

---------------------------------------------------------------------------------------------------------------------

myStartupHook = do
    spawnOnce "$DOTFILES_DIR/scripts/initX.sh && $DOTFILES_DIR/scripts/initApplications.sh &"

---------------------------------------------------------------------------------------------------------------------

myManageHook = composeAll
    [
        className =? "reminders"   --> viewShift (myWorkspaces !! 0),
        className =? "qutebrowser" --> viewShift (myWorkspaces !! 1),
        className =? "Chromium"    --> viewShift (myWorkspaces !! 1),
        className =? "obsidian"    --> viewShift (myWorkspaces !! 2),
        className =? "nvim"        --> viewShift (myWorkspaces !! 2),
        className =? "mpv"         --> viewShift (myWorkspaces !! 6),
        className =? "media"       --> viewShift (myWorkspaces !! 6),
        className =? "Spotify"     --> viewShift (myWorkspaces !! 7),
        className =? "sys"         --> viewShift (myWorkspaces !! 8),
        className =? "Pavucontrol" --> viewShift (myWorkspaces !! 8)
    ]

    where viewShift = doF . liftM2 (.) W.greedyView W.shift

---------------------------------------------------------------------------------------------------------------------

main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar -x 0 $DOTFILES_DIR/config/xmobarrc"

    xmonad $ ewmh $ docks def{
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myUnFocusedBorderColor,
        focusedBorderColor = myFocusedBorderColor,
        keys               = myKeys,
        layoutHook         = myLayoutHook,
        startupHook        = myStartupHook,
        manageHook         = myManageHook <+> manageDocks,

        logHook = dynamicLogWithPP $ xmobarPP
            {
                ppOutput          = hPutStrLn xmproc,
                ppCurrent         = xmobarColor "#56B6C2" "",
                ppHidden          = xmobarColor "#F8F8FF" "",
                ppHiddenNoWindows = xmobarColor "#A8A8AA" "",
                ppLayout          = const "",
                ppTitle           = xmobarColor "#A8A8AA" "" . shorten 30,
                ppSep             = "<fc=#A8A8AA> | </fc>",
                ppExtras          = [gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset],
                ppOrder           = \(ws:l:t:ex) -> [ws,l]++ex++[t]
            }
}
