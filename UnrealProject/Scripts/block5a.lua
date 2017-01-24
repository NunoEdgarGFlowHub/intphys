-- Copyright 2016, 2017 Mario Ynocente Castro, Mathieu Bernard
--
-- You can redistribute this file and/or modify it under the terms of
-- the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.


local uetorch = require 'uetorch'
local config = require 'config'
local utils = require 'utils'
local material = require 'material'
local block = {}

local sphere = uetorch.GetActor("Sphere_1")
local wall = uetorch.GetActor("Occluder_1")
local wall_boxY
local wall2 = uetorch.GetActor("Occluder_2")
block.actors = {sphere=sphere, wall=wall}

local rebound = false
local possible = true

local isHidden
local params = {}

local iterationId
local iterationType
local iterationBlock
local iterationPath

local camera = uetorch.GetActor("MainMap_CameraActor_Blueprint_C_1")
local floor = uetorch.GetActor('Floor')

local function InitSphere()
   if params.left == 1 then
      uetorch.SetActorLocation(sphere, -400, -550, params.sphereZ)
      if rebound then
         uetorch.SetActorLocation(wall2, 0, -750, 20)
      end
   else
      uetorch.SetActorLocation(sphere, 500, -550, params.sphereZ)
      if rebound then
         uetorch.SetActorLocation(wall2, 150, -750, 20)
      end
      params.forceX = -params.forceX
   end

   uetorch.AddForce(sphere, params.forceX, params.forceY, params.signZ * params.forceZ)
end

local t_rotation = 0
local t_rotation_change = 0

local function WallRotationDown(dt)
   local angle = (t_rotation - t_rotation_change) * 60
   uetorch.SetActorRotation(wall, 0, 0, angle)
   uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + math.sin(angle * math.pi / 180) * wall_boxY)
   if angle >= 90 then
      uetorch.RemoveTickHook(WallRotationDown)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function RemainUp(dt)
   params.framesRemainUp = params.framesRemainUp - 1
   if params.framesRemainUp == 0 then
      uetorch.RemoveTickHook(RemainUp)
      uetorch.AddTickHook(WallRotationDown)
   end
end

local function WallRotationUp(dt)
   local angle = (t_rotation - t_rotation_change) * 60
   uetorch.SetActorRotation(wall, 0, 0, 90 - angle)
   uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + math.sin((90 - angle) * math.pi / 180) * wall_boxY)
   if angle >= 90 then
      uetorch.RemoveTickHook(WallRotationUp)
      uetorch.AddTickHook(RemainUp)
      t_rotation_change = t_rotation
   end
   t_rotation = t_rotation + dt
end

local function StartDown(dt)
   params.framesStartDown = params.framesStartDown - 1
   if params.framesStartDown == 0 then
      uetorch.RemoveTickHook(StartDown)
      uetorch.AddTickHook(WallRotationUp)
   end
end

function block.SetBlock(currentIteration)
   iterationId, iterationType, iterationBlock, iterationPath
      = config.GetIterationInfo(currentIteration)

   if iterationType == 0 then
      material.SetActorMaterial(sphere, "GreenMaterial")
      material.SetActorMaterial(wall, "BlackMaterial")

      params = {
         ground = math.random(#material.ground_materials),
         sphereZ = 200 + math.random(150),
         forceX = math.random(1800000, 2200000),
         forceY = 0,
         forceZ = 0,
         signZ = 2 * math.random(2) - 3,
         left = math.random(0,1),
         framesStartDown = math.random(5),
         framesRemainUp = math.random(5),
         scaleW = 1 - 0.1 * math.random(),
         scaleH = 1
      }

      WriteJson(params, iterationPath .. '../params.json')
   else
      isHidden = torch.load(iterationPath .. '../hidden.t7')
      params = ReadJson(iterationPath .. '../params.json')

      if iterationType == 1 then
         rebound = false
         possible = true
      elseif iterationType == 2 then
         rebound = true
         possible = false
      end
   end
end

function block.RunBlock()
   material.SetActorMaterial(floor, material.ground_materials[params.ground])
   uetorch.AddTickHook(StartDown)
   uetorch.SetActorLocation(camera, 100, 30, 80)

   uetorch.SetActorScale3D(wall, params.scaleW, 1, params.scaleH)
   uetorch.SetActorScale3D(wall, params.scaleW, 1, params.scaleH)
   wall_boxY = uetorch.GetActorBounds(wall)['boxY']
   uetorch.SetActorLocation(wall, 100 - 200 * params.scaleW, -350, 20 + wall_boxY)
   uetorch.SetActorRotation(wall, 0, 0, 90)

   InitSphere()

   if rebound then
      uetorch.SetActorRotation(wall2, 0, 90, 0)
      uetorch.SetActorVisible(wall2, false)
   end
end

function block.IsPossible()
   return possible
end

return block
