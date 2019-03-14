class Graph {

    int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
    int gL, gR, gT, gB;     // Graph area coordinates

    float minX, maxX, minY, maxY; // Limits of data
    float[] lastX = {0}, lastY = {-99999999};   // Array containing previous x and y values

    int xScale, yScale;
    int xRate;
    String plotType;

    // Ui variables
    int graphMark;
    //int uimult;
    int border;
    boolean redrawGraph;
    boolean gridLines;


    /**********************************
     * Constructor
     **********************************/
    Graph(int left, int right, int top, int bottom, float minx, float maxx, float miny, float maxy) {

        //uimult = 1;

        cL = gL = left;
        cR = gR = right;
        cT = gT = top;
        cB = gB = bottom;

        minX = minx;
        maxX = maxx;
        minY = miny;
        maxY = maxy;

        xScale = 40;
        yScale = 40;
        xRate = 60;

        graphMark = int(8 * uimult);
        border = int(30 * uimult);

        plotType = "linechart";
        redrawGraph = gridLines = true;
    }
    

    /**********************************
     * Plot Data onto Graph
     **********************************/
    void changeSize(int newL, int newR, int newT, int newB) {
        cL = newL;
        cR = newR;
        cT = newT;
        cB = newB;

        for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
        redrawGraph = true;
    }


    /**********************************
     * Change number of divisions on axis
     **********************************/
    void changeGraphDiv(int deltax, int deltay) {
        xScale += deltax;
        yScale += deltay;
        for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
        drawGrid();
    }

    int getXscale() {
        return xScale;
    }

    int getYscale() {
        return yScale;
    }

    // Change rate at which x-axis data is shown
    int getXrate() {
        return xRate;
    }

    void setXrate(int newrate) {
        xRate = newrate;
    }

    // Change the minimum and maximum bounds of the graph
    void setMinMax(float newval, int type) {
        switch(type){
            case 0: minX = newval; break;
            case 1: maxX = newval; break;
            case 2: minY = newval; break;
            case 3: maxY = newval; break;
        }
        for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
        for(int i = 0; i < lastY.length; i++) lastY[i] = -99999999;
    }

    float getMinMax(int type) {
        switch(type){
            case 0: return minX;
            case 1: return maxX;
            case 2: return minY;
            case 3: return maxY;
            default: return 0;
        }
    }

    void resetGraph(){
        for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
        for(int i = 0; i < lastY.length; i++) lastY[i] = -99999999;
    }

    int setXlabel(float xCoord, float yCoord) {
        if (xCoord < gL || xCoord > gR || yCoord < gT || yCoord > gB) return -1;
        stroke(c_sidebar);
        strokeWeight(1 * uimult);
        line(xCoord, gT, xCoord, gB);
        return round(map(xCoord, gL, gR, minX, maxX) / xRate);
    }


    /**********************************
     * Plot Data onto Graph
     **********************************/
    void plotData(float dataY, float dataX, int type) {
        // Deal with labels
        /*
        if(type == -1) {
            stroke(c_sidebar);
            strokeWeight(1 * uimult);
            line(map(lastX[0], minX, maxX, gL, gR), gT, map(lastX[0], minX, maxX, gL, gR), gB);
            return;
        }*/

        float xStep = 1 / float(xRate);
        int x1, y1, x2 = gL, y2;

        // Ensure that the element actually exists in data arrays
        while(lastY.length < type + 1) lastY = append(lastY, -99999999);
        while(lastX.length < type + 1) lastX = append(lastX, 0);
        
        // Redraw grid, if required
        if(lastX[type] == 0 && redrawGraph) drawGrid();

        // Bound the Y-axis data
        if (dataY > maxY && dataY != 99999999 && dataY != -99999999) dataY = maxY;
        if (dataY < minY && dataY != 99999999 && dataY != -99999999) dataY = minY;

        // Only plot data if it is within bounds
        if(dataY >= minY && dataY <= maxY && dataY != 99999999) {

            // Get relevant color from list
            fill(c_colorlist[type - (c_colorlist.length * floor(type / c_colorlist.length))]);
            stroke(c_colorlist[type - (c_colorlist.length * floor(type / c_colorlist.length))]);
            strokeWeight(1 * uimult);
            
            switch(plotType){

                case "dotchart":
                    // Determine x and y coordinates
                    if(dataX == -99999999) x2 = round(map(lastX[type] + xStep, minX, maxX, gL, gR));
                    else x2 = round(map(dataX, minX, maxX, gL, gR));
                    y2 = round(map(dataY, minY, maxY, gB, gT));
                    
                    ellipse(x2, y2, 2*uimult, 2*uimult);
                    break;

                case "barchart":
                    // Determine x and y coordinates
                    x1 = round(map(lastX[type], minX, maxX, gL, gR));
                    if(dataX == -99999999) x2 = round(map(lastX[type] + xStep, minX, maxX, gL, gR));
                    else x2 = round(map(dataX, minX, maxX, gL, gR));
                    y1 = round(map(dataY, minY, maxY, gB, gT));
                    if (minY <= 0) y2 = round(map(0, minY, maxY, gB, gT));
                    else y2 = round(map(minY, minY, maxY, gB, gT));
                    
                    rectMode(CORNERS);
                    rect(x1, y1, x2, y2);
                    break;

                // linechart
                default: 
                    // Only draw line if last value is set
                    if(abs(lastY[type]) != 99999999){
                        // Determine x and y coordinates
                        x1 = round(map(lastX[type], minX, maxX, gL, gR));
                        if(dataX == -99999999) x2 = round(map(lastX[type] + xStep, minX, maxX, gL, gR));
                        else x2 = round(map(dataX, minX, maxX, gL, gR));
                        y1 = round(map(lastY[type], minY, maxY, gB, gT));
                        y2 = round(map(dataY, minY, maxY, gB, gT));
                        line(x1, y1, x2, y2);
                    }
            }
        } 

        if(int(lastY[type]) != -99999999) { 
            if(dataX == -99999999) lastX[type] = lastX[type] + xStep;
            else lastX[type] = dataX;
        } else lastX[type] = 0;
        lastY[type] = dataY;

        if(x2 >= gR) {
            if (type == lastX.length - 1) {
              for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
            } else lastX[type] = 0;
            redrawGraph = true;
        }
    }


    /**********************************
     * Draw Grid
     **********************************/
    void drawGrid() {
      redrawGraph = false;

        // X and Y axis zero
        float yZero = 0, xZero = 0;
        if((minY > 0) || (maxY < 0)) yZero = minY;

        int yOffset = round(map(yZero, minY, maxY, 0, yScale));
        int xOffset = round(map(xZero, minX, maxX, 0, xScale));

        float yDivUnit = abs((maxY - yZero) / float(yScale - yOffset));
        float xDivUnit = abs((maxX - minX) / float(xScale - xOffset));

        // Text width and height
        int padding = int(4 * uimult);
        int yTextWidth = 0;
        int xTextWidth = 0;
        int yTextHeight = int(12 * uimult) + padding;
        int xTextHeight = int(12 * uimult) + padding;

        textSize(12 * uimult);

        // Find largest width, and use that as our width value
        for (int i = 1; i < yScale; i++) {
            if (textWidth(nfs(int(i * yDivUnit * 100) / 100.0,0,0)) + padding > yTextWidth) yTextWidth = int(textWidth(nfs(int(i * yDivUnit * 100) / 100.0,0,0)) + padding);
        }
        for (int i = 1; i < xScale; i++) {
            if (textWidth(nfs(int(i * xDivUnit * 100) / 100.0,0,0)) + padding > xTextWidth) xTextWidth = int(textWidth(nfs(int(i * xDivUnit * 100) / 100.0,0,0)) + padding);
        }

        // Calculate graph area bounds
        gL = cL + border + yTextWidth + graphMark + int(2 * uimult);
        gT = cT + border;
        gR = cR - border;
        gB = cB - border - xTextHeight - graphMark;

        // Clear the content area
        rectMode(CORNER);
        noStroke();
        fill(c_background);
        rect(cL, cT, cR - cL, cB - cT);

        // Setup drawing parameters
        stroke(c_lightgrey);
        strokeWeight(1 * uimult);
        fill(c_lightgrey);
        textAlign(RIGHT, CENTER);


        // ---------- Y-AXIS ----------
        int labelsHeight = yScale * yTextHeight;

        // Draw each of the division markings
        for (int i = 0;  i < yScale; i++){

            float currentY = yZero;
            if (i < yOffset) currentY -= yDivUnit * (yOffset - i);
            else currentY += yDivUnit * (i - yOffset);

            float currentYpixel = map(currentY, minY, maxY, gB, gT);

            if (currentYpixel >= gT && currentYpixel <= gB) {
                // Small inbetween mark
                stroke(c_lightgrey);
                line(gL - (graphMark * 0.6), currentYpixel, gL - int(1 * uimult), currentYpixel);

                // Only show labels if there is enough room on screen
                for (float j = 1; j <= yScale; j*=2){
                    
                  
                    if ((i%j == 0) && (labelsHeight / j < gB - gT)) {

                        // Draw background grid line, if enabelled
                        if (gridLines) {
                            stroke(c_darkgrey);
                            line(gL, currentYpixel, gR, currentYpixel);
                        }

                        // Limit to 2 decimal places, but only show decimals if needed
                        String label = nf(int(currentY * 100) / 100.0,0,0);

                        // Draw axis labelling
                        stroke(c_lightgrey);
                        text(label, cL + border, currentYpixel - ((yTextHeight + padding) / 2), yTextWidth, yTextHeight);
                        line(gL - graphMark, currentYpixel, gL - int(1 * uimult), currentYpixel);
                        break;
                    }
                }
            }
        }


        // ---------- X-AXIS ----------
        textAlign(CENTER, CENTER);
        int labelsWidth = xScale * xTextWidth;

        // Draw each of the division markings
        for (int i = 0;  i < xScale; i++){

            float currentX = xZero;
            if (i < xOffset) currentX -= xDivUnit * (xOffset - i);
            else currentX += xDivUnit * (i - xOffset);

            float currentXpixel = map(currentX, minX, maxX, gL, gR);
            float yZeroPixel = map(yZero, minY, maxY, gB, gT);

            // Small inbetween mark
            stroke(c_lightgrey);
            line(currentXpixel, gB, currentXpixel, gB + (graphMark * 0.6));

            // Only show labels if there is enough room on screen
            for (int j = 1; j <= xScale; j*=2){

                if ((i%j == 0) && (labelsWidth / j < gR - gL)) {

                    // Draw background grid line, if enabelled
                    if (gridLines) {
                        stroke(c_darkgrey);
                        line(currentXpixel, gT, currentXpixel, gB);
                    }

                    // Limit to 2 decimal places, but only show decimals if needed
                    String label = nf(int(currentX * 100) / 100.0,0,0);

                    // Draw axis labelling
                    stroke(c_lightgrey);
                    text(label, currentXpixel - (xTextWidth / 2), gB + graphMark, xTextWidth, xTextHeight);
                    line(currentXpixel, gB, currentXpixel, gB + graphMark);
                    break;
                }
            }
        }

        stroke(c_lightgrey);
        line(gL, gT, gL, gB);

        stroke(c_lightgrey);
        line(gL, map(yZero, minY, maxY, gB, gT), gR, map(yZero, minY, maxY, gB, gT));
    }
}
