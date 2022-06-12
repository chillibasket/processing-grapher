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

class Settings implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	int menuScroll;
	int menuHeight;
	int menuLevel;
	ScrollBar sidebarScroll = new ScrollBar(ScrollBar.VERTICAL, ScrollBar.NORMAL);

	String name;
	String outputfile;

	boolean unsavedChanges = false;
	boolean tabIsVisible = false;
	final int[] baudRateList = {300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 74880, 115200, 230400, 250000, 500000, 1000000, 2000000};
	final String[] lineEndingNames = {"New Line (Default)", "Carriage Return"};
	final char[] lineEndingList = {'\n', '\r'};
	final String[] parityBitsNames = {"None (Default)", "Even", "Odd", "Mark", "Space"};
	final char[] parityBitsList = {'N', 'E', 'O', 'M', 'S'};
	final String[] dataBitsNames = {"5", "6", "7", "8 (Default)"};
	final int[] dataBitsList = {5, 6, 7, 8};
	final String[] stopBitsNames = {"1.0 (Default)", "1.5", "2.0"};
	final float[] stopBitsList = {1.0, 1.5, 2.0};

	/**
	 * Constructor
	 *
	 * @param  setname Name of the tab
	 * @param  left    Tab area left x-coordinate
	 * @param  right   Tab area right x-coordinate
	 * @param  top     Tab area top y-coordinate
	 * @param  bottom  Tab area bottom y-coordinate
	 */
	Settings (String setname, int left, int right, int top, int bottom) {
		name = setname;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		outputfile = "No File Set";

		menuScroll = 0;
		menuHeight = cB - cT - 1; 
		menuLevel = 0;

		//loadSettings();
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
		loadSettings();
	}


	/**
	 * Draw new tab data
	 */
	void drawNewData () {
		// Not in use
		menuLevel = 0;
		menuScroll = 0;
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
	}


	/**
	 * Change CSV data file location
	 *
	 * @param  newoutput Absolute path to the new file location
	 */
	void setOutput (String newoutput) {
		// Not in use
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
	 * Load user prefences from the settings file
	 */
	void loadSettings() {

		// Check if file exists
		if (dataFile("user-preferences.xml").isFile()) {
			XML xmlFile = loadXML("user-preferences.xml");

			// Interface scale
			XML entry = xmlFile.getChild("interface-scale");
			try {
				int value = entry.getInt("percentage", 100);
				if (value == value && value <= 200 && value >= 50) {
					uimult = value / 100.0;
					uiResize();
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <interface-scale>:\n" + e);
			}

			// Colour scheme
			entry = xmlFile.getChild("color-scheme");
			try {
				int value = entry.getInt("id", 2);
				if (value == value && value <= 2 && value >= 0) {
					colorScheme = value;
					loadColorScheme(colorScheme);
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <color-scheme>:\n" + e);
			}

			// Toggle FPS indicator on/off
			entry = xmlFile.getChild("fps-indicator");
			try {
				int value = entry.getInt("visible", 0);
				if (value == value && value <= 1 && value >= 0) {
					if (value == 1) drawFPS = true;
					else drawFPS = false;
					redrawUI = true;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <fps-indicator>:\n" + e);
			}

			// Toggle usage instructions on/off
			entry = xmlFile.getChild("usage-instructions");
			try {
				int value = entry.getInt("visible", 1);
				if (value == value && value <= 1 && value >= 0) {
					if (value == 1) showInstructions = true;
					else showInstructions = false;
					redrawUI = true;
					redrawContent = true;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <usage-instructions>\n" + e);
			}

			// Get serial port settings
			entry = xmlFile.getChild("serial-port");
			try {
				int value = entry.getInt("baud-rate", 9600);
				for (int i = 0; i < baudRateList.length; i++) {
					if (baudRateList[i] == value) baudRate = value;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <serial-port: baud-rate>\n" + e);
			}

			try {
				String value = entry.getString("line-ending", str('\n'));
				char charValue = value.charAt(0);
				for (int i = 0; i < lineEndingList.length; i++) {
					if (lineEndingList[i] == charValue) lineEnding = charValue;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <serial-port: line-ending>\n" + e);
			}

			try {
				String value = entry.getString("parity", str('N'));
				char charValue = value.charAt(0);
				for (int i = 0; i < parityBitsList.length; i++) {
					if (parityBitsList[i] == charValue) serialParity = charValue;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <serial-port: parity>\n" + e);
			}

			try {
				int value = entry.getInt("databits", 8);
				for (int i = 0; i < dataBitsList.length; i++) {
					if (dataBitsList[i] == value) serialDatabits = value;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <serial-port: databits>\n" + e);
			}

			try {
				float value = entry.getFloat("stopbits", 1.0);
				for (int i = 0; i < stopBitsList.length; i++) {
					if (stopBitsList[i] == value) serialStopbits = value;
				}
			} catch (Exception e) {
				println("Unable to parse user settings - <serial-port: stopbits>\n" + e);
			}
		}
	}


	/**
	 * Save user preferences to the settings file
	 */
	void saveSettings() {
		XML xmlFile = new XML("user-preferences");
		xmlFile.addChild("interface-scale");
		xmlFile.getChild("interface-scale").setInt("percentage", round(uimult * 100));
		xmlFile.addChild("color-scheme");
		xmlFile.getChild("color-scheme").setInt("id", colorScheme);
		xmlFile.addChild("fps-indicator");
		xmlFile.getChild("fps-indicator").setInt("visible", int(drawFPS));
		xmlFile.addChild("usage-instructions");
		xmlFile.getChild("usage-instructions").setInt("visible", int(showInstructions));
		xmlFile.addChild("serial-port");
		xmlFile.getChild("serial-port").setInt("baud-rate", baudRate);
		xmlFile.getChild("serial-port").setString("line-ending", str(lineEnding));
		xmlFile.getChild("serial-port").setString("parity", str(serialParity));
		xmlFile.getChild("serial-port").setInt("databits", serialDatabits);
		xmlFile.getChild("serial-port").setFloat("stopbits", serialStopbits);

		if (saveXML(xmlFile, "data/user-preferences.xml")) {
			alertMessage("Success\nUser preferences saved");
			unsavedChanges = false;
		} else {
			alertMessage("Error\nUnable to save user preferences");
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
		if (menuLevel == 0) menuHeight = round(23 * uH);
		else if (menuLevel == 1) menuHeight = round((3 + baudRateList.length) * uH);
		else if (menuLevel == 2) menuHeight = round((3 + lineEndingList.length) * uH);
		else if (menuLevel == 3) menuHeight = round((3 + parityBitsList.length) * uH);
		else if (menuLevel == 4) menuHeight = round((3 + dataBitsList.length) * uH);
		else if (menuLevel == 5) menuHeight = round((3 + stopBitsList.length) * uH);

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

		if (menuLevel == 0) {
			// UI Scaling Options
			drawHeading("Interface Size", iL, sT + (uH * 0), iW, tH);
			drawButton("-", c_sidebar_button, iL, sT + (uH * 1), iW / 4, iH, tH);
			drawButton("+", c_sidebar_button, iL + (iW * 3 / 4), sT + (uH * 1), iW / 4, iH, tH);
			drawDatabox(round(uimult*100) + "%", c_idletab_text, iL + (iW / 4), sT + (uH * 1), iW / 2, iH, tH);

			// Change the colour scheme
			drawHeading("Colour Scheme", iL, sT + (uH * 2.5), iW, tH);
			drawButton("Light - Celeste", (colorScheme == 0)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 3.5), iW, iH, tH);
			drawButton("Dark - Gravity", (colorScheme == 1)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
			drawButton("Dark - Monokai", (colorScheme == 2)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);

			// Turn FPS counter on/off
			drawHeading("FPS Indicator", iL, sT + (uH * 7), iW, tH);
			drawButton("Show", (drawFPS)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 8), iW/2, iH, tH);
			drawButton("Hide", (!drawFPS)? c_sidebar_accent:c_sidebar_button, iL + (iW/2), sT + (uH * 8), iW/2, iH, tH);
			drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 8) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

			// Turn useful instructions on/off
			drawHeading("Usage Instructions", iL, sT + (uH * 9.5), iW, tH);
			drawButton("Show", (showInstructions)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 10.5), iW/2, iH, tH);
			drawButton("Hide", (!showInstructions)? c_sidebar_accent:c_sidebar_button, iL + (iW/2), sT + (uH * 10.5), iW/2, iH, tH);
			drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 10.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

			drawHeading("Serial Port", iL, sT + (uH * 12), iW, tH);
			color c_serial_items = c_sidebar_text;
			if (serialConnected) c_serial_items = c_sidebar_button;
			drawDatabox("Baud: " + baudRate, c_serial_items, iL, sT + (uH * 13), iW, iH, tH);
			drawDatabox("Line Ending: " + ((lineEnding == '\r')? "CR":"NL"), c_serial_items, iL, sT + (uH * 14), iW, iH, tH);
			drawDatabox("Parity: " + serialParity, c_serial_items, iL, sT + (uH * 15), iW, iH, tH);
			drawDatabox("Data Bits: " + serialDatabits, c_serial_items, iL, sT + (uH * 16), iW, iH, tH);
			drawDatabox("Stop Bits: " + serialStopbits, c_serial_items, iL, sT + (uH * 17), iW, iH, tH);

			// Save preferences
			drawHeading("User Preferences", iL, sT + (uH * 18.5), iW, tH);
			if (unsavedChanges) drawButton("Save Settings", c_sidebar_button, iL, sT + (uH * 19.5), iW, iH, tH);
			else drawDatabox("Save Settings", c_sidebar_button, iL, sT + (uH * 19.5), iW, iH, tH);

			if (checkDefault()) {
				drawButton("Reset to Default", c_sidebar_button, iL, sT + (uH * 20.5), iW, iH, tH);
			} else {
				drawDatabox("Reset to Default", c_sidebar_button, iL, sT + (uH * 20.5), iW, iH, tH);
			}

			drawButton("Exit Settings", c_sidebar_button, iL, sT + (uH * 21.5), iW, iH, tH);

		// Baud rate selection
		} else if (menuLevel == 1) {
			drawHeading("Select Baud Rate", iL, sT + (uH * 0), iW, tH);
			float tHnow = 1;
			for (int i = 0; i < baudRateList.length; i++) {
				drawButton(str(baudRateList[i]), (baudRate == baudRateList[i])?c_sidebar_accent:c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
		
		// Line ending list
		} else if (menuLevel == 2) {
			drawHeading("Select Line Ending", iL, sT + (uH * 0), iW, tH);
			float tHnow = 1;
			for (int i = 0; i < lineEndingNames.length; i++) {
				drawButton(lineEndingNames[i], (lineEnding == lineEndingList[i])?c_sidebar_accent:c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
		
		// Parity List
		} else if (menuLevel == 3) {
			drawHeading("Select Parity", iL, sT + (uH * 0), iW, tH);
			float tHnow = 1;
			for (int i = 0; i < parityBitsNames.length; i++) {
				drawButton(parityBitsNames[i], (serialParity == parityBitsList[i])?c_sidebar_accent:c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
		
		// Data bits List
		} else if (menuLevel == 4) {
			drawHeading("Select Data Bits", iL, sT + (uH * 0), iW, tH);
			float tHnow = 1;
			for (int i = 0; i < dataBitsNames.length; i++) {
				drawButton(dataBitsNames[i], (serialDatabits == dataBitsList[i])?c_sidebar_accent:c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
		
		// Stop bits list
		} else if (menuLevel == 5) {
			drawHeading("Select Stop Bits", iL, sT + (uH * 0), iW, tH);
			float tHnow = 1;
			for (int i = 0; i < stopBitsNames.length; i++) {
				drawButton(stopBitsNames[i], (serialStopbits == stopBitsList[i])?c_sidebar_accent:c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
		}
	}


	/**
	 * Check whether settings are different than the default
	 *
	 * @return true if different, false if not
	 */
	boolean checkDefault() {
		if (uimult != 1) return true;
		if (!showInstructions) return true;
		if (drawFPS) return true;
		if (colorScheme != 2) return true;
		if (!serialConnected) {
			if (baudRate != 9600) return true;
			if (lineEnding != '\n') return true;
			if (serialParity != 'N') return true;
			if (serialDatabits != 8) return true;
			if (serialStopbits != 1.0) return true;
		}
		return false;
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
			} else {
				settingsMenuActive = false;
				menuLevel = 0;
				menuScroll = 0;
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
		// Not in use
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

		int sW = width - cR;
		int sH = height - sT;

		int uH = round(sideItemHeight * uimult);
		int tH = round((sideItemHeight - 8) * uimult);
		int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		int iW = round(sW - (20 * uimult));

		// Click on sidebar menu scroll bar
		if ((menuScroll != -1) && sidebarScroll.click(xcoord, ycoord)) {
			startScrolling(false);
		}

		// Main Menu
		if (menuLevel == 0) {
			// UI scaling
			if (menuXYclick(xcoord, ycoord, sT, uH, iH, 1, iL, iW)){
				// Decrease
				if (menuXclick(xcoord, iL, iW / 4)) {
					if (uimult > 0.5) {
						uiResize(-0.1);
						unsavedChanges = true;
					}
				}

				// Increase
				else if (menuXclick(xcoord, iL + (iW * 3 / 4), iW / 4)) {
					if (uimult < 2.0) {
						uiResize(0.1);
						unsavedChanges = true;
					}
				}
			}

			// Color Scheme 0 - Light Celeste
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 3.5, iL, iW)) {
				if (colorScheme != 0) {
					unsavedChanges = true;
					colorScheme = 0;
					loadColorScheme(colorScheme);
				}
			}

			// Color Scheme 1 - Dark Gravity
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 4.5, iL, iW)) {
				if (colorScheme != 1) {
					unsavedChanges = true;
					colorScheme = 1;
					loadColorScheme(colorScheme);
				}
			}

			// Color Scheme 2 - Dark Monokai
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 5.5, iL, iW)) {
				if (colorScheme != 2) {
					unsavedChanges = true;
					colorScheme = 2;
					loadColorScheme(colorScheme);
				}
			}

			// Toggle FPS indicator
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 8, iL, iW)) {
				// Show
				if (menuXclick(xcoord, iL, iW / 2)) {
					if (!drawFPS) {
						drawFPS = true;
						unsavedChanges = true;
						redrawUI = true;
					}
				}

				// Hide
				else if (menuXclick(xcoord, iL + (iW / 2), iW / 2)) {
					if (drawFPS) {
						drawFPS = false;
						unsavedChanges = true;
						redrawUI = true;
					}
				}
			}

			// Toggle usage instructions
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 10.5, iL, iW)){
				// Show
				if (menuXclick(xcoord, iL, iW / 2)) {
					if (!showInstructions) {
						showInstructions = true;
						unsavedChanges = true;
						redrawUI = true;
						redrawContent = true;
					}
				}

				// Hide
				else if (menuXclick(xcoord, iL + (iW / 2), iW / 2)) {
					if (showInstructions) {
						showInstructions = false;
						unsavedChanges = true;
						redrawUI = true;
						redrawContent = true;
					}
				}
			}

			// Baud rate selection
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 13, iL, iW)) {
				if (!serialConnected) {
					menuLevel = 1;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Line ending selection
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 14, iL, iW)) {
				if (!serialConnected) {
					menuLevel = 2;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Parity selection
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 15, iL, iW)) {
				if (!serialConnected) {
					menuLevel = 3;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Data bits selection
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 16, iL, iW)) {
				if (!serialConnected) {
					menuLevel = 4;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Stop bits selection
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 17, iL, iW)) {
				if (!serialConnected) {
					menuLevel = 5;
					menuScroll = 0;
					redrawUI = true;
				}
			}

			// Remember preferences
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 19.5, iL, iW)){
				if (unsavedChanges) saveSettings();
			}

			// Reset preferences to default
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 20.5, iL, iW)){
				if (checkDefault()) {
					drawFPS = false;
					showInstructions = true;
					colorScheme = 2;

					if (!serialConnected) {
						baudRate = 9600;
						lineEnding = '\n';
						serialParity = 'N';
						serialDatabits = 8;
						serialStopbits = 1.0;
					}

					unsavedChanges = true;
					loadColorScheme(colorScheme);
					uimult = 1;
					uiResize();
				}
			}

			// Exit settings menu
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 21.5, iL, iW)){
				settingsMenuActive = false;
				redrawUI = true;
			}

		// Baud rate menu
		} else if (menuLevel == 1) {
			float tHnow = 1;
			if (baudRateList.length == 0) tHnow++;
			else {
				for (int i = 0; i < baudRateList.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (baudRate != baudRateList[i]) unsavedChanges = true;
						baudRate = baudRateList[i];
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
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

		// Line ending menu
		} else if (menuLevel == 2) {
			float tHnow = 1;
			if (lineEndingNames.length == 0) tHnow++;
			else {
				for (int i = 0; i < lineEndingNames.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (lineEnding != lineEndingList[i]) unsavedChanges = true;
						lineEnding = lineEndingList[i];
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
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

		// Parity menu
		} else if (menuLevel == 3) {
			float tHnow = 1;
			if (parityBitsNames.length == 0) tHnow++;
			else {
				for (int i = 0; i < parityBitsNames.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (serialParity != parityBitsList[i]) unsavedChanges = true;
						serialParity = parityBitsList[i];
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
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

		// Data bits menu
		} else if (menuLevel == 4) {
			float tHnow = 1;
			if (dataBitsNames.length == 0) tHnow++;
			else {
				for (int i = 0; i < dataBitsNames.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (serialDatabits != dataBitsList[i]) unsavedChanges = true;
						serialDatabits = dataBitsList[i];
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
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

		// Stop bits menu
		} else if (menuLevel == 5) {
			float tHnow = 1;
			if (stopBitsNames.length == 0) tHnow++;
			else {
				for (int i = 0; i < stopBitsNames.length; i++) {
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
						if (serialStopbits != stopBitsList[i]) unsavedChanges = true;
						serialStopbits = stopBitsList[i];
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
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
		}
	}


	/**
	 * Serial port data handler function
	 *
	 * @param  inputData New data received from the serial port
	 * @param  graphable True if data in message can be plotted on a graph
	 */
	void parsePortData(String inputData, boolean graphable) {
		// Not in use
	}


	/**
	 * Function called when a serial device has connected/disconnected
	 *
	 * @param  status True if a device has connected, false if disconnected
	 */
	void connectionEvent (boolean status) {
		// Not in use
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
}
