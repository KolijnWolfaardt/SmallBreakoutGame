
HC = require 'hc'

brickImages= {}
brickParticles = {}
brickFilenames = {"tileBlack_27.png","tileBlue_27.png","tileGreen_27.png","tileGrey_27.png","tileOrange_26.png","tilePink_27.png","tileRed_27.png","tileYellow_27.png"}
numberOfBrickTypes = 8

batImage = nil

brickScale = 0.3
brickWidth = 108
bricksInX = 32
bricksInY = 8

screenWidth = 1600
screenHeight = 900
sidebarWidth = 150

sideOffsets = 50
topOffsets = 38

-- Bat related variables
bat = {}
bat.x = (screenWidth - sidebarWidth)/2
bat.y = screenHeight *0.9
bat.speedX = 0
bat.yOffset = 0

 -- Ball related variables
ball = {}
ball.x = (screenWidth - sidebarWidth)/2
ball.y = screenHeight *0.85
ball.radius = 18
ball.normalSpeed = 600
ball.speedX = ball.normalSpeed*math.cos(0.9275)
ball.speedY = ball.normalSpeed*math.sin(0.9275)
ball.stepsSinceBounce = 5

gameState = {}

listOfBricks = {}
listOfBrickObjects = {}

local text = {}

function love.load()

    loadAssets()
    resetBoard()
end


function resetBoard()

    math.randomseed(os.time())
    pattern = math.random(1, 4)

    for k in pairs (listOfBricks) do
        listOfBricks [k] = nil
    end

    for k in pairs (listOfBrickObjects) do
        listOfBrickObjects [k] = nil
    end
    HC.resetHash() -- Clear all the physics objects

    --Generate all the random bricks
    for i=1,bricksInX do
        listOfBricks[i] = {}
        listOfBrickObjects[i] = {}

        for j=1,bricksInY do
            listOfBricks[i][j] = getPattern(i,j,pattern)
            listOfBrickObjects[i][j] = HC.rectangle(sideOffsets+(i-1)*brickInc,topOffsets+(j-1)*brickInc,brickInc,brickInc)
            listOfBrickObjects[i][j].isBrick = true
            listOfBrickObjects[i][j].i = i
            listOfBrickObjects[i][j].j = j
            listOfBrickObjects[i][j].imageCode = listOfBricks[i][j]
        end
    end

    gameState.gameState = 1
    gameState.difficulty = 1
    gameState.playerLives = 3
    gameState.playerScore = 0
end



function loadAssets()
    --Set the window
    love.window.setFullscreen(false)
    love.window.setMode(1600,900)

    -- Load all the images
    for i=1,numberOfBrickTypes do
        brickImages[i] = love.graphics.newImage("images/" .. brickFilenames[i])
        brickParticles[i] = createParticleSystem(brickImages[i])
    end

    bat.image = love.graphics.newImage("images/paddle_02.png")
    ball.image = love.graphics.newImage("images/ballYellow_05.png")
    coinImage = love.graphics.newImage("images/coin_16.png")

    particleImage = love.graphics.newImage("images/particleWhite_1.png")

    bat.bounceSound = love.audio.newSource("sounds/tone1.ogg","static")

    sidebarImage = love.graphics.newImage("images/sidebar.png")

    brickInc = (screenWidth-sidebarWidth-2*sideOffsets)/bricksInX
    brickScale = brickInc/brickWidth

    love.mouse.setVisible(false)

    love.graphics.setBackgroundColor(30,30,30)

    -- Set up the collision mechanics
    bat.object = HC.rectangle(200,200,bat.image:getWidth()*brickScale,bat.image:getHeight()*brickScale)
    bat.object:moveTo(love.mouse.getX(),bat.y)

    ball.object = HC.circle(ball.x,ball.y,ball.radius)

    ball.particleEngine = createParticleSystem(particleImage)
    ball.particleEngine:setEmissionRate(30)
    partSystem:setLinearAcceleration(-20, -20, 20, 20)
    partSystem:setParticleLifetime(0.8, 1.0)
    partSystem:setSizes(0.05,0.02,0.01,0.005)

    arialFont = love.graphics.newFont("prototype_font/Prototype.ttf",22)
    scoreText = love.graphics.newText(arialFont,"Score :")
    scoreNumber = love.graphics.newText(arialFont,"0")
end



