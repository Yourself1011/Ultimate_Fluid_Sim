import g4p_controls.*;
import processing.awt.*;
import java.awt.Frame;
import java.util.function.*;
import java.util.*;

ArrayList<Particle> particles = new ArrayList<Particle>();
Particle testParticle;
float t, lastFrame, speed = 1;
float smoothingRadius = 10;
float zoom = 9;
float mouseRadius = 10, mousePower = 15;
PVector cameraPos = new PVector(0, 0), mouseVec;
float frameX, frameY, lastFrameX, lastFrameY;
int n; // number of particles
boolean fpsCounter = true;

void setup() {
    size(600, 600);
    windowResizable(true);
    // frameRate(1);

    // merge sort test
    // ArrayList<Float> l = new ArrayList<Float>();
    // for (int i = 0; i < 21; i++) {
    //     l.add(random(10));
    // }
    // println(
    //     this.<Float>mergeSort(l, Comparator.<Float>naturalOrder(), 0,
    //     l.size())
    // );
    // noLoop();

    // binary search test
    // ArrayList<Integer> l = new ArrayList<Integer>();
    // l.add(1);
    // l.add(2);
    // l.add(2);
    // l.add(2);
    // l.add(2);
    // l.add(3);
    // l.add(3);
    // l.add(3);
    // l.add(5);
    // l.add(5);
    // l.add(5);
    // l.add(5);
    // l.add(6);
    // l.add(6);
    // l.add(8);
    // println(
    //     this.<Integer>binarySearch(l, 4, Integer::intValue, 0, l.size(), 1,
    //     6)
    // );

    cameraPos.set(-displayWidth / (2 * zoom), -displayHeight / (2 * zoom));
    getFramePos();

    // Arrange in grid/random
    // for (int i = 0; i < 2000; i++) {
    for (int i = -25; i < 25; i++) {
        for (int j = -25; j < 25; j++) {
            particles.add(new Particle(
                new VectorGetter[]{
                    Particle::pressure,
                    Particle::viscosity,
                    Particle::gravity,
                    Particle::mouse
                },
                new VectorGetter[]{Particle::window},
                new PVector(0, 0),
                new PVector(0, 0),
                new PVector(i * 1, j * 1),
                // windowToGlobal(new PVector(random(width), random(height))),
                0.25,
                10,
                15,
                color(255, 0, 0)
                // i < 0 ? 0.25 : 0.3,
                // 15,
                // i < 0 ? 400 : 10,
                // i < 0 ? color(255, 0, 0) : color(0, 255, 255)
            ));
        }
    }

    // testParticle = new Particle(
    //     new VectorGetter[]{},
    //     new VectorGetter[]{VelMod.WINDOW},
    //     new PVector(0, 0),
    //     new PVector(0, 0),
    //     // new PVector(i * 2, j * 2),
    //     windowToGlobal(new PVector(random(width), random(height))),
    //     0.075,
    //     15
    //     // 0.035,
    //     // 15
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
    n = particles.size();
    createGUI();
}

void draw() {
    background(0);
    pushMatrix();
    scale(zoom);
    translate(-cameraPos.x, -cameraPos.y);

    if (lastFrame == 0) lastFrame = millis();
    // t = (millis() - lastFrame) / 1000 * speed;
    t = 1 / 10.0;
    lastFrame = millis();

    getFramePos();

    mouseVec = windowToGlobal(new PVector(mouseX, mouseY));

    // Draw hash grid (for debug purposes)
    // PVector start = windowToGlobal(new PVector(0, 0)),
    //         end = windowToGlobal(new PVector(width, height));
    // start.x = floor(start.x / smoothingRadius) * smoothingRadius - frameX;
    // start.y = floor(start.y / smoothingRadius) * smoothingRadius - frameY;
    // end.x = floor(end.x / smoothingRadius) * smoothingRadius - frameX;
    // end.y = floor(end.y / smoothingRadius) * smoothingRadius - frameY;

    // stroke(200);
    // strokeWeight(0.5);
    // for (float i = start.x; i < end.x; i += smoothingRadius) {
    //     line(i, start.y, i, end.y);
    // }
    // for (float i = start.y; i < end.y; i += smoothingRadius) {
    //     line(start.x, i, end.x, i);
    // }

    // testParticle.pos = windowToGlobal(new PVector(mouseX, mouseY));

    // hash the particle positions for optimized neighbor search
    particles.parallelStream().forEach(Particle::hash);
    particles = mergeSort(
        particles,
        Comparator.comparing(Particle::getHash),
        0,
        particles.size()
    );

    // particle precalculations
    particles.parallelStream().forEach(particle->{
        particle.neighborSearch();
        particle.calculateDensity();
        particle.calculatePressure();
    });

    // move the particles
    particles.parallelStream().forEach(Particle::move);

    // draw inside a normal for loop because processing doesn't like it when you
    // try to draw things in parallel
    for (Particle particle : particles) {
        // particle.move();
        particle.draw();
    }
    // fill(0, 255, 0);
    // for (Particle particle : testParticle.neighbors) {
    //     circle(particle.pos.x - frameX, particle.pos.y - frameY, 1);
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

    popMatrix();

    if (fpsCounter) {
        // fps counter
        textAlign(RIGHT, TOP);
        textSize(24);
        fill(255);
        text("Fps: " + frameRate, width - 10, 10);
    }
}

void getFramePos() {
    // Get position of frame in window
    PSurfaceAWT.SmoothCanvas sc =
        (PSurfaceAWT.SmoothCanvas) surface.getNative();
    Frame frame = sc.getFrame();
    lastFrameX = frameX;
    lastFrameY = frameY;
    frameX = frame.getX() / zoom;
    frameY = frame.getY() / zoom;
}
