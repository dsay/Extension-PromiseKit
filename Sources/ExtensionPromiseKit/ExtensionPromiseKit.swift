import PromiseKit
import Foundation

public enum PromiseKitError: LocalizedError {
    
    case notFound
}

public extension Thenable where T: Sequence {

    func sortedValues(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ areInIncreasingOrder: @escaping(T.Iterator.Element, T.Iterator.Element) -> Bool) -> Promise<[T.Iterator.Element]> {

          return map(on: on, flags: flags) {
              $0.sorted(by: areInIncreasingOrder)
          }
      }
}

public extension NotificationCenter {
    
    func observe<T>(once name: Notification.Name, object: Any? = nil) -> Promise<T> {
        return observeNotification(once: name).then { self.map(notification: $0)}
    }
        
    private func observeNotification(once name: Notification.Name, object: Any? = nil) -> Guarantee<Notification> {
        let (promise, fulfill) = Guarantee<Notification>.pending()
        let id = addObserver(forName: name, object: object, queue: nil, using: fulfill)
        promise.done { _ in self.removeObserver(id) }
        return promise
    }
    
    private func map<T>(notification: Notification) -> Promise<T> {
        return Promise { resolver in
            if let object = notification.object as? T {
                resolver.fulfill(object)
            } else {
                resolver.reject(PromiseKitError.notFound)
            }
        }
    }
}

public extension Array {
    
    var promise: Promise<[Element]> {
        Promise.value(self)
    }
    
    var ifNotEmpty: Promise<[Element]> {
        Promise { resolver in
            if self.isEmpty {
                resolver.reject(PromiseKitError.notFound)
            } else {
                resolver.fulfill(self)
            }
        }
    }
    
    var firstElement: Promise<Element> {
        Promise { resolver in
            if let value = self.first {
                resolver.fulfill(value)
            } else {
                resolver.reject(PromiseKitError.notFound)
            }
        }
    }
}

public extension Swift.Result {
    
    var promise: Promise<Success> {
        Promise { resolver in
            switch self {
            case .success(let value):
                resolver.fulfill(value)
            case .failure(let error):
                resolver.reject(error)
            }
        }
    }
}
