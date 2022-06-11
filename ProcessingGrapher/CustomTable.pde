/* * * * * * * * * * * * * * * * * * * * * * *
 * CUSTOM-TABLE CLASS
 * extends Processing Table Class
 *
 * @file     CustomTable.pde
 * @brief    Extend Table class with additional saving options
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    CustomTable
 * @see      Table <Processing core/data/Table.java>
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

class CustomTable extends Table {

	protected boolean csvStreamActive = false;
	protected PrintWriter csvWriter;


	/**
	 * Open an output stream where table rows can be saved
	 *
	 * @param  filename : The file name/location where output should be saved
	 * @return True if successful, false if function is unable to initialise output file
	 */

	public boolean openCSVoutput(String filename) {

		try {
			// Figure out location and make sure the target path exists
			File outputFile = saveFile(filename);

			// Open the writer
			csvWriter = PApplet.createWriter(outputFile);

			// Print the header row
			if (hasColumnTitles()) {
				for (int col = 0; col < getColumnCount(); col++) {
					if (col != 0) {
						csvWriter.print(',');
					}
					try {
						if (getColumnTitle(col) != null) {  // col < columnTitles.length &&
							writeEntryCSV(csvWriter, getColumnTitle(col));
						}
					} catch (ArrayIndexOutOfBoundsException e) {
						PApplet.printArray(getColumnTitles());
						PApplet.printArray(columns);
						throw e;
					}
				}
				csvWriter.println();
			}

			csvStreamActive = true;
			return true;

		} catch (Exception e) {
			println("Error opening up CSV output file stream: " + e);
			printStackTrace(e);
			return false;
		}

	}


	/**
	 * Add save new data rows to the current output file
	 *
	 * @param  indexA : Row index where to start saving from (inclusive)
	 * @param  indexB : Row index of last row to be saved (inclusive)
	 * @return Whether save operation was successful
	 */

	public boolean saveCSVentries(int indexA, int indexB) {

		// Entries can only be saved if csv output stream is open
		if (!csvStreamActive) {
			println("Error saving CSV entries; the output stream hasn't been initialised");
			return false;
		}

		// Check that the index values are within bounds
		if (indexA < 0 || indexB >= rowCount || indexA > indexB) {
			println("Error saving CSV entries; the index parameters are out of bounds");
			return false;
		}

		try {
			// Save the specified rows
			for (int row = indexA; row < indexB + 1; row++) {
				for (int col = 0; col < getColumnCount(); col++) {
					if (col != 0) {
						csvWriter.print(',');
					}
					String entry = getString(row, col);
					// just write null entries as blanks, rather than spewing 'null'
					// all over the spreadsheet file.
					if (entry != null) {
						writeEntryCSV(csvWriter, entry);
					}
				}
				// Prints the newline for the row, even if it's missing
				csvWriter.println();
			}

			if (csvWriter.checkError()) return false;
			return true;

		} catch (Exception e) {
			println("Error saving CSV entries " + e);
			printStackTrace(e);
			return false;
		}
	}


	/**
	 * Close the CSV output stream
	 */

	public boolean closeCSVoutput() {
		if (csvStreamActive) {
			csvStreamActive = false;

			if (csvWriter.checkError()) {
				csvWriter.close();
				return false;
			}

			csvWriter.close();
		}

		return true;
	}
	
}