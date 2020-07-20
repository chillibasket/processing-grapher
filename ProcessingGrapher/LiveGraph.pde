/* * * * * * * * * * * * * * * * * * * * * * *
 * LIVE GRAPH PLOTTER CLASS
 * implements TabAPI for Processing Grapher
 *
 * Code by: Simon Bluett
 * Email:   hello@chillibasket.com
 * Copyright (C) 2020, GPL v3
 * * * * * * * * * * * * * * * * * * * * * * */

class LiveGraph implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	Graph graphA, graphB, graphC, graphD;
	int menuScroll;
	int menuHeight;

	String name;
	String outputfile;
	String[] dataColumns = {};
	int[] graphAssignment = {};
	int graphMode;
	Table dataTable;
	boolean recordData;
	int recordCounter;
	int autoSave;
	int drawFrom;
	int xRate;
	int selectedGraph;
	boolean autoAxis;
	//float[] dataPoints = {0};


	/**
	 * Constructor
	 *
	 * @param  setname Name of the tab
	 * @param  left    Tab area left x-coordinate
	 * @param  right   Tab area right x-coordinate
	 * @param  top     Tab area top y-coordinate
	 * @param  bottom  Tab area bottom y-coordinate
	 */
	LiveGraph(String setname, int left, int right, int top, int bottom) {
		name = setname;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		graphA = new Graph(cL, cR, cT, cB, 0, 10, 0, 1, "Graph 1");
		graphB = new Graph(cL, cR, (cT + cB) / 2, cB, 0, 10, 0, 1, "Graph 2");
		graphC = new Graph((cL + cR) / 2, cR, cT, (cT + cB) / 2, 0, 10, 0, 1, "Graph 3");
		graphD = new Graph((cL + cR) / 2, cR, (cT + cB) / 2, cB, 0, 10, 0, 1, "Graph 4");
		graphA.setHighlight(true, true);
		graphMode = 1;
		selectedGraph = 1;
		outputfile = "No File Set";
		recordData = false;
		recordCounter = 0;
		autoSave = 10;
		xRate = 100;
		autoAxis = true;
		drawFrom = 0;

		dataTable = new Table();
		menuScroll = 0;
		menuHeight = cB - cT - 1; 
	}


	/**
	 * Get the name of the current tab
	 *
	 * @return Tab name
	 */
	String getName() {
		return name;
	}


	/**
	 * Redraw all tab content
	 */
	void drawContent() {
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
	}


	/**
	 * Draw new tab data
	 */
	void drawNewData() {
		// If there is content to draw
		if (dataTable.getRowCount() > 0) {
			for (int j = drawFrom; j < dataTable.getRowCount() - 1; j++) {
				for (int i = 0; i < dataTable.getColumnCount(); i++) {
					try {
						float dataPoint = dataTable.getFloat(j, i);
						if(Float.isNaN(dataPoint)) dataPoint = 99999999;
						if (graphAssignment[i] == 2 && graphMode >= 2) {
							checkGraphSize(dataPoint, 2);
							graphB.plotData(dataPoint, -99999999, i);
						} else if (graphAssignment[i] == 3 && graphMode >= 3) {
							checkGraphSize(dataPoint, 3);
							graphC.plotData(dataPoint, -99999999, i);
						} else if (graphAssignment[i] == 4 && graphMode >= 4) {
							checkGraphSize(dataPoint, 4);
							graphD.plotData(dataPoint, -99999999, i);
						} else {
							checkGraphSize(dataPoint, 1);
							graphA.plotData(dataPoint, -99999999, i);
						}
					} catch (Exception e) {
						println("Error trying to plot file data.");
						println(e);
						println(drawFrom);
						println(dataTable.getRowCount());
					}
				}
				drawFrom++;
			}
		}
	}
	

	/**
	 * Resize graph y-axis if data point is out of bounds
	 *
	 * @param  dataPoint   Y-coordinate of new data point
	 * @param  graphSelect Which if the 4 graphs to check
	 */
	void checkGraphSize(float dataPoint, int graphSelect) {
		
		// If data exceeds graph size, resize the graph
		if (autoAxis && dataPoint !=  99999999) {

			Graph currentGraph;
			if (graphSelect == 2) currentGraph = graphB;
			else if (graphSelect == 3) currentGraph = graphC;
			else if (graphSelect == 4) currentGraph = graphD;
			else currentGraph = graphA;

			if (dataPoint < currentGraph.getMinMax(2)) {
				currentGraph.setMinMax(floorToSigFig(dataPoint, 2), 2);
				currentGraph.drawGrid();
				redrawUI = true;
			}
			else if (dataPoint > currentGraph.getMinMax(3)) {
				currentGraph.setMinMax(ceilToSigFig(dataPoint, 2), 3);
				currentGraph.drawGrid();
				redrawUI = true;
			}
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
	void changeSize(int newL, int newR, int newT, int newB) {
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
	void setOutput(String newoutput) {
		if (newoutput != "No File Set") {
			// Ensure file type is *.csv
			int dotPos = newoutput.lastIndexOf(".");
			if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
			newoutput = newoutput + ".csv";
		}
		outputfile = newoutput;
	}


	/**
	 * Get the current CSV data file location
	 *
	 * @return Absolute path to the data file
	 */
	String getOutput(){
		return outputfile;
	}


	/** 
	 * Start recording new serial data points to file
	 */
	void startRecording() {
		// Ensure table is empty
		dataTable = new Table();
		drawFrom = 0;

		// Add columns to the table
		while(dataTable.getColumnCount() < dataColumns.length) dataTable.addColumn(dataColumns[dataTable.getColumnCount()]);

		recordCounter = 0;
		recordData = true;
		redrawUI = true;
	}


	/**
	 * Stop recording data points to file
	 */
	void stopRecording(){
		recordData = false;
		try {
			saveTable(dataTable, outputfile, "csv");
		} catch (Exception e) {
			print(e);
			saveTable(dataTable, "autoSave.csv", "csv");
			alertHeading = "Error saving CSV file; see autoSave.csv for backup";
			redrawAlert = true;
		}
		redrawUI = true;
	}


	/**
	 * Parse new data points received from serial port
	 *
	 * @param  inputData String containing data points separated by commas
	 */
	void parsePortData(String inputData){

		// Check that the starts with a number
		if (charIsNum(inputData.charAt(0)) || charIsNum(inputData.charAt(1))) {
			String[] dataArray = split(inputData,',');
			
			// If data column does not exist, add it to the list
			while(dataColumns.length < dataArray.length){
				dataColumns = append(dataColumns, "Signal-" + (dataColumns.length + 1));
				graphAssignment = append(graphAssignment, 1);
				dataTable.addColumn("Signal-" + (dataColumns.length + 1));
				redrawUI = true;
			}
	
			// --- Data Recording ---
			TableRow newRow = dataTable.addRow();
			// Go through each data column, and try to parse and add to file
			for(int i = 0; i < dataArray.length; i++){
				try {
					float dataPoint = Float.parseFloat(dataArray[i]);
					newRow.setFloat(i, dataPoint);
				} catch (Exception e) {
					print(e);
					println(" - When parsing live graph data");
				}
			}

			if (recordData) {
				recordCounter++;
				// Auto-save recording at set intervals to prevent loss of data
				if(recordCounter >= autoSave * xRate){
					recordCounter = 0;
					try {
						saveTable(dataTable, outputfile, "csv");
					} catch (Exception e) {
						print(e);
						saveTable(dataTable, "autoSave.csv", "csv");
					}
				}

			// Remove first few rows from table while table length exceeds bounds
			} else {
				while (dataTable.getRowCount() > xRate * abs(graphA.getMinMax(1) - graphA.getMinMax(0))) {
					dataTable.removeRow(0);
					drawFrom--;
					if (drawFrom < 0) drawFrom = 0;
				}
			}
	
			drawNewData = true;
		}
	}


	/**
	 * Draw the sidebar menu for the current tab
	 */
	void drawSidebar () {

		// Check if serial port has recently been disconnected
		if (!serialConnected && dataColumns.length > 0) {
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
			redrawContent = true;
		}
		
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
		menuHeight = round((11 + dataColumns.length + (graphMode * 0.75)) * uH);

		// Figure out if scrolling of the menu is necessary
		if (menuHeight > sH) {
			if (menuScroll == -1) menuScroll = 0;
			else if (menuScroll > menuHeight - sH) menuScroll = menuHeight - sH;

			// Draw left bar
			fill(c_darkgrey);
			rect(width - round(15 * uimult) / 2, sT, round(15 * uimult) / 2, sH);

			// Figure out size and position of scroll bar indicator
			int scrollbarSize = sH - round(sH * float(menuHeight - sH) / menuHeight);
			if (scrollbarSize < uH) scrollbarSize = uH;
			int scrollbarOffset = round((sH - scrollbarSize) * (menuScroll / float(menuHeight - sH)));
			fill(c_terminal_text);
			rect(width - round(15 * uimult) / 2, sT + scrollbarOffset, round(15 * uimult) / 2, scrollbarSize);

			sT -= menuScroll;
			sL -= round(15 * uimult) / 4;
			iL -= round(15 * uimult) / 4;
		} else {
			menuScroll = -1;
		}

		// Connect or Disconnect to COM Port
		//drawHeading("COM Port", iL, sT + (uH * 0), iW, tH);
		//String[] ports = Serial.list();
		//if(ports.length == 0) drawDatabox("Port: None", iL, sT + (uH * 1), iW, iH, tH);
		//else if(ports.length <= portNumber) drawDatabox("Port: Invalid", iL, sT + (uH * 1), iW, iH, tH);
		//else drawDatabox("Port: " + ports[portNumber], iL, sT + (uH * 1), iW, iH, tH);
		//drawDatabox("Baud: " + baudRate, iL, sT + (uH * 2), iW, iH, tH);
		//drawButton((serialConnected)? "Disconnect":"Connect", (serialConnected)? c_red:c_sidebar_button, iL, sT + (uH * 3), iW, iH, tH);

		// Save to File
		drawHeading("Record Graph Data", iL, sT + (uH * 0), iW, tH);
		drawButton("Set Output File", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
		drawButton((recordData)? "Stop Recording":"Start Recording", (recordData)? c_red:c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);

		// Graph options
		Graph currentGraph;
		if (selectedGraph == 2) currentGraph = graphB;
		else if (selectedGraph == 3) currentGraph = graphC;
		else if (selectedGraph == 4) currentGraph = graphD;
		else currentGraph = graphA;

		drawHeading("Graph " + selectedGraph + " - Options",                                     iL,                sT + (uH * 3.5),         iW, tH);
		drawButton("Line", (currentGraph.getGraphType() == "linechart")? c_red:c_sidebar_button, iL,                sT + (uH * 4.5), iW / 3, iH, tH);
		drawButton("Dots", (currentGraph.getGraphType() == "dotchart")? c_red:c_sidebar_button,  iL + (iW / 3),     sT + (uH * 4.5), iW / 3, iH, tH);
		drawButton("Bar", (currentGraph.getGraphType() == "barchart")? c_red:c_sidebar_button,   iL + (iW * 2 / 3), sT + (uH * 4.5), iW / 3, iH, tH);
		drawRectangle(c_grey, iL + (iW / 3),     sT + (uH * 4.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_grey, iL + (iW * 2 / 3), sT + (uH * 4.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		drawDatabox(str(currentGraph.getMinMax(0)), c_sidebar_button, iL,                           sT + (uH * 5.5), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("x",                             c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 5.5), 12 * uimult,             iH, tH);
		drawDatabox(str(currentGraph.getMinMax(1)),                   iL + (iW / 2) + (6 * uimult), sT + (uH * 5.5), (iW / 2) - (6 * uimult), iH, tH);
		drawDatabox(str(currentGraph.getMinMax(2)),                   iL,                           sT + (uH * 6.5), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("y",                             c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 6.5), 12 * uimult,             iH, tH);
		drawDatabox(str(currentGraph.getMinMax(3)),                   iL + (iW / 2) + (6 * uimult), sT + (uH * 6.5), (iW / 2) - (6 * uimult), iH, tH);

		// Input Data Columns
		drawHeading("Data Format", iL, sT + (uH * 8), iW, tH);
		drawDatabox("Rate: " + xRate + "Hz", iL, sT + (uH * 9), iW, iH, tH);
		//drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
		drawDatabox("Split", c_sidebar_button, iL, sT + (uH * 10), iW - (80 * uimult), iH, tH);
		drawButton("1", (graphMode == 1)? c_red:c_sidebar_button, iL + iW - (80 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
		drawButton("2", (graphMode == 2)? c_red:c_sidebar_button, iL + iW - (60 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
		drawButton("3", (graphMode == 3)? c_red:c_sidebar_button, iL + iW - (40 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
		drawButton("4", (graphMode == 4)? c_red:c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
		drawRectangle(c_grey, iL + iW - (60 * uimult), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_grey, iL + iW - (40 * uimult), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_grey, iL + iW - (20 * uimult), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		float tHnow = 11;

		for (int j = 0; j < graphMode; j++) {
			drawText("Graph " + (j + 1), c_sidebar_button, iL, sT + (uH * tHnow), iW, iH * 3 / 4);
			tHnow += 0.75;
			int itemCount = 0;

			// List of Data Columns
			for(int i = 0; i < dataColumns.length; i++){

				if (graphAssignment[i] == j + 1) {
					// Column name
					drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

					// Up button
					color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
					drawButton((graphAssignment[i] > 1)? "▲":"", c_sidebar, buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

					// Down button
					drawButton((graphAssignment[i] < graphMode)? "▼":"", c_sidebar, buttonColor, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

					drawRectangle(c_grey, iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
					tHnow++;
					itemCount++;
				}
			}

			if (itemCount == 0) drawText("Empty", c_sidebar_button, iL + iW / 2, sT + (uH * (tHnow - itemCount - 0.75)), iW / 2, iH * 3 / 4);
		}

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_lightgrey);
		text("Output File: " + outputfile, round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult), width - sW - round(10 * uimult), round(bottombarHeight * uimult));
	}


	/**
	 * Keyboard input handler function
	 *
	 * @param  key The character of the key that was pressed
	 */
	void keyboardInput(char key) {
		if (key == 's' && serialConnected) {
			final String message = showInputDialog("Serial Message:");
			if (message != null){
				serialSend(message);
			}

		} else if (keyCode == UP) {
			// Scroll menu bar
			if (mouseX >= cR && menuScroll != -1) {
				menuScroll -= (12 * uimult);
				if (menuScroll < 0) menuScroll = 0;
			}
			redrawUI = true;

		} else if (keyCode == DOWN) {
			// Scroll menu bar
			if (mouseX >= cR && menuScroll != -1) {
				menuScroll += (12 * uimult);
				if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
			}
			redrawUI = true;
		}
	}


	/**
	 * Content area mouse click handler function
	 *
	 * @param  xcoord X-coordinate of the mouse click
	 * @param  ycoord Y-coordinate of the mouse click
	 */
	void getContentClick (int xcoord, int ycoord) {
		if ((graphMode == 1 || ycoord <= (cT + cB) / 2) && (graphMode < 3 || xcoord <= (cL + cR) / 2)) {
			selectedGraph = 1;
			graphA.setHighlight(true, true);
			graphB.setHighlight(false, (graphMode > 1)? true:false);
			graphC.setHighlight(false, (graphMode > 2)? true:false);
			graphD.setHighlight(false, (graphMode > 3)? true:false);
			redrawUI = true;
		} else if ((ycoord > (cT + cB) / 2 && graphMode > 1) && (xcoord <= (cL + cR) / 2 || graphMode < 4)) {
			selectedGraph = 2;
			redrawUI = true;
			graphA.setHighlight(false, true);
			graphB.setHighlight(true, true);
			graphC.setHighlight(false, (graphMode > 2)? true:false);
			graphD.setHighlight(false, (graphMode > 3)? true:false);
		} else if ((ycoord <= (cT + cB) / 2 && graphMode > 2) && (xcoord > (cL + cR) / 2)) {
			selectedGraph = 3;
			redrawUI = true;
			graphA.setHighlight(false, true);
			graphB.setHighlight(false, true);
			graphC.setHighlight(true, true);
			graphD.setHighlight(false, (graphMode > 3)? true:false);
		} else if ((ycoord > (cT + cB) / 2 && graphMode > 3) && (xcoord > (cL + cR) / 2)) {
			selectedGraph = 4;
			redrawUI = true;
			graphA.setHighlight(false, true);
			graphB.setHighlight(false, true);
			graphC.setHighlight(false, true);
			graphD.setHighlight(true, true);
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
			menuScroll += (5 * amount * uimult);
			if (menuScroll < 0) menuScroll = 0;
			else if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
		}

		redrawUI = true;
	}


	/**
	 * Sidebar mouse click handler function
	 *
	 * @param  xcoord X-coordinate of the mouse click
	 * @param  ycoord Y-coordinate of the mouse click
	 */
	void mclickSBar (int xcoord, int ycoord) {

		// Coordinate calculation
		int sT = cT;
		if (menuScroll > 0) sT -= menuScroll;
		int sL = cR;
		int sW = width - cR;
		int sH = height - sT;

		int uH = round(sideItemHeight * uimult);
		int tH = round((sideItemHeight - 8) * uimult);
		int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		int iW = int(sW - (20 * uimult));

		// COM Port Number
		/*
		if ((mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
			// Make a list of available serial ports and convert into string
			String dialogOutput = "List of available ports:\n";
			String[] ports = Serial.list();
			if(ports.length == 0) dialogOutput += "No ports available!\n";
			else {
				for(int i = 0; i < ports.length; i++) dialogOutput += ("[" + i + "]: " + ports[i] + "\n");
			}

			final String id = showInputDialog(dialogOutput + "\nPlease enter a list number for the port:");

			if (id != null){
				try {
					portNumber = Integer.parseInt(id);
					redrawUI = true;
				} catch (Exception e) {}
			} 
		}

		// COM Port Baud Rate
		else if ((mouseY > sT + (uH * 2)) && (mouseY < sT + (uH * 2) + iH)){

			final String rate = showInputDialog("Please enter a baud rate:");

			if (rate != null){
				try {
					baudRate = Integer.parseInt(rate);
					redrawUI = true;
				} catch (Exception e) {}
			} 
		}

		// Connect or disconnect COM port
		else if ((mouseY > sT + (uH * 3)) && (mouseY < sT + (uH * 3) + iH)){

			// Connect or disconnect from the port
			setupSerial();
		}*/

		// Select output file name and directory
		if ((mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
			outputfile = "";
			selectInput("Select select a directory and name for output", "fileSelected");
		}
		
		// Start recording data and saving it to a file
		else if ((mouseY > sT + (uH * 2)) && (mouseY < sT + (uH * 2) + iH)){
			if(recordData){
				stopRecording();
			} else if(outputfile != "" && outputfile != "No File Set"){
				startRecording();
			} else {
				alertHeading = "Error - Please set an output file path";
				redrawAlert = true;
			}
		}

		// Change graph type
		else if ((mouseY > sT + (uH * 4.5)) && (mouseY < sT + (uH * 4.5) + iH)){
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Line
			if ((mouseX > iL) && (mouseX <= iL + iW / 3)) {
				currentGraph.setGraphType("linechart");
				redrawContent = redrawUI = true;
			}

			// Dot
			else if ((mouseX > iL + (iW / 3)) && (mouseX <= iL + (iW * 2 / 3))) {
				currentGraph.setGraphType("dotchart");
				redrawContent = redrawUI = true;
			}

			// Bar
			else if ((mouseX > iL + (iW * 2 / 3)) && (mouseX <= iL + iW)) {
				currentGraph.setGraphType("barchart");
				redrawContent = redrawUI = true;
			}
		}

		// Update X axis scaling
		else if ((mouseY > sT + (uH * 5.5)) && (mouseY < sT + (uH * 5.5) + iH)){
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Change X axis minimum value [DISABLED]
			/*
			if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
				final String xMin = showInputDialog("Please enter new X-axis minimum value:");
				if (xMin != null){
					try {
						currentGraph.setMinMax(Float.parseFloat(xMin), 0);
					} catch (Exception e) {}
				} 
				redrawContent = redrawUI = true;
			}
			*/

			// Change X axis maximum value
			if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
				final String xMax = showInputDialog("Please enter new X-axis maximum value:");
				if (xMax != null){
					try {
						currentGraph.setMinMax(Float.parseFloat(xMax), 1);
					} catch (Exception e) {}
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Update Y axis scaling
		else if ((mouseY > sT + (uH * 6.5)) && (mouseY < sT + (uH * 6.5) + iH)){
			Graph currentGraph;
			if (selectedGraph == 2) currentGraph = graphB;
			else if (selectedGraph == 3) currentGraph = graphC;
			else if (selectedGraph == 4) currentGraph = graphD;
			else currentGraph = graphA;

			// Change Y axis minimum value
			if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
				final String yMin = showInputDialog("Please enter new Y-axis minimum value:");
				if (yMin != null){
					try {
						currentGraph.setMinMax(Float.parseFloat(yMin), 2);
					} catch (Exception e) {}
				} 
				redrawContent = redrawUI = true;
			}

			// Change Y axis maximum value
			else if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
				final String yMax = showInputDialog("Please enter new Y-axis maximum value:");
				if (yMax != null){
					try {
						currentGraph.setMinMax(Float.parseFloat(yMax), 3);
					} catch (Exception e) {}
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Change the input data rate
		else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){
			final String newrate = showInputDialog("Set new data rate:");
			if (newrate != null){
				try {
					int newXrate = Integer.parseInt(newrate);
					xRate = newXrate;
					graphA.setXrate(newXrate);
					graphB.setXrate(newXrate);
					graphC.setXrate(newXrate);
					graphD.setXrate(newXrate);
					redrawUI = true;
				} catch (Exception e) {}
			}
		}

		// Add a new input data column
		else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){
			
			// Graph mode 1
			if ((mouseX >= iL + iW - (80 * uimult)) && (mouseX < iL + iW - (60 * uimult))) {
				graphMode = 1;
				graphA.changeSize(cL, cR, cT, cB);
				redrawUI = true;
				redrawContent = true;
				if (selectedGraph > 1) {
					selectedGraph = 1;
					graphA.setHighlight(true, true);
					graphB.setHighlight(false, false);
					graphC.setHighlight(false, false);
					graphD.setHighlight(false, false);
				}
				for (int i = 0; i < graphAssignment.length; i++) graphAssignment[i] = 1;
			
			// Graph mode 2
			} else if ((mouseX >= iL + iW - (60 * uimult)) && (mouseX < iL + iW - (40 * uimult))) {
				graphMode = 2;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, cR, cT, (cT + cB) / 2);
				graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
				if (selectedGraph > 2) {
					selectedGraph = 2;
					graphA.setHighlight(false, true);
					graphB.setHighlight(true, true);
					graphC.setHighlight(false, false);
					graphD.setHighlight(false, false);
				}
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode) graphAssignment[i] = graphMode;
				}

			// Graph mode 3
			} else if ((mouseX >= iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
				graphMode = 3;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
				graphB.changeSize(cL, cR, (cT + cB) / 2, cB);
				graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
				if (selectedGraph > 3) {
					selectedGraph = 3;
					graphA.setHighlight(false, true);
					graphB.setHighlight(false, true);
					graphC.setHighlight(true, true);
					graphD.setHighlight(false, false);
				}
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode) graphAssignment[i] = graphMode;
				}

			// Graph mode 4
			} else if ((mouseX >= iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
				graphMode = 4;
				redrawUI = true;
				redrawContent = true;
				graphA.changeSize(cL, (cL + cR) / 2, cT, (cT + cB) / 2);
				graphB.changeSize(cL, (cL + cR) / 2, (cT + cB) / 2, cB);
				graphC.changeSize((cL + cR) / 2, cR, cT, (cT + cB) / 2);
				graphD.changeSize((cL + cR) / 2, cR, (cT + cB) / 2, cB);
				for (int i = 0; i < graphAssignment.length; i++) {
					if (graphAssignment[i] > graphMode) graphAssignment[i] = graphMode;
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
		
		else {
			float tHnow = 11;

			for (int j = 0; j < graphMode; j++) {
				tHnow += 0.75;

				// List of Data Columns
				for(int i = 0; i < dataColumns.length; i++){

					if (graphAssignment[i] == j + 1) {

						if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)){

							// Down arrow
							if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
								graphAssignment[i]++;
								if (graphAssignment[i] > graphMode) graphAssignment[i] = graphMode;
								redrawUI = true;
								redrawContent = true;
							}

							// Up arrow
							else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
								graphAssignment[i]--;
								if (graphAssignment[i] < 1) graphAssignment[i] = 1;
								redrawUI = true;
								redrawContent = true;
							}

							// Change name of column
							else {
								final String colname = showInputDialog("New Column Name:");
								if (colname != null){
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
}
