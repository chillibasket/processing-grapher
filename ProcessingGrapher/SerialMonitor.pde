/* * * * * * * * * * * * * * * * * * * * * * *
 * SERIAL MONITOR CLASS
 * implements TabAPI for Processing Grapher
 *
 * Code by: Simon Bluett
 * Email:   hello@chillibasket.com
 * Copyright (C) 2020, GPL v3
 * * * * * * * * * * * * * * * * * * * * * * */

class SerialMonitor implements TabAPI {

	int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
	int msgB;

	int msgBorder;
	int msgSize;

	String name;
	String outputfile;
	Table dataTable;
	boolean recordData;
	int recordCounter;
	int autoSave;
	int displayRows;
	String[] serialBuffer = {"--- PROCESSING SERIAL MONITOR ---"};
	String[] tagColumns = {"SENT:"};
	String msgText= "";
	int maxBuffer;
	int scrollUp;
	int cursorPosition;
	int[] msgTextBounds = {0,0};


	/**********************************
	 * Constructor
	 **********************************/
	SerialMonitor(String setname, int left, int right, int top, int bottom) {
		name = setname;
		
		cL = left;
		cR = right;
		cT = top;
		cB = bottom;

		msgBorder = round(15 * uimult);
		msgSize = round(2*(msgBorder) + (30 * uimult));

		msgB = cT + msgSize;
		outputfile = "No File Set";
		recordData = false;
		recordCounter = 0;
		maxBuffer = 10000;
		scrollUp = 0;
		displayRows = 0;
		cursorPosition = 0;
	}


	/**********************************
	 * Func   String getName()
	 * Retu   The name of the current object instance
	 */
	String getName() {
		return name;
	}


	/**********************************
	 * Func   void drawContent()
	 * Desc   Draw the content area
	 */
	void drawContent() {
		// Draw the message box
		rectMode(CORNERS);
		noStroke();
		fill(c_background);
		rect(cL, cT, cR, cB);
		fill(c_darkgrey);
		rect(cL + msgBorder, cT + msgBorder, cR - msgBorder, msgB - msgBorder);

		// Message text button
		String msgBtnText = "Send:";
		textSize(12 * uimult);
		textFont(base_font);
		int msgBtnSize = int(textWidth(msgBtnText)); 
		textAlign(LEFT, TOP);
		fill(c_terminal_text);
		text(msgBtnText, cL + 2*msgBorder, cT + msgBorder + round(9 * uimult));
		fill(c_background);
		stroke(c_background);
		strokeWeight(1 * uimult);
		line(cL + 3*msgBorder + msgBtnSize, cT + msgBorder, cL + 3*msgBorder + msgBtnSize, msgB - msgBorder);

		// Ensure cursor is within bounds
		if (cursorPosition < 0) cursorPosition = 0;
		else if (cursorPosition > msgText.length()) cursorPosition = msgText.length();

		// Figure out where the cursor is and how much of the message to show
		textSize(12 * uimult);
		textFont(mono_font);
		if (textWidth(msgText) < cR -cL - 6*msgBorder - msgBtnSize) {
			msgTextBounds[0] = 0;
			msgTextBounds[1] = msgText.length();
		} else if (cursorPosition > msgTextBounds[1]) {
			msgTextBounds[0] += (cursorPosition - msgTextBounds[1] - 1);
			msgTextBounds[1] = cursorPosition;
			while (textWidth(msgText.substring(msgTextBounds[0], msgTextBounds[1])) > cR - cL - 6*msgBorder - msgBtnSize) {
				msgTextBounds[0]++;
			}
		} else if (cursorPosition < msgTextBounds[0]) {
			msgTextBounds[1] -= (msgTextBounds[0] - cursorPosition - 1);
			msgTextBounds[0] = cursorPosition;
			while (textWidth(msgText.substring(msgTextBounds[0], msgTextBounds[1])) > cR - cL - 6*msgBorder - msgBtnSize) {
				msgTextBounds[1]--;
			}
		} else if (msgTextBounds[1] > msgText.length()) {
			msgTextBounds[0] -= (msgTextBounds[1] - msgText.length()) - 1;
			msgTextBounds[1] = msgText.length();
			while (textWidth(msgText.substring(msgTextBounds[0], msgTextBounds[1])) > cR - cL - 6*msgBorder - msgBtnSize) {
				msgTextBounds[0]++;
			}
		}

		// Validate the bounds
		if (msgTextBounds[0] < 0) msgTextBounds[0] = 0;
		if (msgTextBounds[1] < 0) msgTextBounds[1] = 0; 

		// Draw cursor
		fill(c_terminal_text);
		stroke(c_terminal_text);
		rectMode(CORNER);
		rect(cL + 4*msgBorder + msgBtnSize + textWidth(msgText.substring(msgTextBounds[0], cursorPosition)) + round(1*uimult), cT + msgBorder + round(9 * uimult), round(2*uimult), round(13 * uimult));

		// Message text
		rectMode(CORNERS);
		textAlign(LEFT, TOP);
		textSize(12 * uimult);
		textFont(mono_font);
		fill(c_white);
		stroke(c_message_text);
		strokeWeight(1 * uimult);
		text(msgText.substring(msgTextBounds[0], msgTextBounds[1]), cL + 4*msgBorder + msgBtnSize, cT + msgBorder + round(9 * uimult), cR - 2*msgBorder, msgB - msgBorder);

		// Draw arrows to indicate if there is any hidden text
		if (msgTextBounds[0] > 0) {
			int halfWay = cT + msgBorder + round(15 * uimult);
			int frontPos = cL + round(3.25*msgBorder) + msgBtnSize;
			fill(c_terminal_text);
			stroke(c_terminal_text);
			triangle(frontPos, halfWay, frontPos + round(4*uimult), halfWay + round(2*uimult), frontPos + round(4*uimult), halfWay - round(2*uimult));
		}

		if (msgTextBounds[1] < msgText.length()) {
			int halfWay = cT + msgBorder + round(15 * uimult);
			int backPos = cR - round(1.25*msgBorder);
			fill(c_terminal_text);
			stroke(c_terminal_text);
			triangle(backPos, halfWay, backPos - round(4*uimult), halfWay + round(2*uimult), backPos - round(4*uimult), halfWay - round(2*uimult));
		}

		// Draw the terminal
		drawNewData();
	}


