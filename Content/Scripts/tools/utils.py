"""Defines general utility functions used by intphys"""

import json
import os

import unreal_engine as ue
from unreal_engine.classes import KismetSystemLibrary, GameplayStatics



# TODO Does not exit the game immediately, find better
def exit_ue(world, message=None):
    """Quit the game, optionally logging an error message

    `world` is the world reference from the running game.
    `message` is the error message to be looged.

    """
    if message:
        ue.log_error(message)

    # KismetSystemLibrary.QuitGame(world)
    world.quit_game()


def set_game_paused(world, paused):
    """Pause/unpause the game

    `paused` is a boolean value

    """
    GameplayStatics.SetGamePaused(world, paused)


def set_game_resolution(world, resolution):
    """Set the game and captured images resolution

    `resolution` is a tuple of (width, height) in pixels

    """
    # cast resolution to string
    resolution = (str(r) for r in resolution)

    # command that change the resolution
    command = 'r.SetRes {}'.format('x'.join(resolution))

    # execute the command
    KismetSystemLibrary.ExecuteConsoleCommand(world, command)


def intphys_root_directory():
    """Return the absolute path to the intphys root directory"""
    # guess it from the evironment variable first, or from the
    # relative path from here
    try:
        root_dir = os.environ['INTPHYS_ROOT']
    except:
        root_dir = os.path.join(os.path.dirname(__file__), '../..')

    # make sure the directory is the good one
    assert os.path.isdir(root_dir)
    assert 'intphys.py' in os.listdir(root_dir)

    return os.path.abspath(root_dir)


def parse_scenes_json(world, scenes_json):
    """Return a list of scenarii to be generated by the director

    Parameters
    ----------
    world : UE World
        The game's world hosting the scenes's rendering
    scenes_json : file
        A JSON file defining the scenes to render. For an exemple of
        such a file, see intphys/Exemples/exemple.json. Defines a
        number of train and test scenes to execute for each scenario.

    Returns
    -------
    A list of instances of scenario classes (derived from scenario.base.Base)

    """
    from scenario.factory import get_train_scenario, get_test_scenario

    # load the JSON as a dictionary
    scenes_dict = json.loads(open(scenes_json, 'r').read())

    # fill the scenes to render while parsing the dict
    scenes = []

    # iterate on the scenarii defined in the dict
    for scenario, cases in scenes_dict.items():
        # 'scenario_O1' -> 'O1'
        scenario = scenario.split('_')[1]

        for k, v in cases.items():
            # train case, v is the number of scenes to generate
            if 'train' in k:
                nscenes = v
                scenes += [get_train_scenario(scenario) for _ in range(nscenes)]

            # test scenes in the form 'test_visible' or 'test_occluded'
            else:
                is_occluded = 'occluded' in k
                for condition, nscenes in v.items():
                    # condition is 'static', 'dynamic_1' or 'dynamic_2'
                    is_static = 'static' in condition
                    ntricks = 2 if condition.endswith('2') else 1
                    scenes += [
                        get_test_scenario(scenario, is_occluded, is_static, ntricks)
                        for _ in range(nscenes)]

    return scenes