function createParticleSystem(image)

    partSystem = love.graphics.newParticleSystem(image,60)
    partSystem:setParticleLifetime(0.2, 1.0)
    partSystem:setSizeVariation(0)
    partSystem:setSizes(0.1,0.05,0.02,0.01)
    partSystem:setSpinVariation(0.8)
    partSystem:setRotation(0,10,20)
    partSystem:setAreaSpread("normal",10,10)
    --partSystem:setRadialAcceleration(500,800)
    partSystem:setOffset(111,111)

    partSystem:setLinearAcceleration(-200, -200, 200, 200)

    return partSystem
end

function getPattern(x,y,number)
    if number == 1 then
        return math.floor(((x-y)*0.5)%numberOfBrickTypes+1)
    elseif number == 2 then
        return math.floor(((x+y)*0.5)%numberOfBrickTypes+1)
    elseif number == 3 then
        if (x%2 == 0) then
            if (y%2 == 0) then
                return 5
            else
                return 2
            end
        else
            if (y%2 == 0) then
                return 3
            else
                return 4
            end
        end
    elseif number == 4 then
        if (x%3 ==0) or (y%3 == 0) then
            if (x%3 ==0) and (y%3 == 0) then
                return 8
            else
                return 5
            end
        else 
            return 1
        end
    end
end

function love.update(dt)

    bat.speedX = 0.8* (bat.x-love.mouse.getX()) + 0.2 * bat.speedX

    --Set the paddle position equal to the mouse position
    bat.x = love.mouse.getX()

    if gameState.gameState == 2 then
        ball.x = ball.x + ball.speedX*dt
        ball.y = ball.y + ball.speedY*dt

        if (ball.x+ball.radius > screenWidth-sidebarWidth) then
            if (ball.speedX > 0) then
                ball.speedX = - ball.speedX
                decrementBallSpeed()
            end
        end
        if (ball.x-ball.radius < 0) then
            if (ball.speedX < 0) then
                ball.speedX = - ball.speedX
                decrementBallSpeed()
            end
        end
        if (ball.y > screenHeight+ball.radius) then
            -- Lose a life
            gameState.gameState = 1
            gameState.playerLives = gameState.playerLives - 1

            if (gameState.playerLives == -1) then

                resetBoard()
                return
            end
        end
        if (ball.y-ball.radius < 0) then
            if (ball.speedY < 0) then
                ball.speedY = - ball.speedY
                decrementBallSpeed()
            end
        end

        -- ballSpeed = ballSpeed - 0.1
        if (bat.yOffset > 0) then
            bat.yOffset = bat.yOffset - 0.6
        end
    elseif gameState.gameState == 1 then
        ball.x = love.mouse.getX()
        ball.y = bat.y-ball.radius*3
    end
    -- Update the physics objects
    bat.object:moveTo(love.mouse.getX(),bat.y)
    ball.object:moveTo(ball.x,ball.y)
    ball.particleEngine:moveTo(ball.x,ball.y)

    if ball.stepsSinceBounce == 0 then
    -- Check if the ball collides with the bal
        for shape, delta in pairs(HC.collisions(bat.object)) do 
            -- use the collision vector to calculate the new angle

            bounceBall(delta,true)
            ball.stepsSinceBounce = 20
            bat.bounceSound:play()

            bat.yOffset = 4
        end
    else
        ball.stepsSinceBounce = ball.stepsSinceBounce -1
    end

    nextFunction,collisionTable = pairs(HC.collisions(ball.object))
     
    if (next(collisionTable) ~= nil) then
        shape, delta = nextFunction(collisionTable,nil)
    
    --for shape, delta in pairs(HC.collisions(ballCircle)) do
        if ((delta.x^2 + delta.y^2) > 0.1) then
            if (shape.isBrick == true) then

                i = shape.i
                j = shape.j

                --bounce the ball
                if (ball.stepsSinceBounce == 0) then
                   bounceBall(delta,false)

                   pSystem  = brickParticles[listOfBricks[i][j]]
                   pSystem:setPosition(sideOffsets+(i-0.5)*brickInc,topOffsets+(j-0.5)*brickInc)
                   pSystem:emit(20)
                   --ball.stepsSinceBounce = 1
                end

                gameState.playerScore = gameState.playerScore + 1

                listOfBricks[i][j] = 0
                listOfBrickObjects[i][j] = nil
                HC.remove(shape)
            end
        end

    end

    while #text > 40 do
        table.remove(text, 1)
    end   

    for i=1,numberOfBrickTypes do
        brickParticles[i]:update(dt)
    end
    ball.particleEngine:update(dt)

