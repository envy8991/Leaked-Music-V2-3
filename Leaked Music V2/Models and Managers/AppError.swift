// AppError.swift
import Foundation

struct AppError: Error, Identifiable, Codable { // Add ": Error" right here
    let id = UUID()
    let message: String
}
