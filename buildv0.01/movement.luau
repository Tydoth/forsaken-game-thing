-- Improved Movement Module
-- Notes:
--- Assitant was made to fix some faults, but not to make the script.
--
--- In the future, please, take some time organizing this script into modules;
--- It's a mess right now. - Tydoth, 7/21/2025, 11:09 pm
--
--- Please fix the bug where if you spam click the sprint key, you won't lose stamina
--- while retaining sprint speed. - Tydoth, 7/22/25, 11:05 am

-- Sources
--- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--- References
local Player: Player = game:GetService("Players").LocalPlayer
local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart: Part = Character:FindFirstChild("HumanoidRootPart")
local Animator: Animator = Humanoid:FindFirstChild("Animator")
local AnimationConfigurations: Folder = Animator:WaitForChild("Configurations")
local AbilityConfigurations: Folder = Animator:FindFirstChild("AbilityConfigurations") or nil
local Camera: Camera = workspace.CurrentCamera
local StaminaGui: ScreenGui = Player.PlayerGui:WaitForChild("Stamina")
local StaminaLabel: TextLabel = StaminaGui:WaitForChild("StaminaLabel")

--- Modles
local Packets = script:WaitForChild("Packets")
local Footsteps = require(Packets:WaitForChild("Footsteps"))

-- Internal Storage
--- Containers
local anims: {AnimationTrack} = {}

--- Visuals
--- Animations are stored in their respective animator.
do ---- Animations
  local movementFolder: Folder = Animator:WaitForChild("Movement")
  for _, v in movementFolder:GetChildren() do
    if v:IsA("Animation") then
      anims[v.Name] = Animator:LoadAnimation(v)
    end
  end
end

-- Declarables

--- Constants
local Constants: Folder = AnimationConfigurations:WaitForChild("Constants")
----- Note: The ones without a comment are self-explanatory.
---- Stamina Constants
local WALKSPEED_ALPHA: number = Constants:WaitForChild("WALKSPEED_ALPHA").Value -- smooth walkspeed transition
local WALK_SPEED: number = 10
local RUN_SPEED: number = 24
local STAMINA_DRAIN: number = 10
local STAMINA_GAIN: number = 15
local STAMINA_MAX: number = 100
local WAIT_TIME: number = 0.1 -- put this at a low number for smoothness, higher for performance
local STAMINA_REGEN_COOLDOWN: number = 1.9 -- seconds to wait after depletion

---- Animation Constants
local IDLE_FADE_OFF: number = Constants:WaitForChild("IDLE_FADE_OFF").Value
local WALK_FADE_OFF: number = Constants:WaitForChild("WALK_FADE_OFF").Value
local RUN_FADE_OFF: number = Constants:WaitForChild("RUN_FADE_OFF").Value
local LEANING_ALPHA: number = Constants:WaitForChild("LEANING_ALPHA").Value -- smooth leaning
local ORIG_ROOT_JOINT: CFrame = HumanoidRootPart.RootJoint.C0

---- Keybinds
local keybinds = {
  Sprint = Enum.KeyCode.Q,
  M1 = Enum.UserInputType.MouseButton1,
  Attack1 = Enum.KeyCode.E,
  Attack2 = Enum.KeyCode.R,
  Attack3 = Enum.KeyCode.F,
}

--- Variables

---- Stamina Variables
local currentlyRunning: boolean = false
local currentStamina: number = 100
local displayedStamina: number = 100
local displayedSpeed: number = WALK_SPEED
local extraSpeed: number = 8
local canRegenStamina: boolean = true
local prevState: boolean = false -- false = walking, true = running, used to calculate wait time
local stopLoop: boolean = false
local regenAvailableTime: number = 0 -- timestamp when stamina regen is allowed

---- Animation Variables
local currentSound: Sound
local previewAngleX: number = 0
local previewAngleY: number = 0
local displayedAngleX: number = 0
local displayedAngleY: number = 0
local direction: Vector3
local velocity: Vector3

-- Animation Replication State
local lastReplicatedAnim = nil

-- Helper Functions

