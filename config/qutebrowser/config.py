# Don't load autoconfig.yml
config.load_autoconfig(False)

# Colors
config.set("colors.webpage.bg", "#1e2127")
config.set("colors.messages.info.bg", "#1e2127")
config.set("colors.messages.warning.bg", "#1e2127")
config.set("colors.messages.error.bg", "#1e2127")
config.set("colors.messages.info.border", "#1e2127")
config.set("colors.messages.warning.border", "#1e2127")
config.set("colors.messages.error.border", "#1e2127")
config.set("colors.prompts.bg", "#1e2127")
config.set("colors.statusbar.url.fg", "#a8a8aa")
config.set("colors.statusbar.normal.fg", "#a8a8aa")
config.set("colors.statusbar.normal.bg", "#1e2127")
config.set("colors.statusbar.insert.fg", "#a8a8aa")
config.set("colors.statusbar.insert.bg", "#1e2127")
config.set("colors.statusbar.command.fg", "#a8a8aa")
config.set("colors.statusbar.command.bg", "#1e2127")
config.set("colors.statusbar.url.hover.fg", "#f8f8ff")
config.set("colors.statusbar.url.success.http.fg", "#a8a8aa")
config.set("colors.statusbar.url.success.https.fg", "#a8a8aa")
config.set("colors.tabs.bar.bg", "#1e2127")
config.set("colors.tabs.even.bg", "#1e2127")
config.set("colors.tabs.odd.bg", "#1e2127")
config.set("colors.tabs.even.fg", "#a8a8a8")
config.set("colors.tabs.odd.fg", "#a8a8a8")
config.set("colors.tabs.selected.even.bg", "#1e2127")
config.set("colors.tabs.selected.odd.bg", "#1e2127")
config.set("colors.tabs.selected.even.fg", "#f8f8ff")
config.set("colors.tabs.selected.odd.fg", "#f8f8ff")
config.set("colors.downloads.bar.bg", "#1e2127")

# Fonts
config.set("fonts.default_family", "Anonymous Pro")
config.set("fonts.default_size", "15pt")
config.set("fonts.tabs.selected", "bold default_size default_family")
config.set("fonts.tabs.unselected", "bold default_size default_family")
config.set("fonts.statusbar", "bold default_size default_family")

# Tabs and statusbar
config.set("statusbar.show", "always")
config.set("tabs.show", "multiple")
config.set("tabs.favicons.scale", 0.9)
config.set("tabs.indicator.width", 0)
config.set("tabs.max_width", 350)
config.set("tabs.padding", {"bottom": 5, "left": 5, "right": 5, "top": 0})

# Default programs
config.set("editor.command", ['alacritty', '-e', 'nvim', '{}'])
config.set("fileselect.handler", "external")
config.set("fileselect.single_file.command", ['alacritty', '-e', 'vifm', '--choose-files={}'])
config.set("fileselect.multiple_files.command", ['alacritty', '-e', 'vifm', '--choose-files={}'])

# Open mpv
config.bind('<Meta+m>', 'hint links spawn -d mpv --ytdl-raw-options=\'sub-lang="en,eng,enUS,en-US",write-auto-sub=,write-sub=,cookies=~/.config/cookies_Z.txt,mark-watched=\' {hint-url} &')

# Search engines
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'wk': 'https://en.wikipedia.org/wiki/{}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'se': 'https://math.stackexchange.com//search?q={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
    'mf': 'https://myflixer.to/search/{}',
    'lg': 'https://libgen.is/search.php?req={}'}

# Download
config.set("downloads.remove_finished", 1000)
config.set("downloads.location.directory", "~/Downloads")
config.set("downloads.prevent_mixed_content", False)

# Zoom
config.set("zoom.default", "100%")
config.bind('<Meta+=>', 'zoom-in')
config.bind('<Meta+->', 'zoom-out')
config.bind('<Meta+0>', 'zoom 100')

# Toggle bars
config.bind('<Meta+`>', 'config-cycle statusbar.show always never;; config-cycle tabs.show multiple never')

# Tab control
config.bind('<Meta+u>', 'undo')
config.bind('<Meta+h>', 'back')
config.bind('<Meta+l>', 'forward')
config.bind('<Meta+j>', 'tab-prev')
config.bind('<Meta+k>', 'tab-next')
config.bind('<Meta+w>', 'tab-close')
for i in range (1, 9):
    config.bind('<Meta+' + str(i) + '>', 'tab-select ' + str(i))
    config.bind('<Meta+F' + str(i) + '>', 'tab-move ' + str(i))

# Restart
config.bind('<Meta+r>', 'restart')

# Auto load images
config.set('content.images', True, 'chrome-devtools://*')
config.set('content.images', True, 'devtools://*')

# Scrolling
config.set('scrolling.smooth', True)

# Enable javascript
config.set('content.javascript.enabled', True, 'chrome-devtools://*')
config.set('content.javascript.enabled', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome://*/*')
config.set('content.javascript.enabled', True, 'qute://*/*')

# Certificate
config.set('content.tls.certificate_errors', 'block')
