import numpy as np
import matplotlib.cm as cm
import  matplotlib.pyplot as plt
file_index = 2
filename = '../../dat/traj_%3d.dat' % file_index
data = np.loadtxt( filename )
px_0 = data[:, 0]
pz_0 = data[:, 1]
ts_re = data[:, 2]
ts_im = data[:, 3]
x0 = data[:, 4]
z0 = data[:, 5]
px = data[:, 6]
pz = data[:, 7]
L1 = data[:, 8]
L2 = data[:, 9]
M_re = data[:, 10]
M_im = data[:, 11]
n_step = data[:, 12]
ierr = data[:, 13]
w2 = M_re**2 + M_im**2
w2[w2<1e-99] = 1e-99

# x = M_re
# y = M_im
x = px[np.where(ts_re<240)]
y = ts_re[np.where(ts_re<240)]

xmin = x.min()
xmax = x.max()
ymin = y.min()
ymax = y.max()

fig = plt.figure(figsize=(6,10))
fig.canvas.set_window_title(filename) 
#plt.subplots_adjust(hspace=0.5)
plt.subplots_adjust(bottom=0.1, right=0.8, top=0.9)
plt.subplot(211)
plt.hexbin(x, y, gridsize=50, cmap=cm.jet, bins='log', C=w2)
#plt.xlim([-0.03, 0.03])
#plt.ylim([-0.03, 0.03])

#plt.axis([xmin, xmax, ymin, ymax])
plt.subplot(212)
plt.hexbin(x, y, gridsize=50, cmap=cm.jet, bins='log')
#plt.axis([xmin, xmax, ymin, ymax])
#plt.title("Hexagon binning with log color scale")
#cb = plt.colorbar()
#cb.set_label('log10(N)')
#plt.xlim([-0.03, 0.03])
#plt.ylim([-0.03, 0.03])
plt.savefig( '../fig/corr_%3d.png' % file_index )

plt.show()
