/* * * * * * * * * * * * * * * * * * * * * * *
 * LIVE GRAPH PLOTTER CLASS
 * implements TabAPI for Processing Grapher
 *
 * @file     LiveGraph.pde
 * @brief    Real-time serial data plotter tab
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    LiveGraph
 * @see      TabAPI <ProcessingGrapher.pde>
 * * * * * * * * * * * * * * * * * * * * * * */

/*
 * Copyright (C) 2022 - Simon Bluett <hello@chillibasket.com>
 *
 * This file is part of ProcessingGrapher 
 * <https://github.com/chillibasket/processing-grapher>
 * 
 * ProcessingGrapher is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

class LiveGraph implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	Graph graphA, graphB, graphC, graphD;
	int menuScroll;
	int menuHeight;
	String name;
	ScrollBar sidebarScroll = new ScrollBar(ScrollBar.VERTICAL, ScrollBar.NORMAL);
	ReentrantLock lock = new ReentrantLock();

	String outputfile;

	String[] dataColumns = {};
	int[] graphAssignment = {};
	int graphMode;
	CustomTable dataTable;
	boolean recordData;
	boolean tabIsVisible;
	int recordCounter;
	int fileCounter;
	int maxFileRows = 100000;
	int drawFrom;
	int pausedCount;
	float xRate;
	int selectedGraph;
	int customXaxis;
	int autoAxis;            //! Graph axis scaling: 0 = Manual, 1 = Expand Only, 2 = Auto expand and contract
	boolean autoFrequency;   //! Detect data sampling rate: True = Automatic, False = Manual
	int frequencyCounter;    //! Counter used to detect sampling rate
	int frequencyTimer;      //! Timer used to detect sampling rate
	boolean isPaused;        //! Play/Pause data on live graphs: True = paused, False = playing
	int maxSamples;          //! Maximum number of samples to record and display on the graphs
	int[] sampleWindow = {1000,1000,1000,1000};
	float[] newMinimum = {0,0,0,0};
	float[] newMaximum = {0,0,0,0};
	float newXminimum = 0;
	float newXmaximum = 0;
	int signalListChange;


	/**
	 * Constructor
	 *
	 * @param  setname Name of the tab
	 * @param  left    Tab area left x-coordinate
	 * @param  right   Tab area right x-coordinate
	 * @param  top     Tab area top y-coordinate
	 * @param  bottom  Tab area bottom y-coordinate
	 */
	LiveGraph (String setname, int left, int right, int top, int bottom) {
		name = setname;
		tabIsVisible = false;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		graphA = new Graph(cL, cR, cT, cB, 0, 20, 0, 1, "Graph 1");
		graphB = new Graph(cL, cR, (cT + cB) / 2, cB, 0, 20, 0, 1, "Graph 2");
		graphC = new Graph((cL + cR) / 2, cR, cT, (cT + cB) / 2, 0, 20, 0, 1, "Graph 3");
		graphD = new Graph((cL + cR) / 2, cR, (cT + cB) / 2, cB, 0, 20, 0, 1, "Graph 4");
		graphA.setHighlight(true);
		graphA.setXaxisName("Time (s)");
		graphB.setXaxisName("Time (s)");
		graphC.setXaxisName("Time (s)");
		graphD.setXaxisName("Time (s)");

		graphMode = 1;
		selectedGraph = 1;

		outputfile = "No File Set";
		recordData = false;
		recordCounter = 0;
		fileCounter = 0;

		xRate = 100;
		customXaxis = -1;
		autoAxis = 1;
		autoFrequency = true;
		frequencyCounter = 0;
		frequencyTimer = 0;
		isPaused = false;
		
		drawFrom = 0;
		pausedCount = 0;
		maxSamples = 10;
		signalListChange = 0;

		dataTable = new CustomTable();
		
		menuScroll = 0;
		menuHeight = cB - cT - 1; 
	}


	/**
	 * Get the name of the current tab
	 *
	 * @return Tab name
	 */
	String getName () {
		return name;
	}


	/**
	 * Set tab as being active or hidden
	 * 
	 * @param  newState True = active, false = hidden
	 */
	void setVisibility(boolean newState) {
		tabIsVisible = newState;
	}


	/**
	 * Redraw all tab content
	 */
	void drawContent () {
		graphA.drawGrid();
		graphA.resetGraph();
		if (graphMode > 1) {
			graphB.drawGrid();
			graphB.resetGraph();
		}
		if (graphMode > 2) {
			graphC.drawGrid();
			graphC.resetGraph();
		}
		if (graphMode > 3) {
			graphD.drawGrid();
			graphD.resetGraph();
		}

		if (isPaused) {
			String messageText = "Live Graph is Paused";
			rectMode(CENTER);
			textAlign(CENTER, TOP);
			stroke(c_alert_message_box);
			fill(c_alert_message_box);
			rect((cR - cL) / 2, cT + (15 * uimult), textWidth(messageText) + (10 * uimult), 20 * uimult);
			fill(c_sidebar_heading);
			text(messageText, (cR - cL) / 2, cT + int(5 * uimult));
		}

		// Show message if no serial device is connected
		if (!serialConnected) {
			if (showInstructions) {
				String[] message = {"1. In the 'Serial' tab, use the right-hand menu to connect to a serial device",
								    "2. Each line sent by the device should contain only numbers separated with commas",
								    "3. The signals/numbers can be displayed in real-time on up to 4 separate graphs"};
				drawMessageArea("Getting Started", message, cL + 60 * uimult, cR - 60 * uimult, cT + 30 * uimult);
			}

		} else if (dataTable.getRowCount() > 0) {
			drawNewData();
		}
	}


	/**
	 * Draw new tab data
	 */
	void drawNewData () {
		lock.lock();
		int currentCount = dataTable.getRowCount();
		if (isPaused) {
			if (pausedCount < currentCount) currentCount = pausedCount;
		}

		// If there is content to draw
		if (currentCount > 0) {
			
			int samplesA = currentCount - sampleWindow[0] - 1;
			int samplesB = currentCount - sampleWindow[1] - 1;
			int samplesC = currentCount - sampleWindow[2] - 1;
			int samplesD = currentCount - sampleWindow[3] - 1;

			drawFrom = samplesA;
			graphA.clearGraph();
			if (graphMode >= 2) {
				graphB.clearGraph();
				if (samplesB < drawFrom) drawFrom = samplesB;
			}
			if (graphMode >= 3) {
				graphC.clearGraph();
				if (samplesC < drawFrom) drawFrom = samplesC;
			}
			if (graphMode >= 4) {
				graphD.clearGraph();
				if (samplesD < drawFrom) drawFrom = samplesD;
			}

			maxSamples = currentCount - drawFrom;
			if (drawFrom < 0) drawFrom = 0;
			newMinimum[0] = Float.NaN;
			newMinimum[1] = Float.NaN;
			newMinimum[2] = Float.NaN;
			newMinimum[3] = Float.NaN;
			newXminimum = Float.NaN;

			newMaximum[0] = Float.NaN;
			newMaximum[1] = Float.NaN;
			newMaximum[2] = Float.NaN;
			newMaximum[3] = Float.NaN;
			newXmaximum = Float.NaN;

			for (int j = drawFrom; j < currentCount; j++) {
				for (int i = 0; i < dataTable.getColumnCount(); i++) {
					if (i != customXaxis)
					{
						try {
							float xDataValue = 0;
							if (customXaxis >= 0) xDataValue = (float) dataTable.getDouble(j, customXaxis);
							float dataPoint = (float) dataTable.getDouble(j, i);

							if (dataPoint != dataPoint) dataPoint = 99999999;
							if (graphAssignment[i] == 2 && graphMode >= 2 && samplesB <= drawFrom) {
								checkGraphSize(dataPoint, xDataValue, 1);
								if (customXaxis >= 0) graphB.plotData(dataPoint, xDataValue, i);
								else graphB.plotData(dataPoint, i);
							} else if (graphAssignment[i] == 3 && graphMode >= 3 && samplesC <= drawFrom) {
								checkGraphSize(dataPoint, xDataValue, 2);
								if (customXaxis >= 0) graphC.plotData(dataPoint, xDataValue, i);
								else graphC.plotData(dataPoint, i);
							} else if (graphAssignment[i] == 4 && graphMode >= 4 && samplesD <= drawFrom) {
								checkGraphSize(dataPoint, xDataValue, 3);
								if (customXaxis >= 0) graphD.plotData(dataPoint, xDataValue, i);
								else graphD.plotData(dataPoint, i);
							} else if (graphAssignment[i] == 1 && samplesA <= drawFrom) {
								checkGraphSize(dataPoint, xDataValue, 0);
								if (customXaxis >= 0) graphA.plotData(dataPoint, xDataValue, i);
								else graphA.plotData(dataPoint, i);
							}
						} catch (Exception e) {
							println("LiveGraph::drawNewData() - drawFrom: " + drawFrom + ", currentCount: " + currentCount + ", Error: " + e);
						}
					}
				}
				drawFrom++;
			}

			updateGraphSize(graphA, 0);
			if (graphMode >= 2) updateGraphSize(graphB, 1);
			if (graphMode >= 3) updateGraphSize(graphC, 2);
			if (graphMode >= 4) updateGraphSize(graphD, 3);
		}
		lock.unlock();
	}
	

	/**
	 * Update minimum and maximum datapoint arrays
	 *
	 * @param  dataPoint    Y-coordinate of new data point
	 * @param  xAxisPoint   X-coordinate of the new data point
	 * @param  currentGrpah Array index of the graph
	 */
	void checkGraphSize (float dataPoint, float xAxisPoint, int currentGraph) {
		
		// If data exceeds graph size, resize the graph
		if (autoAxis != 0 && dataPoint != 99999999) {

			// Find minimum point
			if (dataPoint < newMinimum[currentGraph] || Float.isNaN(newMinimum[currentGraph])) {
				newMinimum[currentGraph] = dataPoint;
			}
			// Find maximum point
			else if (dataPoint > newMaximum[currentGraph] || Float.isNaN(newMaximum[currentGraph])) {
				newMaximum[currentGraph] = dataPoint;
			}

			if (customXaxis >= 0)
			{
				// Find minimum point
				if (xAxisPoint < newXminimum || Float.isNaN(newXminimum)) {
					newXminimum = xAxisPoint;
				}
				// Find maximum point
				else if (xAxisPoint > newXmaximum || Float.isNaN(newXmaximum)) {
					newXmaximum = xAxisPoint;
				}
			}
		}
	}


	/**
	 * Resize graph y-axis if data point is out of bounds
	 *
	 * @param  currentGraph Which if the 4 graphs to check
	 * @param  graphIndx    Array index of the graph
	 */
	void updateGraphSize(Graph currentGraph, int graphIndex) {

		boolean redrawGrid = false;

		if (autoAxis != 0 && !Float.isNaN(newMinimum[graphIndex]) && !Float.isNaN(newMaximum[graphIndex])) {
			newMinimum[graphIndex] = floorToSigFig(newMinimum[graphIndex], 1);
			newMaximum[graphIndex] = ceilToSigFig(newMaximum[graphIndex], 1);

			if (autoAxis == 1) {
				if (currentGraph.getMinY() > newMinimum[graphIndex]) {
					currentGraph.setMinY(newMinimum[graphIndex]);
					redrawGrid = true;
				}
				if (currentGraph.getMaxY() < newMaximum[graphIndex]) {
					currentGraph.setMaxY(newMaximum[graphIndex]);
					redrawGrid = true;
				}
			} else if (autoAxis == 2) {
				if (currentGraph.getMinY() != newMinimum[graphIndex]) {
					currentGraph.setMinY(newMinimum[graphIndex]);
					redrawGrid = true;
				}
				if (currentGraph.getMaxY() != newMaximum[graphIndex]) {
					currentGraph.setMaxY(newMaximum[graphIndex]);
					redrawGrid = true;
				}
			}
		}

		if (autoAxis != 0 && customXaxis >= 0 && !Float.isNaN(newXminimum) && !Float.isNaN(newXmaximum)) {
			newXminimum = floorToSigFig(newXminimum, 1);
			newXmaximum = ceilToSigFig(newXmaximum, 1);

			if (autoAxis == 1) {
				if (currentGraph.getMinX() > newXminimum) {
					currentGraph.setMinX(newXminimum);
					redrawGrid = true;
				}
				if (currentGraph.getMaxX() < newXmaximum) {
					currentGraph.setMaxX(newXmaximum);
					redrawGrid = true;
				}
			} else if (autoAxis == 2) {
				if (currentGraph.getMinX() != newXminimum) {
					currentGraph.setMinX(newXminimum);
					redrawGrid = true;
				}
				if (currentGraph.getMaxX() != newXmaximum) {
					currentGraph.setMaxX(newXmaximum);
					redrawGrid = true;
				}
			}
		}

		if (redrawGrid)
		{
			currentGraph.drawGrid();
			redrawContent = true;
			redrawUI = true;
		}
	}


	/**
	 * Change tab content area dimensions
	 *
	 * @param  newL New left x-coordinate
	 * @param  newR New right x-coordinate
	 * @param  newT New top y-coordinate
	 * @param  newB new bottom y-coordinate
	 */
	void changeSize (int newL, int newR, int newT, int newB) {
		cL = newL;
		cR = newR;
		cT = newT;
		cB = newB;

		if (graphMode == 2) {
			graphA.changeSize(cL, cR, cT, (cT + cB) / 2);
			graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
		} else if (graphMode == 3) {
			graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
			graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
			graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
		} else if (graphMode == 4) {
			graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
			graphB.changeSize(cL, (cL + cR) / 2, (cT + cB) / 2, cB);
			graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
			graphD.changeSize((cL + cR) / 2, cR, (cT + cB) / 2, cB);
		} else {
			graphA.changeSize(cL, cR, cT, cB);
		}
		//drawContent();
	}


	/**
	 * Change CSV data file location
	 *
	 * @param  newoutput Absolute path to the new file location
	 */
	void setOutput (String newoutput) {
		if (newoutput != "No File Set") {
			// Ensure file type is *.csv
			int dotPos = newoutput.lastIndexOf(".");
			if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
			newoutput = newoutput + ".csv";

			// Test whether this file is actually accessible
			if (saveFile(newoutput) == null) {
				alertMessage("Error\nUnable to access the selected output file location; perhaps this location is write-protected?\n" + newoutput);
				newoutput = "No File Set";
			}
		}
		outputfile = newoutput;
	}


	/**
	 * Get the current CSV data file location
	 *
	 * @return Absolute path to the data file
	 */
	String getOutput () {
		return outputfile;
	}


	/** 
	 * Start recording new serial data points to file
	 */
	void startRecording () {
		// Ensure table is empty
		dataTable = new CustomTable();
		drawFrom = 0;
		pausedCount = 0;
		isPaused = false;
		redrawContent = true;

		// Add columns to the table
		while (dataTable.getColumnCount() < dataColumns.length) {
			if (customXaxis >= 0 && customXaxis == dataTable.getColumnCount()) {
				dataTable.addColumn("x:" + dataColumns[dataTable.getColumnCount()]);
			} else {
				dataTable.addColumn(dataColumns[dataTable.getColumnCount()]);
			}
		}

		// Open up the CSV output stream
		if (!dataTable.openCSVoutput(outputfile)) {
			alertMessage("Error\nUnable to create the output file; perhaps the location no longer exists?\n" + outputfile);
		} else {
			recordCounter = 0;
			fileCounter = 0;
			recordData = true;
			redrawUI = true;
		}
	}


	/**
	 * Stop recording data points to file
	 */
	void stopRecording(){
		recordData = false;
		if (dataTable.closeCSVoutput()) {
			alertMessage("Success\nRecorded " + ((fileCounter * 10000) + recordCounter) + " samples to " + (fileCounter + 1) + " CSV file(s)");
		} else {
			emergencyOutputSave(false);
		}
		outputfile = "No File Set";
		if (tabIsVisible) redrawUI = true;
	}


	/**
	 * Recover from an rrror when recording data to file
	 *
	 * @param  continueRecording If we want to continue recording after dealing with the error
	 */
	void emergencyOutputSave(boolean continueRecording) {
		dataTable.closeCSVoutput();

		// Figure out name for new backup file
		String[] tempSplit = split(outputfile, '/');
		int dotPos = tempSplit[tempSplit.length - 1].lastIndexOf(".");
		String nextoutputfile = tempSplit[tempSplit.length - 1].substring(0, dotPos);
		outputfile = nextoutputfile + "-backup.csv";

		String emergencysavefile = nextoutputfile + "-backup-" + (fileCounter + 1) + ".csv";

		try {
			// Backup the existing data
			saveTable(dataTable, emergencysavefile);

			// If we want to continue recording, try setting up a new output file
			if (continueRecording) {
				fileCounter++;
				nextoutputfile = nextoutputfile + "-backup-" + (fileCounter + 1) + ".csv";

				// If new output file was successfully opened, only show a Warning message
				if (dataTable.openCSVoutput(nextoutputfile)) {
					alertMessage("Warning\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. Data is still being recorded (to a new file)\n3. The files are in the same directory as ProcessingGrapher.exe");
				
				// If not, show an error message that the recording has stopped
				} else {
					recordData = false;
					redrawUI = true;
					alertMessage("Error - Recording Stopped\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. The files are in the same directory as ProcessingGrapher.exe");
				}

			// If we don't want to continue, show a simple error message
			} else {
				recordData = false;
				alertMessage("Error\nAn issue occurred when trying to save new data to the ouput file.\n1. Data recording has been stopped\n2. A backup of all the data has been created\n3. The backup is in the same directory as ProcessingGrapher.exe");
			}

		// If something went wrong in the error recovery process, show a critical error message
		} catch (Exception e) {
			dataTable.closeCSVoutput();
			recordData = false;
			alertMessage("Critical Error\nAn issue occurred when trying to save new data to the ouput file.\nData backup was also unsuccessful, so some data may have been lost...\n" + e);
		}
	}


	/**
	 * Function called when a serial device has connected/disconnected
	 *
	 * @param  status True if a device has connected, false if disconnected
	 */
	void connectionEvent (boolean status) {

		// If port has disconnected
		if (!status) {
			// Stop recording any data
			if (recordData) stopRecording();

			// Reset the signal list
			dataTable.clearRows();
			
			while (dataColumns.length > 0) {
				dataColumns = shorten(dataColumns);
				graphAssignment = shorten(graphAssignment);
			}
			while (dataTable.getColumnCount() > 0) dataTable.removeColumn(0);
			drawFrom = 0;
			frequencyCounter = 0;
			frequencyTimer = 0;
			if (tabIsVisible) redrawContent = true;
		}
	}


	/**
	 * Parse new data points received from serial port
	 *
	 * @param  inputData String containing data points separated by commas
	 * @param  graphable True if data in message can be plotted on a graph
	 */
	void parsePortData (String inputData, boolean graphable) {

		// Check that the starts with a number
		if (graphable) {
			// Get data
			String[] dataArray = trim(split(inputData, ','));
			
			// Check the frequency
			if (autoFrequency && (frequencyCounter != -1)) {
				if (frequencyCounter == 0) frequencyTimer = millis();
				frequencyCounter++;
				if ((frequencyCounter > 20) && (millis() - frequencyTimer >= 10000)) {
					float newXrate = 1000.0 * (frequencyCounter) / float(millis() - frequencyTimer);
					if (abs(newXrate - xRate) > 2) {
						xRate = roundToSigFig(newXrate, 2);
						graphA.setXrate(xRate);
						graphB.setXrate(xRate);
						graphC.setXrate(xRate);
						graphD.setXrate(xRate);
						sampleWindow[0] = int(xRate * abs(graphA.getMaxX() - graphA.getMinX()));
						sampleWindow[1] = int(xRate * abs(graphB.getMaxX() - graphB.getMinX()));
						sampleWindow[2] = int(xRate * abs(graphC.getMaxX() - graphC.getMinX()));
						sampleWindow[3] = int(xRate * abs(graphD.getMaxX() - graphD.getMinX()));
						redrawContent = true;
						redrawUI = true;
					}
					frequencyCounter = 0;
				}
			}

			// If data column does not exist, add it to the list
			while(dataColumns.length < dataArray.length){
				dataColumns = append(dataColumns, "Signal-" + (dataColumns.length + 1));
				graphAssignment = append(graphAssignment, 1);
				dataTable.addColumn("Signal-" + (dataColumns.length + 1), CustomTable.STRING);
				redrawUI = true;
			}

			// Only remove extra columns if not recording and
			// the last 10 input data samples didn't contain the signal
			if (dataColumns.length > dataArray.length) {
				signalListChange++;
				if (signalListChange >= 10 && !recordData && !isPaused) {
					dataColumns = shorten(dataColumns);
					graphAssignment = shorten(graphAssignment);
					dataTable.removeColumn(dataColumns.length);
					signalListChange = 0;
					redrawUI = true;
				}
			}
	
			// --- Data Recording ---
			TableRow newRow = dataTable.addRow();
			//float[] newData = new float[dataArray.length];

			// Go through each data column, and try to parse and add to file
			for(int i = 0; i < dataArray.length; i++){
				try {
					double dataPoint = Double.parseDouble(dataArray[i]);
					newRow.setDouble(i, dataPoint);
					//newData[i] = dataPoint;
					//checkGraphSize(dataPoint, 0);
				} catch (Exception e) {
					print(e);
					println(" - When parsing live graph data");
				}
			}

			//graphA.bufferNewData(newData);

			// Record data to file
			if (recordData) {
				recordCounter++;
				if (!dataTable.saveCSVentries(dataTable.lastRowIndex(), dataTable.lastRowIndex())) {
					emergencyOutputSave(true);
				}

				// Separate data into files once the max number of rows has been reached
				if (recordCounter >= maxFileRows) {
					dataTable.closeCSVoutput();
					fileCounter++;
					recordCounter = 0;

					int dotPos = outputfile.lastIndexOf(".");
					String nextoutputfile = outputfile.substring(0, dotPos);
					nextoutputfile = nextoutputfile + "-" + (fileCounter + 1) + ".csv";
					if (!dataTable.openCSVoutput(nextoutputfile)) {
						emergencyOutputSave(true);
					}

					// Ensure table is empty
					dataTable = new CustomTable();
					drawFrom = 0;
				}
			} else if (!isPaused && !lock.isLocked()) {
				// Remove rows from table which don't need to be shown on the graphs anymore
				while (dataTable.getRowCount() > maxSamples) {
					lock.lock();
					dataTable.removeRow(0);
					drawFrom--;
					if (drawFrom < 0) drawFrom = 0;
					lock.unlock();
				}
			}
	
			if (tabIsVisible) drawNewData = true;
		}
	}


	/**
	 * Draw the sidebar menu for the current tab
	 */
	void drawSidebar () {
		
		// Calculate sizing of sidebar
		// Do this here so commands below are simplified
		int sT = cT;
		int sL = cR;
		int sW = width - cR;
		int sH = height - sT;

		int uH = round(sideItemHeight * uimult);
		int tH = round((sideItemHeight - 8) * uimult);
		int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		int iW = round(sW - (20 * uimult));
		menuHeight = round((13.5 + dataColumns.length + ((graphMode + 1) * 0.75)) * uH);

		// Figure out if scrolling of the menu is necessary
		if (menuHeight > sH) {
			if (menuScroll == -1) menuScroll = 0;
			else if (menuScroll > menuHeight - sH) menuScroll = menuHeight - sH;

			// Draw left bar
			fill(c_serial_message_box);
			rect(width - round(15 * uimult) / 2, sT, round(15 * uimult) / 2, sH);

			// Figure out size and position of scroll bar indicator
			int scrollbarSize = sH - round(sH * float(menuHeight - sH) / menuHeight);
			if (scrollbarSize < uH) scrollbarSize = uH;
			int scrollbarOffset = round((sH - scrollbarSize) * (menuScroll / float(menuHeight - sH)));
			fill(c_terminal_text);
			rect(width - round(15 * uimult) / 2, sT + scrollbarOffset, round(15 * uimult) / 2, scrollbarSize);
			sidebarScroll.update(menuHeight, sH, width - round(15 * uimult) / 2, sT + scrollbarOffset, round(15 * uimult) / 2, scrollbarSize);

			sT -= menuScroll;
			sL -= round(15 * uimult) / 4;
			iL -= round(15 * uimult) / 4;
		} else {
			menuScroll = -1;
		}

		// Save to File
		drawHeading("Record Graph Data", iL, sT + (uH * 0), iW, tH);
		if (outputfile == "No File Set" || outputfile == "") {
			drawButton("Set Output File", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
			drawDatabox("Start Recording", c_idletab_text, iL, sT + (uH * 2), iW, iH, tH);
		} else {
			String[] fileParts = split(outputfile, '/');
			String fileName = fileParts[fileParts.length - 1];

			if (recordData) {
				drawDatabox(fileName, c_idletab_text, iL, sT + (uH * 1), iW, iH, tH);
				drawButton("Stop Recording", c_sidebar_accent, iL, sT + (uH * 2), iW, iH, tH);
			} else {
				drawDatabox(fileName, c_sidebar_text, iL, sT + (uH * 1), iW, iH, tH);
				drawButton("Start Recording", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);
			}
		}

		// Graph options
		Graph currentGraph;
		if (selectedGraph == 2) currentGraph = graphB;
		else if (selectedGraph == 3) currentGraph = graphC;
		else if (selectedGraph == 4) currentGraph = graphD;
		else currentGraph = graphA;

		drawHeading("Graph " + selectedGraph + " - Options",                                     iL,                sT + (uH * 3.5),         iW, tH);
		drawButton("Line", (currentGraph.getGraphType() == "linechart")? c_sidebar_accent:c_sidebar_button, iL,                sT + (uH * 4.5), iW / 3, iH, tH);
		drawButton("Dots", (currentGraph.getGraphType() == "dotchart")? c_sidebar_accent:c_sidebar_button,  iL + (iW / 3),     sT + (uH * 4.5), iW / 3, iH, tH);
		drawButton("Bar", (currentGraph.getGraphType() == "barchart")? c_sidebar_accent:c_sidebar_button,   iL + (iW * 2 / 3), sT + (uH * 4.5), iW / 3, iH, tH);
		drawRectangle(c_sidebar_divider, iL + (iW / 3),     sT + (uH * 4.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_sidebar_divider, iL + (iW * 2 / 3), sT + (uH * 4.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		drawDatabox(str(currentGraph.getMinX()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), (customXaxis >= 0 && autoAxis != 2)? c_sidebar_text:c_idletab_text, iL, sT + (uH * 5.5), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("x", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 5.5), 12 * uimult,             iH, tH);
		drawDatabox(str(currentGraph.getMaxX()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), (autoAxis != 2)? c_sidebar_text:c_idletab_text, iL + (iW / 2) + (6 * uimult), sT + (uH * 5.5), (iW / 2) - (6 * uimult), iH, tH);
		drawDatabox(str(currentGraph.getMinY()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), (autoAxis != 2)? c_sidebar_text:c_idletab_text, iL,                           sT + (uH * 6.5), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("y", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 6.5), 12 * uimult,             iH, tH);
		drawDatabox(str(currentGraph.getMaxY()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), (autoAxis != 2)? c_sidebar_text:c_idletab_text, iL + (iW / 2) + (6 * uimult), sT + (uH * 6.5), (iW / 2) - (6 * uimult), iH, tH);
		if (autoAxis == 2) drawButton("Scale: Automatic", c_sidebar_button, iL, sT + (uH * 7.5), iW, iH, tH);
		else if (autoAxis == 1) drawButton("Scale: Expand Only", c_sidebar_button, iL, sT + (uH * 7.5), iW, iH, tH);
		else drawButton("Scale: Manual", c_sidebar_button, iL, sT + (uH * 7.5), iW, iH, tH);

		// Input Data Columns
		drawHeading("Data Format", iL, sT + (uH * 9), iW, tH);
		//drawButton((isPaused)? "Resume Data":"Pause Data", (isPaused)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 11), iW, iH, tH);
		drawButton("", (!isPaused)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 10), iW / 4, iH, tH);
		drawTriangle(c_sidebar_text, iL + (12 * uimult), sT + (uH * 10) + (8 * uimult), iL + (12 * uimult), sT + (uH * 10) + iH - (8 * uimult), iL + (iW / 4) - (12 * uimult), sT + (uH * 10) + (tH / 2) + 1);
		drawButton("", (isPaused)? c_sidebar_accent:c_sidebar_button, iL + (iW / 4), sT + (uH * 10), iW / 4 + 1, iH, tH);
		drawButton("Clear", c_sidebar_button, iL + (iW / 2), sT + (uH * 10), iW / 2, iH, tH);
		drawRectangle(c_sidebar_text, iL + (iW / 4) + (12 * uimult), sT + (uH * 10) + (8 * uimult), 3 * uimult, iH - (16 * uimult));
		drawRectangle(c_sidebar_text, iL + (iW / 2) - (12 * uimult), sT + (uH * 10) + (8 * uimult), -3 * uimult, iH - (16 * uimult));
		drawRectangle(c_sidebar_divider, iL + (iW / 4), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		//drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
		drawDatabox("Split", c_idletab_text, iL, sT + (uH * 11), iW - (80 * uimult), iH, tH);
		drawButton("1", (graphMode == 1)? c_sidebar_accent:c_sidebar_button, iL + iW - (80 * uimult), sT + (uH * 11), 20 * uimult, iH, tH);
		drawButton("2", (graphMode == 2)? c_sidebar_accent:c_sidebar_button, iL + iW - (60 * uimult), sT + (uH * 11), 20 * uimult, iH, tH);
		drawButton("3", (graphMode == 3)? c_sidebar_accent:c_sidebar_button, iL + iW - (40 * uimult), sT + (uH * 11), 20 * uimult, iH, tH);
		drawButton("4", (graphMode == 4)? c_sidebar_accent:c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * 11), 20 * uimult, iH, tH);
		drawRectangle(c_sidebar_divider, iL + iW - (60 * uimult), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_sidebar_divider, iL + iW - (40 * uimult), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_sidebar_divider, iL + iW - (20 * uimult), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		if (customXaxis >= 0) drawDatabox("X: " + dataColumns[customXaxis], iL, sT + (uH * 12), iW, iH, tH);
		else drawDatabox(((autoFrequency)? "Auto: ":"Rate: ") + xRate + "Hz", iL, sT + (uH * 12), iW, iH, tH);

		float tHnow = 13;

		for (int j = 0; j < graphMode + 1; j++) {
			if (j < graphMode) drawText("Graph " + (j + 1), c_idletab_text, iL, sT + (uH * tHnow), iW, iH * 3 / 4);
			else drawText("Hidden", c_idletab_text, iL, sT + (uH * tHnow), iW, iH * 3 / 4);
			tHnow += 0.75;
			int itemCount = 0;

			// List of Data Columns
			for(int i = 0; i < dataColumns.length; i++) {

				if (graphAssignment[i] == j + 1) {
					// Column name
					drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

					// Up button
					color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
					drawButton("▲", c_sidebar, buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

					// Down button
					drawButton((graphAssignment[i] < graphMode + 1)? "▼":"", c_sidebar, buttonColor, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

					drawRectangle(c_sidebar_divider, iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
					tHnow++;
					itemCount++;
				}
			}

			if (itemCount == 0) drawText("Empty", c_idletab_text, iL + iW / 2, sT + (uH * (tHnow - itemCount - 0.75)), iW / 2, iH * 3 / 4);
		}

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_status_bar);
		text("Output: " + constrainString(outputfile, width - sW - round(30 * uimult) - textWidth("Output: ")), round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult));
	}


	/**
	 * Keyboard input handler function
	 *
	 * @param  key The character of the key that was pressed
	 */
	void keyboardInput (char keyChar, int keyCodeInt, boolean codedKey) {
		if (!codedKey && key == 's' && serialConnected) {
			thread("serialSendDialog");

		} else if (codedKey) {
			switch (keyCodeInt) {
				case UP:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll -= (12 * uimult);
						if (menuScroll < 0) menuScroll = 0;
					}
					redrawUI = true;
					break;

				case DOWN:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll += (12 * uimult);
						if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
					}
					redrawUI = true;
					break;

				case KeyEvent.VK_PAGE_UP:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll -= height - cT;
						if (menuScroll < 0) menuScroll = 0;
						redrawUI = true;
					}
					break;

				case KeyEvent.VK_PAGE_DOWN:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll += height - cT;
						if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
						redrawUI = true;
					}
					break;

				case KeyEvent.VK_END:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll = menuHeight - (height - cT);
						redrawUI = true;
					}
					break;

				case KeyEvent.VK_HOME:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll = 0;
						redrawUI = true;
					}
					break;
			}
		}
	}


	/**
	 * Content area mouse click handler function
	 *
	 * @param  xcoord X-coordinate of the mouse click
	 * @param  ycoord Y-coordinate of the mouse click
	 */
	void contentClick (int xcoord, int ycoord) {
		if ((graphMode == 1 || ycoord <= (cT + cB) / 2) && (graphMode < 3 || xcoord <= (cL + cR) / 2)) {
			selectedGraph = 1;
			graphA.setHighlight(true);
			graphB.setHighlight(false);
			graphC.setHighlight(false);
			graphD.setHighlight(false);
			redrawUI = true;
			redrawContent = true;
		} else if ((ycoord > (cT + cB) / 2 && graphMode > 1) && (xcoord <= (cL + cR) / 2 || graphMode < 4)) {
			selectedGraph = 2;
			graphA.setHighlight(false);
			graphB.setHighlight(true);
			graphC.setHighlight(false);
			graphD.setHighlight(false);
			redrawUI = true;
			redrawContent = true;
		} else if ((ycoord <= (cT + cB) / 2 && graphMode > 2) && (xcoord > (cL + cR) / 2)) {
			selectedGraph = 3;
			graphA.setHighlight(false);
			graphB.setHighlight(false);
			graphC.setHighlight(true);
			graphD.setHighlight(false);
			redrawUI = true;
			redrawContent = true;
		} else if ((ycoord > (cT + cB) / 2 && graphMode > 3) && (xcoord > (cL + cR) / 2)) {
			selectedGraph = 4;
			graphA.setHighlight(false);
			graphB.setHighlight(false);
			graphC.setHighlight(false);
			graphD.setHighlight(true);
			redrawUI = true;
			redrawContent = true;
		}
	}


	/**
	 * Scroll wheel handler function
	 *
	 * @param  amount Multiplier/velocity of the latest mousewheel movement
	 */
	void scrollWheel (float amount) {
		// Scroll menu bar
		if (mouseX >= cR && menuScroll != -1) {
			menuScroll += (sideItemHeight * amount * uimult);
			if (menuScroll < 0) menuScroll = 0;
			else if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
		}

		redrawUI = true;
	}


	/**
	 * Scroll bar handler function
	 *
	 * @param  xcoord Current mouse x-coordinate position
	 * @param  ycoord Current mouse y-coordinate position
	 */
	void scrollBarUpdate (int xcoord, int ycoord) {
		if (sidebarScroll.active()) {
			int previousScroll = menuScroll;
			menuScroll = sidebarScroll.move(xcoord, ycoord, menuScroll, 0, menuHeight - (height - cT));
			if (previousScroll != menuScroll) redrawUI = true;
		}
	}


	/**
	 * Sidebar mouse click handler function
	 *
	 * @param  xcoord X-coordinate of the mouse click
	 * @param  ycoord Y-coordinate of the mouse click
	 */
	void menuClick (int xcoord, int ycoord) {

		// Coordinate calculation
		int sT = cT;
		int sL = cR;
		if (menuScroll > 0) sT -= menuScroll;
		if (menuScroll != -1) sL -= round(15 * uimult) / 4;
		final int sW = width - cR;
		final int sH = height - sT;

		final int uH = round(sideItemHeight * uimult);
		final int tH = round((sideItemHeight - 8) * uimult);
		final int iH = round((sideItemHeight - 5) * uimult);
		final int iL = round(sL + (10 * uimult));
		final int iW = int(sW - (20 * uimult));

		// Click on sidebar menu scroll bar
		if ((menuScroll != -1) && sidebarScroll.click(xcoord, ycoord)) {
			startScrolling(false);
		}

		// Select output file name and directory
		if (menuXYclick(xcoord, ycoord, sT, uH, iH, 1, iL, iW)){
			if (!recordData) {
				outputfile = "";
				selectOutput("Select a location and name for the output *.CSV file", "fileSelected");
			}
		}
		
		// Start recording data and saving it to a file
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 2, iL, iW)){
			if(recordData){
				stopRecording();
			} else if(outputfile != "" && outputfile != "No File Set"){
				startRecording();
			}
			//else {
			//	alertMessage("Error\nPlease set an output file path.");
			//}
		}

		// Change graph type
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 4.5, iL, iW)){
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Line
			if (menuXclick(xcoord, iL, iW / 3)) {
				currentGraph.setGraphType("linechart");
				redrawContent = redrawUI = true;
			}

			// Dot
			else if (menuXclick(xcoord, iL + (iW / 3), iW / 3)) {
				currentGraph.setGraphType("dotchart");
				redrawContent = redrawUI = true;
			}

			// Bar
			else if (menuXclick(xcoord, iL + (iW * 2 / 3), iW / 3)) {
				currentGraph.setGraphType("barchart");
				redrawContent = redrawUI = true;
			}
		}

		// Update X axis scaling
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 5.5, iL, iW) && (autoAxis != 2)) {
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Change X axis minimum value
			if ((customXaxis >= 0) && (mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
				ValidateInput userInput = new ValidateInput("Set the X-axis Minimum Value", "Minimum:", str(currentGraph.getMinX()));
				userInput.setErrorMessage("Error\nInvalid x-axis minimum value entered.\nPlease input a number less than the maximum x-axis value.");
				if (userInput.checkFloat(userInput.LT, currentGraph.getMaxX())) {
					graphA.setMinX(userInput.getFloat());
					graphB.setMinX(userInput.getFloat());
					graphC.setMinX(userInput.getFloat());
					graphD.setMinX(userInput.getFloat());
				} 
				redrawContent = redrawUI = true;
			}

			// Change X axis maximum value
			else if (menuXclick(xcoord, iL + (iW / 2) + int(6 * uimult), (iW / 2) - int(6 * uimult))) {
				ValidateInput userInput = new ValidateInput("Set the X-axis Maximum Value", "Maximum:", str(currentGraph.getMaxX()));
				userInput.setErrorMessage("Error\nInvalid x-axis maximum value entered.\nPlease input a number greater than 0.");
				if (userInput.checkFloat(userInput.GT, 0)) {
					if (customXaxis >= 0) {
						graphA.setMaxX(userInput.getFloat());
						graphB.setMaxX(userInput.getFloat());
						graphC.setMaxX(userInput.getFloat());
						graphD.setMaxX(userInput.getFloat());
					} else {
						currentGraph.setMaxX(userInput.getFloat());
						sampleWindow[selectedGraph - 1] = int(xRate * abs(currentGraph.getMaxX() - currentGraph.getMinX()));
					}
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Update Y axis scaling
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 6.5, iL, iW) && (autoAxis != 2)) {
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Change Y axis minimum value
			if (menuXclick(xcoord, iL, (iW / 2) - int(6 * uimult))) {
				ValidateInput userInput = new ValidateInput("Set the Y-axis Minimum Value", "Minimum:", str(currentGraph.getMinY()));
				userInput.setErrorMessage("Error\nInvalid y-axis minimum value entered.\nThe number should be smaller the the maximum value.");
				if (userInput.checkFloat(userInput.LT, currentGraph.getMaxY())) {
					currentGraph.setMinY(userInput.getFloat());
				} 
				redrawContent = redrawUI = true;
			}

			// Change Y axis maximum value
			else if (menuXclick(xcoord, iL + (iW / 2) + int(6 * uimult), (iW / 2) - int(6 * uimult))) {
				ValidateInput userInput = new ValidateInput("Set the Y-axis Maximum Value", "Maximum:", str(currentGraph.getMaxY()));
				userInput.setErrorMessage("Error\nInvalid y-axis maximum value entered.\nThe number should be larger the the minimum value.");
				if (userInput.checkFloat(userInput.GT, currentGraph.getMinY())) {
					currentGraph.setMaxY(userInput.getFloat());
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Turn auto-scaling on/off
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 7.5, iL, iW)) {
			autoAxis++;
			if (autoAxis > 2) autoAxis = 0;
			redrawUI = true;
			redrawContent = true;
		}

		// Play/pause and reset
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 10, iL, iW)) {

			// Play
			if (menuXclick(xcoord, iL, iW / 4)) {
				if (isPaused) {
					pausedCount = dataTable.getRowCount();
					isPaused = false;
					redrawUI = true;
					redrawContent = true;
				}

			// Pause
			} else if (menuXclick(xcoord, iL + (iW / 4) + 1, iW / 4)) {
				if (!isPaused) {
					pausedCount = dataTable.getRowCount();
					isPaused = true;
					redrawUI = true;
					redrawContent = true;
				}
			
			// Clear graphs
			} else if (menuXclick(xcoord, iL + (iW / 2) + 1, iW / 2)) {
				// Reset the signal list
				dataTable.clearRows();
				drawFrom = 0;
				redrawUI = true;
				redrawContent = true;
			}
		}

		// Add a new input data column
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 11, iL, iW)){
			
			// Graph mode 1
			if (menuXclick(xcoord, iL + iW - int(80 * uimult), int(20 * uimult))) {
				graphMode = 1;
				graphA.changeSize(cL, cR, cT, cB);
				redrawUI = true;
				redrawContent = true;
				if (selectedGraph > 1) {
					selectedGraph = 1;
					graphA.setHighlight(true);
					graphB.setHighlight(false);
					graphC.setHighlight(false);
					graphD.setHighlight(false);
				}
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode + 1) graphAssignment[i] = graphMode + 1;
				}
			
			// Graph mode 2
			} else if (menuXclick(xcoord, iL + iW - int(60 * uimult), int(20 * uimult))) {
				graphMode = 2;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, cR, cT, (cT + cB) / 2);
				graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
				if (selectedGraph > 2) {
					selectedGraph = 2;
					graphA.setHighlight(false);
					graphB.setHighlight(true);
					graphC.setHighlight(false);
					graphD.setHighlight(false);
				}
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode + 1) graphAssignment[i] = graphMode + 1;
				}

			// Graph mode 3
			} else if (menuXclick(xcoord, iL + iW - int(40 * uimult), int(20 * uimult))) {
				graphMode = 3;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
				graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
				graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
				if (selectedGraph > 3) {
					selectedGraph = 3;
					graphA.setHighlight(false);
					graphB.setHighlight(false);
					graphC.setHighlight(true);
					graphD.setHighlight(false);
				}
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode + 1) graphAssignment[i] = graphMode + 1;
				}

			// Graph mode 4
			} else if (menuXclick(xcoord, iL + iW - int(20 * uimult), int(20 * uimult))) {
				graphMode = 4;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
				graphB.changeSize(cL, (cL + cR) / 2, (cT + cB) / 2, cB);
				graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
				graphD.changeSize((cL + cR) / 2, cR, (cT + cB) / 2, cB);
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode + 1) graphAssignment[i] = graphMode + 1;
				}
			}

			//final String colname = showInputDialog("Column Name:");
			//if (colname != null){
			//    dataColumns = append(dataColumns, colname);
			//    dataTable.addColumn("Untitled-" + dataColumns.length);
			//    graphAssignment = append(graphAssignment, 1);
			//    redrawUI = true;
			//}
		}

		// Change the input data rate
		else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 12, iL, iW)){
			ValidateInput userInput = new ValidateInput("Received Data Update Rate","Frequency (Hz):\n(Leave blank for automatic)", str(graphA.getXrate()));
			userInput.setErrorMessage("Error\nInvalid frequency entered.\nThe rate can only be a number between 0 - 10,000 Hz");
			if (userInput.isEmpty()) {
				autoFrequency = true;
				frequencyCounter = 0;
				frequencyTimer = 0;
				redrawUI = true;

			} else if (userInput.checkFloat(userInput.GT, 0, userInput.LTE, 10000)) {
				autoFrequency = false;
				xRate = userInput.getFloat();
				graphA.setXrate(xRate);
				graphB.setXrate(xRate);
				graphC.setXrate(xRate);
				graphD.setXrate(xRate);
				sampleWindow[0] = int(xRate * abs(graphA.getMaxX() - graphA.getMinX()));
				sampleWindow[1] = int(xRate * abs(graphB.getMaxX() - graphB.getMinX()));
				sampleWindow[2] = int(xRate * abs(graphC.getMaxX() - graphC.getMinX()));
				sampleWindow[3] = int(xRate * abs(graphD.getMaxX() - graphD.getMinX()));

				redrawContent = true;
				redrawUI = true;
			}

			if (customXaxis != -1) {
				graphAssignment[customXaxis] = 1;
				customXaxis = -1;
				autoAxis = 2;
				graphA.setMinX(0);
				graphB.setMinX(0);
				graphC.setMinX(0);
				graphD.setMinX(0);
				graphA.setMaxX(30);
				graphB.setMaxX(30);
				graphC.setMaxX(30);
				graphD.setMaxX(30);
				sampleWindow[0] = int(xRate * abs(graphA.getMaxX() - graphA.getMinX()));
				sampleWindow[1] = int(xRate * abs(graphB.getMaxX() - graphB.getMinX()));
				sampleWindow[2] = int(xRate * abs(graphC.getMaxX() - graphC.getMinX()));
				sampleWindow[3] = int(xRate * abs(graphD.getMaxX() - graphD.getMinX()));
				graphA.setXaxisName("Time (s)");
				graphB.setXaxisName("Time (s)");
				graphC.setXaxisName("Time (s)");
				graphD.setXaxisName("Time (s)");
				redrawContent = true;
				redrawUI = true;
			}
		}
		
		else {
			float tHnow = 13;

			for (int j = 0; j < graphMode + 1; j++) {
				tHnow += 0.75;

				// List of Data Columns
				for(int i = 0; i < dataColumns.length; i++){

					if (graphAssignment[i] == j + 1) {

						if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)){

							// Down arrow
							if (menuXclick(xcoord, iL + iW - int(20 * uimult), int(20 * uimult))) {
								graphAssignment[i]++;
								if (graphAssignment[i] > graphMode + 1) graphAssignment[i] = graphMode + 1;
								redrawUI = true;
								redrawContent = true;
							}

							// Up arrow
							else if (menuXclick(xcoord, iL + iW - int(40 * uimult), int(20 * uimult))) {
								graphAssignment[i]--;
								if (graphAssignment[i] < 1) {
									if (customXaxis >= 0) graphAssignment[customXaxis] = 1;
									autoAxis = 2;
									customXaxis = i;
									sampleWindow[0] = 1000;
									sampleWindow[1] = 1000;
									sampleWindow[2] = 1000;
									sampleWindow[3] = 1000;
									graphA.setXaxisName(dataColumns[i]);
									graphB.setXaxisName(dataColumns[i]);
									graphC.setXaxisName(dataColumns[i]);
									graphD.setXaxisName(dataColumns[i]);
									graphAssignment[i] = -1;
								}
								redrawUI = true;
								redrawContent = true;
							}

							// Change name of column
							else {
								final String colname = myShowInputDialog("Set the Data Signal Name", "Name:", dataColumns[i]);
								if (colname != null && colname.length() > 0) {
									dataColumns[i] = colname;
									redrawUI = true;
								}
							}
						}
					
						tHnow++;
					}
				}
			}
		}
	}


	/**
	 * Check whether it is safe to exit the program
	 *
	 * @return True if the are no tasks active, false otherwise
	 */
	boolean checkSafeExit() {
		if (recordData) return false;
		return true;
	}


	/**
	 * End any active processes and safely exit the tab
	 */
	void performExit() {
		if (recordData) stopRecording();
	}
}
