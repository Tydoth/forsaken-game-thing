
-- !nonstrict

-- Notes:
--- Assitant was made to fix some faults, but not to make the script.
--
--- In the future, please, take some time organizing this script into modules;
--- It's a mess right now. - Tydoth, 7/21/2025, 11:09 pm

-- Sources
--- Services
local UserInputService: UserInputService = game:GetService("UserInputService");

--- References
local Player: Player = game:GetService("Players").LocalPlayer;
local Character: Model = Player.Character or Player.CharacterAdded:Wait();
local Humanoid: Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart: Part = Character:WaitForChild("HumanoidRootPart");
local Head: Part = Character:WaitForChild("Head");
local CharAnimations: Folder = Character:WaitForChild("Amimations", 3) or nil;
local Animator: Animator = Humanoid:WaitForChild("Animator");
local AnimationConfigurations: Folder = script:WaitForChild("Configurations");
local AbilityConfigurations: Folder = script:FindFirstChild("AbilityConfigurations") or nil;
local Camera: Camera = workspace.CurrentCamera;
local Interface = script:WaitForChild("Interface");

local NeckAttachment: Motor6D = Character:WaitForChild("Torso"):WaitForChild("Neck"); NeckAttachment.MaxVelocity = 1 / 3;

-- Internal Storage
--- Containers
local anims: {AnimationTrack} = {}
local footsteps: {Sound} = {}

--- Visuals
--- Animations are stored in their respective animator.
do ---- Animations
  if not CharAnimations then
    local movementFolder: Folder = script:WaitForChild("Movement");
    for _, v in movementFolder:GetChildren() do
      if v:IsA("Animation") then
        anims[v.Name] = Animator:LoadAnimation(v);
      end;
    end;
  else
    for _, v in CharAnimations:GetChildren() do
      if v:IsA("Animation") then
        anims[v.Name] = Animator:LoadAnimation(v);
      end;
    end;
  end;
end;

do ---- Footsteps
  HumanoidRootPart:WaitForChild("Running").Volume = 0; -- disable default walk sfx
  local footstep1: Sound = Instance.new("Sound");
  footstep1.SoundId = "rbxassetid://79867504001965";
  footstep1.Parent = HumanoidRootPart;

  local footstep2: Sound = Instance.new("Sound");
  footstep2.SoundId = "rbxassetid://114223000992532";
  footstep2.Parent = HumanoidRootPart;

  local footstep3: Sound = Instance.new("Sound");
  footstep3.SoundId = "rbxassetid://101831533539194";
  footstep3.Parent = HumanoidRootPart;

  local footstep4: Sound = Instance.new("Sound");
  footstep4.SoundId = "rbxassetid://113597545053199";
  footstep4.Parent = HumanoidRootPart;

  local footstep5: Sound = Instance.new("Sound");
  footstep5.SoundId = "rbxassetid://109793629037912";
  footstep5.Parent = HumanoidRootPart;

  table.insert(footsteps, footstep1); table.insert(footsteps, footstep2); table.insert(footsteps, footstep3); table.insert(footsteps, footstep4); table.insert(footsteps, footstep5)
end;

-- Declarables

--- Constants
local Constants: Folder = AnimationConfigurations:WaitForChild("Constants");
----- Note: The ones without a comment are self-explanatory.
---- Stamina Constants
local WALKSPEED_ALPHA: number = Constants:WaitForChild("WALKSPEED_ALPHA").Value; -- smooth walkspeed transition
local WALK_SPEED: number = 8;
local RUN_SPEED: number = 24;
local STAMINA_DRAIN: number = 10;
local STAMINA_GAIN: number = 10;
local STAMINA_MAX: number = 100;
local WAIT_TIME: number = 0.1; -- put this at a low number for smoothness, higher for performance
local STAMINA_REGEN_COOLDOWN: number = 1.9; -- seconds to wait after depletion

---- Animation Constants
local IDLE_FADE_OFF: number = Constants:WaitForChild("IDLE_FADE_OFF").Value;
local WALK_FADE_OFF: number = Constants:WaitForChild("WALK_FADE_OFF").Value;
local RUN_FADE_OFF: number = Constants:WaitForChild("RUN_FADE_OFF").Value;
local LEANING_ALPHA: number = Constants:WaitForChild("LEANING_ALPHA").Value; -- smooth leaning
local HEAD_HORIZONTAL_MAX: number = .5;
local HEAD_VERTICAL_MAX: number = .5;
local ORIG_ROOT_JOINT: CFrame = HumanoidRootPart.RootJoint.C0;
local ORIG_NECK_JOINT: CFrame = NeckAttachment.C0;
--- Variables

