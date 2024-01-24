class Particle extends PhysicsObject {
    float density, nearDensity, pressure, restDensity, stiffness, viscosity;
    int hash;
    color col;
    ArrayList<Particle> neighbors = new ArrayList<Particle>();

    Particle(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float mass,
        float restDensity,
        float stiffness,
        float viscosity,
        color col
    ) {
        super(f, v, force, vel, pos, mass);
        this.restDensity = restDensity;
        this.stiffness = stiffness;
        this.viscosity = viscosity;
        this.col = col;
        this.prevPos = pos.copy();
    }

    void hash() {
        hash = hashPosition(this.pos);
    }

    int getHash() {
        return this.hash;
    }

    void neighborSearch() {
        neighbors.clear();

        // basic quadratic neighbor search
        // for (Particle particle : particles) {
        //     if (particle != this &&
        //         distSq(this.pos, particle.pos) <= pow(smoothingRadius, 2))
        //         neighbors.add(particle);
        // }

        // neighbor search with hashing
        for (float x = -smoothingRadius; x <= smoothingRadius;
             x += smoothingRadius) {
            for (float y = -smoothingRadius; y <= smoothingRadius;
                 y += smoothingRadius) {
                int cellHash = hashPosition(pos.copy().add(x, y));
                int firstIndex = binarySearch(
                    particles,
                    cellHash,
                    Particle::getHash,
                    0,
                    n,
                    -n / 2,
                    n / 2
                );

                if (firstIndex != -1) {
                    ArrayList<Particle> candidates = new ArrayList();
                    // add this particle to neighbors if in range
                    Particle p = particles.get(firstIndex);

                    candidates.add(p);

                    int iBack = firstIndex;

                    // Go back from the particle we first found until we've
                    // found all particles with the hash we are looking for. Add
                    // them if they are in range

                    while (true) {
                        iBack--;
                        if (iBack < 0) break;

                        p = particles.get(iBack);
                        if (p.hash != cellHash) break;

                        candidates.add(p);
                        p = particles.get(iBack);
                    }

                    // Go forwards from the particle we first found until
                    // we've found all particles with the hash we are
                    // looking for. Add them if they are in range
                    while (true) {
                        firstIndex++;
                        if (firstIndex >= particles.size()) break;

                        p = particles.get(firstIndex);
                        if (p.hash != cellHash) break;

                        candidates.add(p);
                        p = particles.get(firstIndex);
                    }

                    for (Particle particle : candidates) {
                        float distSq = distSq(this.pos, particle.pos);
                        if (particle != this) {

                            if (distSq == 0 || Float.isNaN(distSq)) {
                                force.add(PVector.random2D().mult(0.25));
                                // println(this.pos, particle.pos, distSq);
                            } else if (distSq <= pow(smoothingRadius, 2)) {
                                neighbors.add(particle);
                            }
                        }
                    }
                }
            }
        }
    }

    void calculateDensity() {
        this.density = this.mass * smoothKernelFunction(0, smoothingRadius);
        // include this particle in density calculations

        // this.density = 0;
        // println(density);

        for (Particle particle : neighbors) {
            float distSq = distSq(this.pos, particle.pos);

            density +=
                particle.mass * smoothKernelFunction(distSq, smoothingRadius);
        }
        // if (density < 0) println("WTF");

        // draw a ring around the smoothing radius
        // stroke(255, 0, 0);
        // noFill();
        // circle(pos.x - frameX, pos.y - frameY, smoothingRadius * 2);
    }

    void calculatePressure() {
        pressure = stiffness * (pow(density / restDensity, 7) - 1);
        // pressure = 100 * stiffness * (density - restDensity);
    }

    void draw() {
        // println(pressure);
        fill(lerpColor(
            color(8, 8, 255),
            color(255, 0, 0),
            map(pressure, -stiffness, stiffness, 0, 1)
        ));
        // fill(col);
        noStroke();
        circle(pos.x - framePos.left, pos.y - framePos.top, 0.5);
        // stroke(255);
        // strokeWeight(0.25);
        // line(
        //     prevPos.x - frameX,
        //     prevPos.y - frameY,
        //     pos.x - frameX,
        //     pos.y - frameY
        // );
        // prevPos.set(pos);
    }

    PVector mouse() {
        if (!mousePressed) return new PVector();
        if (!(mouseMode == MouseMode.ATTRACT || mouseMode == MouseMode.REPEL))
            return new PVector();

        float distSq = distSq(tempPos, mouseVec);
        if (distSq > pow(mouseRadius, 2)) return new PVector();
        return PVector.sub(mouseVec, tempPos)
            .mult(mouseMode == MouseMode.ATTRACT ? mousePower : -mousePower);
    }

    PVector pressure() {
        PVector pForce = new PVector(0, 0);
        PVector toAdd = new PVector(0, 0);

        for (Particle particle : neighbors) {
            toAdd.set(0, 0);

            // if (particle.density > 0 && this.density > 0) {
            toAdd = gradCubic(this.tempPos, particle.pos, smoothingRadius)
                        .mult(
                            particle.mass *
                            ((this.pressure / pow(this.density, 2) +
                              (particle.pressure / pow(particle.density, 2))))
                        );
            // .mult(
            //     particle.mass * (this.pressure + particle.pressure) /
            //     particle.density
            // );
            // if (toAdd.mag() > 100) {
            //     println(
            //         toAdd,
            //         this.tempPos,
            //         this.density,
            //         this.restDensity,
            //         this.pressure,
            //         particle.pos,
            //         particle.density,
            //         particle.pressure,
            //         gradSpiky(this.tempPos, particle.pos, smoothingRadius)
            //     );
            //     noLoop();
            // }
            // }

            // if (!(Float.isNaN(toAdd.x) || Float.isNaN(toAdd.y))) {
            pForce.add(fixVector(toAdd));
            // } else {
            //     println(this.pos, particle.pos, particle.vel);
            // }

            // if (toAdd.mag() > 1E10) {
            //     println(toAdd);
            // }
        }
        pForce.mult(-this.mass / this.density);
        // println(pForce);
        return pForce;
    }

    PVector viscosity() {
        PVector vForce = new PVector(0, 0);

        for (Particle particle : neighbors) {

            // if (PVector.dist(particle.pos, this.tempPos) == 0) {
            //     vForce.add(new PVector(1, 0).rotate(random(2 * PI)));
            //     continue;
            // }

            float dist = PVector.dist(particle.pos, this.tempPos);
            vForce.add(
                fixVector(PVector.sub(particle.vel, this.tempVel)
                              .mult(
                                  laplacianViscosity(dist, smoothingRadius) *
                                  particle.mass / particle.density
                              ))
            );
            // vForce.add(PVector.mult(
            //     particle.pos,
            //     laplacianViscosity(dist, smoothingRadius) * particle.mass /
            //         particle.density
            // ));
        }

        return vForce.mult(viscosity);
    }

    PVector window() {
        PVector vel = this.vel.copy();
        float xAdj = pos.x - frameX - cameraPos.x,
              yAdj = pos.y - frameY - cameraPos.y;
        PVector posAdj = globalToWindow(pos);
        float bounceDecay = 0.25;
        float minPush = 1;

        if (posAdj.y < 0 || pos.y == Float.POSITIVE_INFINITY) {
            vel.y = (max(abs(vel.y), minPush) + framePos.leftVel * 2 / t) *
                    bounceDecay;
            pos.y = framePos.top + cameraPos.y + vel.y * t;
        }
        if (posAdj.x < 0 || pos.x == Float.POSITIVE_INFINITY) {
            vel.x = (max(abs(vel.x), minPush) + framePos.topVel * 2 / t) *
                    bounceDecay;
            pos.x = framePos.left + cameraPos.x + vel.x * t;
        }
        if (posAdj.y > height || pos.y == Float.NEGATIVE_INFINITY) {
            vel.y = (-max(abs(vel.y), minPush) + framePos.rightVel * 2 / t) *
                    bounceDecay;
            pos.y = framePos.bottom + cameraPos.y + vel.y * t;
        }
        if (posAdj.x > width || pos.x == Float.NEGATIVE_INFINITY) {
            vel.x = (-max(abs(vel.x), minPush) + framePos.bottomVel * 2 / t) *
                    bounceDecay;
            pos.x = framePos.right + cameraPos.x + vel.x * t;
        }

        return vel;
    }
}