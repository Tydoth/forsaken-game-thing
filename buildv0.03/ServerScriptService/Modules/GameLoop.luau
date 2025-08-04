--!strict
-- Main Module for the game

local Players = game:GetService("Players");
local ServerScriptService = game:GetService("ServerScriptService");

local MapService = require(ServerScriptService.Modules.Helpers.MapService);
local Setup = require(script.Setup);

--local Counter = require(ServerScriptService.Modules.Helpers.Counter);
local hint: Hint = workspace:FindFirstChildOfClass("Hint") or Instance.new("Hint");
hint.Parent = workspace;

local GameLoop = {};

function GameLoop.OnLoad(): {}
  while (#Players:GetPlayers() == 0) do
    task.wait(1);
  end;

  task.spawn(function() GameLoop:loop(); end); 
  return {}
end;

function GameLoop:loop(): ()
  
  hint.Text = "Starting game..";
  task.wait(3);
  for duration = 2, 1, -1 do
    hint.Text = "Round starting in: " .. duration;
    task.wait(1);
  end;
  
  local map: Folder;
  do -- Get map
    map = MapService:GetMap();
    MapService:InitMap(map);
  end;
  
  do -- Main loop
    local participants: {Player} = Players:GetPlayers();

    local chosen: number = math.random(1, #participants);
    Setup:SetKillers({[1] = {Player = participants[chosen]; Killer = "Elif"}});
    for i, participant in pairs(participants) do
      if i == chosen then
        continue;
      end;
      Setup:SetSurvivors({[1] = {Player = participant}})
    end;
    
    task.wait(0.1);
    MapService:SetupPlayerSpawns(participants);
    for i = 120, 1, -1 do
      hint.Text = "Round ending in: " .. i;
      task.wait(1);
    end;
    
    for _, participant in pairs(participants) do
      Setup:SetSurvivors({[1] = {Player = participant}});
    end;
  end;
  
  do -- Cleanup
    game.ReplicatedStorage.Events.ClearClasses:Fire();
  end;
  
  GameLoop:loop();

  return;
end;

return GameLoop.OnLoad()
