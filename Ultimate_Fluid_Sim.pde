import g4p_controls.*;
import processing.awt.*;
import java.awt.Frame;
import java.util.function.*;
import java.util.stream.*;
import java.util.*;

final float[] rkCoefficients = {1, 0.5, 0.5, 1};
// final float[] rkCoefficients = {1};
GImageToggleButton[] mouseModeButtons;

float divBy;
int[] indexLookup;
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Solid> solids = new ArrayList<Solid>();
Particle testParticle;
float t = 1, lastFrame;
float smoothingRadius = 7;
float zoom = 9;
MouseMode mouseMode = MouseMode.NONE;
float mouseRadius = 10, mousePower = 15;
PVector cameraPos = new PVector(), mouseVec;
FramePos framePos = new FramePos();
int n; // number of particles
boolean fpsCounter = false, paused = false;

ArrayList<PVector> shapePoints = new ArrayList<PVector>();
PVector shapeCMass;
boolean settingCMass = false;

void setup() {
    size(600, 600);
    windowResizable(true);
    // frameRate(1);

    cameraPos.set(-displayWidth / (2 * zoom), -displayHeight / (2 * zoom));
    getFramePos();

    // Arrange in grid/random
    // for (int i = 0; i < 2000; i++) {
    for (int i = -26; i < 26; i++) {
        for (int j = -24; j < 24; j++) {
            particles.add(new Particle(
                new VectorGetter[]{
                    (VectorGetter<PhysicsObject>) PhysicsObject::gravity,
                    (VectorGetter<Particle>) Particle::pressure,
                    (VectorGetter<Particle>) Particle::viscosity,
                    (VectorGetter<Particle>) Particle::mouse
                },
                new VectorGetter[]{
                    (VectorGetter<Particle>) Particle::window,
                    (VectorGetter<Particle>) Particle::solidCollisions
                },
                new PVector(0, 0),
                new PVector(0, 0),
                new PVector(i < 0 ? i * 1 - 10 : i * 1 + 10, j * 1),
                // new PVector(i * 1, j * 1),
                // windowToGlobal(new PVector(random(width), random(height))),
                1,
                0.25,
                15,
                2.5,
                5,
                color(0, 128, 255),
                0.5
                // j < 10 ? 1 : 0.5,
                // j < 10 ? 0.25 : 0.125,
                // j < 10 ? 10 : 1,
                // j < 10 ? 5 : 0.5,
                // j < 10 ? 10 : 5,
                // j < 10 ? color(255, 0, 0) : color(0, 255, 255),
                // 0.5
            ));
        }
    }

    // testParticle = new Particle(
    //     new VectorGetter[]{},
    //     new VectorGetter[]{},
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     // new PVector(i * 2, j * 2),
    //     windowToGlobal(new PVector(random(width), random(height))),
    //     1,
    //     0.25,
    //     15,
    //     2.5,
    //     5,
    //     color(0, 128, 255),
    //     0.5
    // );
    // particles.add(testParticle);
    // particles.add(new Particle(
    //     new VectorGetter[]{Force.GRAVITY},
    //     new VectorGetter[]{VelMod.WINDOW},
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     10,
    //     0.5
    // ));

    // solids.add(new Solid(
    //     new VectorGetter[]{
    //         // (VectorGetter<PhysicsObject>) PhysicsObject::gravity
    //     },
    //     new VectorGetter[]{},
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     50,
    //     new ArrayList<PVector>(Arrays.asList(
    //         new PVector(-5, -10),
    //         new PVector(5, -10),
    //         new PVector(5, 0),
    //         new PVector(-5, 0)
    //     )),
    //     new PVector(0, -5),
    //     0,
    //     true
    // ));

    n = particles.size();
    createGUI();
    hideAllPanels();

    mouseModeButtons = new GImageToggleButton[]{
        toolAddFluid,
        toolRemoveFluid,
        toolRepel,
        toolAttract,
        toolSolid
    };

    for (float coefficient : rkCoefficients) {
        divBy += 1 / coefficient;
    }
}

