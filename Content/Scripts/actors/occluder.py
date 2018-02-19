# coding: utf-8

import unreal_engine as ue
from unreal_engine import FVector, FRotator
from unreal_engine.classes import Material, StaticMesh
from unreal_engine.enums import ECollisionChannel
from actors.baseMesh import BaseMesh
import tools.materials

"""
Ok here we go:
This is a recursive instantiate class.
The general principle is to instantiate a class twice to avoid making two distinct classes.
I needed to instantiate a python component with parameters but UnrealEnginePython
wouldn't let me do that.
Furthermore, I couldn't spawn the actor without instanciate the class and thus,
I couldn't spawn it with any parameter.

Let me explain myself :
In the main, I call the constructor of the class Object (for instance, or Floor, or Occluder),
which call the __init__ function of Object with at least 1 argument, world
which call the __init__function of BaseMesh with at least 1 argument, mesh_str.
In the Object __init__ function, I call actor_spawn,
which implicitely instanciate Object (yes, again)
BUT during the second instantiation, no parameters is given to __init__ (of Object and BaseMesh)
(this is why there is default values to every parameters of __init__).
Thus, if __init__ is called without any parameters, I know that it is the second instantiation,
so I don't spawn the actor again.
Once the object spawned, all I have to do is to set the parameters in the second instantiation
(location, rotation,...).
Et voilà !
"""

"""
Occluder is the vertical plane thing that sometimes fall and sometimes get up by itself.
Sounds weird, it is.
It inherits from BaseMesh.
"""

class Occluder(BaseMesh):
    def __init__(self, world = None,
                 location = FVector(0, 0, 0),
                 rotation = FRotator(0, 0, 0),
                 scale = FVector(1, 1, 1),
                 material = tools.materials.get_random_material(tools.materials.load_materials('Materials/Wall'))):
        if (world != None):
            BaseMesh.__init__(self, world.actor_spawn(ue.load_class('/Game/Occluder.Occluder_C')),
                              '/Game/Meshes/OccluderWall',
                              location,
                              rotation,
                              ue.load_object(Material, material),
                              scale)
        else:
            BaseMesh.__init__(self)