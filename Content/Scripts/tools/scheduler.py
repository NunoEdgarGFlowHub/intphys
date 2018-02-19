import os

import unreal_engine as ue

from tools.scene import TrainScene, TestScene
from tools.tick import Tick
from tools.utils import exit_ue

def parse_scenes_json(world, scenes_json):
    """Return a list of scenes to be generated by the scheduler

    Parameters
    ----------
    world : UE World
        The game's world hosting the scenes's rendering
    scenes_json : dict
        A dictionary loaded from an input scenes configuration
        file. For an exemple of such a file, see
        intphys/Exemples/exemple.json. Defines a number of train and
        test scenes to execute for each scenario.

    Returns
    -------
    A list of instances of TestScene and TrainScene

    """
    scenes = []
    # iterate on the blocks defined in the configuration
    for scenario, cases in scenes_json.items():
        # 'scenario_O1' -> 'O1'
        scenario = scenario.split('_')[1]

        for k, v in cases.items():
            if 'train' in k:
                nscenes = v
                scenes += [TrainScene(world, scenario)] * nscenes
            else:  # test scenes
                is_occluded = 'occluded' in k
                for condition, nscenes in v.items():
                    is_static = 'static' in condition
                    ntricks = 2 if condition.endswith('2') else 1
                    scenes += [TestScene(
                        world, scenario,
                        is_occluded, is_static, ntricks)] * nscenes

    return scenes


class Scheduler:
    def __init__(self, world, scenes_json, output_dir, dry_mode=False):
        self.world = world

        # generate the list of scenes from the input JSON file
        self.scenes_list = parse_scenes_json(self.world, scenes_json)
        ue.log('scheduling {nscenes} scenes, ({ntest} for test and '
               '{ntrain} for train), total of {nruns} runs'.format(
            nscenes=len(self.scenes_list),
            ntest=len([s for s in self.scenes_list if isinstance(s, TestScene)]),
            ntrain=len([s for s in self.scenes_list if isinstance(s, TrainScene)]),
            nruns=sum(s.get_nruns() for s in self.scenes_list)))

        self.current_scene_index = -1
        self.current_scene = None

        self.ticker = Tick(nticks=100)
        self.ticker.add_hook(self.schedule_next, 'final')

        self.schedule_next()

    def schedule_next(self):
        """Called at the end of a run, setup the next run for generation"""
        # if the current run failed, schedule the scene again
        # if not self.current_scene.is_valid():
        #     ue.log_warning('scene failed, retry it')
        #     self.current_scene.generate_parameters()
        #     self.current_scene.spawn_actors()

        # if there are remaining runs for the current scene, render
        # the next one
        # if self.current_scene.get_nruns_remaining() > 0:
        #     self.current_scene.setup_run()

        # else:  # new scene
        self.current_scene_index += 1
        if self.current_scene_index >= len(self.scenes_list):
            ue.log('all scenes rendered, exiting')
            exit_ue(self.world)
            return
        else:
            self.current_scene = self.scenes_list[self.current_scene_index]
            self.current_scene.current_run = 0
            # self.current_scene.generate_parameters()
            # self.current_scene.spawn_actors()

        # log a description of the current run
        description = 'rendering scene {}/{}'.format(
            self.current_scene_index+1, len(self.scenes_list))
        if isinstance(self.current_scene, TestScene):
            description += ', run {}/{}'.format(
                self.current_scene.current_run + 1, self.current_scene.get_nruns())
        ue.log(description)

        self.ticker.reset()
        self.current_scene.render()
        self.ticker.run()


    def tick(self, dt):
        self.ticker.tick(dt)