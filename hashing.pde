/**
 * A function to hash the position of a particle to optimize neighbor searching
 * @param  p  the position of the particle
 * @return  the hash number (int)
 */
int hashPosition(PVector p) {
    return Math.floorMod(
        (floor(p.x / smoothingRadius) * 73856093) ^
            (floor(p.y / smoothingRadius) * 19349663),
        n
    );
}