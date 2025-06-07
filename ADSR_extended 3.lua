-- Created by Fabian Martinez aka Jodok31283
-- Date: 2023-10-01 
-- Version: 3.0
-- Description:
-- This script implements an ADSR envelope generator with additional features:
-- ° User-defined trigger voltages and durations for EoA, EoD, EoS, EoR (1V and 1ms resolution)
-- ° Added "Offset" parameter for CV output with 1 mV resolution    
-- ° Added "Inverted Envelope" option
-- ° Loop functionality with pause and counting
-- ° Linear and Exponential modes for envelope calculation
-- ° Customizable loop modes (ADSR, AD, AR)
-- ° Semitone adjustment for CV output
-- ° Clean code and comments for easy understanding


--==========================================================================
-- This script is designed for a modular synthesizer environment
-- PARAMETERS:
-- Attack 1ms to 30s with 1ms resolution
-- Decay 1ms to 30s with 1ms resolution 
-- Sustain 0% to 100% with 1% resolution
-- Release 1ms to 30s with 1ms resolution
-- EoA, EoD, EoS, EoR voltages 0V to 10V with 1V resolution
-- EoA, EoD, EoS, EoR durations 1ms to 5s with 1ms resolution
-- Offset in mV from -10V to +10V with 1mV resolution
-- Semitone adjustment from -120 to +120 with 1 semitone resolution equals to -10V to +10V
-- Inverted Envelope option (Normal/Inv)
-- Loop On/Off with pause and counting
-- Loop Mode (ADSR, AD, AR)
-- Inputs: Gate
-- Outputs: Envelope, EoA, EoD, EoS, EoR, CV mV, Pitch

---=====================================================================
-- PHASE DEFINITIONS
local IDLE = -1
local ATTACK = 0
local DECAY = 1
local SUSTAIN = 2
local RELEASE = 3

-- CONSTANTS
local EXP_FACTOR = -5
local SUSTAIN_LINE_PX = 20 -- fixed horizontal length of the sustain segment

-- MODULE STATE
local loopCounter = 0
local loopPauseTimer = 0

local gateState = false

local phase = IDLE


local envelope = 0
local timeInPhase = 0
local startLevel = 0
local modeIndex = 1 -- 1 = Linear, 2 = Exponential

-- Trigger states and timers
local trigEoA = 0
local trigEoD = 0
local trigEoS = 0
local trigEoR = 0
local trigEoA_timer = 0
local trigEoD_timer = 0
local trigEoS_timer = 0
local trigEoR_timer = 0

-- Pre-allocated output table for step()
-- Envelope, EoA, EoD, EoS, EoR, Offset
local stepOutputs = {0, 0, 0, 0, 0, 0, 0} -- 7 outputs

-- Pre-allocated points table for draw()
local points = {{0, 0}, {0, 0}, {0, 0}, {0, 0}, {0, 0}}

-------------------------------------------------
-- ENVELOPE CALCULATION
-------------------------------------------------
local function calculateEnvelope(self, dt, attack, decay, sustain, release)
    timeInPhase = timeInPhase + dt
    


    if phase == ATTACK then
        if modeIndex == 2 then
            envelope = startLevel + (1 - startLevel) *
                           (1 - math.exp(EXP_FACTOR * (timeInPhase / attack)))
        else
            envelope = startLevel + (1 - startLevel) * (timeInPhase / attack)
        end

        if timeInPhase >= attack then
            envelope = 1
            timeInPhase = 0
            startLevel = 1
            phase = DECAY
            trigEoA = 1
            trigEoA_timer = (self.parameters[10] or 10) / 1000 -- EoA Duration in seconds
        end

    elseif phase == DECAY then
        if modeIndex == 2 then
            envelope = sustain + (1 - sustain) *
                           math.exp(EXP_FACTOR * (timeInPhase / decay))
        else
            envelope = 1 - (timeInPhase / decay) * (1 - sustain)
        end

        if timeInPhase >= decay then
            envelope = sustain
            timeInPhase = 0
            startLevel = sustain
            phase = SUSTAIN
            trigEoD = 1
            trigEoD_timer = (self.parameters[11] or 10) / 1000 -- EoD Duration in seconds
        end

    elseif phase == SUSTAIN then
    envelope = sustain
    if gateState == false then
        phase = RELEASE
        timeInPhase = 0
        trigEoS = 1
        trigEoS_timer = (self.parameters[12] or 10) / 1000
    end



    elseif phase == RELEASE then
        if modeIndex == 2 then
            envelope = startLevel *
                           math.exp(EXP_FACTOR * (timeInPhase / release))
        else
            envelope = startLevel * (1 - timeInPhase / release)
        end

        if timeInPhase >= release then
            envelope = 0
            timeInPhase = 0
            startLevel = 0
            phase = IDLE
            if self.parameters[16] == 2 then
                loopPauseTimer = (self.parameters[17] or 0) / 1000
            end

            trigEoR = 1
        
            trigEoR_timer = (self.parameters[13] or 10) / 1000 -- EoR Duration in seconds
        end
    end

    return envelope
