-- Notes:
--- Assistant was made to fix some faults, but not to make the script.

local Movement = {};
Movement.__index = Movement;

-- Sources
--- Services
local UserInputService: UserInputService = game:GetService("UserInputService");

--- References
local Player: Player = game:GetService("Players").LocalPlayer;

function Movement.new(character)
  local self = setmetatable({}, Movement);

  local Character: Model = character or Player.CharacterAdded:Wait();
  local Humanoid: Humanoid = Character:WaitForChild("Humanoid");
  local HumanoidRootPart: Part = Character:WaitForChild("HumanoidRootPart");
  local Head: Part = Character:WaitForChild("Head");
  local StaminaValues: Folder = Character:WaitForChild("StaminaValues", 1) or nil;
  local CharAnimations: Folder =  Character:WaitForChild("MovementAnims", 1) or script:WaitForChild("Movement"); -- Default Animations
  local Animator: Animator = Humanoid:WaitForChild("Animator");
  local AnimationConfigurations: Folder = script:WaitForChild("Configurations");
  local AbilityConfigurations: Folder = script:FindFirstChild("AbilityConfigurations") or nil;
  local Camera: Camera = workspace.CurrentCamera;
  local Interface = script:WaitForChild("Interface");

  local NeckAttachment: Motor6D =  Character:WaitForChild("Torso"):WaitForChild("Neck"); NeckAttachment.MaxVelocity = 1 / 3;

  -- Internal Storage
  --- Containers
  local anims: {AnimationTrack} = {};
  local footsteps: {Sound} = {};

  -- Declarables

  --- Constants
  local Constants: Folder = AnimationConfigurations:WaitForChild("Constants");
  ----- Note: The ones without a comment are self-explanatory.
  ---- Stamina Constants
  local SPEED_CHANGE_ALPHA: number = Constants:WaitForChild("WALKSPEED_ALPHA").Value -- smooth walkspeed transition
  local WALK_SPEED: NumberValue = StaminaValues and StaminaValues:WaitForChild("WALK_SPEED") or Instance.new("NumberValue"); 
  WALK_SPEED.Value = (WALK_SPEED.Value ~= 0 and WALK_SPEED.Value) or 8;
  local RUN_SPEED: NumberValue = StaminaValues and StaminaValues:WaitForChild("RUN_SPEED") or Instance.new("NumberValue");
  RUN_SPEED.Value = (RUN_SPEED.Value ~= 0 and RUN_SPEED.Value) or 24;
  local STAMINA_DRAIN: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA_DRAIN") or Instance.new("NumberValue");
  STAMINA_DRAIN.Value = (STAMINA_DRAIN.Value ~= 0 and STAMINA_DRAIN.Value) or 10;
  local STAMINA_GAIN: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA_GAIN") or Instance.new("NumberValue");
  STAMINA_GAIN.Value = (STAMINA_GAIN.Value ~= 0 and STAMINA_GAIN.Value) or 10;
  local STAMINA_MAX: NumberValue = StaminaValues and StaminaValues:WaitForChild("STAMINA_MAX") or Instance.new("NumberValue");
  STAMINA_MAX.Value = (STAMINA_MAX.Value ~= 0 and STAMINA_MAX.Value) or 100;
  local extra_speed: NumberValue = StaminaValues and StaminaValues:WaitForChild("ExtraSpeed") or Instance.new("NumberValue");
  extra_speed.Value = 0; -- was originally 8 but changed it for convenience
  
  local WAIT_TIME: number = 0.1; -- put this at a low number for smoothness, higher for performance
  local STAMINA_REGEN_COOLDOWN: number = 1.9; -- seconds to wait after depletion
  
  ---- Ability Constants
  local DASH_COOLDOWN: number = 30;
  local DASH_SOUND: Sound = Instance.new("Sound");
  DASH_SOUND.SoundId = "rbxassetid://103660195159597"; DASH_SOUND.Parent = Character.PrimaryPart;
  local DASH_SPEED: number = 60;
  local DASH_LENGTH: number = 3 / 2; -- calculate for the for loop in its respective function
  local PUNCH_COOLDOWN: number = 30;
  local PUNCH_SOUND: Sound = Instance.new("Sound");
  PUNCH_SOUND.SoundId = "rbxassetid://123796710194563"; PUNCH_SOUND.Parent = Character.PrimaryPart;
  local PUNCH_DAMAGE: number = 20;
  
  ---- Animation Constants
  local IDLE_FADE_OFF: number = Constants:WaitForChild("IDLE_FADE_OFF").Value;
  local WALK_FADE_OFF: number = Constants:WaitForChild("WALK_FADE_OFF").Value;
  local RUN_FADE_OFF: number = Constants:WaitForChild("RUN_FADE_OFF").Value;
  local LEANING_ALPHA: number = Constants:WaitForChild("LEANING_ALPHA").Value;
  local HEAD_HORIZONTAL_MAX: number = .7;
  local HEAD_VERTICAL_MAX: number = .5;
  local ORIG_ROOT_JOINT: CFrame = HumanoidRootPart.RootJoint.C0;
  local ORIG_NECK_JOINT: CFrame = NeckAttachment.C0;
  
  --- Variables
  ---- OOP Variables
  local currentInstance;
  
  ---- Ability Variables
  local isActionable: boolean = true;
  local canDash: boolean = true;
  local currentDashCooldown: number = 0;
  local canPunch: boolean = true;
  local currentPunchCooldown: number = 0;
  
  ---- Stamina Variables
  local currentlyRunning: boolean = false;
  local currentStamina: number = STAMINA_MAX.Value;
  local displayedStamina: number = STAMINA_MAX.Value;
  local displayedSpeed: number = WALK_SPEED.Value;
  local canRegenStamina: boolean = true;
  local stopLoop: boolean = false;
  local regenAvailableTime: number = 0; -- timestamp when stamina regen is allowed

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
  --- Info Billboard
  local infoBillboard: BillboardGui = Interface:WaitForChild("InfoBillboard"):Clone();
  infoBillboard.Adornee = Character.PrimaryPart;
  infoBillboard.Parent = Character;
  ---- Stamina
  local staminaBar: Frame = infoBillboard:WaitForChild("StaminaBar");
  local staminaVisualizer: Frame = staminaBar:WaitForChild("StaminaVisualizer");
  local staminaAmount: TextLabel = staminaBar:WaitForChild("StaminaAmount");
  ---- Health
  local healthBar: Frame = infoBillboard:WaitForChild("HealthBar");
  local healthVisualizer: Frame = healthBar:WaitForChild("HealthVisualizer");
  local healthAmount: TextLabel = healthBar:WaitForChild("HealthLabel");
  ---- Abilities
  local abilitiesFrame: Frame = infoBillboard:WaitForChild("Abilities");
  local dashFrame: Frame = abilitiesFrame:WaitForChild("Template"):Clone();
  local labelCooldownDash: TextLabel = dashFrame:WaitForChild("LabelCooldown");
  dashFrame.Name = "Dash"; dashFrame.Parent = abilitiesFrame; dashFrame.Visible = true;
  
  local punchFrame: Frame = abilitiesFrame:WaitForChild("Template"):Clone();
  local labelName: TextLabel = punchFrame:WaitForChild("LabelName");
  local labelCooldownPunch: TextLabel = punchFrame:WaitForChild("LabelCooldown");
  punchFrame.Name = "Punch"; punchFrame.Parent = abilitiesFrame; labelName.Text = "Punch"; punchFrame:WaitForChild("Display").Image = "rbxassetid://13050670424"; punchFrame.Visible = true; 
  
  -- Helper Functions
  
  --- Dash Ability
  local function initDash(): ()
    if (not canDash and not isActionable) then return end; -- buffer
    isActionable = false; canDash = false; currentDashCooldown = DASH_COOLDOWN;
    local preservedGain: number, preservedDrain: number = STAMINA_GAIN.Value, STAMINA_DRAIN.Value;
    do -- Main Ability
      anims["Dash"]:Play();
      DASH_SOUND:Play();
      extra_speed.Value = -24;
      STAMINA_GAIN.Value = 0; STAMINA_DRAIN.Value = 0;
      for i = 1, DASH_LENGTH * 20 do
        local lookVector: Vector3 = Character.PrimaryPart.CFrame.LookVector;
        Character.PrimaryPart.AssemblyLinearVelocity = lookVector * DASH_SPEED;
        task.wait(0.05);
      end;
    end;
   
    do -- After effect
      extra_speed.Value = -6;
      STAMINA_DRAIN.Value = preservedDrain * 2;
      anims["Dash"]:Stop();
      task.wait(1.5);
      STAMINA_GAIN.Value = preservedGain;
      STAMINA_DRAIN.Value = preservedDrain;
      extra_speed.Value = 0;
      task.wait(1);
      isActionable = true;
      preservedGain, preservedDrain = nil;
    end;
  end;
  
  -- Punch Ability
  local function initPunch(): ()
    if (not canPunch and not isActionable) then return end; -- buffer
    isActionable = false; canPunch = false; currentPunchCooldown = PUNCH_COOLDOWN;
    anims["Punch"]:Play();
    PUNCH_SOUND:Play()
    extra_speed.Value = -7;
    task.wait(0.3);
    print("i am supposed to release a hitbox");
    task.wait(1.7);
    extra_speed.Value = 0;
    task.wait(1);
    isActionable = true;
  end
  
  --- Play a random footstep sound
  local function playRandomFootstep(): ()
    currentSound = footsteps[math.random(1, #footsteps)];
    currentSound:Play();
    currentSound = nil;
  end;

  --- Register player input
  local function registerInput(input: InputObject, gameProcessedEvent: boolean, state: boolean): ()
    if (gameProcessedEvent) then return end;
    if (input.KeyCode == Enum.KeyCode.LeftShift) then
      currentlyRunning = state;
    elseif (input.KeyCode == Enum.KeyCode.C and canDash and isActionable) then
      initDash()
    elseif (input.KeyCode == Enum.KeyCode.V and canPunch and isActionable) then
      initPunch()
    end;
  end;

  do -- Create visuals
    do ---- Animations
      for _, v in CharAnimations:GetChildren() do
        if (v:IsA("Animation")) then
          anims[v.Name] = Animator:LoadAnimation(v);
        end;
      end;
      anims["Dash"]:AdjustSpeed(2);
    end;

    do ---- Footsteps
      HumanoidRootPart:WaitForChild("Running", 1).Volume = 0; -- disable default walk sfx
      local footstep1: Sound = Instance.new("Sound");
      footstep1.SoundId = "rbxassetid://79867504001965";
      footstep1.Parent = HumanoidRootPart

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
  end;

  -- Store connections for cleanup
  self._connections = {};
  self._loop = nil;
  self._stopLoop = false;

  -- The Main Function!
  self._loop = task.spawn(function()
    while (not self._stopLoop) do 
      do -- Main Logic
        local now = os.clock();

        -- Check if enough time has passed to allow stamina regen
        if (not canRegenStamina and now >= regenAvailableTime) then
          canRegenStamina = true;
        end;

        if (currentlyRunning) then
          if (HumanoidRootPart.AssemblyLinearVelocity.Magnitude <= 0.2) then -- Standing still while on run state
            if (canRegenStamina) then
              currentStamina += STAMINA_GAIN.Value * WAIT_TIME;
            end;
          else
            currentStamina -= STAMINA_DRAIN.Value * WAIT_TIME;
            if (currentStamina <= 0) then
              currentStamina = 0;
              currentlyRunning = false;
              canRegenStamina = false;
              regenAvailableTime = os.clock() + STAMINA_REGEN_COOLDOWN;
            end;
          end;
        else
          if (canRegenStamina) then
            currentStamina += STAMINA_GAIN.Value * WAIT_TIME;
          end;
        end;

        -- Clamp stamina
        if (currentStamina >= STAMINA_MAX.Value) then
          currentStamina = STAMINA_MAX.Value;
        elseif (currentStamina <= 0) then
          currentStamina = 0;
        end;
        
        Humanoid.WalkSpeed = displayedSpeed;
      end;

      do -- Visuals
        do -- Animation
          if (not anims["Dash"].IsPlaying) then
            local velocityMagnitude: number = HumanoidRootPart.AssemblyLinearVelocity.Magnitude;
            anims["Walk"]:AdjustSpeed(velocityMagnitude / WALK_SPEED.Value / 2);
            anims["Run"]:AdjustSpeed(velocityMagnitude / RUN_SPEED.Value);

            if (velocityMagnitude <= 0.1) then
              if (anims["Walk"].IsPlaying) then anims["Walk"]:Stop(WALK_FADE_OFF); end;
              if (anims["Run"].IsPlaying) then anims["Run"]:Stop(RUN_FADE_OFF); end;
              if (not anims["Idle"].IsPlaying) then anims["Idle"]:Play(IDLE_FADE_OFF); end;
            elseif not currentlyRunning then
              if (not anims["Walk"].IsPlaying) then anims["Walk"]:Play(WALK_FADE_OFF); end;
              if (anims["Run"].IsPlaying) then anims["Run"]:Stop(RUN_FADE_OFF); end;
              if (anims["Idle"].IsPlaying) then anims["Idle"]:Stop(IDLE_FADE_OFF); end;
            elseif currentlyRunning then
              if (anims["Walk"].IsPlaying) then anims["Walk"]:Stop(WALK_FADE_OFF); end;
              if (not anims["Run"].IsPlaying) then anims["Run"]:Play(RUN_FADE_OFF); end;
              if (anims["Idle"].IsPlaying) then anims["Idle"]:Stop(IDLE_FADE_OFF); end;
            end;
          else
            if (anims["Walk"].IsPlaying) then anims["Walk"]:Stop(WALK_FADE_OFF); end;
            if (anims["Run"].IsPlaying) then anims["Run"]:Stop(RUN_FADE_OFF); end;
            if (anims["Idle"].IsPlaying) then anims["Idle"]:Stop(IDLE_FADE_OFF); end;
          end;
        end;

        do -- Leaning Calculations
          velocity = HumanoidRootPart.AssemblyLinearVelocity;
          if (velocity.Magnitude > 2) then
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
        displayedAngleY = math.lerp(displayedAngleY, previewAngleY * (extra_speed.Value / 16 + 1), LEANING_ALPHA);
        displayedAngleX = math.lerp(displayedAngleX, previewAngleX * (extra_speed.Value / 13 + 1), LEANING_ALPHA);
        displayedHeadRot = previewHeadRot;
        displayedSpeed = math.lerp(Humanoid.WalkSpeed, (currentlyRunning and RUN_SPEED.Value or WALK_SPEED.Value) + extra_speed.Value, SPEED_CHANGE_ALPHA);
        displayedStamina = math.round(currentStamina);
        Humanoid.WalkSpeed = displayedSpeed;
        HumanoidRootPart.RootJoint.C0 = ORIG_ROOT_JOINT * CFrame.Angles(displayedAngleX, -displayedAngleY, 0);
        NeckAttachment.C0 = displayedHeadRot;
        staminaAmount.Text = tostring(displayedStamina);
        staminaVisualizer.Size = UDim2.new(1, 0, currentStamina / STAMINA_MAX.Value, 0);
        labelCooldownDash.Text = tostring(math.round(currentDashCooldown));
        currentDashCooldown -= 1 * WAIT_TIME; if (currentDashCooldown < 0) then currentDashCooldown = 0; canDash = true; end;
        labelCooldownPunch.Text = tostring(math.round(currentPunchCooldown));
        currentPunchCooldown -= 1 * WAIT_TIME; if (currentPunchCooldown < 0) then currentPunchCooldown = 0; canPunch = true; end;
      end;

      task.wait(WAIT_TIME);
      -- No more task.spawn for stamina regen needed here!
      -- Removed buggy canRegenStamina reset here ^^
    end;
  end);

  do -- Connections
    -- Input Conns
    local inputStarted = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
      registerInput(input, gameProcessedEvent, true);
    end);
    table.insert(self._connections, inputStarted);

    local inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
      registerInput(input, gameProcessedEvent, false);
    end);
    table.insert(self._connections, inputEnded);

    -- Footstep Conns
    local walkConn;
    local runConn;
    if (Constants:WaitForChild("FOOTSTEPS_ENABLED").Value) then
      walkConn = anims["Walk"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);
      runConn = anims["Run"]:GetMarkerReachedSignal("footstep"):Connect(playRandomFootstep);
      table.insert(self._connections, walkConn);
      table.insert(self._connections, runConn);
    end;

    -- Used for animation playing, to be used later
    local eventConn = script:WaitForChild("Event").Event:Connect(function(event: string) 
      if (anims[event]) then
        if (AbilityConfigurations and AbilityConfigurations:FindFirstChild(event)) then
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
    table.insert(self._connections, eventConn);
    
    local healthConn = Humanoid.HealthChanged:Connect(function(health: number) 
      healthAmount.Text = tostring(math.round(health));
      healthVisualizer.Size = UDim2.new(1, 0, health / Humanoid.MaxHealth, 0);
    end);
    table.insert(self._connections, healthConn);
    
    -- Cleanup upon character death or character change
    local diedConn = Humanoid.Died:Connect(function()
      self:stop();
    end);
    table.insert(self._connections, diedConn);
  end
  workspace.CurrentCamera.CameraSubject = Character:WaitForChild("Humanoid")
  print("Running stamina system!");

  return self;
end;

function Movement:stop()
  -- Stop the main loop
  self._stopLoop = true;
  if (self._loop) then
    -- task.cancel is only available in newer Luau, fallback to setting flag
    self._loop = nil;
  end;
  -- Disconnect all connections
  for _, conn in self._connections do
    if (conn and conn.Disconnect) then
      conn:Disconnect();
    end;
  end;
  self._connections = {};
end;

return Movement
