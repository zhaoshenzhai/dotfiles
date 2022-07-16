# Don't load autoconfig.yml
config.load_autoconfig(False)

# Colors
config.set("colors.webpage.bg", "#1e2127")
config.set("colors.statusbar.url.fg", "#a8a8aa")
config.set("colors.statusbar.normal.fg", "#a8a8aa")
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

# Open mpv
config.bind('<Meta+m>', 'hint links spawn -d mpv --ytdl-raw-options=\'sub-lang="en",write-auto-sub=,cookies=~/.config/cookies_Z.txt,mark-watched=\' {hint-url} &')

# Search engines
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'wk': 'https://en.wikipedia.org/wiki/{}',
    'yt': 'https://www.youtube.com/results?search_query={}',
    'mse': 'https://math.stackexchange.com//search?q={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
    'mf': 'https://myflixer.to/search/{}'}

# Download
config.set("downloads.remove_finished", 1000)
config.set("downloads.location.directory", "~/Downloads")

# Zoom
config.set("zoom.default", "125%")
config.bind('<Meta+=>', 'zoom-in')
config.bind('<Meta+->', 'zoom-out')
config.bind('<Meta+0>', 'zoom 125')

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
config.bind('<Meta+q>', 'restart')

# Auto load images
config.set('content.images', True, 'chrome-devtools://*')
config.set('content.images', True, 'devtools://*')

# Enable javascript
config.set('content.javascript.enabled', True, 'chrome-devtools://*')
config.set('content.javascript.enabled', True, 'devtools://*')
config.set('content.javascript.enabled', True, 'chrome://*/*')
config.set('content.javascript.enabled', True, 'qute://*/*')
