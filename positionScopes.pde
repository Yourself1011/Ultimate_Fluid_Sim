/**
 * Converts a coordinate from global scope to window scope
 * @param  global  global scope position
 * @return  the coordinate relative to the window
 */
PVector globalToWindow(PVector global) {
    PVector result = global.copy();
    result.sub(cameraPos);
    result.sub(framePos.left, framePos.top);
    result.mult(zoom);
    return result;
}

/**
 * Converts a coordinate from window scope to global scope
 * @param  window  window scope position
 * @return  the coordinate relative to the actual screen
 */
PVector windowToGlobal(PVector window) {
    PVector result = window.copy();
    result.div(zoom);
    result.add(framePos.left, framePos.top);
    result.add(cameraPos);
    return result;
}