from actors.floor import Floor
from actors.light import Light
from actors.object import Object
from actors.occluder import Occluder
from actors.walls import Walls


def get_actor_class(name):
    classes = {
        'floor': Floor,
        'light': Light,
        'object': Object,
        'occluder': Occluder,
        'walls': Walls}

    for k, v in classes.items():
        if name.lower().startswith(k):
            return v

    raise ValueError('actor class unknown for {}'.format(name))


class Scene(object):
    """The scene renders a given `scenario` in a given `world`

    A scene is made of several runs. Train scenes are always a single
    run. Test scenes have 4 runs plus some check runs. The number of
    checks varies accross scenarii.

    Parameters
    ----------
    world: ue.uobject
       The game world in which to render the scene.
    scenario: child of scenario.base.Base
        The scenario to execute. A scenario defines the actors,
        generates parameters for them and implement the magic trick.

    """
    def __init__(self, world, scenario):
        self.world = world
        self.scenario = scenario
        self.current_run = 0

        # generate random parameters for the scene
        self.params = self.scenario.generate_parameters()

        # spawn the actors from generated params
        self.actors = {
            k: get_actor_class(k)(world=self.world, params=v)
            for k, v in self.params.items() if 'magic' not in k}

    def get_nruns_remaining(self):
        """Return the number of runs to render before the end of the scene"""
        return self.scenario.get_nruns() - self.current_run

    def description(self):
        desc = self.scenario.get_description()
        if self.scenario.get_nruns() > 1:
            desc += f' (run {self.current_run}/{self.scenario.get_nruns()})'
            if self.is_check_run():
                desc = desc[:-1] + ', check)'
        return desc

    def render(self, saver):
        """Setup the actors defined by the scenario to their initial state"""
        # replace the actors to their initial position
        self.reset()

        # update the run index
        self.current_run += 1

        # setup the magic actor before applying the magic trick
        actor = self.actors[self.params['magic']['actor']]
        self.scenario.setup_magic_trick(saver, actor, self.current_run)

    def run_magic(self, tick):
        if 'magic' not in self.params:
            return

        if tick == self.params['magic']['tick']:
            actor = self.actors[self.params['magic']['actor']]
            self.scenario.apply_magic_trick(actor, self.current_run)

    def clear(self):
        """Destroy all the actors in the scene"""
        for k, v in self.actors.items():
            v.actor_destroy()
        self.actors = {}

    def get_status(self):
        """Return the current status of each actor in the scene"""
        return {k: v.get_status() for k, v in self.actors.items()}

    def is_valid(self):
        """Return True when the scene is in valid state

        A scene can be invalid if some forbidden hit occured (e.g. an
        occluder overlapping the camera), or , for test scenes, if a
        check run failed.

        """
        # TODO
        return True

    def is_check_run(self):
        """Return True if the current run is a check"""
        if self.scenario.is_train():
            return False
        elif self.current_run <= self.scenario.get_nchecks():
            return True
        else:
            return False

    def get_moving_actors(self):
        """Return the dict of moving actors (objects and occluders)"""
        return {
            k: v for k, v in self.actors.items()
            if 'occluder' in k or 'object' in k}

    def reset(self):
        """Set all the actors to their initial location/rotation"""
        for k, v in self.get_moving_actors().items():
            v.set_location(self.params[k].location)
            v.set_rotation(self.params[k].rotation)