---- Stamina Variables
local currentlyRunning: boolean = false;
local currentStamina: number = 100;
local displayedStamina: number = 100;
local displayedSpeed: number = WALK_SPEED;
local extraSpeed: number = 8;
local canRegenStamina: boolean = true;
local stopLoop: boolean = false;
local regenAvailableTime: number = 0 -- timestamp when stamina regen is allowed;

---- Animation Variables
local currentSound: Sound;
local previewAngleX: number = 0;
local previewAngleY: number = 0;
local previewHeadRot: Vector3;
local displayedAngleX: number = 0;
local displayedAngleY: number = 0;
local displayedHeadRot: Vector3;
local direction: Vector3;
local velocity: Vector3;

-- Interface
local infoBillboard: BillboardGui = Interface:WaitForChild("InfoBillboard");
infoBillboard.Adornee = Character.PrimaryPart;
infoBillboard.Parent = Character;

local staminaBar: Frame = infoBillboard:WaitForChild("StaminaBar");
local staminaVisualizer: Frame = staminaBar:WaitForChild("StaminaVisualizer");
local staminaAmount: TextLabel = staminaBar:WaitForChild("StaminaAmount");
local healthBar: Frame = infoBillboard:WaitForChild("HealthBar");
local healthVisualizer: Frame = healthBar:WaitForChild("HealthVisualizer");
local healthAmount: TextLabel = healthBar:WaitForChild("HealthLabel");

