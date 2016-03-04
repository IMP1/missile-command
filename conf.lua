function love.conf(game)
    game.window.title = "Meteor Defence"
    game.window.icon = "icon.png"
    game.window.width = 800
    game.window.height = 800
    game.console = false
    
    game.modules.joystick = false
    game.modules.physics  = false
    game.modules.math     = false
    game.modules.system   = false
    game.modules.thread   = false
end