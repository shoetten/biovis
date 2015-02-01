biovis
============
Analyse und Visualisierung von causal-loop Diagrammen.

ToDo
------------
- +/- arrow types
- node colors & size
- auto resize on change of parent size
- feedback loop visualization
- filters (by category and degree of consent)
- search
- zoom & pan
- meta info of node in sidebar
- zoom to node

Ideen
------------
- [d3.js](http://d3js.org/)
- [networkx](https://networkx.github.io/)
- Node-Kategorien durch Farben visualisiert
- Bei Klick auf Node
	- Feedbackloops durch Einfärbung der Kanten (Berechnung nach D.B. Johnson, Implementierung in [networkx](https://networkx.github.io/documentation/latest/reference/generated/networkx.algorithms.cycles.simple_cycles.html))
	- Anzeige der Zentralität (Degree)
	- Wahlweise Anzeige der Nachbarknoten (see http://visjs.org/examples/network/29_neighbourhood_highlight.html)
- Größe der Nodes über Zentralität
- Konsensindikator eines Feedbackloops
