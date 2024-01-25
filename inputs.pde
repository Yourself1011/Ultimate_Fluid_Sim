enum MouseMode {
    NONE,
    ADD_FLUID,
    REMOVE_FLUID,
    ATTRACT,
    REPEL

}

void changeMouseMode(MouseMode mode, GImageToggleButton source) {

    if (source.getState() == 1) {
        mouseMode = mode;
        for (GImageToggleButton button : mouseModeButtons) {
            if (button != source) {
                button.setState(0);
            }
        }
    } else {
        mouseMode = MouseMode.NONE;
    }
}

void mouseWheel(MouseEvent e) {
    mouseRadius -= e.getCount() * 0.1;
    mouseRadius = max(mouseRadius, 0);
}