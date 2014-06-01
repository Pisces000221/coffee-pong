size =
    width: window.innerWidth - 20
    height: window.innerHeight - 60

Crafty.init size.width, size.height, document.getElementById 'game'
Crafty.background 'RGB(127, 127, 127)'

# Type: ColouredButton
#  Changes its colour when hovered by the mouse, clicked, etc.
Number.prototype.to2digHex = ->
    s = this.toString(16)
    if s.length is 1 then '0' + s else s

Crafty.c 'ColouredButton', {
    _initColour: { r: 0, g: 0, b: 0 }
    _setLightColour: ->
        this.color '#' + ((255 - (255 - v) // 2).to2digHex() for k, v of @_initColour).join ''
    _setOriginalColour: ->
        this.color '#' + (v.to2digHex() for k, v of @_initColour).join ''
    _setDarkColour: ->
        this.color '#' + ((v // 2).to2digHex() for k, v of @_initColour).join ''
    init: ->
        this.requires 'Color, Mouse'
        this.bind 'MouseOver', @_setLightColour
        this.bind 'MouseOut', @_setOriginalColour
        this.bind 'MouseDown', @_setDarkColour
        this.bind 'MouseUp', @_setOriginalColour
    buttonColour: (r, g, b) ->
        @_initColour if not r
        @_initColour = r: r, g: g, b: b
        this._setOriginalColour()
}

# Labels displaying scores
label =
    paddingX: 20
    paddingY: 20
    width: 150
label.updateScore = () ->
    @points++;
    this.tween { alpha: 0.0 }, 200
        .bind 'TweenEnd', () ->
            this.unbind 'TweenEnd'
            this.text "#{@points} point" + (if @points is 1 then '' else 's')
            this.tween { alpha: 1.0 }, 200
label.showBigText = (colour, text) ->
    Crafty.e 'BigText, DOM, 2D, Text, Tween'
        .attr x: 0, y: size.height / 2 - 60, w: size.width, h: 0
        .text text
        .textFont size: '120px'
        .css 'text-align': 'center', 'color': colour
        .tween { alpha: 0.0 }, 1000
        .bind 'TweenEnd', () ->
            this.unbind 'TweenEnd'
            this.undraw()

Crafty.e 'LabelLeft, DOM, 2D, Text, Tween'
    .attr x: label.paddingX, y: label.paddingY, w: label.width, h: 20, points: 0
    .text '0 points'
    .textFont size: '30px'

Crafty.e 'LabelRight, DOM, 2D, Text, Tween'
    .attr x: size.width - label.paddingX - label.width, y: label.paddingY, w: label.width, h: 20, points: 0
    .text '0 points'
    .textFont size: '30px'
    .css 'text-align': 'right'

# Paddles
paddle =
    len: 100
    width: 10
    paddingX: 15
    paddingY: 10
    speed: 90
paddle.maxY = size.height - paddle.len - paddle.paddingY
paddle.movedTrigger = (data) ->
    @_y = if data.y < paddle.paddingY then paddle.paddingY
    else if data.y > paddle.maxY then paddle.maxY
    else @_y

Crafty.e 'Paddle, 2D, DOM, Multiway, Draggable, ColouredButton'
    .buttonColour 255, 0, 0
    .attr x: paddle.paddingX, y: paddle.len, w: paddle.width, h: paddle.len
    .multiway 4, W: -paddle.speed, S: paddle.speed
    .bind 'Moved', paddle.movedTrigger
    .dragDirection x: 0, y: 1

Crafty.e 'Paddle, 2D, DOM, Multiway, Draggable, ColouredButton'
    .buttonColour 0, 255, 0
    .attr x: size.width - paddle.paddingX - paddle.width, y: paddle.len, w: paddle.width, h: paddle.len
    .multiway 4, UP_ARROW: -paddle.speed, DOWN_ARROW: paddle.speed
    .bind 'Moved', paddle.movedTrigger
    .dragDirection x: 0, y: 1

# The ball
ball =
    side: 10
ball.reset = (B) ->
    B.x = size.width / 2
    B.dx = Crafty.math.randomInt(2, 5)
    B.dy = Crafty.math.randomInt(2, 5)
ball.stopResting = () -> this.isResting = false

Crafty.e '2D, DOM, Color, Collision'
    .color 'RGB(0, 0, 255)'
    .attr
        x: size.width / 2, y: size.height / 2, w: ball.side, h: ball.side,
        dx: Crafty.math.randomInt(2, 5),
        dy: Crafty.math.randomInt(2, 5),
        isResting: false
    .bind 'EnterFrame', () ->
        return if @isResting
        @dy = -@dy if @y <= 0 or @y >= size.height - ball.side
        if @x > size.width
            ball.reset(this)
            this.isResting = true
            this.timeout ball.stopResting, 1000
            Crafty('LabelLeft').each label.updateScore
            label.showBigText '#ff0000', 'RED GETS 1 POINT'
        else if @x < ball.side
            ball.reset(this)
            this.isResting = true
            this.timeout ball.stopResting, 1000
            Crafty('LabelRight').each label.updateScore
            label.showBigText '#00ff00', 'GREEN GETS 1 POINT'
        @x += @dx
        @y += @dy
    .onHit 'Paddle', () -> @dx = -@dx

