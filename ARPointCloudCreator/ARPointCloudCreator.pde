import java.nio.file.Path;
import java.nio.file.Paths;

import org.jengineering.sjmply.PLY;
import static org.jengineering.sjmply.PLYType.*;
import static org.jengineering.sjmply.PLYFormat.*;

import peasy.PeasyCam;

boolean cloudLoaded = false;
boolean meshCloudConverted = false;

boolean showMeshCloud = false;

String exportPath = "";
boolean exportPathSet = false;

PShape cloud;
PShape convertedCloud;

PeasyCam cam;

void setup()
{
  size(512, 512, P3D);
  pixelDensity = 2;

  cloud = createShape();
  selectInput("PLY file to load cloud:", "openFileSelected");
}

void draw()
{
  background(0);

  if (cloudLoaded && !meshCloudConverted)
  {
    println("converting pointcloud...");
    convertCloud();
    println("converted!");
    //selectOutput("PLY file to store cloud:", "saveFileSelected");
  }

  if (exportPathSet)
  {
    savePointCloud(exportPath, convertedCloud);
    exit();
  }
}

void convertCloud()
{
  // create shape
  convertedCloud = createShape();
  convertedCloud.beginShape(POINTS);

  PVector max = new PVector(0, 0, 0);

  // calc for normalisation
  for (int i = 0; i < cloud.getVertexCount(); i++) {
    PVector v = cloud.getVertex(i);

    // update max
    max.x = max(max.x, abs(v.x));
    max.y = max(max.y, abs(v.y));
    max.z = max(max.z, abs(v.z));
  }

  for (int i = 0; i < cloud.getVertexCount(); i++) {
    PVector v = cloud.getVertex(i);
    color c = cloud.getFill(i);

    // rotate

    // colorize

    // set floor

    convertedCloud.fill(c);
    convertedCloud.stroke(c);

    // normalize
    convertedCloud.vertex(v.x / max.x, v.y / max.y, v.z / max.z);
  }

  convertedCloud.endShape();

  meshCloudConverted = true;
}

void keyPressed()
{
  if (key == 'E' || key == 'e')
  {
    selectOutput("PLY file to store cloud:", "saveFileSelected");
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

public void savePointCloud(String fileName, PShape cloud)
{
  Path path = Paths.get(fileName);
  PLY ply = new PLY();

  PLYElementList vertex = new PLYElementList(cloud.getVertexCount());

  // coordinates
  float[] x = vertex.addProperty(FLOAT32, "x");
  float[] y = vertex.addProperty(FLOAT32, "y");
  float[] z = vertex.addProperty(FLOAT32, "z");

  // colors
  byte[] r = vertex.addProperty(UINT8, "red");
  byte[] g = vertex.addProperty(UINT8, "green");
  byte[] b = vertex.addProperty(UINT8, "blue");

  for (int i = 0; i < cloud.getVertexCount(); i++)
  {
    PVector v = cloud.getVertex(i);
    color c = cloud.getFill(i);

    // coordinates
    x[i] = v.x;
    y[i] = v.y;
    z[i] = v.z;

    // colors
    r[i] = (byte)red(c);
    g[i] = (byte)green(c);
    b[i] = (byte)blue(c);
  }

  ply.elements.put("vertex", vertex);
  ply.setFormat(ASCII);
  //ply.setFormat(BINARY_LITTLE_ENDIAN);
  println(ply);

  try
  {
    ply.save(path);
  } 
  catch (Exception ex) {
    ex.printStackTrace();
  }
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

    cloud.stroke(rv, gv, bv);
    cloud.vertex(x[i], y[i], z[i]);
  }

  cloud.endShape();
}
