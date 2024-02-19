class FramePos {
    float left, right, top, bottom;
    float leftVel, rightVel, topVel, bottomVel;

    FramePos() {
    }

    void updateCoords(float frameX, float frameY) {
        float leftNext = frameX / zoom;
        float topNext = frameY / zoom;
        float rightNext = frameX / zoom + width / zoom;
        float bottomNext = frameY / zoom + height / zoom;

        leftVel = (left - leftNext) / t;
        topVel = (top - topNext) / t;
        rightVel = (right - rightNext) / t;
        bottomVel = (bottom - bottomNext) / t;

        left = leftNext;
        top = topNext;
        right = rightNext;
        bottom = bottomNext;
    }
}