enum MouseMode {
    NONE,
    ADD_FLUID,
    REMOVE_FLUID,
    ATTRACT,
    REPEL

}

void changeMouseMode(MouseMode mode, GImageToggleButton source) {

    mouseMode = mode;
    for (GImageToggleButton button : mouseModeButtons) {
        if (button != source) {
            button.setState(0);
        }
    }
}