import sys
import os
from warnings import warn

from .compat import filename_decode, filename_encode

from .base import phil, with_phil
#                                  from .group import Group
from .. import h5, h5f, h5p, h5i, h5fd, _objects, h5es
from .. import version




class Eventset():
	
	def __init__(self, es_id=None):
		"""
		if es_id is specified, set es_id.es_id to the specified value
		if not, then create a new es_id with H5EScreate
		"""
		if es_id is not None:
			if type(es_id) != int:
				raise ValueError("es_id must be an int")
			elif es_id < 0:
				raise ValueError("Negative number are not allowed")
			self.es_id=es_id
		else:
			self.es_id=h5es.create()
		self.num_in_progress = 0
		self.op_failed = False
	     
	
	def wait(self, timeout):
		forever = 2*sys.maxsize +1
		if timeout > forever:
			raise ValueError("Too large value for timeout, the maximum number is 18446744073709551615")	
		elif timeout < 0:
			raise ValueError("Negative number are not allowed")
		else:
			h5es.wait(self, timeout=timeout)
        

	def close(self):
		return h5es.close(self)

 
