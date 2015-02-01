/** 
 * Draws graph with vis.js
 */


var PREFIX = "";


var network;

var nodes = new vis.DataSet();
var edges = new vis.DataSet();
var gephiImported;

var allowedToMoveCheckbox = document.getElementById("allowedToMove");
allowedToMoveCheckbox.onchange = redrawAll;

var parseColorCheckbox = document.getElementById("parseColor");
parseColorCheckbox.onchange = redrawAll;

var nodeContent = document.getElementById("nodeContent");
var edgeContent = document.getElementById("edgeContent");

loadJSON(PREFIX + "/data/bioenergie.json", redrawAll);

var container = document.getElementById('bioGraph');

var data = {
    nodes: nodes,
    edges: edges
};
var options = {
    nodes: {
        shape: 'dot',
        fontFace: "Tahoma"
    },
    edges: {
    		style: 'arrow',
        width: 0.15,
        inheritColor: "from"
    },
    tooltip: {
        delay: 200,
        fontSize: 12,
        color: {
            background: "#fff"
        }
    },
    smoothCurves: {dynamic:false, type: "continuous"},
    stabilize: false,
    physics: {barnesHut: {gravitationalConstant: -10000, springConstant: 0.002, springLength: 150}},
    configurePhysics: true,
    hideEdgesOnDrag: true
};

network = new vis.Network(container, data, options);
network.on("click",onClick);


/**
 * This function fills the DataSets. These DataSets will update the network.
 */
function redrawAll(gephiJSON) {
    if (gephiJSON.nodes === undefined) {
        gephiJSON = gephiImported;
    }
    else {
        gephiImported = gephiJSON;
    }

    nodes.clear();
    edges.clear();

    var allowedToMove = allowedToMoveCheckbox.checked;
    var parseColor = parseColorCheckbox.checked;
    var parsed = vis.network.gephiParser.parseGephi(gephiJSON, {allowedToMove:allowedToMove, parseColor:parseColor});

    // add the parsed data to the DataSets.
    nodes.add(parsed.nodes);
    edges.add(parsed.edges);

    var data = edges.get(92); // get the data from node 2
    edgeContent.innerHTML = syntaxHighlight(data);

    network.zoomExtent(); // zoom to fit
}

jQuery(document).ready(function($) {
	var physicsHidden = true;
	$('.PhysicsConfiguration').hide();

	// add mouse events to settings
	$('#settings #showPhysics').click(function() {
		if(physicsHidden) {
			$(this).text('Hide physics settings');
			$('.PhysicsConfiguration').fadeIn(150);
			physicsHidden = false;
		} else {
			$(this).text('Show physics settings');
			$('.PhysicsConfiguration').fadeOut(150);
			physicsHidden = true;
		}
		return false;
	});
});

function loadJSON(path, success, error) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                success(JSON.parse(xhr.responseText));
            }
            else {
                error(xhr);
            }
        }
    };
    xhr.open("GET", path, true);
    xhr.send();
}

// from http://stackoverflow.com/questions/4810841/how-can-i-pretty-print-json-using-javascript
function syntaxHighlight(json) {
    if (typeof json != 'string') {
        json = JSON.stringify(json, undefined, 2);
    }
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
        var cls = 'number';
        if (/^"/.test(match)) {
            if (/:$/.test(match)) {
                cls = 'key';
            } else {
                cls = 'string';
            }
        } else if (/true|false/.test(match)) {
            cls = 'boolean';
        } else if (/null/.test(match)) {
            cls = 'null';
        }
        return '<span class="' + cls + '">' + match + '</span>';
    });
}





