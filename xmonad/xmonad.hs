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
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.WorkspaceHistory
import XMonad.Hooks.DynamicIcons

-- Layout
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
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

myLayoutHook =
    avoidStruts $ smartBorders myLayout
    where
        myLayout = full ||| tall
---------------------------------------------------------------------------------------------------------------------
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [
        ((modm, xK_backslash), spawn myTerminal                 ),
        ((modm, xK_p        ), spawn "pavucontrol"              ),
        ((modm, xK_v        ), spawn "alacritty -e vifm"        ),
        ((modm, xK_n        ), spawn "alacritty -e nvim"),
        ((modm, xK_b        ), spawn "alacritty --class sys,sys -e bluetoothctl"),
        ((modm, xK_i        ), spawn "alacritty --class sys,sys -e nmtui"       ),

        ((modm, xK_Return), spawn "./.config/scripts/dmenu/open_file.sh"),

        ((modm, xK_w                   ), spawn "google-chrome-stable --profile-directory=Default --force-dark-mode"    ),
        ((modm .|. shiftMask, xK_w     ), spawn "google-chrome-stable --profile-directory='Profile 2' --force-dark-mode"),

        ((modm, xK_s), spawn "spotify"),
        ((modm, xK_o), spawn "obsidian"),
        ((modm, xK_d), spawn "discord"),

        ((modm, xK_f     ), sendMessage NextLayout  ),
        ((modm, xK_grave ), sendMessage ToggleStruts),
        ((modm, xK_Tab   ), windows W.focusDown     ),
        ((modm, xK_m     ), windows W.swapMaster    ),
        ((modm, xK_h     ), windows W.swapUp        ),
        ((modm, xK_l     ), windows W.swapDown      ),
        ((modm, xK_j     ), sendMessage Shrink      ),
        ((modm, xK_k     ), sendMessage Expand      ),
        ((modm, xK_Escape), kill                    ),

        ((modm, xK_F1              ), spawn "./.config/scripts/volume/volumeControl.sh -t"  ),
        ((modm, xK_F2              ), spawn "./.config/scripts/volume/volumeControl.sh -d 5"),
        ((modm, xK_F3              ), spawn "./.config/scripts/volume/volumeControl.sh -i 5"),
        ((modm .|. shiftMask, xK_F2), spawn "./.config/scripts/volume/volumeControl.sh -d 1"),
        ((modm .|. shiftMask, xK_F3), spawn "./.config/scripts/volume/volumeControl.sh -i 1"),
        ((modm, xK_F5              ), spawn "./.config/scripts/volume/volumeControl.sh -p"  ),

        ((modm .|. shiftMask, xK_g), spawn "alacritty -e ~/MathWiki/.github/gitCommit.sh"),
        ((modm .|. shiftMask, xK_u), spawn "alacritty -e ~/MathWiki/.scripts/mathLinks.sh -u"),
        ((modm .|. shiftMask, xK_n), spawn "alacritty -e ~/MathWiki/.scripts/mathLinks.sh -n"),

        ((modm              , xK_q), spawn "xmonad --recompile; killall xmobar; xmonad --restart"),
        ((modm .|. shiftMask, xK_q), io exitSuccess)
    ]

    ++[((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
---------------------------------------------------------------------------------------------------------------------
myWorkspaces = [
    "<fn=2>\xf303  </fn>", -- Arch
    "<fn=2>\xf269  </fn>", -- Browser
    "<fn=2>\xf448  </fn>", -- LaTeX
    "<fn=2>\xf02d  </fn>", -- Book1
    "<fn=2>\xfad9  </fn>", -- Book2
    "<fn=2>\xf753  </fn>", -- Images (TeX)
    "<fn=2>\xf9c6  </fn>", -- Spotify
    "<fn=2>\xf013 </fn>"   -- Config
    ]

myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..]
---------------------------------------------------------------------------------------------------------------------
myStartupHook = do
    spawnOnce "~/.config/scripts/init.sh &"
---------------------------------------------------------------------------------------------------------------------
myManageHook = composeAll
    [
        className =? "reminders"     --> viewShift (myWorkspaces !! 0),
        className =? "discord"       --> viewShift (myWorkspaces !! 0),
        className =? "Google-chrome" --> viewShift (myWorkspaces !! 1),
        className =? "obsidian"      --> viewShift (myWorkspaces !! 2),
        className =? "nvim"          --> viewShift (myWorkspaces !! 2),
        className =? "image"         --> viewShift (myWorkspaces !! 5),
        className =? ""              --> viewShift (myWorkspaces !! 6),
        className =? "sys"           --> viewShift (myWorkspaces !! 7),
        className =? "Pavucontrol"   --> viewShift (myWorkspaces !! 7)
    ]

    where viewShift = doF . liftM2 (.) W.greedyView W.shift
---------------------------------------------------------------------------------------------------------------------
main :: IO ()
main = do
    xmproc <- spawnPipe "xmobar -x 0 /home/zhao/.config/xmonad/xmobarrc"

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
                ppTitle           = xmobarColor "#A8A8AA" "" . shorten 40,
                ppSep             = "<fc=#A8A8AA> | </fc>",
                ppExtras          = [gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset],
                ppOrder           = \(ws:l:t:ex) -> [ws,l]++ex++[t]
            }
}
