import csv
import networkx as nx


G = nx.DiGraph()

# read graph from csv
with open('data/graph.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile, delimiter=';', quotechar='"')
	for rowIdx, row in enumerate(reader):
			for colIdx, column in enumerate(row):
				if colIdx != 0:
					if rowIdx == 0:										# use first row for labels
						G.add_node(colIdx, name=column)
					else:
						weight = int(column)						# get int value of string
						if weight != 0:
							G.add_edge(rowIdx, colIdx, weight=weight)

# analyze graph
print G.nodes()
# print G.edges()
print list(nx.strongly_connected_components(G))
# print len(list(nx.simple_cycles(G)))