-- Helper Functions
--- Play a random footstep sound
local function playRandomFootstep()
  currentSound = footsteps[math.random(1, #footsteps)];
  currentSound:Play();
  currentSound = nil;
end;

--- Change if the player is running or not
local function changeRunningState(input: InputObject, gameProcessedEvent: boolean, state: boolean)
  if gameProcessedEvent then return end;
  if input.KeyCode == Enum.KeyCode.LeftShift then
    currentlyRunning = state;
  end;
end;

local Movement = {}

function Movement.new()
  local loop: thread;

  do -- The Main Function!
    loop = task.spawn(function()
      while not stopLoop do 
        do -- Main Logic
          local now = os.clock();

          -- Check if enough time has passed to allow stamina regen
          if not canRegenStamina and now >= regenAvailableTime then
            canRegenStamina = true;
          end;

          if currentlyRunning then
            if HumanoidRootPart.AssemblyLinearVelocity.Magnitude <= 0.2 then -- Standing still while on run state
              if canRegenStamina then
                currentStamina += STAMINA_GAIN * WAIT_TIME;
              end;
            else
              currentStamina -= STAMINA_DRAIN * WAIT_TIME;
              if currentStamina <= 0 then
                currentStamina = 0;
                currentlyRunning = false;
                canRegenStamina = false;
                regenAvailableTime = os.clock() + STAMINA_REGEN_COOLDOWN;
              end;
            end;
          else
            if canRegenStamina then
              currentStamina += STAMINA_GAIN * WAIT_TIME;
            end;
          end;

          -- Clamp stamina
          if currentStamina >= STAMINA_MAX then
            currentStamina = STAMINA_MAX;
          elseif currentStamina <= 0 then
            currentStamina = 0;
          end;
        end;

        do -- Visuals
          do -- Animation
            local velocityMagnitude: number = HumanoidRootPart.AssemblyLinearVelocity.Magnitude;
            anims["Walk"]:AdjustSpeed(velocityMagnitude / WALK_SPEED / 2);
            anims["Run"]:AdjustSpeed(velocityMagnitude / RUN_SPEED);

            if velocityMagnitude <= 0.1 then
              if anims["Walk"].IsPlaying then anims["Walk"]:Stop(WALK_FADE_OFF) end;
              if anims["Run"].IsPlaying then anims["Run"]:Stop(RUN_FADE_OFF) end;
              if not anims["Idle"].IsPlaying then anims["Idle"]:Play(IDLE_FADE_OFF) end;
            elseif not currentlyRunning then
              if not anims["Walk"].IsPlaying then  anims["Walk"]:Play(WALK_FADE_OFF) end;
              if anims["Run"].IsPlaying then anims["Run"]:Stop(RUN_FADE_OFF) end;
              if anims["Idle"].IsPlaying then anims["Idle"]:Stop(IDLE_FADE_OFF) end;
            elseif currentlyRunning then
              if anims["Walk"].IsPlaying then anims["Walk"]:Stop(WALK_FADE_OFF) end;
              if not anims["Run"].IsPlaying then anims["Run"]:Play(RUN_FADE_OFF) end;
              if anims["Idle"].IsPlaying then anims["Idle"]:Stop(IDLE_FADE_OFF) end;
            end;
          end;

          do -- Leaning Calculations
            velocity = HumanoidRootPart.AssemblyLinearVelocity;
            if velocity.Magnitude > 2 then
              direction = velocity.Unit;
              previewAngleY = HumanoidRootPart.CFrame.RightVector:Dot(direction) / 8;
              previewAngleX = HumanoidRootPart.CFrame.LookVector:Dot(direction) / 8;
            else
              previewAngleY = 0; previewAngleX = 0;
            end;
          end;

          do -- Head Facing
            local camCF: CFrame = Camera.CFrame;
            local headCF: CFrame = Head.CFrame;
            local torsoLookVec: Vector3 = Character:WaitForChild("Torso").CFrame.LookVector;
            local dist: number = (camCF.Position - headCF.Position).Magnitude;
            local diff: number = headCF.Y - camCF.Y;
            local asin = math.asin(diff / dist);
            local headCross = ((headCF.Position - camCF.Position).Unit:Cross(torsoLookVec)).Y;
            previewHeadRot = NeckAttachment.C0:Lerp(ORIG_NECK_JOINT * CFrame.Angles(
              -1 * asin * HEAD_VERTICAL_MAX, 0, -1 * headCross * HEAD_HORIZONTAL_MAX
              ), 0.5);
          end;
        end;

        do -- Finalize values and display
          displayedAngleY = math.lerp(displayedAngleY, previewAngleY * (extraSpeed / 16 + 1), LEANING_ALPHA);
          displayedAngleX = math.lerp(displayedAngleX, previewAngleX * (extraSpeed / 13 + 1), LEANING_ALPHA);
          displayedHeadRot = previewHeadRot;
          displayedSpeed = math.lerp(Humanoid.WalkSpeed, (currentlyRunning and RUN_SPEED or WALK_SPEED) + extraSpeed, WALKSPEED_ALPHA);
          displayedStamina = math.round(currentStamina);
          Humanoid.WalkSpeed = displayedSpeed;
          HumanoidRootPart.RootJoint.C0 = ORIG_ROOT_JOINT * CFrame.Angles(displayedAngleX, -displayedAngleY, 0);
          NeckAttachment.C0 = displayedHeadRot;
          staminaAmount.Text = tostring(displayedStamina);
          staminaVisualizer.Size = UDim2.new(1, 0, currentStamina / STAMINA_MAX, 0);
        end;

        task.wait(WAIT_TIME);
        -- No more task.spawn for stamina regen needed here!
        -- Removed buggy canRegenStamina reset here ^^
      end;
    end);
  end;

  do -- Connections
    -- Input Conns
    local inputStarted: RBXScriptConnection; inputStarted = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
      changeRunningState(input, gameProcessedEvent, true);
    end);

    local inputEnded: RBXScriptConnection; inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
      changeRunningState(input, gameProcessedEvent, false);
    end);

    -- Footstep Conns

    local walkConn: RBXScriptConnection;
    local runConn: RBXScriptConnection;
    if Constants:WaitForChild("FOOTSTEPS_ENABLED").Value then
      walkConn = anims["Walk"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);
      runConn = anims["Run"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);
    end;

    script:WaitForChild("Event").Event:Connect(function(event: string) 
      if anims[event] then
        if AbilityConfigurations and AbilityConfigurations:FindFirstChild(event) then
          anims[event].Looped = false;
          anims[event].Priority = Enum.AnimationPriority.Action;
          anims[event]:Play(AbilityConfigurations[event].FadeTime.Value, AbilityConfigurations[event].Weight.Value, AbilityConfigurations[event].Speed.Value);
        else
          anims[event].Looped = false;
          anims[event].Priority = Enum.AnimationPriority.Action;
          anims[event]:Play(0.1, 100, 1);
        end;

      end;
    end);
    local healthConn: RBXScriptConnection = Humanoid.HealthChanged:Connect(function(health: number) 
      healthAmount.Text = tostring(math.round(health));
      healthVisualizer.Size = UDim2.new(1, 0, health / Humanoid.MaxHealth, 0);
    end);

    -- Cleanup upon character death
    Humanoid.Died:Connect(function() 
      stopLoop = true;
      if inputStarted then
        inputStarted:Disconnect();
        inputStarted = nil;
      end;
      if inputEnded then
        inputEnded:Disconnect();
        inputEnded = nil;
      end;
      if walkConn then
        walkConn:Disconnect();
        walkConn = nil;
      end;
      if runConn then
        runConn:Disconnect();
        runConn = nil;
      end;
      loop = nil;
    end);
  end;

  print("Running stamina system!");
end;
--- The Code


return Movement
