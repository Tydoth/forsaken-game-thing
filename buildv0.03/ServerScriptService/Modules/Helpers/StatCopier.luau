--!nonstrict

-- most ovious helper module i've ever made bro

local StatCopier = {}

function StatCopier.copyMovesetValues(MovementAnimations: {[string]: string}, MovementValues: {[string]: number | boolean}): (Folder, Folder)
  local movementAnimations = Instance.new("Folder");
  do -- Animations
    for name, val: string in MovementAnimations do
      local value = Instance.new("Animation");
      value.Name = name;
      value.AnimationId = val;
      value.Parent = movementAnimations
    end;
    movementAnimations.Name = "MovementAnims";
  end;

  local movementValues = Instance.new("Folder");
  do -- Stamina
    for name, val: number | boolean in MovementValues do
      local value;
      if typeof(val) == "boolean" then
        value = Instance.new("BoolValue");
      elseif typeof(val) == "number" then
        value = Instance.new("NumberValue");
      end;
      value.Value = val;
      value.Name = name;
      value.Parent = movementValues;
    end;

    local extraSpeed = Instance.new("NumberValue");
    extraSpeed.Name = "ExtraSpeed";
    extraSpeed.Parent = movementValues;
    local extraSpeed2 = Instance.new("NumberValue");
    extraSpeed2.Name = "ExtraSpeed2";
    extraSpeed2.Parent = movementValues;

    movementValues.Name = "StaminaValues";
  end;
  
  return movementAnimations, movementValues;
end;

function StatCopier.copySounds(SoundsFolder, metatable): ()
  for _, sound in SoundsFolder.Ability:GetChildren() do
    local clone: Sound = sound:Clone()
    metatable.Sounds.Ability[sound.Name] = clone;
    clone.Parent = metatable.Character.PrimaryPart;
  end;
  for _, sound in SoundsFolder.Stun:GetChildren() do
    local clone: Sound = sound:Clone()
    metatable.Sounds.Stun[sound.Name] = clone;
    clone.Parent = metatable.Character.PrimaryPart;
  end;
  for _, sound in SoundsFolder.Idle:GetChildren() do
    local clone: Sound = sound:Clone()
    metatable.Sounds.Idle[sound.Name] = clone;
    clone.Parent = metatable.Character.PrimaryPart;
  end;
  for _, sound in SoundsFolder.Voiceline:GetChildren() do
    local clone: Sound = sound:Clone()
    metatable.Sounds.Voiceline[sound.Name] = clone;
    clone.Parent = metatable.Character.PrimaryPart;
  end
  return;
end;

return StatCopier
