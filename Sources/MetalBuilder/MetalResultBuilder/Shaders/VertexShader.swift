
import SwiftUI

public struct VertexShader: InternalShaderProtocol{
    
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] = []
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] = []
    var texsAndArgs: [(Texture, MetalTextureArgument)] = []
    
    var uniformsAndNames: [(UniformsContainer, String?)] = []
    
    public init(_ name: String, source: String=""){
        self.vertexFunc = name
        self.source = source
        self.vertexOut = getVertexOutTypeFromVertexSource(source)
    }
    
    public init(_ name: String, vertexOut: String="float4",
                body: String=""){
        self.vertexFunc = name
        self.vertexOut = vertexOut
        self.body = body
    }
    
    let vertexFunc: String
    var vertexOut: String?
    var vertexOutDeclaration: String?
    
    public var body: String?
    public var source: String?
    
    func librarySource(vertexOut: String?) -> String{
        if let source = source{
            return source
        }
        if let body = body, let vertexOut = vertexOut,
           let vertexOutDeclaration = vertexOutDeclaration{
            return vertexOutDeclaration+"vertex "+vertexOut+" "+vertexFunc+"(uint vertex_id [[vertex_id]]){"+body+"}"
        }
        print("Couldn't get the source code for ", vertexFunc, " vertex shader!")
        return ""
    }
    func getVertexOutTypeFromVertexSource(_ source: String) ->String?{
        let structRange = source.range(of: "struct ")
        guard let startIndex = structRange?.upperBound
        else{ return nil }
        guard let endIndex = source[startIndex...].firstIndex(of: "{")
        else { return nil }
        
        return ""+source[startIndex...source.index(before: endIndex)]
    }
}

//Modifiers specific to VertexShader
extension VertexShader{
    func vertexOut(_ type: String, properties: String)->VertexShader{
        var v = self
        v.vertexOut = type
        v.vertexOutDeclaration = "struct "+"vertexOut{"+properties+"};"
        return v
    }
}
