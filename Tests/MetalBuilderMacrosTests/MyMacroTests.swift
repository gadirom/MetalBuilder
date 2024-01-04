
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
//#if canImport(MetalBuilderMacros)
import MetalBuilderMacros

let testMacros: [String: Macro.Type] = [
    "UniformsStruct": UniformsStructMacro.self
]
//#endif

final class MyMacroTests: XCTestCase {

    func testUniformsStructMacro() {
            assertMacroExpansion(
            """
            @UniformsStruct
            struct UniformsForBlock{
                var property1 = Uniform(simd_float2([1, 0]),     range: 0...1, editable: false)
                var property2 = Uniform(simd_uint3 ([3, 2, 1]),  range: 0...10)
            }
            """,
            expandedSource:
            """
            struct UniformsForBlock{
                var property1 = Uniform(simd_float2([1, 0]),     range: 0...1, editable: false)
                var property2 = Uniform(simd_uint3 ([3, 2, 1]),  range: 0...10)
            
                init(buffer: MTLBufferContainer<UInt8>, setOffset: (Int) -> ()) {
                    var offset = 0
                    property1 = Uniform(binding: Binding<simd_float2>(get: {
                                                        buffer.getUniformValue(offset: offset)
                                                    }, set: { value in
                                                        buffer.setUniformValue(value, offset: offset)
                                                    }),
                                         range: 0 ... 1,
                                         initValue: simd_float2([1, 0]),
                                         editable: false,
                                         offset: offset)
                    offset += MemoryLayout.stride(ofValue: simd_float2([1, 0]))
                    property2 = Uniform(binding: Binding<simd_uint3 >(get: {
                                                        buffer.getUniformValue(offset: offset)
                                                    }, set: { value in
                                                        buffer.setUniformValue(value, offset: offset)
                                                    }),
                                         range: 0 ... 10,
                                         initValue: simd_uint3 ([3, 2, 1]),
                                         editable: true,
                                         offset: offset)
                    offset += MemoryLayout.stride(ofValue: simd_uint3 ([3, 2, 1]))
                    setOffset(offset)
                }
            }
            """,
                macros: testMacros
            )
        }
}

