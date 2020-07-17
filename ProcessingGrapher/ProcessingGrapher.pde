/* * * * * * * * * * * * * * * * * * * * * * *
 * PROCESSING GRAPHER
 *
 * Code by: Simon Bluett
 * Email:   hello@chillibasket.com
 * Date:    17th July 2020
 * Version: 1.2
 * Copyright (C) 2020, GPL v3
 * * * * * * * * * * * * * * * * * * * * * * */

// Swing for input popups
import static javax.swing.JOptionPane.*;
import processing.serial.*;

// Legacy imports - if no bugs pop up, then remove
import java.io.File;
import javax.swing.JFrame;
import java.awt.Dimension;
import processing.awt.PSurfaceAWT.SmoothCanvas;


// -------- UI APPEARANCE SETTINGS ---------------------------------------------
// UI Scaling Options (eg. 0.6 = tiny, 1.0 = normal, 1.4 = huge)
float uimult = 1.0;

// Fonts
String programFont = "Lucida Sans";
String terminalFont = "Monaco";

// Predefined colors
color c_white = color(255, 255, 255);
color c_blue = color(96, 200, 220);
color c_purple = color(147, 111, 212);
color c_red = color(208, 38, 98);
color c_yellow = color(215, 196, 96);
color c_green = color(35, 205, 65);
color c_orange = color(230, 85, 37);
color c_lightgrey = color(134, 134, 138);
color c_grey = color(111, 108, 90);
color c_darkgrey = color(49, 50, 44);

// UI colors
color c_background = color(39, 40, 34);
color c_tabbar = color(23, 24, 20);
color c_tabbar_h = color(19, 19, 18);
color c_idletab = color(61, 61, 59);
color c_tabbar_text = c_white;
color c_sidebar = color(87, 87, 87);
color c_sidebar_h = color(125, 125, 125);
color c_sidebar_heading = c_yellow;
color c_sidebar_text = c_white;
color c_sidebar_button = c_lightgrey;
color c_terminal_text = c_lightgrey;
color c_message_text = c_white;

// Graph color list
color[] c_colorlist = {c_blue, c_purple, c_red, c_yellow, c_green, c_orange};

// Default Window Size
int lastWidth = 1000;
int lastHeight = 700;

// Size Values
int tabWidth = 90;
int tabHeight = 30;
int sidebarWidth = 150;
int sideItemHeight = 30;
int bottombarHeight = 20;
// -----------------------------------------------------------------------------

// Serial Port Variables
Serial myPort;
int portNumber = 0;
int baudRate = 115200;
boolean serialConnected = false;

// Drawing Booleans
boolean redrawUI = true;
boolean redrawAlert = false;
boolean redrawContent = true;
boolean drawNewData = false;

// Interaction Booleans
boolean textInput = false;

// Tab Bar
ArrayList<TabAPI> tabObjects = new ArrayList<TabAPI>();
int currentTab = 0;

// Fonts
PFont base_font;
PFont mono_font;

// Alert Messages
int alertWidth = 300;
int alertHeight = 150;
String alertHeading = "";
boolean alertActive = false;


/*********************************************
 * Setup
 *********************************************/
void setup() {
	size(1000, 700);

	// These lines implement a minimum window size
	SmoothCanvas sc = (SmoothCanvas) getSurface().getNative();
	JFrame jf = (JFrame) sc.getFrame();
	Dimension d = new Dimension(500, 500);
	jf.setMinimumSize(d);
	
	// Set up the canvas
	surface.setResizable(true);
	background(c_background);
	frameRate(60);

	// Initialise the fonts
	base_font = createFont(programFont, 12*uimult);
	mono_font = createFont(terminalFont, 12*uimult);
	
	// Calculate screen size of the tab content area
	int tabWidth = round(width - (sidebarWidth * uimult));
	int tabTop = round(tabHeight * uimult);
	int tabBottom = round(height - (bottombarHeight * uimult));

	// Define all the tabs here
	tabObjects.add(new SerialMonitor("Serial", 0, tabWidth, tabTop, tabBottom));
	tabObjects.add(new LiveGraph("Live Graph", 0, tabWidth, tabTop, tabBottom));
	tabObjects.add(new FileGraph("File Graph", 0, tabWidth, tabTop, tabBottom));
	
	delay(20);
}


/*********************************************
 * Draw
 *********************************************/
