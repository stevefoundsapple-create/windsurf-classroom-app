import Foundation

extension String {
    func localized(comment: String = "") -> String {
        NSLocalizedString(self, comment: comment)
    }

    func localizedFormat(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}
