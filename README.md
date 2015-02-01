biovis
============
Analyse und Visualisierung von causal-loop Diagrammen.

ToDo
------------
- arrows
- +/- arrow types
- node colors
- auto resize on change of parent size
- feedback loop visualization
- filters (by category and degree of consent)
- search

Ideen
------------
- d3.js
- Node-Kategorien durch Farben visualisiert
- Bei Klick auf Node
	- Feedbackloops durch Einfärbung der Kanten
		- Berechnung durch Strongly Connected Components
		- http://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
	- Anzeige der Zentralität (Degree)
	- Wahlweise Anzeige der Nachbarknoten (see http://visjs.org/examples/network/29_neighbourhood_highlight.html)
- Größe der Nodes über Zentralität
- Import von Gephi (see http://visjs.org/examples/network/30_importing_from_gephi.html)
- Konsensindikator eines Feedbackloops