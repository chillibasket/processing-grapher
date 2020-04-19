# processing-grapher
A Processing-based terminal and graphing program for the analysis and recording of data from serial devices, such as Arduinos. 

This is still a work in progress, with several features still to be added and bugs to be fixed!

## Features
1. Easy UI scaling and colour adjustments 
1. Serial terminal monitor
	1. Connect to any serial port at any baud rate
	1. Send and receive serial communication
	1. Record the communication as a comma delimited file
	1. Change the colour of lines containing specific tags
1. Live Graphing
	1. Plot real-time data obtained from serial device on a graph
	1. Can display data on up to 4 separate graphs
	1. Supports comma delimited numbers only (example: 12,24,-15.4)
	1. Apply different colours and names to each input
	1. Record the real-time data as a comma delimited file
1. File Graphing
	1. Opens comma delimited files for analysis
	1. Apply different colours and names to each input
	1. Supports zooming into sections of the waveforms


## Usage
1. Open "ProcessingGrapher.pde" in the Processing editor.
1. To change the size/scaling of all text and buttons, you can change the "uimult" multiplier on line 23.
1. To connect to an Arduino:
	1. Ensure Arduino is plugged into your computer
	1. Go to the "Serial" or "Live Graph" tab of the program
	1. In the right-hand sidebar, press on "Port: None" button
	1. A pop-up, listing all available ports should appear. Type in the number corresponding to the port you want to connect to
	1. Press on the "Baud: 115200" button and insert the baud rate of the serial connection
	1. Finally, click on the "Connect" button to initiate the connection with the Arduino.

## Changelog
1. (19th April 2020) Version 1.1
	1. Added ability to display live serial data on up to four separate graphs.
	1. Graphs now support the display of linecharts, dotcharts and barcharts.
	1. Updated zooming options on the "Live Graph" and "File Graph" tabs.
	1. Fixed some of the bugs in displaying the live graph data.
	1. Changed method used to plot live serial data, so that the maximum frequency which can be displayed is no longer limited by th frame rate (60Hz).

![](/Images/SerialMonitor_tab.jpg) *Serial monitor tab, showing the communication with an Arduino*

![](/Images/LiveGraph_tab.jpg) *Live graph tab, illustrating how real-time data can be plotted on multiple graphs*

![](/Images/FileGraph_tab.jpg) *File graph tab, showing how information from a CSV file can be plotted on a graph*