	/**********************************
	 * Func   void drawNewData()
	 * Desc   Draw the serial terminal content
	 */
	void drawNewData() {
		// Figure out some measurements
		int border = round(15 * uimult);
		int padding = round(5 * uimult);
		int yTextHeight = round(12 * uimult) + padding;
		int totalHeight = 0;
		displayRows = 0;

		// Clear the content area
		rectMode(CORNER);
		noStroke();
		fill(c_background);
		rect(cL, msgB, cR - cL, cB - msgB);
		
		// Figure out how many rows of text can be displayed
		while (totalHeight < (cB - msgB - border)) {
			if (displayRows >= serialBuffer.length - scrollUp) break;
			else {
				displayRows++;
				totalHeight += yTextHeight;
			}
		}

		// Draw left bar
		fill(c_darkgrey);
		rect(cL, msgB, border/2, totalHeight);

		// Figure out size and position of scroll bar indicator
		int scrollbarSize = round(totalHeight * displayRows / float(serialBuffer.length));
		if (scrollbarSize < yTextHeight) scrollbarSize = yTextHeight;
		int scrollbarOffset = round((totalHeight - scrollbarSize) * (1 - (scrollUp / float(serialBuffer.length - displayRows))));
		fill(c_terminal_text);
		rect(cL, msgB + scrollbarOffset, border/2, scrollbarSize);

		textAlign(LEFT, TOP);
		textSize(12 * uimult);
		textFont(mono_font);
		totalHeight -= yTextHeight;

		// Now print the text
		for (int i = 0; i < displayRows; i++) {

			color textColor = c_terminal_text;
			int textIndex = serialBuffer.length - 1 - i - scrollUp;
			if (textIndex < 0) textIndex = 0;
			String textRow = serialBuffer[textIndex];

			// Firgure out the text colour
			for (int j = 0; j < tagColumns.length; j++) {
				if (textRow.contains(tagColumns[j])) {
					textColor = c_colorlist[j-(c_colorlist.length * floor(j / c_colorlist.length))];
				}
			}
			fill(textColor);

			// Print the text
			text(textRow, cL + 2*border, msgB + totalHeight, cR - cL - 3*border, yTextHeight);
			totalHeight -= yTextHeight;
		}

		textFont(base_font);
	}
	

	/**********************************
	 * Change content area size
	 **********************************/
	void changeSize(int newL, int newR, int newT, int newB) {
		cL = newL;
		cR = newR;
		cT = newT;
		cB = newB;
		msgB = cT + msgSize;
		drawContent();
	}


	/**********************************
	 * Change output file location
	 **********************************/
	void setOutput(String newoutput) {
    	if (newoutput != "No File Set") {
	        // Ensure file type is *.csv
	        int dotPos = newoutput.lastIndexOf(".");
	        if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
	        newoutput = newoutput + ".csv";
	    }
        outputfile = newoutput;
	}

