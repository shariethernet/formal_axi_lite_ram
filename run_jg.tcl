# ----------------------------------------
#  Copyright (c) 2017 Cadence Design Systems, Inc. All Rights
#  Reserved.  Unpublished -- rights reserved under the copyright 
#  laws of the United States.
# ----------------------------------------

# Analyze design under verification files


analyze -v2k \
 axil_ram.v

# Analyze property files
analyze -sva \
 bindfile.sv\
 axilite_prop_pkg.sv
  
# Elaborate design and properties
elaborate -top axil_ram

# Set up Clocks and Resets
clock clk
reset rst

# Get design information to check general complexity
get_design_info

# Prove properties
prove -all

# Report proof results
report

