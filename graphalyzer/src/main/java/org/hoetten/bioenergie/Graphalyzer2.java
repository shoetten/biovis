package org.hoetten.bioenergie;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

import jgraphalgos.WeightedEdge;
import jgraphalgos.johnson.Johnson;
import jgraphalgos.johnson.Johnson.JohnsonIllegalStateException;
import edu.uci.ics.jung.graph.DirectedGraph;
import edu.uci.ics.jung.graph.DirectedSparseGraph;

public class Graphalyzer2 {
	
	private String path;
	private DirectedGraph<Integer, WeightedEdge> dsg;
	
	public Graphalyzer2(String path) {
		this.path = path;
		this.dsg = new DirectedSparseGraph<Integer, WeightedEdge>();
	}
	
	
	public void readDirectedGraph() {
	
		BufferedReader br = null;
		try {
			br = new BufferedReader(new FileReader(this.path + "edges.csv"));
			br.readLine(); //skip first line (column titles)
			String line = br.readLine();
			
			for (int from = 0; line != null; from++) {
				String[] split = line.split(";");
				for (int to = 0; to < split.length -1; to++) {
					int weight = Integer.parseInt(split[to+1]);
					if (weight != 0) {
				        
				        dsg.addEdge(new WeightedEdge((float) weight), from, to);

				        System.out.println("Added edge from "
				        		+ from + " to "
				        		+ to + " with weight " + weight);
					}
				}
				line = br.readLine();
			}

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				br.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		
	}
	
	public void calculateCycles() {
        Johnson j = new Johnson(dsg);
        try {
			j.findCircuits();
			
			System.out.println("Found " + j.getCircuits().size() + " cycles.");
			System.out.println(j.getCircuits());
		} catch (JohnsonIllegalStateException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
