import Foundation
let text = "اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ"
let pythonPrefix = "اللَّهُ لاَ إِلَهَ إ"
print(text.range(of: pythonPrefix, options: .literal) != nil)
