/* * * * * * * * * * * * * * * * * * * * * * *
 * FILE GRAPH PLOTTER CLASS
 * implements TabAPI for Processing Grapher
 *
 * Code by: Simon Bluett
 * Email:   hello@chillibasket.com
 * * * * * * * * * * * * * * * * * * * * * * */

class FileGraph implements TabAPI {

    int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
    int xData;
    Graph graph;

    String name;
    String outputfile;
    String[] dataColumns = {};
    Table dataTable;

    boolean labelling;
    boolean zoomActive;
    int setZoomSize;
    float[] zoomCoordOne = {0, 0, 0, 0};



    /**********************************
     * Constructor
     **********************************/
    FileGraph(String setname, int left, int right, int top, int bottom) {
        name = setname;
        
        cL = left;
        cR = right;
        cT = top;
        cB = bottom;

        xData = -1;     // -1 if no data column contains x-axis data

        graph = new Graph(cL, cR, cT, cB, 0, 100, 0, 10, "Graph 1");
        outputfile = "No File Set";

        zoomActive = false;
        setZoomSize = -1;
        labelling = false;
    }

    String getName() {
        return name;
    }

    void drawContent() {
        graph.drawGrid();
        plotFileData();
    }

    void drawNewData() {
        // Not being used yet 
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
        outputfile = newoutput;
        if (outputfile != "No File Set") {
            // Check whether file is of type *.csv
            if (outputfile.contains(".csv")) {
                dataTable = loadTable(outputfile, "csv, header");
                zoomActive = false;
            } else {
                alertHeading = "Invalid file type; it must be *.csv";
                outputfile = "No File Set";
                redrawAlert = true;
            }
        }
        redrawContent = true;
    }

