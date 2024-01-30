enum MouseMode {
    NONE,
    ADD_FLUID,
    REMOVE_FLUID,
    ATTRACT,
    REPEL,
    SOLID

}

void changeMouseMode(MouseMode mode, GImageToggleButton source) {

    if (source.getState() == 1) {
        mouseMode = mode;
        for (GImageToggleButton button : mouseModeButtons) {
            if (button != source) {
                button.setState(0);
            }
        }

        hideAllPanels();
        switch (mode) {
            case ADD_FLUID:
                addFluidPanel.setVisible(true);
                break;
            case SOLID:
                addSolidPanel.setVisible(true);
                shapePoints.clear();
                addSolidButton.setEnabled(false);
                break;
        }
    } else {
        mouseMode = MouseMode.NONE;
        hideAllPanels();
    }
}

void hideAllPanels() {
    addFluidPanel.setVisible(false);
    addSolidPanel.setVisible(false);
}

void mouseWheel(MouseEvent e) {
    mouseRadius -= e.getCount() * 0.1;
    mouseRadius = max(mouseRadius, 0);
}

void mousePressed() {
    if (mouseMode == MouseMode.SOLID) {
        if (settingCMass) {
            shapeCMass = mouseVec.copy();
            settingCMass = false;
            addSolidButton.setEnabled(true);

        } else {
            shapePoints.add(mouseVec.copy());
        }
    }
}