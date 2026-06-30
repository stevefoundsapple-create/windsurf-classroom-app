import Foundation

enum UITestHarness {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    static var mockRole: UserProfile.UserRole? {
        guard isUITesting else { return nil }
        if ProcessInfo.processInfo.arguments.contains("-UITestingRole teacher") { return .teacher }
        if ProcessInfo.processInfo.arguments.contains("-UITestingRole parent") { return .parent }
        if ProcessInfo.processInfo.arguments.contains("-UITestingRole student") { return .student }
        return nil
    }

    static var mockDataState: String {
        guard isUITesting else { return "" }
        for arg in ProcessInfo.processInfo.arguments {
            if arg.hasPrefix("-UITestingDataState ") {
                return arg.replacingOccurrences(of: "-UITestingDataState ", with: "")
            }
        }
        return "populated"
    }

    static var isErrorState: Bool { mockDataState == "error" }
    static var isEmptyState: Bool { mockDataState == "empty" }
    static var isLoadingState: Bool { mockDataState == "loading" }
    static var isPopulatedState: Bool { mockDataState == "populated" }
}