    void plotFileData() {
        if(outputfile != "No File Set" && outputfile != "" && dataTable.getColumnCount() > 0) {
            xData = -1;

            // Load columns
            while (dataColumns.length > 0) dataColumns = remove(dataColumns, 0);

            for (int i = 0; i < dataTable.getColumnCount(); i++) {
                dataColumns = append(dataColumns, dataTable.getColumnTitle(i));
                if ((i == 0) && (dataTable.getColumnTitle(i).contains("x:"))) {
                    xData = i;
                }
            }

            redrawUI = true;

            // Ensure that some data acutally exists in the table
            if (dataTable.getRowCount() > 0 && !(xData == 0 && dataTable.getColumnCount() == 1)) {
                
                float minx = 0, maxx = 0;
                float miny = dataTable.getFloat(0, 0), maxy = dataTable.getFloat(0, 0);

                if (xData == -1) {
                    minx = 0;
                    maxx = 0;
                    miny = dataTable.getFloat(0, 0);
                    maxy = dataTable.getFloat(0, 0);
                } else {
                    minx = dataTable.getFloat(0, 0);
                    maxx = dataTable.getFloat(dataTable.getRowCount() - 1, 0);
                    miny = dataTable.getFloat(0, 1);
                    maxy = dataTable.getFloat(0, 1);
                }

                // Calculate Min and Max X and Y axis values
                for (TableRow row : dataTable.rows()) {
                    int i = 0;

                    if (xData != -1) {
                        i = 1;
                        if(minx > row.getFloat(0)) minx = row.getFloat(0);
                        if(maxx < row.getFloat(0)) maxx = row.getFloat(0);
                    } else {
                        maxx += 1 / float(graph.getXrate());
                    }

                    for(   ; i < dataTable.getColumnCount(); i++){
                        if(miny > row.getFloat(i)) miny = row.getFloat(i);
                        if(maxy < row.getFloat(i)) maxy = row.getFloat(i);
                    }
                }

                // Only update axis values if zoom isn't active
                if (zoomActive == false) {
                    // Set these min and max values
                    graph.setMinMax(floorToSigFig(minx, 2), 0);
                    graph.setMinMax(ceilToSigFig(maxx, 2), 1);
                    graph.setMinMax(floorToSigFig(miny, 2), 2);
                    graph.setMinMax(ceilToSigFig(maxy, 2), 3);
                }

                // Draw the axes and grid
                graph.resetGraph();
                graph.drawGrid();

                // Start plotting the data
                int counter = 0;
                for (TableRow row : dataTable.rows()) {
                    if (xData != -1){
                        for (int i = 1; i < dataTable.getColumnCount(); i++) {
                            try {
                                float dataX = row.getFloat(0);
                                float dataPoint = row.getFloat(i);
                                if(Float.isNaN(dataX) || Float.isNaN(dataPoint)) dataPoint = dataX = 99999999;
                                
                                // Only plot it if it is within the X-axis data range
                                if (dataX >= graph.getMinMax(0) && dataX <= graph.getMinMax(1)) {
                                    graph.plotData(dataPoint, dataX, i);
                                }
                            } catch (Exception e) {
                                println("Error trying to plot file data.");
                                println(e);
                            }
                        }
                    } else {
                        for (int i = 0; i < dataTable.getColumnCount(); i++) {
                            try {
                                // Only start plotting when desired X-point has arrived
                                float currentX = counter / float(graph.getXrate());
                                if (currentX >= graph.getMinMax(0) && currentX <= graph.getMinMax(1)) {
                                    float dataPoint = row.getFloat(i);
                                    if(Float.isNaN(dataPoint)) dataPoint = 99999999;
                                    graph.plotData(dataPoint, currentX, i);
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

    String getOutput() {
        return outputfile;
    }

    void saveData() {
        if(outputfile != "No File Set" && outputfile != "") {
            try {
                saveTable(dataTable, outputfile, "csv");
                alertHeading = "File Saved!";
                redrawAlert = true;
            } catch (Exception e){
                alertHeading = "Error - Unable to save file " + e;
                redrawAlert = true;
            }
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

        // Open, close and save files
        drawHeading("Content File", iL, sT + (uH * 0), iW, tH);
        drawButton("Open Data", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
        drawButton("Save Data", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);

        // Add labels to data
        drawHeading("Data Labels", iL, sT + (uH * 3.5), iW, tH);
        drawButton("Add Label", c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
        drawButton("Remove Labels", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);
        
        // Graph type
        drawHeading("Graph Options", iL, sT + (uH * 7), iW, tH);
        drawButton("Line", (graph.getGraphType() == "linechart")? c_red:c_sidebar_button, iL, sT + (uH * 8), iW / 3, iH, tH);
        drawButton("Dots", (graph.getGraphType() == "dotchart")? c_red:c_sidebar_button, iL + (iW / 3), sT + (uH * 8), iW / 3, iH, tH);
        drawButton("Bar", (graph.getGraphType() == "barchart")? c_red:c_sidebar_button, iL + (iW * 2 / 3), sT + (uH * 8), iW / 3, iH, tH);
        fill(c_grey);
        rect(iL + (iW / 3), sT + (uH * 8) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
        rect(iL + (iW * 2 / 3), sT + (uH * 8) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

        // Graph scaling / segmentation
        drawDatabox(str(graph.getMinMax(0)), iL, sT + (uH * 9), (iW / 2) - (6 * uimult), iH, tH);
        drawButton("x", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 9), 12 * uimult, iH, tH);
        drawDatabox(str(graph.getMinMax(1)), iL + (iW / 2) + (6 * uimult), sT + (uH * 9), (iW / 2) - (6 * uimult), iH, tH);
        drawDatabox(str(graph.getMinMax(2)), iL, sT + (uH * 10), (iW / 2) - (6 * uimult), iH, tH);
        drawButton("y", c_sidebar_button, iL + (iW / 2) - (6 * uimult), sT + (uH * 10), 12 * uimult, iH, tH);
        drawDatabox(str(graph.getMinMax(3)), iL + (iW / 2) + (6 * uimult), sT + (uH * 10), (iW / 2) - (6 * uimult), iH, tH);

        // Zoom Options
        drawButton("Zoom", c_sidebar_button, iL, sT + (uH * 11), iW / 2, iH, tH);
        drawButton("Reset", c_sidebar_button, iL + (iW / 2), sT + (uH * 11), iW / 2, iH, tH);
        fill(c_grey);
        rect(iL + (iW / 2), sT + (uH * 11) + (1 * uimult), 1 * uimult, iH - (2 * uimult));

        // Input Data Columns
        drawHeading("Data Format", iL, sT + (uH * 12.5), iW, tH);
        if (xData == 0) drawButton("X-axis: " + dataColumns[0].substring(2, dataColumns[0].length()), c_sidebar_button, iL, sT + (uH * 13.5), iW, iH, tH);
        else drawDatabox("Rate: " + graph.getXrate() + "Hz", iL, sT + (uH * 13.5), iW, iH, tH);
        //drawButton("Add Column", c_sidebar_button, iL, sT + (uH * 12.5), iW, iH, tH);

        float tHnow = 14.5;

        // List of Data Columns
        for(int i = 0; i < dataColumns.length; i++){
            if (!(i == 0 && xData == 0)) {
                // Column name
                drawDatabox(dataColumns[i], iL, sT + (uH * tHnow), iW - (40 * uimult), iH, tH);

                // Remove column button
                drawButton("x", c_sidebar_button, iL + iW - (20 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);
                
                // Hide or Show data series
                color buttonColor = c_colorlist[i-(c_colorlist.length * floor(i / c_colorlist.length))];
                drawButton("", buttonColor, iL + iW - (40 * uimult), sT + (uH * tHnow), 20 * uimult, iH, tH);

                fill(c_grey);
                rect(iL + iW - (20 * uimult), sT + (uH * tHnow) + (1 * uimult), 1 * uimult, iH - (2 * uimult));
                tHnow++;
            }
        }

        textAlign(LEFT, TOP);
        textFont(base_font);
        fill(c_lightgrey);
        text("Input File: " + outputfile, round(5 * uimult), height - round(bottombarHeight * uimult) + round(2*uimult), width - sW - round(10 * uimult), round(bottombarHeight * uimult));
    }

    void keyboardInput(char key) {
        // Not being used yet
    }

    void getContentClick (int xcoord, int ycoord) {
        if (labelling) {
            if(outputfile != "" && outputfile != "No File Set"){

                int xItem = graph.setXlabel(xcoord, ycoord);
                if (xItem != -1) {
                }
            } 
            labelling = false;
            cursor(ARROW);
        } 

        else if (setZoomSize == 0) {
            if (graph.onGraph(xcoord, ycoord)) {
                zoomCoordOne[0] = (graph.xGraphPos(xcoord) * (graph.getMinMax(1) - graph.getMinMax(0))) + graph.getMinMax(0);
                zoomCoordOne[1] = ((1 - graph.yGraphPos(ycoord)) * (graph.getMinMax(3) - graph.getMinMax(2))) + graph.getMinMax(2);
                stroke(c_white);
                strokeWeight(1 * uimult);
                line(xcoord - (5 * uimult), ycoord, xcoord + (5 * uimult), ycoord);
                line(xcoord, ycoord - (5 * uimult), xcoord, ycoord + (5 * uimult));
                setZoomSize = 1;
            }

        } else if (setZoomSize == 1) {
            if (graph.onGraph(xcoord, ycoord)) {
                zoomCoordOne[2] = (graph.xGraphPos(xcoord) * (graph.getMinMax(1) - graph.getMinMax(0))) + graph.getMinMax(0);
                zoomCoordOne[3] = ((1 - graph.yGraphPos(ycoord)) * (graph.getMinMax(3) - graph.getMinMax(2))) + graph.getMinMax(2);
                setZoomSize = -1;

                if (zoomCoordOne[0] < zoomCoordOne[2]) {
                    graph.setMinMax(floorToSigFig(zoomCoordOne[0], 4), 0);
                    graph.setMinMax(ceilToSigFig(zoomCoordOne[2], 4), 1);
                } else {
                    graph.setMinMax(ceilToSigFig(zoomCoordOne[0], 4), 1);
                    graph.setMinMax(floorToSigFig(zoomCoordOne[2], 4), 0);
                }

                if (zoomCoordOne[1] < zoomCoordOne[3]) {
                    graph.setMinMax(floorToSigFig(zoomCoordOne[1], 4), 2);
                    graph.setMinMax(ceilToSigFig(zoomCoordOne[3], 4), 3);
                } else {
                    graph.setMinMax(ceilToSigFig(zoomCoordOne[1], 4), 3);
                    graph.setMinMax(floorToSigFig(zoomCoordOne[3], 4), 2);
                }

                redrawContent = true;
                redrawUI = true;
                cursor(ARROW);
            }
        }

        else cursor(ARROW);
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
        int iW = round(sW - (20 * uimult));

        // Open data
        if ((mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
            outputfile = "";
            selectInput("Select select a directory and name for output", "fileSelected");
        }

        // Save data
        else if ((mouseY > sT + (uH * 2)) && (mouseY < sT + (uH * 2) + iH)){
            if(outputfile != "" && outputfile != "No File Set"){
                saveData();
            }
        }

        // Add label
        else if ((mouseY > sT + (uH * 4.5)) && (mouseY < sT + (uH * 4.5) + iH)){
            if(outputfile != "" && outputfile != "No File Set"){
                labelling = true;
                cursor(CROSS);
            }
        }
        
        // Remove all labels
        else if ((mouseY > sT + (uH * 5.5)) && (mouseY < sT + (uH * 5.5) + iH)){
            redrawContent = redrawUI = true;
        }

        // Change graph type
        else if ((mouseY > sT + (uH * 8)) && (mouseY < sT + (uH * 8) + iH)){

            // Line
            if ((mouseX > iL) && (mouseX <= iL + iW / 3)) {
                graph.setGraphType("linechart");
                redrawContent = redrawUI = true;
            }

            // Dot
            else if ((mouseX > iL + (iW / 3)) && (mouseX <= iL + (iW * 2 / 3))) {
                graph.setGraphType("dotchart");
                redrawContent = redrawUI = true;
            }

            // Bar
            else if ((mouseX > iL + (iW * 2 / 3)) && (mouseX <= iL + iW)) {
                graph.setGraphType("barchart");
                redrawContent = redrawUI = true;
            }
        }

        // Update X axis scaling
        else if ((mouseY > sT + (uH * 9)) && (mouseY < sT + (uH * 9) + iH)){

            // Change X axis minimum value
            if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
                final String xMin = showInputDialog("Please enter new X-axis minimum value:");
                if (xMin != null){
                    try {
                        graph.setMinMax(Float.parseFloat(xMin), 0);
                        zoomActive = true;
                    } catch (Exception e) {}
                } 
                redrawContent = redrawUI = true;
            }

            // Change X axis maximum value
            else if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
                final String xMax = showInputDialog("Please enter new X-axis maximum value:");
                if (xMax != null){
                    try {
                        graph.setMinMax(Float.parseFloat(xMax), 1);
                        zoomActive = true;
                    } catch (Exception e) {}
                } 
                redrawContent = redrawUI = true;
            }
        }

        // Update Y axis scaling
        else if ((mouseY > sT + (uH * 10)) && (mouseY < sT + (uH * 10) + iH)){

            // Change Y axis minimum value
            if ((mouseX > iL) && (mouseX < iL + (iW / 2) - (6 * uimult))) {
                final String yMin = showInputDialog("Please enter new Y-axis minimum value:");
                if (yMin != null){
                    try {
                        graph.setMinMax(Float.parseFloat(yMin), 2);
                        zoomActive = true;
                    } catch (Exception e) {}
                } 
                redrawContent = redrawUI = true;
            }

            // Change Y axis maximum value
            else if ((mouseX > iL + (iW / 2) + (6 * uimult)) && (mouseX < iL + iW)) {
                final String yMax = showInputDialog("Please enter new Y-axis maximum value:");
                if (yMax != null){
                    try {
                        graph.setMinMax(Float.parseFloat(yMax), 3);
                        zoomActive = true;
                    } catch (Exception e) {}
                } 
                redrawContent = redrawUI = true;
            }
        }

        // Zoom Options
        else if ((mouseY > sT + (uH * 11)) && (mouseY < sT + (uH * 11) + iH)){

            // New zoom
            if ((mouseX > iL) && (mouseX <= iL + iW / 2)) {
                zoomActive = true;
                setZoomSize = 0;
                cursor(CROSS);
                //redrawUI = true;
            }

            // Reset zoom
            else if ((mouseX > iL + (iW / 2)) && (mouseX <= iL + iW)) {
                zoomActive = false;
                cursor(ARROW);
                redrawContent = redrawUI = true;
            }
        }

        // Change the input data rate
        else if ((mouseY > sT + (uH * 13.5)) && (mouseY < sT + (uH * 13.5) + iH)){
            final String newrate = showInputDialog("Set new data rate:");
            if (newrate != null){
                try {
                    graph.setXrate(Integer.parseInt(newrate));
                    redrawContent = redrawUI = true;
                } catch (Exception e) {}
            }
        }
        
        // Add a data column
        /*
        else if ((mouseY > sT + (uH * 12.5)) && (mouseY < sT + (uH * 12.5) + iH)){
            final String colname = showInputDialog("Column Name:");
            if (colname != null){
                dataColumns = append(dataColumns, colname);
                redrawUI = true;
            }
        }*/
        
        // Edit data column
        else {
            float tHnow = 14.5;

            // List of Data Columns
            for(int i = 0; i < dataColumns.length; i++){

                if ((mouseY > sT + (uH * tHnow)) && (mouseY < sT + (uH * tHnow) + iH)){

                    if ((mouseX > iL + iW - (20 * uimult)) && (mouseX < iL + iW)) {
                        if (xData == 0) {
                            dataColumns = remove(dataColumns, i + 1);
                            dataTable.removeColumn(i + 1);
                        } else {
                            dataColumns = remove(dataColumns, i);
                            dataTable.removeColumn(i);
                        }
                        redrawContent = redrawUI = true;
                    }

                    else if ((mouseX > iL + iW - (40 * uimult)) && (mouseX < iL + iW - (20 * uimult))) {
                        /*
                        if (i - 1 >= 0) {
                            String temp = dataColumns[i - 1];
                            dataColumns[i - 1] = dataColumns[i];
                            dataColumns[i] = temp;
                        }
                        redrawUI = true;*/
                    }
                }
                
                tHnow++;
            }
        }
    }

    void parsePortData(String inputData) {
        // Not using serial comms 
    }
}
