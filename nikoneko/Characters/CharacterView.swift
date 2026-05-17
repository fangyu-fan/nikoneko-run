import SwiftUI

protocol CharacterViewProtocol: View {
    var characterId: String { get }
    var color: Color { get }
    var speedMultiplier: Double { get }
}
