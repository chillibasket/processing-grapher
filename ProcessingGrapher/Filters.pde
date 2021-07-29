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
 * Copyright (C) 2021 - Simon Bluett <hello@chillibasket.com>
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
	                       "h:More coming soon!"};

	String[] filterSlug = {"h", "avg", "tv", "lp", "hp", "h", "abs", "squ", "Δ/dt", "Σdt", "h"};

	/**
	 * Default Constructor
	 */
	Filters() {
		// Empty
	}


	/**
	 * Run the specified filter on the provided data
	 */
	public double[] runFilter(int filterType, double[] signalData, double[] xAxisData) {

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
	 * @copyright CeCILL Licence (compatible with GNU GPL v2)
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

}