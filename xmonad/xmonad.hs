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
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog(dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.WorkspaceHistory
import XMonad.Hooks.DynamicIcons

-- Layout
import XMonad.Layout.Renamed
import XMonad.Layout.NoBorders
import XMonad.Layout.Spacing
import XMonad.Layout.ResizableTile
import XMonad.Layout.ThreeColumns
import XMonad.Layout.LayoutModifier(ModifiedLayout)

-- Actions
import XMonad.Actions.CopyWindow(copy, kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.Submap(submap)
import XMonad.Actions.SpawnOn

-- Utils
import XMonad.Util.Run (spawnPipe, spawnPipeWithNoEncoding, spawnPipeWithUtf8Encoding)
import XMonad.Util.NamedScratchpad
import XMonad.Util.EZConfig
import XMonad.Util.SpawnOnce
import XMonad.Util.Dmenu
import XMonad.Util.WorkspaceCompare

-- Keys
import Graphics.X11.ExtraTypes.XF86
---------------------------------------------------------------------------------------------------------------------
myTerminal                                   = "alacritty"                       :: String
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

myLayout =
    avoidStruts $ smartBorders myLayout
    where
        myLayout = full ||| tall
---------------------------------------------------------------------------------------------------------------------
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        ((modm, xK_backslash), spawnOn "1" myTerminal         ),
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
myWorkspaces = [
    "<fn=2>\xf489  </fn>", -- Terminal
    "<fn=2>\xf448  </fn>", -- Writing
    "<fn=2>\xf269  </fn>", -- Chrome
    "<fn=2>\xf013 </fn>"   -- Config
    ]
---------------------------------------------------------------------------------------------------------------------
myStartupHook = do
    spawnOnce "~/.config/scripts/init.sh &"
---------------------------------------------------------------------------------------------------------------------
myManageHook = composeAll
    [
        className =? myTerminal --> doShift "<fn=2>\xf489 </fn>",
        manageDocks
    ]
---------------------------------------------------------------------------------------------------------------------
main :: IO ()
main = do
    xmproc <- spawnPipeWithUtf8Encoding "xmobar -x 0 /home/zhao/.config/xmonad/xmobarrc"

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
        layoutHook         = myLayout,
        startupHook        = myStartupHook,
        manageHook         = myManageHook <+> manageHook def,

        logHook = dynamicLogWithPP $ xmobarPP
            {
                ppOutput = hPutStrLn xmproc,
                ppCurrent = xmobarColor "#56B6C2" "",
                ppHidden = xmobarColor "#F8F8FF" "",
                ppHiddenNoWindows = xmobarColor "#888888" "",
                ppLayout = const "",
                ppTitle = xmobarColor "#A8A8AA" "" . shorten 80,
                ppSep = "<fc=#888888> | </fc>"
            }
}
