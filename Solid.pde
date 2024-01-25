class Solid extends PhysicsObject {
    ArrayList<PVector> points;
    PVector centerMass, centerPoints = new PVector();
    float rSq;

    Solid(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float mass,
        ArrayList<PVector> points,
        PVector centerMass
    ) {
        super(f, v, force, vel, pos, mass);
        this.points = points;
        this.centerMass = centerMass;

        for (PVector point : points) {
            centerPoints.add(point);
        }
        centerPoints.div(points.size());

        for (PVector point : points) {
            float distSq = distSq(point, centerPoints);
            if (distSq > rSq) rSq = distSq;
        }
    }

    void checkCollision(Particle p) {
        if (distSq(p.pos, centerPoints) > rSq) return;
    }

    void draw() {
    }
}