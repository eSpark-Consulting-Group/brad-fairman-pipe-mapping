# Pipe Mapping Product Design and Development
#### Client Name: Brad Fairman

## Project Requirements
The product consists of two PCBs and primary requirement is to develop firmware for those:
1. Control PCB (schematic pushed to github docs)
2. Probe PCB (schematic pushed to github docs)

The core requirements are:
- Probe PCB    
    - The probe PCB should interface with an IMU sensor to extract movement and direction information. The final sensor may or may not be 9DoF
    - The probe PCB should be able to report all information via RS-232 to the Control PCB
    - The probe PCB should handle basic edge cases such as:
    - Filter out fluctuations through averaging.
    - Only start to work and report data when the control signal sends the signal to start recording.
    - Should have capability to tare / reset the reading of IMU from Control PCB if required.
- Control PCB
    - The control PCB should be able to send control and read commands to Probe PCB (we can discuss and propose a protocol for implementation).
    - The control PCB should be able to interface with a laptop and map out the IMU data and distance information in a 3D visualizer.
    - The control PCB should be able to interface with an optical sensor to read the distance by counting black lines on a Fish Pipe.
    - The control PCB should actively note the directional data from IMU and use that information to decrease or increase distance (if the pipe is moving forward, increase distance and vice versa)
    - Basic edge case handling should be implemented for Control PCB. TBD.
