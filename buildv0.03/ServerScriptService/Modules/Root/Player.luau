
-- Moved movement animation container to their respective module script instead of their model for ease of access
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Player = {};
Player.__index = Player;

function Player.new(player: Player): {}
  local self = setmetatable({}, Player);
  
  do
    self.Actionable = true;
    self.Player = player;
    self.PlayAnimation = Player.PlayAnimation;
    self.destroy = Player.destroy;
  end;
  
  return self;
end;

function Player:destroy()
  for _, v in pairs(self) do
    self = nil;
  end;
end;

function Player:PlayAnimation(model: Model, anim: string, params: {}): AnimationTrack
  local animator: Animator = model.Humanoid:FindFirstChild("Animator");
  if (not animator) then
    warn("Animator not found");
    return;
  end;
  local animToPlay: Animation = model.MovementAnims:FindFirstChild(anim);
  if (not animToPlay) then
    warn(anim .. " animation not found, won't play but hitboxes will still appear");
  else
    ReplicatedStorage.Events.ReplicateAnimation:FireAllClients(model, animToPlay.Name, params);
  end;
end;

return Player
