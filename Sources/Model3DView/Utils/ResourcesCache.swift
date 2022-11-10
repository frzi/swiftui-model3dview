/*
 * ResourcesCache.swift
 * Created by Freek (github.com/frzi) on 08-08-2021.
 */

import Combine
import Dispatch
import Foundation

/// Object keeping track of initialized resources.
///
/// Resources are loaded via a given action and kept in memory as long as there's at least one reference.
final class ResourcesCache<K: Hashable, T: AnyObject> {
	private var table: [K : WeakValue] = [:]
	
	func resource(for key: K, action: (K) -> T?) -> T? {
		if let container = table[key],
		   let value = container.value
		{
			return value
		}
		if let value = action(key) {
			table[key] = WeakValue(value: value)
			return value
		}
		return nil
	}

	// MARK: - Weak Value container
	/// Simple container for a weak value.
	private final class WeakValue {
		private(set) weak var value: T?
		
		init(value: T) {
			self.value = value
		}
	}
}

// MARK: -
/// Object keeping track of initialized resources.
///
/// Resources are loaded asynchronously and kept in memory as long as there's at least one reference.
final class AsyncResourcesCache<K: Hashable, T: AnyObject> {
	private var table: [K : WeakFutureValue] = [:]

	/// Returns a publisher for the resource associated with `identifier`.
	/// `action` runs on a different thread.
	func resource(for key: K, action: @escaping (K, Future<T, Error>.Promise) -> Void) -> any Publisher<T, Error> {
		// Find already loaded resource. Or a publisher in the process of loading...
		if let container = table[key] {
			if let value = container.value {
				return Result<T, Error>
					.success(value)
					.publisher
			}
			else if let publisher = container.publisher {
				return publisher
			}
		}

		// ... otherwise create a new publisher.
		let future = Future<T, Error> { promise in
			action(key, promise)
		}

		table[key] = WeakFutureValue(future)

		return future
	}

	// MARK: - Weak Future Value container
	/// This object holds a weak reference to the value as well as a temporary publisher for the Future.
	private final class WeakFutureValue {
		private(set) weak var value: T?
		private(set) var publisher: (any Publisher<T, Error>)?
		private var cancellable: (any Cancellable)!

		init(_ future: Future<T, Error>) {
			publisher = future
				.map { value in
					self.value = value
					return value
				}

			cancellable = publisher!
				.sink(
					receiveCompletion: { _ in self.publisher = nil },
					receiveValue: { _ in self.publisher = nil }
				)
		}
	}
}
