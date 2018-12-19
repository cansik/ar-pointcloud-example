import java.nio.file.Path;
import java.nio.file.Paths;

import org.jengineering.sjmply.PLY;
import static org.jengineering.sjmply.PLYType.*;
import static org.jengineering.sjmply.PLYFormat.*;

import peasy.PeasyCam;

import nervoussystem.obj.*;

boolean cloudLoaded = false;
boolean meshCloudConverted = false;

boolean showMeshCloud = false;

String exportPath = "";
boolean exportPathSet = false;

PShape cloud;
PShape meshCloud;

PeasyCam cam;

void setup()
{
  size(1280, 720, P3D);
  pixelDensity = 2;

  // clipping
  perspective(PI/3.0, (float)width/height, 1, 100000);

  cam = new PeasyCam(this, 400);
  cam.setSuppressRollRotationMode();

  cloud = createShape();
  meshCloud = createShape();
  selectInput("PLY file to load cloud:", "openFileSelected");
}

void draw()
{
  background(0);

  if (cloudLoaded)
  {
    if (showMeshCloud)
    {
      shape(meshCloud);
    } else
    {
      shape(cloud);
    }
  }

  if (exportPathSet)
  {
    // export object
    OBJExport obj = (OBJExport) createGraphics(10, 10, "nervoussystem.obj.OBJExport", exportPath);
    obj.setColor(false);
    obj.beginDraw();
    obj.noFill();
    obj.shape(meshCloud);
    obj.endDraw();
    obj.dispose();

    println("exported obj of meshcloud");
    exportPathSet = false;
  }

  cam.beginHUD();
  fill(255);
  text("PointCloud: " + cloud.getVertexCount()  + " MeshCloud: " + meshCloud.getVertexCount() +  " FPS: " + frameRate, 10, 10);
  cam.endHUD();
}

void keyPressed()
{
  if (key == 'C' || key == 'c')
  {
    convertToMeshCloud();
  }

  if (key == 'E' || key == 'e')
  {
    selectOutput("PLY file to store cloud:", "saveFileSelected");
  }

  if (key == 'S' || key == 's')
  {
    convertToSubLineMeshCloud();
  }

  if (key == 'M' || key == 'm')
  {
    convertToCenterLineMeshCloud();
  }

  if (key == 'V' || key == 'v')
  {
    convertToLineMeshCloud();
  }

  if (key == ' ')
  {
    showMeshCloud = !showMeshCloud;

    if (showMeshCloud)
      println("show mesh cloud!");
    else
      println("show point cloud!");
  }
}

void saveFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    exportPath = selection.getAbsolutePath();
    exportPathSet = true;
  }
}

void openFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String path = selection.getAbsolutePath();
    loadPointCloud(path);
    cloudLoaded = true;
  }
}

void convertToMeshCloud()
{
  meshCloud = createShape(GROUP);

  int size = 5;

  for (int i = 0; i < cloud.getVertexCount(); i++)
  {
    PVector v = cloud.getVertex(i);
    color c = cloud.getFill(i);

    PShape shape = createShape();
    shape.fill(255);
    shape.setStroke(false);

    shape.beginShape();
    shape.vertex(v.x - size, v.y - size, v.z);
    shape.vertex(v.x + size, v.y - size, v.z);
    shape.vertex(v.x + size, v.y + size, v.z);
    shape.vertex(v.x - size, v.y + size, v.z);
    shape.endShape(CLOSE);

    meshCloud.addChild(shape);
  }

  meshCloudConverted = true;
  println("mesh cloud created!");
}

void convertToLineMeshCloud()
{
  // sort vertices
  List<PVector> vecs = new ArrayList<PVector>(cloud.getVertexCount());
  for (int i = 0; i < cloud.getVertexCount(); i++)
    vecs.add(cloud.getVertex(i));
  Collections.sort(vecs, VectorComperator);

  // create shape
  meshCloud = createShape();
  meshCloud.beginShape(LINES);

  meshCloud.noFill();
  meshCloud.setStroke(true);
  meshCloud.stroke(255);
  meshCloud.strokeWeight(0.1);

  for (int i = 0; i < vecs.size(); i++) {
    PVector v = vecs.get(i);
    meshCloud.vertex(v.x, v.y, v.z);
  }

  meshCloud.endShape();

  meshCloudConverted = true;
  println("line mesh cloud created!");
}

