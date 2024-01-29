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
    if (Float.isNaN(vec.x) || vec.x == Float.POSITIVE_INFINITY ||
        vec.x == Float.NEGATIVE_INFINITY) {
        // println("x component was NaN");
        vec.x = 0;
    }
    if (Float.isNaN(vec.y) || vec.y == Float.POSITIVE_INFINITY ||
        vec.y == Float.NEGATIVE_INFINITY) {
        // println("y component was NaN");
        vec.y = 0;
    }
    vec.z = 0;
    // if (vec.z != 0 || vec.z == Float.POSITIVE_INFINITY ||
    //     vec.z == Float.NEGATIVE_INFINITY) {
    // }
    return vec;
}

// Intersection of lines between four points, where p1 and p2 form a line, and
// p3 and p4 form a line
PVector intersectOfLines(PVector p1, PVector p2, PVector p3, PVector p4) {
    float t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) /
              ((p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x));
    float u = -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) /
              ((p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x));

    // println(t, u, p1, p2, p3, p4);
    if (t < 0 || t > 1 || u < 0 || u > 1) {
        return null;
    }
    return PVector.add(p1, PVector.sub(p2, p1).mult(t));
}

PVector rotatePoint(PVector point, PVector origin, float theta) {
    return point.sub(origin).rotate(theta).add(origin);
}
