import java.util.*;
import java.util.Map.Entry;

int width = 800, height = 700;

int originX = 40, originY = 70;

int edgeLength = 80;
int paletteHeight = 30;

int lastUpdate = 0;

int updateInterval = 750;

int rows = 4;
int cols = 4;

int x = 1<<4;

int chosenColor = 100;

HashMap<Integer,Map<String,List<Float>>> edges;
HashMap<Integer,Set<Integer>> neighbors;
HashMap<Integer,Integer> state, prevState;

HashMap<List<Float>,Integer> labels;
HashMap<List<Float>,ArrayList<Integer>> vertices;
HashSet<List<Float>> edgeVertices;

// The state hashtable is double buffered so we don't step on ourselves
// Copy state to its prevState buffer
void copyPrevState() {
  prevState = new HashMap(state);
}

void addEdgeVertices(List<Float> p1, List<Float> p2) {
  ArrayList<Float> a = new ArrayList(4);
  a.add(p1.get(0));
  a.add(p1.get(1));
  a.add(p2.get(0));
  a.add(p2.get(1));
  edgeVertices.add(a);
  
  ArrayList<Float> b = new ArrayList(4);
  b.add(p2.get(0));
  b.add(p2.get(1));
  b.add(p1.get(0));
  b.add(p1.get(1));
  edgeVertices.add(b);
}

boolean edgeExists(List<Float> p1, List<Float> p2) {
  for (List<Float> e : edgeVertices) {
    // they're the same if within 1 unit of each other
    // TODO: Figure out how to put edgeVertices in a TreeSet and use the tree to avoid iterating
    // over all the edges to find overlaps
    float dist1 = (float)Math.sqrt(Math.pow(e.get(0) - p1.get(0), 2) + Math.pow(e.get(1) - p1.get(1), 2));
    float dist2 = (float)Math.sqrt(Math.pow(e.get(2) - p2.get(0), 2) + Math.pow(e.get(3) - p2.get(1), 2));
    
    if (dist1 < 1.0 && dist2 < 1.0) {
      return true;
    }
  }
  
  return false;
}

Integer edgeNo = 0;

List<Float> e8a, e8b;

void addEdgeIfNotExists(float x1, float y1, float x2, float y2) {
  ArrayList<Float> p1 = new ArrayList(2);
  p1.add(x1);
  p1.add(y1);
    
  ArrayList<Float> p2 = new ArrayList(2);
  p2.add(x2);
  p2.add(y2);
    
  if (!edgeExists(p1, p2)) {
    Integer id = ++edgeNo;
    HashMap edge = new HashMap();
    edge.put("p1", p1);
    edge.put("p2", p2);
    edges.put(id, edge);
    
    addEdgeVertices(p1, p2);

    state.put(id, round(random(256)));
  }
}