local function isCustomCharacter()
  local humanoid = Character:FindFirstChildWhichIsA("Humanoid")
  if not humanoid then return false end
  local humanoidDescription = humanoid:GetAppliedDescription()
  local defaultHumanoidDescription = game:GetService("Players"):GetHumanoidDescriptionFromUserId(Player.UserId)
  -- List of relevant properties to compare
  local propertiesToCompare = {
    "Head", "Face", "BodyTypeScale", "DepthScale", "HeadScale", "HeightScale", "ProportionScale", "WidthScale",
    "ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation",
    "HatAccessory", "HairAccessory", "FaceAccessory", "NeckAccessory", "ShouldersAccessory", "FrontAccessory", "BackAccessory", "WaistAccessory",
    "Shirt", "Pants", "ShirtGraphic", "GraphicTShirt", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"
  }
  for _, property in propertiesToCompare do
    local successDefault, defaultValue = pcall(function() return defaultHumanoidDescription[property] end)
    local successCurrent, currentValue = pcall(function() return humanoidDescription[property] end)
    if successDefault and successCurrent then
      if defaultValue ~= currentValue then
        return true -- At least one property is different, so it's custom
      end
    end
  end
  return false -- All relevant properties match, so it's default
end

--- Change if the player is running or not
local function changeRunningState(input: InputObject, gameProcessedEvent: boolean, state: boolean)
  if gameProcessedEvent then return end
  if input.KeyCode == keybinds.Sprint then
    currentlyRunning = state
  else

    -- Map input to action names
    local function getActionFromInput(input)
      if input.UserInputType == keybinds.M1 or input.UserInputType == Enum.UserInputType.Touch then
        return "MouseButton1"
      elseif input.KeyCode == keybinds.Attack1 then
        return "E"
      elseif input.KeyCode == keybinds.Attack2 then
        return "R"
      elseif input.KeyCode == keybinds.Attack3 then
        return "F"
      end
      return nil
    end

    ReplicatedStorage.AttackEvent:FireServer(getActionFromInput(input))
  end
end

-- Helper to replicate movement animation state to server
local function replicateMovementAnimation(animName)
  if lastReplicatedAnim ~= animName then
    lastReplicatedAnim = animName
    ReplicatedStorage:WaitForChild("ReplicateMovementAnimation"):FireServer(animName)
  end
end

do -- Connections 
  -- Stamina
  ReplicatedStorage:WaitForChild("ChangeStamina").OnClientEvent:Connect(function(changes : {})
    print("hello i activated")
    for i, v in pairs(changes) do
      if i == "MAX_STAMINA" then
        STAMINA_MAX = v
      elseif i == "STAMINA_DRAIN" then
        STAMINA_DRAIN = v
      elseif i == "STAMINA_REGEN" then
        STAMINA_GAIN = v
      elseif i == "RUN_SPEED" then
        RUN_SPEED = v
      elseif i == "WALK_SPEED" then
        WALK_SPEED = v
      elseif i == "EXTRA_SPEED" then
        extraSpeed = v
      elseif i == "FORCE_SPEED" then
        task.spawn(function()
          Humanoid.WalkSpeed = v.Amount
          task.wait(v.Length)
          Humanoid.WalkSpeed = WALK_SPEED
        end)
      elseif i == "STATUS_EFFECT" then
        --  CurrentStatusEffects[v.Name] = v.Desired
      end
    end
  end)

  ReplicatedStorage:WaitForChild("PlayAttackAnimation").OnClientEvent:Connect(function(anim: string) 
    local animation = Humanoid:FindFirstChild("Animator"):FindFirstChild("Animations"):FindFirstChild(anim)
    if animation then
      animation = Animator:LoadAnimation(animation)
      animation.Priority = Enum.AnimationPriority.Action
      animation.Looped = false
      animation:Play()
    end
  end)

  -- Input Conns
  local inputStarted: RBXScriptConnection; inputStarted = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    changeRunningState(input, gameProcessedEvent, true)
  end)
  local inputEnded: RBXScriptConnection; inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    changeRunningState(input, gameProcessedEvent, false)
  end)

  -- Footstep Conns
  local walkConn: RBXScriptConnection
  local runConn: RBXScriptConnection
  if Constants:WaitForChild("FOOTSTEPS_ENABLED").Value then
    walkConn = anims["Walk"]:GetMarkerReachedSignal("footstep"):Connect(Footsteps.playFootstep)
    runConn = anims["Run"]:GetMarkerReachedSignal("footstep"):Connect(Footsteps.playFootstep)
  end

  -- Cleanup upon character death

  Humanoid.Died:Connect(function() 
    stopLoop = true
    if inputStarted then
      inputStarted:Disconnect()
      inputStarted = nil
    end
    if inputEnded then
      inputEnded:Disconnect()
      inputEnded = nil
    end
    if walkConn then
      walkConn:Disconnect()
      walkConn = nil
    end
    if runConn then
      runConn:Disconnect()
      runConn = nil
    end
  end)
end

--- The Code
local loop: thread

