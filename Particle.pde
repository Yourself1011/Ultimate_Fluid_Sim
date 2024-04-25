class Particle {
    VectorGetter[] forces;
    VectorGetter[] velMods;
    PVector force, vel, pos;
    float mass = 1, density, pressure, restDensity, stiffness, viscosity;
    int hash;
    color col;
    ArrayList<Particle> neighbors = new ArrayList<Particle>();

    Particle(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float restDensity,
        float stiffness,
        float viscosity,
        color col
    ) {
        this.forces = f;
        this.velMods = v;
        this.force = force;
        this.vel = vel;
        this.pos = pos;
        this.restDensity = restDensity;
        this.stiffness = stiffness;
        this.viscosity = viscosity;
        this.col = col;
    }

    void move() {
        for (VectorGetter f : forces) {
            force.add(f.apply(this));
        }
        fixVector(force);

        vel.add(force.div(mass).mult(t));

        for (VectorGetter v : velMods) {
            vel = v.apply(this);
        }

        fixVector(vel);
        pos.add(PVector.mult(vel, t));
        fixVector(pos);
        force.set(0, 0);
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
                // println("sussy");
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
                        if (distSq == 0) {
                            force.add(new PVector(1, 0).rotate(random(2 * PI)));
                            continue;
                        }

                        if (particle != this &&
                            distSq <= pow(smoothingRadius, 2))
                            neighbors.add(particle);
                    }
                }
                // println("e");
            }
        }
    }

    void calculateDensity() {
        this.density = 0;

        for (Particle particle : neighbors) {
            float distSq = distSq(this.pos, particle.pos);

            density +=
                particle.mass * smoothKernelFunction(distSq, smoothingRadius);
        }

        // draw a ring around the smoothing radius
        stroke(255, 0, 0);
        strokeWeight(0.5);
        noFill();
        circle(pos.x - frameX, pos.y - frameY, smoothingRadius * 2);
    }

    void calculatePressure() {
        pressure = stiffness * (pow(density / restDensity, 7) - 1);
        // pressure = stiffness * (density - restDensity);
    }

    void draw() {
        // println(pressure);
        // fill(lerpColor(
        //     color(0, 0, 255),
        //     color(255, 0, 0),
        //     map(pressure, -stiffness, stiffness, 0, 1)
        // ));
        fill(col);
        noStroke();
        circle(pos.x - frameX, pos.y - frameY, 0.5);
    }

    PVector mouse() {
        PVector empty = new PVector(0, 0);
        if (!mousePressed) return empty;

        if (distSq(pos, mouseVec) > pow(mouseRadius, 2)) return empty;
        return PVector.sub(mouseVec, pos).mult(mousePower);
    }

    PVector gravity() {
        return new PVector(0, 9.81 * mass);
    }

    PVector pressure() {
        PVector pForce = new PVector(0, 0);
        PVector toAdd = new PVector(0, 0);

        for (Particle particle : neighbors) {
            toAdd.set(0, 0);
            if (PVector.dist(particle.pos, this.pos) == 0) {
                toAdd = new PVector(1, 0).rotate(random(2 * PI));

            } else if (particle.density > 0 && this.density > 0) {
                toAdd = gradCubic(this.pos, particle.pos, smoothingRadius)
                            // .mult(
                            //     particle.mass *
                            //     ((this.pressure / pow(this.density, 2) +
                            //       (particle.pressure / pow(particle.density,
                            //       2))))
                            // );
                            .mult(
                                particle.mass *
                                (this.pressure + particle.pressure) /
                                particle.density
                            );
            }

            // if (!(Float.isNaN(toAdd.x) || Float.isNaN(toAdd.y))) {
            pForce.add(toAdd);
            // } else {
            //     println(this.pos, particle.pos, particle.vel);
            // }

            // if (toAdd.mag() > 1E10) {
            //     println(toAdd);
            // }
        }
        pForce.mult(-this.mass);
        // println(pForce);
        return pForce;
    }

    PVector viscosity() {
        PVector vForce = new PVector(0, 0);

        for (Particle particle : neighbors) {

            if (PVector.dist(particle.pos, this.pos) == 0) {
                vForce.add(new PVector(1, 0).rotate(random(2 * PI)));
                continue;
            }

            float dist = PVector.dist(particle.pos, this.pos);
            vForce.add(PVector.sub(particle.vel, this.vel)
                           .mult(
                               laplacianViscosity(dist, smoothingRadius) *
                               particle.mass / particle.density
                           ));
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
        float bounceDecay = 0.25;
        float minPush = 1;

        if (yAdj < 0) {
            pos.y = frameY + cameraPos.y;
            vel.y = (max(abs(vel.y), minPush) + (frameY - lastFrameY) * 2 / t) *
                    bounceDecay;
        }
        if (xAdj < 0) {
            pos.x = frameX + cameraPos.x;
            vel.x = (max(abs(vel.x), minPush) + (frameX - lastFrameX) * 2 / t) *
                    bounceDecay;
        }
        if (yAdj > height / zoom) {
            pos.y = height / zoom + frameY + cameraPos.y;
            vel.y =
                (-max(abs(vel.y), minPush) + (lastFrameY - frameY) * 2 / t) *
                bounceDecay;
        }
        if (xAdj > width / zoom) {
            pos.x = width / zoom + frameX + cameraPos.x;
            vel.x =
                (-max(abs(vel.x), minPush) + (lastFrameX - frameX) * 2 / t) *
                bounceDecay;
        }

        return vel;
    }
}