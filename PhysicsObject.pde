abstract class PhysicsObject {
    VectorGetter[] forces;
    VectorGetter[] velMods;
    PVector force, vel, tempVel = new PVector(), pos, tempPos = new PVector(),
                        prevPos = new PVector();
    ArrayList<PVector> k = new ArrayList<PVector>();
    float mass;

    PhysicsObject(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float mass
    ) {
        this.forces = f;
        this.velMods = v;
        this.force = force;
        this.vel = vel;
        this.pos = pos;
        this.mass = mass;

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
            kThis.add(fixVector((PVector) f.apply(this)));
            // if (kThis.mag() == Float.POSITIVE_INFINITY) println(f);
        }

        // find the rest
        for (int i = 1; i < rkCoefficients.length; i++) {
            tempVel.add(PVector.mult(kThis, t * rkCoefficients[i] / mass));
            tempPos.add(PVector.mult(tempVel, t * rkCoefficients[i]));

            kThis = k.get(i);
            kThis.set(0, 0);

            for (VectorGetter f : forces) {
                kThis.add(fixVector((PVector) f.apply(this)));
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
        force.set(0, 0);

        for (VectorGetter v : velMods) {
            vel = fixVector((PVector) v.apply(this));
        }

        pos.add(PVector.mult(vel, t));
        fixVector(pos);
    }

    abstract void draw();

    PVector gravity() {
        return new PVector(0, 9.81 * mass);
    }
}