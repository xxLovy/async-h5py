import sys
import os
from warnings import warn

from .compat import filename_decode, filename_encode

from .base import phil, with_phil
#                                  from .group import Group
from .. import h5, h5f, h5p, h5i, h5fd, _objects, h5es
from .. import version




class Es():
	
	def __init__(self):
		self.id=h5es.create()
	
	def wait(self, timeout):
		return h5es.wait(self.id, timeout=timeout)
		
	def close(self):
		return h5es.close(self.id)
