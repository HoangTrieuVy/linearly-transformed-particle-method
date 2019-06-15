import os
import sys

import numpy as np

h = 0.08

outDir = sys.argv[1]

#______________________________________________________________________#
#
# SP method 
#______________________________________________________________________#

N_arr = np.array([25, 50, 100, 200, 500, 1000, 2000, 5000, 10000])
dt_arr = np.array([0.01, 0.001, 0.0001, 0.00001])
q_arr =  np.array([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1., 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8])
epsilon_arr = h**q_arr




#______________________________________________________________________#
#
# LTP method hybrid
#______________________________________________________________________#


CFL = dt/h
delta_arr = CFL * np.array([0.001, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1., 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8])
epsilon_arr = (1+delta_arr) * h
print delta_arr
