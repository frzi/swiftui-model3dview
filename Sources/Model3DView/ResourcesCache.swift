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
final class ResourcesCache<Resource: AnyObject> {
	typealias LoadPublisher = Future<Resource, Never>
	
	private var table: [String : LoadPublisher] = [:]
	
	func resource(identifier: URL, action: @escaping (URL) -> Resource) -> AnyPublisher<Resource, Never> {
		if let publisher = table[identifier.path] {
			return publisher.eraseToAnyPublisher()
		}

		return Future { promise in
			DispatchQueue.global().async {
				let resource = action(identifier)
				promise(.success(resource))
			}
		}
		.eraseToAnyPublisher()
	}
}
