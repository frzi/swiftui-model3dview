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
/// TODO: Error handling.
final class AsyncResourcesCache<K: Hashable, T: AnyObject> {
	private var table: [K : WeakFutureValue] = [:]

	/// Returns a publisher for the resource associated with `identifier`.
	func resource(for key: K, action: @escaping (K, Future<T, Error>.Promise) -> Void) -> AnyPublisher<T, Error> {
		// Find already loaded resource - or a publisher in the process of loading...
		if let container = table[key] {
			if let value = container.value {
				return Result<T, Error>.success(value)
					.publisher
					.eraseToAnyPublisher()
			}
			else if let publisher = container.publisher {
				return publisher
			}
		}

		// ... otherwise create a new publisher.
		let future = Future<T, Error> { promise in
			DispatchQueue.global().async {
				action(key, promise)
			}
		}

		table[key] = WeakFutureValue(future)

		return future.eraseToAnyPublisher()
	}

	// MARK: - Weak Value container
	/// This object holds a weak reference to the value as well as a temporary publisher for the Future.
	private final class WeakFutureValue {
		private(set) weak var value: T?
		private(set) var publisher: AnyPublisher<T, Error>?
		private var cancellable: AnyCancellable!
		
		init(_ future: Future<T, Error>) {
			publisher = future
				.map { value in
					self.value = value
					return value
				}
				.eraseToAnyPublisher()
			
			cancellable = publisher!
				.sink { _ in } receiveValue: { _ in
					self.publisher = nil
				}
		}
	}
}
