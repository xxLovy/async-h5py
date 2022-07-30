import sys
import os
from warnings import warn

from .compat import filename_decode, filename_encode

from .base import phil, with_phil
#                                  from .group import Group
from .. import h5, h5f, h5p, h5i, h5fd, _objects, h5es
from .. import version




class Eventset():
	
	def __init__(self):
		self.es_id=h5es.create()
		self.num_in_progress = 0
		self.op_failed = False
	
	def wait(self, timeout):
		forever = 18446744073709551615
		if timeout < 0:
			timeout = forever
			h5es.wait(self, timeout=timeout)
			return
		if timeout <= forever:
			h5es.wait(self, timeout=timeout)
			return
		try:
			if timeout > forever:
				raise ValueError("ValueError: Too large value for timeout, the maximum number is 18446744073709551615")
		except ValueError as v:
			print(v)
        

	def close(self):
		return h5es.close(self.es_id)

 