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

class FileGraph implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	int xData;
	Graph graph;
	int menuScroll;
	int menuHeight;
	int menuLevel;
	ScrollBar sidebarScroll = new ScrollBar(ScrollBar.VERTICAL, ScrollBar.NORMAL);

	String name;
	String outputfile;
	String currentfile;
	Table dataTable;
	ArrayList<DataSignal> dataSignals = new ArrayList<DataSignal>();

	color previousColor = c_red;
	color hueColor = c_red;
	color newColor = c_red;
	int colorSelector = 0;

	boolean saveFilePath = false;
	boolean changesMade;
	boolean labelling;
	boolean zoomActive;
	boolean workerActive;
	boolean tabIsVisible;
	int setZoomSize;
	int selectedSignal;
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
		currentfile = "No File Set";

		tabIsVisible = false;
		zoomActive = false;
		setZoomSize = -1;
		labelling = false;
		menuScroll = 0;
		menuHeight = cB - cT - 1; 
		menuLevel = 0;
		changesMade = false;
		selectedSignal = 0;
		workerActive = false;
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

		if (workerActive) {
			String[] message = {"Loading in progress!"};
			drawMessageArea("Please Standby", message, cL + 60 * uimult, cR - 60 * uimult, cT + 30 * uimult);
		
		// Show message if no serial device is connected
		} else if (currentfile == "No File Set") {
			graph.drawGrid();
			if (showInstructions) {
				String[] message = {"1. Click 'Open CSV File' to open and plot the signals from a *.CSV file",
								    "2. The first row of the file should contain headings for each of the signal",
								    "3. If the heading starts with 'x:', this column will be used as the x-axis"};
				drawMessageArea("Getting Started", message, cL + 60 * uimult, cR - 60 * uimult, cT + 30 * uimult);
			}
		} else {
			//graph.drawGrid();
			plotFileData();
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

			if (saveFilePath) {
				// Ensure file type is *.csv
				int dotPos = newoutput.lastIndexOf(".");
				if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
				newoutput = newoutput + ".csv";

				// Test whether this file is actually accessible
				if (saveFile(newoutput) == null) {
					alertMessage("Error\nUnable to access the selected output file location; perhaps this location is write-protected?\n" + newoutput);
					newoutput = "No File Set";
				}
				outputfile = newoutput;
				saveData();

			} else {
				// Check whether file is of type *.csv
				if (newoutput.contains(".csv")) {
					//outputfile = newoutput;
					currentfile = newoutput;
					outputfile = "No File Set";
					xData = -1;
					workerActive = true;
					WorkerThread loadingThread = new WorkerThread();
					loadingThread.loadFile();
					zoomActive = false;
					changesMade = false;
				} else {
					alertMessage("Error\nInvalid file type; it must be *.csv");
					outputfile = "No File Set";
					zoomActive = false;
				}
			}
			
		} else {
			outputfile = newoutput;
			zoomActive = false;
		}

		redrawContent = true;
	}


	/**
	 * Plot CSV data from file onto a graph
	 */
	void plotFileData () {
		if (currentfile != "No File Set" && currentfile != "" && dataTable.getColumnCount() > 0) {

			xData = -1;

			// Check that columns are loaded
			for (int i = 0; i < dataTable.getColumnCount(); i++) {
				
				String columnTitle = dataTable.getColumnTitle(i);
				if (columnTitle.contains("x:") || columnTitle.contains("X:")) {
					xData = i;
				} else if (columnTitle.contains("l:")) {
					columnTitle = split(columnTitle, ':')[1];
				}

				boolean signalCheck = false;
				for (DataSignal curSig : dataSignals) {
					if (curSig.signalText.equals(columnTitle))
						signalCheck = true;
				}
				if (!signalCheck)
					dataSignals.add(new DataSignal(columnTitle, c_colorlist[i % c_colorlist.length]));
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
				
				double minx, maxx;
				double miny, maxy;

				if (xData == -1) {
					minx = 0;
					maxx = 0;
					miny = dataTable.getDouble(0, 0);
					maxy = dataTable.getDouble(0, 0);
				} else {
					minx = dataTable.getDouble(0, xData);
					maxx = dataTable.getDouble(dataTable.getRowCount() - 1, xData);
					if (xData == 0) {
						miny = dataTable.getDouble(0, 1);
						maxy = dataTable.getDouble(0, 1);
					} else {
						miny = dataTable.getDouble(0, 0);
						maxy = dataTable.getDouble(0, 0);
					}
				}

				// Calculate Min and Max X and Y axis values
				for (TableRow row : dataTable.rows()) {

					if (xData != -1) {
						if(minx > row.getDouble(xData)) minx = row.getDouble(xData);
						if(maxx < row.getDouble(xData)) maxx = row.getDouble(xData);
					} else {
						maxx += 1.0 / graph.getXrate();
					}

					for(int i = 0; i < dataTable.getColumnCount(); i++){
						if ((i != xData) && (!dataTable.getColumnTitle(i).contains("l:"))) {
							if(miny > row.getDouble(i)) miny = row.getDouble(i);
							if(maxy < row.getDouble(i)) maxy = row.getDouble(i);
						}
					}
				}

				// Only update axis values if zoom isn't active
				if (zoomActive == false) {
					// Set these min and max values
					graph.setMinMax((float) floorToSigFig(minx, 2), (float) ceilToSigFig(maxx, 2), (float) floorToSigFig(miny, 2), (float) ceilToSigFig(maxy, 2));
				}

				// Draw the axes and grid
				graph.reset();
				graph.drawGrid();

				int counter = 0;

				// Start plotting the data
				int percentage = 0;
				for (TableRow row : dataTable.rows()) {

					float value = counter / float(dataTable.getRowCount());
					if (percentage < int(value * 100)) {
						percentage = int(value * 100);
						//println(percentage);
					}

					if (xData != -1){
						for (int i = 0; i < dataTable.getColumnCount(); i++) {
							if (i != xData) {
								try {
									double dataX = row.getDouble(xData);
									double dataPoint = row.getDouble(i);
									if(Double.isNaN(dataX) || Double.isNaN(dataPoint)) dataPoint = dataX = 99999999;
									
									// Only plot it if it is within the X-axis data range
									if (dataX >= graph.getMinX() && dataX <= graph.getMaxX()) {
										if (dataTable.getColumnTitle(i).contains("l:")) {
											if (dataPoint == 1) graph.plotXlabel((float) dataX, i, dataSignals.get(i).signalColor);
										} else graph.plotData((float) dataPoint, (float) dataX, i, dataSignals.get(i).signalColor);
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
								float currentX = counter / graph.getXrate();
								if (currentX >= graph.getMinX() && currentX <= graph.getMaxX()) {
									double dataPoint = row.getDouble(i);
									if (Double.isNaN(dataPoint)) dataPoint = 99999999;
									if (dataTable.getColumnTitle(i).contains("l:")) {
										if (dataPoint == 1) graph.plotXlabel((float) currentX, i, dataSignals.get(i).signalColor);
									} else graph.plotData((float) dataPoint, (float) currentX, i, dataSignals.get(i).signalColor);
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
		if (outputfile != "No File Set" && outputfile != "" && currentfile != "No File Set") {
			try {
				saveTable(dataTable, outputfile, "csv");
				currentfile = outputfile;
				saveFilePath = false;
				redrawUI = true;
				alertMessage("Success!\nThe data has been saved to the file");
			} catch (Exception e){
				alertMessage("Error\nUnable to save file:\n" + e);
			}
			outputfile = "No File Set";
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
		Filters filterClass = new Filters();

		if (menuLevel == 0)	{
			menuHeight = round((15 + dataSignals.size()) * uH);
			if (xData != -1) menuHeight -= uH;
		} else if (menuLevel == 1) {
			menuHeight = round((3 + dataSignals.size()) * uH);
			if (xData != -1) menuHeight -= uH;
		} else if (menuLevel == 2) menuHeight = round((3 + filterClass.filterList.length) * uH);
		else if (menuLevel == 3) menuHeight = round(9 * uH + iW);

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

		// Root sidebar menu
		if (menuLevel == 0) {
			// Open, close and save files
			drawHeading("Analyse Data", iL, sT + (uH * 0), iW, tH);
			drawButton("Open CSV File", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
			if (currentfile != ""  && currentfile != "No File Set" && changesMade) {
				drawButton("Save Changes", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);
			} else {
				drawDatabox("Save Changes", c_idletab_text, iL, sT + (uH * 2), iW, iH, tH);
			}

			// Add labels to data
			drawHeading("Data Manipulation", iL, sT + (uH * 3.5), iW, tH);
			if (currentfile != ""  && currentfile != "No File Set") {
				drawButton("Add a Label", c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
				drawButton("Apply a Filter", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
			} else {
				drawDatabox("Add a Label", c_idletab_text, iL, sT + (uH * 4.5), iW, iH, tH);
				drawDatabox("Apply a Filter", c_idletab_text, iL, sT + (uH * 5.5), iW, iH, tH);
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
			if (currentfile != ""  && currentfile != "No File Set") {
				drawButton("Zoom", (setZoomSize >= 0)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 11), iW / 2, iH, tH);
				drawButton("Reset", (zoomActive)? c_sidebar_accent:c_sidebar_button, iL + (iW / 2), sT + (uH * 11), iW / 2, iH, tH);
				drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
			} else {
				drawDatabox("Zoom", c_idletab_text, iL, sT + (uH * 11), iW / 2, iH, tH);
				drawDatabox("Reset", c_idletab_text, iL + (iW / 2), sT + (uH * 11), iW / 2, iH, tH);
			}

			// Input Data Columns
			drawHeading("Data Format", iL, sT + (uH * 12.5), iW, tH);
			if (xData != -1) drawButton("X: " + split(dataSignals.get(xData).signalText, ':')[1], c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
			else drawDatabox("Rate: " + graph.getXrate() + "Hz", iL, sT + (uH * 13.5), iW, iH, tH);
			//drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 12.5), iW, iH, tH);

			float tHnow = 14.5;

			// List of Data Columns
			for (int i = 0; i < dataSignals.size(); i++) {
				if (i != xData) {
					// Column name
					drawDatabox(dataSignals.get(i).signalText, iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

					// Remove column button
					drawButton("✕", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);
					
					// Hide or Show data series
					color buttonColor = dataSignals.get(i).signalColor;
					drawButton("", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

					drawRectangle(c_sidebar_divider, iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
					tHnow++;
				}
			}

		// Signal selection menu (signal to be filtered)
		} else if (menuLevel == 1) {
			drawHeading("Select a Signal", iL, sT + (uH * 0), iW, tH);

			float tHnow = 1;
			if (dataSignals.size() == 0 || (dataSignals.size() == 1 && xData != -1)) {
				drawText("No signals available", c_sidebar_text, iL, sT + (uH * tHnow), iW, iH);
				tHnow += 1;
			} else {
				for (int i = 0; i < dataSignals.size(); i++) {
					if (i != xData && !dataTable.getColumnTitle(i).contains("l:")) {
						drawButton(constrainString(dataSignals.get(i).signalText, iW - (10 * uimult)), c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
						tHnow += 1;
					}
				}
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_accent, iL, sT + (uH * tHnow), iW, iH, tH);

		// Filter selection menu
		} else if (menuLevel == 2) {
			drawHeading("Select a Filter", iL, sT + (uH * 0), iW, tH);

			float tHnow = 1;
			if (filterClass.filterList.length == 0) {
				drawText("No filters available", c_sidebar_text, iL, sT + (uH * tHnow), iW, iH);
				tHnow += 1;
			} else {
				for (int i = 0; i < filterClass.filterList.length; i++) {
					String filterName = filterClass.filterList[i];
					if (filterName.contains("h:")) {
						filterName = split(filterName, ":")[1];
						drawText(filterName, c_idletab_text, iL, sT + (uH * tHnow), iW, iH);
					} else {
						drawButton(constrainString(filterClass.filterList[i], iW - (10 * uimult)), c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
					}
					tHnow += 1;
				}
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_accent, iL, sT + (uH * tHnow), iW, iH, tH);
		
		// Colour picker menu
		} else if (menuLevel == 3) {
			drawHeading("Select a Colour", iL, sT + (uH * 0), iW, tH);
			drawColorSelector(hueColor, iL, sT + (uH * 1), iW, iW); 
			drawHeading("Set Brightness", iL, sT + (uH * 1.5) + iW, iW, tH);
			drawColorBox2D(newColor, c_white, hueColor, iL, sT + (uH * 2.5) + iW, iW / 2, iH);
			drawColorBox2D(newColor, hueColor, c_black, iL + (iW / 2), sT + (uH * 2.5) + iW, iW / 2, iH);
			drawHeading("Colour Preview", iL, sT + (uH * 4) + iW, iW, tH);
			drawText("New", c_idletab_text, iL, sT + (uH * 4.75) + iW, iW / 2, iH);
			drawText("Old", c_idletab_text, iL + (iW / 2) + (2 * uimult), sT + (uH * 4.75) + iW, iW / 2, iH);
			drawButton("", newColor, iL, sT + (uH * 5.5) + iW, (iW / 2) - (3 * uimult), iH, tH);
			drawButton("", previousColor, iL + (iW / 2) + (2 * uimult), sT + (uH * 5.5) + iW, (iW / 2) - (2 * uimult), iH, tH);
			drawButton("Confirm", c_sidebar_button, iL, sT + (uH * 6.5) + iW, iW, iH, tH);
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * 7.5) + iW, iW, iH, tH);
		}

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_status_bar);
		text("Input: " + constrainString(currentfile, width - sW - round(30 * uimult) - textWidth("Input: ")), round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult));
	}


	/**
	 * Keyboard input handler function
	 *
	 * @param  key The character of the key that was pressed
	 */
	void keyboardInput (char keyChar, int keyCodeInt, boolean codedKey) {
		if (keyChar == ESC) {
			if (menuLevel != 0) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
			} else if (setZoomSize >= 0) {
				setZoomSize = -1;
				cursor(ARROW);
				redrawContent = true;
				redrawUI = true;
			}
		}

		else if (codedKey) {
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

		// Add a new data label
		if (labelling) {
			if (currentfile != "" && currentfile != "No File Set") {
				if (graph.onGraph(xcoord, ycoord)) {

					// Check if a label column already exists in the table
					int labelColumn = -1;
					for (int i = 0; i < dataTable.getColumnCount(); i++) {
						if (dataTable.getColumnTitle(i).contains("l:Labels")) {
							labelColumn = i;
							break;
						}
					}

					// If label column does not exist, add it to the table
					if (labelColumn == -1) {
						dataTable.addColumn("l:Labels");
						labelColumn = dataTable.getColumnCount() - 1;
						dataSignals.add(new DataSignal("Labels", c_colorlist[dataSignals.size() % c_colorlist.length]));
					}

					// Draw the label and get the x-axis position
					float xPosition = graph.setXlabel(xcoord, labelColumn, dataSignals.get(labelColumn).signalColor);

					// Set the correct entry in the label column
					if (xData != -1) {
						// Calculate approximately where in the sequence the label should go
						int startPosition = round((xPosition - graph.getMinX()) / (graph.getMaxX() - graph.getMinX()) * (dataTable.getRowCount() - 1));
						if (startPosition < 0) startPosition = 0;
						else if (startPosition >= dataTable.getRowCount()) startPosition = dataTable.getRowCount() - 1;

						try {
							if (dataTable.getFloat(startPosition, xData) <= xPosition) {
								for (int i = startPosition; i < dataTable.getRowCount() - 2; i++) {
									if (xPosition < dataTable.getFloat(i + 1, xData)) {
										dataTable.setInt(i, "l:Labels", 1);
										break;
									}
								}
							} else {
								for (int i = startPosition; i > 1; i--) {
									if (xPosition > dataTable.getFloat(i - 1, xData)) {
										dataTable.setInt(i, "l:Labels", 1);
										break;
									}
								}
							}
						} catch (Exception e) {
							println("FileGraph()::labels Unable to calculate correct label position");
							dataTable.setInt(startPosition, "l:Labels", 1);
						}
					} else {
						int startPosition = round(xPosition * graph.getXrate());
						if (startPosition < 0) startPosition = 0;
						else if (startPosition >= dataTable.getRowCount()) startPosition = dataTable.getRowCount() - 1;
						dataTable.setInt(startPosition, "l:Labels", 1);
					}

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
				zoomActive = true;

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
		final int iW = round(sW - (20 * uimult));

		// Click on sidebar menu scroll bar
		if ((menuScroll != -1) && sidebarScroll.click(xcoord, ycoord)) {
			startScrolling(false);
		}

		// Root menu level
		if (menuLevel == 0) {

			// Open data
			if (menuXYclick(xcoord, ycoord, sT, uH, iH, 1, iL, iW)){
				saveFilePath = false;
				outputfile = "";
				selectInput("Select *.CSV data file to open", "fileSelected");
			}

			// Save data - currently disabled
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 2, iL, iW)){
				if (currentfile != "" && currentfile != "No File Set" && changesMade){
					saveFilePath = true;
					outputfile = "";
					selectOutput("Select a location and name for the output *.CSV file", "fileSelected");
				}
			}

			// Add label
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 4.5, iL, iW)){
				if (currentfile != "" && currentfile != "No File Set"){
					labelling = true;
					cursor(CROSS);
				}
			}
			
			// Open the filters sub-menu
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 5.5, iL, iW)){
				if (currentfile != "" && currentfile != "No File Set"){
					if (xData == -1 && dataSignals.size() == 1) {
						selectedSignal = 0;
						menuLevel = 2;
					} else if (xData != -1 && dataSignals.size() == 2) {
						if (xData == 0) selectedSignal = 1;
						else selectedSignal = 0;
						menuLevel = 2;
					} else menuLevel = 1;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Change graph type
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 8, iL, iW)){

				// Line
				if (menuXclick(xcoord, iL, int(iW / 3))) {
					graph.setGraphType("linechart");
					redrawContent = redrawUI = true;
				}

				// Dot
				else if (menuXclick(xcoord, iL + int(iW / 3), int(iW / 3))) {
					graph.setGraphType("dotchart");
					redrawContent = redrawUI = true;
				}

				// Bar
				else if (menuXclick(xcoord, iL + int(2 * iW / 3), int(iW / 3))) {
					graph.setGraphType("barchart");
					redrawContent = redrawUI = true;
				}
			}

			// Update X axis scaling
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 9, iL, iW)){

				// Change X axis minimum value
				if (menuXclick(xcoord, iL, (iW / 2) - int(6 * uimult))) {
					ValidateInput userInput = new ValidateInput("Set the X-axis Minimum Value", "Minimum:", str(graph.getMinX()));
					userInput.setErrorMessage("Error\nInvalid x-axis minimum value entered.\nThe number should be smaller the the maximum value.");
					if (userInput.checkFloat(userInput.LT, graph.getMaxX())) {
						graph.setMinX(userInput.getFloat());
						zoomActive = true;
					} 
					redrawContent = redrawUI = true;
				}

				// Change X axis maximum value
				else if (menuXclick(xcoord, iL + (iW / 2) + int(6 * uimult), (iW / 2) - int(6 * uimult))) {
					ValidateInput userInput = new ValidateInput("Set the X-axis Maximum Value", "Maximum:", str(graph.getMaxX()));
					userInput.setErrorMessage("Error\nInvalid x-axis maximum value entered.\nThe number should be larger the the minimum value.");
					if (userInput.checkFloat(userInput.GT, graph.getMinX())) {
						graph.setMaxX(userInput.getFloat());
						zoomActive = true;
					} 
					redrawContent = redrawUI = true;
				}
			}

			// Update Y axis scaling
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 10, iL, iW)){

				// Change Y axis minimum value
				if (menuXclick(xcoord, iL, (iW / 2) - int(6 * uimult))) {
					ValidateInput userInput = new ValidateInput("Set the Y-axis Minimum Value", "Minimum:", str(graph.getMinY()));
					userInput.setErrorMessage("Error\nInvalid y-axis minimum value entered.\nThe number should be smaller the the maximum value.");
					if (userInput.checkFloat(userInput.LT, graph.getMaxY())) {
						graph.setMinY(userInput.getFloat());
						zoomActive = true;
					} 
					redrawContent = redrawUI = true;
				}

				// Change Y axis maximum value
				else if (menuXclick(xcoord, iL + (iW / 2) + int(6 * uimult), (iW / 2) - int(6 * uimult))) {
					ValidateInput userInput = new ValidateInput("Set the Y-axis Maximum Value", "Maximum:", str(graph.getMaxY()));
					userInput.setErrorMessage("Error\nInvalid y-axis maximum value entered.\nThe number should be larger the the minimum value.");
					if (userInput.checkFloat(userInput.GT, graph.getMinY())) {
						graph.setMaxY(userInput.getFloat());
						zoomActive = true;
					} 
					redrawContent = redrawUI = true;
				}
			}

			// Zoom Options
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 11, iL, iW)){

				if (currentfile != "" && currentfile != "No File Set") {
					// New zoom
					if (menuXclick(xcoord, iL, iW / 2)) {
						if (setZoomSize >= 0) {
							setZoomSize = -1;
							cursor(ARROW);
							redrawContent = true;
							redrawUI = true;
						} else {
							setZoomSize = 0;
							cursor(CROSS);
							redrawUI = true;
						}
					}

					// Reset zoom
					else if (menuXclick(xcoord, iL + (iW / 2), iW / 2)) {
						zoomActive = false;
						cursor(ARROW);
						redrawContent = redrawUI = true;
					}
				}
			}

			// Change the input data rate
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 13.5, iL, iW)){
				if (xData == -1) {
					ValidateInput userInput = new ValidateInput("Received Data Update Rate","Frequency (Hz):", str(graph.getXrate()));
					userInput.setErrorMessage("Error\nInvalid frequency entered.\nThe rate can only be a number between 0 - 10,000 Hz");
					if (userInput.checkFloat(userInput.GT, 0, userInput.LTE, 10000)) {
						float newXrate = userInput.getFloat();
						graph.setXrate(newXrate);
						redrawContent = true;
						redrawUI = true;
					}
				}
			}
			
			// Edit data column
			else {
				float tHnow = 14.5;

				// List of Data Columns
				for(int i = 0; i < dataSignals.size(); i++){

					if (i != xData) {
						if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)){

							// Remove the signal
							if (menuXclick(xcoord, iL + iW - int(20 * uimult), int(20 * uimult))) {
								dataSignals.remove(i);
								dataTable.removeColumn(i);
								
								if (dataSignals.size() == 0 || (dataSignals.size() == 1 && xData != -1)) {
									currentfile = "No File Set";
									xData = -1;
									dataSignals.clear();
								}

								changesMade = true;
								redrawContent = true;
								redrawUI = true;
							}

							else if (menuXclick(xcoord, iL + iW - int(40 * uimult), int(20 * uimult))) {
								previousColor = dataSignals.get(i).signalColor;
								hueColor = previousColor;
								newColor = previousColor;
								colorSelector = i;

								menuLevel = 3;
								menuScroll = 0;
								redrawUI = true;
							}

							// Change name of column
							else {
								final String colname = myShowInputDialog("Set the Data Signal Name", "Name:", dataSignals.get(i).signalText);
								if (colname != null && colname != ""){
									dataSignals.get(i).signalText = colname;
									if (dataTable.getColumnTitle(i).contains("l:")) dataTable.setColumnTitle(i, "l:" + colname);
									else dataTable.setColumnTitle(i, colname);
									redrawUI = true;
								}
							}
						}

						tHnow++;
					}
				}
			}

		// Signal selection sub-menu
		} else if (menuLevel == 1) {
			float tHnow = 1;
			if (dataSignals.size() == 0) tHnow++;
			else {
				for (int i = 0; i < dataSignals.size(); i++) {
					if (i != xData && !dataTable.getColumnTitle(i).contains("l:")) {
						if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
							selectedSignal = i;
							menuLevel = 2;
							menuScroll = 0;
							redrawUI = true;
						}
						tHnow++;
					}
				}
			}

			// Cancel button
			tHnow += 0.5;
			if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
			}

		// Filter selection sub-menu
		} else if (menuLevel == 2) {
			float tHnow = 1;
			Filters filterClass = new Filters();
			if (filterClass.filterList.length == 0) tHnow++;
			else {
				for (int i = 0; i < filterClass.filterList.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (!filterClass.filterList[i].contains("h:")) {
							workerActive = true;
							WorkerThread filterThread = new WorkerThread();
							filterThread.setFilterTask(i, selectedSignal);
							menuLevel = 0;
							menuScroll = 0;
							redrawUI = true;
							redrawContent = true;
						}
					}
					tHnow++;
				}
			}

			// Cancel button
			tHnow += 0.5;
			if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
			}
		
		// Select a Colour
		} else if (menuLevel == 3) {

			// Colour hue selection
			if (menuXYclick(xcoord, ycoord, sT, uH, iW, 1, iL, iW)) {
				colorMode(HSB, iW, iW, iW);
				hueColor = color(mouseX - iL, mouseY - (sT + uH), iW);
				newColor = hueColor;
				colorMode(RGB, 255, 255, 255);
				redrawUI = true;

			// Colour brightness selection
			} else if (menuXYclick(xcoord, ycoord, sT + iW, uH, iH, 2.5, iL, iW)) {
				if (mouseX > iL && mouseX < iL + (iW / 2)) {
					newColor = lerpColor(c_white, hueColor, (float) (mouseX - iL) / (iW / 2));
					redrawUI = true;
				} else if (mouseX > iL + (iW / 2) && mouseX < iL + iW) {
					newColor = lerpColor(hueColor, c_black, (float) (mouseX - (iL + iW / 2)) / (iW / 2));
					redrawUI = true;
				}

			// Submit button
			} else if (menuXYclick(xcoord, ycoord, sT + iW, uH, iH, 6.5, iL, iW)) {
				dataSignals.get(colorSelector).signalColor = newColor;
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
				redrawContent = true;

			// Cancel button
			} else if (menuXYclick(xcoord, ycoord, sT + iW, uH, iH, 7.5, iL, iW)) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
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


	/**
	 * Background thread to take care of loading and processing operations
	 * without causing the program to appear to freeze
	 */
	class WorkerThread extends Thread {

		// Tasks: 0=load file, 1=apply filter
		int task = 0;
		int signal = 0;
		int filter = 0;

		/**
		 * Set up the worker to perform filtering
		 */
		public void setFilterTask(int filterType, int signalNumber) {
			workerActive = true;
			task = 1;
			filter = filterType;
			signal = signalNumber;
			super.start();
		}

		/**
		 * Set up the worker to load a file into memory
		 */
		public void loadFile() {
			workerActive = true;
			task = 0;
			super.start();
		}

		/**
		 * Perform the worker task
		 */
		public void run() {
			// Load a file
			if (task == 0) {
				dataSignals.clear();
				dataTable = loadTable(currentfile, "csv, header");
				for (int i = 0; i < dataTable.getColumnCount(); i++) {
					dataTable.setColumnType(i, Table.STRING);
				}
				workerActive = false;
				redrawContent = true;
				redrawUI = true;

			// Run a filter
			} else if (task == 1) {
				Filters filterClass = new Filters();

				double[] signalData = dataTable.getDoubleColumn(signal);
				double[] xAxisData;

				if (xData != -1) xAxisData = dataTable.getDoubleColumn(xData);
				else {
					xAxisData = new double[signalData.length];
					xAxisData[0] = 0;
					for (int i = 1; i < signalData.length; i++) {
						xAxisData[i] = xAxisData[i - 1] + (1.0 / graph.getXrate());
					}
				}

				double[] outputData = filterClass.runFilter(filter, signalData, xAxisData, currentfile);

				if (outputData != null) {
					String signalName = filterClass.filterSlug[filter] + "[" + dataTable.getColumnTitle(signal) + "]";

					dataTable.addColumn(signalName, Table.STRING);
					int newColumnIndex = dataTable.getColumnIndex(signalName);

					for (int i = 0; i < dataTable.getRowCount(); i++) {
						dataTable.setDouble(i, newColumnIndex, outputData[i]);
					}
				}

				workerActive = false;
				redrawContent = true;
				redrawUI = true;
			}
		}
	}


	/**
	 * Check whether it is safe to exit the program
	 *
	 * @return True if the are no tasks active, false otherwise
	 */
	boolean checkSafeExit() {
		return true;
	}


	/**
	 * End any active processes and safely exit the tab
	 */
	void performExit() {
		// Nothing to do here
	}


	/**
	 * Data structure to store info related to each colour tag
	 */
	class DataSignal {
		public String signalText;
		public color signalColor;

		/**
		 * Constructor
		 * 
		 * @param  setText  The keyword text which is search for in the serial data
		 * @param  setColor The colour which all lines containing that text will be set
		 */
		DataSignal(String setText, color setColor) {
			signalText = setText;
			signalColor = setColor;
		}
	}
}