void convertToCenterLineMeshCloud()
{
  // sort vertices
  List<PVector> vecs = new ArrayList<PVector>(cloud.getVertexCount());
  for (int i = 0; i < cloud.getVertexCount(); i++)
    vecs.add(cloud.getVertex(i));
  Collections.sort(vecs, VectorComperator);

  PVector zero = new PVector(0, 0, 0);
  float startColorFade = 0.9;

  // create shape
  meshCloud = createShape(GROUP);

  for (int i = 0; i < vecs.size(); i++) {
    PVector v = vecs.get(i);

    PVector startColor = PVector.lerp(zero, v, startColorFade);

    PShape shape = createShape();
    shape.beginShape(LINES);
    shape.noFill();
    shape.setStroke(true);
    shape.stroke(0);
    shape.strokeWeight(0.2);
    shape.vertex(startColor.x, startColor.y, startColor.z);
    shape.stroke(255);
    //shape.vertex(zero.x, zero.y, zero.z);
    shape.vertex(v.x * 10, v.y * 10, v.z * 10);
    shape.endShape();
    meshCloud.addChild(shape);
  }

  meshCloudConverted = true;
  println("center line mesh cloud created!");
}


void convertToSubLineMeshCloud()
{
  // sort vertices
  List<PVector> vecs = new ArrayList<PVector>(cloud.getVertexCount());
  for (int i = 0; i < cloud.getVertexCount(); i++)
    vecs.add(cloud.getVertex(i));
  Collections.sort(vecs, VectorComperator);

  // create shape
  meshCloud = createShape(GROUP);
  float maxDistance = 1000.0;

  PShape shape = createShape();
  shape.beginShape(TRIANGLES);
  shape.noFill();
  shape.setStroke(true);
  shape.stroke(255);
  shape.strokeWeight(0.1);

  for (int i = 0; i < vecs.size(); i++) {
    PVector v = vecs.get(i);
    float d = abs(PVector.dist(v, vecs.get((i + 1) % vecs.size())));

    if (d < maxDistance)
      shape.vertex(v.x, v.y, v.z);
    else
    {
      shape.endShape();
      meshCloud.addChild(shape);

      // create new
      shape = createShape();
      shape.beginShape(TRIANGLES);
      shape.fill(0, 100, 0);
      shape.setStroke(true);
      shape.stroke(255);
      shape.strokeWeight(0.1);
    }
  }

  shape.endShape();
  meshCloud.addChild(shape);

  meshCloudConverted = true;
  println("sub line mesh cloud created!");
}

public void loadPointCloud(String fileName)
{
  Path path = Paths.get(fileName);
  PLY ply = new PLY();

  try
  {
    ply = PLY.load(path);
  } 
  catch (Exception ex) {
    ex.printStackTrace();
  }

  PLYElementList vertex = ply.elements("vertex");

  // coordinates
  float[] x = vertex.property(FLOAT32, "x");
  float[] y = vertex.property(FLOAT32, "y");
  float[] z = vertex.property(FLOAT32, "z");

  // colors
  byte[] r = vertex.property(UINT8, "red");
  byte[] g = vertex.property(UINT8, "green");
  byte[] b = vertex.property(UINT8, "blue");

  cloud = createShape();
  cloud.beginShape(POINTS);

  for (int i = 0; i < x.length; i++)
  {
    int rv = r[i] & 0xFF;
    int gv = g[i] & 0xFF;
    int bv = b[i] & 0xFF;

    cloud.strokeWeight(5);
    cloud.stroke(rv, gv, bv);
    cloud.vertex(x[i], -y[i], z[i]);
  }

  cloud.endShape();
}
