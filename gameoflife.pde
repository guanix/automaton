import java.util.*;
import java.util.Map.Entry;

int width = 800, height = 700;

int edgeLength = 80;
int paletteHeight = 30;

int lastUpdate = 0;

int updateInterval = 750;

int x = 1<<4;

int chosenColor = 100;

HashMap<Integer,Map<String,Float>> edges;
HashMap<Integer,Set<Integer>> neighbors;
HashMap<Integer,Integer> state, prevState;

HashMap<ArrayList<Float>,Integer> labels;

// Hexagons; list of IDs (we will hook up the connections later)
// ID of top left, coordinates of top left
// 6 indicates for whether to include the 6 edges
float[][] hexagons = {
  {1, 100, 100, 1, 1, 1, 1, 1, 1},
  {7, 100 + 2*edgeLength*cos(radians(30)), 100, 0, 1, 1, 1, 1, 1},
  {13, 100 + 4*edgeLength*cos(radians(30)), 100, 0, 1, 1, 1, 1, 1},
  {19, 100 + edgeLength*cos(radians(30)), 100 + edgeLength*(1+sin(radians(30))), 1, 1, 1, 1, 0, 0},
  {25, 100 + 3*edgeLength*cos(radians(30)), 100+edgeLength*(1+sin(radians(30))), 0, 1, 1, 1, 0, 0},
  {31, 100 + 5*edgeLength*cos(radians(30)), 100+edgeLength*(1+sin(radians(30))), 0, 1, 1, 1, 1, 0},
  {37, 100, 100+edgeLength*(2+2*sin(radians(30))), 1, 1, 1, 1, 0, 1},
  {42, 100+2*edgeLength*cos(radians(30)), 100+edgeLength*(2+2*sin(radians(30))), 0, 1, 1, 1, 0, 0},
  {49, 100+4*edgeLength*cos(radians(30)), 100+edgeLength*(2+2*sin(radians(30))), 0, 1, 1, 1, 0, 0}
};

// does not yet wrap around
float[][] neighbors_data = {
  {1, 6, 2, 0, 0},
  {2, 1, 3, 19, 0},
  {3, 2, 19, 4, 8},
  {4, 3, 8, 5, 12},
  {5, 4, 12, 6, 0},
  {6, 5, 1, 0, 0},
  {8, 3, 4, 9, 22},
  {9, 10, 14, 22, 8},
  {10, 11, 18, 9, 14},
  {11, 12, 18, 10, 0},
  {12, 5, 4, 11, 0},
  {14, 9, 10, 28, 15},
  {15, 14, 28, 16, 35},
  {16, 17, 15, 35, 0},
  {17, 18, 16, 0, 0},
  {18, 10, 11, 17, 0},
  {19, 2, 3, 20, 42},
  {20, 19, 21, 40, 42},
  {21, 22, 20, 26, 40},
  {22, 8, 9, 21, 26},
  {26, 21, 22, 27, 45},
  {27, 26, 28, 32, 45},
  {28, 27, 32, 14, 15},
  {32, 27, 28, 33, 52},
  {33, 32, 34, 0, 0},
  {34, 33, 35, 0, 0},
  {35, 15, 16, 34, 0},
  {37, 38, 42, 0, 0},
  {38, 37, 39, 0, 0},
  {39, 38, 40, 43, 0},
  {40, 20, 21, 39, 43},
  {42, 19, 20, 37, 0},
  {43, 39, 40, 44, 0},
  {44, 43, 45, 50, 0},
  {45, 26, 27, 44, 50},
  {50, 44, 45, 51, 0},
  {51, 50, 52, 0, 0},
  {52, 51, 32, 33, 0}
};

void copyPrevState() {
  for (Entry<Integer,Integer> entry : (Set<Entry<Integer,Integer>>)state.entrySet()) {
    Integer id = (Integer)entry.getKey();
    prevState.put(id, entry.getValue());
  }
}