void draw() {
	// Redraw the content area elements
	if (redrawContent){
		TabAPI curTab = tabObjects.get(currentTab);
		curTab.drawContent();
		redrawContent = false;
	}

	// Draw new data in the content area
	if (drawNewData) {
		TabAPI curTab = tabObjects.get(currentTab);
		curTab.drawNewData();
		drawNewData = false;
	}
	
	// Redraw the UI elements (right and top bars)
	if (redrawUI){
		drawTabs(currentTab);
		drawSidebar();
		redrawUI = false;
	}

	// Redraw the alert message
	if(redrawAlert){
		drawAlert();
		redrawAlert = false;
	}

	// If the window is resized, redraw all elements at the new size
	if ((lastWidth != width) || (lastHeight != height)){
		redrawUI = true;
		redrawContent = true;
		lastWidth = width;
		lastHeight = height;
		for (TabAPI curTab : tabObjects) {
			curTab.changeSize(0, round(width - (sidebarWidth * uimult)), round(tabHeight * uimult), round(height - (bottombarHeight * uimult)));
		}
	}
}


/*********************************************
 * Draw the Tabs Top-Bar
 *********************************************/
void drawTabs (int highlight) {

	// Setup drawing parameters
	rectMode(CORNER);
	noStroke();
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);

	// Tab Bar
	fill(c_tabbar);
	rect(0, 0, width, tabHeight * uimult);
	fill(c_tabbar_h);
	rect(0, (tabHeight - 1) * uimult, width, 1 * uimult);

	// Tab Buttons
	int i = 0;
	for(TabAPI curTab : tabObjects){
		if(highlight == i){
			fill(c_background);
			rect((i * tabWidth) * uimult, 0, (tabWidth - 1) * uimult, (tabHeight) * uimult);
			fill(c_red);
			rect((i * tabWidth) * uimult, 0, (tabWidth - 1) * uimult, 4 * uimult);
		} else {
			fill(c_idletab);
			rect((i * tabWidth) * uimult, 0, (tabWidth - 1) * uimult, (tabHeight - 1) * uimult);
		}
		fill(c_tabbar_text);
		text(curTab.getName(), (i * tabWidth) * uimult, 0, (tabWidth - 1) * uimult, tabHeight * uimult);
		i++;
	}
}


/*********************************************
 * Draw the Side Bar & Bottom Bar
 *********************************************/
void drawSidebar () {

	// Setup drawing parameters
	rectMode(CORNER);
	noStroke();
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);

	// Calculate sizing of sidebar
	int sT = round(tabHeight * uimult);
	int sL = round(width - ((sidebarWidth - 1) * uimult));
	int sW = round((sidebarWidth - 1) * uimult);
	int sH = height - sT;

	// Bottom info area
	fill(c_tabbar);
	rect(0, height - (bottombarHeight * uimult), width - sW, bottombarHeight * uimult);
	fill(c_tabbar_h);
	rect(0, height - (bottombarHeight * uimult), width - sW, 1 * uimult);

	// Sidebar
	fill(c_sidebar);
	rect(sL, sT, sW, sH);
	fill(c_sidebar_h);
	rect(width - (sidebarWidth * uimult), sT, 1 * uimult, sH);
	
	// Draw sidebar elements specific to the current tab
	TabAPI curTab = tabObjects.get(currentTab);
	curTab.drawSidebar();
}


/*********************************************
 * Sidebar Drawing Functions
 *********************************************/
// Draw a sidebar heading
void drawText(String text, color textcolor, float lS, float tS, float iW, float tH) {
	textAlign(LEFT, CENTER);
	textSize(12 * uimult);
	textFont(base_font);
	fill(textcolor);
	text(text, lS, tS, iW, tH);
}

void drawHeading(String text, float lS, float tS, float iW, float tH){
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);
	textFont(base_font);
	fill(c_sidebar_heading);
	text(text, lS, tS, iW, tH);
}

// Draw a sidebar button
void drawButton(String text, color boxcolor, float lS, float tS, float iW, float iH, float tH){
	drawButton(text, c_sidebar_text, boxcolor, lS, tS, iW, iH, tH);
}

void drawButton(String text, color textcolor, color boxcolor, float lS, float tS, float iW, float iH, float tH){
	rectMode(CORNER);
	noStroke();
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);
	textFont(base_font);
	fill(boxcolor);
	rect(lS, tS, iW, iH);
	fill(textcolor);
	text(text, lS, tS, iW, tH);
}

// Draw a sidebar databox
void drawDatabox(String text, float lS, float tS, float iW, float iH, float tH){
	drawDatabox(text, c_sidebar_text, lS, tS, iW, iH, tH);
}