do -- The Main Function!
  loop = task.spawn(function()
    while not stopLoop do 
      do -- Main Logic
        local now = os.clock()

        -- Check if enough time has passed to allow stamina regen
        if not canRegenStamina and now >= regenAvailableTime then
          canRegenStamina = true
        end

        if currentlyRunning then
          if HumanoidRootPart.AssemblyLinearVelocity.Magnitude <= 0.2 then -- Standing still while on run state
            if canRegenStamina then
              currentStamina += STAMINA_GAIN * WAIT_TIME
            end
          else
            currentStamina -= STAMINA_DRAIN * WAIT_TIME
            if currentStamina <= 0 then
              currentStamina = 0
              currentlyRunning = false
              canRegenStamina = false
              regenAvailableTime = os.clock() + STAMINA_REGEN_COOLDOWN
            end
          end
        else
          if canRegenStamina then
            if prevState == true then -- Small buffer if player just ran
              task.wait(0.4)
            end
            currentStamina += STAMINA_GAIN * WAIT_TIME
          end
        end

        -- Clamp stamina
        if currentStamina >= STAMINA_MAX then
          currentStamina = STAMINA_MAX
        elseif currentStamina <= 0 then
          currentStamina = 0
        end
      end

      do -- Animation
        do -- Base
          local velocityMagnitude: number = HumanoidRootPart.AssemblyLinearVelocity.Magnitude
          anims["Walk"]:AdjustSpeed(velocityMagnitude / WALK_SPEED)
          anims["Run"]:AdjustSpeed(velocityMagnitude / RUN_SPEED)

          -- Animation state logic for replication
          local animToReplicate = nil
          if velocityMagnitude <= 0.1 then
            if not isCustomCharacter() then
              if anims["Walk"].IsPlaying then anims["Walk"]:Stop(WALK_FADE_OFF) end
              if anims["Run"].IsPlaying then anims["Run"]:Stop(RUN_FADE_OFF) end
              if not anims["Idle"].IsPlaying then anims["Idle"]:Play(IDLE_FADE_OFF) end
            end
            

            animToReplicate = "Idle"
          elseif not currentlyRunning then
            if not isCustomCharacter() then
              if not anims["Walk"].IsPlaying then  anims["Walk"]:Play(WALK_FADE_OFF); end
              if anims["Run"].IsPlaying then anims["Run"]:Stop(RUN_FADE_OFF); end
              if anims["Idle"].IsPlaying then anims["Idle"]:Stop(IDLE_FADE_OFF); end
            end
             

            animToReplicate = "Walk"
          elseif currentlyRunning then
            if not isCustomCharacter() then
              if anims["Walk"].IsPlaying then anims["Walk"]:Stop(WALK_FADE_OFF) end
              if not anims["Run"].IsPlaying then anims["Run"]:Play(RUN_FADE_OFF) end
              if anims["Idle"].IsPlaying then anims["Idle"]:Stop(IDLE_FADE_OFF) end
            end
            

            animToReplicate = "Run"
          end

          -- Replicate movement animation state to server
          if animToReplicate then
            replicateMovementAnimation(animToReplicate)
          end
        end

        do -- Leaning Calculations
          velocity = HumanoidRootPart.AssemblyLinearVelocity
          if velocity.Magnitude > 2 then
            direction = velocity.Unit
            previewAngleY = HumanoidRootPart.CFrame.RightVector:Dot(direction) / 6
            previewAngleX = HumanoidRootPart.CFrame.LookVector:Dot(direction) / 6
          else
            previewAngleY = 0; previewAngleX = 0
          end
        end
      end

      do -- Finalize values and display
        prevState = currentlyRunning
        displayedAngleY = math.lerp(displayedAngleY, previewAngleY * (extraSpeed / 16 + 1), LEANING_ALPHA)
        displayedAngleX = math.lerp(displayedAngleX, previewAngleX * (extraSpeed / 13 + 1), LEANING_ALPHA)
        displayedSpeed = math.lerp(Humanoid.WalkSpeed, (currentlyRunning and RUN_SPEED or WALK_SPEED) + extraSpeed, WALKSPEED_ALPHA)
        displayedStamina = math.round(currentStamina)
        Humanoid.WalkSpeed = displayedSpeed
        HumanoidRootPart.RootJoint.C0 = ORIG_ROOT_JOINT * CFrame.Angles(displayedAngleX, -displayedAngleY, 0)
        StaminaLabel.Text = "Stamina: " .. displayedStamina .. "/" .. STAMINA_MAX
      end
      task.wait(WAIT_TIME)
      -- No more task.spawn for stamina regen needed here!
      -- Removed buggy canRegenStamina reset here ^^
    end
  end)
end

print("Running stamina system!")

