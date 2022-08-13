
import Foundation

// find function "prefix some_type name" and returns range of "("...
func findFunction(_ function: MetalFunction, in source: String) throws -> Range<Substring.Index>{
    let prefix = function.prefix
    let name = function.name
    
    // find prefix(kernel, vertex, fragment)
    var s = source[source.startIndex..<source.endIndex]
    var nameId: String.Index?
    while true{
        guard let prefixId = findPrefix(prefix, in: s)
        else {
            throw MetalBuilderParserError
            .syntaxError("no "+prefix+" "+name+" function in source!")
        }
        // find "{"
        guard let curlyId = s[prefixId...].range(of: "{")?.upperBound
        else {
            throw MetalBuilderParserError
            .syntaxError("no '{' after '"+prefix+"'!")
        }
        // find name between prefix and "{"
        guard let nameRange = s[prefixId...curlyId].range(of: name)
        else {
            guard let skipped = skipCurlies(in: s[curlyId...])
            else {
                throw MetalBuilderParserError
                .syntaxError("no closing '}' after '"+name+"'!")
            }
            s = skipped
            continue }
        nameId = nameRange.lowerBound
        break
    }
    guard let nameId = nameId
    else {
        throw MetalBuilderParserError
        .syntaxError("no "+prefix+" "+name+" function in source!")
    }
    guard let bracketRange = source[nameId...].range(of: "(")
    else {
        throw MetalBuilderParserError
        .syntaxError("expected '(' after '"+function.name+"'!")
    }
    return bracketRange
}


// takes substring starting with '{'
// return index after {...} expression
// or nil if there's no ending '}'
func skipCurlies(in s: String.SubSequence) -> String.SubSequence?{
    var curlyCount = 1
    for index in s.dropFirst().indices{
        switch s[index]{
        case "{": curlyCount += 1
        case "}": curlyCount -= 1
        default: break
        }
        if curlyCount == 0{ return s[index...].dropFirst() }
    }
    return nil
}
// takes substring starting with
// return index after (...) expression
// or nil if there's no ending ')'
func skipRounds(in s: String.SubSequence) -> String.SubSequence?{
    var roundCount = 1
    for index in s.dropFirst().indices{
        switch s[index]{
        case "(": roundCount += 1
        case ")": roundCount -= 1
        default: break
        }
        if roundCount == 0{ return s[index...].dropFirst() }
    }
    return nil
}

// find prefix (it should be outside any {...} or (...))
func findPrefix(_ prefix: String, in string: String.SubSequence) -> String.Index?{
    
    var s = string[string.startIndex..<string.endIndex]
    while true{
        guard let firstCurly = s.range(of: "{")?.lowerBound
        else { return nil }
        guard let firstRound = s.range(of: "(")?.lowerBound
        else { return nil }
        guard let prefixRange = s.range(of: prefix)
        else{ return nil }
        if firstCurly<prefixRange.upperBound{
            guard let skipped = skipCurlies(in: s[firstCurly...])
            else{ return nil }
            s = skipped
            continue
        }
        if firstRound<prefixRange.upperBound{
            guard let skipped = skipRounds(in: s[firstRound...])
            else{ return nil }
            s = skipped
            continue
        }
        return prefixRange.lowerBound
    }
}
