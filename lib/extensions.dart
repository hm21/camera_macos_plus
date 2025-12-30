extension IterableExt<T> on Iterable<T> {
  T? safeElementAt(int index) {
    try {
      return elementAt(index);
    } catch (e) {
      return null;
    }
  }
}
