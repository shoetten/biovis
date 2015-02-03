// Generated by CoffeeScript 1.7.1
(function() {
  var Network, PREFIX, debug, root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  PREFIX = "";

  debug = true;

  Network = function() {
    var allData, collide, color, container, curLinksData, curNodesData, drag, dragended, dragged, dragstarted, filterLinks, filterNodes, force, forceTick, height, hideDetails, link, linkPath, linkedByIndex, linksG, mapNodes, neighboring, network, node, nodesG, setSize, setupData, showDetails, tip, update, updateLinks, updateNodes, vis, width, xScale, yScale, zoom, zoomed;
    width = 700;
    height = 600;
    vis = null;
    container = null;
    nodesG = null;
    linksG = null;
    node = null;
    link = null;
    allData = [];
    curLinksData = [];
    curNodesData = [];
    linkedByIndex = {};
    color = d3.scale.ordinal().range(["#1f77b4", "#fd8d3c", "#74c476", "#9467bd"]);
    tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return d.name;
    }).direction('n').offset(function(d) {
      return [-(d.radius / 2 + 3), 0];
    });
    force = d3.layout.force().charge(-250).linkDistance(120).size([width, height]);
    xScale = d3.scale.linear().domain([0, width]).range([0, width]);
    yScale = d3.scale.linear().domain([0, height]).range([0, height]);
    zoomed = function() {
      return forceTick();
    };
    dragstarted = function(d) {
      d3.event.sourceEvent.stopPropagation();
      return d3.select(this).classed("dragging", true);
    };
    dragged = function(d) {
      var mouse;
      console.log("DRAG");
      mouse = d3.mouse(vis.node());
      d.x = xScale.invert(mouse[0]);
      d.y = yScale.invert(mouse[1]);
      if (debug) {
        return console.log("drag", mouse[0], mouse[1], "scaled:", xScale.invert(mouse[0]), yScale.invert(mouse[1]));
      }
    };
    dragended = function(d) {
      return d3.select(this).classed("dragging", false);
    };
    zoom = d3.behavior.zoom().x(xScale).y(yScale).scaleExtent([1, 10]).on("zoom", zoomed);
    drag = force.drag().origin(function(d) {
      return d;
    }).on("dragstart", dragstarted).on("drag", dragged).on("dragend", dragended);
    network = function(selection, graph) {
      var defs;
      vis = d3.select(selection).append("svg").attr("width", width).attr("height", height).call(zoom);
      allData = setupData(graph);
      container = vis.append("g");
      linksG = container.append("g").attr("id", "links");
      nodesG = container.append("g").attr("id", "nodes");
      defs = vis.append("defs");
      defs.selectAll("marker").data(["arrowhead", "arrowhead-background", "arrowhead-highlight"]).enter().append("marker").attr("id", function(d) {
        return d;
      }).attr("viewBox", "0 -5 10 10").attr("refX", 11).attr("refY", 0).attr("markerWidth", 11).attr("markerHeight", 11).attr("orient", "auto").append("path").attr("d", "M0,-5L10,0L0,5 L0,-5").attr("class", function(d) {
        return d;
      });
      vis.call(tip);
      force.on("tick", forceTick);
      return update();
    };
    update = function() {
      curNodesData = allData.nodes;
      curLinksData = allData.links;
      force.nodes(curNodesData);
      force.links(curLinksData);
      updateNodes();
      updateLinks();
      force.start();
      return setSize();
    };
    forceTick = function() {
      link.attr("d", function(d) {
        return linkPath(d);
      });
      node.attr("cx", function(d) {
        return xScale(d.x);
      }).attr("cy", function(d) {
        return yScale(d.y);
      });
      return node.each(collide(0.5));
    };
    updateNodes = function() {
      node = nodesG.selectAll("circle.node").data(curNodesData, function(d) {
        return d.id;
      });
      node.enter().append("circle").attr("class", "node").attr("cx", function(d) {
        return xScale(d.x);
      }).attr("cy", function(d) {
        return yScale(d.y);
      }).attr("r", function(d) {
        return d.radius;
      }).style("fill", function(d) {
        return color(d.category[0]);
      }).call(drag).on('mouseover', showDetails).on('mouseout', hideDetails);
      return node.exit().remove();
    };
    updateLinks = function() {
      link = linksG.selectAll(".link").data(curLinksData, function(d) {
        return "" + d.source.id + "_" + d.target.id;
      });
      link.enter().append("path").attr("class", "link").attr("d", function(d) {
        return linkPath(d);
      });
      return link.exit().remove();
    };
    linkPath = function(d) {
      var dr, dsx, dsy, dtx, dty, dx, dy, gamma, tx, ty;
      dsx = xScale(d.source.x);
      dsy = yScale(d.source.y);
      dtx = xScale(d.target.x);
      dty = yScale(d.target.y);
      dx = dtx - dsx;
      dy = dty - dsy;
      dr = Math.sqrt(dx * dx + dy * dy);
      gamma = Math.atan2(dy, dx);
      tx = dtx - (Math.cos(gamma) * d.target.radius);
      ty = dty - (Math.sin(gamma) * d.target.radius);
      return "M" + dsx + "," + dsy + " A" + dr + "," + dr + " 0 0,0 " + tx + "," + ty;
    };
    filterNodes = function(allNodes) {
      var cutoff, filteredNodes, playcounts;
      filteredNodes = allNodes;
      if (filter === "popular" || filter === "obscure") {
        playcounts = allNodes.map(function(d) {
          return d.playcount;
        }).sort(d3.ascending);
        cutoff = d3.quantile(playcounts, 0.5);
        filteredNodes = allNodes.filter(function(n) {
          if (filter === "popular") {
            return n.playcount > cutoff;
          } else if (filter === "obscure") {
            return n.playcount <= cutoff;
          }
        });
      }
      return filteredNodes;
    };
    filterLinks = function(allLinks, curNodes) {
      curNodes = mapNodes(curNodes);
      return allLinks.filter(function(l) {
        return curNodes.get(l.source.id) && curNodes.get(l.target.id);
      });
    };
    setupData = function(data) {
      var circleRadius, degreeExtent, nodesMap;
      degreeExtent = d3.extent(data.nodes, function(d) {
        return d.degree;
      });
      circleRadius = d3.scale.sqrt().range([9, 17]).domain(degreeExtent);
      data.nodes.forEach(function(n) {
        var randomnumber;
        if (n.id === 5) {
          n.x = width / 2;
          n.y = height / 2;
          n.fixed = true;
        } else {
          n.x = randomnumber = Math.floor(Math.random() * width);
          n.y = randomnumber = Math.floor(Math.random() * height);
          n.fixed = false;
        }
        return n.radius = circleRadius(n.degree);
      });
      nodesMap = mapNodes(data.nodes);
      data.links.forEach(function(l) {
        l.source = nodesMap.get(l.source);
        l.target = nodesMap.get(l.target);
        return linkedByIndex["" + l.source.id + "," + l.target.id] = 1;
      });
      return data;
    };
    mapNodes = function(nodes) {
      var nodesMap;
      nodesMap = d3.map();
      nodes.forEach(function(n) {
        return nodesMap.set(n.id, n);
      });
      return nodesMap;
    };
    showDetails = function(d, i) {
      tip.show(d);
      if (link) {
        link.classed("highlight", function(l) {
          if (l.source === d || l.target === d) {
            return true;
          } else {
            return false;
          }
        });
        link.classed("background", function(l) {
          if (l.source === d || l.target === d) {
            return false;
          } else {
            return true;
          }
        });
      }
      node.classed("highlight", function(n) {
        if (n.searched || neighboring(d, n)) {
          return true;
        } else {
          return false;
        }
      });
      node.classed("background", function(n) {
        if (n.searched || neighboring(d, n)) {
          return false;
        } else {
          return true;
        }
      });
      return d3.select(this).classed({
        'highlight': true,
        'background': false
      });
    };
    hideDetails = function(d, i) {
      tip.hide(d);
      node.classed("highlight", function(n) {
        if (!n.searched) {
          return false;
        } else {
          return true;
        }
      });
      node.classed("background", function(n) {
        if (!n.searched) {
          return false;
        } else {
          return true;
        }
      });
      if (link) {
        return link.classed("highlight background", false);
      }
    };
    neighboring = function(a, b) {
      return linkedByIndex[a.id + "," + b.id] || linkedByIndex[b.id + "," + a.id];
    };
    setSize = function() {
      var svgH, svgStyles, svgW;
      svgStyles = window.getComputedStyle(vis.node());
      svgW = width = parseInt(svgStyles["width"]);
      svgH = height = parseInt(svgStyles["height"]);
      xScale.range([0, svgW]);
      yScale.range([0, svgH]);
      zoom.x(xScale).y(yScale);
      if (debug) {
        console.log("resize", xScale.range(), yScale.range());
      }
      return forceTick();
    };
    window.addEventListener("resize", setSize, false);
    collide = function(alpha) {
      var quadtree;
      quadtree = d3.geom.quadtree(curNodesData);
      return function(d) {
        var nx1, nx2, ny1, ny2, rb;
        rb = 2 * d.radius + 10;
        nx1 = d.x - rb;
        nx2 = d.x + rb;
        ny1 = d.y - rb;
        ny2 = d.y + rb;
        return quadtree.visit(function(quad, x1, y1, x2, y2) {
          var l, x, y;
          if (quad.point && (quad.point !== d)) {
            x = d.x - quad.point.x;
            y = d.y - quad.point.y;
            l = Math.sqrt(x * x + y * y);
            if (l < rb) {
              l = (l - rb) / l * alpha;
              d.x -= x *= l;
              d.y -= y *= l;
              quad.point.x += x;
              quad.point.y += y;
            }
          }
          return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
        });
      };
    };
    return network;
  };

  $(function() {
    var myNetwork;
    myNetwork = Network();
    return d3.json(PREFIX + "/data/graph.json", function(json) {
      return myNetwork("#bioGraph", json);
    });
  });

}).call(this);
