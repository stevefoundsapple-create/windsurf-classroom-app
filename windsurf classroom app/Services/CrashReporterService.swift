import Foundation
import Sentry

enum CrashReporterService {
    static func start() {
        SentrySDK.start { options in
            options.dsn = SentryConfig.dsn
            options.enableSwizzling = false
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.tracesSampleRate = 0.0
        }
    }
}
