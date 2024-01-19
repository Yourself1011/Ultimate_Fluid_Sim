class Particle {
    VectorGetter[] forces;
    VectorGetter[] velMods;
    PVector force, vel, tempVel = new PVector(), pos, tempPos = new PVector(),
                        prevPos = new PVector();
    ArrayList<PVector> k = new ArrayList<PVector>();
    float mass, density, pressure, restDensity, stiffness, viscosity;
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
        this.forces = f;
        this.velMods = v;
        this.force = force;
        this.vel = vel;
        this.pos = pos;
        this.mass = mass;
        this.restDensity = restDensity;
        this.stiffness = stiffness;
        this.viscosity = viscosity;
        this.col = col;

        for (int i = 0; i < rkCoefficients.length; i++) {
            k.add(new PVector());
        }
    }

    void rk4() {
        // find k1
        PVector kThis = k.get(0);
        kThis.set(force);
        // includes any forces applied during neighbor search
        // (eg. random force from particles on top of each other)

        tempVel.set(vel);
        tempPos.set(pos);

        for (VectorGetter f : forces) {
            kThis.add(fixVector(f.apply(this)));
            // if (kThis.mag() == Float.POSITIVE_INFINITY) println(f);
        }

        // find the rest
        for (int i = 1; i < rkCoefficients.length; i++) {
            tempVel.add(PVector.mult(kThis, t * rkCoefficients[i] / mass));
            tempPos.add(PVector.mult(tempVel, t * rkCoefficients[i]));

            kThis = k.get(i);
            kThis.set(0, 0);

            for (VectorGetter f : forces) {
                kThis.add(fixVector(f.apply(this)));
            }
        }
    }

    void move() {
        for (int i = 0; i < rkCoefficients.length; i++) {
            force.add(k.get(i).div(rkCoefficients[i]));
        }
        force.div(divBy);

        // for (VectorGetter f : forces) {
        //     force.add(fixVector(f.apply(this)));
        // }

        vel.add(PVector.mult(force, t / mass));

        for (VectorGetter v : velMods) {
            vel = fixVector(v.apply(this));
        }

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
                        if (particle != this) {

                            if (distSq == 0 || Float.isNaN(distSq)) {
                                force.add(PVector.random2D());
                                // println(this.pos, particle.pos, distSq);
                            } else if (distSq <= pow(smoothingRadius, 2))
                                neighbors.add(particle);
                        }
                    }
                }
                // println("e");
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
        // pressure = 500 * stiffness * (density - restDensity);
    }

    void draw() {
        // println(pressure);
        // fill(lerpColor(
        //     color(8, 8, 255),
        //     color(255, 0, 0),
        //     map(pressure, -stiffness, stiffness, 0, 1)
        // ));
        fill(col);
        noStroke();
        circle(pos.x - frameX, pos.y - frameY, 0.5);
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
        PVector empty = new PVector(0, 0);
        if (!mousePressed) return empty;

        float distSq = distSq(tempPos, mouseVec);
        if (distSq > pow(mouseRadius, 2)) return empty;
        return PVector.sub(mouseVec, tempPos).mult(mousePower);
    }

    PVector gravity() {
        return new PVector(0, 9.81 * mass);
    }

    PVector pressure() {
        PVector pForce = new PVector(0, 0);
        PVector toAdd = new PVector(0, 0);

        for (Particle particle : neighbors) {
            toAdd.set(0, 0);

            // if (particle.density > 0 && this.density > 0) {
            toAdd =
                gradCubic(this.tempPos, particle.pos, smoothingRadius)
                    // .mult(
                    //     particle.mass *
                    //     ((this.pressure / pow(this.density, 2) +
                    //       (particle.pressure / pow(particle.density,
                    //       2))))
                    // );
                    .mult(
                        particle.mass * (this.pressure + particle.pressure) /
                        particle.density
                    );
            // if (toAdd.mag() > 100) println(toAdd);
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
        float bounceDecay = 0.25;
        float minPush = 1;

        if (yAdj < 0 || pos.y == Float.POSITIVE_INFINITY) {
            vel.y = (max(abs(vel.y), minPush) + (frameY - lastFrameY) * 2 / t) *
                    bounceDecay;
            pos.y = frameY + cameraPos.y + vel.y * t;
        }
        if (xAdj < 0 || pos.x == Float.POSITIVE_INFINITY) {
            vel.x = (max(abs(vel.x), minPush) + (frameX - lastFrameX) * 2 / t) *
                    bounceDecay;
            pos.x = frameX + cameraPos.x + vel.x * t;
        }
        if (yAdj > height / zoom || pos.y == Float.NEGATIVE_INFINITY) {
            vel.y =
                (-max(abs(vel.y), minPush) + (lastFrameY - frameY) * 2 / t) *
                bounceDecay;
            pos.y = height / zoom + frameY + cameraPos.y + vel.y * t;
        }
        if (xAdj > width / zoom || pos.x == Float.NEGATIVE_INFINITY) {
            vel.x =
                (-max(abs(vel.x), minPush) + (lastFrameX - frameX) * 2 / t) *
                bounceDecay;
            pos.x = width / zoom + frameX + cameraPos.x + vel.x * t;
        }

        return vel;
    }
}