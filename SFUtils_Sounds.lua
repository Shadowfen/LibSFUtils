-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

-- -----------------------------------------------------------------------
-- sound choice utilities

-- initSounds() is the only function to modify these tables in any way,
-- and they are never nil.
local soundChoices = {}     -- contains [index] value=SOUNDS.xxx
local soundReverse = {}     -- contains [SOUNDS.xxx] index

-- This function loads a pair of "singleton" arrays of sounds
-- from the ZOS SOUNDS map
--
-- An addon may call this (on loading), or may rely on the
-- other sfutil sound functions to call it. If it has already
-- run once, it does not do so again.
--
function sfutil.initSounds(force)
    if force == true then soundChoices={} end
    -- load sound keys to table
    if next(soundChoices) == nil then  
        for k,_ in pairs(SOUNDS) do
            local ndx = #soundChoices+1
            soundChoices[ndx] = k
        end
        table.sort(soundChoices)
        for i,k in pairs(soundChoices) do
            soundReverse[k] = i
        end
    end
end

-- provide the max number of sounds provided by ZOS
-- that were loaded into the soundChoices array
--
function sfutil.numSounds()
    sfutil.initSounds()
    return #soundChoices
end

-- Get the soundChoices index number for a SOUNDS.xxx value.
--
-- Useful for setting a slider value from a saved (string) sound entry.
function sfutil.getSoundIndex(sound, fallback)
    if not fallback then fallback = SOUNDS.DEFAULT_CLICK end
    
    sfutil.initSounds()
    if not soundReverse[fallback] then fallback = SOUNDS.DEFAULT_CLICK end
    
    local ndx = soundReverse[sound]
    if not ndx then return soundReverse[fallback] end
    return ndx
end

-- Given an index number, get the sound entry out of the
-- soundChoices array
function sfutil.getSound(index)
    sfutil.initSounds()
    local sound = soundChoices[index]
    if not sound then return "nil" end
    return sound
end

-- Play a sound selected by index number into a list 
-- of all of the games sounds we have access to or SOUNDS.xxx entry.
-- If the index is out-of-bounds or SOUNDS.xxx is nil, do not play a sound.
--
-- Note that at present, the SOUNDS array has TWO entries
-- for "No_Sound", which will "play" silence.
--
function sfutil.PlaySound(index)
    if not index then return end
    
    if type(index) == "number" then
    	-- we have an index into our soundChoices array
    	-- so, make sure it exists (once).
    	sfutil.initSounds()
        if soundChoices[index] == nil then return end
        PlaySound(soundChoices[index])
        
    elseif type(index) == "string" then
        if SOUNDS[index] ~= nil then
        	-- we got a sound name (index into the SOUNDS array)
            PlaySound(SOUNDS[index])
            
        else
        	-- presume we have a string that was stored in a SOUNDS.xxx
            PlaySound(index)
        end
    end
end    
