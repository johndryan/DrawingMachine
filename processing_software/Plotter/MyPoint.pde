class MyPoint extends RPoint implements Comparable<MyPoint> {
  public MyPoint(RPoint p) {
    super(p);
  }
  public int compareTo(MyPoint other) {
    return (x < other.x) ? -1 : (x == other.x) ? 0 : 1;
  }     
}
