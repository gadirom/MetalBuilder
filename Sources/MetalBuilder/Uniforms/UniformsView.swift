import SwiftUI
import OrderedCollections

public struct UniformsView: View {
    
    public init(_ uniforms: UniformsContainer){
        self.uniforms = uniforms
    }
    
    @ObservedObject public var uniforms: UniformsContainer
    
    @State var values: [[Float]] = []
    @State var defaultsLoaded = false
    
    public var body: some View {
        ScrollView{
            VStack{
                HStack{
                    Button {
                        clearDefaults()
                    } label: {
                        HStack{
                            Image(systemName: "xmark.bin.fill")
                            Text("Clear Defaults")
                        }
                    }
                }
                ForEach(values.indices, id:\.self){ id in
                    let value = values[id]
                    let (name, property) = uniforms.dict.elements[id]
                    if property.show{
                        switch property.type{
                        case .float: SingleSlider(label: name,
                                                  range: property.range ?? (0...1),
                                                  initialValue: value[0]){
                            uniforms.setFloat($0, for: name)
                            saveToDefaults(value: [$0], name: name)
                        }
                        default: MultiSlider(label: name,
                                             range: property.range ?? (0...1),
                                             initialValue: value) { value in
                                saveToDefaults(value: value, name: name)
                                switch value.count{
                                case 2: uniforms.setFloat2(value, for: name)
                                case 3: uniforms.setFloat3(value, for: name)
                                case 4: uniforms.setFloat4(value, for: name)
                                default: break
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: uniforms.bufferAllocated){ _ in
            loadInitial()
            if uniforms.saveToDefaults && !defaultsLoaded{
                print("loadDef")
                loadFomDefaults()
                defaultsLoaded = true
            }
        }
    }
}
//private methods
extension UniformsView{
    func saveToDefaults(value: [Float], name: String){
        let key = keyForName(name)
        print("saved "+key, value)
        UserDefaults.standard.set(value, forKey: key)
    }
    func loadInitial(){
        values = uniforms.dict.values.map{ $0.initValue }
    }
    func loadFomDefaults(){
        for p in uniforms.dict.enumerated(){
            let key = keyForName(p.element.key)
            if let value = UserDefaults.standard.array(forKey: key){
                if let value = value as? [Float]{
                    print(key, value)
                    uniforms.setArray(value, for: p.element.key)
                    values[p.offset] = value
                }
            }
        }
    }
    func keyForName(_ name: String)->String{
        prefixForDefaults+name
    }
    func nameForKey(_ key: String)->String?{
        if let range = key.range(of: prefixForDefaults){
            return String(key[range.upperBound...])
        }else{ return nil }
    }
    var prefixForDefaults: String{
        "Uniforms-"
    }
    func clearDefaults(){
        print("clear")
        values = []
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.01) {
            loadInitial()
        }
    }
}

struct MultiSlider: View {
    let label: String
    let range: ClosedRange<Float>
    let initialValue: [Float]
    let setter: ([Float])->()
    
    @State var value: [Float] = []
    
    var body: some View {
        VStack{
            HStack{
                Text(label)
                VStack{
                    Divider()
                }
            }
            ForEach(value.indices, id:\.self){ id in
                SingleSlider(label: "\(id)",
                             range: range,
                             initialValue: initialValue[id]){
                    value[id] = $0
                }
            }
        }
        .onAppear{
            value = initialValue
        }
        .onChange(of: value) {
            setter($0)
        }
    }
}

struct SingleSlider: View {
    let label: String
    let range: ClosedRange<Float>
    let initialValue: Float
    
    let setter: (Float)->()
    
    @State var precision = 1
    @State var digits = 2
    @State var value: Float = 0
    
    var body: some View {
        HStack{
            let _ = print("refresh slider")
            Text(label+": "+String(format:"%\(digits).\(precision)f", value))
                .monospacedDigit()
                .onAppear{
                    let lg = log10(range.upperBound-range.lowerBound)
                    precision = min(4, Int(4.0/(2+lg)))
                    digits = Int(lg)+precision
                }
            Spacer()
            Slider(value: $value, in: range)
                .onChange(of: value){
                    setter($0)
                }
                .onAppear{
                    value = initialValue
                }
                .onChange(of: initialValue) { newValue in
                    print("new initial")
                    value = newValue
                }
        }
    }
}


