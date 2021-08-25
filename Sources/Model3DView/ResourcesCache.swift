/*
 * ResourcesCache.swift
 * Created by Freek Zijlmans on 08-08-2021.
 */

import Combine
import Dispatch
import Foundation

/// Object keeping track of initialized resources.
///
/// Resources are loaded asynchronously and kept in memory as long as there's at least one reference.
final class ResourcesCache<K: Hashable, T: AnyObject> {
	private var table: [K : WeakFutureValue<T>] = [:]

	/// Returns a publisher for the resource associated with `identifier`.
	func resource(for identifier: K, action: @escaping (K) -> T) -> AnyPublisher<T, Never> {
		if let container = table[identifier],
			let value = container.value
		{
			return Just(value).eraseToAnyPublisher()
		}
		else if let container = table[identifier],
			let publisher = container.publisher
		{
			return publisher
		}
		else {
			let future = Future<T, Never> { promise in
				DispatchQueue.global().async {
					let resource = action(identifier)
					promise(.success(resource))
				}
			}

			table[identifier] = WeakFutureValue(future: future)

			return future.eraseToAnyPublisher()
		}
	}

	// MARK: - Weak Value container
	/// This object holds a weak reference to the value as well as a temporary publisher for the Future.
	private final class WeakFutureValue<Value: AnyObject> {
		private(set) weak var value: Value?
		private(set) var publisher: AnyPublisher<Value, Never>?
		private var cancellable: AnyCancellable!
		
		init(future: Future<Value, Never>) {
			publisher = future
				.map { value in
					self.value = value
					return value
				}
				.eraseToAnyPublisher()
			
			cancellable = publisher!.sink { _ in
				self.publisher = nil
			}
		}
	}
}
