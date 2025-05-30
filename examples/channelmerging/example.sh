#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p output

echo "=========================================================================="
echo "Generating mesh with VEWs from channel, non-channel, and background meshes"
echo "=========================================================================="


echo ""
echo "1. Combining channel and non-channel meshes with VEWs"
echo "-----------------------------------------------------"
python -m vewutils.mesh.mesh_merger input/channel.14 input/non-channel.14 -b vew -o output/ch_la.14 -d 'merged: channel + non-channel with VEWs' 

echo ""
echo "2. Combining channel and non-channel meshes by merging overlapping nodes"
echo "------------------------------------------------------------------------"
python -m vewutils.mesh.mesh_merger input/channel.14 input/non-channel.14 -b merge -o output/ch_la_mgd.14 -d 'merged: channel + non-channel with merged nodes' 

echo ""
echo ""
echo "3. Subtracting channel + non-channel coverage from background"
echo "-------------------------------------------------------------"
python -m vewutils.mesh.mesh_subtractor input/background.14 output/ch_la_mgd.14 -o output/background_subtracted.14 -d 'subtracted: background - (channel + non-channel)'

echo ""
echo ""
echo "4. Merging channel, non-channel, and subtracted background"
echo "-----------------------------------------------------------"
python -m vewutils.mesh.mesh_merger output/ch_la.14 output/background_subtracted.14 -b merge -o output/ch_la_bg.14 -d 'merged: background_subtracted + channel + non-channel'

echo ""
echo ""
echo "5. Adding land boundaries to the merged mesh"
echo "--------------------------------------------"
python -m vewutils.mesh.add_land_boundaries output/ch_la_bg.14 -o output/ch_la_bg_lb.14 -d 'merged: background_subtracted + channel + non-channel with land boundaries'

echo ""
echo ""
echo "6. Ensuring elevations of VEW channel nodes to be lower than bank nodes"
echo "-----------------------------------------------------------------------"
python -m vewutils.mesh.adjust_vew_channel_elevations output/ch_la_bg_lb.14 -o output/ch_la_bg_lb_adjusted1.14

echo ""
echo ""
echo "7. Adjusting VEW barrier heights to be above the bank nodes"
echo "-----------------------------------------------------------"
python -m vewutils.mesh.adjust_vew_barrier_heights output/ch_la_bg_lb_adjusted1.14 -o output/ch_la_bg_lb_adjusted2.14

echo ""
echo ""
echo "8. Copying nodal attributes in the background mesh to the new mesh"
echo "------------------------------------------------------------------"
python -m vewutils.nodalattribute.attribute_transfer input/background.14 input/background.13 output/ch_la_bg_lb_adjusted2.14 -o output/ch_la_bg_lb_adjusted2.13

echo ""
echo ""
echo "9. Updating Manning's n values in the new mesh"
echo "----------------------------------------------"
echo "9.1 Selecting channel mesh nodes from the new mesh"
echo "--------------------------------------------------"
python -m vewutils.utils.node_selector output/ch_la_bg_lb_adjusted2.14 -o output/ch_la_bg_lb_adjusted2_channel_mesh_nodes.csv -m output/ch_la_mgd.14

echo ""
echo "9.2 Updating Manning's n values at the selected nodes"
echo "-----------------------------------------------------"
python -m  vewutils.nodalattribute.manningsn_extractor output/ch_la_bg_lb_adjusted2.14 input/ccap_landuse_sample.tif -s output/ch_la_bg_lb_adjusted2_channel_mesh_nodes.csv input/ccap_class_to_mn_openwater0.02.csv -f output/ch_la_bg_lb_adjusted2.13 -o output/ch_la_bg_lb_adjusted2_mn_updated.13 --format fort13

echo ""
echo "All done!"
