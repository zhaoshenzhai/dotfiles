-- Core
import XMonad

-- Window stack manipulation and map creation
import Data.Tree
import Data.Maybe (fromJust)
import qualified XMonad.StackSet as W
import qualified Data.Map        as M

-- System
import System.Exit (exitSuccess)
import System.IO (hPutStrLn)

-- Hooks
import XMonad.Hooks.ManageDocks(avoidStruts, docks, manageDocks, ToggleStruts(..))
import XMonad.Hooks.DynamicLog(dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.WorkspaceHistory

-- Layout
import XMonad.Layout.Renamed
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.LayoutModifier(ModifiedLayout)

-- Actions
import XMonad.Actions.CopyWindow(copy, kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.Submap(submap)

-- Utils
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.NamedScratchpad
import XMonad.Util.SpawnOnce
import XMonad.Util.Dmenu

-- Keys
import Graphics.X11.ExtraTypes.XF86
---------------------------------------------------------------------------------------------------------------------
myTerminal                                   = "alacritty"                       :: String
myBorderWidth                                = 2                                 :: Dimension
myWindowGap                                  = 0                                 :: Integer
myModMask                                    = mod1Mask                          :: KeyMask
myFocusedBorderColor                         = "#5C6370"                         :: String
myUnFocusedBorderColor                       = "#0C1320"                         :: String
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

myLayout =
    avoidStruts $ smartBorders myLayout
    where
        myLayout = full ||| tall
---------------------------------------------------------------------------------------------------------------------
--Key bindings
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        ((modm, xK_backslash), spawn myTerminal         ),
        ((modm, xK_n        ), spawn "alacritty -e nvim"),
        ((modm, xK_f        ), spawn "alacritty -e vifm"),

        ((modm, xK_Return                 ), spawn "dmenu_extended_run"                                      ),
        ((modm, xK_w                      ), spawn "dmenu_extended_run \"google-chrome-stable\""             ),
        ((modm, xK_s                      ), spawn "dmenu_extended_run \"-> Internet search:\" \"Google\""   ),
        ((modm .|. shiftMask, xK_s        ), spawn "dmenu_extended_run \"-> Internet search:\" \"Wikipedia\""),
 
        ((modm, xK_t        ), sendMessage NextLayout  ),
        ((modm, xK_b        ), sendMessage ToggleStruts),
        ((modm, xK_Tab      ), windows W.focusDown     ),
        ((modm, xK_grave    ), windows W.focusUp       ),
        ((modm, xK_1        ), windows W.focusMaster   ),
        ((modm, xK_m        ), windows W.swapMaster    ),
        ((modm, xK_h        ), windows W.swapUp        ),
        ((modm, xK_l        ), windows W.swapDown      ),
        ((modm, xK_j        ), sendMessage Shrink      ),
        ((modm, xK_k        ), sendMessage Expand      ),
        ((modm, xK_r        ), refresh                 ),
        ((modm, xK_Escape   ), kill                    ),

        ((modm, xK_F1       ), spawn "amixer -q set Master toggle"                           ),
        ((modm, xK_F2       ), spawn "amixer -q set Master unmute & amixer -q set Master 5%-"),
        ((modm, xK_F3       ), spawn "amixer -q set Master unmute & amixer -q set Master 5%+"),

        ((modm, xK_q        ), spawn "xmonad --recompile; xmonad --restart"),
        ((modm .|. shiftMask, xK_q), io exitSuccess)
    ]
    

    ++[((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
---------------------------------------------------------------------------------------------------------------------
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        ((modm, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)),
        ((modm, button2), (\w -> focus w >> windows W.shiftMaster)),
        ((modm, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))
    ]
---------------------------------------------------------------------------------------------------------------------
myWorkspaces = ["1","2","3","4","5","6","7","8","9"]
---------------------------------------------------------------------------------------------------------------------
myEventHook = mempty
myManageHook = composeAll
    [
        className =? "MPlayer"        --> doFloat,
        resource  =? "desktop_window" --> doIgnore,
        resource  =? "kdesktop"       --> doIgnore
    ]
myStartupHook = do
    spawnOnce "~/.config/scripts/init.sh &"
---------------------------------------------------------------------------------------------------------------------
main = do
    xmproc <- spawnPipe "xmobar -x 0 /home/zhao/.config/xmobar/xmobarrc"

    xmonad $ docks def{
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myUnFocusedBorderColor,
        focusedBorderColor = myFocusedBorderColor,
        keys               = myKeys,
        mouseBindings      = myMouseBindings,
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook,
        startupHook        = myStartupHook,
        
        logHook = dynamicLogWithPP $ xmobarPP
            {
                ppOutput = \x -> hPutStrLn xmproc x,
                ppCurrent = xmobarColor "#F8F8FF" "" . wrap "[" "]",
                ppHidden = xmobarColor "#F8F8FF" "",
                ppHiddenNoWindows = xmobarColor "#888888" "",
                ppTitle = xmobarColor "#A8A8AA" "" . shorten 40,
                ppSep = "<fc=#F8F8FF> | </fc>"
            }
    }
