import Foundation

class View {
    static func display(output : String, lineBreak : Bool = true) {
        print (output, terminator : lineBreak ? "\n" : "")
    }

    static func getUserInput() -> String {
        return readLine()!.trimmingCharacters(in: .whitespaces)
    }

    private init() {}
}
