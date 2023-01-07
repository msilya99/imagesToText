import Foundation

actor IsolatedArray<T> {
    var values: [T] = []

    func clear() {
        values = []
    }

    func add(_ value: T) {
        values.append(value)
    }
}
