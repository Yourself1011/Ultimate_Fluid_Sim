<T> ArrayList<T> mergeSort(ArrayList<T> list, Comparator<T> comparator, int start, int end) {
    if (start + 1 == end) return list;

    int mid = (start + end) / 2;
    ArrayList<T> left = mergeSort(list, comparator, start, mid);
    ArrayList<T> right = mergeSort(list, comparator, mid, end);
    ArrayList<T> result = (ArrayList<T>) list.clone();

    int i = start, j = mid;
    while (i < mid && j < end) {
        T lObj = left.get(i);
        T rObj = right.get(j);

        if (comparator.compare(lObj, rObj) < 0) {
            result.set(i + j - mid, lObj);
            i++;
        } else {
            result.set(i + j - mid, rObj);
            j++;
        }
    }

    // free ride
    for (; i < mid; i++) {
        result.set(i + j - mid, left.get(i));
    }
    for (; j < end; j++) {
        result.set(i + j - mid, right.get(j));
    }

    return result;
}