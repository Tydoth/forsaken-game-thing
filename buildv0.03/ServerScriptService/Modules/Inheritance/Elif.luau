--!strict

-- note: fixed the messy draft and now it's actually bearable to look at
-- also made it so script isn't reliant on .Parent property as much
-- and modulated the stuff like boost panels and stat copying

-- Sources
--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");
local ServerStorage = game:GetService("ServerStorage");

--- Modules
local BoostPanel = require(script.Modules.BoostPanel);
local AbilityInfo = require(script.Settings.AbilityInfo);
local HitboxService = require(ServerScriptService.Modules.HitboxService);
local MovementAnimations = require(script.Settings.MovementAnimations);
local MovementValues = require(script.Settings.MovementValues);
local Player = require(ServerScriptService.Modules.Root.Player);
local StatCopier = require(ServerScriptService.Modules.Helpers.StatCopier);

-- Types
-- for the love of goodness pplease move these 2 types elsewhere we do not need it in this script
-- make it soon before school starts nerd
-- oh wait
type SoundMap = {
  [string]: Sound;
};
type SoundsType = {
  Ability: SoundMap;
  Idle: SoundMap;
  Stun: SoundMap;
  Voiceline: SoundMap;
};

export type ElifType = {
  Actionable: boolean;
  Character: Model;
  Panels: {BasePart};
  Player: Player;
  Sounds: SoundsType;
  MovementAnims: Folder;
  StaminaValues: Folder;
  conn: RBXScriptConnection?;
  conn2: RBXScriptConnection?;
  M1: (self: ElifType) -> ();
  Ability1: (self: ElifType) -> ();
  Ability2: (self: ElifType) -> ();
  Ability3: (self: ElifType) -> ();
  PlayAnimation: (self: ElifType, character: Model, animName: string, options: {[string]: any}) -> ();
  Clear: (self: ElifType) -> ();
};

-- Constants
local MAX_PANELS: number = 6;

local Elif = {} :: any;
Elif.__index = Elif;

-- Create new killer
function Elif.new(controller: Player): ElifType
  local self = (setmetatable(Player.new(controller), Elif) :: ElifType); -- we do not care about the warning idk how to fix
  self.Actionable = true;

  do -- Character handling stuff
    do -- Create character
      local clonedModel = (ServerStorage.Objects.KillerModels.Elif :: Model):Clone();
      clonedModel.Name = controller.Name;
      clonedModel.Parent = workspace;
      controller.Character = clonedModel;

      self.Character = clonedModel;
    end;

    do -- Copy stats to player character
      local movementAnims, movementValues = StatCopier.copyMovesetValues(MovementAnimations, MovementValues);

      movementValues.Parent = self.Character;
      movementAnims.Parent = self.Character;
      self.MovementAnims = movementAnims; -- movementAnimsTemplate:Clone();
      self.StaminaValues = movementValues;
    end;
  end;

  do-- Sounds
    local soundsFolder = script.Settings.Sounds;

    -- Set sounds idk at this point
    self.Sounds = {
      Ability = {},
      Idle = {},
      Stun = {},
      Voiceline = {}
    } :: SoundsType

    StatCopier.copySounds(soundsFolder, self);
  end;

  do -- Attacking
    self.Panels = {} :: {BasePart};
    self.conn = ReplicatedStorage.Events.AttackRequest.OnServerEvent:Connect(function(player: Player, abilityName: string)
      do -- Checks to see if player could attack
        if (player ~= self.Player) then
          return;
        end;
        if (not self.Actionable) then
          return;
        end;
        if (not self[abilityName]) then
          return;
        end;
      end;

      do -- stupid bug where self doesn't pass if i do self[abilityname] so i have to do this messy method >:[
        if (abilityName == "M1") then
          self:M1();
        elseif (abilityName == "Ability1") then
          self:Ability1();
        elseif (abilityName == "Ability2") then
          self:Ability2();
        elseif (abilityName == "Ability3") then
          self:Ability3();
        end;
      end;

      return;
    end);

    self.conn2 = ReplicatedStorage.Events.ClearClasses.Event:Connect(function()
      self:Clear();
      return;
    end);
  end;

  task.spawn(function() BoostPanel.new(self.Character); end);
  ReplicatedStorage.CharacterChanged:FireClient(self.Player, self.Character);
  return self;
end;

-- Basic attack
function Elif:M1(): ()
  self.Actionable = false;
  do -- Play visuals
    self:PlayAnimation(self.Character, "M1", {Speed = 2})
    if (self.Sounds.Ability and self.Sounds.Ability.M1) then
      self.Sounds.Ability.M1:Play();
    end;
  end;

  do -- Hitboxes and stuff
    task.wait(0.3);
    for _ = 1, 12 do
      do -- hitbox and damage handling
        local region: CFrame = (self.Character.PrimaryPart :: BasePart).CFrame * CFrame.new(0, 0, -5.5);
        local body: Humanoid? = HitboxService.Request(region, Vector3.new(4, 6, 5), self.Character);
        if (body) then
          body:TakeDamage(24.5);
          if self.Sounds.Ability and self.Sounds.Ability.HitSuccess then
            self.Sounds.Ability.HitSuccess:Play();
          end;
          break;
        end;
      end;

      task.wait(0.02);
      continue;
    end;
  end;

  task.wait(0.5);
  self.Actionable = true;
  return;
