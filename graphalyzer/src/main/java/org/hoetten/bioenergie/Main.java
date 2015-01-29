/**
 * 
 */
package org.hoetten.bioenergie;

/**
 *
 * @author simon
 * @version 29.01.2015
 * @package org.hoetten.bioenergie
 *
 */
public class Main {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		Graphalyzer graphalyzer = new Graphalyzer("data/test/", true);
		graphalyzer.readDirectedGraph();

		graphalyzer.calculateSCC();
		graphalyzer.calculateCycles();
		
		System.out.println("\n");
		
		Graphalyzer2 graphalyzer2 = new Graphalyzer2("data/test/");
		graphalyzer2.readDirectedGraph();
		graphalyzer2.calculateCycles();

	}

}