void drawDatabox(String text, color textcolor, float lS, float tS, float iW, float iH, float tH){
	rectMode(CORNER);
	noStroke();
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);
	textFont(base_font);
	fill(c_sidebar_button);
	rect(lS, tS, iW, iH);
	fill(c_sidebar);
	rect(lS + (1 * uimult), tS + (1 * uimult), iW - (2 * uimult), iH - (2 * uimult));
	fill(textcolor);
	text(text, lS, tS, iW, tH);
}


/*********************************************
 * Draw the Alert Box
 *********************************************/
void drawAlert () {
	alertActive = true;

	// Setup drawing parameters
	rectMode(CORNER);
	noStroke();
	textAlign(CENTER, CENTER);
	textSize(12 * uimult);
	textFont(base_font);

	// Slightly lighten the background content
	fill(c_white, 50);
	rect(0, 0, width, height);

	// Draw the box and the text
	fill(c_tabbar_h);
	rect((width / 2) - (alertWidth * uimult / 2), (height / 2) - (alertHeight * uimult / 2), alertWidth * uimult, alertHeight * uimult);
	fill(c_tabbar);
	rect((width / 2) - ((alertWidth - 2) * uimult / 2), (height / 2) - ((alertHeight - 2) * uimult / 2), (alertWidth - 2) * uimult, (alertHeight - 2) * uimult);
	fill(c_white);
	text(alertHeading, (width / 2) - ((alertWidth - 2) * uimult / 2), (height / 2) - ((alertHeight - 2) * uimult / 2), (alertWidth - 2) * uimult, (alertHeight - 2) * uimult);
}


/*********************************************
 * Mouse Click Handler
 *********************************************/
void mousePressed(){ 

	if (!alertActive) {

		// If mouse is hovering over the content area
		if((mouseX > 0) && (mouseX < int(width - (sidebarWidth * uimult))) && (mouseY > int(tabHeight * uimult)) && (mouseY < int(height - (bottombarHeight * uimult)))){
			TabAPI curTab = tabObjects.get(currentTab);
			curTab.getContentClick(mouseX, mouseY);
		} else cursor(ARROW);

		// If mouse is hovering over a tab button
		if ((mouseY > 0) && (mouseY < tabHeight*uimult)){
			for(int i = 0; i < tabObjects.size(); i++){
				if ((mouseX > i*tabWidth*uimult) && (mouseX < (i+1)*tabWidth*uimult)) {
					currentTab = i;
					redrawUI = redrawContent = true;
				}
			}
		}

		// If mouse is hovering over the side bar
		if ((mouseX > width - (sidebarWidth * uimult)) && (mouseX < width)){
			TabAPI curTab = tabObjects.get(currentTab);
			curTab.mclickSBar(mouseX, mouseY);
		}

	// If an alert is active, any mouse click hides the nofication
	} else {
		alertActive = false;
		redrawUI = true;
		redrawContent = true;
	}
}


/*********************************************
 * Mouse Wheel Scroll Handler
 *********************************************/
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  
  if (abs(e) > 0) {
  	
  	// If mouse is hovering over the content area
  	if ((mouseX > 0) && (mouseX < round(width - (sidebarWidth * uimult))) && (mouseY > round(tabHeight * uimult)) && (mouseY < round(height - (bottombarHeight * uimult)))){
  		TabAPI curTab = tabObjects.get(currentTab);
  		curTab.scrollWheel(e);
  	}
  
  	// If mouse is hovering over the side bar
  	if ((mouseX > width - (sidebarWidth * uimult)) && (mouseX < width)){
  		TabAPI curTab = tabObjects.get(currentTab);
  		curTab.scrollWheel(e);
  	}
  }
}


/*********************************************
 * Keyboard Button Handler
 *********************************************/
void keyPressed() {
	TabAPI curTab = tabObjects.get(currentTab);
	curTab.keyboardInput(key);
}


/*********************************************
 * Setup Serial Communication
 *********************************************/
void setupSerial () {

	if (!serialConnected) {

		// Get a list of the available serial ports
		String[] ports = Serial.list();

		// If no ports are available
		if(ports.length == 0) {

			alertHeading = "Error - No serial ports available";
			redrawAlert = true;

		// If the port number we want to use is not in the list
		} else if((portNumber < 0) || (ports.length <= portNumber)) {

			alertHeading = "Error - Invalid port number selected";
			redrawAlert = true;

		// Try to connet to the serial port
		} else {
			try {
				myPort = new Serial(this, Serial.list()[portNumber], baudRate);
				myPort.bufferUntil('\n');
				serialConnected = true;
				redrawUI = true;
			} catch (Exception e){
				alertHeading = "Error connecting to port: " + e;
				redrawAlert = true;
			}
		}

	// Disconnect from serial port
	} else {
		myPort.clear();
		myPort.stop();
		serialConnected = false;
		redrawUI = true;
	}
}