end;

-- Dash attack
function Elif:Ability1(): ()
  self.Actionable = false;
  do -- Play visuals
    self:PlayAnimation(self.Character, "Ability1Start", {});
    if (self.Sounds.Ability and self.Sounds.Ability.Ability1Start) then
      self.Sounds.Ability.Ability1Start:Play();
    end;
  end;

  do -- Main ability
    local hitStatus: boolean = false;
    local lookVector: Vector3 = (self.Character.PrimaryPart :: BasePart).CFrame.LookVector;
    for _ = 1, 40 do
      (self.Character.PrimaryPart :: BasePart).AssemblyLinearVelocity = lookVector * 60;
      task.wait(0.025);

      do -- hitbox and damage handling
        local region: CFrame = (self.Character.PrimaryPart :: BasePart).CFrame;
        local body: Humanoid? = HitboxService.Request(region, Vector3.new(7, 7, 7), self.Character);
        if (body) then
          hitStatus = true;
          body:TakeDamage(4 * (#self.Panels + 1));
          if (self.Sounds.Ability and self.Sounds.Ability.HitSuccess) then
            self.Sounds.Ability.HitSuccess:Play();
          end;
          break;
        end;
      end;
    end;

    self:PlayAnimation(self.Character, "Ability1End", {Priority = "Action2"});
    if (hitStatus) then
      if (self.Sounds.Ability and self.Sounds.Ability.Ability1Success) then
        self.Sounds.Ability.Ability1Success:Play();
      end;
    else
      if (self.Sounds.Ability and self.Sounds.Ability.Ability1Fail) then
        self.Sounds.Ability.Ability1Fail:Play();
      end;
    end;
  end;

  do -- After state
    task.wait(1);
  end;

  self.Actionable = true;
  return;
end;

-- Boost panel
function Elif:Ability2(): ()
  self.Actionable = false;
  do -- Play visuals
    self:PlayAnimation(self.Character, "Ability2", {Speed = 2})
    if (self.Sounds.Ability and self.Sounds.Ability.Ability2Start) then
      self.Sounds.Ability.Ability2Start:Play();
    end
  end;

  do -- Actual ability
    local extraSpeedVar = self.StaminaValues:FindFirstChild("ExtraSpeed") :: NumberValue?;
    if (extraSpeedVar) then
      extraSpeedVar.Value = -40;
    end;
    task.wait(1.2);

    do -- Main ability
      local clone = (ServerStorage.Objects.KillerObjects.ElifBoostPanel :: BasePart):Clone();
      clone.Parent = workspace;
      clone.CFrame = (self.Character.PrimaryPart :: BasePart).CFrame * CFrame.new(0, -3.5, 0);

      table.insert(self.Panels, clone);
      if (#self.Panels > MAX_PANELS) then
        self.Panels[1]:Destroy(); table.remove(self.Panels, 1);
      end;
    end;

    do -- After effects
      if (self.Sounds.Ability and self.Sounds.Ability.Ability2Placed) then
        self.Sounds.Ability.Ability2Placed:Play();
      end;
      task.wait(0.3);
      if (extraSpeedVar) then
        extraSpeedVar.Value = 0;
      end;
    end;
  end;

  task.wait(1.5);
  self.Actionable = true;
  return;
end;

-- Speed boost
function Elif:Ability3(): ()
  self.Actionable = false;

  task.spawn(function()
    local extraSpeedVar = self.StaminaValues:FindFirstChild("ExtraSpeed") :: NumberValue?;
    -- WHY ARE THERe SO MANY IF STATEMENTS KID
    if (extraSpeedVar) then
      extraSpeedVar.Value = -20;
    end;
    if (self.Sounds.Ability and self.Sounds.Ability.Ability3) then
      self.Sounds.Ability.Ability3:Play();
    end;
    task.wait(1);
    if (extraSpeedVar) then
      extraSpeedVar.Value = 14;
    end;

    for i = 20, 1, -1 do
      if (extraSpeedVar) then
        extraSpeedVar.Value -= 0.8;
      end;
      task.wait(0.1);
    end;

    task.wait(1);
    if (extraSpeedVar) then
      extraSpeedVar.Value = 0;
    end;
  end);

  task.wait(3);
  self.Actionable = true;
  return;
end;

-- save memory
function Elif:Clear(): ()
  do -- Disconnect any connections
    if self.conn then
      self.conn:Disconnect();
      self.conn = nil;
    end;
    if self.conn2 then
      self.conn2:Disconnect();
      self.conn2 = nil;
    end;
  end;

  do -- Turn stuff to nil to save memory
    BoostPanel.destroy();

    if (self.StaminaValues and self.StaminaValues.Parent) then
      self.StaminaValues.Parent = nil;
    end;

    -- Remove references to character and player
    -- And I quit
    self.Actionable = nil :: any;
    self.Character = nil :: any;
    self.Player = nil :: any;
    self.StaminaValues = nil :: any;
  end;
  self = nil :: any;
  return;
end;

return Elif
