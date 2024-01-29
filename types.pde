// A function that returns a PVector, for force calculations and velocity
// modifiers
interface VectorGetter<T extends PhysicsObject> extends Function<T, PVector> {
}