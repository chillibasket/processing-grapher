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

class Settings implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	int menuScroll;
	int menuHeight;

	String name;
	String outputfile;

	boolean unsavedChanges = false;

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

		if (saveXML(xmlFile, "data/user-preferences.xml")) {
			alertHeading = "Success\nUser preferences saved";
			redrawAlert = true;
			unsavedChanges = false;
		} else {
			alertHeading = "Error\nUnable to save user preferences";
			redrawAlert = true;
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
		menuHeight = round(17 * uH);

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

		// UI Scaling Options
		drawHeading("Interface Size", iL, sT + (uH * 0.5), iW, tH);
		drawButton("-", c_sidebar_button, iL, sT + (uH * 1.5), iW / 4, iH, tH);
		drawButton("+", c_sidebar_button, iL + (iW * 3 / 4), sT + (uH * 1.5), iW / 4, iH, tH);
		drawDatabox(round(uimult*100) + "%", c_sidebar_button, iL + (iW / 4), sT + (uH * 1.5), iW / 2, iH, tH);


		// Change the colour scheme
		drawHeading("Colour Scheme", iL, sT + (uH * 3), iW, tH);
		drawButton("Light - Celeste", (colorScheme == 0)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 4), iW, iH, tH);
		drawButton("Dark - Gravity", (colorScheme == 1)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 5), iW, iH, tH);
		drawButton("Dark - Monokai", (colorScheme == 2)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 6), iW, iH, tH);

		// Turn FPS counter on/off
		drawHeading("FPS Indicator", iL, sT + (uH * 7.5), iW, tH);
		drawButton("Show", (drawFPS)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 8.5), iW/2, iH, tH);
		drawButton("Hide", (!drawFPS)? c_sidebar_accent:c_sidebar_button, iL + (iW/2), sT + (uH * 8.5), iW/2, iH, tH);
		drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 8.5) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		// Turn useful instructions on/off
		drawHeading("Usage Instructions", iL, sT + (uH * 10), iW, tH);
		drawButton("Show", (showInstructions)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 11), iW/2, iH, tH);
		drawButton("Hide", (!showInstructions)? c_sidebar_accent:c_sidebar_button, iL + (iW/2), sT + (uH * 11), iW/2, iH, tH);
		drawRectangle(c_sidebar_divider, iL + (iW / 2), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		// Save preferences
		drawHeading("User Preferences", iL, sT + (uH * 12.5), iW, tH);
		if (unsavedChanges) drawButton("Save Settings", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
		else drawDatabox("Save Settings", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);

		if (uimult != 1 || !showInstructions || drawFPS || colorScheme != 2) {
			drawButton("Reset to Default", c_sidebar_button, iL, sT + (uH * 14.5), iW, iH, tH);
		} else {
			drawDatabox("Reset to Default", c_sidebar_button, iL, sT + (uH * 14.5), iW, iH, tH);
		}

		drawButton("Exit Settings", c_sidebar_button, iL, sT + (uH * 15.5), iW, iH, tH);
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
		// Not in use
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

		// UI scaling
		if ((mouseY > sT + (uH * 1.5)) && (mouseY < sT + (uH * 1.5) + iH)){
			// Decrease
			if ((mouseX > iL) && (mouseX <= iL + iW / 4)) {
				if (uimult > 0.5) {
					uiResize(-0.1);
					unsavedChanges = true;
				}
			}

			// Increase
			else if ((mouseX > iL + iW * 3 / 4) && (mouseX <= iL + iW)) {
				if (uimult < 2.0) {
					uiResize(0.1);
					unsavedChanges = true;
				}
			}
		}

		// Color Scheme 0 - Light Celeste
		else if ((mouseY > sT + (uH * 4)) && (mouseY < sT + (uH * 4) + iH)) {
			if (colorScheme != 0) {
				unsavedChanges = true;
				colorScheme = 0;
				loadColorScheme(colorScheme);
			}
		}

		// Color Scheme 1 - Dark Gravity
		else if ((mouseY > sT + (uH * 5)) && (mouseY < sT + (uH * 5) + iH)) {
			if (colorScheme != 1) {
				unsavedChanges = true;
				colorScheme = 1;
				loadColorScheme(colorScheme);
			}
		}

		// Color Scheme 2 - Dark Monokai
		else if ((mouseY > sT + (uH * 6)) && (mouseY < sT + (uH * 6) + iH)) {
			if (colorScheme != 2) {
				unsavedChanges = true;
				colorScheme = 2;
				loadColorScheme(colorScheme);
			}
		}

		// Toggle FPS indicator
		else if ((mouseY > sT + (uH * 8.5)) && (mouseY < sT + (uH * 8.5) + iH)) {
			// Show
			if ((mouseX > iL) && (mouseX <= iL + iW / 2)) {
				if (!drawFPS) {
					drawFPS = true;
					unsavedChanges = true;
					redrawUI = true;
				}
			}

			// Hide
			else if ((mouseX > iL + (iW / 2)) && (mouseX <= iL + iW)) {
				if (drawFPS) {
					drawFPS = false;
					unsavedChanges = true;
					redrawUI = true;
				}
			}
		}

		// Toggle usage instructions
		else if ((mouseY > sT + (uH * 11)) && (mouseY < sT + (uH * 11) + iH)){
			// Show
			if ((mouseX > iL) && (mouseX <= iL + iW / 2)) {
				if (!showInstructions) {
					showInstructions = true;
					unsavedChanges = true;
					redrawUI = true;
					redrawContent = true;
				}
			}

			// Hide
			else if ((mouseX > iL + (iW / 2)) && (mouseX <= iL + iW)) {
				if (showInstructions) {
					showInstructions = false;
					unsavedChanges = true;
					redrawUI = true;
					redrawContent = true;
				}
			}
		}

		// Remember preferences
		else if ((mouseY > sT + (uH * 13.5)) && (mouseY < sT + (uH * 13.5) + iH)){
			if (unsavedChanges) saveSettings();
		}

		// Reset preferences to default
		else if ((mouseY > sT + (uH * 14.5)) && (mouseY < sT + (uH * 14.5) + iH)){
			if (uimult != 1 || !showInstructions || drawFPS || colorScheme != 2) {
				drawFPS = false;
				showInstructions = true;
				colorScheme = 2;
				unsavedChanges = true;
				loadColorScheme(colorScheme);
				uimult = 1;
				uiResize();
			}
		}

		// Exit settings menu
		else if ((mouseY > sT + (uH * 15.5)) && (mouseY < sT + (uH * 15.5) + iH)){
			settingsMenuActive = false;
			redrawUI = true;
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
}
