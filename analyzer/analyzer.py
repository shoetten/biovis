import csv
import networkx as nx
import operator


G = nx.DiGraph()							# new directed graph

######## read graph from csv
############################
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


############## analyze graph
############################
print "Nodes:",len(G)
print "Edges:",len(G.edges())
# print G.edges()

### centrality
degrees = nx.degree_centrality(G)
sorted_degrees = sorted(degrees.items(), key=operator.itemgetter(1), reverse=True)		# sort for degree
names = nx.get_node_attributes(G,'name')

for node in sorted_degrees:
	print G.degree(node[0]), node[0],":",names[node[0]]

absDegrees = {k: round(v*len(G)-1) for k, v in degrees.items()}
# print absDegrees


##### cycle (loops) analysis
############################
copyG = G.copy()
copyG.remove_node(6)		# remove pflanzenanbau

print "SCCs:", list(nx.strongly_connected_components(copyG))
print "Cycles:",len(list(nx.simple_cycles(copyG)))
