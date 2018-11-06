import java.util.List;
import java.util.Collections;
import java.util.Comparator;

static PVector zeroVector = new PVector(0, 0, 10000);

static final Comparator<PVector> VectorComperator = new Comparator<PVector>() {
  @ Override final int compare(final PVector a, final PVector b) {
    int cmp;
    return
    /*
      (cmp = Float.compare(a.x, b.x)) != 0 ? cmp :
     (cmp = Float.compare(a.y, b.y)) != 0? cmp :
     Float.compare(a.z, b.z)*/
      Float.compare(PVector.dist(a, zeroVector), PVector.dist(b, zeroVector));
  }
};
