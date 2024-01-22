class Solid extends PhysicsObject {
    ArrayList<PVector> points;
    PVector centerMass;

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
    }

    void draw() {
    }
}