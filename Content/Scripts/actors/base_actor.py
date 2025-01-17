import unreal_engine as ue
from tools.utils import as_dict


class BaseActor():
    """BaseActor is the very base of the actors inheritance tree

    It is the base class of every python component build with an actor
    (all of them, though).  Beware : this is a recursive instantiation
    (see comments at the begining of other classes) Therefore, don't
    try to use the self.actor before the actor_spawn function is
    called in child class.

    Parameters
    ----------
    actor: UObject
        The spawned actor

    """
    def __init__(self, actor=None):
        self.actor = actor

    def actor_destroy(self):
        if self.actor is not None:
            self.actor.actor_destroy()
            self.actor = None
        self.actor = None

    def get_parameters(self, location, rotation, overlap, warning):
        self.location = location
        self.rotation = rotation
        self.overlap = overlap
        self.warning = warning

    def set_parameters(self):
        self.set_location(self.location)
        self.set_rotation(self.rotation)
        self.hidden = False

        # manage OnActorBeginOverlap events
        if self.warning and self.overlap:
            self.actor.bind_event('OnActorBeginOverlap', self.on_actor_overlap)
        if self.warning and not self.overlap:
            self.actor.bind_event('OnActorHit', self.on_actor_hit)

    def get_actor(self):
        # this getter is important : in the recursive instance, it's
        # an internal unreal engine function called get_actor which is
        # called so wherever you call get_actor(), it will works
        return self.actor

    def set_actor(self, actor):
        self.actor = actor

    def set_location(self, location):
        self.location = location
        if not self.actor.set_actor_location(self.location, False):
            ue.log_warning('Failed to set the location of an actor')
            return False
        return True

    def set_rotation(self, rotation):
        if not self.actor.set_actor_rotation(rotation):
            # the set_actor_rotation is very strict, looks for
            # equality in asked and obtained rotation. We tolerate an
            # epsilon of e-3.
            r0, r1 = rotation, self.actor.get_actor_rotation()
            rd = [abs(d) for d in (
                r0.roll - r1.roll, r0.yaw - r1.yaw, r0.pitch - r1.pitch)]
            if max(rd) > 1e-3:
                ue.log_warning(
                    f'Failed to set the rotation of {self.actor.get_name()}, '
                    f'asked {str(r0)} but have {str(r1)}')
                return False

        self.rotation = self.actor.get_actor_rotation()
        return True

    def on_actor_overlap(self, me, other):
        """Raises a Runtime error when some actor overlaps this object"""
        if (me == other):
            return
        message = '{} overlapping {}'.format(
            self.actor.get_name(), other.get_name())
        ue.log_error(message)

    def on_actor_hit(self, me, other, *args):
        if (other.get_name()[:5] == "Floor"):
            return
        message = '{} hitting {}'.format(
            self.actor.get_name(), other.get_name())
        ue.log_error(message)

    def set_hidden(self, hidden):
        self.hidden = hidden
        self.actor.SetActorHiddenInGame(hidden)

    def get_status(self):
        status = {
            'name': self.actor.get_name(),
            'location': as_dict(self.location),
            'rotation': as_dict(self.rotation)}
        return status
