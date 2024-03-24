class Solid extends PhysicsObject {
    ArrayList<PVector> points;
    PVector centerMass, centerPoints = new PVector();
    float rSq, friction;
    float torque, spin;
    boolean fixed;

    Solid(
        VectorGetter[] f,
        VectorGetter[] v,
        PVector force,
        PVector vel,
        PVector pos,
        float mass,
        ArrayList<PVector> points,
        PVector centerMass,
        float friction,
        boolean fixed
    ) {
        super(f, v, force, vel, pos, mass);
        this.points = points;
        this.centerMass = centerMass;
        this.friction = friction;
        this.fixed = fixed;

        if (points.get(0).x > points.get(1).x) {
            Collections.reverse(points);
        }

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
            PVector velStep = PVector.mult(vel, t);
            PVector p1 = PVector.add(points.get(i), velStep),
                    p2 = PVector.add(
                        points.get(i + 1 == points.size() ? 0 : i + 1),
                        velStep
                    );

            // if (p1.x > p2.x) {
            //     PVector temp = p1.copy();
            //     p1 = p2.copy();
            //     p2 = temp;
            // }

            PVector radiusVector = p.vel.copy().setMag(p.radius);
            PVector intersection = intersectOfLines(
                PVector.sub(p.pos, radiusVector),
                PVector.add(p.pos, radiusVector).add(PVector.mult(p.vel, t)),
                p1,
                p2
            );

            if (intersection == null) continue;

            PVector normal = new PVector(p2.y - p1.y, p1.x - p2.x).setMag(1);

            if (PVector.dot(PVector.mult(normal, -1), p.vel) >
                PVector.dot(normal, p.vel)) {
                normal.mult(-1);
            }

            PVector relVel = PVector.sub(p.vel, velAtPoint(intersection));

            PVector velNormal =
                PVector.mult(normal, PVector.dot(relVel, normal));
            PVector velTangent = PVector.sub(relVel, velNormal);

            PVector impulse =
                PVector.sub(velNormal, PVector.mult(velTangent, friction));

            // println(impulse);
            // fill(255, 0, 0);
            // noStroke();
            // circle(
            //     intersection.x - framePos.left,
            //     intersection.y - framePos.top,
            //     1
            // );

            if (!fixed) addImpulse(impulse, intersection);

            p.vel.set(PVector.mult(impulse, -1 / p.mass));
            p.pos.set(PVector.sub(intersection, PVector.mult(normal, p.radius))
            );
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

        spin -= lenImpulse * sin(theta) / intCMass.mag() / mass;
        vel.add(PVector.mult(intCMassNorm, lenImpulse * cos(theta) / mass));
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

    PVector velAtPoint(PVector point) {
        PVector pToC = PVector.sub(point, centerMass);

        PVector rot = pToC.rotate(PI / 2).setMag(spin * pToC.mag());
        return PVector.add(vel, rot);
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

    PVector window() {
        for (PVector point : points) {
            PVector vel = velAtPoint(point);
            PVector posAdj = globalToWindow(pos);
            float bounceDecay = 0.5;
            float minPush = 0;

            if (posAdj.y < 0 || pos.y == Float.POSITIVE_INFINITY) {
                vel.y = (max(abs(vel.y), minPush) + framePos.leftVel * 2 / t) *
                        bounceDecay;
                pos.y = framePos.top + cameraPos.y;
            }
            if (posAdj.x < 0 || pos.x == Float.POSITIVE_INFINITY) {
                vel.x = (max(abs(vel.x), minPush) + framePos.topVel * 2 / t) *
                        bounceDecay;
                pos.x = framePos.left + cameraPos.x;
            }
            if (posAdj.y > height || pos.y == Float.NEGATIVE_INFINITY) {
                vel.y =
                    (-max(abs(vel.y), minPush) + framePos.rightVel * 2 / t) *
                    bounceDecay;
                pos.y = framePos.bottom + cameraPos.y;
            }
            if (posAdj.x > width || pos.x == Float.NEGATIVE_INFINITY) {
                vel.x =
                    (-max(abs(vel.x), minPush) + framePos.bottomVel * 2 / t) *
                    bounceDecay;
                pos.x = framePos.right + cameraPos.x;
            }
        }
        return vel;
    }
}