end

function bounceBall(distVector,withBat)
    angle = math.atan2(distVector.y,distVector.x)
    currentBallAngle =  math.atan2(ball.speedY,ball.speedX)
    newAngle = angle + (angle - currentBallAngle)

    if (withBat == true) then
        batSpeedInfluence = -((math.atan(bat.speedX*0.1))/math.pi)*0.9
        possibleAngle = (math.pi - newAngle)*batSpeedInfluence

        -- Check that the bat speed does not push the angle negative

        newAngle = (newAngle + possibleAngle) % (math.pi*2)
        --text[#text+1] = string.format("NewAngle is " .. math.deg(newAngle) ..". Bat influence was " .. math.deg(batSpeedInfluence))

        --if batSpeedInfluence > 0 then
        --    ballSpeed = ballSpeed + math.abs(0.8*batSpeedX)
        --else
        --    ballSpeed = ballSpeed - math.abs(0.8*batSpeedX)
        --end
        --text[#text+1] = string.format("Batspeed " .. batSpeedX .. "  influence is " .. math.deg(batSpeedInfluence))
        --text[#text+1] = string.format("Ballspeed " .. ballSpeed .. "  influence is " .. batSpeedInfluence .. " | " .. 0.8*batSpeedX)
    end

    while math.abs(newAngle%math.pi) < 0.09 do
        newAngle = newAngle *1.5
        -- text[#text+1] = string.format("Correction performed to " .. math.deg(newAngle))
    end

    ball.speedX = -math.cos(newAngle)* ball.normalSpeed
    ball.speedY = -math.sin(newAngle)* ball.normalSpeed
    
end


function love.draw()
    -- Draw the bricks
    for i=1,bricksInX do
        for j=1,bricksInY do
            brickType = listOfBricks[i][j]

            if brickType > 0 then
                love.graphics.draw(brickImages[brickType],sideOffsets+(i-1)*brickInc,topOffsets+(j-1)*brickInc,0,brickScale,brickScale,0,0)
            end
        end
    end
    --love.graphics.setColor(150,255,180)
    --bat.object:draw('fill')

    --love.graphics.setColor(220,70,60)
    --ball.object :draw('line')

    love.graphics.setColor(255,255,255)

    --draw the bat
    love.graphics.draw(bat.image,bat.x,bat.y+bat.yOffset,0,brickScale,brickScale,320,70)
        
    -- draw the ball
    love.graphics.draw(ball.image,ball.x,ball.y,0,brickScale,brickScale,64,64)

    for i = 1,#text do
        love.graphics.setColor(255,255,255, 255 - (i-1) * 6)
        love.graphics.print(text[#text - (i-1)], 10, i * 15)
    end

    love.graphics.setColor(255,255,255, 140)
    for i=1,numberOfBrickTypes do
        love.graphics.draw(brickParticles[i],0,0)
    end
    love.graphics.draw(ball.particleEngine,0,0)

    love.graphics.setColor(255,255,255, 255)
    sideBarPos = screenWidth-sidebarWidth
    love.graphics.draw(sidebarImage,sideBarPos,0,0,1,10)

    love.graphics.setColor(229,58,58)
    love.graphics.draw(scoreText,sideBarPos+20,40)
    scoreNumber:set(gameState.playerScore)
    love.graphics.draw(scoreNumber,sideBarPos+scoreText:getWidth(),60)
    love.graphics.setColor(255,255,255)

    for i=1,gameState.playerLives do
        love.graphics.draw(bat.image,sideBarPos+32,400+32*i,0,0.16,0.16)
    end
end


function love.keypressed(key)
end


function love.keyreleased(key)
end

function decrementBallSpeed()
    --ball.normalSpeed = ball.normalSpeed - 10
    --if (ball.normalSpeed < 400) then
    --    ball.normalSpeed = 400
    --end
end


function love.mousepressed(x,y,button,istouch)
    if gameState.gameState == 1 then
        gameState.gameState = 2

        -- calculate the required angle for the ball
        ball.speedX = -bat.speedX*14
        if (ball.speedX > 0.9*ball.normalSpeed) then
            ball.speedX = 0.9*ball.normalSpeed
        elseif (ball.speedX < -0.9*ball.normalSpeed) then
            ball.speedX = -0.9*ball.normalSpeed
        end
        ball.speedY = -math.sqrt(ball.normalSpeed^2 - ball.speedX^2)
    end    
end