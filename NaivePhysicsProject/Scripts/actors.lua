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


-- This module manages the physics actors in the scene (i.e. the
-- actors submitted to physical laws, such as spheres or cubes). It
-- provides to main functions: p = get_random_parameters() generates
-- parameters and initialize(p) setup the actors in the scene for the
-- given parameters.

local uetorch = require 'uetorch'
local material = require 'material'


local actors_bank = {
   sphere = {
      assert(uetorch.GetActor('Sphere_1')),
      assert(uetorch.GetActor('Sphere_2')),
      assert(uetorch.GetActor('Sphere_3'))},

   cube =  {
      assert(uetorch.GetActor('Cube_1')),
      assert(uetorch.GetActor('Cube_2')),
      assert(uetorch.GetActor('Cube_3'))},

   cylinder =  {
      assert(uetorch.GetActor('Cylinder_1')),
      assert(uetorch.GetActor('Cylinder_2')),
      assert(uetorch.GetActor('Cylinder_3'))},
}


local active_actors, nactors = {}, 0

-- true if the actor is currently active in the scene
local function is_active_actor(actor)
   for _, a in pairs(active_actors) do
      if a == actor then
         return true
      end
   end
   return false
end


local M = {}


-- Return a table of parameters for the given actors
--
-- `t_actors` is a table of (actor_shape -> n). For exemple, the table
--     {'sphere' = 2, 'cube' = 1}) will generate parameters for
--     sphere_1, sphere_2 and cube_1.
--
-- The returned table has the format (actor_name -> actor_params),
-- where actor_params is also a table with the following structure:
--    {material, scale, location={x, y, z}, force={x, y, z}}
function M.get_random_parameters(t_actors)
   local p = {}
   for shape, n in pairs(t_actors) do
      for i = 1, n do
         local name = shape .. '_' .. tostring(i)
         assert(M.is_valid_name(name))
         p[name] = M.get_random_actor_parameters(name)
      end
   end
   return p
end


-- Initialize scene's physics actors given their parameters
--
-- Setup actors location, scale, force and material of parametrized
-- actors, destroy the unused actors.
--
-- `params` is a table of (actor_name -> actor_params), for exemple as
--     returned by the get_random_parameters() method. Each actor name
--     must be valid and the actor params must have the following
--     structure: {material, scale, location={x, y, z}, force={x, y,
--     z}}, where the 'force' entry is optional.
--
-- `bounds` is an optional table of scene boundaries structured as
--     {xmin, xmax, ymin, ymax}. When used the actors location s
--     forced to be in thoses bounds.
function M.initialize(params, bounds)
   for actor_name, actor_params in pairs(params) do
      local a = M.get_actor(actor_name)
      local p = actor_params

      -- stay in the bounds
      if bounds then
         p.location.x = math.max(bounds.xmin, p.location.x)
         p.location.x = math.min(bounds.xmax, p.location.x)
         p.location.y = math.max(bounds.ymin, p.location.y)
         p.location.y = math.min(bounds.ymax, p.location.y)
      end

      -- setup material, scale and location
      material.set_actor_material(a, material.actor_materials[p.material])
      uetorch.SetActorScale3D(a, p.scale, p.scale, p.scale)
      uetorch.SetActorLocation(a, p.location.x, p.location.y, p.location.z)

      -- setup force if required
      if p.force then
         uetorch.AddForce(a, p.force.x, p.force.y, p.force.z)
      end

      -- register the new actor as active in the scene
      active_actors[actor_name] = a
      nactors = nactors + 1
   end

   -- destroy the actors not parametrized: for all active actors in
   -- the bank, if it is not an active actor, destroy it
   for _, v in pairs(actors_bank) do
      for _, actor in ipairs(v) do
         if not is_active_actor(actor) then
            uetorch.DestroyActor(actor)
         end
      end
   end
end


-- Return true if `name` is a valid name in the actors bank
function M.is_valid_name(name)
   local shape = name:gsub('_.*$', '')
   local idx = name:gsub('^.*_', '')

   if actors_bank[shape] and tonumber(idx) <= #(actors_bank[shape]) then
      return true
   else
      return false
   end
end


-- Return an actor from its name e.g. cube_1 or sphere_3
function M.get_actor(name)
   local shape = name:gsub('_.*$', '')
   local idx = name:gsub('^.*_', '')

   return assert(actors_bank[shape][tonumber(idx)])
end


-- Return the table (name -> actor) of the active actors
--
-- Active actors are those initialized from parameters
function M.get_active_actors()
   return active_actors
end


-- Return the number of active actors
function M.get_nactors()
   return nactors
end


-- Return a random texture for an actor
function M.random_material()
   return math.random(#material.actor_materials)
end


-- Return 'left' or 'right' with 50% chance
function M.random_side()
   if math.random(0, 1) == 1 then
      return 'left'
   else
      return 'right'
   end
end


-- Return a random scale coefficient for an actor
function M.random_scale()
   return math.random() + 1.5
end


-- Return a random location for the actor `name`
--
-- `name` must be the name of an active actor
-- `side` must be 'left' or 'right'
function M.random_location(name, side)
   local idx = name:gsub('^.*_', '')

   local l = {
      x = -400,
      y = -550 - 150 * (tonumber(idx) - 1),
      z =  70 + math.random(200)
   }

   if side == 'right' then
      l.x = 500
   end

   return l
end


-- Return true or false: 25% chance the actor don't move
function M.random_static()
   return (math.random() < 0.25)
end


-- Return a random force vector applied to an actor
function M.random_force(side)
   local sign_z = 2 * math.random(2) - 3 -- -1 or 1

   local f = {
      x = math.random(5e5, 2e6),
      y = math.random(-1e6, 5e5),
      z = sign_z * math.random(8e5, 1e6)
   }

   if side == 'right' then
      f.x = -1 * f.x
   end

   return f
end


-- Return random parameters for a single actor given its name
function M.get_random_actor_parameters(name)
   local p = {}
   local side = M.random_side()

   p.material = M.random_material()
   p.scale = M.random_scale()
   p.location = M.random_location(name, side)
   if M.random_static() then
      p.force = M.random_force(side)
   end

   return p
end


return M