/**
 * 
 */
package org.hoetten.bioenergie;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.swing.JScrollPane;

import org.jgraph.JGraph;
import org.jgrapht.DirectedGraph;
import org.jgrapht.alg.StrongConnectivityInspector;
import org.jgrapht.alg.cycle.JohnsonSimpleCycles;
import org.jgrapht.alg.cycle.SzwarcfiterLauerSimpleCycles;
import org.jgrapht.ext.VisioExporter;
import org.jgrapht.graph.DefaultDirectedGraph;
import org.jgrapht.graph.DefaultDirectedWeightedGraph;
import org.jgrapht.graph.DefaultEdge;
import org.jgrapht.graph.DefaultWeightedEdge;
import org.jgrapht.graph.DirectedSubgraph;

/**
 *
 * @author simon
 * @version 27.01.2015
 * @package bioenergie
 *
 */
public class Graphalyzer {
	
	private String path;
	private boolean weighted;
	private DefaultDirectedGraph<Integer, DefaultEdge> graph;
	private DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge> graphW;
	private ArrayList<Vertex> vertices;
	private List<List<Integer>> cycles;

	public Graphalyzer(String path, boolean weighted) {
		this.path = path;
		this.vertices = new ArrayList<Vertex>();
		this.weighted = weighted;
		if (weighted) {
			this.graphW = new DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge>(DefaultWeightedEdge.class);
		} else {
			this.graph = new DefaultDirectedGraph<Integer, DefaultEdge>(DefaultEdge.class);
		}
	}

	public void readDirectedGraph() {
		this.readVertices();
		
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
						if (weighted) {
							DefaultWeightedEdge e = this.graphW.addEdge(this.vertices.get(from).getId(), this.vertices.get(to).getId());
							this.graphW.setEdgeWeight(e, weight);
						} else {
							this.graph.addEdge(this.vertices.get(from).getId(), this.vertices.get(to).getId());
						}
				        System.out.println("Added edge from "
				        		+ from + ": " + this.vertices.get(from).getLabel()
				        		+ " to "
				        		+ to + ": " + this.vertices.get(to).getLabel()
				        		+ " with weight " + weight);
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

	private void readVertices() {

		BufferedReader br = null;
		try {
			br = new BufferedReader(new FileReader(this.path + "/nodes.csv"));
			String line = br.readLine();

			for (int i = 0; line != null; i++) {	
				Vertex v = new Vertex(i, line);
				
				this.vertices.add(v);
				if (weighted)
					this.graphW.addVertex(v.getId());
				else
					this.graph.addVertex(v.getId());
				
				System.out.println("Added " + v);

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
	
	public void calculateSCC() {
		// computes all the strongly connected components of the directed graph
        StrongConnectivityInspector<Integer, DefaultWeightedEdge> sci =
            new StrongConnectivityInspector<Integer, DefaultWeightedEdge>(this.graphW);
        List<DirectedSubgraph<Integer, DefaultWeightedEdge>> stronglyConnectedSubgraphs = sci.stronglyConnectedSubgraphs();

        // prints the strongly connected components
        System.out.println("Strongly connected components:");
        for (int i = 0; i < stronglyConnectedSubgraphs.size(); i++) {
            System.out.println(stronglyConnectedSubgraphs.get(i));
        }
        System.out.println();
	}
	
	public void calculateCycles() {
		JohnsonSimpleCycles<Integer, DefaultWeightedEdge> cycleDetector = new JohnsonSimpleCycles<Integer, DefaultWeightedEdge>();
//		SzwarcfiterLauerSimpleCycles<Integer, DefaultWeightedEdge> cycleDetector = new SzwarcfiterLauerSimpleCycles<Integer, DefaultWeightedEdge>();
		cycleDetector.setGraph(this.graphW);
		
		this.cycles = cycleDetector.findSimpleCycles();
		System.out.println("Found " + this.cycles.size() + " cycles.");
		System.out.println(this.cycles);
		
	}
	
	
	public void visioExport(String file) {
		VisioExporter<Integer, DefaultWeightedEdge> exporter = new VisioExporter<Integer, DefaultWeightedEdge>();
		try {
			exporter.export(new FileOutputStream(file), this.graphW);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
}
