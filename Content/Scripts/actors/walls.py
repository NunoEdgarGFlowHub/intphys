from actors.wall import Wall
from actors.parameters import WallsParams
from tools.materials import get_random_material_for_category

"""
Walls is a wrapper class that make 3 walls spawn.
"""


class Walls():
    def __init__(self, world=None, params=WallsParams):
        self.get_parameters(params)
        self.front = Wall(world, "Front",
                          self.length, self.depth,
                          self.height, self.material, self.overlap, self.warning)

        self.right = Wall(world, "Right",
                          self.length, self.depth,
                          self.height, self.material, self.overlap, self.warning)

        self.left = Wall(world, "Left",
                          self.length, self.depth,
                          self.height, self.material, self.overlap, self.warning)

    def actor_destroy(self):
        self.front.actor_destroy()
        self.right.actor_destroy()
        self.left.actor_destroy()

    def get_parameters(self, params):
        self.depth = params.depth
        self.length = params.length
        self.height = params.height

        self.material = params.material
        if self.material is None:
            self.material = get_random_material_for_category('Wall')

        self.overlap = False
        self.warning = False

    def get_status(self):
        return {'depth': self.depth, 'length': self.length, 'height': self.height}
