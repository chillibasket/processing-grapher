/* * * * * * * * * * * * * * * * * * * * * * *
 * LIVE MAP PLOTTER CLASS
 * implements TabAPI for Processing Grapher
 *
 * Code by: Simon B.
 * Email:   hello@chillibasket.com
 * * * * * * * * * * * * * * * * * * * * * * */

class LiveMap implements TabAPI {


    int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
    Graph graph;

    String name;
    String outputfile;
    String[] dataColumns = {"Path","RFID Tags","Obstacles","Lines"};
    Table dataTable;
    Table obstacles;
    boolean recordData;
    int recordCounter;


    /**********************************
     * Constructor
     **********************************/
    LiveMap(String setname, int left, int right, int top, int bottom) {
        name = setname;
        
        cL = left;
        cR = right;
        cT = top;
        cB = bottom;

        graph = new Graph(cL, cR, cT, cB, 0, 1800, 0, 1800);
        graph.changeGraphDiv(25, 25);
        graph.setSquareGrid(true);
        outputfile = "No File Set";
        recordData = false;
        startRecording();
    }

    String getName() {
        return name;
    }
    
    void drawContent() {
        graph.drawGrid();
        graph.resetGraph();
        plotExistingData();
    }

    void plotExistingData() {
        for (TableRow row : obstacles.rows()) {
            try {
                int type = row.getInt(0);
                float dataX = row.getFloat(1);
                float dataY = row.getFloat(2);
                float x1 = dataX;
                float x2 = dataX;
                float y1 = dataY;
                float y2 = dataY;
                for (int i = 0; i < 1800; i += 72) {
                    if (dataX > i && dataX < i + 72) {
                        x1 = i + 4;
                        x2 = i + 68;
                    }
                    if (dataY > i && dataY < i + 72) {
                        y1 = i + 4;
                        y2 = i + 68;
                    }
                }
                graph.plotRectangle(y1, y2, x1, x2, type);
            } catch (Exception e) {
                println("Error trying to plot file data.");
                println(e);
            }
        }

        for (TableRow row : dataTable.rows()) {
            try {
                float dataX = row.getFloat(0);
                float dataPoint = row.getFloat(1);
                graph.plotData(dataPoint, dataX, 0);
            } catch (Exception e) {
                println("Error trying to plot file data.");
                println(e);
            }
        }
    }

    void drawNewData() {
        drawContent();
    }
    
    /**********************************
     * Change content area size
     **********************************/
    void changeSize(int newL, int newR, int newT, int newB) {
        cL = newL;
        cR = newR;
        cT = newT;
        cB = newB;

        graph.changeSize(cL, cR, cT, cB);
        drawContent();
    }


    /**********************************
     * Change output file location
     **********************************/
    void setOutput(String newoutput) {
        // Ensure file type is *.csv
        int dotPos = newoutput.lastIndexOf(".");
        if (dotPos > 0) newoutput = newoutput.substring(0, dotPos);
        newoutput = newoutput + ".csv";
        outputfile = newoutput;
    }

    String getOutput(){
        return outputfile;
    }

    void startRecording() {
        // Ensure table is empty
        dataTable = new Table();
        obstacles = new Table();

        // Add columns to the table
        dataTable.addColumn("X");
        dataTable.addColumn("Y");
        dataTable.addColumn("Heading");
        obstacles.addColumn("Type");
        obstacles.addColumn("X");
        obstacles.addColumn("Y");

        recordData = true;
        redrawContent = true;
    }

    void saveRecording(){
        recordData = false;
        saveTable(dataTable, outputfile, "csv");
        startRecording();
    }


