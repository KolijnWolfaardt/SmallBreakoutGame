

brickImages= {}
brickFilenames = {"tileBlack_27.png","tileBlue_27.png","tileGreen_27.png","tileGrey_27.png","tileOrange_26.png","tilePink_27.png","tileRed_27.png","tileYellow_27.png"}
numberOfBrickTypes = 8

batImage = nil

brickScale = 0.3
brickWidth = 108
bricksInX = 50
bricksInY = 15

screenWidth = 1920
screenHeight = 1080

sideOffsets = 40

listOfBricks = {}

batX = screenWidth/2
batY = screenHeight *0.9

ballX = screenWidth/2
ballY = screenHeight *0.85

ballSpeedX = 5
ballSpeedY = -5

ballradius = 21

function love.load()
    --Set the window
    love.window.setFullscreen(true)
    love.window.maximize()


    -- Load all the images
    for i=1,numberOfBrickTypes do
        brickImages[i] = love.graphics.newImage("images/" .. brickFilenames[i])
    end

    batImage = love.graphics.newImage("images/paddle_02.png")
    ballImage = love.graphics.newImage("images/ballYellow_05.png")
    coinImage = love.graphics.newImage("images/coin_16.png")

    brickInc = (screenWidth-2*sideOffsets)/bricksInX
    brickScale = brickInc/brickWidth

    print ("Scale is " .. brickScale)

    --Generate all the random bricks
    for i=1,bricksInX do
        listOfBricks[i] = {}

        for j=1,bricksInY do
            listOfBricks[i][j] = getPattern(i,j,3)
        end
    end

    love.graphics.setBackgroundColor(10,10,10)

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
    --Set the paddle position equal to the mouse position
    batX = love.mouse.getX()

    ballX = ballX + ballSpeedX
    ballY = ballY + ballSpeedY

    if (ballX+ballradius > screenWidth) then
        ballSpeedX = - ballSpeedX
    end
    if (ballX-ballradius < 0) then
        ballSpeedX = - ballSpeedX
    end
    if (ballY+ballradius > screenHeight) then
        ballSpeedY = - ballSpeedY
    end
    if (ballY-ballradius < 0) then
        ballSpeedY = - ballSpeedY
    end

    -- Check if the ball collides with the bal
    if (ballSpeedY>0) then
        if (ballX > batX-40 and ballX < batX+40) then
            if math.abs(ballY+ballradius - batY) < 3 then
                ballSpeedY = - ballSpeedY
            end
        end
    end

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

    --draw the bat
    love.graphics.draw(batImage,batX,batY,0,brickScale,brickScale,320,70)
        
    -- draw the ball
    love.graphics.draw(ballImage,ballX,ballY,0,brickScale,brickScale,64,64)
    
end


function love.keypressed(key)
end


function love.keyreleased(key)
end