	String getOutput(){
		return outputfile;
	}

	void startRecording() {
		// Ensure table is empty
		dataTable = new Table();

		// Add columns to the table
		if(dataTable.getColumnCount() < 1) dataTable.addColumn("Serial Data");

		recordCounter = 0;
		recordData = true;
		redrawUI = true;
	}

	void stopRecording(){
		recordData = false;
		saveTable(dataTable, outputfile, "csv");
		redrawUI = true;
	}


	/**********************************
	 * Parse data from port and put it into the buffer
	 **********************************/
	void parsePortData(String inputData) {
	
		inputData = inputData.replace("\n", "");
		inputData = inputData.replace("\r", "");

		// --- Data Recording ---
		if(recordData) {
			TableRow newRow = dataTable.addRow();
			try {
				newRow.setString(0, inputData);
			} catch (Exception e) {
				print(e);
			}
			
			// Auto-save recording at set intervals to prevent loss of data
			recordCounter++;
			if(recordCounter >= maxBuffer){
				recordCounter = 0;
				saveTable(dataTable, outputfile, "csv");
			}
		}
		
		// --- Data Buffer ---
    if (inputData.charAt(0) != '%' && inputData.charAt(0) != '$') {
  		if (serialBuffer.length >= maxBuffer) {
  			arrayCopy(serialBuffer, 1, serialBuffer, 0, serialBuffer.length - 1);
  			serialBuffer[serialBuffer.length - 1] = inputData;
  		} else {
  			serialBuffer = append(serialBuffer, inputData);
  		}
    }

		drawNewData = true;
	}


	/**********************************
	 * Draw Side Bar
	 **********************************/
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

		// Connect or Disconnect to COM Port
		drawHeading("COM Port", iL, sT + (uH * 0), iW, tH);
		String[] ports = Serial.list();
		if(ports.length == 0) drawDatabox("Port: None", iL, sT + (uH * 1), iW, iH, tH);
		else if(ports.length <= portNumber) drawDatabox("Port: Invalid", iL, sT + (uH * 1), iW, iH, tH);
		else drawDatabox("Port: " + ports[portNumber], iL, sT + (uH * 1), iW, iH, tH);
		drawDatabox("Baud: " + baudRate, iL, sT + (uH * 2), iW, iH, tH);
		if (serialConnected) drawButton("Disconnect", c_red, iL, sT + (uH * 3), iW, iH, tH);
		else drawButton("Connect", c_sidebar_button, iL, sT + (uH * 3), iW, iH, tH);

