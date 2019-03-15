class LiveGraph implements TabAPI {


    int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
    Graph graph;

    String name;
    String outputfile;
    String[] dataColumns = {"Input1"};
    Table dataTable;
    boolean recordData;
    int recordCounter;
    int autoSave;
    int xRate;
    boolean autoAxis;
    float[] dataPoints = {0};


    /**********************************
     * Constructor
     **********************************/
    LiveGraph(String setname, int left, int right, int top, int bottom) {
        name = setname;
        
        cL = left;
        cR = right;
        cT = top;
        cB = bottom;

        graph = new Graph(cL, cR, cT, cB, 0, 20, 0, 1000);
        outputfile = "No File Set";
        recordData = false;
        recordCounter = 0;
        autoSave = 10;
        xRate = 100;
        autoAxis = true;
    }

    String getName() {
        return name;
    }
    
    void drawContent() {
        graph.drawGrid();
    }


    void drawNewData() {
        for(int i = 0; i < dataPoints.length; i++) {
            graph.plotData(dataPoints[i], -99999999, i);
        }
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
        //drawContent();
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

        // Add columns to the table
        while(dataTable.getColumnCount() < dataColumns.length) dataTable.addColumn(dataColumns[dataTable.getColumnCount()]);

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
     * Parse data from port and plot on graph
     **********************************/
    void parsePortData(String inputData){
        if (charIsNum(inputData.charAt(0))) {
            String[] dataArray = split(inputData,',');
            
            // If data column does not exist, add it to the list
            while(dataColumns.length < dataArray.length){
                dataColumns = append(dataColumns, "Untitled" + dataColumns.length);
                dataPoints = append(dataPoints, 0);
                dataTable.addColumn("Untitled" + dataColumns.length);
                redrawUI = true;
            }
    
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
                // Auto-save recording at set intervals to prevent loss of data
                recordCounter++;
                if(recordCounter >= autoSave * xRate){
                    recordCounter = 0;
                    saveTable(dataTable, outputfile, "csv");
                }
            }
    
            // -- Data Graphing ---
            // Go through each data column, and try to parse and plot it
            for(int i = 0; i < dataArray.length; i++){
                try {
                    dataPoints[i] = Float.parseFloat(dataArray[i]);

                    // If data exceeds graph size, resize the graph
                    if (autoAxis) {
                        if (dataPoints[i] < graph.getMinMax(2)) {
                          graph.setMinMax(decrement(dataPoints[i],false), 2);
                          redrawContent = true;
                        }
                        if (dataPoints[i] > graph.getMinMax(3)) {
                          graph.setMinMax(increment(dataPoints[i]), 3);
                          redrawContent = true;
                        }
                    }

                } catch (Exception e) {
                    print(e);
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

        int uH = int(sideItemHeight * uimult);
        int tH = int((sideItemHeight - 8) * uimult);
        int iH = int((sideItemHeight - 5) * uimult);
        int iL = int(sL + (10 * uimult));
        int iW = int(sW - (20 * uimult));

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
        drawHeading("Graph Scale", iL, sT + (uH * 8), iW, tH);
        textAlign(LEFT, CENTER);
        drawDatabox("xAxis: " + str(graph.getMinMax(1)), iL, sT + (uH * 9), iW - (40 * uimult), iH, tH);
        drawDatabox("yAxis: " + str(graph.getMinMax(3)), iL, sT + (uH * 10), iW - (40 * uimult), iH, tH);

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
        drawDatabox("Rate: " + xRate + "Hz", iL, sT + (uH * 12.5), iW, iH, tH);
        drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);

        float tHnow = 14.5;

        // List of Data Columns
        for(int i = 0; i < dataColumns.length; i++){
            // Column name
            drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

            // Remove column button
            drawButton("x", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

            // Swap column with one being listed above button
            color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
            drawButton("^", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

            fill(c_grey);
            rect(iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
            tHnow++;
        }

        textAlign(LEFT, CENTER);
        fill(c_lightgrey);
        text("Output File: " + outputfile, (5 * uimult), height - (bottombarHeight * uimult), width - sW, (bottombarHeight * uimult) - (5 * uimult));
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

        int uH = int(sideItemHeight * uimult);
        int tH = int((sideItemHeight - 8) * uimult);
        int iH = int((sideItemHeight - 5) * uimult);
        int iL = int(sL + (10 * uimult));
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
                stopRecording();
            } else if(outputfile != "" && outputfile != "No File Set"){
                startRecording();
            } else {
                alertHeading = "Error - Please set an output file path";
                redrawAlert = true;
            }
        }

        // Change number of X and Y axis markings
        else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){
            // Decrease x-Axis scale
            if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                //graph.changeGraphDiv(-1, 0);
                graph.setMinMax(decrement(graph.getMinMax(1),true), 1);
                redrawContent = redrawUI = true;
            }

            // Increase x-Axis scale
            else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                //graph.changeGraphDiv(1, 0);
                graph.setMinMax(increment(graph.getMinMax(1)), 1);
                redrawContent = redrawUI = true;
            }
        }

        else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){
            // Decrease y-Axis scale
            if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                //graph.changeGraphDiv(0, -1);
                graph.setMinMax(decrement(graph.getMinMax(3),true), 3);
                redrawContent = redrawUI = true;
            }

            // Increase y-Axis scale
            else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                //graph.changeGraphDiv(0, 1);
                graph.setMinMax(increment(graph.getMinMax(3)), 3);
                redrawContent = redrawUI = true;
            }
        }

        // Change the input data rate
        else if ((mouseY > sT + (uH * 12.5)) && (mouseY < sT + (uH * 12.5) + iH)){
            final String newrate = showInputDialog("Set new data rate:");
            if (newrate != null){
                try {
                    int newXrate = Integer.parseInt(newrate);
                    xRate = newXrate;
                    if (newXrate < 60) graph.setXrate(newXrate);
                    else graph.setXrate(60);
                    redrawUI = true;
                } catch (Exception e) {}
            }
        }

        // Add a new input data column
        else if ((mouseY > sT + (uH * 13.5)) && (mouseY < sT + (uH * 13.5) + iH)){
            final String colname = showInputDialog("Column Name:");
            if (colname != null){
                dataColumns = append(dataColumns, colname);
                redrawUI = true;
            }
        }
        
        else {
            float tHnow = 14.5;

            // List of Data Columns
            for(int i = 0; i < dataColumns.length; i++){

                if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)){

                    // Remove column
                    if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                        dataColumns = remove(dataColumns, i);
                        redrawUI = true;
                    }

                    // Move column up one space
                    else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                        if (i - 1 >= 0) {
                            String temp = dataColumns[i - 1];
                            dataColumns[i - 1] = dataColumns[i];
                            dataColumns[i] = temp;
                        }
                        redrawUI = true;
                    }

                    // Change name of column
                    else {
                        final String colname = showInputDialog("New Column Name:");
                        if (colname != null){
                            dataColumns[i] = colname;
                            redrawUI = true;
                        }
                    }
                }
                
                tHnow++;
            }
        }
    }
}
