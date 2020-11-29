/* * * * * * * * * * * * * * * * * * * * * * *
 * FILE GRAPH PLOTTER CLASS
 * implements TabAPI for Processing Grapher
 *
 * @file     FileGraph.pde
 * @brief    Tab to plot CSV file data on a graph
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    FileGraph
 * @see      TabAPI <ProcessingGrapher.pde>
 * * * * * * * * * * * * * * * * * * * * * * */

/*
 * Copyright (C) 2020 - Simon Bluett <hello@chillibasket.com>
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

class FileGraph implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	int xData;
	Graph graph;
	int menuScroll;
	int menuHeight;

	String name;
	String outputfile;
	String[] dataColumns = {};
	Table dataTable;

	boolean changesMade;
	boolean labelling;
	boolean zoomActive;
	int setZoomSize;
	float[] zoomCoordOne = {0, 0, 0, 0};


	/**
	 * Constructor
	 *
	 * @param  setname Name of the tab
	 * @param  left    Tab area left x-coordinate
	 * @param  right   Tab area right x-coordinate
	 * @param  top     Tab area top y-coordinate
	 * @param  bottom  Tab area bottom y-coordinate
	 */
	FileGraph (String setname, int left, int right, int top, int bottom) {
		name = setname;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		xData = -1;     // -1 if no data column contains x-axis data

		graph = new Graph(cL, cR, cT, cB, 0, 100, 0, 10, "Graph 1");
		graph.setHighlight(true);
		outputfile = "No File Set";

		zoomActive = false;
		setZoomSize = -1;
		labelling = false;
		menuScroll = 0;
		menuHeight = cB - cT - 1; 
		changesMade = false;
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
	 * Redraw all tab content
	 */
	void drawContent () {
		graph.drawGrid();
		plotFileData();

		// Show message if no serial device is connected
		if (outputfile == "No File Set") {
			if (showInstructions) {
				String[] message = {"1. Click 'Open CSV File' to open and plot the signals from a *.CSV file",
								    "2. The first row of the file should contain headings for each of the signal",
								    "3. If the heading starts with 'x:', this column will be used as the x-axis"};
				drawMessageArea("Getting Started", message, cL + 60 * uimult, cR - 60 * uimult, cT + 30 * uimult);
			}
		}
	}


	/**
	 * Draw new tab data
	 */
	void drawNewData () {
		// Not being used yet 
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

		graph.changeSize(cL, cR, cT, cB);
		//drawContent();
	}


	/**
	 * Change CSV data file location
	 *
	 * @param  newoutput Absolute path to the new file location
	 */
	void setOutput (String newoutput) {
		
		if (newoutput != "No File Set") {
			// Check whether file is of type *.csv
			if (newoutput.contains(".csv")) {
				dataTable = loadTable(newoutput, "csv, header");
				outputfile = newoutput;
				zoomActive = false;
				changesMade = false;
			} else {
				alertHeading = "Error\nInvalid file type; it must be *.csv";
				outputfile = "No File Set";
				redrawAlert = true;
				zoomActive = false;
				changesMade = false;
				xData = -1;
				while (dataColumns.length > 0) dataColumns = remove(dataColumns, 0);
			}
		} else {
			outputfile = newoutput;
			zoomActive = false;
			changesMade = false;
			xData = -1;
			while (dataColumns.length > 0) dataColumns = remove(dataColumns, 0);
		}

		redrawContent = true;
	}


	/**
	 * Plot CSV data from file onto a graph
	 */
	void plotFileData () {
		if(outputfile != "No File Set" && outputfile != "" && dataTable.getColumnCount() > 0) {
			xData = -1;

			// Load columns
			while (dataColumns.length > 0) dataColumns = shorten(dataColumns);

			for (int i = 0; i < dataTable.getColumnCount(); i++) {
				dataColumns = append(dataColumns, dataTable.getColumnTitle(i));
				if (dataTable.getColumnTitle(i).contains("x:")) {
					xData = i;
				}
			}

			redrawUI = true;
			if (xData == -1) graph.setXaxisName("Time (s)");
			else {
				try {
					String xAxisName = split(dataTable.getColumnTitle(xData), ':')[1];
					graph.setXaxisName(xAxisName);
				} catch (Exception e) {
					println("Error when trying to set X-axis name: " + e);
				}
			}

			// Ensure that some data acutally exists in the table
			if (dataTable.getRowCount() > 0 && !(xData == 0 && dataTable.getColumnCount() == 1)) {
				
				float minx, maxx;
				float miny, maxy;

				if (xData == -1) {
					minx = 0;
					maxx = 0;
					miny = dataTable.getFloat(0, 0);
					maxy = dataTable.getFloat(0, 0);
				} else {
					minx = dataTable.getFloat(0, xData);
					maxx = dataTable.getFloat(dataTable.getRowCount() - 1, xData);
					if (xData == 0) {
						miny = dataTable.getFloat(0, 1);
						maxy = dataTable.getFloat(0, 1);
					} else {
						miny = dataTable.getFloat(0, 0);
						maxy = dataTable.getFloat(0, 0);
					}
				}

				// Calculate Min and Max X and Y axis values
				for (TableRow row : dataTable.rows()) {

					if (xData != -1) {
						if(minx > row.getFloat(xData)) minx = row.getFloat(xData);
						if(maxx < row.getFloat(xData)) maxx = row.getFloat(xData);
					} else {
						maxx += 1 / float(graph.getXrate());
					}

					for(int i = 0; i < dataTable.getColumnCount(); i++){
						if (i != xData) {
							if(miny > row.getFloat(i)) miny = row.getFloat(i);
							if(maxy < row.getFloat(i)) maxy = row.getFloat(i);
						}
					}
				}

				// Only update axis values if zoom isn't active
				if (zoomActive == false) {
					// Set these min and max values
					graph.setMinX(floorToSigFig(minx, 2));
					graph.setMaxX(ceilToSigFig(maxx, 2));
					graph.setMinY(floorToSigFig(miny, 2));
					graph.setMaxY(ceilToSigFig(maxy, 2));
				}

				// Draw the axes and grid
				graph.reset();
				graph.drawGrid();

				// Start plotting the data
				int counter = 0;
				for (TableRow row : dataTable.rows()) {
					if (xData != -1){
						for (int i = 0; i < dataTable.getColumnCount(); i++) {
							if (i != xData) {
								try {
									float dataX = row.getFloat(xData);
									float dataPoint = row.getFloat(i);
									if(Float.isNaN(dataX) || Float.isNaN(dataPoint)) dataPoint = dataX = 99999999;
									
									// Only plot it if it is within the X-axis data range
									if (dataX >= graph.getMinX() && dataX <= graph.getMaxX()) {
										graph.plotData(dataPoint, dataX, i);
									}
								} catch (Exception e) {
									println("Error trying to plot file data.");
									println(e);
								}
							}
						}
					} else {
						for (int i = 0; i < dataTable.getColumnCount(); i++) {
							try {
								// Only start plotting when desired X-point has arrived
								float currentX = counter / float(graph.getXrate());
								if (currentX >= graph.getMinX() && currentX <= graph.getMaxX()) {
									float dataPoint = row.getFloat(i);
									if(Float.isNaN(dataPoint)) dataPoint = 99999999;
									graph.plotData(dataPoint, currentX, i);
								}
							} catch (Exception e) {
								println("Error trying to plot file data.");
								println(e);
							}
						}
					}
					counter++;
				}
			}
		}
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
	 * Save any new changes to the current CSV data file
	 */
	void saveData () {
		if(outputfile != "No File Set" && outputfile != "") {
			try {
				saveTable(dataTable, outputfile, "csv");
				alertHeading = "Success!\nThe data has been saved to the file";
				redrawAlert = true;
			} catch (Exception e){
				alertHeading = "Error\nUnable to save file:\n" + e;
				redrawAlert = true;
			}
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
		menuHeight = round((15 + dataColumns.length) * uH);

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

			sT -= menuScroll;
			sL -= round(15 * uimult) / 4;
			iL -= round(15 * uimult) / 4;
		} else {
			menuScroll = -1;
		}

		// Open, close and save files
		drawHeading("Analyse Data", iL, sT + (uH * 0), iW, tH);
		drawButton("Open CSV File", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
		//if (outputfile != ""  && outputfile != "No File Set" && changesMade) {
		//	drawButton("Save Changes", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);
		//} else {
			drawDatabox("Save Changes", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);
		//}

		// Add labels to data
		drawHeading("Data Labels", iL, sT + (uH * 3.5), iW, tH);
		if (outputfile != ""  && outputfile != "No File Set") {
			drawButton("Add Label", c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
			drawButton("Remove Labels", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
		} else {
			drawDatabox("Add Label", c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
			drawDatabox("Remove Labels", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
		}
		
		// Graph type
		drawHeading("Graph Options", iL, sT + (uH * 7), iW, tH);
		drawButton("Line", (graph.getGraphType() == "linechart")? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 8), iW / 3, iH, tH);
		drawButton("Dots", (graph.getGraphType() == "dotchart")? c_sidebar_accent:c_sidebar_button, iL + (iW / 3), sT + (uH * 8), iW / 3, iH, tH);
		drawButton("Bar", (graph.getGraphType() == "barchart")? c_sidebar_accent:c_sidebar_button, iL + (iW * 2 / 3), sT + (uH * 8), iW / 3, iH, tH);
		drawRectangle(c_sidebar_divider, iL + (iW / 3), sT + (uH * 8) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		drawRectangle(c_sidebar_divider, iL + (iW * 2 / 3), sT + (uH * 8) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		// Graph scaling / segmentation
		drawDatabox(str(graph.getMinX()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), iL, sT + (uH * 9), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("x", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 9), 12 * uimult, iH, tH);
		drawDatabox(str(graph.getMaxX()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), iL + (iW / 2) + (6 * uimult), sT + (uH * 9), (iW / 2) - (6 * uimult), iH, tH);
		drawDatabox(str(graph.getMinY()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), iL, sT + (uH * 10), (iW / 2) - (6 * uimult), iH, tH);
		drawButton("y", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 10), 12 * uimult, iH, tH);
		drawDatabox(str(graph.getMaxY()).replaceAll("[0]+$", "").replaceAll("[.]+$", ""), iL + (iW / 2) + (6 * uimult), sT + (uH * 10), (iW / 2) - (6 * uimult), iH, tH);

		// Zoom Options
		if (outputfile != ""  && outputfile != "No File Set") {
			drawButton("Zoom", c_sidebar_button, iL, sT + (uH * 11), iW / 2, iH, tH);
			drawButton("Reset", c_sidebar_button, iL + (iW / 2), sT + (uH * 11), iW / 2, iH, tH);
			drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
		} else {
			drawDatabox("Zoom", c_sidebar_button, iL, sT + (uH * 11), iW / 2, iH, tH);
			drawDatabox("Reset", c_sidebar_button, iL + (iW / 2), sT + (uH * 11), iW / 2, iH, tH);
		}

		// Input Data Columns
		drawHeading("Data Format", iL, sT + (uH * 12.5), iW, tH);
		if (xData != -1) drawButton("X: " + split(dataColumns[xData], ':')[1], c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
		else drawDatabox("Rate: " + graph.getXrate() + "Hz", iL, sT + (uH * 13.5), iW, iH, tH);
		//drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 12.5), iW, iH, tH);

		float tHnow = 14.5;

		// List of Data Columns
		for(int i = 0; i < dataColumns.length; i++){
			if (i != xData) {
				// Column name
				drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

				// Remove column button
				drawButton("x", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);
				
				// Hide or Show data series
				color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
				drawButton("", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

				drawRectangle(c_sidebar_divider, iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
				tHnow++;
			}
		}

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_status_bar);
		text("Input: " + constrainString(outputfile, width - sW - round(30 * uimult) - textWidth("Input: ")), round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult));
	}


	/**
	 * Keyboard input handler function
	 *
	 * @param  key The character of the key that was pressed
	 */
	void keyboardInput (char keyChar, int keyCodeInt, boolean codedKey) {
		if (codedKey) {
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
		if (labelling) {
			if(outputfile != "" && outputfile != "No File Set"){

				int xItem = graph.setXlabel(xcoord, ycoord);
				if (xItem != -1) {
					changesMade = true;
					redrawUI = true;
				}
			} 
			labelling = false;
			cursor(ARROW);
		} 

		else if (setZoomSize == 0) {
			if (graph.onGraph(xcoord, ycoord)) {
				zoomCoordOne[0] = (graph.xGraphPos(xcoord) * (graph.getMaxX() - graph.getMinX())) + graph.getMinX();
				zoomCoordOne[1] = ((1 - graph.yGraphPos(ycoord)) * (graph.getMaxY() - graph.getMinY())) + graph.getMinY();
				stroke(c_graph_axis);
				strokeWeight(1 * uimult);
				line(xcoord - (5 * uimult), ycoord, xcoord + (5 * uimult), ycoord);
				line(xcoord, ycoord - (5 * uimult), xcoord, ycoord + (5 * uimult));
				setZoomSize = 1;
			}

		} else if (setZoomSize == 1) {
			if (graph.onGraph(xcoord, ycoord)) {
				zoomCoordOne[2] = (graph.xGraphPos(xcoord) * (graph.getMaxX() - graph.getMinX())) + graph.getMinX();
				zoomCoordOne[3] = ((1 - graph.yGraphPos(ycoord)) * (graph.getMaxY() - graph.getMinY())) + graph.getMinY();
				setZoomSize = -1;

				if (zoomCoordOne[0] < zoomCoordOne[2]) {
					graph.setMinX(floorToSigFig(zoomCoordOne[0], 4));
					graph.setMaxX(ceilToSigFig(zoomCoordOne[2], 4));
				} else {
					graph.setMaxX(ceilToSigFig(zoomCoordOne[0], 4));
					graph.setMinX(floorToSigFig(zoomCoordOne[2], 4));
				}

				if (zoomCoordOne[1] < zoomCoordOne[3]) {
					graph.setMinY(floorToSigFig(zoomCoordOne[1], 4));
					graph.setMaxY(ceilToSigFig(zoomCoordOne[3], 4));
				} else {
					graph.setMaxY(ceilToSigFig(zoomCoordOne[1], 4));
					graph.setMinY(floorToSigFig(zoomCoordOne[3], 4));
				}

				redrawContent = true;
				redrawUI = true;
				cursor(ARROW);
			}
		}

		else cursor(ARROW);
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
	 * Scroll bar handler function
	 *
	 * @param  xcoord Current mouse x-coordinate position
	 * @param  ycoord Current mouse y-coordinate position
	 */
	void scrollBarUpdate (int xcoord, int ycoord) {

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
		if (menuScroll > 0) sT -= menuScroll;
		int sL = cR;
		int sW = width - cR;
		int sH = height - sT;

		int uH = round(sideItemHeight * uimult);
		int tH = round((sideItemHeight - 8) * uimult);
		int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		int iW = round(sW - (20 * uimult));

		// Open data
		if ((mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
			outputfile = "";
			selectInput("Select CSV data file to open", "fileSelected");
		}

		// Save data - currently disabled
		else if ((mouseY > sT + (uH * 2)) && (mouseY < sT + (uH * 2) + iH)){
			//if (outputfile != "" && outputfile != "No File Set" && changesMade){
			//	saveData();
			//}
		}

		// Add label
		else if ((mouseY > sT + (uH * 4.5)) && (mouseY < sT + (uH * 4.5) + iH)){
			if (outputfile != "" && outputfile != "No File Set"){
				labelling = true;
				cursor(CROSS);
			}
		}
		
		// Remove all labels
		else if ((mouseY > sT + (uH * 5.5)) && (mouseY < sT + (uH * 5.5) + iH)){
			redrawContent = redrawUI = true;
		}

		// Change graph type
		else if ((mouseY > sT + (uH * 8)) && (mouseY < sT + (uH * 8) + iH)){

			// Line
			if ((mouseX > iL) && (mouseX <= iL + iW / 3)) {
				graph.setGraphType("linechart");
				redrawContent = redrawUI = true;
			}

			// Dot
			else if ((mouseX > iL + (iW / 3)) && (mouseX <= iL + (iW * 2 / 3))) {
				graph.setGraphType("dotchart");
				redrawContent = redrawUI = true;
			}

			// Bar
			else if ((mouseX > iL + (iW * 2 / 3)) && (mouseX <= iL + iW)) {
				graph.setGraphType("barchart");
				redrawContent = redrawUI = true;
			}
		}

		// Update X axis scaling
		else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){

			// Change X axis minimum value
			if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
				final String xMin = showInputDialog("Please enter new X-axis minimum value:\nCurrent value = " + graph.getMinX());
				if (xMin != null){
					try {
						graph.setMinX(Float.parseFloat(xMin));
						zoomActive = true;
					} catch (Exception e) {
						println("FileGraph::mclickSBar() - X-axis min value error: " + e);
					}
				} 
				redrawContent = redrawUI = true;
			}

			// Change X axis maximum value
			else if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
				final String xMax = showInputDialog("Please enter new X-axis maximum value:\nCurrent value = " + graph.getMaxX());
				if (xMax != null){
					try {
						graph.setMaxX(Float.parseFloat(xMax));
						zoomActive = true;
					} catch (Exception e) {
						println("FileGraph::mclickSBar() - X-axis max value error: " + e);
					}
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Update Y axis scaling
		else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){

			// Change Y axis minimum value
			if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
				final String yMin = showInputDialog("Please enter new Y-axis minimum value:\nCurrent value = " + graph.getMinY());
				if (yMin != null){
					try {
						graph.setMinY(Float.parseFloat(yMin));
						zoomActive = true;
					} catch (Exception e) {
						println("FileGraph::mclickSBar() - Y-axis min value error: " + e);
					}
				} 
				redrawContent = redrawUI = true;
			}

			// Change Y axis maximum value
			else if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
				final String yMax = showInputDialog("Please enter new Y-axis maximum value:\nCurrent value = " + graph.getMaxY());
				if (yMax != null){
					try {
						graph.setMaxY(Float.parseFloat(yMax));
						zoomActive = true;
					} catch (Exception e) {
						println("FileGraph::mclickSBar() - Y-axis max value error: " + e);
					}
				} 
				redrawContent = redrawUI = true;
			}
		}

		// Zoom Options
		else if ((mouseY > sT + (uH * 11)) && (mouseY < sT + (uH * 11) + iH)){

			if (outputfile != "" && outputfile != "No File Set") {
				// New zoom
				if ((mouseX > iL) && (mouseX <= iL + iW / 2)) {
					zoomActive = true;
					setZoomSize = 0;
					cursor(CROSS);
					//redrawUI = true;
				}

				// Reset zoom
				else if ((mouseX > iL + (iW / 2)) && (mouseX <= iL + iW)) {
					zoomActive = false;
					cursor(ARROW);
					redrawContent = redrawUI = true;
				}
			}
		}

		// Change the input data rate
		else if ((mouseY > sT + (uH * 13.5)) && (mouseY < sT + (uH * 13.5) + iH)){
			if (xData == -1) {
				final String newrate = showInputDialog("Set new data rate:\nCurrent value = " + graph.getXrate());
				if (newrate != null){
					try {
						int newXrate = Integer.parseInt(newrate);

						if (newXrate > 0 && newXrate < 10000) {
							graph.setXrate(newXrate);
							redrawContent = true;
							redrawUI = true;
						} else {
							alertHeading = "Error\nInvalid frequency entered.\nThe rate can only be a number between 0 - 10,000 Hz";
							redrawAlert = true;
						}
					} catch (Exception e) {
						alertHeading = "Error\nInvalid frequency entered.\nThe rate can only be a number between 0 - 10,000 Hz";
						redrawAlert = true;
					}
				}
			}
		}
		
		// Edit data column
		else {
			float tHnow = 14.5;

			// List of Data Columns
			for(int i = 0; i < dataColumns.length; i++){

				if (i != xData) {
					if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)){

						if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
							if (xData != -1 && xData < i) {
								dataColumns = remove(dataColumns, i + 1);
								dataTable.removeColumn(i + 1);
							} else {
								dataColumns = remove(dataColumns, i);
								dataTable.removeColumn(i);
							}
							changesMade = true;
							redrawContent = true;
							redrawUI = true;
						}

						else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
							/*
							if (i - 1 >= 0) {
								String temp = dataColumns[i - 1];
								dataColumns[i - 1] = dataColumns[i];
								dataColumns[i] = temp;
							}
							redrawUI = true;*/
						}
					}
				}
				
				tHnow++;
			}
		}
	}


	/**
	 * Serial port data handler function
	 *
	 * @param  inputData New data received from the serial port
	 * @param  graphable True if data in message can be plotted on a graph
	 */
	void parsePortData(String inputData, boolean graphable) {
		// Empty as this tab is not using serial comms 
	}


	/**
	 * Function called when a serial device has connected/disconnected
	 *
	 * @param  status True if a device has connected, false if disconnected
	 */
	void connectionEvent (boolean status) {
		// Empty as this tab is not using serial comms
	}
}