/*********************************************
 * Receive Serial Message Handler
 *********************************************/
void serialEvent (Serial myPort) {
	try {
		String inString = myPort.readStringUntil('\n');

		// Send the data over to all the tabs
		if (inString != null) {
			for (TabAPI curTab : tabObjects) {
				curTab.parsePortData(inString);
			}
		}
	} catch (Exception e){
		alertHeading = "Error reading port: " + e;
		redrawAlert = true;
	}
}


/*********************************************
 * Send Serial Message
 *********************************************/
void serialSend (String message) {
	if (serialConnected) {
		myPort.write(message);
	}
}


/*********************************************
 * Get the File Selected in the Input Dialog
 *********************************************/
void fileSelected(File selection) {

	// If a file was actually selected
	if (selection != null) {

		// Send it over to the tabs that require it
		for (TabAPI curTab : tabObjects) {
			if(curTab.getOutput() == "") {
				curTab.setOutput(selection.getAbsolutePath());
			}
		}

	} else {
		for (TabAPI curTab : tabObjects) {
			if(curTab.getOutput() == "") {
				curTab.setOutput("No File Set");
			}
		}
	}
	redrawUI = true;
}


/*********************************************
 * Variable Modification Functions
 *********************************************/
// Increment a number
float increment(float number){
	if (abs(number) >= 10 && abs(number) < 100) {
		number = round(number + 1);
	} else if (abs(number) < 10) {
		number *= 10;
		number = increment(number);
		number /= 10;
	} else {
		number /= 10;
		number = increment(number);
		number *= 10;
	}
	return number;
}

// Decrement a number
float decrement(float number, boolean zero){
	if (zero && (number < 0)) number = 0;
	else {
		if (abs(number) > 10 && abs(number) <= 100) {
			number = round(number - 1);
		} else if (abs(number) <= 10) {
			number *= 10;
			number = decrement(number,false);
			number /= 10;
		} else {
			number /= 10;
			number = decrement(number,false);
			number *= 10;
		}
	}
	return number;
}

float ceilToSigFig(float num, int n) {
	return (float) ceilToSigFig((double) num, n);
}

double ceilToSigFig(double num, int n) {
    if(num == 0) {
        return 0;
    }

    final double d = Math.ceil(Math.log10(num < 0 ? -num: num));
    final int power = n - (int) d;

    final double magnitude = Math.pow(10, power);
    final long shifted = (long) Math.ceil(num*magnitude);
    return shifted/magnitude;
}

float floorToSigFig(float num, int n) {
	return (float) floorToSigFig((double) num, n);
}

double floorToSigFig(double num, int n) {
    if(num == 0) {
        return 0;
    }

    final double d = Math.ceil(Math.log10(num < 0 ? -num: num));
    final int power = n - (int) d;

    final double magnitude = Math.pow(10, power);
    final long shifted = (long) Math.floor(num*magnitude);
    return shifted/magnitude;
}

float roundToSigFig(float num, int n) {
	return (float) roundToSigFig((double) num, n);
}

double roundToSigFig(double num, int n) {
    if(num == 0) {
        return 0;
    }

    final double d = Math.ceil(Math.log10(num < 0 ? -num: num));
    final int power = n - (int) d;

    final double magnitude = Math.pow(10, power);
    final long shifted = Math.round(num*magnitude);
    return shifted/magnitude;
}

// Remove an element from a string array
String[] remove(String[] a, int index){
	for (int i = index + 1; i < a.length; i++) {
		a[i-1] = a[i];
	}
	return shorten(a);
}

// Test if a character is a number
boolean charIsNum(char c) {
	return 48<=c&&c<=57;
}



/******************************************************************************************
 * Abstracted TAB API Interface
 ******************************************************************************************/
interface TabAPI {
	// Name of the tab
	String getName();
	
	// Draw functions
	void drawContent();
	void drawNewData();
	void drawSidebar();
	
	// Mouse clicks
	void mclickSBar (int xcoord, int ycoord);
	void getContentClick (int xcoord, int ycoord);
	void scrollWheel(float e);

	// Keyboard input
	void keyboardInput(char key);
	
	// Change content area size
	void changeSize(int newL, int newR, int newT, int newB);
	
	// Getting new files paths
	String getOutput();
	void setOutput(String newoutput);
	
	// Serial communication
	void parsePortData(String inputData);
}
