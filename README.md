biovis
============
Analyse und Visualisierung von causal-loop Diagrammen.

ToDo
------------
- +/- arrow types
- node category colors
- feedback loop visualization
- filters (by category and degree of consent)
- search
- meta info of node in sidebar
	add node description
	- add type of influence in list (+/-)
	- tooltip on hover (e.g. "Mehr x verursacht weniger y")
- zoom to node

Ideen
------------
- [d3.js](http://d3js.org/)
- [networkx](https://networkx.github.io/)
- Node-Kategorien durch Farben visualisiert
- Bei Klick auf Node
	- Feedbackloops durch Einfärbung der Kanten (Berechnung nach D.B. Johnson, Implementierung in [networkx](https://networkx.github.io/documentation/latest/reference/generated/networkx.algorithms.cycles.simple_cycles.html))
	- Anzeige der Zentralität (Degree)
	- Wahlweise Anzeige der Nachbarknoten
- Größe der Nodes über Zentralität
- Konsensindikator eines Feedbackloops