void draw() {
    background(0);
    pushMatrix();
    scale(zoom);
    translate(-cameraPos.x, -cameraPos.y);

    if (lastFrame == 0) lastFrame = millis();
    // t = (millis() - lastFrame) / 1000 * speed;
    t = 1 / 20.0 * speedSlider.getValueF();

    getFramePos();

    mouseVec = windowToGlobal(new PVector(mouseX, mouseY));

    // Draw hash grid (for debug purposes)
    // PVector start = windowToGlobal(new PVector(0, 0)),
    //         end = windowToGlobal(new PVector(width, height));
    // start.x =
    //     floor(start.x / smoothingRadius) * smoothingRadius - framePos.left;
    // start.y = floor(start.y / smoothingRadius) * smoothingRadius -
    // framePos.top; end.x = floor(end.x / smoothingRadius) * smoothingRadius -
    // framePos.left; end.y = floor(end.y / smoothingRadius) * smoothingRadius -
    // framePos.top;

    // stroke(200);
    // strokeWeight(0.5);
    // for (float i = start.x; i < end.x; i += smoothingRadius) {
    //     line(i, start.y, i, end.y);
    // }
    // for (float i = start.y; i < end.y; i += smoothingRadius) {
    //     line(start.x, i, end.x, i);
    // }

    // testParticle.pos = windowToGlobal(new PVector(mouseX, mouseY));

    if (mouseMode == MouseMode.SOLID) {

        stroke(255);
        noFill();
        strokeWeight(0.5);
        beginShape();
        for (PVector point : shapePoints) {
            vertex(point.x - framePos.left, point.y - framePos.top);
        }
        if (!settingCMass)
            vertex(mouseVec.x - framePos.left, mouseVec.y - framePos.top);
        endShape(CLOSE);

        if (settingCMass) {
            fill(0, 0, 255);
            noStroke();
            circle(mouseVec.x - framePos.left, mouseVec.y - framePos.top, 0.5);
        } else if (shapeCMass != null) {
            fill(0, 0, 255);
            noStroke();
            circle(
                shapeCMass.x - framePos.left,
                shapeCMass.y - framePos.top,
                0.5
            );
        }

    } else if (!paused) {
        // float prevStep = millis();
        // hash the particle positions for optimized neighbor search
        particles.parallelStream().forEach(Particle::hash);
        if (!particles.isEmpty()) {
            particles = mergeSort(
                particles,
                Comparator.comparing(Particle::getHash),
                0,
                particles.size()
            );

            // Store the position of the first time the hash appears
            indexLookup = new int[n];

            indexLookup[particles.get(0).hash] = 0;
            IntStream.range(1, particles.size()).parallel().forEach(i->{
                Particle p = particles.get(i);

                if (p.hash != particles.get(i - 1).hash) {
                    indexLookup[p.hash] = i;
                }
            });
        }

        // float timeDebug = millis();
        // print("Sort: " + (timeDebug - prevStep) + "\t");
        // prevStep = timeDebug;

        // particle precalculations
        particles.parallelStream().forEach(particle->{
            particle.neighborSearch();
            particle.calculateDensity();
            particle.calculatePressure();
        });

        // timeDebug = millis();
        // print("Neighbors: " + (timeDebug - prevStep) + "\t");
        // prevStep = timeDebug;

        // move the particles
        particles.parallelStream().forEach(particle->{
            particle.rk4();
            particle.move();
        });
        solids.parallelStream().forEach(solid->{ solid.move(); });

        // timeDebug = millis();
        // print("Integrate: " + (timeDebug - prevStep) + "\t");
        // prevStep = timeDebug;
    }

    // draw inside a normal for loop because processing doesn't like it when
    // you try to draw things in parallel
    for (Particle particle : particles) {
        // particle.move();
        particle.draw();
    }
    for (Solid solid : solids) {
        solid.draw();
    }

    // timeDebug = millis();
    // print("Draw: " + (timeDebug - prevStep) + "\t");
    // prevStep = timeDebug;
    // println();

    // fill(0, 255, 0);
    // for (Particle particle : testParticle.neighbors) {
    //     circle(
    //         particle.pos.x - framePos.left,
    //         particle.pos.y - framePos.top,
    //         1
    //     );
    // }
    // println(testParticle.hash);

    // noLoop();

    // density test
    // Particle test = particles.get(n / 2 + 7);
    // test.neighborSearch();
    // test.calculateDensity();
    // test.calculatePressure();
    // println(test.density, test.pressure);
    // smoothingRadius += 0.1;

    if (!(mouseMode == MouseMode.NONE || mouseMode == MouseMode.SOLID)) {
        noFill();
        stroke(255);
        strokeWeight(0.25);
        circle(
            mouseVec.x - framePos.left,
            mouseVec.y - framePos.top,
            mouseRadius * 2
        );
    }

    popMatrix();

    if (fpsCounter) {
        // fps counter
        textAlign(RIGHT, TOP);
        textSize(24);
        fill(255);
        text(
            "fps: " + frameRate + "\nmspf: " + (millis() - lastFrame) + "\n" +
                n + " particles",
            width - 10,
            10
        );
    }

    if (mousePressed) {
        switch (mouseMode) {
            case ADD_FLUID:
                colorMode(HSB, 360, 100, 100);
                for (int i = 0; i < mousePower / 30 * PI * pow(mouseRadius, 2);
                     i++) {
                    // delay(500);
                    float theta = random(0, 2 * PI);
                    float mag = sqrt(random(1)) * mouseRadius;
                    particles.add(new Particle(
                        new VectorGetter[]{
                            (VectorGetter<PhysicsObject>)
                                PhysicsObject::gravity,
                            (VectorGetter<Particle>) Particle::pressure,
                            (VectorGetter<Particle>) Particle::viscosity,
                            (VectorGetter<Particle>) Particle::mouse
                        },
                        new VectorGetter[]{
                            (VectorGetter<Particle>) Particle::window,
                            (VectorGetter<Particle>) Particle::solidCollisions
                        },
                        new PVector(0, 0),
                        PVector.fromAngle(velDirectionSlider.getValueF())
                            .mult(velMagSlider.getValueF()),
                        PVector.add(
                            mouseVec,
                            new PVector(cos(theta) * mag, sin(theta) * mag)
                        ),
                        massSlider.getValueF(),
                        pow(2, restDensitySlider.getValueF() - 5),
                        stiffnessSlider.getValueF(),
                        nearStiffnessSlider.getValueF(),
                        pow(viscositySlider.getValueF(), 2),
                        color(
                            HSlider.getValueF(),
                            SLSlider.getValueXF(),
                            SLSlider.getValueYF()
                        ),
                        0.5
                    ));
                    n++;
                }
                colorMode(RGB);
                break;

            case REMOVE_FLUID:
                particles.removeIf(
                    particle->distSq(particle.pos, mouseVec) <
                    pow(mouseRadius, 2)
                );
                n = particles.size();
                break;
        }
    }

    lastFrame = millis();
}

void getFramePos() {
    // Get position of frame in window
    PSurfaceAWT.SmoothCanvas sc =
        (PSurfaceAWT.SmoothCanvas) surface.getNative();
    Frame frame = sc.getFrame();
    framePos.updateCoords(frame.getX(), frame.getY());
}
