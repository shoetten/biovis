root = exports ? this

PREFIX = ""
# PREFIX = "/uni/bioenergie"

debug = true

Network = () ->
  # constants for the SVG
  width = 700
  height = 600

  # vis holds the root svg element
  vis = null
  # these will hold the svg groups for
  # accessing the nodes and links display
  container = null
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

  # Set up the color scale
  color = d3.scale.ordinal()
    .range(["#74c476", "#fd8d3c", "#207ec2", "#9467bd"])

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

  # set scales for zooming
  xScale = d3.scale.linear()
    .domain([0, width])
    .range([0, width])
  yScale = d3.scale.linear()
    .domain([0, height])
    .range([0, height])

  # method to handle zoom and pan
  zoomed = () ->
    # container.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")
    # if (debug) then console.log("zoom", d3.event.translate, d3.event.scale)
    # scaleFactor = d3.event.scale
    # translation = d3.event.translate
    forceTick()                                    # update positions

  # methods to handle dragging
  dragstarted = (d) ->
    d3.event.sourceEvent.stopPropagation()
    d3.select(this).classed("dragging", true)

  dragged = (d) ->
    if (debug) then console.log("DRAG")
    # if (d.fixed) then return     # root is fixed

    # get mouse coordinates relative to the visualization coordinate system
    mouse = d3.mouse(vis.node())
    d.x = xScale.invert(mouse[0])
    d.y = yScale.invert(mouse[1])
    if (debug) then console.log("drag", mouse[0], mouse[1], "scaled:", xScale.invert(mouse[0]), yScale.invert(mouse[1]))
    # d3.select(this).attr("cx", d.x = d.x).attr("cy", d.y = d.y)

  dragended = (d) ->
    d3.select(this).classed("dragging", false)

  # init the zoom behaviour
  zoom = d3.behavior.zoom()
    .x(xScale).y(yScale)
    .scaleExtent([1, 10])
    .on("zoom", zoomed)

  drag = force.drag()
    .origin((d) -> d )
    .on("dragstart", dragstarted)
    .on("drag", dragged)
    .on("dragend", dragended)

  # this method is returned at the end
  network = (selection, graph) ->
    # Append a SVG to the body of the html page. Assign this SVG as an object to svg
    vis = d3.select(selection).append("svg")
      .attr("width", width)
      .attr("height", height)
      .call(zoom)
      .on('click', hideDetails)

    # format our data
    allData = setupData(graph)

    # container to hold everything that's beeing zoomed
    container = vis.append("g")

    linksG = container.append("g").attr("id", "links")
    nodesG = container.append("g").attr("id", "nodes")

    # append section for svg defs
    defs = vis.append("defs")
    # setup svg arrowhead def
    defs.selectAll("marker")
      .data(["arrowhead", "arrowhead-background", "arrowhead-highlight"])
    .enter().append("marker")
      .attr("id", (d) -> d)
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 11)
      .attr("refY", 0)
      .attr("markerWidth", 11)
      .attr("markerHeight", 11)
      .attr("orient", "auto")
    .append("path")
      .attr("d", "M0,-5L10,0L0,5 L0,-5")
      .attr("class", (d) -> d)

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

    # set height & width based on calculated svg element size
    setSize()

  forceTick = () ->
    link
      .attr("d", (d) -> linkPath(d))

    node
      .attr("cx", (d) -> xScale(d.x))
      .attr("cy", (d) -> yScale(d.y))

    node.each(collide(0.5))     # collision detection

  # enter/exit display for nodes
  updateNodes = () ->
    node = nodesG.selectAll("circle.node")
      .data(curNodesData, (d) -> d.id)

    node.enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> xScale(d.x))
      .attr("cy", (d) -> yScale(d.y))
      .attr("r", (d) -> d.radius)
      .style("fill", (d) -> color(d.category[0]))
      .call(drag)
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)
      .on('click', showDetails)

    node.exit().remove()

  # enter/exit display for links
  updateLinks = () ->
    link = linksG.selectAll(".link")
      .data(curLinksData, (d) -> "#{d.source.id}_#{d.target.id}")
    link.enter().append("path")
      .attr("class", "link")
      .attr("d", (d) -> linkPath(d))

    link.exit().remove()

  # Calculate line offset, subtracting radius from length, to let the line end at the edge of node, not in the center
  linkPath = (d) ->
    dsx = xScale(d.source.x)    # scaled source x attribute
    dsy = yScale(d.source.y)    # scaled source y attribute
    dtx = xScale(d.target.x)    # scaled target x attribute
    dty = yScale(d.target.y)    # scaled target y attribute
    dx = dtx - dsx
    dy = dty - dsy
    dr = Math.sqrt(dx * dx + dy * dy)     # calculate arc radius without taking zoom scale into account

    # now calculate angle with zoom scales
    # dx = xScale(dx)                        
    # dy = yScale(dy)
    # Math.atan2 returns the angle in the correct quadrant as opposed to Math.atan
    gamma = Math.atan2(dy,dx)
    tx = dtx - (Math.cos(gamma) * d.target.radius)
    ty = dty - (Math.sin(gamma) * d.target.radius)

    "M" + dsx + "," + dsy + " A" + dr + "," + dr + " 0 0,0 " + tx + "," + ty


  # Public function to update highlighted nodes from search
  network.updateSearch = (searchTerm) ->
    if searchTerm
      searchRegEx = new RegExp(searchTerm.toLowerCase())
      meta = "<h2>Suchergebnisse</h2><div class=\"flex\">"
      node.each (d) ->
        element = d3.select(this)
        match = d.name.toLowerCase().search(searchRegEx)
        if searchTerm.length > 0 and match >= 0
          d.searched = true
          element.classed("background", false)
          meta += "<a href=\"#\">#{d.name}</a> "
        else
          d.searched = false
          element.classed("background", true)

        element.classed('searched', d.searched)
        link.classed("background", true)
      meta += "</div>"
      $('#meta .searchResults').html(meta)
    else
      $('#meta .searchResults').html("")
      node.classed('searched background', false)
      node.attr('searched', false)
      # node.classed('selected highlight background', false)
      link.classed('highlight background', false)

 
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
    circleRadius = d3.scale.sqrt().range([9, 17]).domain(degreeExtent)

    data.nodes.forEach (n) ->
      # set initial x/y to values within the width/height
      # of the visualization
      if n.id == 5                    # planzenanbau zur energieerzeugung
        n.x = width / 2
        n.y = height / 2
        n.fixed = true
      else
        n.x = randomnumber=Math.floor(Math.random()*width)
        n.y = randomnumber=Math.floor(Math.random()*height)
        n.fixed = false

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

  # Show details on node click
  showDetails = (d,i) ->
    if (d3.event.defaultPrevented) then return      # click suppressed

    d3.event.stopPropagation()                      # prevent other click events beeing executed
    # tip.show(d)

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
      if (!n.searched)
        if (neighboring(d, n)[0] or neighboring(d, n)[1]) then true else false)
    node.classed("background", (n) ->
      if (!n.searched)
        if (neighboring(d, n)[0] or neighboring(d, n)[1]) then false else true)

    node.classed("selected", false)         # set all nodes to not selected
  
    # highlight the node being moused over
    d3.select(this).classed({'highlight selected': true, 'background': false})


    #################### add meta info to sidebar
    #############################################
    nodeMeta = d3.select("#meta .nodes")
    # remove old stuff
    nodeMeta.text(null)

    # add heading
    nodeMeta.append("h2")
      .text(d.name)

    # add categories
    categories = nodeMeta.append("div").attr("class", "categories")
    
    categories.selectAll("a").data(d.category)
      .enter().append("a")
        .attr("href", '#')
        .attr("class", (n) -> "category #{n.toLowerCase()}")
        .text((n) -> n)

    # add connected nodes
    connected = nodeMeta.append("div").attr("class", "connected")
    connectedData = curNodesData.filter((n) -> (neighboring(d, n)[0] or neighboring(d, n)[1]))

    connected.append("h3").text("Beeinflusst..")
    outgoing = connected.append("div").attr("class", "outgoing")
      .selectAll(".node")
      .data(connectedData.filter((n) -> neighboring(d, n)[0]), (n) -> n.id)

    outgoing.enter().append("a")
      .attr('href', '#')
      .text((n) -> n.name)
      .on('click', (n) -> zoomToNode(n))
    
    connected.append("h3").text("Wird beeinflusst von..")
    incoming = connected.append("div").attr("class", "incoming")
      .selectAll(".node")
      .data(connectedData.filter((n) -> neighboring(d, n)[1]), (n) -> n.id)

    incoming.enter().append("a")
      .attr('href', '#')
      .text((n) -> n.name)
      .on('click', (n) -> zoomToNode(n))


  # click on background function
  hideDetails = (d,i) ->
    if (d3.event.defaultPrevented) then return      # click suppressed

    node.classed("highlight background selected searched", false)
    # node.classed("background", (n) -> if !n.searched then false else true)
    if link
      link.classed("highlight background", false)

    # remove meta info from sidebar
    d3.select("#meta .nodes").text(null)
    # clear search
    $("#search").val("")
    d3.select('#meta .searchResults').text(null)
    node.attr('searched', false)

  # Given two nodes a and b, returns true if
  # there is a link between them.
  # Uses linkedByIndex initialized in setupData
  neighboring = (a, b) ->
    # first element of array for outgoing link, second for incoming link
    [linkedByIndex[a.id + "," + b.id], linkedByIndex[b.id + "," + a.id]]


  # Set the display size based on the SVG size and re-draw
  setSize = () ->
    svgStyles = window.getComputedStyle(vis.node())
    svgW = parseInt(svgStyles["width"])
    svgH = parseInt(svgStyles["height"])
    
    vis.attr("width", svgW)
      .attr("height", svgH)

    # Set the output range of the scales
    xScale.range([0, svgW])
    yScale.range([0, svgH])
    
    # re-attach the scales to the zoom behaviour
    zoom.x(xScale)
        .y(yScale)

    if (debug)
      console.log("resize", xScale.range(), yScale.range())
      console.log("x domain",xScale.domain(),"x range", xScale.range())

    forceTick()              # re-draw

  # make responsive by adapting size to window changes
  window.addEventListener("resize", setSize, false)


  # avoid overlapping nodes
  collide = (alpha) ->
    quadtree = d3.geom.quadtree(curNodesData)
    return (d) ->
      rb = 2* d.radius + 10      # min of 3px padding between nodes
      nx1 = d.x - rb
      nx2 = d.x + rb
      ny1 = d.y - rb
      ny2 = d.y + rb
      quadtree.visit( (quad, x1, y1, x2, y2) ->
        if (quad.point && (quad.point != d))
          x = d.x - quad.point.x
          y = d.y - quad.point.y
          l = Math.sqrt(x * x + y * y)
          if (l < rb)
            l = (l - rb) / l * alpha
            d.x -= x *= l
            d.y -= y *= l
            quad.point.x += x
            quad.point.y += y
        return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1
      )


  # zoom to specified domain
  zoomTo = (xDomain, yDomain) ->
    d3.transition().duration(750).tween("zoom", ->
      ix = d3.interpolate(xScale.domain(), xDomain)
      iy = d3.interpolate(yScale.domain(), yDomain)
      return (t) ->
        zoom.x(xScale.domain(ix(t)))
            .y(yScale.domain(iy(t)))

        zoomed()
    )

  zoomToNode = (n) ->
    zoomTo([n.x-100, n.x+100], [n.y-100, n.y+100])

  # reset zoom and pan
  network.reset = () ->
    zoomTo([0, width], [0, height])

  # Final act of Network() function is to return the inner 'network()' function.
  return network


$  ->
  myNetwork = Network()

  $("#search").keyup () ->
    searchTerm = $(this).val()
    myNetwork.updateSearch(searchTerm)

  $("#reset").click () ->
    myNetwork.reset()

  d3.json(PREFIX + "/data/graph.json", (json) ->
    myNetwork("#bioGraph", json))

