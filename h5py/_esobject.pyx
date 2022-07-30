# This file is part of h5py, a Python interface to the HDF5 library.
#
# http://www.h5py.org
#
# Copyright 2008-2013 Andrew Collette and contributors
#
# License:  Standard 3-clause BSD; see "license.txt" for full license terms
#           and contributor agreement.

"""
    Implements ObjectID base class.
"""

include "_locks.pxi"
from .defs cimport *

DEF USE_LOCKING = True
DEF DEBUG_ID = False

# --- Locking code ------------------------------------------------------------
#
# Most of the functions and methods in h5py spend all their time in the Cython
# code for h5py, and hold the GIL until they exit.  However, in some cases,
# particularly when calling native-Python functions from the stdlib or
# elsewhere, the GIL can be released mid-function and another thread can
# call into the API at the same time.
#
# This is bad news, especially for the object identifier registry.
#
# We serialize all access to the low-level API with a single recursive lock.
# Only one thread at a time can call any low-level routine.
#
# Note that this doesn't affect other applications like PyTables which are
# interacting with HDF5.  In the case of the identifier registry, this means
# that it's possible for an identifier to go stale and for PyTables to reuse
# it before we've had a chance to set obj.id = 0.  For this reason, h5py is
# advertised for EITHER multithreaded use OR use alongside PyTables/NetCDF4,
# but not both at the same time.

IF USE_LOCKING:
    cdef FastRLock _phil = FastRLock()
ELSE:
    cdef BogoLock _phil = BogoLock()

# Python alias for access from other modules
phil = _phil

def with_phil(func):
    """ Locking decorator """

    import functools

    def wrapper(*args, **kwds):
        with _phil:
            return func(*args, **kwds)

    functools.update_wrapper(wrapper, func)
    return wrapper

# --- End locking code --------------------------------------------------------


# --- Registry code ----------------------------------------------------------
#
# With HDF5 1.8, when an identifier is closed its value may be immediately
# re-used for a new object.  This leads to odd behavior when an ObjectID
# with an old identifier is left hanging around... For example, a GroupID
# belonging to a closed file could suddenly "mutate" into one from a
# different file.
#
# There are two ways such "zombie" identifiers can arise.  The first is if
# an identifier is explicitly closed via obj._close().  For this case we
# set obj.id = 0.  The second is that certain actions in HDF5 can *remotely*
# invalidate identifiers.  For example, closing a file opened with
# H5F_CLOSE_STRONG will also close open groups, etc.
#
# When such a "nonlocal" event occurs, we have to examine all live ObjectID
# instances, and manually set obj.id = 0.  That's what the function
# nonlocal_close() does.  We maintain an inventory of all live ObjectID
# instances in the registry dict.  Then, when a nonlocal event occurs,
# nonlocal_close() walks through the inventory and sets the stale identifiers
# to 0.  It must be explicitly called; currently, this happens in FileID.close()
# as well as the high-level File.close().
#
# The entire low-level API is now explicitly locked, so only one thread at at
# time is taking actions that may create or invalidate identifiers. See the
# "locking code" section above.
#
# See also __cinit__ and __dealloc__ for class ObjectID.

import gc
import weakref
import warnings

# Will map id(obj) -> weakref(obj), where obj is an ObjectID instance.
# Objects are added only via ObjectID.__cinit__, and removed only by
# ObjectID.__dealloc__.
cdef dict registry = {}

@with_phil
def print_reg():
    import h5py
    refs = registry.values()
    objs = [r() for r in refs]

    none = len([x for x in objs if x is None])
    files = len([x for x in objs if isinstance(x, h5py.h5f.FileID)])
    groups = len([x for x in objs if isinstance(x, h5py.h5g.GroupID)])

    print("REGISTRY: %d | %d None | %d FileID | %d GroupID" % (len(objs), none, files, groups))


@with_phil
def nonlocal_close():
    """ Find dead ObjectIDs and set their integer identifiers to 0.
    """
    cdef ObjectID obj
    cdef list reg_ids

    # create a cached list of ids whilst the gc is disabled to avoid hitting
    # the cyclic gc while iterating through the registry dict
    gc_was_enabled = gc.isenabled()
    gc.disable()
    try:
        reg_ids = list(registry)
    finally:
        if gc_was_enabled:
            gc.enable()

    for python_id in reg_ids:
        ref = registry.get(python_id)

        # registry dict has changed underneath us, skip to next item
        if ref is None:
            continue

        obj = ref()

        # Object died while walking the registry list, presumably because
        # the cyclic GC kicked in.
        if obj is None:
            continue

        # Locked objects are immortal, as they generally are provided by
        # the HDF5 library itself (property list classes, etc.).
        if obj.locked:
            continue

        # Invalid object; set obj.id = 0 so it doesn't become a zombie
        if not H5Iis_valid(obj.id):
            IF DEBUG_ID:
                print("NONLOCAL - invalidating %d of kind %s HDF5 id %d" %
                        (python_id, type(obj), obj.id) )
            obj.id = 0
            continue

# --- End registry code -------------------------------------------------------


cdef class EsObjectID:
    
   	def __init__(self):
		self.id=h5es.create()
	
	def wait(self, timeout):
		return h5es.wait(self.id, timeout=timeout)
		
	def close(self):
		return h5es.close(self.id)

    if obj.locked:
        return True

    # Former zombie object
    if obj.id == 0:
        return False

    # Ask HDF5.  Note that H5Iis_valid only works for "user"
    # identifiers, hence the above checks.
    with _phil:
        return H5Iis_valid(obj.id)
