/* * * * * * * * * * * * * * * * * * * * * * *
 * SERIAL MONITOR CLASS
 * implements TabAPI for Processing Grapher
 *
 * @file     SerialMonitor.pde
 * @brief    A serial monitor tab for UART comms
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    SerialMonitor
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


class SerialMonitor implements TabAPI {

	int cL, cR, cT, cB;
	int border, padding, yTextHeight;
	int msgB;

	PrintWriter dataWriter;

	int msgBorder;
	int msgSize;
	int menuScroll;
	int menuHeight;
	int menuLevel;

	String name;
	String outputfile;

	boolean recordData;
	int recordCounter;
	int fileCounter;
	final int maxFileRows = 100000;
	String[] tagColumns = {"SENT:","[Info]"};
	
	int displayRows;
	final int maxBuffer = 50000;
	int scrollUp;

	String msgText= "";
	int cursorPosition;
	int[] msgTextBounds = {0,0};
	boolean autoScroll;

	final int[] baudRateList = {300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 74880, 115200, 230400, 250000, 500000, 1000000, 2000000};
	StringList serialBuffer;


	/**
	 * Constructor
	 *
	 * @param  setname Name of the tab
	 * @param  left    Tab area left x-coordinate
	 * @param  right   Tab area right x-coordinate
	 * @param  top     Tab area top y-coordinate
	 * @param  bottom  Tab area bottom y-coordinate
	 */
	SerialMonitor(String setname, int left, int right, int top, int bottom) {
		name = setname;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		msgBorder = round(15 * uimult);
		msgSize = round(2*(msgBorder) + (30 * uimult));
		border = round(15 * uimult);
		padding = round(5 * uimult);
		yTextHeight = round(12 * uimult) + padding;

		msgB = cT + msgSize;
		outputfile = "No File Set";
		recordData = false;
		recordCounter = 0;
		fileCounter = 0;
		scrollUp = 0;
		displayRows = 0;
		cursorPosition = 0;
		menuScroll = 0;
		menuHeight = cB - cT - 1; 
		menuLevel = 0;
		autoScroll = true;

		serialBuffer = new StringList();
		serialBuffer.append("--- PROCESSING SERIAL MONITOR ---");
		serialBuffer.append("");
		if (showInstructions) {
			serialBuffer.append("[Info] Connecting to a Serial Device");
			serialBuffer.append("1. In the right sidebar, select the COM port");
			serialBuffer.append("2. Set the correct baud rate for the communication");
			serialBuffer.append("3. Click the 'Connect' button to begin communication");
			serialBuffer.append("");
			serialBuffer.append("[Info] Using the Serial Monitor");
			serialBuffer.append("1. To send a message, start typing; press the enter key to send");
			serialBuffer.append("2. Scroll using the scroll wheel, up/down arrow and page up/down keys");
			serialBuffer.append("3. Press 'Clear Terminal' to remove all serial monitor messages");
			serialBuffer.append("4. Press CTRL+ or CTRL- to increase or decrease interface size");
			serialBuffer.append("");
			serialBuffer.append("[Info] Recording Serial Communication");
			serialBuffer.append("1. Click 'Set Output File' to set the save file location");
			serialBuffer.append("2. Press 'Start Recording' button to initiate the recording");
			serialBuffer.append("3. Press 'Stop Recording' to stop and save the recording");
			serialBuffer.append("");
			serialBuffer.append("[Info] Adding Visual Colour Tags");
			serialBuffer.append("Tags can be used to highlight lines containing specific text");
			serialBuffer.append("1. Click 'Add New Tag' and type the text to be detected");
			serialBuffer.append("2. Now any line containing this text will change colour");
			serialBuffer.append("3. In the right sidebar, Tags can be deleted and modified");
			serialBuffer.append("");
		}
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
		
		// Draw the message box
		rectMode(CORNERS);
		noStroke();
		fill(c_background);
		rect(cL, cT, cR, cT + msgB);
		fill(c_serial_message_box);
		rect(cL + msgBorder, cT + msgBorder, cR - msgBorder, msgB - msgBorder);

		textFont(base_font);
		textAlign(LEFT, TOP);

		// Message text button
		String msgBtnText = "Send:";
		final int msgBtnSize = int(textWidth(msgBtnText)); 

		fill(c_terminal_text);
		text(msgBtnText, cL + 2*msgBorder, cT + msgBorder + 9 * uimult);

		fill(c_background);
		stroke(c_background);
		strokeWeight(1 * uimult);
		line(cL + 3*msgBorder + msgBtnSize, cT + msgBorder, cL + 3*msgBorder + msgBtnSize, msgB - msgBorder);

		// Ensure cursor is within bounds
		if (cursorPosition < 0) cursorPosition = 0;
		else if (cursorPosition > msgText.length()) cursorPosition = msgText.length();

		// Figure out where the cursor is and how much of the message to show
		textFont(mono_font);

		final float charWidth = textWidth("a");
		final int maxChars = floor((cR -cL - 6*msgBorder - msgBtnSize) / charWidth);

		if (cursorPosition > msgTextBounds[1]) {
			msgTextBounds[0] += cursorPosition - msgTextBounds[1];
			msgTextBounds[1] = cursorPosition;

		} else if (cursorPosition < msgTextBounds[0]) {
			msgTextBounds[1] -= msgTextBounds[0] - cursorPosition;
			msgTextBounds[0] = cursorPosition;
		}

		if (msgTextBounds[1] - msgTextBounds[0] < maxChars || msgTextBounds[1] > msgText.length()) {
			msgTextBounds[1] = msgText.length();
			msgTextBounds[0] = msgText.length() - maxChars;
		}

		// Validate the bounds
		if (msgTextBounds[0] < 0) msgTextBounds[0] = 0;
		if (msgTextBounds[1] < 0) msgTextBounds[1] = 0; 

		// Draw cursor
		fill(c_terminal_text);
		stroke(c_terminal_text);
		rectMode(CORNER);
		rect(cL + 4*msgBorder + msgBtnSize + (cursorPosition - msgTextBounds[0]) * charWidth + round(1*uimult), cT + msgBorder + round(9 * uimult), round(2*uimult), round(13 * uimult));

		// Message text
		rectMode(CORNERS);
		fill(c_message_text);
		text(msgText.substring(msgTextBounds[0], msgTextBounds[1]), cL + 4*msgBorder + msgBtnSize, cT + msgBorder + round(9 * uimult));//, cR - 2*msgBorder, msgB - msgBorder);

		// Draw arrows to indicate if there is any hidden text
		if (msgTextBounds[0] > 0) {
			final int halfWay = cT + msgBorder + round(15 * uimult);
			final int frontPos = cL + round(3.25*msgBorder) + msgBtnSize;
			final int dist4 = round(4 * uimult);
			final int dist2 = round(2 * uimult);

			fill(c_terminal_text);
			stroke(c_terminal_text);
			triangle(frontPos, halfWay, frontPos + dist4, halfWay + dist2, frontPos + dist4, halfWay - dist2);
		}

		if (msgTextBounds[1] < msgText.length()) {
			final int halfWay = cT + msgBorder + round(15 * uimult);
			final int backPos = cR - round(1.25*msgBorder);
			final int dist4 = round(4 * uimult);
			final int dist2 = round(2 * uimult);

			fill(c_terminal_text);
			stroke(c_terminal_text);
			triangle(backPos, halfWay, backPos - dist4, halfWay + dist2, backPos - dist4, halfWay - dist2);
		}

		// Draw the terminal
		drawNewData();
	}


	/**
	 * Draw new tab data
	 */
	void drawNewData() {

		// Clear the content area
		rectMode(CORNER);
		noStroke();
		fill(c_background);
		rect(cL, msgB, cR - cL, cB - msgB);
		
		// Figure out how many rows of text can be displayed
		displayRows = int((cB - msgB - border) / yTextHeight);
		while (displayRows > serialBuffer.size() - scrollUp && scrollUp > 0) {
			scrollUp--;
			displayRows = serialBuffer.size() - scrollUp;
		}
		if (displayRows > serialBuffer.size() - scrollUp) displayRows = serialBuffer.size() - scrollUp;
		int totalHeight = displayRows * yTextHeight;

		// Draw left bar
		fill(c_serial_message_box);
		rect(cL, msgB, border/2, totalHeight);
		textAlign(LEFT, TOP);
		textFont(mono_font);

		// Figure out size and position of scroll bar indicator
		if (serialBuffer.size() > 0) {
			int scrollbarSize = totalHeight * displayRows / serialBuffer.size();
			if (scrollbarSize < yTextHeight) scrollbarSize = yTextHeight;
			int scrollbarOffset = int((totalHeight - scrollbarSize) * (1 - (scrollUp / float(serialBuffer.size() - displayRows))));
			fill(c_terminal_text);
			rect(cL, msgB + scrollbarOffset, border/2, scrollbarSize);

			totalHeight -= yTextHeight;

			final float charWidth = textWidth("a");
			final int maxChars = floor((cR - 2*cL - 5*border) / charWidth);

			// Now print the text
			for (int i = 0; i < displayRows; i++) {

				color textColor = c_terminal_text;
				int textIndex = serialBuffer.size() - 1 - i - scrollUp;
				if (textIndex < 0) textIndex = 0;
				String textRow = serialBuffer.get(textIndex);

				// Figure out the text colour
				for (int j = 0; j < tagColumns.length; j++) {
					if (textRow.contains(tagColumns[j])) {
						textColor = c_colorlist[j-(c_colorlist.length * floor(j / c_colorlist.length))];
					}
				}

				// Check wheter text length exceeds width of the window
				if (textRow.length() > maxChars) {
					textRow = textRow.substring(0, maxChars - 1);

					fill(c_terminal_text);
					text(">>", cR - 2*border, msgB + totalHeight);
				}

				// Print the text
				fill(textColor);
				text(textRow, cL + 2*border, msgB + totalHeight);//, cR - cL - 3*border, yTextHeight);

				totalHeight -= yTextHeight;
			}
		} else {
			if (recordData) {
				fill(c_terminal_text);
				text("Serial monitor has been cleared\n(A new save file has just been opened)", cL + 2*border, msgB);
			} else {
				serialBuffer.append("--- PROCESSING SERIAL MONITOR ---");
				drawNewData = true;
			}
		}

		textFont(base_font);
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

		msgBorder = round(15 * uimult);
		msgSize = round(2*(msgBorder) + (30 * uimult));
		msgB = cT + msgSize;
		border = round(15 * uimult);
		padding = round(5 * uimult);
		yTextHeight = round(12 * uimult) + padding;
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
			final int dotPos = newoutput.lastIndexOf(".");
			if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
			newoutput = newoutput + ".txt";

			// Test whether this file is actually accessible
			if (saveFile(newoutput) == null) {
				alertHeading = "Error\nUnable to access the selected output file location; is this actually a writable location?\n" + newoutput;
				newoutput = "No File Set";
				redrawAlert = true;
			}
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
		try {
			// Open the writer
			File filePath = saveFile(outputfile);
			dataWriter = createWriter(filePath);
			serialBuffer.clear();
			scrollUp = 0;
			recordCounter = 0;
			fileCounter = 0;
			recordData = true;
			redrawUI = true;
			drawNewData = true;
		} catch (Exception e) {
			println(e);
			alertHeading = "Error\nUnable to create the output file:\n" + e;
			redrawAlert = true;
		}
	}


	/**
	 * Stop recording data points to file
	 */
	void stopRecording(){
		recordData = false;

		try {
			dataWriter.flush();
			dataWriter.close();

			alertHeading = "Success\nRecorded " + ((fileCounter * 10000) + recordCounter) + " entries to " + (fileCounter + 1) + " TXT file(s)";
			redrawAlert = true;
		} catch (Exception e) {
			println(e);
			alertHeading = "Error\nUnable to save the output file:\n" + e;
			redrawAlert = true;
		}

		outputfile = "No File Set";
		redrawUI = true;
	}


	/**
	 * Function called when a serial device has connected/disconnected
	 *
	 * @param  status True if a device has connected, false if disconnected
	 */
	void connectionEvent (boolean status) {

		// On disconnect
		if (!status) {
			// Stop recording any data
			if (recordData) stopRecording();
		}
	}

	/**
	 * Parse new data points received from serial port
	 *
	 * @param  inputData String containing data points separated by commas
	 * @param  graphable True if data in message can be plotted on a graph
	 */
	void parsePortData(String inputData, boolean graphable) {

		serialBuffer.append(inputData);
		if (!autoScroll && scrollUp < maxBuffer) scrollUp++;

		// --- Data Recording ---
		if(recordData) {
			recordCounter++;

			try {
				dataWriter.println(inputData);
				if (dataWriter.checkError()) {
					emergencyOutputSave(true);
				}

				// Separate data into files once the max number of rows has been reached
				if (recordCounter >= maxFileRows) {
					dataWriter.close();
					fileCounter++;
					recordCounter = 0;

					final int dotPos = outputfile.lastIndexOf(".");
					final String nextoutputfile = outputfile.substring(0, dotPos) + "-" + (fileCounter + 1) + ".txt";
					File filePath = saveFile(nextoutputfile);
					dataWriter = createWriter(filePath);

					serialBuffer.clear();
					scrollUp = 0;
					redrawUI = true;
				}
			} catch (Exception e) {
				emergencyOutputSave(true);
			}
		} else {
			// --- Data Buffer ---
			if (serialBuffer.size() >= maxBuffer) {
				serialBuffer.remove(0);
			}
		}

		drawNewData = true;
	}


	/**
	 * Recover from an rrror when recording data to file
	 *
	 * @param  continueRecording If we want to continue recording after dealing with the error
	 */
	void emergencyOutputSave(boolean continueRecording) {
		dataWriter.close();

		// Figure out name for new backup file
		String[] tempSplit = split(outputfile, '/');
		int dotPos = tempSplit[tempSplit.length - 1].lastIndexOf(".");
		String nextoutputfile = tempSplit[tempSplit.length - 1].substring(0, dotPos);
		outputfile = nextoutputfile + "-backup.txt";

		String emergencysavefile = nextoutputfile + "-backup-" + (fileCounter + 1) + ".txt";

		try {
			// Backup the existing data
			File filePath = saveFile(emergencysavefile);
			dataWriter = createWriter(filePath);
			for (int i = 0; i < serialBuffer.size(); i++) {
				dataWriter.println(serialBuffer.get(i));
			}
			if (dataWriter.checkError()) continueRecording = false;
			dataWriter.close();

			// If we want to continue recording, try setting up a new output file
			if (continueRecording) {
				fileCounter++;
				nextoutputfile = nextoutputfile + "-backup-" + (fileCounter + 1) + ".txt";

				filePath = saveFile(nextoutputfile);

				// If new output file was successfully opened, only show a Warning message
				if (filePath != null) {
					alertHeading = "Warning\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. Data is still being recorded (to a new file)\n3. The files are in the same directory as ProcessingGrapher.exe";
					dataWriter = createWriter(filePath);
					serialBuffer.clear();
					scrollUp = 0;

				// If not, show an error message that the recording has stopped
				} else {
					recordData = false;
					alertHeading = "Error - Recording Stopped\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. The files are in the same directory as ProcessingGrapher.exe";
				}

			// If we don't want to continue, show a simple error message
			} else {
				recordData = false;
				alertHeading = "Error\nAn issue occurred when trying to save new data to the ouput file.\n1. Data recording has been stopped\n2. A backup of all the data has been created\n3. The backup is in the same directory as ProcessingGrapher.exe";
			}

			redrawAlert = true;
			redrawUI = true;
			drawNewData = true;

		// If something went wrong in the error recovery process, show a critical error message
		} catch (Exception e) {
			dataWriter.close();
			recordData = false;
			redrawAlert = true;
			redrawUI = true;
			alertHeading = "Critical Error\nAn issue occurred when trying to save new data to the ouput file.\nData backup was also unsuccessful, so some data may have been lost...\n" + e;
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
		final int sW = width - cR;
		final int sH = height - cT;

		final int uH = round(sideItemHeight * uimult);
		final int tH = round((sideItemHeight - 8) * uimult);
		final int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		final int iW = round(sW - (20 * uimult));

		String[] ports = Serial.list();

		if (menuLevel == 0)	menuHeight = round((14 + tagColumns.length) * uH);
		else if (menuLevel == 1) menuHeight = round((3 + ports.length) * uH);
		else if (menuLevel == 2) menuHeight = round((3 + baudRateList.length) * uH);

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

		// Root sidebar menu
		if (menuLevel == 0) {
			// Connect or Disconnect to COM Port
			drawHeading("Serial Port", iL, sT + (uH * 0), iW, tH);
			if (ports.length == 0) drawDatabox("Port: None", iL, sT + (uH * 1), iW, iH, tH);
			else if (ports.length <= portNumber) drawDatabox("Port: Invalid", iL, sT + (uH * 1), iW, iH, tH);
			else drawDatabox("Port: " + constrainString(ports[portNumber], iW - textWidth("Port: ") - (15 * uimult)), iL, sT + (uH * 1), iW, iH, tH);
			drawDatabox("Baud: " + baudRate, iL, sT + (uH * 2), iW, iH, tH);
			drawButton((serialConnected)? "Disconnect":"Connect", (serialConnected)? c_sidebar_accent:c_sidebar_button, iL, sT + (uH * 3), iW, iH, tH);

			// Save to File
			drawHeading("Record Messages", iL, sT + (uH * 4.5), iW, tH);
			if (outputfile == "No File Set" || outputfile == "") {
				drawButton("Set Output File", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
				drawDatabox("Start Recording", c_sidebar_button, iL, sT + (uH * 6.5), iW, iH, tH);
			} else {
				String[] fileParts = split(outputfile, '/');
				String fileName = fileParts[fileParts.length - 1];

				if (recordData) {
					drawDatabox(fileName, c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
					drawButton("Stop Recording", c_sidebar_accent, iL, sT + (uH * 6.5), iW, iH, tH);
				} else {
					drawDatabox(fileName, c_sidebar_text, iL, sT + (uH * 5.5), iW, iH, tH);
					drawButton("Start Recording", c_sidebar_button, iL, sT + (uH * 6.5), iW, iH, tH);
				}
			}

			// Input Data Columns
			drawHeading("Terminal Options", iL, sT + (uH * 8), iW, tH);
			if (recordData) drawDatabox("Clear Terminal", c_sidebar_button, iL, sT + (uH * 9), iW, iH, tH);
			else drawButton("Clear Terminal", c_sidebar_button, iL, sT + (uH * 9), iW, iH, tH);
			drawButton((autoScroll)? "Autoscroll: On":"Autoscroll: Off", c_sidebar_button, iL, sT + (uH * 10), iW, iH, tH);

			// Input Data Columns
			drawHeading("Colour Tags", iL, sT + (uH * 11.5), iW, tH);
			drawButton("Add New Tag", c_sidebar_button, iL, sT + (uH * 12.5), iW, iH, tH);

			float tHnow = 13.5;

			// List of Data Columns
			for(int i = 0; i < tagColumns.length; i++){
				// Column name
				drawDatabox(tagColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

				// Remove column button
				drawButton("x", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

				// Swap column with one being listed above button
				color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
				drawButton("^", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

				drawRectangle(c_sidebar_divider, iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
				tHnow++;
			}

		// Serial port select menu
		} else if (menuLevel == 1) {
			drawHeading("Select a Port", iL, sT + (uH * 0), iW, tH);

			float tHnow = 1;
			if (ports.length == 0) {
				drawText("No devices detected", c_sidebar_text, iL, sT + (uH * tHnow), iW, iH);
				tHnow += 1;
			} else {
				for (int i = 0; i < ports.length; i++) {
					drawButton(constrainString(ports[i], iW - (10 * uimult)), c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
					tHnow += 1;
				}
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_accent, iL, sT + (uH * tHnow), iW, iH, tH);

		// Baud rate selection menu
		} else if (menuLevel == 2) {
			drawHeading("Select Baud Rate", iL, sT + (uH * 0), iW, tH);

			float tHnow = 1;
			for (int i = 0; i < baudRateList.length; i++) {
				drawButton(str(baudRateList[i]), c_sidebar_button, iL, sT + (uH * tHnow), iW, iH, tH);
				tHnow += 1;
			}
			tHnow += 0.5;
			drawButton("Cancel", c_sidebar_accent, iL, sT + (uH * tHnow), iW, iH, tH);
		}

		// Draw bottom info bar
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
	void keyboardInput(char keyChar, int keyCodeInt, boolean codedKey) {

		// For standard characters, simply type them into the message box
		if (!codedKey && 32 <= keyChar && keyChar <= 126) {
			if (cursorPosition < msgText.length()) {
				if (cursorPosition == 0) {
					msgText = keyChar + msgText;
				} else {
					String msg = msgText.substring(0,cursorPosition) + keyChar;
					msg = msg + msgText.substring(cursorPosition,msgText.length());
					msgText = msg;
				}
			} else {
				msgText += keyChar;
			}
			cursorPosition++;
			redrawContent = true;

		// Test for all other keys in a slightly slower switch statement			
		} else {

			switch (keyCodeInt) {
				case ENTER:
				case RETURN:
					if (msgText != ""){
						if (serialConnected) {
							serialSend(msgText);
						}
						msgText = "SENT: " + msgText;
						//serialBuffer = append(serialBuffer, msgText);
						serialBuffer.append(msgText);
						msgText = "";
						cursorPosition = 0;
						if (!autoScroll) scrollUp++;
						redrawContent = true;
					}
					break;

				case BACKSPACE:
					if (msgText != "") {
						if (cursorPosition < msgText.length() && cursorPosition > 0) {
							String msg = msgText.substring(0,cursorPosition-1) + msgText.substring(cursorPosition,msgText.length());
							msgText = msg;
							cursorPosition--;
						} else if (cursorPosition >= msgText.length() && msgText.length() > 1) {
							msgText = msgText.substring(0, msgText.length()-1);
							cursorPosition--;
							if (cursorPosition < 0) cursorPosition = 0;
						} else if (cursorPosition >= msgText.length() && msgText.length() <= 1) {
							msgText = "";
							cursorPosition = 0;
						}
						redrawContent = true;
					}
					break;

				case DELETE:
					if (msgText != "") {
						if (cursorPosition + 1 < msgText.length() && cursorPosition > 0) {
							String msg = msgText.substring(0,cursorPosition) + msgText.substring(cursorPosition + 1,msgText.length());
							msgText = msg;
						} else if (cursorPosition + 1 == msgText.length() && msgText.length() > 1) {
							msgText = msgText.substring(0, msgText.length()-1);
						} else if (cursorPosition==0 && msgText.length() > 1) {
							msgText = msgText.substring(1, msgText.length());
						} else if (cursorPosition==0 && msgText.length() <= 1) {
							msgText = "";
							cursorPosition = 0;
						}
						redrawContent = true;
					}
					break;

				case RIGHT:
					if (cursorPosition < msgText.length()) cursorPosition++;
					else cursorPosition = msgText.length();
					redrawContent = true;
					break;

				case LEFT:
					if (cursorPosition > 0) cursorPosition--;
					else cursorPosition = 0;
					redrawContent = true;
					break;

				case UP:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll -= (12 * uimult);
						if (menuScroll < 0) menuScroll = 0;
						redrawUI = true;
					// Scroll serial monitor
					} else {
						if (scrollUp < serialBuffer.size() - displayRows) scrollUp++;
						else scrollUp = serialBuffer.size() - displayRows;
						drawNewData = true;
					}
					break;

				case DOWN:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll += (12 * uimult);
						if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
						redrawUI = true;
					// Scroll serial monitor
					} else {
						if (scrollUp > 0) scrollUp--;
						else scrollUp = 0;
						drawNewData = true;
					}
					break;

				case KeyEvent.VK_PAGE_UP:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll -= height - cT;
						if (menuScroll < 0) menuScroll = 0;
						redrawUI = true;
					// Scroll serial monitor
					} else {
						if (scrollUp < serialBuffer.size() - displayRows) scrollUp += displayRows;
						if (scrollUp > serialBuffer.size() - displayRows) scrollUp = serialBuffer.size() - displayRows;
						drawNewData = true;
					}
					break;

				case KeyEvent.VK_PAGE_DOWN:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll += height - cT;
						if (menuScroll > menuHeight - (height - cT)) menuScroll = menuHeight - (height - cT);
						redrawUI = true;
					// Scroll serial monitor
					} else {
						if (scrollUp > 0) scrollUp -= displayRows;
						if (scrollUp < 0) scrollUp = 0;
						drawNewData = true;
					}
					break;

				case KeyEvent.VK_END:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll = menuHeight - (height - cT);
						redrawUI = true;
					// Scroll serial monitor
					} else {
						scrollUp = 0;
						drawNewData = true;
					}
					break;

				case KeyEvent.VK_HOME:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll = 0;
						redrawUI = true;
					// Scroll serial monitor
					} else {
						scrollUp = serialBuffer.size() - displayRows;
						drawNewData = true;
					}
					break;

				default:
					print("Unknown character: ");
					print(keyChar);
					print(" ");
					println(keyCodeInt);
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
		// Nothing here yet  
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
		final int sL = cR;
		final int sW = width - cR;
		final int sH = height - sT;

		final int uH = round(sideItemHeight * uimult);
		final int tH = round((sideItemHeight - 8) * uimult);
		final int iH = round((sideItemHeight - 5) * uimult);
		final int iL = round(sL + (10 * uimult));
		final int iW = round(sW - (20 * uimult));

		String[] ports = Serial.list();

		// Root menu level
		if (menuLevel == 0) {

			// COM Port Number
			if (menuYclick(mouseY, sT, uH, iH, 1)) { //(mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
				menuLevel = 1;
				menuScroll = 0;
				redrawUI = true;
			}

			// COM Port Baud Rate
			else if (menuYclick(mouseY, sT, uH, iH, 2)){
				menuLevel = 2;
				menuScroll = 0;
				redrawUI = true;
			}

			// Connect to COM port
			else if (menuYclick(mouseY, sT, uH, iH, 3)){
				setupSerial();
			}

			// Select output file name and directory
			else if (menuYclick(mouseY, sT, uH, iH, 5.5)){
				if (!recordData) {
					outputfile = "";
					frame.setAlwaysOnTop(false);
					selectOutput("Select a location and name for the output *.txt file", "fileSelected");
					frame.toBack();
				}
			}
			
			// Start recording data and saving it to a file
			else if (menuYclick(mouseY, sT, uH, iH, 6.5)) {
				if(recordData) {
					stopRecording();
				} else if(outputfile != "" && outputfile != "No File Set") {
					startRecording();
				}
			}

			// Clear the terminal buffer
			else if (menuYclick(mouseY, sT, uH, iH, 9)) {
				if (!recordData) {
					serialBuffer.clear();
					serialBuffer.append("--- PROCESSING SERIAL MONITOR ---");
					scrollUp = 0;
					drawNewData = true;
				}
			}

			// Turn autoscrolling on/off
			else if (menuYclick(mouseY, sT, uH, iH, 10)) {
				autoScroll = !autoScroll;
				redrawUI = true;
			}

			// Add a new colour tag column
			else if (menuYclick(mouseY, sT, uH, iH, 12.5)) {
				final String colname = trim(showInputDialog("New Tag Keyword Text:"));
				if (colname != null && colname.length() > 0){
					tagColumns = append(tagColumns, colname);
					redrawUI = true;
					drawNewData = true;
				}
			}
			
			else {
				float tHnow = 13.5;

				// List of Data Columns
				for(int i = 0; i < tagColumns.length; i++) {

					if (menuYclick(mouseY, sT, uH, iH, tHnow)) {

						// Remove column
						if ((mouseX > iL + iW - (20 * uimult)) && (mouseX <= iL + iW)) {
							tagColumns = remove(tagColumns, i);
							redrawUI = true;
							drawNewData = true;
						}

						// Move column up one space
						else if ((mouseX >= iL + iW - (40 * uimult)) && (mouseX <= iL + iW - (20 * uimult))) {
							if (i - 1 >= 0) {
								String temp = tagColumns[i - 1];
								tagColumns[i - 1] = tagColumns[i];
								tagColumns[i] = temp;
							}
							redrawUI = true;
							drawNewData = true;
						}

						// Change name of column
						else {
							final String colname = trim(showInputDialog("Please enter the new tag text\nCurrent Tag = " + tagColumns[i]));
							if (colname != null && colname.length() > 0){
								tagColumns[i] = colname;
								redrawUI = true;
								drawNewData = true;
							}
						}
					}
					
					tHnow++;
				}
			}

		// Select COM port
		} else if (menuLevel == 1) {
			float tHnow = 1;
			if (ports.length == 0) tHnow++;
			else {
				for (int i = 0; i < ports.length; i++) {
					if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)) {

						// If the serial port is already connected to a different port, disconnect it
						if (serialConnected && portNumber != i) setupSerial();

						portNumber = i;
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
					}
					tHnow++;
				}
			}

			// Cancel button
			tHnow += 0.5;
			if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
			}

		// Select a baud rate
		} else if (menuLevel == 2) {
			float tHnow = 1;
			for (int i = 0; i < baudRateList.length; i++) {
				if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)) {
					baudRate = baudRateList[i];
					menuLevel = 0;
					menuScroll = 0;

					// If serial is already connected, disconnect and reconnect it at the new rate
					if (serialConnected) {
						setupSerial();
						setupSerial();
					}
					redrawUI = true;
				}
				tHnow++;
			}

			// Cancel button
			tHnow += 0.5;
			if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)) {
				menuLevel = 0;
				menuScroll = 0;
				redrawUI = true;
			}
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

		// Scroll serial monitor
		} else {
			scrollUp -= round(1 * amount);
			if (scrollUp < 0) scrollUp = 0;
			else if (scrollUp > serialBuffer.size() - displayRows) scrollUp = serialBuffer.size() - displayRows;
			drawNewData = true;
		}

		redrawUI = true;
	}


	/**
	 * Scroll bar handler function
	 *
	 * @param  xcoord Current mouse x-coordinate position
	 * @param  ycoord Current mouse y-coordinate position
	 */
	void scrollBarUpdate(int xcoord, int ycoord) {

	}
}
