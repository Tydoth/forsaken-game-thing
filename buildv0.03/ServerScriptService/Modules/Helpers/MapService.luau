--!strict

-- Map module for getting maps, also to activate certain events which some maps might have
-- Also just for clean stuff i guess ok

-- Sources
--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage"); -- will be used later for events
local ServerStorage = game:GetService("ServerStorage");

-- Constants
local MAP_CONTAINER: Folder = (workspace.GameRelated.Playing.CurrentMap);
local MapService = {};

-- Returns a random map, but if mapName is provided, it will return that map instead, and if that map isn't found, returns default map.
function MapService:GetMap(mapName: string?): Folder
  local map: Folder;
  if (not mapName) then
    map = ServerStorage.Objects.Maps:GetChildren()[math.random(1, #ServerStorage.Objects.Maps:GetChildren())] :: Folder;
    return map;
  end;
  
  map = ServerStorage.Objects.Maps:FindFirstChild(mapName);
  if (not map) then
    warn("Map " .. mapName .. " not found");
    return ServerStorage.Objects.Maps.TeapotTemplate :: Folder;
  end;
  
  return map :: Folder;
end;

-- Initiate map stuff, usually happens right after :GetMap function by its requirer.
function MapService:InitMap(map: Folder): ()
  if (not map) then
    warn("Map is not provided, returning without any initializing being done.");
    return;
  end;
  map.Parent = MAP_CONTAINER;
  -- yeah nothing else to do, map is already there, maybe add some stuff later
end;

-- Activates the map event after its interval.
function MapService:CallMapEvent(map: Folder): ()
  if (not map) then
    warn("Map is not provided, returning without any event being done.");
    return;
  end;
  
  -- To be added when maps get their own events or when i quit
  return;
end;

-- Sets up player spawns, not in Setup module because i thought it wound be more fitting here.
function MapService:SetupPlayerSpawns(participants: {Player}): ()
  for i, v in participants do
    if (not v.Character) then
      warn("what");
      break;
    end;
    
    if (v.Character:HasTag("Killer")) then
      v.Character:PivotTo(CFrame.new(100, 0, 0));
    else
      v.Character:PivotTo(CFrame.new(0, 0, 0))
    end;
  end;
  
  return;
end;

return MapService;
