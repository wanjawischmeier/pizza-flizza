import SwiftUI
import Foundation
import shared

struct ContentView: View {
    let greet = "\(Greeting().greet())\n\(Database().signedIn())\n\(Database().generateTimeBasedId(length: 6))\n\(Time.companion.getMilis())"
    
	var body: some View {
		Text(greet)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
