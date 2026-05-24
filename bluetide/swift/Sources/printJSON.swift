import Darwin
import Foundation

func printJSON( withJSONObject: [String: Any] ) -> Void {
if let jsonData = try? JSONSerialization.data(withJSONObject: withJSONObject, options: .prettyPrinted),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)  // Pretty-printed JSON string
fflush(stdout)
}
}