--!strict
-- fix the draft of this script later bro
-- services
local Debris = game:GetService("Debris");

-- constants
local REMOVE_COOLDOWN: number = 1;
local REMOVE_SUCCESS_COOLDOWN: number = 3;

local function VisualizeHitbox(cframe: CFrame, size: Vector3): Part
  local hitbox: Part = Instance.new("Part");
  hitbox.CFrame = cframe;
  hitbox.Size = size;
  hitbox.Color = Color3.new(1, 0, 0);
  hitbox.Anchored = true;
  hitbox.Material = Enum.Material.ForceField;
  hitbox.CanCollide = false;
  hitbox.CanQuery = false;
  hitbox.Parent = workspace;
  
  return hitbox;
end;

local HitboxService = {}

function HitboxService.Request(cframe: CFrame, size: Vector3, character: Model): Humanoid
  local hitbox = VisualizeHitbox(cframe, size);
  
  local params = OverlapParams.new();
  params.FilterDescendantsInstances = {character};
  params.FilterType = Enum.RaycastFilterType.Exclude;
  
  local parts: {BasePart} = workspace:GetPartBoundsInBox(cframe, size, params);
  local humanoid: Humanoid = nil;
  
  for _, part in pairs(parts) do
    if (part.Parent and part.Parent:IsA("Model")) then
      for _, child in part.Parent:GetChildren() do
        if child:IsA("Humanoid") then
           Debris:AddItem(hitbox, REMOVE_SUCCESS_COOLDOWN);
          humanoid = child;
        end;
      end;
      if (humanoid) then break; end
    end;
  end;
  if (not humanoid) then
    Debris:AddItem(hitbox, REMOVE_COOLDOWN);
  end;
  
  return humanoid;
end;

return HitboxService
