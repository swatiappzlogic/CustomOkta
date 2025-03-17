//
//  NetworkManagerNew.swift
//  WinkApp
//
//  Created by MacBook on 06/12/24.
//

import Alamofire

class NetworkManager{
    
    // Shared singleton instance
    static let shared = NetworkManager()
    
    // Alamofire Session for making requests
    private let session: Session
    
    // Reachability Manager to monitor internet connectivity
    private let reachabilityManager: NetworkReachabilityManager?
    
    private init() {
        // Set up the Alamofire session with timeout configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // Timeout for request
        configuration.timeoutIntervalForResource = 120 // Timeout for resources
        session = Session(configuration: configuration)
        
        // Initialize the reachability manager
        reachabilityManager = NetworkReachabilityManager()
        
        // Start monitoring network reachability
        reachabilityManager?.startListening { status in
            switch status {
            case .notReachable:
                print("No internet connection.")
            case .reachable(.ethernetOrWiFi):
                print("Internet connection available via WiFi.")
            case .reachable(.cellular):
                print("Internet connection available via Cellular.")
            case .unknown:
                print("Network status unknown.")
            }
        }
    }
    
    // MARK: - Internet Reachability Check
    // Check if the device is connected to the internet
    func isInternetAvailable() -> Bool {
        return reachabilityManager?.isReachable ?? false
    }

    // MARK: - Generic Network Request
    // Function to make a generic request (GET, POST, etc.)
    func request<T: Decodable>(url: String, method: Alamofire.HTTPMethod, parameters: [String: Any]? = nil, encoding: ParameterEncoding = JSONEncoding.default, headers: HTTPHeaders? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        // Check if internet is available
        guard isInternetAvailable() else {
            completion(.failure(.noInternet))
            return
        }

        // Log the request (optional)
        print("Requesting \(method.rawValue) to: \(url), with parameters: \(String(describing: parameters))")

        // Make the network request using Alamofire
        session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .validate(statusCode: 200..<300) // Accept only 2xx status codes
            .validate(contentType: ["application/json"]) // Ensure JSON response
            .responseDecodable(of: T.self) { response in
                // Log the response (optional)
                if let data = response.data {
                    print("Response: \(String(describing: String(data: data, encoding: .utf8)))")
                }

                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    // Handle different types of errors
                    if let statusCode = response.response?.statusCode, statusCode >= 500 {
                        completion(.failure(.serverError(statusCode)))
                    } else if let decodingError = error as? DecodingError {
                        completion(.failure(.decodingError(decodingError)))
                    } else if let afError = error.asAFError {
                        switch afError {
                        case .sessionTaskFailed(let error):
                            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                                completion(.failure(.noInternet))
                            } else {
                                completion(.failure(.unknownError(error)))
                            }
                        default:
                            completion(.failure(.unknownError(error)))
                        }
                    } else {
                        completion(.failure(.unknownError(error)))
                    }
                }
            }
    }
    
    // MARK: - GET Request
    // Function to make a GET request with optional headers
    func get<T: Decodable>(url: String, parameters: [String: Any]? = nil, headers: HTTPHeaders? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers, completion: completion)
    }

    // MARK: - POST Request
    // Function to make a POST request with optional headers
    func post<T: Decodable>(url: String, parameters: [String: Any], headers: HTTPHeaders? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        request(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, completion: completion)
    }

    // MARK: - PUT Request
    // Function to make a PUT request with optional headers
    func put<T: Decodable>(url: String, parameters: [String: Any], headers: HTTPHeaders? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        request(url: url, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers, completion: completion)
    }

    // MARK: - DELETE Request
    // Function to make a DELETE request with optional headers
    func delete<T: Decodable>(url: String, parameters: [String: Any]? = nil, headers: HTTPHeaders? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        request(url: url, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headers, completion: completion)
    }

    // MARK: - Cancel Pending Requests
    // Function to cancel a network request if necessary
    func cancelAllRequests() {
        session.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }

    // MARK: - Upload Image to Azure Blob
    func uploadImageToAzureBlobRequest(imageData: Data, url: URL, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        print("Request URL: \(url)") // Debug: print the request URL to ensure it's correct
        
        // Perform the upload with a PUT request, adding the `x-ms-blob-type` header
        session.upload(imageData, to: url, method: .put, headers: [
            "Content-Type": "image/jpeg",  // Set the Content-Type header to the appropriate MIME type
            "x-ms-blob-type": "BlockBlob"  // Add the missing x-ms-blob-type header with value "BlockBlob"
        ])
        .validate(statusCode: 200..<300)  // Validate successful status codes (200–299)
        .response { response in
            // Log the full response if available
            if let data = response.data, let message = String(data: data, encoding: .utf8) {
                print("Response: \(message)")
            }
            
            switch response.result {
            case .success:
                print("Image uploaded successfully to Azure Blob Storage.")
                completion(.success(()))  // Upload successful
            case .failure(let error):
                // Handle error based on status code
                if let statusCode = response.response?.statusCode {
                    print("Status Code: \(statusCode)")  // Debug: Print the status code
                    if statusCode >= 500 {
                        completion(.failure(.serverError(statusCode)))  // Server errors (e.g., 500 series)
                    } else {
                        completion(.failure(.unknownError(error)))  // General errors (e.g., connection issues)
                    }
                } else {
                    completion(.failure(.unknownError(error)))  // No response status code available
                }
            }
        }
    }




    // MARK: - Upload Multipart
    func uploadMultipart<T: Decodable>(
        url: String,
        headers: HTTPHeaders? = nil,
        parameters: [String: String]? = nil,
        imageData: Data,
        imageKey: String,
        fileName: String,
        mimeType: String = "image/jpeg",
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // Check if internet is available
        guard isInternetAvailable() else {
            completion(.failure(.noInternet))
            return
        }

        // Log the request (optional)
        print("Uploading to: \(url) with headers: \(String(describing: headers)) and parameters: \(String(describing: parameters))")

        session.upload(
            multipartFormData: { formData in
                // Add image data
                formData.append(imageData, withName: imageKey, fileName: fileName, mimeType: mimeType)
                
                // Add other parameters
                parameters?.forEach { key, value in
                    formData.append(Data(value.utf8), withName: key)
                }
            },
            to: url,
            method: .post,
            headers: headers
        )
        .validate()
        .responseDecodable(of: T.self) { response in
            // Log the response (optional)
            if let data = response.data {
                print("Response: \(String(describing: String(data: data, encoding: .utf8)))")
            }

            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                if let statusCode = response.response?.statusCode, statusCode >= 500 {
                    completion(.failure(.serverError(statusCode)))
                } else if let decodingError = error as? DecodingError {
                    completion(.failure(.decodingError(decodingError)))
                } else if let afError = error.asAFError {
                    switch afError {
                    case .sessionTaskFailed(let error):
                        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                            completion(.failure(.noInternet))
                        } else {
                            completion(.failure(.unknownError(error)))
                        }
                    default:
                        completion(.failure(.unknownError(error)))
                    }
                } else {
                    completion(.failure(.unknownError(error)))
                }
            }
        }
    }
}

// MARK: - NetworkError Enum
// Custom error to handle various network-related issues
enum NetworkError: Error {
    case noInternet
    case serverError(Int)
    case decodingError(DecodingError)
    case unknownError(Error)

    var localizedDescription: String {
        switch self {
        case .noInternet:
            return "Please check your internet connection and try again."
        case .serverError(let code):
            return "Server error occurred (Code: \(code))."
        case .decodingError:
            return "Failed to process server response."
        case .unknownError(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}
