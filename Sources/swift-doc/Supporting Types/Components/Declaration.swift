import CommonMarkBuilder
import SwiftDoc
import SwiftMarkup
import SwiftSemantics
import HypertextLiteral
import Highlighter
import Xcode

struct Declaration: Component {
    var symbol: Symbol
    var module: Module
    let baseURL: String

    init(of symbol: Symbol, in module: Module, baseURL: String) {
        self.symbol = symbol
        self.module = module
        self.baseURL = baseURL
    }

    // MARK: - Component

    var fragment: Fragment {
        Fragment {
            CodeBlock("swift") {
                symbol.declaration.map { $0.text }.joined()
            }
        }
    }

    var html: HypertextLiteral.HTML {

        var filteredDeclaration = [Token]()

        // This is a very basic, hacky way to strip extra space tokens at the start of a line.
        // It may not work for everything, but it's better than doing nothing.
        var hasYieldedTextOnLine = false
        var indentLevel = 0
        for token in symbol.declaration {
          if token.text == "(" { indentLevel += 1 }
          if token.text == ")" { indentLevel = max(indentLevel - 1, 0) }

          if token.text.allSatisfy({ $0 == " " }), !hasYieldedTextOnLine { continue }

          guard token.text != "\n" else {
            hasYieldedTextOnLine = false
            filteredDeclaration.append(token)
            continue
          }
          if !hasYieldedTextOnLine {
            filteredDeclaration.append(contentsOf: repeatElement(Token("  ", kind: Text.self), count: indentLevel))
            hasYieldedTextOnLine = true
          }
          filteredDeclaration.append(token)
        }

        let code = filteredDeclaration.map { $0.html }.joined()

        return #"""
        <div class="declaration">
        <pre class="highlight"><code>\#(unsafeUnescaped: code)</code></pre>
        </div>
        """#
    }
}
