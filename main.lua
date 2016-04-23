
HC = require 'hc'

brickImages= {}
brickFilenames = {"tileBlack_27.png","tileBlue_27.png","tileGreen_27.png","tileGrey_27.png","tileOrange_26.png","tilePink_27.png","tileRed_27.png","tileYellow_27.png"}
numberOfBrickTypes = 8

batImage = nil

brickScale = 0.3
brickWidth = 108
bricksInX = 40
bricksInY = 10

screenWidth = 1600
screenHeight = 900

sideOffsets = 200

listOfBricks = {}
listOfBrickObjects = {}

-- bat related variables
batX = screenWidth/2
batY = screenHeight *0.9

batSpeedX = 0

 -- Ball related variables
ballX = screenWidth/2
ballY = screenHeight *0.85

ballradius = 18

ballSpeed = 600
ballSpeedX = ballSpeed*math.cos(0.9275)
ballSpeedY = ballSpeed*math.sin(0.9275)

ballStepsSinceBounce = 5
batSpeedX = 0
local text = {}

function love.load()
    --Set the window
    love.window.setFullscreen(false)
    love.window.setMode(1600,900)

    -- Load all the images
    for i=1,numberOfBrickTypes do
        brickImages[i] = love.graphics.newImage("images/" .. brickFilenames[i])
    end

    batImage = love.graphics.newImage("images/paddle_02.png")
    ballImage = love.graphics.newImage("images/ballYellow_05.png")
    coinImage = love.graphics.newImage("images/coin_16.png")

    brickInc = (screenWidth-2*sideOffsets)/bricksInX
    brickScale = brickInc/brickWidth

    --Generate all the random bricks
    for i=1,bricksInX do
        listOfBricks[i] = {}
        listOfBrickObjects[i] = {}

        for j=1,bricksInY do
            listOfBricks[i][j] = getPattern(i,j,1)
            listOfBrickObjects[i][j] = HC.rectangle(sideOffsets+(i-1)*brickInc,sideOffsets+(j-1)*brickInc,brickInc,brickInc)
            listOfBrickObjects[i][j].isBrick = true
            listOfBrickObjects[i][j].i = i
            listOfBrickObjects[i][j].j = j
        end
    end

    love.graphics.setBackgroundColor(10,10,10)

    -- Set up the collision mechanics
    batRectangle = HC.rectangle(200,200,200,38)
    batRectangle:moveTo(love.mouse.getX(),batY)

    ballCircle = HC.circle(ballX,ballY,ballradius)
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

    end
end

function love.update(dt)

    batSpeedX = 0.8* (batX-love.mouse.getX()) + 0.2 * batSpeedX

    --Set the paddle position equal to the mouse position
    batX = love.mouse.getX()

    ballX = ballX + ballSpeedX*dt
    ballY = ballY + ballSpeedY*dt

    if (ballX+ballradius > screenWidth) then
        if (ballSpeedX > 0) then
            ballSpeedX = - ballSpeedX
            decrementBallSpeed()
        end
    end
    if (ballX-ballradius < 0) then
        if (ballSpeedX < 0) then
            ballSpeedX = - ballSpeedX
            decrementBallSpeed()
        end
    end
    if (ballY+ballradius > screenHeight) then
        if (ballSpeedY > 0) then
            ballSpeedY = - ballSpeedY
            decrementBallSpeed()
        end
    end
    if (ballY-ballradius < 0) then
        if (ballSpeedY < 0) then
            ballSpeedY = - ballSpeedY
            decrementBallSpeed()
        end
    end

    -- ballSpeed = ballSpeed - 0.1

    -- Update the physics objects
    batRectangle:moveTo(love.mouse.getX(),batY)
    ballCircle:moveTo(ballX,ballY)

    if ballStepsSinceBounce == 0 then
    -- Check if the ball collides with the bal
        for shape, delta in pairs(HC.collisions(batRectangle)) do 
            -- use the collision vector to calculate the new angle

            bounceBall(delta,true)

            ballStepsSinceBounce = 20
        end
    else
        ballStepsSinceBounce = ballStepsSinceBounce -1
    end

    nextFunction,collisionTable = pairs(HC.collisions(ballCircle))
     
    if (next(collisionTable) ~= nil) then
        shape, delta = nextFunction(collisionTable,nil)
    
    --for shape, delta in pairs(HC.collisions(ballCircle)) do
        if ((delta.x^2 + delta.y^2) > 0.1) then
            if (shape.isBrick == true) then
                i = shape.i
                j = shape.j
                listOfBricks[i][j] = 0
                listOfBrickObjects[i][j] = nil
                HC.remove(shape)

                --bounce the ball
                if (ballStepsSinceBounce == 0) then
                   bounceBall(delta,false)
                   --ballStepsSinceBounce = 1
                end
            end
        end

    end

    while #text > 40 do
        table.remove(text, 1)
    end   

end

function bounceBall(distVector,withBat)
    angle = math.atan2(distVector.y,distVector.x)
    currentBallAngle =  math.atan2(ballSpeedY,ballSpeedX)
    newAngle = angle + (angle - currentBallAngle)

    if (withBat == true) then
        batSpeedInfluence = -(math.atan(batSpeedX*0.05))
        if batSpeedInfluence > 1.1 then
            batSpeedInfluence = 1.1
        end
        if batSpeedInfluence < -1.1 then
            batSpeedInfluence = -1.1
        end

        newAngle = newAngle + batSpeedInfluence

        --if batSpeedInfluence > 0 then
        --    ballSpeed = ballSpeed + math.abs(0.8*batSpeedX)
        --else
        --    ballSpeed = ballSpeed - math.abs(0.8*batSpeedX)
        --end
        --text[#text+1] = string.format("Batspeed " .. batSpeedX .. "  influence is " .. math.deg(batSpeedInfluence))
        --text[#text+1] = string.format("Ballspeed " .. ballSpeed .. "  influence is " .. batSpeedInfluence .. " | " .. 0.8*batSpeedX)
    end

    while math.abs(newAngle%math.pi) < 0.05 do
        newAngle = newAngle *1.5
        text[#text+1] = string.format("Correction performed to " .. newAngle)
    end

    ballSpeedX = -math.cos(newAngle)* ballSpeed
    ballSpeedY = -math.sin(newAngle)* ballSpeed
    
end


function love.draw()
    -- Draw the bricks
    for i=1,bricksInX do
        for j=1,bricksInY do
            brickType = listOfBricks[i][j]

            if brickType > 0 then
                love.graphics.draw(brickImages[brickType],sideOffsets+(i-1)*brickInc,sideOffsets+(j-1)*brickInc,0,brickScale,brickScale,0,0)
            end
        end
    end
    love.graphics.setColor(150,255,180)
    batRectangle:draw('fill')

    love.graphics.setColor(220,70,60)
    ballCircle:draw('line')

    love.graphics.setColor(255,255,255)

    --draw the bat
    love.graphics.draw(batImage,batX,batY,0,brickScale,brickScale,320,70)
        
    -- draw the ball
    love.graphics.draw(ballImage,ballX,ballY,0,brickScale,brickScale,64,64)

    for i = 1,#text do
        love.graphics.setColor(255,255,255, 255 - (i-1) * 6)
        love.graphics.print(text[#text - (i-1)], 10, i * 15)
    end
end


function love.keypressed(key)
end


function love.keyreleased(key)
end

function decrementBallSpeed()
    --ballSpeed = ballSpeed - 10
    --if (ballSpeed < 400) then
    --    ballSpeed = 400
    --end
end
