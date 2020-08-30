/* * * * * * * * * * * * * * * * * * * * * * *
 * GRAPH CLASS
 *
 * @file    Graph.pde
 * @brief   Class to draw graphs in Processing
 * @author  Simon Bluett
 *
 * @class   Graph
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

class Graph {

	// Content coordinates (left, right, top bottom)
	int cL, cR, cT, cB;
	int gL, gR, gT, gB;     // Graph area coordinates
	float gridX, gridY; 		// Grid spacing
	float offsetLeft, offsetBottom;

	float minX, maxX, minY, maxY; // Limits of data
	float[] lastX = {0}, lastY = {-99999999};   // Array containing previous x and y values
	float xStep;

	int xRate;
	int plotType;
	String plotName;
	String xAxisName;
	String yAxisName;

	// Ui variables
	int graphMark;
	int border;
	boolean redrawGraph;
	boolean gridLines;
	boolean squareGrid;
	boolean highlighted;


	/**
	 * Constructor
	 *
	 * @param  left    Graph area left x-coordinate
	 * @param  right   Graph area right x-coordinate
	 * @param  top     Graph area top y-coordinate
	 * @param  bottom  Graph area bottom y-coordinate
	 * @param  minx    Minimum X-axis value on graph
	 * @param  maxx    Maximum X-axis value on graph
	 * @param  miny    Minimum Y-axis value on graph
	 * @param  maxy    Maximum Y-axis value on graph
	 * @param  name    Name/title of the graph
	 */
	Graph(int left, int right, int top, int bottom, float minx, float maxx, float miny, float maxy, String name) {

		plotName = name;

		cL = gL = left;
		cR = gR = right;
		cT = gT = top;
		cB = gB = bottom;

		gridX = 0;
		gridY = 0;
		offsetLeft = cL;
		offsetBottom = cT;

		minX = minx;
		maxX = maxx;
		minY = miny;
		maxY = maxy;

		xRate = 100;
		xStep = 1 / float(xRate);

		graphMark = round(8 * uimult);
		border = round(30 * uimult);

		plotType = 0;
		redrawGraph = gridLines = true;
		squareGrid = false;
		highlighted = false;

		xAxisName = "";
		yAxisName = "";
	}
	

	/**
	 * Change graph content area dimensions
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
		graphMark = round(8 * uimult);
		border = round(30 * uimult);

		for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
		redrawGraph = true;
	}


	/**
	 * Get the data rate relating to Y-axis spacing
	 * of the live serial data graph
	 *
	 * @return Data rate in samples per second
	 */
	int getXrate() {
		return xRate;
	}


	/**
	 * Set the data rate relating to Y-axis spacing
	 * of the live serial data graph
	 *
	 * @param  newrate Data rate in samples per second
	 */
	void setXrate(int newrate) {
		if (newrate > 0 && validFloat(newrate)) {
			xRate = newrate;
			xStep = 1 / float(xRate);

		} else println("Graph::setXrate() - Invalid number: " + newrate);
	}


	/**
	 * Set the X- and Y- graph axes to the same scale
	 *
	 * @param  value True/false to enable equal graph axes
	 */
	void setSquareGrid(boolean value) {
		squareGrid = value;
	}


	/**
	 * Set the name label for the X-axis
	 *
	 * @param  newName The text to be displayed beside the axis
	 */
	void setXaxisName(String newName) {
		xAxisName = newName;
	}


	/**
	 * Set the name label for the Y-axis
	 *
	 * @param  newName The text to be displayed beside the axis
	 */
	void setYaxisName(String newName) {
		yAxisName = newName;
	}


	/**
	 * Set the minimum X-axis value
	 *
	 * @param  newValue The new x-axis minimum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean setMinX(float newValue) {
		if (validFloat(newValue) && newValue < maxX) {
			minX = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the maximum X-axis value
	 *
	 * @param  newValue The new x-axis maximum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean setMaxX(float newValue) {
		if (validFloat(newValue) && newValue > minX) {
			maxX = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the minimum Y-axis value
	 *
	 * @param  newValue The new y-axis minimum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean setMinY(float newValue) {
		if (validFloat(newValue) && newValue < maxY) {
			minY = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the maximum Y-axis value
	 *
	 * @param  newValue The new y-axis maximum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean setMaxY(float newValue) {
		if (validFloat(newValue) && newValue > minY) {
			maxY = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Functions to get the range of the X- or Y- axes
	 *
	 * @return The new minimum or maximum range value
	 */	
	float getMinX() { return minX; }
	float getMaxX() { return maxX; }
	float getMinY() { return minY; }
	float getMaxY() { return maxY; }


	/**
	 * Reset graph 
	 */
	void resetGraph(){
		for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
		for(int i = 0; i < lastY.length; i++) lastY[i] = -99999999;
	}


	/**
	 * Reset and remove all saved data
	 */
	void reset() {
		while(lastX.length > 0) lastX = shorten(lastX);
		while(lastY.length > 0) lastY = shorten(lastY);
	}


	/**
	 * Test whether a float number is valid
	 *
	 * @param  newNumber The number to test
	 * @return True if valid, false is number is NaN or Infinity
	 */
	boolean validFloat(float newNumber) {
		if ((newNumber != newNumber) || newNumber == Float.POSITIVE_INFINITY || newNumber == Float.NEGATIVE_INFINITY) {
			return false;
		}
		return true;
	}


	/**
	 * Draw a X-axis label onto the graph
	 *
	 * @param  xCoord The X-coordinate on the screen
	 * @param  yCoord The Y-coordinate on the screen
	 * @return The X-axis value of the label position on the graph
	 */
	int setXlabel(float xCoord, float yCoord) {
		if (xCoord < gL || xCoord > gR || yCoord < gT || yCoord > gB) return -1;
		stroke(c_sidebar);
		strokeWeight(1 * uimult);
		line(xCoord, gT, xCoord, gB);
		return round(map(xCoord, gL, gR, minX, maxX) / xRate);
	}


	/**
	 * Change the graph display type
	 *
	 * @param  type The name of the graph type to display
	 */
	void setGraphType(String type) {
		if (type == "linechart") plotType = 0;
		else if (type == "dotchart") plotType = 1;
		else if (type == "barchart") plotType = 2;
	}


	/**
	 * Get the type of graph which is currently being displayed
	 *
	 * @return The name of the graph type being displayed
	 */
	String getGraphType() {
		switch (plotType) {
			case 0: return "linechart";
			case 1: return "dotchart";
			case 2: return "barchart";
			default: return "invalid";
		}
	}


	/**
	 * Show that current graph is active
	 *
	 * This function changes the colour of the graph name/title text
	 * to show that it has been selected.
	 *
	 * @param  state
	 * ---@param  update--- removed
	 */
	void setHighlight(boolean state) {
		highlighted = state;
	}


	/**
	 * Check if a window coordinate is in the graph area
	 *
	 * @param  xCoord The window X-coordinate
	 * @param  yCoord The window Y-coordinate
	 * @return True if coordinate is within the content area
	 */
	boolean onGraph(int xCoord, int yCoord) {
		if (xCoord >= cL && xCoord <= cR && yCoord >= cT && yCoord <= cB) return true;
		else return false;
	}


	/**
	 * Convert window coordinate into X-axis graph value
	 *
	 * @param  xCoord The window X-coordinate
	 * @return The graph X-axis value at this X-coordinate
	 */
	float xGraphPos(int xCoord) {
		if (xCoord < gL) xCoord = gL;
		else if (xCoord > gR) xCoord = gR;
		return map(xCoord, gL, gR, 0, 1);
	}


	/**
	 * Convert window coordinate into Y-axis graph value
	 *
	 * @param  yCoord The window Y-coordinate
	 * @return The graph Y-axis value at this Y-coordinate
	 */
	float yGraphPos(int yCoord) {
		if (yCoord < gT) yCoord = gT;
		else if (yCoord > gB) yCoord = gB;
		return map(yCoord, gT, gB, 0, 1);
	}


	/**
	 * Plot a new data point using default y-increment
	 *
	 * @note   This is an overload function
	 * @see    void plotData(float, float, int)
	 */
	void plotData(float dataY, int type) {
	
		// Ensure that the element actually exists in data arrays
		while(lastY.length < type + 1) lastY = append(lastY, -99999999);
		while(lastX.length < type + 1) lastX = append(lastX, 0);

		plotData(dataY, lastX[type] + xStep, type);
	}


	/**
	 * Plot a new data point on the graph
	 *
	 * @param  dataY The Y-axis value of the data
	 * @param  dataX The X-axis value of the data
	 * @param  type  The signal ID/number
	 */
	void plotData(float dataY, float dataX, int type) {

		if (validFloat(dataY) && validFloat(dataX)) {
			// Deal with labels
			/*
			if(type == -1) {
				stroke(c_sidebar);
				strokeWeight(1 * uimult);
				line(map(lastX[0], minX, maxX, gL, gR), gT, map(lastX[0], minX, maxX, gL, gR), gB);
				return;
			}*/

			int x1, y1, x2 = gL, y2;

			// Ensure that the element actually exists in data arrays
			while(lastY.length < type + 1) lastY = append(lastY, -99999999);
			while(lastX.length < type + 1) lastX = append(lastX, 0);
			
			// Redraw grid, if required
			if (redrawGraph) drawGrid();

			// Bound the Y-axis data
			if (dataY > maxY) dataY = maxY;
			if (dataY < minY) dataY = minY;

			// Bound the X-axis
			if (dataX > maxX) dataX = maxX;
			if (dataX < minX) dataX = minX;

			// Get relevant color from list
			int colorIndex = type - (c_colorlist.length * floor(type / c_colorlist.length));
			fill(c_colorlist[colorIndex]);
			stroke(c_colorlist[colorIndex]);
			strokeWeight(1 * uimult);

			switch(plotType){
				// Dot chart
				case 1:
					// Determine x and y coordinates
					x2 = round(map(dataX, minX, maxX, gL, gR));
					y2 = round(map(dataY, minY, maxY, gB, gT));
					
					ellipse(x2, y2, 1*uimult, 1*uimult);
					break;

				// Bar chart
				case 2:
					if (lastY[type] != -99999999 && lastY[type] != 99999999) {
						noStroke();
						// Determine x and y coordinates
						x1 = round(map(lastX[type], minX, maxX, gL, gR));
						x2 = round(map(dataX, minX, maxX, gL, gR));
						y1 = round(map(dataY, minY, maxY, gB, gT));
						if (minY <= 0) y2 = round(map(0, minY, maxY, gB, gT));
						else y2 = round(map(minY, minY, maxY, gB, gT));

						// Figure out how wide the bar should be
						int oneSegment = ceil((x2 - x1) / float(lastX.length));
						x1 += oneSegment * type;
						if (lastX.length > 1) x2 = x1 + oneSegment;
						else x2 = x1 + ceil(oneSegment / 1.5);
						
						rectMode(CORNERS);
						rect(x1, y1, x2, y2);
					}
					break;

				// linechart
				default: 
					// Only draw line if last value is set
					if (lastY[type] != -99999999) {
						// Determine x and y coordinates
						x1 = round(map(lastX[type], minX, maxX, gL, gR));
						x2 = round(map(dataX, minX, maxX, gL, gR));
						y1 = round(map(lastY[type], minY, maxY, gB, gT));
						y2 = round(map(dataY, minY, maxY, gB, gT));
						line(x1, y1, x2, y2);
					}
					break;
			}
			
			lastY[type] = dataY;
			lastX[type] = dataX;
		}
	}


	/**
	 * Plot a rectangle on the graph
	 *
	 * @param  dataY1 Y-axis value of top-left point
	 * @param  dataY2 Y-axis value of bottom-right point
	 * @param  dataX1 X-axis value of top-left point
	 * @param  dataX2 X-axis value of bottom-right point
	 * @param  type   The signal ID/number (this determines the colour)
	 */
	void plotRectangle(float dataY1, float dataY2, float dataX1, float dataX2, int type) {

		// Only plot data if it is within bounds
		if (dataY1 >= minY && dataY1 <= maxY && dataY2 >= minY && dataY2 <= maxY) {
			if (dataX1 >= minX && dataX1 <= maxX && dataX2 >= minX && dataX2 <= maxX) {

				// Get relevant color from list
				fill(c_colorlist[type - (c_colorlist.length * floor(type / c_colorlist.length))]);
				stroke(c_colorlist[type - (c_colorlist.length * floor(type / c_colorlist.length))]);
				strokeWeight(1 * uimult);

				// Determine x and y coordinates
				int x1 = round(map(dataX1, minX, maxX, gL, gR));
				int x2 = round(map(dataX2, minX, maxX, gL, gR));
				int y1 = round(map(dataY1, minY, maxY, gB, gT));
				int y2 = round(map(dataY2, minY, maxY, gB, gT));
				
				rectMode(CORNERS);
				rect(x1, y1, x2, y2);
			}
		}
	}


	/**
	 * Clear the graph area and redraw the grid lines
	 */
	void clearGraph () {
		// Clear the content area
		rectMode(CORNER);
		noStroke();
		fill(c_background);
		rect(gL, gT - (uimult * 1), gR - gL + (uimult * 1), gB - gT + (uimult * 2));

		// Setup drawing parameters
		strokeWeight(1 * uimult);
		stroke(c_darkgrey);

		// Draw X-axis grid lines
		if (gridLines && gridX != 0) {
			for (float i = offsetLeft; i < gR; i += gridX) {
				line(i, gT, i, gB);
			}
		}

		// Draw y-axis grid lines
		if (gridLines && gridY != 0) {
			for (float i = offsetBottom; i > gT; i -= gridY) {
				line(gL, i, gR, i);
			}
		}

		float yZero = 0;
		float xZero = 0;
		if (minY > 0) yZero = minY;
		else if (maxY < 0) yZero = maxY;
		if (minX > 0) xZero = minX;
		else if (maxX < 0) xZero = maxX;

		// Draw the graph axis lines
		stroke(c_lightgrey);
		line(map(xZero, minX, maxX, gL, gR), gT, map(xZero, minX, maxX, gL, gR), gB);
		line(gL, map(yZero, minY, maxY, gB, gT), gR, map(yZero, minY, maxY, gB, gT));

		// Clear all previous data positions
		resetGraph();
	}


	/**
	 * Round a number to the closest suitable axis division size
	 *
	 * The axis divisions should end in the numbers 1, 2, 2.5, or 5
	 * to ensure that the axes are easily interpretable
	 *
	 * @param  num The approximate division size we are aiming for
	 * @return The closest idealised division size
	 */
	double roundToIdeal(float num) {
		if(num == 0) {
			return 0;
		}

		int n = 2;

		final double d = Math.ceil(Math.log10(num < 0 ? -num: num));
		final int power = n - (int) d;

		final double magnitude = Math.pow(10, power);
		long shifted = Math.round(num*magnitude);

		// Apply rounding to nearest useful divisor
		if (abs(shifted) > 75) shifted = (num < 0)? -100:100;
		else if (abs(shifted) > 30) shifted = (num < 0)? -50:50;
		else if (abs(shifted) > 23) shifted = (num < 0)? -25:25;
		else if (abs(shifted) > 15) shifted = (num < 0)? -20:20;
		else shifted = (num < 0)? -10:10; 

		return shifted/magnitude;
	}


	/**
	 * Calculate the precision with which the graph axes should be drawn
	 *
	 * @param  maxValue The maximum axis value
	 * @param  minValue The minimum axis value
	 * @param  segments The step size with which the graph will be divided
	 * @return The number of significant digits to display
	 */
	int calculateRequiredPrecision(double maxValue, double minValue, double segments) {
		if (segments == 0 || maxValue == minValue) return 1;

		double largeValue = (maxValue < 0) ? -maxValue : maxValue;
		if (maxValue == 0 || -minValue > largeValue) largeValue = (minValue < 0) ? -minValue : minValue;

		final double d1 = Math.ceil(Math.log10((segments < 0) ? -segments : segments));
		final double d2 = Math.ceil(Math.log10(largeValue));
		final double removeMSN = segments % Math.pow( 10, Math.floor( d1 ) ) ;

		int value = abs((int) d2 - (int) d1);
		if (removeMSN > 0) value++;

		//println(maxValue + " - " + minValue + "(" + d2 + ") - " + segments + "(" + d1 + ") - " + value + " " + removeMSN);

		return  value;
	}


	/**
	 * Draw the grid and axes of the graph
	 */
	void drawGrid() {

		redrawGraph = false;

		// Clear the content area
		rectMode(CORNER);
		noStroke();
		fill(c_background);
		rect(cL, cT, cR - cL, cB - cT);

		// Add border and graph title
		strokeWeight(1 * uimult);
		stroke(c_darkgrey);
		if (cT > round((tabHeight + 1) * uimult)) line(cL, cT, cR, cT);
		if (cL > 1) line(cL, cT, cL, cB);
		line(cL, cB, cR, cB);
		line(cR, cT, cR, cB);		

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_lightgrey);
		if (highlighted) fill(c_red);
		text(plotName, cL + int(5 * uimult), cT + int(5 * uimult));

		// X and Y axis zero
		float yZero = 0;
		float xZero = 0;
		if (minY > 0) yZero = minY;
		else if (maxY < 0) yZero = maxY;
		if (minX > 0) xZero = minX;
		else if (maxX < 0) xZero = maxX;

		// Text width and height
		textFont(mono_font);
		int padding = int(5 * uimult);
		int textHeight = int(textAscent() + textDescent() + padding);
		float charWidth = textWidth("0");

		/* -----------------------------------
		 *     Define graph top and bottom
		 * -----------------------------------*/
		gT = cT + border + textHeight / 3;
		gB = cB - border - textHeight - graphMark;

		/* -----------------------------------
		 *     Calculate y-axis parameters 
		 * -----------------------------------*/
		// Figure out how many segments to divide the data into
		double y_segment = Math.abs(roundToIdeal((maxY - minY) * (textHeight * 2) / (gB - gT)));

		// Figure out a base reference for all the segments
		double y_basePosition = yZero;
		if (yZero > 0) y_basePosition = Math.ceil(minY / y_segment) * y_segment;
		else if (yZero < 0) y_basePosition = -Math.ceil(-maxY / y_segment) * y_segment;

		// Figure out how many decimal places need to be shown on the labels
		int y_precision = calculateRequiredPrecision(maxY, minY, y_segment);

		// Figure out where each of the labels should be drawn
		double y_bottomPosition = y_basePosition - (Math.floor((y_basePosition - minY) / y_segment) * y_segment);
		offsetBottom = map((float) y_bottomPosition, minY, maxY, gB, gT);
		gridY = map((float) y_bottomPosition, minY, maxY, gB, gT) - map((float) (y_bottomPosition + y_segment), minY, maxY, gB, gT);;

		// Figure out the width of the largest label so we know how much room to make
		int yTextWidth = 0;
		for (double i = y_bottomPosition; i <= maxY; i += y_segment) {
			int labelWidth = int(String.format("%." + y_precision + "g", i).length() * charWidth);
			if (labelWidth > yTextWidth) yTextWidth = labelWidth;
		}

		/* -----------------------------------
		 *     Define graph left and right
		 * -----------------------------------*/
		gL = cL + border + yTextWidth + graphMark + padding;
		gR = cR - border;

		/* -----------------------------------
		 *     Calculate x-axis parameters 
		 * -----------------------------------*/
		// Figure out an approximate number of segments to divide the data
		double x_segment = Math.abs(roundToIdeal((maxX - minX) * (10 * 2) / (gR - gL)));

		// Figure out approximately the precision required
		int x_precision = calculateRequiredPrecision(maxX, minX, x_segment);

		// 
		int xTextWidth = int(max(String.format("%." + x_precision + "g", (maxX - x_segment)).length(), 
			String.format("%." + x_precision + "g", minX).length()) * charWidth);

		//println(x_segment + " " + xTextWidth);

		x_segment = Math.abs(roundToIdeal((maxX - minX) * (xTextWidth * 3) / (gR - gL)));
		//println(x_segment);

		double x_basePosition = xZero;
		if (xZero > 0) x_basePosition = Math.ceil(minX / x_segment) * x_segment;
		else if (xZero < 0) x_basePosition = -Math.ceil(-maxX / x_segment) * x_segment;
		x_precision = calculateRequiredPrecision(maxX, minX, x_segment);
		double x_leftPosition = x_basePosition - (Math.floor((x_basePosition - minX) / x_segment) * x_segment);
		offsetLeft = map((float) x_leftPosition, minX, maxX, gL, gR);
		gridX = map((float) (x_leftPosition + x_segment), minX, maxX, gL, gR) - map((float) x_leftPosition, minX, maxX, gL, gR);

		fill(c_lightgrey);

		//if (yAxisName != "") {
		//	textAlign(CENTER, CENTER);
		//	pushMatrix();
		//	translate(border / 2, (gB + gT) / 2);
		//	rotate(-HALF_PI);
		//	text("Some text here",0,0);
		//	popMatrix();
		//}

		// ---------- Y-AXIS ----------
		textAlign(RIGHT, CENTER);

		for (double i = y_bottomPosition; i <= maxY; i += y_segment) {
			float currentYpixel = map((float) i, minY, maxY, gB, gT);

			if (gridLines) {
				stroke(c_darkgrey);
				line(gL, currentYpixel, gR, currentYpixel);
			}

			String label = String.format("%." + (y_precision +1) + "g", i);
			if (label.contains(".")) label = label.replaceAll("[0]+$", "").replaceAll("[.]+$", "");

			stroke(c_lightgrey);
			text(label, gL - graphMark - padding, currentYpixel - (1 * uimult));
			line(gL - graphMark, currentYpixel, gL - round(1 * uimult), currentYpixel);

			// Minor graph lines
			if (i > y_bottomPosition) {
				float minorYpixel = map((float) (i - (y_segment / 2.0)), minY, maxY, gB, gT);
				line(gL - (graphMark / 2.0), minorYpixel, gL - round(1 * uimult), minorYpixel);
			}
		}


		// ---------- X-AXIS ----------
		textAlign(CENTER, TOP);
		if (xAxisName != "") text(xAxisName, (gL + gR) / 2, cB - border + padding);

		// Move right first
		for (double i = x_leftPosition; i <= maxX; i += x_segment) {
			float currentXpixel = map((float) i, minX, maxX, gL, gR);

			if (gridLines) {
				stroke(c_darkgrey);
				line(currentXpixel, gT, currentXpixel, gB);
			}

			String label = String.format("%." + x_precision + "g", i);
			if (label.contains(".")) label = label.replaceAll("[0]+$", "").replaceAll("[.]+$", "");

			stroke(c_lightgrey);
			if (i != maxX) text(label, currentXpixel, gB + graphMark + padding);
			line(currentXpixel, gB, currentXpixel, gB + graphMark);

			// Minor graph lines
			if (i > x_leftPosition) {
				float minorXpixel = map((float) (i - (x_segment / 2.0)), minX, maxX, gL, gR);
				line(minorXpixel, gB, minorXpixel, gB + (graphMark / 2.0));
			}
		}

		// The outer grid axes
		stroke(c_lightgrey);
		line(map(xZero, minX, maxX, gL, gR), gT, map(xZero, minX, maxX, gL, gR), gB);
		line(gL, map(yZero, minY, maxY, gB, gT), gR, map(yZero, minY, maxY, gB, gT));
		textFont(base_font);
	}
}