end

-------------------------------------------------
-- SCRIPT DEFINITION
-------------------------------------------------
return {
    name = "ADSR Extended",
    author = "Fabian Martinez aka Jodok31283",

    init = function(self)
        phase = IDLE
        


        return {
            inputs = {kGate},
            outputs = {kLinear, kLinear, kLinear, kLinear, kLinear, kLinear, kLinear},
            inputNames = {"Gate"},
            outputNames = {"Envelope", "EoA", "EoD", "EoS", "EoR", "CV mV", "Pitch"},
            parameters = {
                {"Attack  ms", 1, 30000, 250, kMilliseconds},
                {"Decay  ms", 1, 30000, 100, kMilliseconds},
                {"Sustain  %", 0, 100, 70, kPercent},
                {"Release  ms", 1, 30000, 500, kMilliseconds},
                {"Mode  Lin/Exp", {"Linear", "Exponential"}, 1},
                {"EoA Voltage  V", 0, 10, 5, kVolts},
                {"EoD Voltage  V", 0, 10, 5, kVolts},
                {"EoS Voltage  V", 0, 10, 5, kVolts},
                {"EoR Voltage  V", 0, 10, 5, kVolts},
                {"EoA Duration  ms", 1, 5000, 10, kMilliseconds},
                {"EoD Duration  ms", 1, 5000, 10, kMilliseconds},
                {"EoS Duration  ms", 1, 5000, 10, kMilliseconds},
                {"EoR Duration  ms", 1, 5000, 10, kMilliseconds},
                {"CV mV",-10000, 10000, 0,},
                {"Envelope  Norm/Inv", {"Normal", "Inverted"}, 1},     -- 1=Normal, 2=Inverted
                {"Loop On/Off", {"Off", "On"}, 1},
                {"Loop Pause  ms", 0, 5000, 0, kMilliseconds},
                {"Loop Count", 0, 9999, 0},
                {"Loop Mode", {"ADSR", "AD", "AR"}, 1},
                {"Semitones",-120, 120, 0},

            }
        }
        
    end,


    gate = function(self, input, rising)
        if input == 1 then
            gateState = rising
            if rising then
                -- Begin Attack
                startLevel = envelope
                phase = ATTACK
                timeInPhase = 0
            else
                -- Begin Release
                if phase == SUSTAIN then
                    trigEoS = 1
                    trigEoS_timer = (self.parameters[12] or 10) / 1000 -- EoS Duration in seconds
                end
                startLevel = envelope
                phase = RELEASE
                timeInPhase = 0
            end
        end
    end,

    
    step = function(self, dt, inputs)
        local attack = self.parameters[1] / 1000
        local decay = self.parameters[2] / 1000
        local sustain = self.parameters[3] / 100
        local release = self.parameters[4] / 1000

        modeIndex = self.parameters[5]

        local trigVoltA = self.parameters[6] or 0
        local trigVoltD = self.parameters[7] or 0
        local trigVoltS = self.parameters[8] or 0
        local trigVoltR = self.parameters[9] or 0

        local mv = (self.parameters[14] or 0) 
        local offset = mv * 0.001 -- outputs offset in mV
        local invert = self.parameters[15] or 1

        local loopOn = self.parameters[16] or 1
        local loopPause = (self.parameters[17] or 0) / 1000
        local loopCount = self.parameters[18] or 0
        local loopMode = self.parameters[19] or 1
        local semi = (self.parameters[20] or 0) 
        local cv = semi * (1/12) -- Convert semitones to CV
        -- Update loop pause timer
        if loopPauseTimer > 0 then
            loopPauseTimer = loopPauseTimer - dt
            if loopPauseTimer < 0 then loopPauseTimer = 0 end
        end


      




        local env = calculateEnvelope(self, dt, attack, decay, sustain, release)

        -- Loop logic
       if loopOn == 2 and phase == IDLE and loopPauseTimer == 0 then
    if loopCount == 0 or loopCounter < loopCount then

        if loopCount > 0 then
            loopCounter = loopCounter + 1
        end

        if loopMode == 2 then  -- AD
            phase = ATTACK
            timeInPhase = 0
            startLevel = 0
            gateState = false
        elseif loopMode == 3 then  -- AR
            phase = ATTACK
            timeInPhase = 0
            startLevel = 0
            gateState = false
        else  -- ADSR
            phase = ATTACK
            timeInPhase = 0
            startLevel = 0
            gateState = false
        end
    end
end




        -- Handle trigger timers
        if trigEoA_timer > 0 then
            trigEoA_timer = trigEoA_timer - dt
            if trigEoA_timer <= 0 then trigEoA = 0 end
        end
        if trigEoD_timer > 0 then
            trigEoD_timer = trigEoD_timer - dt
            if trigEoD_timer <= 0 then trigEoD = 0 end
        end
        if trigEoS_timer > 0 then
            trigEoS_timer = trigEoS_timer - dt
            if trigEoS_timer <= 0 then trigEoS = 0 end
        end
        if trigEoR_timer > 0 then
            trigEoR_timer = trigEoR_timer - dt
            if trigEoR_timer <= 0 then trigEoR = 0 end
        end

        -- Outputs
        if invert == 2 then
            stepOutputs[1] = env * -10
        else
            stepOutputs[1] = env * 10
        end
        stepOutputs[2] = trigEoA * trigVoltA
        stepOutputs[3] = trigEoD * trigVoltD
        stepOutputs[4] = trigEoS * trigVoltS
        stepOutputs[5] = trigEoR * trigVoltR
        stepOutputs[6] = offset -- Offset output in mV
        stepOutputs[7] = cv -- CV output in semitones
        return stepOutputs
    end,


    draw = function(self)
        local width = 256
        local height = 64
        local headerHeight = 12
        local textHeight = 12
        local baselineY = height - 2
        local maxAmplitude = baselineY - headerHeight - textHeight

        -- Parameters
        local attack = self.parameters[1] / 1000
        local decay = self.parameters[2] / 1000
        local sustain = self.parameters[3] / 100
        local release = self.parameters[4] / 1000
        modeIndex = self.parameters[5]
        local invert = self.parameters[15] or 1

        local totalTime = attack + decay + release
        local availableWidth = (width - 20) - SUSTAIN_LINE_PX
        local scaleX = availableWidth / totalTime
        local scaleY = maxAmplitude

        -- (1) Start: baseline
        points[1][1] = 10
        points[1][2] = baselineY

        -- (2) Attack peak
        local attackX = points[1][1] + (attack * scaleX)
        local attackY = baselineY - scaleY
        points[2][1] = attackX
        points[2][2] = attackY

        -- (3) Decay end => sustain start
        local decayX = points[2][1] + (decay * scaleX)
        local decayY = baselineY - (scaleY * sustain)
        points[3][1] = decayX
        points[3][2] = decayY

        -- (4) Sustain end => horizontal line
        points[4][1] = decayX + SUSTAIN_LINE_PX
        points[4][2] = decayY

        -- (5) Release end => back to baseline
        points[5][1] = points[4][1] + (release * scaleX)
        points[5][2] = baselineY

        -- Draw lines with highlighting
        for i = 1, 4 do
            local color = 7 -- default dim color

            if (i == 1 and phase == ATTACK) or (i == 2 and phase == DECAY) then
                color = 15
            elseif i == 3 and phase == SUSTAIN then
                color = 15
            elseif i == 4 and phase == RELEASE then
                color = 15
            end

            drawSmoothLine(points[i][1], points[i][2], points[i + 1][1],
                           points[i + 1][2], color)
        end

        -- Label the segments near each endpoint
        drawText(points[2][1], points[2][2] - 5, "A")
        drawText(points[3][1], points[3][2] - 5, "D")
        drawText(points[4][1], points[4][2] - 5, "S")
        drawText(points[5][1], points[5][2] - 5, "R")

        -- Optionally, indicate inversion visually (e.g., with a label)
        if invert == 2 then
            drawText(width - 70, headerHeight + 15, "INVERTED", 15)
        end
        
        -- Loop
        if self.parameters[16] == 2 then  -- Loop On
            local loopCount = self.parameters[18] or 0
            local mode = self.parameters[19] or 1
            local modeLabel = (mode == 2 and "AD") or (mode == 3 and "AR") or "ADSR"
            local loopLabel = (loopCount == 0 and "infinite") or tostring(loopCounter)
            drawText(width - 120, headerHeight + 6, "LOOP " .. loopLabel .. " (" .. modeLabel .. ")", 15)
        end

        -- Loop-Pause
        if loopPauseTimer and loopPauseTimer > 0 then
            local totalPause = (self.parameters[17] or 0) / 1000
            local px = 10
            local barWidth = 80
            local barHeight = 4
            local filled = barWidth * (1 - loopPauseTimer / totalPause)
            drawRectangle(px, headerHeight, barWidth, barHeight, 7)
            drawRectangle(px, headerHeight, filled, barHeight, 15)
        end

    end
}
