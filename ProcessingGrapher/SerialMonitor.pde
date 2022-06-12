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
	final int maxFileRows = 50000;
	ArrayList<SerialTag> serialTags = new ArrayList<SerialTag>();
	
	int displayRows;
	final int maxBuffer = 50000;
	int scrollUp;
	ScrollBar serialScroll = new ScrollBar(ScrollBar.VERTICAL, ScrollBar.INVERT);
	ScrollBar sidebarScroll = new ScrollBar(ScrollBar.VERTICAL, ScrollBar.NORMAL);

	String msgText= "";
	int cursorPosition;
	int[] msgTextBounds = {0,0};
	boolean autoScroll;
	boolean tabIsVisible;
	int msgBtnSize = 0;

	color previousColor = c_red;
	color hueColor = c_red;
	color newColor = c_red;
	int colorSelector = 0;

	final int[] baudRateList = {300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 74880, 115200, 230400, 250000, 500000, 1000000, 2000000};
	SerialMessages serialBuffer;                              //! Ring buffer used to store serial messages
	//PGraphics serialGraphics;

	TextSelection inputTextSelection = new TextSelection();   //! Selection/highlighting of serial input text area
	TextSelection serialTextSelection = new TextSelection();  //! Selection/highlighting of serial monitor text area
	int activeArea = 0;


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
		tabIsVisible = false;
		
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

		serialTags.add(new SerialTag("SENT:", c_colorlist[0]));
		serialTags.add(new SerialTag("[Info]", c_colorlist[1]));

		serialBuffer = new SerialMessages(maxBuffer);
		//serialBuffer = new StringList();
		serialBuffer.append("--- PROCESSING SERIAL MONITOR ---");
		if (showInstructions) {
			serialBuffer.append("");
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
		msgBtnSize = int(textWidth(msgBtnText)); 

		fill(c_terminal_text);
		text(msgBtnText, cL + 2*msgBorder, cT + msgBorder + 6.5 * uimult);

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

		// If text is highlighted, draw the background
		if (inputTextSelection.valid && (inputTextSelection.startChar <= msgTextBounds[1]) && (inputTextSelection.endChar >= msgTextBounds[0])) {
			fill(c_highlight_background);
			noStroke();
			rectMode(CORNERS);
			float leftHighlight = cL + 4*msgBorder + msgBtnSize;
			float rightHighlight = leftHighlight + (msgTextBounds[1] - msgTextBounds[0]) * charWidth;
			if (inputTextSelection.startChar > msgTextBounds[0]) leftHighlight += (inputTextSelection.startChar - msgTextBounds[0]) * charWidth;
			if (inputTextSelection.endChar < msgTextBounds[1]) rightHighlight -= (msgTextBounds[1] - inputTextSelection.endChar) * charWidth;
			rect(leftHighlight, cT + msgBorder + round(9 * uimult), rightHighlight, cT + msgBorder + round(9 * uimult) + yTextHeight);
		}

		// Draw cursor
		if (!inputTextSelection.valid && activeArea == 0) {
			fill(c_terminal_text);
			stroke(c_terminal_text);
			rectMode(CORNER);
			rect(cL + 4*msgBorder + msgBtnSize + (cursorPosition - msgTextBounds[0]) * charWidth + round(1*uimult), cT + msgBorder + round(9 * uimult), round(2*uimult), round(13 * uimult));
		}

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

		// Figure out size and position of vertical scroll bar indicator
		if (serialBuffer.size() > 0) {
			int scrollbarSize = totalHeight * displayRows / serialBuffer.size();
			if (scrollbarSize < yTextHeight) scrollbarSize = yTextHeight;
			int scrollbarOffset = int((totalHeight - scrollbarSize) * (1 - (scrollUp / float(serialBuffer.size() - displayRows))));
			fill(c_terminal_text);
			rect(cL, msgB + scrollbarOffset, border/2, scrollbarSize);
			serialScroll.update(serialBuffer.size(), totalHeight, cL, msgB + scrollbarOffset, border / 2, scrollbarSize);

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
				for (SerialTag curTag : serialTags) {
					if (textRow.contains(curTag.tagText)) {
						textColor = curTag.tagColor;
					}
				}

				// Check wheter text length exceeds width of the window
				if (textRow.length() > maxChars) {
					textRow = textRow.substring(0, maxChars - 1);

					fill(c_terminal_text);
					text(">>", cR - 2*border, msgB + totalHeight);
				}

				// If text is highlighted, draw the background
				if (serialTextSelection.valid) {
					fill(c_highlight_background);
					if (serialTextSelection.startLine < textIndex && serialTextSelection.endLine > textIndex) {
						rect(cL + 2*border, msgB + totalHeight, textRow.length() * charWidth, yTextHeight);
					} else if (serialTextSelection.startLine == textIndex && serialTextSelection.endLine == textIndex) {
						rect(cL + 2*border + charWidth * serialTextSelection.startChar, msgB + totalHeight, (serialTextSelection.endChar - serialTextSelection.startChar) * charWidth, yTextHeight);
					} else if (serialTextSelection.startLine == textIndex && serialTextSelection.endLine > textIndex) {
						rect(cL + 2*border + charWidth * serialTextSelection.startChar, msgB + totalHeight, (textRow.length() - serialTextSelection.startChar) * charWidth, yTextHeight);
					} else if (serialTextSelection.startLine < textIndex && serialTextSelection.endLine == textIndex) {
						rect(cL + 2*border, msgB + totalHeight, serialTextSelection.endChar * charWidth, yTextHeight);
					}
				}

				// Print the text
				fill(textColor);
				text(textRow, cL + 2*border, msgB + totalHeight);//, cR - cL - 3*border, yTextHeight);

				totalHeight -= yTextHeight;
			}

			// If scrolled up, draw a return to bottom button
			if (scrollUp > 0) {
				fill(c_sidebar);
				rect(cR - (40 * uimult), cB - (40 * uimult), (30 * uimult), (30 * uimult));
				fill(c_background);
				strokeWeight(1 * uimult);
				stroke(c_terminal_text);
				triangle(cR - (30*uimult), cB - (29*uimult), cR - (20*uimult), cB - (29*uimult), cR - (25*uimult), cB - (20*uimult));
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
				alertMessage("Error\nUnable to access the selected output file location; is this actually a writable location?\n" + newoutput);
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
			alertMessage("Error\nUnable to create the output file:\n" + e);
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
			alertMessage("Success\nRecorded " + ((fileCounter * 10000) + recordCounter) + " entries to " + (fileCounter + 1) + " TXT file(s)");
		} catch (Exception e) {
			println(e);
			alertMessage("Error\nUnable to save the output file:\n" + e);
		}

		outputfile = "No File Set";
		if (tabIsVisible) redrawUI = true;
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

		serialBuffer.append(inputData, graphable);
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
			//if (serialBuffer.size() >= maxBuffer) {
			//	serialBuffer.remove(0);
			//}
		}

		if (!serialBuffer.getVisibility() && graphable) {
			return;
		} else if (tabIsVisible) {
			drawNewData = true;
		}
	}


	/**
	 * Recover from an error when recording data to file
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
					alertMessage("Warning\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. Data is still being recorded (to a new file)\n3. The files are in the same directory as ProcessingGrapher.exe");
					dataWriter = createWriter(filePath);
					serialBuffer.clear();
					scrollUp = 0;

				// If not, show an error message that the recording has stopped
				} else {
					recordData = false;
					alertMessage("Error - Recording Stopped\nAn issue occurred when trying to save new data to the ouput file.\n1. A backup of all the data has been created\n2. The files are in the same directory as ProcessingGrapher.exe");
				}

			// If we don't want to continue, show a simple error message
			} else {
				recordData = false;
				alertMessage("Error\nAn issue occurred when trying to save new data to the ouput file.\n1. Data recording has been stopped\n2. A backup of all the data has been created\n3. The backup is in the same directory as ProcessingGrapher.exe");
			}

			redrawUI = true;
			drawNewData = true;

		// If something went wrong in the error recovery process, show a critical error message
		} catch (Exception e) {
			dataWriter.close();
			recordData = false;
			redrawUI = true;
			alertMessage("Critical Error\nAn issue occurred when trying to save new data to the ouput file.\nData backup was also unsuccessful, so some data may have been lost...\n" + e);
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

		if (menuLevel == 0)	menuHeight = round((15 + serialTags.size()) * uH);
		else if (menuLevel == 1) menuHeight = round((3 + ports.length) * uH);
		else if (menuLevel == 2) menuHeight = round((3 + baudRateList.length) * uH);
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
				drawDatabox("Start Recording", c_idletab_text, iL, sT + (uH * 6.5), iW, iH, tH);
			} else {
				String[] fileParts = split(outputfile, '/');
				String fileName = fileParts[fileParts.length - 1];

				if (recordData) {
					drawDatabox(fileName, c_idletab_text, iL, sT + (uH * 5.5), iW, iH, tH);
					drawButton("Stop Recording", c_sidebar_accent, iL, sT + (uH * 6.5), iW, iH, tH);
				} else {
					drawDatabox(fileName, c_sidebar_text, iL, sT + (uH * 5.5), iW, iH, tH);
					drawButton("Start Recording", c_sidebar_button, iL, sT + (uH * 6.5), iW, iH, tH);
				}
			}

			// Input Data Columns
			drawHeading("Terminal Options", iL, sT + (uH * 8), iW, tH);
			if (recordData) drawDatabox("Clear Terminal", c_idletab_text, iL, sT + (uH * 9), iW, iH, tH);
			else drawButton("Clear Terminal", c_sidebar_button, iL, sT + (uH * 9), iW, iH, tH);
			drawButton((autoScroll)? "Autoscroll: On":"Autoscroll: Off", (autoScroll)? c_sidebar_button:c_sidebar_accent, iL, sT + (uH * 10), iW, iH, tH);
			drawButton((serialBuffer.getVisibility())? "Graph Data: Shown":"Graph Data: Hidden", (serialBuffer.getVisibility())? c_sidebar_button:c_sidebar_accent, iL, sT + (uH * 11), iW, iH, tH);

			// Input Data Columns
			drawHeading("Colour Tags", iL, sT + (uH * 12.5), iW, tH);
			drawButton("Add New Tag", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);

			float tHnow = 14.5;

			// List of Data Columns
			for (SerialTag curTag : serialTags) {
				// Column name
				drawDatabox(curTag.tagText, iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

				// Remove column button
				drawButton("✕", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

				// Swap column with one being listed above button
				color buttonColor = curTag.tagColor;
				drawButton("", c_sidebar, buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

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
			
			// If text is selected, overwrite it
			serialTextSelection.setVisibility(false);
			if (inputTextSelection.valid) {
				String msg = msgText.substring(0,inputTextSelection.startChar) + msgText.substring(inputTextSelection.endChar,msgText.length());
				msgText = msg;
				cursorPosition = inputTextSelection.startChar;
				inputTextSelection.setVisibility(false);
			}

			// Add the new text to the message string
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
			activeArea = 0;
			redrawContent = true;

		// Test for all other keys in a slightly slower switch statement			
		} else {

			switch (keyCodeInt) {
				case ESC:
					if (menuLevel != 0) {
						menuLevel = 0;
						menuScroll = 0;
						redrawUI = true;
					} else if (serialTextSelection.valid) {
						serialTextSelection.setVisibility(false);
						redrawContent = true;
					} else if (inputTextSelection.valid) {
						inputTextSelection.setVisibility(false);
						redrawContent = true;
					}
					break;
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
						if (inputTextSelection.valid) {
							String msg = msgText.substring(0,inputTextSelection.startChar) + msgText.substring(inputTextSelection.endChar,msgText.length());
							msgText = msg;
							cursorPosition = inputTextSelection.startChar;
							inputTextSelection.setVisibility(false);
						} else {
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
						}
						activeArea = 0;
						redrawContent = true;
					}
					break;

				case DELETE:
					if (msgText != "") {
						if (inputTextSelection.valid) {
							String msg = msgText.substring(0,inputTextSelection.startChar) + msgText.substring(inputTextSelection.endChar,msgText.length());
							msgText = msg;
							cursorPosition = inputTextSelection.startChar;
							inputTextSelection.setVisibility(false);
						} else {
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
						}
						activeArea = 0;
						redrawContent = true;
					}
					break;

				case RIGHT:
					if (cursorPosition < msgText.length()) cursorPosition++;
					else cursorPosition = msgText.length();
					serialTextSelection.setVisibility(false);
					activeArea = 0;
					redrawContent = true;
					break;

				case LEFT:
					if (cursorPosition > 0) cursorPosition--;
					else cursorPosition = 0;
					serialTextSelection.setVisibility(false);
					activeArea = 0;
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
						int previousScroll = scrollUp;
						if (scrollUp < serialBuffer.size() - displayRows) scrollUp++;
						else scrollUp = serialBuffer.size() - displayRows;
						drawNewData = true;
						if (previousScroll == 0 && scrollUp > 0) {
							autoScroll = false;
							redrawUI = true;
						}
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
						int previousScroll = scrollUp;
						if (scrollUp > 0) scrollUp--;
						else scrollUp = 0;
						drawNewData = true;
						if (previousScroll > 0 && scrollUp == 0) {
							autoScroll = true;
							redrawUI = true;
						}
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
						int previousScroll = scrollUp;
						if (scrollUp < serialBuffer.size() - displayRows) scrollUp += displayRows;
						if (scrollUp > serialBuffer.size() - displayRows) scrollUp = serialBuffer.size() - displayRows;
						if (previousScroll == 0 && scrollUp > 0) {
							autoScroll = false;
							redrawUI = true;
						}
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
						int previousScroll = scrollUp;
						if (scrollUp > 0) scrollUp -= displayRows;
						if (scrollUp < 0) scrollUp = 0;
						drawNewData = true;
						if (previousScroll > 0 && scrollUp == 0) {
							autoScroll = true;
							redrawUI = true;
						}
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
						autoScroll = true;
						drawNewData = true;
						redrawUI = true;
					}
					break;

				case KeyEvent.VK_HOME:
					// Scroll menu bar
					if (mouseX >= cR && menuScroll != -1) {
						menuScroll = 0;
						redrawUI = true;
					// Scroll serial monitor
					} else {
						int previousScroll = scrollUp;
						scrollUp = serialBuffer.size() - displayRows;
						drawNewData = true;
						autoScroll = false;
						redrawUI = true;
					}
					break;

				case KeyEvent.VK_ALL_CANDIDATES: {
					// Select all - text
					if (activeArea == 0) {
						serialTextSelection.setVisibility(false);
						inputTextSelection.startChar = 0;
						inputTextSelection.endChar = msgText.length();
						cursorPosition = msgText.length();
						inputTextSelection.setVisibility(true);
					} else if (activeArea == 1) {
						inputTextSelection.setVisibility(false);
						serialTextSelection.startLine = 0;
						serialTextSelection.startChar = 0;
						serialTextSelection.endLine = serialBuffer.size() - 1;
						serialTextSelection.endChar = serialBuffer.get(serialTextSelection.endLine).length();
						serialTextSelection.setVisibility(true);
					}
					redrawContent = true;
					break;
				}

				case KeyEvent.VK_COPY: {
					
					if (serialTextSelection.valid) {
						String copyText = "";

						for (int i = serialTextSelection.startLine; i <= serialTextSelection.endLine; i++) {
							String tempString = serialBuffer.get(i);
							if (serialTextSelection.startLine == serialTextSelection.endLine) {
								copyText = tempString.substring(serialTextSelection.startChar, serialTextSelection.endChar);
							} else if (i == serialTextSelection.startLine) {
								if (serialTextSelection.startChar > 0) {
									copyText += tempString.substring(serialTextSelection.startChar) + '\n';
								}
							} else if (i == serialTextSelection.endLine) {
								copyText += tempString.substring(0, serialTextSelection.endChar);
							} else {
								copyText += tempString + '\n';
							}
						}

						//println("Copying: " + copyText);
						StringSelection selection = new StringSelection(copyText);
						Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
						clipboard.setContents(selection, selection);
					}

					else if (inputTextSelection.valid) {
						String copyText = msgText.substring(inputTextSelection.startChar, inputTextSelection.endChar);
						//println("Copying: " + copyText);
						StringSelection selection = new StringSelection(copyText);
						Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
						clipboard.setContents(selection, selection);
					}
					
					break;
				}

				case KeyEvent.VK_PASTE: {
					String clipboardText = getStringClipboard();
					if (clipboardText != null && clipboardText.length() > 0) {
						String msgEnd = "";
						if (cursorPosition == 0) {
							msgEnd = msgText;
							msgText = "";
						} else if (cursorPosition < msgText.length()) {
							msgEnd = msgText.substring(cursorPosition, msgText.length());
							msgText = msgText.substring(0, cursorPosition);
						}
						//println("Pasting: " + clipboardText);
						String clipboardLines[] = clipboardText.split("\\r?\\n");
						for (int i = 0; i < clipboardLines.length - 1; i++) {
							if (serialConnected) {
								serialSend(msgText + clipboardLines[i]);
							}
							msgText = "SENT: " + msgText + clipboardLines[i];
							serialBuffer.append(msgText);
							msgText = "";
						}
						msgText += clipboardLines[clipboardLines.length - 1] + msgEnd;
						cursorPosition = msgText.length() - msgEnd.length();

						inputTextSelection.setVisibility(false);
						redrawContent = true;
					}
					break;
				}
				default:
					//print("Unknown character: ");
					//print(keyChar);
					//print(" ");
					//println(keyCodeInt);
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

		// Scroll down to bottom of serial message button
		if (scrollUp > 0) {
			if ((xcoord > cR - (40*uimult)) && (ycoord > cB - (40*uimult)) && (xcoord < cR - (10*uimult)) && (ycoord < cB - (10*uimult))) {
				scrollUp = 0;
				autoScroll = true;
				redrawUI = true;
				redrawContent = true;
				return;
			}
		}

		// Click on serial monitor scrollbar
		if ((scrollUp != -1) && serialScroll.click(xcoord, ycoord)) {
			sidebarScroll.active(false);
			serialTextSelection.active = false;
			inputTextSelection.active = false;
			startScrolling(true, 0);
			return;
		}

		// Text selection in message area
		if ((ycoord > msgB) && (ycoord < cB - border*1.5)) {
			sidebarScroll.active(false);
			serialScroll.active(false);
			inputTextSelection.setVisibility(false);
			activeArea = 1;
			serialTextSelectionCalculation(xcoord, ycoord, true);
			startScrolling(true, 1);
			redrawContent = true;
		}

		// Text selection in input area
		if ((ycoord > cT) && (ycoord < msgB)) {
			sidebarScroll.active(false);
			serialScroll.active(false);
			serialTextSelection.setVisibility(false);
			activeArea = 0;
			inputTextSelectionCalculation(xcoord, ycoord, true);
			startScrolling(true, 1);
			redrawContent = true;
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

		String[] ports = Serial.list();

		// Click on sidebar menu scroll bar
		if ((menuScroll != -1) && sidebarScroll.click(xcoord, ycoord)) {
			serialScroll.active(false);
			serialTextSelection.active = false;
			inputTextSelection.active = false;
			startScrolling(false);
		}

		// Root menu level
		if (menuLevel == 0) {

			// COM Port Number
			if (menuXYclick(xcoord, ycoord, sT, uH, iH, 1, iL, iW)) {
				menuLevel = 1;
				menuScroll = 0;
				redrawUI = true;
			}

			// COM Port Baud Rate
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 2, iL, iW)){
				menuLevel = 2;
				menuScroll = 0;
				redrawUI = true;
			}

			// Connect to COM port
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 3, iL, iW)){
				setupSerial();
			}

			// Select output file name and directory
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 5.5, iL, iW)){
				if (!recordData) {
					outputfile = "";
					selectOutput("Select a location and name for the output *.TXT file", "fileSelected");
				}
			}
			
			// Start recording data and saving it to a file
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 6.5, iL, iW)) {
				if(recordData) {
					stopRecording();
				} else if(outputfile != "" && outputfile != "No File Set") {
					startRecording();
				}
			}

			// Clear the terminal buffer
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 9, iL, iW)) {
				if (!recordData) {
					serialBuffer.clear();
					serialBuffer.append("--- PROCESSING SERIAL MONITOR ---");
					scrollUp = 0;
					drawNewData = true;
				}
			}

			// Turn autoscrolling on/off
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 10, iL, iW)) {
				autoScroll = !autoScroll;
				redrawUI = true;
			}

			// Turn graphable numbers on/off
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 11, iL, iW)) {
				serialBuffer.setVisibility(!serialBuffer.getVisibility());
				redrawContent = true;
				redrawUI = true;
			}

			// Add a new colour tag column
			else if (menuXYclick(xcoord, ycoord, sT, uH, iH, 13.5, iL, iW)) {
				final String colname = myShowInputDialog("Add a new Colour Tag","Keyword Text:","");
				if (colname != null && colname.length() > 0){
					serialTags.add(new SerialTag(colname, c_colorlist[serialTags.size() % c_colorlist.length]));
					redrawUI = true;
					drawNewData = true;
				}
			}
			
			else {
				float tHnow = 14.5;

				// List of Data Columns
				for(int i = 0; i < serialTags.size(); i++) {

					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {

						// Remove column
						if (menuXclick(xcoord, iL + iW - int(20 * uimult), int(20 * uimult))) {
							serialTags.remove(i);
							redrawUI = true;
							drawNewData = true;
						}

						// Change colour of entry
						else if (menuXclick(xcoord, iL + iW - int(40 * uimult), int(40 * uimult))) {
							previousColor = serialTags.get(i).tagColor;
							hueColor = previousColor;
							newColor = previousColor;
							colorSelector = i;

							menuLevel = 3;
							menuScroll = 0;
							redrawUI = true;
						}

						// Change name of column
						else {
							final String colname = myShowInputDialog("Update the Colour Tag Keyword", "Keyword Text:", serialTags.get(i).tagText);
							if (colname != null && colname.length() > 0){
								serialTags.get(i).tagText = colname;
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
					if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {

						// If the serial port is already connected to a different port, disconnect it
						if (serialConnected && portNumber != i) setupSerial();

						portNumber = i;
						currentPort = portList[portNumber];
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

		// Select a baud rate
		} else if (menuLevel == 2) {
			float tHnow = 1;
			for (int i = 0; i < baudRateList.length; i++) {
				if (menuXYclick(xcoord, ycoord, sT, uH, iH, tHnow, iL, iW)) {
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
				serialTags.get(colorSelector).tagColor = newColor;
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

		// Scroll serial monitor
		} else {
			int previousScroll = scrollUp;
			scrollUp -= round(2 * amount);
			if (scrollUp < 0) scrollUp = 0;
			else if (scrollUp > serialBuffer.size() - displayRows) scrollUp = serialBuffer.size() - displayRows;
			drawNewData = true;
			if (previousScroll == 0 && scrollUp > 0) {
				autoScroll = false;
				redrawUI = true;
			} else if (previousScroll > 0 && scrollUp == 0) {
				autoScroll = true;
				redrawUI = true;
			}
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
		if (serialScroll.active()) {
			int previousScroll = scrollUp;
			scrollUp = serialScroll.move(xcoord, ycoord, scrollUp, 0, serialBuffer.size() - displayRows);
			if (previousScroll != scrollUp) redrawContent = true;
			if (previousScroll == 0 && scrollUp > 0) {
				autoScroll = false;
				redrawUI = true;
			} else if (previousScroll > 0 && scrollUp == 0) {
				autoScroll = true;
				redrawUI = true;
			}
		}

		else if (sidebarScroll.active()) {
			int previousScroll = menuScroll;
			menuScroll = sidebarScroll.move(xcoord, ycoord, menuScroll, 0, menuHeight - (height - cT));
			if (previousScroll != menuScroll) redrawUI = true;
		}

		else if (serialTextSelection.active) {
			if (serialTextSelectionCalculation(xcoord, ycoord, false)) {
				drawNewData = true;
			}
		}

		else if (inputTextSelection.active) {
			if (inputTextSelectionCalculation(xcoord, ycoord, false)) {
				redrawContent = true;
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
		if (serialConnected) setupSerial();
	}


	/**
	 * New serial monitor text selection calculations
	 */
	boolean serialTextSelectionCalculation(int xcoord, int ycoord, boolean selectionStart) {
		
		// Figure out where in the serial messages was clicked
		int selectedLine = displayRows - ((ycoord - msgB) / yTextHeight);

		// Apply limits and perform automatic scrolling of text is mouse exceeds bounds
		if (selectedLine > displayRows) {
			if (!selectionStart && (scrollUp < serialBuffer.size() - displayRows)) {
				scrollUp++;
				selectedLine = displayRows + 1;
			} else {
				selectedLine = displayRows;
			}
		} else if (selectedLine < 0) {
			if (!selectionStart && (scrollUp > 0)) {
				scrollUp--;
				selectedLine = 0;
			} else {
				selectedLine = 0;
			}
		}

		// Get the actual index of the serial message text
		int textIndex = (serialBuffer.size() - selectedLine - scrollUp);
		if (textIndex < 0) textIndex = 0;
		else if (textIndex >= serialBuffer.size()) textIndex = serialBuffer.size() - 1;

		// Retreive the text in the selected row
		final String textRow = serialBuffer.get(textIndex);

		// Calculate the width of a single character, and the maximum row width (note: assumes mono-spaced font)
		textFont(mono_font);
		final float charWidth = textWidth("a");
		final int maxChars = floor((cR - 2*cL - 5*border) / charWidth);
		textFont(base_font);

		// Figure out which character was selection
		int selectedChar = int((xcoord - (cL + 2*border)) / charWidth) + 1;
		if (selectionStart) selectedChar--;
		if (selectedChar < 0) selectedChar = 0;

		// Ensure character is within bounds
		else if (selectedChar >= textRow.length()) selectedChar = textRow.length();
		else if (selectedChar > maxChars) selectedChar = maxChars;

		return serialTextSelection.setNewSelection(selectionStart, textIndex, selectedChar);
	}


	/**
	 * New serial monitor text selection calculations
	 */
	boolean inputTextSelectionCalculation(int xcoord, int ycoord, boolean selectionStart) {

		// Calculate the width of a single character, and the maximum row width (note: assumes mono-spaced font)
		textFont(mono_font);
		final float charWidth = textWidth("a");
		final int maxChars = floor((cR - 2*cL - 5*border) / charWidth);
		textFont(base_font);

		// Figure out which character was selection
		int selectedChar = msgTextBounds[0] + int((xcoord - (cL + 4*msgBorder + msgBtnSize)) / charWidth);

		// Apply limits and perform automatic scaling
		if (selectedChar < msgTextBounds[0]) {
			if (msgTextBounds[0] > 0) {
				msgTextBounds[0]--;
				msgTextBounds[1]--;
				if (cursorPosition > msgTextBounds[1]) cursorPosition--;
			}
			selectedChar = msgTextBounds[0];
		} else if (selectedChar > msgTextBounds[1]) {
			if (msgTextBounds[1] < msgText.length()) {
				msgTextBounds[0]++;
				msgTextBounds[1]++;
				if (cursorPosition < msgTextBounds[0]) cursorPosition++;
			}
			selectedChar = msgTextBounds[1];
		}

		if (selectionStart) {
			cursorPosition = selectedChar;
		}

		return inputTextSelection.setNewSelection(selectionStart, 0, selectedChar);
	}


	/**
	 * Data structure to store info related to each colour tag
	 */
	class SerialTag {
		public String tagText;
		public color tagColor;

		/**
		 * Constructor
		 * 
		 * @param  setText  The keyword text which is search for in the serial data
		 * @param  setColor The colour which all lines containing that text will be set
		 */
		SerialTag(String setText, color setColor) {
			tagText = setText;
			tagColor = setColor;
		}
	}


	/**
	 * Data structure to store info related to selected/highlighted text
	 */
	class TextSelection {
		public int startLine = 0;
		public int startChar = 0;
		public int endLine = 0;
		public int endChar = 0;
		public boolean active = false;
		public boolean valid = false;
		private boolean inverted = false;


		/**
		 * Enable or disable the text selection
		 */ 
		public void setVisibility(boolean selectionState) {
			if (selectionState) {
				valid = true;
			} else {
				valid = false;
				active = false;
				inverted = false;
			}
		}

		/**
		 * Set a new starting or end position for the selection
		 * @param  selectionStart  True = start position of selection, False = new end position
		 * @param  newLine         Line index of the new selection position
		 * @param  newChar         Character index of the new selection position
		 */
		public boolean setNewSelection(boolean selectionStart, int newLine, int newChar) {

			if (this.inverted && newLine == this.startLine && newChar == this.startChar) return false;
			else if (!this.inverted && newLine == this.endLine && newChar == this.endChar) return false;

			// If the supplied position related to the start position of the selection
			if (selectionStart) {
				this.startLine = newLine;
				this.startChar = newChar;
				this.endLine = newLine;
				this.endChar = newChar;
				this.valid = false;

			// If the end position of the selection needs to be updated
			} else {

				// Figure out if the selection direction needs to be switched
				if (!this.inverted && (newLine < this.startLine || (newLine == this.startLine && newChar < this.startChar))) {
					this.inverted = true;
					this.endLine = this.startLine;
					this.endChar = this.startChar;
				} else if (this.inverted && (newLine > this.endLine || (newLine == this.endLine && newChar > this.endChar))) {
					this.inverted = false;
					this.startLine = this.endLine;
					this.startChar = this.endChar;
				}

				// Save the new position in the variables
				if (this.inverted) {
					this.startLine = newLine;
					this.startChar = newChar;
				} else {
					this.endLine = newLine;
					this.endChar = newChar;
				}

				if (this.endLine > this.startLine || this.endChar > this.startChar) {
					this.valid = true;
				}
			}

			this.active = true;
			return true;
		}
	}


	/**
	 * Data structure to store serial messages and other related info
	 */
	class SerialMessages {
		private int totalMessagesLength;
		private int lookupTableLength;
		private int maximumLength;

		private boolean showAllMessages;

		private int bufferEndIdx;
		private int tableStartIdx;
		private int tableEndIdx;

		private StringList serialMessagesBuffer; //!< Buffer which contains all received serial messages
		private IntList textLookupTable;         //!< Table containing indices to all non-graphable serial messages

		/**
		 * Constructor
		 * @param  maxLength Maximum number of entries in the serial buffer
		 */
		SerialMessages(int maxLength) {
			this.bufferEndIdx = 0;
			this.tableStartIdx = 0;
			this.tableEndIdx = 0;
			this.totalMessagesLength = 0;
			this.lookupTableLength = 0;
			this.showAllMessages = true;
			this.maximumLength = maxLength;
			int initialLength = 1000;
			if (initialLength > maxLength) initialLength = maxLength;
			this.serialMessagesBuffer = new StringList(initialLength);
			this.textLookupTable = new IntList(initialLength);
		}

		/**
		 * Get the value at the specific index
		 * @param  index The index at which to retrieve the value
		 * @return The requested serial message
		 */
		public String get(int index) {
			// If reading from the serial messages buffer directly
			if (showAllMessages) {
				// Check that the requested index is within bounds
				if (index < totalMessagesLength) {
					// If buffer is full, ensure values wrap around properly
					if (totalMessagesLength == maximumLength) {
						index += bufferEndIdx;
						if (index >= totalMessagesLength) index -= totalMessagesLength;
					}
					return serialMessagesBuffer.get(index);
				}
			// If only showing non-graphable results, read from the lookup table
			} else {
				// Check that the requested index is within bounds
				if (index < lookupTableLength) {
					index += tableStartIdx;
					if (index >= textLookupTable.size()) index -= textLookupTable.size();
					return serialMessagesBuffer.get(textLookupTable.get(index));
				}
			}
			return null;
		}

		/**
		 * Get the number of items in the list
		 * @return The length of the list (if disabled, graphable entries are excluded)
		 */
		public int size() {
			if (showAllMessages) return totalMessagesLength;
			return lookupTableLength;
		}

		/**
		 * Clear all items from the list
		 */
		public void clear() {
			totalMessagesLength = 0;
			bufferEndIdx = 0;
			tableStartIdx = 0;
			tableEndIdx = 0;
			lookupTableLength = 0;
		}

		/**
		 * Read whether all messages are being shown, or just the non-graphable ones
		 * @return True = all messages shown, false = non-graphable messages shown
		 */
		public boolean getVisibility() {
			return showAllMessages;
		}

		/**
		 * Set whether all messages will be shown, or only the non-graphable ones
		 * @param  setState True = all messages shown, false = only non-graphable messages shown
		 */
		public void setVisibility(boolean setState) {
			showAllMessages = setState;
		}

		/**
		 * Add a new serial message to the list
		 * @param  message   The serial message to add
		 * @param  graphable Whether the message only contains numbers and can be graphed
		 */
		public void append(String message, boolean graphable) {
			// If list hasn't reached its max length, append the new value
			if (totalMessagesLength < maximumLength) {
				if (totalMessagesLength < serialMessagesBuffer.size()) {
					serialMessagesBuffer.set(bufferEndIdx, message);
					if (!graphable) textLookupTable.set(tableEndIdx, bufferEndIdx);
				} else {
					serialMessagesBuffer.append(message);
					textLookupTable.append(0);
					if (!graphable) textLookupTable.set(tableEndIdx, bufferEndIdx);
				}

				totalMessagesLength++;
				bufferEndIdx++;
				if (!graphable) {
					tableEndIdx++;
					lookupTableLength++;
				}

			// Otherwise overwrite oldest item in list in a circular manner
			} else {
				int firstItem = bufferEndIdx;
				if (firstItem >= serialMessagesBuffer.size()) firstItem = 0;
				
				if (textLookupTable.get(tableStartIdx) == firstItem) {
					lookupTableLength--;
					tableStartIdx++;
					if (tableStartIdx >= textLookupTable.size()) tableStartIdx = 0;
				}

				// Add the item to the list
				serialMessagesBuffer.set(firstItem, message);

				if (!graphable) {
					if (tableEndIdx >= textLookupTable.size()) tableEndIdx = 0;
					textLookupTable.set(tableEndIdx++, firstItem);
					lookupTableLength++;
				}

				bufferEndIdx = firstItem + 1;
			}
		}

		/**
		 * Add a new serial message to the list
		 * @note This is an overload function where it is assumed the message cannot be plotted on a graph
		 * @see  void append(String message, boolean graphable)
		 */
		public void append(String message) {
			append(message, false);
		}
	}

	/**
	 * Class to deal with highlighting text in the serial monitor
	 */
	// class TextHighlight {
	// 	private boolean active;
	// 	private int startChar;
	// 	private int endChar;

	// 	/**
	// 	 * Constructor
	// 	 */
	// 	TextHighlight() {
	// 		active = false;
	// 		startChar = 0;
	// 		endChar = 0;
	// 	}

	// 	/**
	// 	 * Check if mouse has clicked on the some text
	// 	 * 
	// 	 * @param  xcoord Mouse x-axis coordinate
	// 	 * @param  ycoord Mouse y-axis coordinate
	// 	 * @return True if mouse has clicked on scrollbar, false otherwise
	// 	 */
	// 	boolean click(int xcoord, int ycoord) {

	// 	}

	// }
}
