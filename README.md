# BRADFAIRMAN-FISHPIPE-FIRMWARE
To develop firmware for fish-pipe mapping
## STEPS FOR COMPILING AND FLASHING 
### Required Softwares
1. [ESP32 Flash Download Tool](https://www.espressif.com/sites/default/files/tools/flash_download_tool_3.9.4.zip)
2. [Teapot Processing IDE](https://processing.org/download)

### Compiling & Flashing Procedure
1. Connect the ESP32 Dev Module to the PC via MicroUSB cable.
2. Open flash download tool and select options as shown in screenshot below and click OK to proceed.      
![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/eeeed66f-e3f0-4014-b35e-5e5686e71752)
3. Click erase button on new window that opens, to first completely wipe off the ESP32 memory.
4. Upload the provided [Code Binaries](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/tree/Development/Firmware-Development/Arduino/MPU6050_DMP6/Binaries) as follows:
    * MPU6050_DMP6.ino.bootloader.bin -> 0x1000
    * MPU6050_DMP6.ino.partitions.bin -> 0x8000
    * MPU6050_DMP6.ino.bin -> 0x10000
5. Select the COM Port and press the start button to start the flashing process as shown in screenshot below:
![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/df68ce66-abdf-4ec1-bc65-92f982b4d45a)

6. Once finished, close the software and reset the ESP32 using EN button on the Dev Module.

### Teapot Processing IDE
1. Open the Processing IDE, go to [GUI_Code](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/tree/Development/Firmware-Development/Teapot/3D_representation) and open it.
![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/0c96f399-27d5-4b10-8350-d6011d674f59)
2. Right-click on the windows icon present at the taskbar, navigate to Device Manager and click on it.     
![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/c4bb7255-ea72-44c4-af5c-812f16fcb0a2)
3. A windows will open, go to Ports (COM & LPT), double-click on it and a drop down option will be displayed. Search for "Silicon Labs CP210x USB to UART Bridge (COMxx), this means that your ESP32 board is connected on this serial port of your system.    ![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/5942af29-9c55-484c-8b28-538f4a9681ac)
4. Tally the COM Port in your code, it should be the same as found in the device manager.
5. Now, go to Sketch>>Run in your Processing IDE.        ![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/a02b604a-6aab-4bc1-92c0-5582eb41498a)

6. Now you will see the GUI of your code with the distances displayed on the window. ![image](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/assets/144008938/eb3d128c-8d43-49f0-8f4c-e3874fda97d3)
7. If there is a toxic library error, go to [libraryfolder](https://github.com/eSpark-Consultants/bradfairman-fishpipe-firmware/blob/Development/Firmware-Development/Teapot/libraries/processinglibraries.zip), download & extract it to any known path in your pc and then copy them to This PC>>Documents>>Processing>>libraries. Then restart your Teapot Processing IDE and your error will be resolved.
