# coding: utf-8

import unreal_engine as ue
from unreal_engine import FVector, FRotator
from unreal_engine.classes import Material
from actors.base_mesh import BaseMesh

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
Wall is the vertical plane thing
It inherits from BaseMesh.
"""


class Wall(BaseMesh):
    """
    __init__ instantiate the class
    parameters ->
    world: UEngine world instance
    side: the wall you wanna build compared to the floor
    (either "Back, "Front", "Left" or "Right"). Default: "Front"
    material: material of the actor (UObject). Default value: a random one in the relevant directory

    You can't pass the location, direction and so on of the wall as parameter
    because it is not needed, I gess
    If you need it anyway, help yourself
    Just for you to know, there is a formula in the location to make that the reference point
    of the location is the center of the mesh, not the corner in the left back
    formula = 'the place where you want it to be' - (('size of the mesh' * 'scale') / 2
    Disclaimer: if you change the size of the mesh, think about changing the formula
    """
    def __init__(self,
                 world=None,
                 side='Front',
                 length=2000,
                 depth=1000,
                 height=1,
                 material=None,
                 overlap=False,
                 warning=False):
        self.sides = {
            'Front': self.front,
            'Left': self.left,
            'Right': self.right
        }
        if (world is not None):
            super().__init__(world.actor_spawn(ue.load_class('/Game/Wall.Wall_C')))
            self.get_parameters(side, length, depth,
                                height, material, overlap, warning)
            self.set_parameters()
        else:
            super().__init__()

    def get_parameters(self, side, length,
                       depth, height, material,
                       overlap, warning):
        self.depth = depth
        self.length = length
        self.height = height
        self.side = side
        self.sides[self.side]()
        super().get_parameters(self.location, self.rotation, self.scale,
                               0.5, 0.5, overlap, warning,
                               '/Game/Meshes/Wall_400x400')
        self.material = ue.load_object(Material, material)

    def set_parameters(self):
        super().set_parameters()

    def front(self):
        self.scale = FVector(self.length / 400, 1, self.height)
        self.rotation = FRotator(0, 0, 90)
        self.location = FVector(self.depth, (-1 * self.length) / 2, 0)

    def left(self):
        self.scale = FVector(self.depth / 400, 1, self.height)
        self.rotation = FRotator(0, 0, 0)
        self.location = FVector(0, (-1 * self.length) / 2, 0)

    def right(self):
        self.scale = FVector(self.depth / 400, 1, self.height)
        self.rotation = FRotator(0, 0, 0)
        self.location = FVector(-0, self.length / 2, 0)

    def get_status(self):
        status = super().get_status()
        status['side'] = self.side
        status['length'] = self.length
        status['height'] = self.height
        status['depth'] = self.depth
        status['material'] = self.material.get_name()
        return status
