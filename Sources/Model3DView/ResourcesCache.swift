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
	private var table: [K : AnyPublisher<T, Error>] = [:]

	func resource(for identifier: K, action: @escaping (K) -> T) -> AnyPublisher<T, Error> {
		if let publisher = table[identifier] {
			return publisher
		}
		else {
			let future = Future<T, Error> { promise in
				DispatchQueue.global().async {
					let resource = action(identifier)
					promise(.success(resource))
				}
			}
			.eraseToAnyPublisher()

			table[identifier] = future

			return future
		}
	}
}
