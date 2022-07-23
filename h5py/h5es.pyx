# This file is part of h5py, a Python interface to the HDF5 library.
#
# http://www.h5py.org
#
# Copyright 2008-2013 Andrew Collette and contributors
#
# License:  Standard 3-clause BSD; see "license.txt" for full license terms
#           and contributor agreement.

from ._objects cimport pdefault
from ._objects import phil, with_phil



def create():
	return H5EScreate()
	
	
	
def wait(es_id, timeout):
	cdef size_t num_in_progress
	cdef hbool_t op_failed
	
	return H5ESwait(es_id, timeout, &num_in_progress, &op_failed)
	
	
def close(es_id):
	return H5ESclose(es_id)
	
