import Foundation

let json = """
Sure, here is the trip:
```json
{
    "title": "Trip",
    "itinerary": [
        { "day": 1 }
    ]
}
```
Enjoy!
"""

let pattern = "(\\{[\\s\\S]*\\})" // greedy
let regex = try! NSRegularExpression(pattern: pattern, options: [])
if let match = regex.firstMatch(in: json, options: [], range: NSRange(location: 0, length: json.utf16.count)) {
    let range = Range(match.range, in: json)!
    print(String(json[range]))
}
