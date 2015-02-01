root = exports ? this

PREFIX = ""

Network = () ->
  # Constants for the SVG
  width = 700
  height = 600

  # these will hold the svg groups for
  # accessing the nodes and links display
  nodesG = null
  linksG = null
  # these will point to the circles and lines
  # of the nodes and links
  node = null
  link = null

  allData = []                      # allData will store the unfiltered data
  curLinksData = []                 # filtered links data
  curNodesData = []                 # filtered nodes data
  linkedByIndex = {}                # links between nodes, used for highlighting

  # Set up the colour scale
  color = d3.scale.category20()

  # setup tooltips
  tip = d3.tip()
    .attr('class', 'd3-tip')
    .html((d) -> d.name)
    .direction('n')
    .offset((d) -> [-(d.radius / 2 + 3), 0])

  # Set up the force layout
  force = d3.layout.force()
    .charge(-250)
    .linkDistance(120)
    .size([width, height])

  # this method is returned at the end
  network = (selection, graph) ->
    # format our data
    allData = setupData(graph)

    # Append a SVG to the body of the html page. Assign this SVG as an object to svg
    vis = d3.select(selection).append("svg")
      .attr("width", width)
      .attr("height", height)
    linksG = vis.append("g").attr("id", "links")
    nodesG = vis.append("g").attr("id", "nodes")

    # setup svg arrow def
    vis.append("defs").selectAll("marker")
      .data(["arrow"])
    .enter().append("marker")
      .attr("id", (d) -> d)
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 25)
      .attr("refY", 0)
      .attr("markerWidth", 6)
      .attr("markerHeight", 6)
      .attr("orient", "auto")
    .append("path")
      .attr("d", "M0,-5L10,0L0,5 L10,0 L0, -5")
      .attr("class", "link")

    # Invoke the tip in the context of your visualization
    vis.call(tip)

    # Now we are giving the SVGs co-ordinates - the force layout is generating the co-ordinates which this code is using to update the attributes of the SVG elements
    force.on("tick", forceTick)

    # perform rendering and start force layout
    update()


  # The update() function performs the bulk of the
  # work to setup our visualization based on the
  # current layout/sort/filter.
  #
  # update() is called everytime a parameter changes
  # and the network needs to be reset.
  update = () ->
    # filter data to show based on current filter settings.
    # curNodesData = filterNodes(allData.nodes)
    # curLinksData = filterLinks(allData.links, curNodesData)
    curNodesData = allData.nodes
    curLinksData = allData.links

    # reset nodes in force layout
    force.nodes(curNodesData)
    force.links(curLinksData)

    # enter / exit for nodes & links
    updateNodes()
    updateLinks()

    # start me up!
    force.start()

  forceTick = () ->
    link
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

      node
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)

  # enter/exit display for nodes
  updateNodes = () ->
    node = nodesG.selectAll("circle.node")
      .data(curNodesData, (d) -> d.id)

    node.enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", (d) -> d.radius)
      .style("fill", (d) -> color(4))
      .call(force.drag)
      .on('mouseover', showDetails)
      .on('mouseout', hideDetails)

    node.exit().remove()

  # enter/exit display for links
  updateLinks = () ->
    link = linksG.selectAll("line.link")
      .data(curLinksData, (d) -> "#{d.source.id}_#{d.target.id}")
    link.enter().append("line")
      .attr("class", "link")
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
      .style("marker-end",  "url(#arrow)")

    link.exit().remove()

  # Removes nodes from input array
  # based on current filter setting.
  # Returns array of nodes
  filterNodes = (allNodes) ->
    filteredNodes = allNodes
    if filter == "popular" or filter == "obscure"
      playcounts = allNodes.map((d) -> d.playcount).sort(d3.ascending)
      cutoff = d3.quantile(playcounts, 0.5)
      filteredNodes = allNodes.filter (n) ->
        if filter == "popular"
          n.playcount > cutoff
        else if filter == "obscure"
          n.playcount <= cutoff

    filteredNodes

  # Removes links from allLinks whose
  # source or target is not present in curNodes
  # Returns array of links
  filterLinks = (allLinks, curNodes) ->
    curNodes = mapNodes(curNodes)
    allLinks.filter (l) ->
      curNodes.get(l.source.id) and curNodes.get(l.target.id)


  # called once to clean up raw data and switch links to
  # point to node instances
  # Returns modified data
  setupData = (data) ->
    # initialize circle radius scale
    degreeExtent = d3.extent(data.nodes, (d) -> d.degree)
    circleRadius = d3.scale.sqrt().range([5, 14]).domain(degreeExtent)

    data.nodes.forEach (n) ->
      # set initial x/y to values within the width/height
      # of the visualization
      n.x = randomnumber=Math.floor(Math.random()*width)
      n.y = randomnumber=Math.floor(Math.random()*height)
      # add radius to the node so we can use it later
      n.radius = circleRadius(n.degree)

    # id's -> node objects
    nodesMap = mapNodes(data.nodes)

    # switch links to point to node objects instead of id's
    data.links.forEach (l) ->
      l.source = nodesMap.get(l.source)
      l.target = nodesMap.get(l.target)

      # linkedByIndex is used for link sorting
      linkedByIndex["#{l.source.id},#{l.target.id}"] = 1

    data

  # Helper function to map node id's to node objects.
  # Returns d3.map of ids -> nodes
  mapNodes = (nodes) ->
    nodesMap = d3.map()
    nodes.forEach (n) ->
      nodesMap.set(n.id, n)
    nodesMap

  # Mouseover function to show tooltop and highlight
  showDetails = (d,i) ->
    tip.show(d)

    # higlight connected links
    if link
      link.classed("highlight", (l) ->
        if l.source == d or l.target == d then true else false)
      link.classed("background", (l) ->
        if l.source == d or l.target == d then false else true)

      # link.each (l) ->
      #   if l.source == d or l.target == d
      #     d3.select(this).attr("stroke", "#555")

    # highlight neighboring nodes
    # watch out - don't mess with node if search is currently matching
    node.classed("highlight", (n) ->
      if (n.searched or neighboring(d, n)) then true else false)
    node.classed("background", (n) ->
      if (n.searched or neighboring(d, n)) then false else true)
  
    # highlight the node being moused over
    d3.select(this).classed({'highlight': true, 'background': false})

  # Mouseout function
  hideDetails = (d,i) ->
    tip.hide(d)

    # watch out - don't mess with node if search is currently matching
    node.classed("highlight", (n) -> if !n.searched then false else true)
    node.classed("background", (n) -> if !n.searched then false else true)
    if link
      link.classed("highlight background", false)

  # Given two nodes a and b, returns true if
  # there is a link between them.
  # Uses linkedByIndex initialized in setupData
  neighboring = (a, b) ->
    linkedByIndex[a.id + "," + b.id] or
      linkedByIndex[b.id + "," + a.id]

  # Final act of Network() function is to return the inner 'network()' function.
  return network


$  ->
  myNetwork = Network()

  d3.json(PREFIX + "/data/graph.json", (json) ->
    myNetwork("#bioGraph", json))