void setup() {
  size(width, height);
  
  edges = new HashMap();
  state = new HashMap();
  prevState = new HashMap();
  labels = new HashMap();
  
  for (float[] hexagon : hexagons) {
//    println("HEXAGON starting at " + (int)hexagon[0]);
    
    // edge 1
    if (hexagon[3] == 1) {
      Integer id = new Integer((int)hexagon[0]);
      HashMap edge1 = new HashMap();
      edge1.put("x1", new Float(hexagon[1]));
      edge1.put("y1", new Float(hexagon[2]));
      edge1.put("x2", new Float(hexagon[1]));
      edge1.put("y2", new Float(hexagon[2] + edgeLength));
      edges.put(id, edge1);
//      println("generating edge " + (int)hexagon[0]);
      
      state.put(id, round(random(256)));
    }

    // edge 2
    if (hexagon[4] == 1) {
      Integer id = new Integer((int)hexagon[0]+1);
      HashMap edge2 = new HashMap();
      edge2.put("x1", new Float(hexagon[1]));
      edge2.put("y1", new Float(hexagon[2] + edgeLength));
      edge2.put("x2", new Float(hexagon[1] + edgeLength*cos(radians(30))));
      edge2.put("y2", new Float(hexagon[2] + edgeLength + edgeLength*sin(radians(30))));
      edges.put(id, edge2);
//      println("generating edge " + ((int)hexagon[0]+1));
      
      state.put(id, round(random(256)));
    }
    
    // edge 3
    if (hexagon[5] == 1) {
      Integer id = new Integer((int)hexagon[0]+2);
      HashMap edge3 = new HashMap();
      edge3.put("x1", new Float(hexagon[1] + edgeLength*cos(radians(30))));
      edge3.put("y1", new Float(hexagon[2] + edgeLength*(1+sin(radians(30)))));
      edge3.put("x2", new Float(hexagon[1] + 2*edgeLength*cos(radians(30))));
      edge3.put("y2", new Float(hexagon[2] + edgeLength));
      edges.put(id, edge3);
//      println("generating edge " + ((int)hexagon[0]+2));
      
      state.put(id, round(random(256)));
    }
    
    // edge 4
    if (hexagon[6] == 1) {
      Integer id = new Integer((int)hexagon[0]+3);
      HashMap edge4 = new HashMap();
      edge4.put("x1", new Float(hexagon[1] + 2*edgeLength*cos(radians(30))));
      edge4.put("y1", new Float(hexagon[2] + edgeLength));
      edge4.put("x2", new Float(hexagon[1] + 2*edgeLength*cos(radians(30))));
      edge4.put("y2", new Float(hexagon[2]));
      edges.put(id, edge4);
//      println("generating edge " + ((int)hexagon[0]+3));
      
      state.put(id, round(random(256)));
    }
    
    // edge 5
    if (hexagon[7] == 1) {
      Integer id = new Integer((int)hexagon[0]+4);
      HashMap edge5 = new HashMap();
      edge5.put("x1", new Float(hexagon[1] + 2*edgeLength*cos(radians(30))));
      edge5.put("y1", new Float(hexagon[2]));
      edge5.put("x2", new Float(hexagon[1] + edgeLength*cos(radians(30))));
      edge5.put("y2", new Float(hexagon[2] - edgeLength*sin(radians(30))));
      edges.put(id, edge5);
//      println("generating edge " + ((int)hexagon[0]+4));
      
      state.put(id, round(random(256)));
    }
    
    // edge 6
    if (hexagon[8] == 1) {
      Integer id = new Integer((int)hexagon[0]+5);
      HashMap edge6 = new HashMap();
      edge6.put("x1", new Float(hexagon[1] + edgeLength*cos(radians(30))));
      edge6.put("y1", new Float(hexagon[2] - edgeLength*sin(radians(30))));
      edge6.put("x2", new Float(hexagon[1]));
      edge6.put("y2", new Float(hexagon[2]));
      edges.put(id, edge6);
//      println("generating edge " + ((int)hexagon[0]+5));
      
      state.put(id, round(random(256)));
    }
  }
  
  copyPrevState();
  
  neighbors = new HashMap();
  
  // set up the neighbors hashtable
  for (float[] edge : neighbors_data) {
    Integer id = new Integer(int(edge[0]));
    HashSet n = new HashSet();
    for (int i = 1; i < 5; i++) {
      if (edge[i] != 0) {
        n.add(new Integer((int)edge[i]));
      }
    }
    neighbors.put(id, n);
  }
  
  for (Entry<Integer,Map<String,Float>> entry : (Set<Entry<Integer,Map<String,Float>>>)edges.entrySet()) {
    Integer id = (Integer)entry.getKey();
    Map edge = (Map)entry.getValue();
    Float x = ((Float)edge.get("x1") + (Float)edge.get("x2"))/2.0;
    Float y = ((Float)edge.get("y1") + (Float)edge.get("y2"))/2.0;
    //println("x=" + x + " y=" + y);
    
    ArrayList<Float> coord = new ArrayList();
    coord.add(x);
    coord.add(y);
    
    labels.put(coord, id);
  }
}

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
  
  stroke(0);
  textSize(15);
  textAlign(LEFT);
  text("Select a color from the palette, then click a number to change an edge", paletteHeight*3, height-paletteHeight-20.0);
  
  // The chosen color
  rectMode(CORNERS);
  
  float chosen[] = palette(chosenColor);
  fill(chosen[0], chosen[1], chosen[2]);
  stroke(chosen[0], chosen[1], chosen[2]);
  rect(0, height-paletteHeight*3, paletteHeight*2, height);
  
  // the color palette
  for (int i = 0; i < 256; i++) {
    float pal[] = palette(i);
    stroke(pal[0], pal[1], pal[2]);
    rect(i*boxWidth, height-paletteHeight, (i+1)*boxWidth, height);
  }

  for (Entry<Integer,Map<String,Float>> entry : (Set<Entry<Integer,Map<String,Float>>>)edges.entrySet()) {  
    Integer id = (Integer)entry.getKey();
    Map<String,Float> edge = (Map)entry.getValue();
    
    int col = (int)(Integer)state.get(id);
/*    int r = col >> 5;
    int g = (col - (r<<5))>>2;
    int b = (col - (r<<5) -(g<<2));
    stroke(round(r/8.0*255.0), round(g/8.0*255.0), round(b/4.0)*255.0);
    */
    
    float[] rgb = palette((float)col);
    stroke(rgb[0], rgb[1], rgb[2]);
    
    Float x1 = edge.get("x1");
    Float y1 = edge.get("y1");
    Float x2 = edge.get("x2");
    Float y2 = edge.get("y2");
        
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

void mousePressed() {
  if (mouseY > height-paletteHeight) {
    float boxWidth = width/256;
    int i = round(mouseX/boxWidth);
    if (i > 255) return;
    
    chosenColor = i;
    return;
  }
  
  for (Entry<ArrayList<Float>,Integer> entry : (Set<Entry<ArrayList<Float>,Integer>>)labels.entrySet()) {
    ArrayList<Float> coord = (ArrayList<Float>)entry.getKey();
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

