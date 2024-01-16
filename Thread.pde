class PressureThread extends Thread {
    Particle particle;

    PressureThread(Particle particle) {
        this.particle = particle;
    }

    void run() {
        particle.neighborSearch();
        particle.calculateDensity();
        particle.calculatePressure();
    }
}