
import SwiftUI

struct CollapsableTitle<T: View>: View {
    
    init(title: String, @ViewBuilder content: @escaping ()->(T)) {
        self.title = title
        self.content = content
        self.isCollapsed = UserDefaults.standard.bool(forKey: key)
    }
    
    let title: String
    @ViewBuilder var content: ()->(T)
    
    @State var isCollapsed: Bool = true
    
    func toggleCollapse(){
        withAnimation(.easeOut) {
            isCollapsed.toggle()
            UserDefaults.standard.set(isCollapsed, forKey: key)
        }
    }
    
    var key: String{
        "CollapsedState-\(title)"
    }
    
    var body: some View {
        VStack{
            Button {
                toggleCollapse()
            } label: {
                HStack{
                    TitleView(text: title)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.init(radians: isCollapsed ? .pi/2 : 0))
                }
            }.buttonStyle(.plain)
            if !isCollapsed{
                content()
            }
        }
    }
}
