// at input.conf: KEY script-message cycle-cmd "CMD1" "CMD2" ...
// then pressing KEY cycles CMD1 -> CMD2 ->... CMD1 -> CMD2 ->...
// different keys can be bound to cycle diffrent sets of commands
// by avih

var registry = {};

mp.register_script_message("cycle-cmd", function() {
    var key = JSON.stringify(arguments);
    if (!(registry[key] >= 0))
        registry[key] = -1;
    
    registry[key] = (registry[key] + 1) % arguments.length;
    mp.command(arguments[registry[key]]);
});
