class Filters implements TabAPI {

	  int cL, cR, cT, cB;     // Content coordinates (left, right, top bottom)
    String name;
    String inputfile, outputfile;
    Table dataTable;

    /**********************************
     * Constructor
     **********************************/
    Filters(String setname, int left, int right, int top, int bottom) {
        name = setname;
        
        cL = left;
        cR = right;
        cT = top;
        cB = bottom;

        inputfile = outputfile = "No File Set";
    }

    String getName() {
        return name;
    }

    void drawContent() {
        // Clear the content area
        rectMode(CORNER);
        noStroke();
        fill(c_background);
        rect(cL, cT, cR - cL, cB - cT);

        // Button to 
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

        //drawContent();
    }


    void runFFT(){
    	// Test out FFT Function
        if(inputfile != "" && inputfile != "No File Set"){
            int length = dataTable.getRowCount();
            int pt = length;
            pt--;
            pt |= pt >> 1;
            pt |= pt >> 2;
            pt |= pt >> 4;
            pt |= pt >> 8;
            pt |= pt >> 16;
            pt++;

            float[]  dataArray = new float[pt * 2];
            for(int i = 0; i < pt * 2; i++) dataArray[i] = 0;
            for(int i = 0; i < length; i++) dataArray[i * 2] = dataTable.getFloat(i, 0);
            FFT(dataArray, pt, 1);

            Table fftTable = new Table();
            fftTable.addColumn("x:Frequency");
            fftTable.addColumn("Amplitude");
            float freqDiv = 100 / float(pt); // TODO: set x Rate here !!!!!!

            for (int i = 0; i < length; i++) {
                fftTable.setFloat(i, "x:Frequency", freqDiv * i);
                fftTable.setFloat(i, "Amplitude", sqrt((dataArray[i * 2] * dataArray[i * 2]) + (dataArray[i*2 + 1] * dataArray[i*2 + 1])));
            }

            saveTable(fftTable, outputfile, "csv");
            redrawContent = redrawUI = true;
        }
    }


	//data -> float array that represent the array of complex samples
	//number_of_complex_samples -> number of samples (N^2 order number) 
	//isign -> 1 to calculate FFT and -1 to calculate Reverse FFT
	void FFT(float data[], int number_of_complex_samples, int isign)
	{
	    //variables for trigonometric recurrences
	    int i, j, n, m, mmax, istep;
	    float wr, wpr, wi, wpi, wtemp, tempr, tempi, theta;

		// The complex array is real+complex so the array has a 
		// size n = 2* number of complex samples. The real part 
		// is the data[index] and the complex part is the data[index+1]
		n = number_of_complex_samples * 2;

		// Binary inversion (note that the indexes start from 
		// 0 which means that the real part of the complex is 
		// on the even-indexes and the complex part is on the odd-indexes
		j = 0;
		for (i = 0; i < n / 2; i += 2) {
		    if (j > i) {
		        // Swap the real part
		        tempr = data[j];
		        data[j] = data[i];
		        data[i] = tempr;
		        // Swap the complex part
		        tempr = data[j+1];
		        data[j+1] = data[i+1];
		        data[i+1] = tempr;
		        // Checks if the changes occurs in the first half
		        // and use the mirrored effect on the second half
		        if ((j / 2) < (n / 4)) {
		            // Swap the real part
		            tempr = data[(n - (i + 2))];
		            data[(n - (i + 2))] = data[(n - (j + 2))];
		            data[(n - (j + 2))] = tempr;
		            // Swap the complex part
		            tempr = data[(n - (i + 2)) + 1];
		            data[(n - (i + 2)) + 1] = data[(n - (j + 2)) + 1];
		            data[(n - (j + 2)) + 1] = tempr;
		        }
		    }
		    m = n / 2;
		    while (m >= 2 && j >= m) {
		        j -= m;
		        m = m / 2;
		    }
		    j += m;
		    print(i); print(" , "); println(j);
		}

		// Danielson-Lanzcos routine
		mmax = 2;
		// External loop
		while (n > mmax) {
		    istep = mmax << 1;
		    theta = isign * (2 * PI / mmax);
		    wtemp = sin(0.5 * theta);
		    wpr = -2.0 * wtemp * wtemp;
		    wpi = sin(theta);
		    wr = 1.0;
		    wi = 0.0;
		    // Internal loops
		    for (m = 1; m < mmax; m += 2) {
		        for (i = m; i <= n; i += istep) {
		            j = i + mmax;
		            tempr = wr * data[j-1] - wi * data[j];
		            tempi = wr * data[j] + wi * data[j-1];
		            data[j-1] = data[i-1] - tempr;
		            data[j] = data[i] - tempi;
		            data[i-1] += tempr;
		            data[i] += tempi;
		        }
		        wr = (wtemp = wr) * wpr - wi * wpi + wr;
		        wi = wi * wpr + wtemp * wpi + wi;
		    }
		    mmax = istep;
		}
	}


    void keyboardInput(char key) {
        // Not being used yet
    }

	void getContentClick (int xcoord, int ycoord) {
        // Not being used yet    
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

        // Open, close and save files
        drawHeading("I/O Files", iL, sT + (uH * 0), iW, tH);
        drawButton("Input File", c_sidebar_button, iL, sT + (uH * 1), iW, iH, tH);
        drawButton("Output File", c_sidebar_button, iL, sT + (uH * 2), iW, iH, tH);

        // Add labels to data
        drawHeading("OneClick Filter", iL, sT + (uH * 3.5), iW, tH);
        drawButton("Simple FFT", c_sidebar_button, iL, sT + (uH * 4.5), iW, iH, tH);
        drawButton("Inverse FFT", c_sidebar_button, iL, sT + (uH * 5.5), iW, iH, tH);

        textAlign(LEFT, CENTER);
        fill(c_lightgrey);
        text("Input File: " + inputfile, (5 * uimult), height - (bottombarHeight * uimult), width - sW, bottombarHeight - (5 * uimult));
        text("Output File: " + outputfile, (width - sW) / 2, height - (bottombarHeight * uimult), width - sW, bottombarHeight - (5 * uimult));
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

        // Input data
        if ((mouseY > sT + (uH * 1)) && (mouseY < sT + (uH * 1) + iH)){
            outputfile = "";
            selectInput("Select select a directory and name for output", "fileSelected");
        }

        // Output data
        else if ((mouseY > sT + (uH * 2)) && (mouseY < sT + (uH * 2) + iH)){
            if(outputfile != "" && outputfile != "No File Set"){
                //saveData();
            }
        }


        else if ((mouseY > sT + (uH * 4.5)) && (mouseY < sT + (uH * 4.5) + iH)){
            if(outputfile != "" && inputfile != "No File Set") {
                runFFT();
            }
        }
    }
    
    String getOutput() {
        return outputfile;
    }
    
    void setOutput(String newoutput) {
        inputfile = newoutput;
        if (inputfile == "No File Set") outputfile = inputfile;
        else {
            outputfile = inputfile.substring( 0, inputfile.length()-4 ) + "-fft.csv";
            dataTable = loadTable(inputfile, "csv, header");
        }
        redrawContent = true;
    }
    
    void parsePortData(String inputData) {
        // Not using serial comms 
    }
    
    void scrollWheel (float amount) {
        // Not being used yet
    }
}
