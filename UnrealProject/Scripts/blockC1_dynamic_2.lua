local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local material = require 'material'
local block = {}

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_0")
local floor = uetorch.GetActor('Floor')
local sphere = uetorch.GetActor("Sphere_4")
local sphere2 = uetorch.GetActor("Sphere9_4")
local sphere3 = uetorch.GetActor("Sphere10_7")
local spheres = {sphere, sphere2, sphere3}
local wall1 = uetorch.GetActor("Wall_400x200_8")
local wall2 = uetorch.GetActor("Wall_400x201_7")
local wall1_boxY,wall2_boxY
block.actors = {wall1=wall1, wall2=wall2}

local iterationId, iterationType, iterationBlock, iterationPath
local params = {}
local isHidden1,isHidden2

local visible1 = true
local visible2 = true
local possible = true
local trick1 = false
local trick2 = false

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125
   local succ = uetorch.SetActorRotation(wall1, 0, 0, angle)
   local succ2 = uetorch.SetActorRotation(wall2, 0, 0, angle)

   uetorch.SetActorLocation(
      wall1, -200 * params.scaleW, -350,
      20 + math.sin(angle * math.pi / 180) * wall1_boxY)

   uetorch.SetActorLocation(
      wall2, 300 - 200 * params.scaleW, -350,
      20 + math.sin(angle * math.pi / 180) * wall2_boxY)

   if angle >= 90 then
      utils.RemoveTickHook(WallRotationDown)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function RemainUp(dt)
   params.framesRemainUp = params.framesRemainUp - 1
   if params.framesRemainUp == 0 then
      utils.RemoveTickHook(RemainUp)
      utils.AddTickHook(WallRotationDown)
   end
end

local function WallRotationUp(dt)
   local angle = (t_rotation - t_rotation_change) * 20 * 0.125
   local succ = uetorch.SetActorRotation(wall1, 0, 0, 90 - angle)
   local succ2 = uetorch.SetActorRotation(wall2, 0, 0, 90 - angle)

   uetorch.SetActorLocation(
      wall1, -200 * params.scaleW, -350,
      20 + math.sin((90 - angle) * math.pi / 180) * wall1_boxY)

   uetorch.SetActorLocation(
      wall2, 300 - 200 * params.scaleW, -350,
      20 + math.sin((90 - angle) * math.pi / 180) * wall2_boxY)

   if angle >= 90 then
      utils.RemoveTickHook(WallRotationUp)
      utils.AddTickHook(RemainUp)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function StartDown(dt)
   params.framesStartDown = params.framesStartDown - 1
   if params.framesStartDown == 0 then
      utils.RemoveTickHook(StartDown)
      utils.AddTickHook(WallRotationUp)
   end
end

local tCheck, tLastCheck = 0, 0
local step = 0

local function Trick(dt)
   if tCheck - tLastCheck >= config.GetBlockCaptureInterval(iterationBlock) then
      step = step + 1

      if params.left[params.index] == 1 then
         if not trick1 and isHidden1[step] then
            trick1 = true
            uetorch.SetActorVisible(spheres[params.index], visible2)
         end

         if trick1 and not trick2 and isHidden2[step] then
            trick2 = true
            uetorch.SetActorVisible(spheres[params.index], visible1)
         end
      else
         if not trick1 and isHidden2[step] then
            trick1 = true
            uetorch.SetActorVisible(spheres[params.index], visible2)
         end

         if trick1 and not trick2 and isHidden1[step] then
            trick2 = true
            uetorch.SetActorVisible(spheres[params.index], visible1)
         end
      end

      tLastCheck = tCheck
   end
   tCheck = tCheck + dt
end


