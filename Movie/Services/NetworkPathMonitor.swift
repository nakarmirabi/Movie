//
//  NetworkPathMonitor.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation
import Network

final class NetworkPathMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkPathMonitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
