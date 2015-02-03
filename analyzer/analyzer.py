import csv
import networkx as nx
import json
from networkx.readwrite import json_graph

import operator


G = nx.DiGraph()							# new directed graph
categoryNames = ["Umwelt","Politik","Technologie","Wirtschaft"]

######## read graph from csv
############################
with open('data/graph.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile, delimiter=';', quotechar='"')
	for rowIdx, row in enumerate(reader):
		d = dict()
		for colIdx, column in enumerate(row):
			if (colIdx < 4) and (rowIdx != 0):
				column = int(column)							# get int value of string
				if (column > 8):
					d[categoryNames[colIdx]] = column
					
			elif (colIdx >= 5):
				if rowIdx == 0:										# use first row for labels
					# print "Added node",colIdx-5,column
					G.add_node(colIdx-5, name=column)
				else:
					weight = int(column)						# get int value of string
					if weight != 0:
						# print "Added edge from",rowIdx-1,"to",colIdx-5
						G.add_edge(rowIdx-1, colIdx-5, weight=weight)
		if (rowIdx != 0):
			G.node[rowIdx-1]['category'] = d


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
	G.node[node[0]]['degree'] = G.degree(node[0])						# adds node degree as attribute
	G.node[node[0]]['category'] = sorted(G.node[node[0]]['category'].items(), key=operator.itemgetter(1), reverse=True)
	G.node[node[0]]['category'] = [val[0] for val in G.node[node[0]]['category']]
	print G.degree(node[0]), node[0],":",names[node[0]],"categories:",G.node[node[0]]['category']


##### cycle (loops) analysis
############################
# copyG = G.copy()
# copyG.remove_node(6)		# remove pflanzenanbau

print "SCCs:", list(nx.strongly_connected_components(G))
# print "Cycles:",len(list(nx.simple_cycles(copyG)))


######### export json for d3
############################
# write json formatted data
data = json_graph.node_link_data(G)				# node-link format to serialize
# write json
json.dump(data, open('out/graph.json','w'))
print('Wrote node-link JSON data to out/graph.json')
