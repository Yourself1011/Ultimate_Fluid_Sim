/**
 * A function to hash the position of a particle to optimize neighbor searching
 * @param  p  the position of the particle
 * @return  the hash number (int)
 */
int hashPosition(PVector p) {
    float gridSize = smoothingRadius;
    return ((floor(p.x / gridSize) * 73856093) ^
            (floor(p.y / gridSize) * 19349663)) %
           (n / 2);
}