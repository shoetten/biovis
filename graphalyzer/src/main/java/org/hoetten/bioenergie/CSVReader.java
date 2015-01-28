/**
 * 
 */
package org.hoetten.bioenergie;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.jgrapht.alg.cycle.JohnsonSimpleCycles;
import org.jgrapht.alg.cycle.SzwarcfiterLauerSimpleCycles;
import org.jgrapht.graph.DefaultDirectedWeightedGraph;
import org.jgrapht.graph.DefaultWeightedEdge;

/**
 *
 * @author simon
 * @version 27.01.2015
 * @package bioenergie
 *
 */
public class CSVReader {
	
	public static void main(String[] args) {
		CSVReader reader = new CSVReader("data/");
		DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge> graph = reader.readDirectedWeightedGraph();
		reader.calculateCycles();
	}

	private String path;
	private DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge> graph;
	private ArrayList<Vertex> vertices;
	private List<List<Integer>> cycles;

	public CSVReader(String path) {
		this.path = path;
		this.vertices = new ArrayList<Vertex>();
		this.graph = new DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge>(DefaultWeightedEdge.class);
	}

	public DefaultDirectedWeightedGraph<Integer, DefaultWeightedEdge> readDirectedWeightedGraph() {
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
						DefaultWeightedEdge e = this.graph.addEdge(this.vertices.get(from).getId(), this.vertices.get(to).getId());
				        this.graph.setEdgeWeight(e, weight);
				        System.out.println("Added edge from "
				        		+ this.vertices.get(from).getLabel()
				        		+ " to "
				        		+ this.vertices.get(to).getLabel()
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
		
		return graph;
	}

	private void readVertices() {

		BufferedReader br = null;
		try {
			br = new BufferedReader(new FileReader(this.path + "/nodes.csv"));
			br.readLine(); //skip first line (column titles)
			String line = br.readLine();

			for (int i = 0; line != null; i++) {
				String[] split = line.split(";");
				
				Vertex v = new Vertex(i, split[1]);
				
				this.vertices.add(v);
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
	
	public void calculateCycles() {
		JohnsonSimpleCycles<Integer, DefaultWeightedEdge> cycleDetector = new JohnsonSimpleCycles<Integer, DefaultWeightedEdge>();
//		SzwarcfiterLauerSimpleCycles<Integer, DefaultWeightedEdge> cycleDetector = new SzwarcfiterLauerSimpleCycles<Integer, DefaultWeightedEdge>();
		cycleDetector.setGraph(this.graph);
		
		this.cycles = cycleDetector.findSimpleCycles();
		System.out.println(this.cycles.size());
	}
}
