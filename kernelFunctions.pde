
/**
 * A "spiky" kernel function used for pressure and density
 * @param  dist the distance between the two particles
 * @param  r  the smoothing radius
 * @return  how much the other particle affects the property
 */
float spikyKernelFunction(float dist, float r) {
    if (dist > r) return 0;
    return (3) / (2 * PI * pow(r, 4)) * pow(r - dist, 2);
}

/**
 * The gradient of the above spiky kernel function
 * @param  i  the current position
 * @param  j  the other particle's position
 * @param  r  the smoothing radius
 * @return  the gradient vector
 */
PVector gradSpiky(PVector i, PVector j, float r) {
    float dist = PVector.dist(i, j);
    if (dist > r) return new PVector();
    float coefficient = -(6 * (r - dist)) / (2 * PI * pow(r, 4) * dist);

    // return new PVector(
    //     -(9 * (i.x - j.x) * pow(r - dist, 2)) / (2 * PI * pow(r, 5) * dist),
    //     -(9 * (i.y - j.y) * pow(r - dist, 2)) / (2 * PI * pow(r, 5) * dist)
    // );
    return PVector.sub(i, j).mult(coefficient);
}

/**
 * A cubic kernel function used to remove particle clumping
 * @param  dist the distance between the two particles
 * @param  r  the smoothing radius
 * @return  how much the other particle affects the property
 */
float cubicKernelFunction(float dist, float r) {
    if (dist > r) return 0;
    return (3) / (2 * PI * pow(r, 5)) * pow(r - dist, 3);
}

/**
 * The gradient of the above cubic kernel function
 * @param  i  the current position
 * @param  j  the other particle's position
 * @param  r  the smoothing radius
 * @return  the gradient vector
 */
PVector gradCubic(PVector i, PVector j, float r) {
    float dist = PVector.dist(i, j);
    if (dist > r) return new PVector();
    float coefficient = -(9 * pow(r - dist, 2)) / (2 * PI * pow(r, 5) * dist);

    // return new PVector(
    //     -(9 * (i.x - j.x) * pow(r - dist, 2)) / (2 * PI * pow(r, 5) * dist),
    //     -(9 * (i.y - j.y) * pow(r - dist, 2)) / (2 * PI * pow(r, 5) * dist)
    // );
    return PVector.sub(i, j).mult(coefficient);
}

Cache<Float, Float> smoothKernelCoefficient = new Cache<Float, Float>(
    (Function<Float, Float>) (Float r)->3 / (2 * PI * pow(r, 8)),
    smoothingRadius
);

/**
 * A smooth kernel function used for everything else
 * @param  distSq  the distance between the two particles, squared. This is
 * calculated in the distance calculation anyway, so it is a small optimization
 * @param  r  the smoothing radius
 * @return  how much the other particle affects the property
 */
float smoothKernelFunction(float distSq, float r) {
    //     return 128 * (315) / (64 * PI * pow(r, 8)) * pow(pow(r, 2) - distSq,
    //     3);
    if (distSq > pow(r, 2)) return 0;
    // return 3 / (2 * PI * pow(r, 8)) * pow(pow(r, 2) - distSq, 3);
    return smoothKernelCoefficient.get(r) * pow(pow(r, 2) - distSq, 3);
}

/**
 * A kernel function used for viscosity
 * @param  dist  the distance between the two particles, squared
 * @param  r  the smoothing radius
 * @return  how much the other particle affects the property
 */
float viscosityKernelFunction(float dist, float r) {
    if (dist > r) return 0;
    return 15 / (2 * PI * pow(r, 2)) *
           (-pow(dist, 3) / (2 * pow(r, 2)) + pow(dist, 2) / pow(r, 2) +
            r / (2 * dist) - 2);
}

Cache<Float, Float> laplacianViscosityCoefficient = new Cache<Float, Float>(
    (Function<Float, Float>) (Float r)->(30) / (PI * pow(r, 6)),
    smoothingRadius
);

/**
 * The Laplacian of the above function
 * @param  dist  the distance between the two particles, squared
 * @param  r  the smoothing radius
 * @return  The laplacian of the viscosity kernel
 */
float laplacianViscosity(float dist, float r) {
    if (dist > r) return 0;
    return laplacianViscosityCoefficient.get(r) * (r - dist);
}