function onClick(selectedItems) {
    var nodeId;
    var degrees = 1;
    // we get all data from the dataset once to avoid updating multiple times.
    var allNodes = nodes.get({returnType:"Object"});
    if (selectedItems.nodes.length == 0) {
        // restore on unselect
        
        nodeContent.innerHTML = "No node selected";
        
        for (nodeId in allNodes) {
            if (allNodes.hasOwnProperty(nodeId)) {
                allNodes[nodeId].color = undefined;
                if (allNodes[nodeId].oldLabel !== undefined) {
                    allNodes[nodeId].label = allNodes[nodeId].oldLabel;
                    allNodes[nodeId].oldLabel = undefined;
                }
                allNodes[nodeId]['levelOfSeperation'] = undefined;
                allNodes[nodeId]['inConnectionList'] = undefined;
            }
        }
    }
    else {
        var allEdges = edges.get();

        // we clear the level of separation in all nodes.
        clearLevelOfSeperation(allNodes);

        // we will now start to collect all the connected nodes we want to highlight.
        var connectedNodes = selectedItems.nodes;

        nodeContent.innerHTML = syntaxHighlight(nodes.get(connectedNodes[0])); // show the data in the div

        // we can store them into levels of separation and we could then later use this to define a color per level
        // any data can be added to a node, this is just stored in the nodeObject.
        storeLevelOfSeperation(connectedNodes,0, allNodes);
        for (var i = 1; i < degrees + 1; i++) {
            appendConnectedNodes(connectedNodes, allEdges);
            storeLevelOfSeperation(connectedNodes, i, allNodes);
        }
        for (nodeId in allNodes) {
            if (allNodes.hasOwnProperty(nodeId)) {
                if (allNodes[nodeId]['inConnectionList'] == true) {
                    if (allNodes[nodeId]['levelOfSeperation'] !== undefined) {
                        if (allNodes[nodeId]['levelOfSeperation'] >= 2) {
                            allNodes[nodeId].color = 'rgba(150,150,150,0.75)';
                        }
                        else {
                            allNodes[nodeId].color = undefined;
                        }
                    }
                    else {
                        allNodes[nodeId].color = undefined;
                    }
                    if (allNodes[nodeId].oldLabel !== undefined) {
                        allNodes[nodeId].label = allNodes[nodeId].oldLabel;
                        allNodes[nodeId].oldLabel = undefined;
                    }
                }
                else {
                    allNodes[nodeId].color = 'rgba(200,200,200,0.5)';
                    if (allNodes[nodeId].oldLabel === undefined) {
                        allNodes[nodeId].oldLabel = allNodes[nodeId].label;
                        allNodes[nodeId].label = "";
                    }
                }
            }
        }
    }
    var updateArray = [];
    for (nodeId in allNodes) {
        if (allNodes.hasOwnProperty(nodeId)) {
            updateArray.push(allNodes[nodeId]);
        }
    }
    nodes.update(updateArray);
}


/**
 * update the allNodes object with the level of separation.
 * Arrays are passed by reference, we do not need to return them because we are working in the same object.
 */
function storeLevelOfSeperation(connectedNodes, level, allNodes) {
    for (var i = 0; i < connectedNodes.length; i++) {
        var nodeId = connectedNodes[i];
        if (allNodes[nodeId]['levelOfSeperation'] === undefined) {
            allNodes[nodeId]['levelOfSeperation'] = level;
        }
        allNodes[nodeId]['inConnectionList'] = true;
    }
}

function clearLevelOfSeperation(allNodes) {
    for (var nodeId in allNodes) {
        if (allNodes.hasOwnProperty(nodeId)) {
            allNodes[nodeId]['levelOfSeperation'] = undefined;
            allNodes[nodeId]['inConnectionList'] = undefined;
        }
    }
}

/**
 * Add the connected nodes to the list of nodes we already have
 *
 *
 */
function appendConnectedNodes(sourceNodes, allEdges) {
    var tempSourceNodes = [];
    // first we make a copy of the nodes so we do not extend the array we loop over.
    for (var i = 0; i < sourceNodes.length; i++) {
        tempSourceNodes.push(sourceNodes[i])
    }

    for (var i = 0; i < tempSourceNodes.length; i++) {
        var nodeId = tempSourceNodes[i];
        if (sourceNodes.indexOf(nodeId) == -1) {
            sourceNodes.push(nodeId);
        }
        addUnique(getConnectedNodes(nodeId, allEdges),sourceNodes);
    }
    tempSourceNodes = null;
}

/**
 * Join two arrays without duplicates
 * @param fromArray
 * @param toArray
 */
function addUnique(fromArray, toArray) {
    for (var i = 0; i < fromArray.length; i++) {
        if (toArray.indexOf(fromArray[i]) == -1) {
            toArray.push(fromArray[i]);
        }
    }
}

/**
 * Get a list of nodes that are connected to the supplied nodeId with edges.
 * @param nodeId
 * @returns {Array}
 */
function getConnectedNodes(nodeId, allEdges) {
    var edgesArray = allEdges;
    var connectedNodes = [];

    for (var i = 0; i < edgesArray.length; i++) {
        var edge = edgesArray[i];
        if (edge.to == nodeId) {
            connectedNodes.push(edge.from);
        }
        else if (edge.from == nodeId) {
            connectedNodes.push(edge.to)
        }
    }
    return connectedNodes;
}