-- Return random parameters for the C1 dynamic_2 block
local function GetRandomParams()
   local params = {
      ground = math.random(#material.ground_materials),
      wall = math.random(#material.wall_materials),
      sphere = math.random(#material.sphere_materials),
      sphereZ = {
         70 + math.random(200),
         70 + math.random(200),
         70 + math.random(200)
      },
      forceX = {
         1600000,
         1600000,
         1600000
      },
      forceY = {0, 0, 0},
      forceZ = {
         math.random(800000, 1000000),
         math.random(800000, 1000000),
         math.random(800000, 1000000)
      },
      signZ = {
         2 * math.random(2) - 3,
         2 * math.random(2) - 3,
         2 * math.random(2) - 3,
      },
      left = {
         math.random(0,1),
         math.random(0,1),
         math.random(0,1),
      },
      framesStartDown = math.random(5),
      framesRemainUp = math.random(5),
      scaleW = 0.5,--1 - 0.5 * math.random(),
      scaleH = 1 - 0.4 * math.random(),
      n = math.random(1,3)
   }
   params.index = math.random(1, params.n)

   return params
end


local mainActor

function block.MainActor()
   return mainActor
end


function block.SetBlockTrain(currentIteration)
   iterationId, iterationType, iterationBlock, iterationPath =
      config.GetIterationInfo(currentIteration)

   local file = io.open (config.GetDataPath() .. 'output.txt', "a")
   file:write(currentIteration .. ", " ..
                 iterationId .. ", " ..
                 iterationType .. ", " ..
                 iterationBlock .. "\n")
   file:close()

   params = GetRandomParams()
   WriteJson(params, iterationPath .. 'params.json')

   visible1 = RandomBool()
   visible2 = visible1
   possible = true

   mainActor = spheres[params.index]
   for i = 1,params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end


function block.SetBlockTest(currentIteration)
   iterationId, iterationType, iterationBlock, iterationPath =
      config.GetIterationInfo(currentIteration)

   local file = io.open (config.GetDataPath() .. 'output.txt', "a")
   file:write(currentIteration .. ", " ..
                 iterationId .. ", " ..
                 iterationType .. ", " ..
                 iterationBlock .. "\n")
   file:close()

   if iterationType == 6 then
      if config.GetLoadParams() then
         params = ReadJson(iterationPath .. '../params.json')
      else
         params = GetRandomParams()
         WriteJson(params, iterationPath .. '../params.json')
      end

      uetorch.DestroyActor(wall2)
   else
      params = ReadJson(iterationPath .. '../params.json')

      if iterationType == 5 then
         uetorch.DestroyActor(wall1)
      else
         isHidden1 = torch.load(iterationPath .. '../hidden_6.t7')
         isHidden2 = torch.load(iterationPath .. '../hidden_5.t7')
         utils.AddTickHook(Trick)

         if iterationType == 1 then
            visible1 = false
            visible2 = false
            possible = true
         elseif iterationType == 2 then
            visible1 = true
            visible2 = true
            possible = true
         elseif iterationType == 3 then
            visible1 = false
            visible2 = true
            possible = false
         elseif iterationType == 4 then
            visible1 = true
            visible2 = false
            possible = false
         end
      end
   end

   mainActor = spheres[params.index]
   for i = 1,params.n do
      block.actors['sphere' .. i] = spheres[i]
   end
end

function block.RunBlock()
   -- camera
   uetorch.SetActorLocation(camera, 150, 30, 80)

   -- floor
   material.SetActorMaterial(floor, material.ground_materials[params.ground])

   -- walls
   material.SetActorMaterial(wall1, material.wall_materials[params.wall])
   material.SetActorMaterial(wall2, material.wall_materials[params.wall])
   utils.AddTickHook(StartDown)
   uetorch.SetActorScale3D(wall1, params.scaleW, 1, params.scaleH)
   uetorch.SetActorScale3D(wall2, params.scaleW, 1, params.scaleH)
   wall1_boxY = uetorch.GetActorBounds(wall1).boxY
   wall2_boxY = uetorch.GetActorBounds(wall2).boxY
   uetorch.SetActorLocation(wall1, -200 * params.scaleW, -350, 20 + wall1_boxY)
   uetorch.SetActorLocation(wall2, 300 - 200 * params.scaleW, -350, 20 + wall2_boxY)
   uetorch.SetActorRotation(wall1, 0, 0, 90)
   uetorch.SetActorRotation(wall2, 0, 0, 90)

   -- spheres
   uetorch.SetActorVisible(sphere, visible1)

   for i = 1,params.n do
      material.SetActorMaterial(spheres[i], material.sphere_materials[params.sphere])
      uetorch.SetActorScale3D(spheres[i], 0.9, 0.9, 0.9)
      if params.left[i] == 1 then
         uetorch.SetActorLocation(spheres[i], -400, -550 - 150 * (i - 1), params.sphereZ[i])
      else
         uetorch.SetActorLocation(spheres[i], 700, -550 - 150 * (i - 1), params.sphereZ[i])
         params.forceX[i] = -params.forceX[i]
      end
      uetorch.AddForce(
         spheres[i], params.forceX[i], params.forceY[i],
         params.signZ[i] * params.forceZ[i])
   end
end

local checkData = {}
local saveTick = 1

function block.SaveCheckInfo(dt)
   local aux = {}
   aux.location = uetorch.GetActorLocation(mainActor)
   aux.rotation = uetorch.GetActorRotation(mainActor)
   table.insert(checkData, aux)
   saveTick = saveTick + 1
end

local maxDiff = 1e-6

function block.Check()
   local status = true
   torch.save(iterationPath .. '../check_' .. iterationType .. '.t7', checkData)
   local file = io.open(config.GetDataPath() .. 'output.txt', "a")

   if iterationType == 6 then
      local isHidden1 = torch.load(iterationPath .. '../hidden_6.t7')
      local foundHidden = false
      for i = 1,#isHidden1 do
         if isHidden1[i] then
            foundHidden = true
         end
      end

      if not foundHidden then
         file:write("Iteration check failed on condition 1: not hidden in visibility check 1\n")
         status = false
      end
   end

   if iterationType == 5 then
      local isHidden2 = torch.load(iterationPath .. '../hidden_5.t7')
      local foundHidden = false
      for i = 1,#isHidden2 do
         if isHidden2[i] then
            foundHidden = true
         end
      end

      if not foundHidden then
         file:write("Iteration check failed on condition 1: not hidden in visibility check 2\n")
         status = false
      end
   end

   if iterationType < 6 and status then
      local iteration = utils.GetCurrentIteration()
      local ticks = config.GetBlockTicks(iterationBlock)
      local prevData = torch.load(iterationPath .. '../check_' .. (iterationType + 1) .. '.t7')

      for t = 1,ticks do
         -- check location values
         if(math.abs(checkData[t].location.x - prevData[t].location.x) > maxDiff) then
            status = false
         end
         if(math.abs(checkData[t].location.y - prevData[t].location.y) > maxDiff) then
            status = false
         end
         if(math.abs(checkData[t].location.z - prevData[t].location.z) > maxDiff) then
            status = false
         end
         -- check rotation values
         if(math.abs(checkData[t].rotation.pitch - prevData[t].rotation.pitch) > maxDiff) then
            status = false
         end
         if(math.abs(checkData[t].rotation.yaw - prevData[t].rotation.yaw) > maxDiff) then
            status = false
         end
         if(math.abs(checkData[t].rotation.roll - prevData[t].rotation.roll) > maxDiff) then
            status = false
         end
      end

      if not status then
         file:write("Iteration check failed on condition 2\n")
      end
   end

   if not status then
      file:write("Iteration check failed\n")
   elseif iterationType == 1 then
      file:write("Iteration check succeeded\n")
   end

   file:close()
   utils.UpdateIterationsCounter(status)
end

function block.IsPossible()
   return possible
end

return block