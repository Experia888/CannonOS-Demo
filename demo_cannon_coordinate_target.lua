--[[
 - Automatic Coordinate Targeting System Demo Project
 - Authors: Experia888 (GitHub: https://github.com/Experia888), Priton (GitHub: https://github.com/Priton-CE)
 - GitHub: https://github.com/Experia888/CannonOS-Demo
 - Purpose: Warcrimes
]]--

--GUIDE & SETTINGS

--Thank you for using the Automatic Coordinate Targeting System!
--To begin, adjust these settings to fit your cannon:

local powderCharges = 8 --Number of powder charges. This code assumes you get the maximum velocity from each powder charge
local rpm = 4 --RPM for rotating cannon pitch and yaw (recommended 4, only the cannon pitch and yaw have to use this speed)
local reloadTime = 15 --Time in seconds for your cannon to reload, if you want to use computercraft to automate your reload, implement it in reloadCannon()
local barrelLength = <TODO: Lenght Here> --Length of barrel in blocks from the cannon location to the tip
local cannonLocationX,cannonLocationY,cannonLocationZ = <x>,<y>,<z> --X,Y,Z coordinates of your cannon.
local offsetAngle = -180 --This cannon points east by default
local projectileAccuracy = 0.001 --Distance accuracy (lower numbers are more accurate. too low and it'll time out, too high and you will miss by 39 nautical miles)

--Next, you will need to setup your cannon with 5 redstone inputs:

--Yaw Clutch        
--Pitch Clutch      
--Fire              
--Reload            
--Build             

--Assign them to these faces on the redstone integrator, or change the faces if you want:

local redstoneOutputs = {} --Sets up the redstoneOutputs table. No need to touch this

redstoneOutputs['yaw'] = 'back'
redstoneOutputs['reload'] = 'front'
redstoneOutputs['fire'] = 'right'
redstoneOutputs['pitch'] = 'left'
redstoneOutputs['build'] = 'bottom'

--This program is set up by default to use a single redstone integrator from advanced peripherals to output redstone signals, but you can modify the code to do anything you want with the output functions, or just the outputs on the computer itself.
--You can change this in the 'Redstone Functions' section.

--The code is meant to be very easy to modify if you're new to Lua so it's a little bloated in some areas.
--Happy shooting! - Experia888, Priton

--variables
local projectileVelocity = (powderCharges*20)

--declare integrators
local redstoneIntegrator
-- assign integrators to variables (useful if you want to use more than 1 integrator)
local integrators = peripheral.find("redstoneIntegrator",function(name,object)
    object.setOutput('front',false)
    object.setOutput('back',false)
    object.setOutput('left',false)
    object.setOutput('right',false)
    object.setOutput('top',false)
    object.setOutput('bottom',false)
 
    if name == "redstoneIntegrator_11" then
        redstoneIntegrator = object
    end
end)

--------------------------------------------------------------------------------
--                             interface functions
--------------------------------------------------------------------------------
local function inputQuestion(question,questionType,termColour,typeColour)
    if typeColour ~= nil then
        term.setTextColor(termColour)
   end
    print(question)
    if questionType == 'bool' then
        if typeColour ~= nil then
             term.setTextColor(typeColour)
        end
        local questionInput = read()
        term.setTextColor(colors.white)
        if questionInput == 'y' or questionInput == 'Y' or questionInput == 'yes' or questionInput == 'Yes' then
            return true
        elseif questionInput == 'n' or questionInput == 'N' or questionInput == 'no' or questionInput == 'No' then
            return false
        else
            print('\nInvalid input, please try again.\n')
            return inputQuestion(question,questionType)
        end
    end
end

--------------------------------------------------------------------------------
--     redstone functions (what happens when you want to output redstone)
--------------------------------------------------------------------------------
--yaw output
local function outputYaw(bool)
    redstoneIntegrator.setOutput(redstoneOutputs['yaw'],bool)
end

--reload output
local function outputReload(bool)
    redstoneIntegrator.setOutput(redstoneOutputs['reload'],bool)
end

--fire output
local function outputFire(bool)
    redstoneIntegrator.setOutput(redstoneOutputs['fire'],bool)
end

--pitch output
local function outputPitch(bool)
    redstoneIntegrator.setOutput(redstoneOutputs['pitch'],bool)
end

--build output
local function outputBuild(bool)
    redstoneIntegrator.setOutput(redstoneOutputs['build'],bool)
end

--------------------------------------------------------------------------------
--                            cannon functions
--------------------------------------------------------------------------------

local function rotateCannonPitch(angle)
    term.setTextColor(colors.yellow)
    local calculatedTime = ((((angle)/360)*60)*8)/rpm
    print('\nRotating cannon pitch by:',angle..'°\nRotating for',calculatedTime,'seconds.')
    term.setTextColor(colors.white)
    outputPitch(true)
    sleep(calculatedTime)
    outputPitch(false)
    sleep(1)
end

local function rotateCannonYaw(angle)
    term.setTextColor(colors.yellow)
    local calculatedTime = (((math.abs(angle)/360)*60)*8)/rpm
    print('\nRotating cannon yaw by:',-angle..'°\nRotating for',calculatedTime,'seconds.')
    term.setTextColor(colors.white)
    outputYaw(true)
    sleep(calculatedTime)
    outputYaw(false)
    sleep(1)
end

local function reloadCannon(shell)
    --reload sequence--
    outputBuild(false)
    sleep(1)
    outputReload(true)
    sleep(1)
    outputReload(false)
    sleep(reloadTime)

    --onFinish
    term.setTextColor(colors.green)
    print('\nReloaded!\n')
    term.setTextColor(colors.white)
end

local function calculateTargetData(targetX, targetY, targetZ, cannonLocationX, cannonLocationY, cannonLocationZ, accuracy)
    -- input selfmade trajectories library (contribution of Priton)
    local trajectories = require("trajectories")

    --target distance calculation
    local targetDistance = math.floor((((targetX-cannonLocationX)^2)+((targetY-cannonLocationY)^2)+((targetZ-cannonLocationZ)^2))^0.5)

    --angle calculation
    local yawAngle = -(math.deg(math.atan2(cannonLocationZ-targetZ,cannonLocationX-targetX))-offsetAngle)
    local pitchAngle, ticks = trajectories.determine_pitch(projectileVelocity, targetDistance, cannonLocationY - targetY, barrelLength, accuracy)

    return yawAngle, pitchAngle, targetDistance, ticks
end

--------------------------------------------------------------------------------
--                      main function in a loop
--------------------------------------------------------------------------------

function routine()
    --get input datas
    print('Please input target data:')
    print('X:')
    local targetX = read()
    print('Y:')
    local targetY = read()
    print('Z:')
    local targetZ = read()

    term.setTextColor(colors.lightBlue)
    print('\nTarget coordinates selected:',targetX..', '..targetY..', '..targetZ..'\n')

    local yawAngle, pitchAngle, targetDistance, ticks = calculateTargetData(targetX,targetY,targetZ,cannonLocationX,cannonLocationY,cannonLocationZ,projectileAccuracy)
    sleep(1)

    local seconds = math.floor(ticks / 20)
    local tick_steps = ticks - (seconds*20)

    term.setTextColor(colors.orange)
    print('Distance to target:',targetDistance..'m\nHeight Difference: '..cannonLocationY - targetY..'m\nYaw angle:',-yawAngle..'°\n'..'Pitch angle:',pitchAngle..'°\n'..'flight time:',seconds..' s and '..tick_steps..' ticks\n')
    term.setTextColor(colors.white)

    if pitchAngle >= 60 or pitchAngle <= 0 then
        term.setTextColor(colors.red)
        print('\nWarning: Unusual cannon pitch angles, firing arc may be very inaccurate!\n')
        term.setTextColor(colors.white)
    end

    if inputQuestion('\nLoad cannon? (y/n)','bool',colors.white,colors.white) == true then
        --check if loaded (only works if set up with rose quartz lamps)
        local loadBool = redstoneIntegrator.getInput('front')
        if loadBool == true then
            if inputQuestion('\nCannon is already loaded! Override? (y/n)','bool',colors.red,colors) == true then
                term.setTextColor(colors.green)
                print('\nReloading!\n')
                term.setTextColor(colors.white)
                reloadCannon('explosive')
            end
        else
            term.setTextColor(colors.green)
            print('\nReloading!\n')
            term.setTextColor(colors.white)
            reloadCannon('explosive')
        end
    end

    if inputQuestion('\nAim cannon? (y/n)','bool') == true then
        --target cannon
        outputBuild(false)
        sleep(3)
        outputBuild(true)
        sleep(3)
        rotateCannonYaw(yawAngle)
        rotateCannonPitch(pitchAngle)
        sleep(1)

        if inputQuestion('\nFire cannon? (y/n)','bool',colors.red,colors.orange) == true then
            term.setTextColor( colors.orange)
            print('\nFiring in:')
            term.setTextColor( colors.red)
            print('3')
            sleep(1)
            print('2')
            sleep(1)
            print('1')
            sleep(1)
            print('Cannon ignited!')
            outputFire(true)
            sleep(1)
            outputFire(false)
        end
    end
    term.setTextColor( colors.white)
    sleep(5)
    sleep()
end

--run program

while true do
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.blue)
    print("\nWelcome to the Automatic Coordinate Targeting System.\n")
    term.setTextColor(colors.gray)
    print("Booting up...\n")
    term.setTextColor(colors.white)
    routine()
end
