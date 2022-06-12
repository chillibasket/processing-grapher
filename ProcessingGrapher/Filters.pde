/* * * * * * * * * * * * * * * * * * * * * * *
 * FILTERS CLASS
 *
 * @file     Filters.pde
 * @brief    Algorithms to filter time-variant signals
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    Filters
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

import java.text.DecimalFormat;


class Filters {

	// Filter list to be shown in the sidebar menu.
	// Entries starting with "h:" are headings
	String[] filterList = {"h:Noise Removal", 
	                            "Moving Average", 
	                            "1D Total Variance",
	                            "RC Low Pass",
	                            "RC High Pass",
	                       "h:Mathematical Functions", 
	                            "Absolute Value:  |x|", 
	                            "Squared:  x^2", 
	                            "Derivative:  Δx/dt", 
	                            "Integral:  Σxdt",
	                       "h:Signal Analysis",
	                   	        "Fourier Transform",
	                   	    	"Enclosed Area"};

	String[] filterSlug = {"h", "avg", "tv", "lp", "hp", "h", "abs", "squ", "Δ/dt", "Σdt", "h", "fft", "ea"};

	/**
	 * Default Constructor
	 */
	Filters() {
		// Empty
	}


	/**
	 * Run the specified filter on the provided data
	 */
	public double[] runFilter(int filterType, double[] signalData, double[] xAxisData, String currentFileLocation) {

		double[] outputData = null;

		switch (filterType) {
			// Moving average filter
			case 0:
			case 1: {
				ValidateInput userInput = new ValidateInput("Set Moving Average Filter Amount", "Number of Samples:", str(5));
				userInput.setErrorMessage("Error\nInvalid window size entered.\nThe window size should be an integer greater than 2.");
				if (userInput.checkInt(userInput.GTE, 2)) {
					int windowSize = userInput.getInt();
					MovingAverage avgFilter = new MovingAverage(windowSize);
					outputData = avgFilter.process(signalData);
				}
				break;
			}

			// 1D Total Variance denoiser 
			case 2: {
				ValidateInput userInput = new ValidateInput("Set Denoising Filter Amount", "Lambda Value:", str(1));
				userInput.setErrorMessage("Error\nInvalid filter value entered.\nThe Lambda value should be a number greater than 0.");
				if (userInput.checkDouble(userInput.GT, 0)) {
					double filterValue = userInput.getDouble();
					DenoiseTv1D denoiseFilter = new DenoiseTv1D();
					outputData = denoiseFilter.process(signalData, filterValue);
				}
				break;
			}

			// Low pass filter
			case 3: {
				ValidateInput userInput = new ValidateInput("Set the 3dB Cutoff Frequency", "Filter Frequency (Hz):", str(100));
				userInput.setErrorMessage("Error\nInvalid filter value entered.\nThe cutoff frequency should be a number above 0 Hz.");
				if (userInput.checkDouble(userInput.GT, 0)) {
					double filterValue = userInput.getDouble();
					RcLowPass lowPassFilter = new RcLowPass(filterValue);
					outputData = lowPassFilter.process(signalData, xAxisData);
				}
				break;
			}

			// High pass filter
			case 4: {
				ValidateInput userInput = new ValidateInput("Set the 3dB Cutoff Frequency", "Filter Frequency (Hz):", str(100));
				userInput.setErrorMessage("Error\nInvalid filter value entered.\nThe cutoff frequency should be a number above 0 Hz.");
				if (userInput.checkDouble(userInput.GT, 0)) {
					double filterValue = userInput.getDouble();
					RcHighPass highPassFilter = new RcHighPass(filterValue);
					outputData = highPassFilter.process(signalData, xAxisData);
				}
				break;
			}

			// Absolute value
			case 5:
			case 6: {
				outputData = new double[signalData.length];
				for (int i = 0; i < signalData.length; i++) {
					outputData[i] = Math.abs(signalData[i]);
				}
				break;
			}

			// Squared
			case 7: {
				outputData = new double[signalData.length];
				for (int i = 0; i < signalData.length; i++) {
					outputData[i] = Math.pow(signalData[i], 2);
				}
				break;
			}

			// Numerical Derivative using central difference
			case 8: {
				outputData = new double[signalData.length];
				outputData[0] = 0;
				outputData[signalData.length - 1] = 0;
				for (int i = 1; i < signalData.length  - 1; i++) {
					outputData[i] = (signalData[i + 1] - signalData[i - 1]) / (xAxisData[i + 1] - xAxisData[i - 1]);
				}
				break;
			}

			// Numerical Intgral 
			case 9: {
				outputData = new double[signalData.length];
				outputData[0] = 0;
				for (int i = 1; i < signalData.length; i++) {
					outputData[i] = outputData[i - 1] + (signalData[i] * (xAxisData[i] - xAxisData[i - 1]));
				}
				break;
			}

			// Fast Fourier Transform
			case 10:
			case 11: {
				double[] amplitudeAxis = null;
				double[] frequencyAxis = new double[signalData.length];
				double samplingFrequency = 0;

				// Figure out the sampling frequency
				for (int i = 0; i < xAxisData.length - 1; i++) {
					samplingFrequency += xAxisData[i+1] - xAxisData[i];
				}
				samplingFrequency /= xAxisData.length - 1;
				samplingFrequency = 1 / samplingFrequency;
				//println("freq: " + samplingFrequency);

				// Run the FFT
				FastFourierTransform fft = new FastFourierTransform();
				amplitudeAxis = fft.processForward(signalData, samplingFrequency, frequencyAxis);

				if (frequencyAxis == null || amplitudeAxis == null) {
					alertMessage("Fast Fourier Transform\nError: Unable to calculate the FFT");
				} else {
					double maxAmplitude = 0;
					int maxAmpIndex = 0;

					// Save the result to a file
					String[] lines = new String[amplitudeAxis.length + 1];
					lines[0] = "x:Frequency (Hz),Amplitude";
					for (int i = 0; i < amplitudeAxis.length; i++) {
						lines[i+1] = frequencyAxis[i] + "," + amplitudeAxis[i];

						if (maxAmplitude < amplitudeAxis[i]) {
							maxAmplitude = amplitudeAxis[i];
							maxAmpIndex = i;
						}
					}

					String newFileLocation = currentFileLocation.substring(0,currentFileLocation.length()-4) + "_fft.csv";
					saveStrings(newFileLocation, lines);
					DecimalFormat format = new DecimalFormat("0.#####");
					alertMessage("Fast Fourier Transform\nDominant frequency:   " + 
						format.format(frequencyAxis[maxAmpIndex]) + " Hz\n(Assuming time axis was in seconds)\n" + 
						"\nFull spectrogram is saved at:\n" + newFileLocation);
				}
				break;
			}

			// Enclosed Area Calculation
			case 12: {
				AreaCalculation areaCalc = new AreaCalculation();
				double[] calculatedAreas = areaCalc.processCycles(xAxisData, signalData);

				if (calculatedAreas == null || calculatedAreas.length < 1) {
					alertMessage("Enclosed Area Calculation\nError: No cycles were found in the data\nTherefore there are no enclosed areas");
				} else {
					double averageArea = 0;
					for (int i = 0; i < calculatedAreas.length; i++) averageArea += calculatedAreas[i];
					averageArea /= calculatedAreas.length;
					DecimalFormat format = new DecimalFormat("0.########");
					alertMessage("Enclosed Area Calculation\nCycles Detected:   " + calculatedAreas.length + "\nAverage Area:   " + format.format(averageArea));
				}
				break;
			}
		}

		return outputData;
	}


	/**
	 * Simple Moving Average (Sliding Window) Filter Class
	 */
	public class MovingAverage {
		private int size;
		private double samples[];
		private double total = 0;
		private int index = 0;
		private boolean bufferFilled = false;

		/**
		 * Constructor
		 *
		 * @param  windowSize The size of the sliding window
		 */
		public MovingAverage(int windowSize) {
			size = windowSize;
			samples = new double[size];
		}

		/**
		 * Add a new sample to the moving average
		 *
		 * @param  signalValue The value of the sample to add
		 */
		public void add(double signalValue) {
			total -= samples[index];
			samples[index] = signalValue;
			total += signalValue;
			index++;
			if (index == size) {
				bufferFilled = true;
				index = 0;
			}
		}

		/**
		 * Get the average value
		 *
		 * @return The moving average result
		 */
		public double getAverage() {
			if (bufferFilled) return total / size;
			return total / index;
		}

		/**
		 * Apply the filter to all the provided signal data at once
		 *
		 * @param  signalData Array containing the y-axis data to be filtered
		 * @return Output an array containing the filtered value for each step
		 */
		public double[] process(double[] signalData) {
			double[] outputData = new double[signalData.length];
			int samplesOffset = size / 2;

			// Calculate average, offsetting signal by half the window size to compensate filter delay
			for (int i = 0; i < signalData.length; i++) {
				add(signalData[i]);

				// Main filter portion, offset by half the window size
				if (i >= samplesOffset) {
					outputData[i - samplesOffset] = getAverage();
				}
			}

			// Gradually trail off the end, in same manner as is done to beginning
			reset();
			for (int i = signalData.length - 1; i >= signalData.length - size; i--) {
				add(signalData[i]);
				if (i < signalData.length - samplesOffset) {
					outputData[i + samplesOffset] = getAverage();
				}
			}

			return outputData;
		}

		/**
		 * Reset the filter
		 */
		public void reset() {
			total = 0;
			index = 0;
			bufferFilled = false;
			for (int i = 0; i < size; i++) samples[i] = 0;
		}
	}


	/**
	 * First-order RC Low Pass Filter
	 *
	 * @author    Simon Bluett
	 * @copyright GNU GPL-v3
	 */
	public class RcLowPass {
		private double timeConstant;
		private double lastOutput;
		private double lastXaxis;
		private boolean filterInitialised;

		/**
		 * Constructor
		 *
		 * @param cutoffFrequeuncy The filter 3dB cutoff frequency (Hz)
		 */
		public RcLowPass(double cutoffFrequency) {
			if (cutoffFrequency <= 0) cutoffFrequency = 1;
			timeConstant = 1 / (2 * Math.PI * cutoffFrequency);
			filterInitialised = false;
		}

		/**
		 * Calculate the next filter output, when provided with the realtime input
		 *
		 * @param  signalData The y-axis data to be filtered
		 * @param  xAxisData  The x-axis value for the current step
		 * @return The filtered output for the current step
		 */
		public double processStep(double signalData, double xAxisData) {
			double outputData;
			if (filterInitialised) {
				double alpha = (xAxisData - lastXaxis) / (timeConstant + (xAxisData - lastXaxis));
				outputData = lastOutput + alpha * (signalData - lastOutput);
			} else {
				outputData = signalData;
				filterInitialised = true;
			}
			lastOutput = outputData;
			lastXaxis = xAxisData;
			return outputData;
		}

		/**
		 * Apply the filter to all the provided signal data at once
		 *
		 * @param  signalData Array containing the y-axis data to be filtered
		 * @param  xAxisData  Array containing the x-axis value for each step
		 * @return Output an array containing the filtered value for each step
		 */
		public double[] process(double[] signalData, double[] xAxisData) {
			double[] outputData = new double[signalData.length];				
			for (int i = 0; i < signalData.length; i++) {
				outputData[i] = processStep(signalData[i], xAxisData[i]);
			}
			return outputData;
		}

		/**
		 * Reset the filter
		 */
		public void reset() {
			filterInitialised = false;
		}
	}


	/**
	 * First-order RC High Pass Filter
	 *
	 * @author    Simon Bluett
	 * @copyright GNU GPL-v3
	 */
	public class RcHighPass {
		private double timeConstant;
		private double lastOutput;
		private double lastInput;
		private double lastXaxis;
		private boolean filterInitialised;

		/**
		 * Constructor
		 *
		 * @param cutoffFrequeuncy The filter 3dB cutoff frequency (Hz)
		 */
		public RcHighPass(double cutoffFrequency) {
			if (cutoffFrequency <= 0) cutoffFrequency = 1;
			timeConstant = 1 / (2 * Math.PI * cutoffFrequency);
			filterInitialised = false;
		}

		/**
		 * Calculate the next filter output, when provided with the realtime input
		 *
		 * @param  signalData The y-axis data to be filtered
		 * @param  xAxisData  The x-axis value for the current step
		 * @return The filtered output for the current step
		 */
		public double processStep(double signalData, double xAxisData) {
			double outputData;
			if (filterInitialised) {
				double alpha = timeConstant / (timeConstant + (xAxisData - lastXaxis));
				outputData = alpha * (lastOutput + signalData - lastInput);
			} else {
				outputData = signalData;
				filterInitialised = true;
			}
			lastOutput = outputData;
			lastInput = signalData;
			lastXaxis = xAxisData;
			return outputData;
		}

		/**
		 * Apply the filter to all the provided signal data at once
		 *
		 * @param  signalData Array containing the y-axis data to be filtered
		 * @param  xAxisData  Array containing the x-axis value for each step
		 * @return Output an array containing the filtered value for each step
		 */
		public double[] process(double[] signalData, double[] xAxisData) {
			double[] outputData = new double[signalData.length];				
			for (int i = 0; i < signalData.length; i++) {
				outputData[i] = processStep(signalData[i], xAxisData[i]);
			}
			return outputData;
		}

		/**
		 * Reset the filter
		 */
		public void reset() {
			filterInitialised = false;
		}
	}


	/**
	 * 1D Total Variation (TV) Noise Removal Algorithm
	 *
	 * @author    Laurent Condat
	 * @copyright CeCILL Licence (compatible with GNU GPL v3)
	 * @note      The algorithm is based on the original C code by 
	 *            Laurent Condat with minor adaptations to encapsulate 
	 *            it in a class and make it work in Java
	 * @website   https://lcondat.github.io/software.html
	 */
	public class DenoiseTv1D {

		public double[] process(double[] input, final double lambda) {
	
			int width = input.length;
			int[] indstart_low = new int[width];
			int[] indstart_up = new int[width];
			double[] output = new double[width];

			int j_low = 0, j_up = 0, jseg = 0, indjseg = 0, i=1;
			int indjseg2, ind;
			double output_low_first = input[0] - lambda;
			double output_low_curr = output_low_first;
			double output_up_first = input[0] + lambda;
			double output_up_curr = output_up_first;
			final double twolambda = 2.0 * lambda;
			if (width == 1) {
				output[0] = input[0];
				return output;
			}
			indstart_low[0] = 0;
			indstart_up[0] = 0;
			width--;
			for (; i<width; i++) {
				if (input[i]>=output_low_curr) {
					if (input[i]<=output_up_curr) {
						output_up_curr+=(input[i]-output_up_curr)/(i-indstart_up[j_up]+1);
						output[indjseg]=output_up_first;
						while ((j_up>jseg)&&(output_up_curr<=output[ind=indstart_up[j_up-1]]))
							output_up_curr+=(output[ind]-output_up_curr)*
								((double)(indstart_up[j_up--]-ind)/(i-ind+1));
						if (j_up==jseg) {
							while ((output_up_curr<=output_low_first)&&(jseg<j_low)) {
								indjseg2=indstart_low[++jseg];
								output_up_curr+=(output_up_curr-output_low_first)*
									((double)(indjseg2-indjseg)/(i-indjseg2+1));
								while (indjseg<indjseg2) output[indjseg++]=output_low_first;
								output_low_first=output[indjseg];
							}
							output_up_first=output_up_curr;
							indstart_up[j_up=jseg]=indjseg;
						} else output[indstart_up[j_up]]=output_up_curr;
					} else 
						output_up_curr=output[i]=input[indstart_up[++j_up]=i];
					output_low_curr+=(input[i]-output_low_curr)/(i-indstart_low[j_low]+1);      
					output[indjseg]=output_low_first;
					while ((j_low>jseg)&&(output_low_curr>=output[ind=indstart_low[j_low-1]]))
						output_low_curr+=(output[ind]-output_low_curr)*
								((double)(indstart_low[j_low--]-ind)/(i-ind+1));	        		
					if (j_low==jseg) {
						while ((output_low_curr>=output_up_first)&&(jseg<j_up)) {
							indjseg2=indstart_up[++jseg];
							output_low_curr+=(output_low_curr-output_up_first)*
								((double)(indjseg2-indjseg)/(i-indjseg2+1));
							while (indjseg<indjseg2) output[indjseg++]=output_up_first;
							output_up_first=output[indjseg];
						}
						if ((indstart_low[j_low=jseg]=indjseg)==i) output_low_first=output_up_first-twolambda;
						else output_low_first=output_low_curr; 
					} else output[indstart_low[j_low]]=output_low_curr;
				} else {
					output_up_curr+=((output_low_curr=output[i]=input[indstart_low[++j_low] = i])-
						output_up_curr)/(i-indstart_up[j_up]+1);
					output[indjseg]=output_up_first;
					while ((j_up>jseg)&&(output_up_curr<=output[ind=indstart_up[j_up-1]]))
						output_up_curr+=(output[ind]-output_up_curr)*
								((double)(indstart_up[j_up--]-ind)/(i-ind+1));
					if (j_up==jseg) {
						while ((output_up_curr<=output_low_first)&&(jseg<j_low)) {
							indjseg2=indstart_low[++jseg];
							output_up_curr+=(output_up_curr-output_low_first)*
								((double)(indjseg2-indjseg)/(i-indjseg2+1));
							while (indjseg<indjseg2) output[indjseg++]=output_low_first;
							output_low_first=output[indjseg];
						}
						if ((indstart_up[j_up=jseg]=indjseg)==i) output_up_first=output_low_first+twolambda;
						else output_up_first=output_up_curr;
					} else output[indstart_up[j_up]]=output_up_curr;
				}
			}
			/* here i==width (with value the actual width minus one) */
			if (input[i]+lambda<=output_low_curr) {
				while (jseg<j_low) {
					indjseg2=indstart_low[++jseg];
					while (indjseg<indjseg2) output[indjseg++]=output_low_first;
					output_low_first=output[indjseg];
				}
				while (indjseg<i) output[indjseg++]=output_low_first;
				output[indjseg]=input[i]+lambda;
			} else if (input[i]-lambda>=output_up_curr) {
				while (jseg<j_up) {
					indjseg2=indstart_up[++jseg];
					while (indjseg<indjseg2) output[indjseg++]=output_up_first;
					output_up_first=output[indjseg];
				}
				while (indjseg<i) output[indjseg++]=output_up_first;
				output[indjseg]=input[i]-lambda;
			} else {
				output_low_curr+=(input[i]+lambda-output_low_curr)/(i-indstart_low[j_low]+1);      
				output[indjseg]=output_low_first;
				while ((j_low>jseg)&&(output_low_curr>=output[ind=indstart_low[j_low-1]]))
					output_low_curr+=(output[ind]-output_low_curr)*
								((double)(indstart_low[j_low--]-ind)/(i-ind+1));	        		
				if (j_low==jseg) {
					if (output_up_first>=output_low_curr)
						while (indjseg<=i) output[indjseg++]=output_low_curr;
					else {
						output_up_curr+=(input[i]-lambda-output_up_curr)/(i-indstart_up[j_up]+1);
						output[indjseg]=output_up_first;
						while ((j_up>jseg)&&(output_up_curr<=output[ind=indstart_up[j_up-1]]))
							output_up_curr+=(output[ind]-output_up_curr)*
								((double)(indstart_up[j_up--]-ind)/(i-ind+1));
						while (jseg<j_up) {
							indjseg2=indstart_up[++jseg];
							while (indjseg<indjseg2) output[indjseg++]=output_up_first;
							output_up_first=output[indjseg];
						}
						indjseg=indstart_up[j_up];
						while (indjseg<=i) output[indjseg++]=output_up_curr;
					}
				} else {
					while (jseg<j_low) {
						indjseg2=indstart_low[++jseg];
						while (indjseg<indjseg2) output[indjseg++]=output_low_first;
						output_low_first=output[indjseg];
					}
					indjseg=indstart_low[j_low];
					while (indjseg<=i) output[indjseg++]=output_low_curr;
				}
			}
			return output;
		}
	}


	/**
	 * Fast Fourier Transform (FFT) to analyse frequency response of a signal
	 *
	 * @author    Numerical Recipes chapter on FFTs
	 * @copyright Apache Licence (compatible with GNU GPL v3)
	 */
	public class FastFourierTransform {

		public double[] processForward(double[] signalData, double samplingFrequency, double[] frequencyAxis)
		{
			// Figure out length of FFT (it must be a factor of 2)
			int signalLength = signalData.length;
			int pt = signalLength;
			pt--;
			pt |= pt >> 1;
			pt |= pt >> 2;
			pt |= pt >> 4;
			pt |= pt >> 8;
			pt |= pt >> 16;
			pt++;

			// Generate the complex data array
			double[] complexArray = new double[pt * 2];
			for (int i = 0; i < pt * 2; i++) complexArray[i] = 0;
			for (int i = 0; i < signalLength; i++) complexArray[i * 2] = signalData[i];

			// Calculate the FFT
			fft(complexArray, pt, 1);

			// Get the amplitude of the complex number
			double[] amplitudeArray = new double[signalLength];
			for (int i = 0; i < signalLength; i++) {
				amplitudeArray[i] = java.lang.Math.sqrt((complexArray[i * 2] * complexArray[i * 2]) + (complexArray[i*2 + 1] * complexArray[i*2 + 1]));
			}

			// Generate the frequency axis
			//frequencyAxis = new double[signalLength];
			if (frequencyAxis != null && frequencyAxis.length >= signalData.length) {
				for (int i = 0; i < signalLength; i++) frequencyAxis[i] = i * samplingFrequency / pt;
			}

			return amplitudeArray;
		}
		

		public void fft(double[] data, int noOfSamples, int direction)
		{
			//variables for trigonometric recurrences
			int i, j, n, m, mmax, istep;
			double wr, wpr, wi, wpi, wtemp, tempr, tempi, theta;

			// The complex array is real+complex so the array has a 
			// size n = 2* number of complex samples. The real part 
			// is the data[index] and the complex part is the data[index+1]
			n = noOfSamples * 2;

			// Binary inversion (real = even-indexes, complex = odd-indexes)
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

				//print(i); print(" , "); println(j);
			}

			// Danielson-Lanzcos routine
			mmax = 2;

			// External loop
			while (n > mmax) {
				istep = mmax << 1;
				theta = direction * (2 * PI / mmax);
				wtemp = java.lang.Math.sin(0.5 * theta);
				wpr = -2.0 * wtemp * wtemp;
				wpi = java.lang.Math.sin(theta);
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
	}


	/**
	 * Enclosed Area Calculation
	 *
	 * @author    Simon Bluett
	 * @copyright GNU GPL-v3
	 */
	public class AreaCalculation {

		/**
		 * Calculate the area of enclosed cycles/loops in the data
		 * @param[in]  xData  X-axis data
		 * @param[in]  yData  Y-axis data
		 */
		public double[] processCycles(double[] xData, double[] yData) {

			// Detect cycles in the data, which correspond to enclosed areas
			int[] cycleEnd = detectCycles(xData, yData);
			double[] calculatedArea = null;
			//println("CycleEnd.length = " + cycleEnd.length);

			if ((cycleEnd != null) && (cycleEnd.length > 1)) {
				calculatedArea = new double[0];

				for (int i = 1; i < cycleEnd.length; i++) {

					double currentArea = 0;

					// Apply the discrete version of Green's Theorem (Pick's Theorem)
					// Based on formula in DOI: 10.1117/1.JEI.26.6.063022
					for (int j = cycleEnd[i - 1]; j < cycleEnd[i] - 1; j++) {
						double areaSlice = ((xData[j] * yData[j+1]) - (yData[j] * xData[j + 1])) / 2.0;
						currentArea += areaSlice;
						//println(areaSlice);
					}

					// Ensure the cycle is closed
					currentArea += ((xData[cycleEnd[i]-1] * yData[cycleEnd[i - 1]]) - (yData[cycleEnd[i] - 1] * xData[cycleEnd[i - 1]])) / 2.0;
					currentArea = java.lang.Math.abs(currentArea);
					calculatedArea = (double[])append(calculatedArea, currentArea);
					//println(currentArea);
				}
			}

			return calculatedArea;
		}

		/**
		 * Detect whether the data forms a closed loop
		 * @param[in]  xData  X-axis data
		 * @param[in]  yData  Y-axis data
		 * @return     An array of the indices where one cycle ends and a new one starts
		 */
		public int[] detectCycles(double[] xData, double[] yData) {

			if (xData == null || yData == null || (xData.length != yData.length) || xData.length < 3) return null;

			int[] cycleEnd = { 0 };
			double[] startPoint = { xData[0], yData[0] };
			double avgStepDistance = distance(xData[0], yData[0], xData[1], yData[1]);
			double avgXstep = java.lang.Math.abs(xData[1] - xData[0]);
			double avgYstep = java.lang.Math.abs(yData[1] - yData[0]);

			for (int i = 2; i < xData.length; i++) {
				// Update the average distance between points
				avgStepDistance = ((avgStepDistance * i) + distance(xData[i-1], yData[i-1], xData[i], yData[i])) / (double)(i + 1);
				avgXstep = ((avgXstep * i) + java.lang.Math.abs(xData[i] - xData[i-1])) / (double)(i + 1);
				avgYstep = ((avgYstep * i) + java.lang.Math.abs(yData[i] - yData[i-1])) / (double)(i + 1);

				// If the current point is closer to the start point than half the
				// average distance, then a full loop has probably been completed
				double currentDistance = distance(startPoint[0], startPoint[1], xData[i], yData[i]);
				if  (
					  (currentDistance < avgStepDistance * 0.5) 
					  && (java.lang.Math.abs(xData[i] - startPoint[0]) < avgXstep * 0.5)
					  && (java.lang.Math.abs(yData[i] - startPoint[1]) < avgYstep * 0.5)
					) {
					cycleEnd = append(cycleEnd, i);
					startPoint[0] = xData[i];
					startPoint[1] = yData[i];
					//println("Index: " + i + ", Avg Step: " + avgStepDistance + ", Dist: " + currentDistance + ", Avg X: " + avgXstep);

					// Increment twice to prevent the next point from triggering a loop detection
					i++;
				}
			}

			return cycleEnd;
		}

		/**
		 * Calculate the distance between two coordinates
		 * @param[in]  x1  X-value of point A
		 * @param[in]  y1  Y-value of point A
		 * @param[in]  x2  X-value of point B
		 * @param[in]  y2  Y-value of point B
		 * @return     The euclidean distance between two points
		 */
		private double distance(double x1, double y1, double x2, double y2) {
			return java.lang.Math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1));
		}
	}
}