class Solid extends PhysicsObject {
    ArrayList<PVector> points;
    PVector centerMass, centerPoints = new PVector();
    float rSq, friction;
    float torque, spin;

    Solid(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float mass,
        ArrayList<PVector> points,
        PVector centerMass,
        float friction
    ) {
        super(f, v, force, vel, pos, mass);
        this.points = points;
        this.centerMass = centerMass;
        this.friction = friction;

        for (PVector point : points) {
            centerPoints.add(point);
        }
        centerPoints.div(points.size());

        for (PVector point : points) {
            float distSq = distSq(point, centerPoints);
            if (distSq > rSq) rSq = distSq;
        }
    }

    void checkCollision(Particle p) {
        if (distSq(p.pos, centerPoints) > rSq) return;

        for (int i = 0; i < points.size(); i++) {
            PVector p1 = points.get(i),
                    p2 = points.get(i + 1 == points.size() ? 0 : i + 1);

            PVector intersection = intersectOfLines(
                p.pos,
                PVector.add(p.pos, PVector.mult(p.vel, t)),
                p1,
                p2
            );

            if (intersection == null) continue;

            PVector normal = new PVector(p2.y - p1.y, p1.x - p2.x).setMag(1);
            PVector relVel = PVector.sub(p.vel, this.vel);

            PVector velNormal =
                PVector.mult(normal, PVector.dot(relVel, normal));
            PVector velTangent = PVector.sub(relVel, velNormal);

            PVector impulse =
                PVector.sub(velNormal, PVector.mult(velTangent, friction));

            // println(impulse);
            // fill(255, 0, 0);
            // circle(
            //     intersection.x - framePos.left,
            //     intersection.y - framePos.top,
            //     1
            // );

            addImpulse(impulse, intersection);

            p.vel.set(PVector.mult(impulse, -1 / p.mass));
        }
    }

    void addImpulse(PVector impulse, PVector intersection) {
        float lenImpulse = impulse.mag();

        PVector impulseNorm = impulse.copy().setMag(1);
        PVector intCMass = PVector.sub(centerMass, intersection);
        PVector intCMassNorm = intCMass.copy().setMag(1);

        float theta = asin(
            intCMassNorm.x * impulseNorm.y - intCMassNorm.y * impulseNorm.x
        );

        spin += lenImpulse * sin(theta) / intCMass.mag() / mass;
        vel.set(PVector.mult(intCMassNorm, lenImpulse * cos(theta) / mass));
    }

    @Override void move() {
        for (VectorGetter f : forces) {
            force.add(fixVector((PVector) f.apply(this)));
        }

        vel.add(PVector.mult(force, t / mass));
        spin += torque * t / mass;

        for (VectorGetter v : velMods) {
            vel = fixVector((PVector) v.apply(this));
        }

        translate(PVector.mult(vel, t));
        rotate(spin * t);

        force.set(0, 0);
        torque = 0;
    }

    void translate(PVector translation) {
        for (PVector point : points) {
            point.add(translation);
        }
        centerMass.add(translation);
        centerPoints.add(translation);
    }

    void rotate(float theta) {
        for (PVector point : points) {
            rotatePoint(point, centerMass, theta);
        }
        rotatePoint(centerPoints, centerMass, theta);
    }

    void draw() {
        stroke(255);
        noFill();
        strokeWeight(0.5);
        beginShape();
        for (PVector point : points) {
            vertex(point.x - framePos.left, point.y - framePos.top);
        }
        endShape(CLOSE);
    }
}