void setup() {
  size(width, height);
  
  edges = new HashMap();
  state = new HashMap();
  prevState = new HashMap();
  labels = new HashMap();
  vertices = new HashMap();
  edgeVertices = new HashSet();
  
  int edgeNo = 0;
  
  // Go through hardcoded list of hexagons and create the edges. Edge 1 is the vertical
  // edge on the left of the hexagon.
  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      float x = originX + col*2*edgeLength*cos(radians(30));
      float y = originY + edgeLength*(row+row*sin(radians(30)));

      if ((row % 2) == 1) {
        println("HELLO");
        x += edgeLength*cos(radians(30));
      }
      
      // edge 1
      addEdgeIfNotExists(x, y,
        x, y + edgeLength);
  
      // edge 2
      addEdgeIfNotExists(x, y + edgeLength,
        x + edgeLength*cos(radians(30)), y + edgeLength + edgeLength*sin(radians(30)));
  
      // edge 3
      addEdgeIfNotExists(x + edgeLength*cos(radians(30)), y + edgeLength*(1+sin(radians(30))),
         x + 2*edgeLength*cos(radians(30)), y + edgeLength);
      
      // edge 4
      addEdgeIfNotExists(x + 2*edgeLength*cos(radians(30)), y + edgeLength,
        x + 2*edgeLength*cos(radians(30)), y);
      
      // edge 5
      addEdgeIfNotExists(x + 2*edgeLength*cos(radians(30)), y,
        x + edgeLength*cos(radians(30)), y - edgeLength*sin(radians(30)));
      
      // edge 6
      addEdgeIfNotExists(x + edgeLength*cos(radians(30)), y - edgeLength*sin(radians(30)),
        x, y);
    }
  }
  
  copyPrevState();
  
  neighbors = new HashMap();
  
  // automatically set up neighbors hashtable using a hashmap of vertices
  for (Entry<Integer,Map<String,List<Float>>> e : (Set<Entry<Integer,Map<String,List<Float>>>>)edges.entrySet()) {
    Integer id = e.getKey();
    Map<String,List<Float>> edge = e.getValue();
    List<Float> p1 = edge.get("p1");
    List<Float> p2 = edge.get("p2");
    
    if (vertices.containsKey(p1)) {
      vertices.get(p1).add(id);
    } else {
      ArrayList<Integer> list = new ArrayList();
      list.add(id);
      vertices.put(p1, list);
    }
    
    if (vertices.containsKey(p2)) {
      vertices.get(p2).add(id);
    } else {
      ArrayList<Integer> list = new ArrayList();
      list.add(id);
      vertices.put(p2, list);
    }
    
    // update the labels  
    // labels are used for detecting mouse clicks for manual interaction
    Float x = (edge.get("p1").get(0) + edge.get("p2").get(0))/2.0;
    Float y = (edge.get("p1").get(1) + edge.get("p2").get(1))/2.0;
    //println("x=" + x + " y=" + y);
    
    ArrayList<Float> coord = new ArrayList();
    coord.add(x);
    coord.add(y);
    
    labels.put(coord, id);
  }

  for (Entry<Integer,Map<String,List<Float>>> e : (Set<Entry<Integer,Map<String,List<Float>>>>)edges.entrySet()) {
    Integer id = e.getKey();
    Map<String,List<Float>> edge = e.getValue();
    List<Float> p1 = edge.get("p1");
    List<Float> p2 = edge.get("p2");
    
    print("neighbors for edge " + id + ": ");
    
    for (Entry<List<Float>,ArrayList<Integer>> ve : (Set<Entry<List<Float>,ArrayList<Integer>>>)vertices.entrySet()) {
      List<Float> vertex = ve.getKey();
      List<Integer> vertexEdges = ve.getValue();
      
      float dist1 = (float)Math.sqrt(Math.pow(p1.get(0) - vertex.get(0), 2) + Math.pow(p1.get(1) - vertex.get(1), 2));
      float dist2 = (float)Math.sqrt(Math.pow(p2.get(0) - vertex.get(0), 2) + Math.pow(p2.get(1) - vertex.get(1), 2));
      
      if (dist1 > 1.0 && dist2 > 1.0) continue;
      
      for (Integer n : vertexEdges) {
        if (!n.equals(id)) {
          print(n + " ");
          // add neighbors data
          if (neighbors.containsKey(id)) {
            neighbors.get(id).add(n);
          } else {
            HashSet ns = new HashSet();
            ns.add(n);
            neighbors.put(id, ns);
          }
        }
      }
    }

    
    println("");
  }
  
  frameRate(10);
}

// map unsigned 8-bit value to a color 
float[] palette(float col) {
  float[] rgb = {0,0,0};
  float red, green, blue;
    
  // red to green
  if (col <= 85) {
    green = map(col, 0, 85, 0, 255);
    red = map(col, 0, 85, 255, 0);
    blue = 0;
  // green to blue
  } else if (col <= 170) {
    green = map(col, 85, 170, 255, 0);
    blue = map(col, 85, 170, 0, 255);
    red = 0;
  // blue to red
  } else {
    green = 0;
    blue = map(col, 170, 255, 255, 0);
    red = map(col, 170, 255, 0, 255);
  }
    
  rgb[0] = red;
  rgb[1] = green;
  rgb[2] = blue;
    
  return rgb;
}

