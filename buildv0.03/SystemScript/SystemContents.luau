
-- bro rework this main local script it is bad like bad

-- Global Constants
_G.___DEBUG = true; -- Enables Debug Mode, allowing for developer prints to be shown, which allows for debugging.

-- Sources
--- References
local Players: Players = game:GetService("Players");
local player: Player = Players.LocalPlayer;

local Abilities = require(script:WaitForChild("Abilities"));
local Effects = require(script:WaitForChild("Effects"));
local Movement = require(script:WaitForChild("Movement"));
local Input = require(script:WaitForChild("Input"));

-- Store the current movement instance for cleanup
local currentMovement = nil;
local currentInput = nil;

game:GetService("ReplicatedStorage"):WaitForChild("CharacterChanged").OnClientEvent:Connect(function(character: Model)
    -- Clean up previous movement logic
    if currentMovement and currentMovement.stop then
        currentMovement:stop();
        currentMovement = nil;
    end
    if currentInput and currentInput.Disconnect then
        currentInput:Disconnect();
        currentInput = nil;
    end

    -- Start new movement logic for the new character
    currentMovement = Movement.new(character);
    currentInput = Input.new()
end);

Effects.new();
Abilities.new();
