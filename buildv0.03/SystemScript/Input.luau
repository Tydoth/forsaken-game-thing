--!nonstrict

-- Input module
-- There's no purpose for this besides keeping code clean.

-- Services
local UserInputService: UserInputService = game:GetService("UserInputService");
local InputEvent: BindableEvent = script.Parent:WaitForChild("Events"):WaitForChild("InputEvent");

-- Main Module
local Input = {}
Input.__index = Input;

-- Create a new input object for whoever is playing this game
function Input.new(): {RBXScriptConnection}
  local self = setmetatable({}, Input);
  
  do -- do block mayhem
    self.conn1 = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
      InputEvent:Fire(input, gameProcessedEvent, "Began")
    end);
    self.conn2 = UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
      InputEvent:Fire(input, gameProcessedEvent, "Ended")
    end);
  end;
  
  return self;
end;

-- "Destroy" the input
function Input:Disconnect()
  for _, v in self do
    if (v and v.Disconnect :: boolean) then v:Disconnect(); v = nil; end;
  end;
end;

return Input;
