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
	
	
	
def wait(es_id, uint64_t timeout):
    cdef size_t num_in_progress
    cdef hbool_t op_failed
    H5ESwait(es_id.es_id, timeout, &num_in_progress, &op_failed)
    es_id.num_in_progress = num_in_progress
    
    if op_failed == 0:
        es_id.op_failed = False
    else:
        es_id.op_failed = True	
	
def close(es_id):
    H5ESclose(es_id.es_id)
    

cdef class EsObjectID():
    property es_id:
        def __get__(self):
            return int(self.es_id)
    
            
    
