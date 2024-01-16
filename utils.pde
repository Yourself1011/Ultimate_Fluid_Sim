/**
 * A utility function to efficiently give the distance between two points,
 squared
 @param  a  the first position
 @param  b  the second position
 @return  the distance between the two positions, squared
 */
float distSq(PVector a, PVector b) {
    return pow(a.x - b.x, 2) + pow(a.y - b.y, 2);
}

/**
 * If a component of the vector is NaN or infinity, set it to 0 to avoid
 * breaking everything. Returns the result and modifies in place
 * @param  vec  the vector to fix
 * @return  the vector without non-number components
 */
PVector fixVector(PVector vec) {
    if (Float.isNaN(vec.x)) {
        println("x component was NaN");
        vec.x = 0;
    }
    if (Float.isNaN(vec.y)) {
        println("y component was NaN");
        vec.y = 0;
    }
    return vec;
}