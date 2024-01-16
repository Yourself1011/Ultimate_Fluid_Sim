<T> int binarySearch(ArrayList<T> list, int target, Function<T, Integer> getter, int start, int end, int rangeStart, int rangeEnd) {
    while (true) { // while loop instead of recursion because it's too much for the call stack when this is called in parallel
        if (start + 1 == end || target < rangeStart || target > rangeEnd) return -1; // could not find it

        // int split = round(float(target - rangeStart) / float(rangeEnd - rangeStart) * (end - start) + start);
        int split = (start + end) / 2;
        T item = list.get(split);
        int result = getter.apply(item);

        if (result == target) return split;
        else if (result > target) {
            // return binarySearch(list, target, getter, start, split, rangeStart, result);
            end = split;
            rangeEnd = result;
        } else {
            // return binarySearch(list, target, getter, split, end, result, rangeEnd);
            start = split;
            rangeStart = result;
        }
    }
}