    /**********************************
     * Parse data from port and plot on graph
     **********************************/
    void parsePortData(String inputData){
        // New XYT coordinates
        if (inputData.charAt(0) == '%') {
            inputData = inputData.substring(1);
            String[] dataArray = split(inputData,',');
    
            // --- Data Recording ---
            if(recordData) {
                TableRow newRow = dataTable.addRow();
                // Go through each data column, and try to parse and add to file
                for(int i = 0; i < dataArray.length; i++){
                    try {
                        float dataPoint = Float.parseFloat(dataArray[i]);
                        newRow.setFloat(i, dataPoint);
                    } catch (Exception e) {
                        print(e);
                    }
                }
            }

            drawNewData = true;

        // New Obstacle or object of interest
        } else if (inputData.charAt(0) == '$') {
            inputData = inputData.substring(1);
            String[] dataArray = split(inputData,',');
    
            // --- Data Recording ---
            if(recordData) {
                TableRow newRow = obstacles.addRow();
                // Go through each data column, and try to parse and add to file
                for(int i = 0; i < dataArray.length; i++){
                    try {
                        float dataPoint = Float.parseFloat(dataArray[i]);
                        newRow.setFloat(i, dataPoint);
                    } catch (Exception e) {
                        print(e);
                    }
                }
            }

            drawNewData = true;
        }
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
        if(outputfile != "" && outputfile != "No File Set") drawButton("Save & Reset Map", c_red, iL, sT + (uH * 6.5), iW, iH, tH);
        else drawButton("Reset Map", c_sidebar_button, iL, sT + (uH * 6.5), iW, iH, tH);

        // Input Data Columns
        drawHeading("Graph Scale", iL, sT + (uH * 8), iW, tH);
        textAlign(LEFT, CENTER);
        drawDatabox("xAxis: " + str(graph.getXscale()), iL, sT + (uH * 9), iW - (40 * uimult), iH, tH);
        drawDatabox("yAxis: " + str(graph.getYscale()), iL, sT + (uH * 10), iW - (40 * uimult), iH, tH);

        // +- Buttons
        drawButton("-", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * 9), 20 * uimult, iH, tH);
        drawButton("-", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
        drawButton("+", c_sidebar_button, iL + iW - (40 * uimult), sT + (uH * 9), 20 * uimult, iH, tH);
        drawButton("+", c_sidebar_button, iL + iW - (40 * uimult), sT + (uH * 10), 20 * uimult, iH, tH);
        fill(c_grey);
        rect(iL + iW - (20 * uimult), sT + (uH * 9) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
        rect(iL + iW - (20 * uimult), sT + (uH * 10) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

        // Input Data Columns
        drawHeading("Data Format", iL, sT + (uH * 11.5), iW, tH);
        //drawDatabox("Rate: " + xRate + "Hz", iL, sT + (uH * 12.5), iW, iH, tH);
        //drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);

        float tHnow = 12.5;

        // List of Data Columns
        for(int i = 0; i < dataColumns.length; i++){
            // Column name
            drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (20 * uimult), iH, tH);

            // Remove column button
            //drawButton("x", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

            // Swap column with one being listed above button
            //color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
            //drawButton("^", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

            // Hide or Show data series
            color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
            drawButton("", buttonColor, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

            //fill(c_grey);
            //rect(iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
            tHnow++;
        }

        textAlign(LEFT, TOP);
        textFont(base_font);
        fill(c_lightgrey);
        text("Output File: " + outputfile, round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult), width - sW - round(10 * uimult), round(bottombarHeight * uimult));
    }


    void keyboardInput(char key) {
        if (key == 's' && serialConnected) {
            final String message = showInputDialog("Serial Message:");
            if (message != null){
                serialSend(message);
            }
        }
    }

    void getContentClick (int xcoord, int ycoord) {
        // Not being used yet
    }
    
    void scrollWheel (float amount) {
        // Not being used yet
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
        int iW = int(sW - (20 * uimult));

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
                startRecording();
            } else if(outputfile != "" && outputfile != "No File Set"){
                saveRecording();
            } else {
                alertHeading = "Error - Please set an output file path";
                redrawAlert = true;
            }
        }

        // Change number of X and Y axis markings
        else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){
            // Decrease x-Axis scale
            if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                graph.changeGraphDiv(graph.getXscale()-1, graph.getYscale());
                redrawContent = redrawUI = true;
            }

            // Increase x-Axis scale
            else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                graph.changeGraphDiv(graph.getXscale()+1, graph.getYscale());
                redrawContent = redrawUI = true;
            }
        }

        else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){
            // Decrease y-Axis scale
            if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                graph.changeGraphDiv(graph.getXscale(), graph.getYscale()-1);
                redrawContent = redrawUI = true;
            }

            // Increase y-Axis scale
            else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                graph.changeGraphDiv(graph.getXscale(), graph.getYscale()+1);
                redrawContent = redrawUI = true;
            }
        }
    }
}
