

from metpy.io.gini import GiniFile



gini = GiniFile("WEST-CONUS_4km_IR_20180205_1145.gini")
gini_ds = gini.to_dataset()
print(gini_ds)


data_var=gini_ds.variables['IR']
# #print(data_var)
#
x = gini_ds.variables['x'][:]
y = gini_ds.variables['y'][:]

proj_var = gini_ds.variables[data_var.grid_mapping]
# #print
print(proj_var)

import cartopy.crs as ccrs

# Create a Globe specifying a spherical earth with the correct radius
globe = ccrs.Globe(ellipse='sphere', semimajor_axis=proj_var.earth_radius,
                    semiminor_axis=proj_var.earth_radius)

proj = ccrs.LambertConformal(central_longitude=proj_var.longitude_of_central_meridian,
                              central_latitude=proj_var.latitude_of_projection_origin,
                              standard_parallels=[proj_var.standard_parallel],
                              globe=globe)


# # Make sure the notebook puts figures inline
# #%matplotlib inline

import matplotlib.pyplot as plt


# Create a new figure with size 10" by 10"
fig = plt.figure(figsize=(8.6, 10))


# Put a single axes on this figure; set the projection for the axes to be our
# Lambert conformal projection
ax = fig.add_subplot(1, 1, 1, projection=proj)
# Ajusta la imagen al plot
plt.subplots_adjust(left=0, bottom=0, right=1, top=1, wspace=0, hspace=0)






# Add high-resolution coastlines to the plot
ax.coastlines(resolution='50m', color='yellow')

import cartopy.feature as cfeat

print(cfeat.BORDERS)
# Add country borders with a thick line.

# #ax.add_feature(cfeat.BORDERS, linewidth='2', edgecolor='black')
ax.add_feature(cfeat.BORDERS, linewidth=2, edgecolor='yellow')

# Set up a feature for the state/province lines. Tell cartopy not to fill in the polygons
state_boundaries = cfeat.NaturalEarthFeature(category='cultural',
                                              name='admin_1_states_provinces_lines',
                                              scale='50m', facecolor='none')

land_boundaries = cfeat.NaturalEarthFeature(category='physical',
                                              name='lakes',
                                              scale='50m', facecolor='none')

# Add the feature with dotted lines, denoted by ':'
ax.add_feature(state_boundaries, linestyle=':', edgecolor='yellow')
ax.add_feature(land_boundaries, linestyle='-.', edgecolor='yellow')



# print(x[:])
# print(x[-1])
print(data_var[:])

import numpy as N
print(N.amax(data_var[:]))
#print(a)

#
from metpy.plots.ctables import registry
wv_norm, wv_cmap = registry.get_with_range('ir_bd', 0, 38)

#wv_norm, wv_cmap = registry.get_with_steps('ir_bd', 0, 1)
# #im.set_cmap(wv_cmap)
# #im.set_norm(wv_norm)
#
#
#
# Plot the data using a simple greyscale colormap (with black for low values);
# set the colormap to extend over a range of values from 140 to 255.
# Note, we save the image returned by imshow for later...
im = ax.imshow(data_var[:], extent=(x[0], x[-1], y[-1], y[0]),origin='upper',
                cmap=wv_cmap, norm=wv_norm)
#
#
#
#
#
# #plt.tight_layout()
plt.show()
# #plt.savefig('prueba.png')