void draw() {
//  background(255, 204, 0);
  background(255);
  strokeWeight(20);
  
  float boxWidth = width/256;

  // Draw color palette at the bottom
  
  stroke(0);
  textSize(15);
  textAlign(LEFT);
  text("Select a color from the palette, then click a number to change an edge", paletteHeight*3, height-paletteHeight-20.0);
  
  rectMode(CORNERS);
  
  float chosen[] = palette(chosenColor);
  fill(chosen[0], chosen[1], chosen[2]);
  stroke(chosen[0], chosen[1], chosen[2]);
  rect(0, height-paletteHeight*3, paletteHeight*2, height);
  
  for (int i = 0; i < 256; i++) {
    float pal[] = palette(i);
    stroke(pal[0], pal[1], pal[2]);
    rect(i*boxWidth, height-paletteHeight, (i+1)*boxWidth, height);
  }

  for (Entry<Integer,Map<String,List<Float>>> entry : (Set<Entry<Integer,Map<String,List<Float>>>>)edges.entrySet()) {  
    Integer id = entry.getKey();
    Map<String,List<Float>> edge = entry.getValue();
    
    int col = (int)(Integer)state.get(id);
    
    float[] rgb = palette((float)col);
    stroke(rgb[0], rgb[1], rgb[2]);
    
    List<Float> p1 = edge.get("p1");
    List<Float> p2 = edge.get("p2");
    
    Float x1 = p1.get(0);
    Float y1 = p1.get(1);
    Float x2 = p2.get(0);
    Float y2 = p2.get(1);
        
    line(x1, y1, x2, y2);
    
    textAlign(CENTER, CENTER);
    textSize(12);
    fill(0);
    text(id.toString(), (x1 + x2)/2.0, (y1 + y2)/2.0);
  }
  
  // Update state once every 500 ms
  if (millis() - lastUpdate < updateInterval) {
    return;
  }
  
  lastUpdate = millis();
  
  advanceState();
}

// State transition function
void advanceState() { 
  for (Entry<Integer,Integer> entry : (Set<Entry<Integer,Integer>>)state.entrySet()) {
    Integer id = (Integer)entry.getKey();
    Set<Integer> n = neighbors.get(id);
    
    float ownState = (float)(int)(Integer)prevState.get(id);
    //println(ownState);
    
    float high = 127;
    float low = 127;
    
    int count = 0;
    float sum = 0;
    
    if (n == null) {
      println("missing neighbors data for " + id);
      continue;
    }
    
    for (Integer neighborId : n) {
      if (!prevState.containsKey(neighborId)) {
        println("for " + id + " neighbor " + neighborId + " is not in prevState");
        continue;
      }
      Float neighborState = prevState.get(neighborId).floatValue();
      if (neighborState > high) high = neighborState;
      if (neighborState < low) low = neighborState;
      
      count++;
      sum += neighborState;
    }
    
    float avg = sum/count;
    float nextState = ownState;
    
    nextState = 0.6*ownState + 0.4*avg;
    
    if (avg >= 145 && avg <= 195) {
      nextState = 0.25*ownState + 0.75*avg;
    } else if (high > 230 || low < 25) {
      if (abs(high - ownState) > abs(low - ownState)) {
        // closer to low
        nextState = 0.25*ownState + 0.75*low;
      } else {
        // closer to high
        nextState = 0.25*ownState + 0.75*high;
      }
    }
    
    nextState = nextState + random(10);
    if (random(1) <= 0.0001 && false) nextState += random(80);
    if (nextState < 0) nextState = 255 - nextState;
    if (nextState > 255) nextState = nextState - 255;
    //    int avg = round(sum/weight);
    
    state.put(id, new Integer(round(nextState)));
  }
  
  copyPrevState();
}

// Mouse click handler for color selection
void mousePressed() {
  if (mouseY > height-paletteHeight) {
    float boxWidth = width/256;
    int i = round(mouseX/boxWidth);
    if (i > 255) return;
    
    chosenColor = i;
    return;
  }
  
  for (Entry<List<Float>,Integer> entry : (Set<Entry<List<Float>,Integer>>)labels.entrySet()) {
    List<Float> coord = (List<Float>)entry.getKey();
    float dist = (float)Math.sqrt(Math.pow(coord.get(0) - mouseX, 2) + Math.pow(coord.get(1) - mouseY, 2));
    if (dist < 40) {
      Integer id = (Integer)entry.getValue();
//      println("pressed " + id);
      state.put(id, chosenColor);
      prevState.put(id, chosenColor);
      break;  
    }
  }
}