		// Save to File
		drawHeading("Save to File", iL, sT + (uH * 4.5), iW, tH);
		drawButton("Set Output File", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
		if(recordData) drawButton("Stop Recording", c_red, iL, sT + (uH * 6.5), iW, iH, tH);
		else drawButton("Start Recording", c_sidebar_button, iL, sT + (uH * 6.5), iW, iH, tH);

		// Input Data Columns
		drawHeading("Serial Buffer", iL, sT + (uH * 8), iW, tH);
		textAlign(LEFT, CENTER);
		drawDatabox("Size: " + str(maxBuffer), iL, sT + (uH * 9), iW - (40 * uimult), iH, tH);
		drawButton("Clear Terminal", c_sidebar_button, iL, sT + (uH * 10), iW, iH, tH);

		// +- Buttons
		drawButton("-", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * 9), 20 * uimult, iH, tH);
		drawButton("+", c_sidebar_button, iL + iW - (40 * uimult), sT + (uH * 9), 20 * uimult, iH, tH);
		fill(c_grey);
		rect(iL + iW - (20 * uimult), sT + (uH * 9) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

		// Input Data Columns
		drawHeading("Colour Tags", iL, sT + (uH * 11.5), iW, tH);
		//drawDatabox("Rate: " + xRate + "Hz", iL, sT + (uH * 12.5), iW, iH, tH);
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

			fill(c_grey);
			rect(iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
			tHnow++;
		}

		textAlign(LEFT, TOP);
		textFont(base_font);
		fill(c_lightgrey);
		text("Output File: " + outputfile, round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult), width - sW - round(10 * uimult), round(bottombarHeight * uimult));
	}


	void keyboardInput(char key) {
		if (key == ENTER || key == RETURN) {
			if (msgText != ""){
				if (serialConnected) {
					serialSend(msgText);
				}
				msgText = "SENT: " + msgText;
				serialBuffer = append(serialBuffer, msgText);
				msgText = "";
				cursorPosition = 0;
				redrawContent = true;
			}
		} else if (key == BACKSPACE) {
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
		} else if (key == DELETE) {
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
		} else if (keyCode == RIGHT) {
			if (cursorPosition < msgText.length()) cursorPosition++;
			else cursorPosition = msgText.length();
			redrawContent = true;
		} else if (keyCode == LEFT) {
			if (cursorPosition > 0) cursorPosition--;
			else cursorPosition = 0;
			redrawContent = true;
		} else if (keyCode == UP) {
			if (scrollUp < serialBuffer.length - displayRows) scrollUp++;
			else scrollUp = serialBuffer.length - displayRows;
			redrawUI = true;
			drawNewData = true;
		} else if (keyCode == DOWN) {
			if (scrollUp > 0) scrollUp--;
			else scrollUp = 0;
			redrawUI = true;
			drawNewData = true;
		} else if (key != CODED) {
			if (cursorPosition < msgText.length()) {
				if (cursorPosition == 0) {
					msgText = key + msgText;
				} else {
					String msg = msgText.substring(0,cursorPosition) + key;
					msg = msg + msgText.substring(cursorPosition,msgText.length());
					msgText = msg;
				}
			} else {
				msgText += key;
			}
			cursorPosition++;
			redrawContent = true;
		}
	}


	void getContentClick (int xcoord, int ycoord) {
		// Nothing here yet  
	}
	
	
	/**********************************
	 * Mouse Click on the SideBar
	 **********************************/
	void mclickSBar (int xcoord, int ycoord) {

		// Coordinate calculation
		int sT = cT;
		int sL = cR;
		int sW = width - cR;
		int sH = height - sT;

		int uH = round(sideItemHeight * uimult);
		int tH = round((sideItemHeight - 8) * uimult);
		int iH = round((sideItemHeight - 5) * uimult);
		int iL = round(sL + (10 * uimult));
		int iW = round(sW - (20 * uimult));

		// COM Port Number
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

		// Connect to COM port
		else if ((mouseY > sT + (uH * 3)) && (mouseY < sT + (uH * 3) + iH)){
			setupSerial();
		}

		// Select output file name and directory
		else if ((mouseY > sT + (uH * 5.5)) && (mouseY < sT + (uH * 5.5) + iH)){
			outputfile = "";
			selectInput("Select select a directory and name for output", "fileSelected");
		}
		
		// Start recording data and saving it to a file
		else if ((mouseY > sT + (uH * 6.5)) && (mouseY < sT + (uH * 6.5) + iH)){
			if(recordData){
				stopRecording();
			} else if(outputfile != "" && outputfile != "No File Set"){
				startRecording();
			} else {
				alertHeading = "Error - Please set an output file path";
				redrawAlert = true;
			}
		}

		// Change number of serial buffer
		else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){
			// Decrease serial buffer
			if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
				maxBuffer -= 1;
				if (maxBuffer < 10) maxBuffer = 10;
				redrawUI = true;
			}

			// Increase serial buffer
			else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
				maxBuffer += 1;
				redrawUI = true;
			}
		}

		// Clear the terminal buffer
		else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){
			for (int i = serialBuffer.length - 1; i > 0; i--) {
				serialBuffer = shorten(serialBuffer);
			}
			serialBuffer[0] = "--- PROCESSING SERIAL MONITOR ---";
			scrollUp = 0;
			drawNewData = true;
		}

		// Add a new colour tag column
		else if ((mouseY > sT + (uH * 12.5)) && (mouseY < sT + (uH * 12.5) + iH)){
			final String colname = showInputDialog("Tag Keyword:");
			if (colname != null){
				tagColumns = append(tagColumns, colname);
				redrawUI = true;
				drawNewData = true;
			}
		}
		
		else {
			float tHnow = 13.5;

			// List of Data Columns
			for(int i = 0; i < tagColumns.length; i++){

				if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)){

					// Remove column
					if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
						tagColumns = remove(tagColumns, i);
						redrawUI = true;
						drawNewData = true;
					}

					// Move column up one space
					else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
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
						final String colname = showInputDialog("New Tag Keyword:");
						if (colname != null){
							tagColumns[i] = colname;
							redrawUI = true;
							drawNewData = true;
						}
					}
				}
				
				tHnow++;
			}
		}
	}
	
	/**********************************
	 * Mouse Scrolled
	 **********************************/
	void scrollWheel (float amount) {
		if (amount > 0) {
			scrollUp -= 5;
			if (scrollUp < 0) scrollUp = 0;
			redrawUI = true;
			drawNewData = true;
		} else {
			scrollUp += 5;
			if (scrollUp > serialBuffer.length - displayRows) scrollUp = serialBuffer.length - displayRows;
			redrawUI = true;
			drawNewData = true;
		}
	}       
}
