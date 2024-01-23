class Cache<T, R> {
    R lastValue;
    T lastDependency;
    Function<T, R> function;

    Cache(Function<T, R> function, T startDependency) {
        this.function = function;
        this.lastDependency = startDependency;
        this.lastValue = function.apply(startDependency);
    }

    R get(T dependency) {
        if (dependency.equals(lastDependency)) return lastValue;

        // println("a");
        lastDependency = dependency;
        lastValue = function.apply(dependency);
        return lastValue;
    }
}