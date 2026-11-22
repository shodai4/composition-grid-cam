import SwiftUI
import UIKit

/// 下部の操作帯。墨色の半透明に、文字と数値だけを置く。
struct ControlPanel: View {
    @Binding var grid: GridType
    @Binding var spiral: SpiralSpec
    @Binding var preset: CanvasPreset
    @Binding var style: GridStyle
    @Binding var includeGridOnSave: Bool

    let isFrozen: Bool
    let isSaving: Bool
    let onFreeze: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            gridRow
            presetRow
            if grid == .spiral {
                spiralRow
            }
            styleRow
            actionRow
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Theme.panel)
        .overlay(alignment: .top) { Hairline() }
    }

    // MARK: 構図線の種類

    private var gridRow: some View {
        HStack(spacing: 0) {
            ForEach(GridType.allCases) { type in
                Button {
                    grid = type
                    if type != .spiral {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(type.title)
                            .font(Theme.label(12, weight: grid == type ? .medium : .regular))
                            .foregroundStyle(grid == type ? Theme.ivory : Theme.ivory.opacity(0.40))
                        Rectangle()
                            .fill(grid == type ? Theme.accent : Color.clear)
                            .frame(width: 14, height: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.longTitle)
            }
        }
    }

    // MARK: 号数

    private var presetRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(CanvasPreset.all) { item in
                        Button {
                            preset = item
                        } label: {
                            VStack(spacing: 3) {
                                Text(item.name)
                                    .font(Theme.mono(11, weight: preset == item ? .medium : .regular))
                                    .foregroundStyle(preset == item ? Theme.ivory : Theme.ivory.opacity(0.38))
                                Rectangle()
                                    .fill(preset == item ? Theme.accent : Color.clear)
                                    .frame(height: 1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .frame(height: 26)
            .onChange(of: preset) { _, newValue in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(newValue.id, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(preset.id, anchor: .center)
            }
        }
    }

    // MARK: 螺旋の向き

    private var spiralRow: some View {
        HStack(spacing: 14) {
            Text("螺旋の向き")
                .font(Theme.label(10))
                .foregroundStyle(Theme.ivory.opacity(0.45))

            HStack(spacing: 10) {
                Button {
                    spiral.turnBack()
                } label: {
                    Text("←")
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.ivory.opacity(0.75))
                        .frame(width: 22, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(spiral.quarterText)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.ivory)
                    .frame(minWidth: 38)

                Button {
                    spiral.turn()
                } label: {
                    Text("→")
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.ivory.opacity(0.75))
                        .frame(width: 22, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)

            Button {
                spiral.mirrored.toggle()
            } label: {
                Text("反転")
                    .font(Theme.label(10, weight: spiral.mirrored ? .medium : .regular))
                    .foregroundStyle(spiral.mirrored ? Theme.accent : Theme.ivory.opacity(0.45))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule()
                            .stroke(spiral.mirrored ? Theme.accent : Theme.ivory.opacity(0.20),
                                    lineWidth: 0.8)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 24)
    }

    // MARK: 線の見た目

    private var styleRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 11) {
                ForEach(LineColor.allCases) { item in
                    Button {
                        style.color = item
                    } label: {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.color)
                            .frame(width: 14, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3.5)
                                    .stroke(Theme.ivory.opacity(style.color == item ? 0.85 : 0),
                                            lineWidth: 1)
                                    .padding(-3)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.title)
                }
            }

            Spacer(minLength: 10)

            HStack(spacing: 9) {
                ForEach(LineWeight.allCases) { item in
                    Button {
                        style.weight = item
                    } label: {
                        Text(item.title)
                            .font(Theme.mono(10, weight: style.weight == item ? .medium : .regular))
                            .foregroundStyle(style.weight == item ? Theme.ivory : Theme.ivory.opacity(0.35))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("線の太さ \(item.title)")
                }
            }

            Spacer(minLength: 10)

            HStack(spacing: 9) {
                ForEach(LineOpacity.allCases) { item in
                    Button {
                        style.opacity = item
                    } label: {
                        Text(item.title)
                            .font(Theme.mono(10, weight: style.opacity == item ? .medium : .regular))
                            .foregroundStyle(style.opacity == item ? Theme.ivory : Theme.ivory.opacity(0.35))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("線の濃さ \(item.title)")
                }
            }
        }
        .frame(height: 22)
    }

    // MARK: 停止と保存

    private var actionRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                Text("線")
                    .font(Theme.label(10))
                    .foregroundStyle(Theme.ivory.opacity(0.40))
                saveChoice("あり", selected: includeGridOnSave)
                saveChoice("なし", selected: !includeGridOnSave)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onFreeze) {
                ZStack {
                    Circle()
                        .stroke(Theme.ivory.opacity(0.85), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                    if isFrozen {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent)
                            .frame(width: 20, height: 20)
                    } else {
                        Circle()
                            .fill(Theme.ivory.opacity(0.90))
                            .frame(width: 40, height: 40)
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFrozen ? "映像を再開" : "映像を止める")

            Button(action: onSave) {
                Text(isSaving ? "保存中" : "保存")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ivory)
                    .frame(minWidth: 48)
                    .padding(.vertical, 9)
                    .overlay(
                        Capsule()
                            .stroke(Theme.ivory.opacity(isSaving ? 0.15 : 0.35), lineWidth: 0.8)
                    )
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func saveChoice(_ title: String, selected: Bool) -> some View {
        Button {
            includeGridOnSave = (title == "あり")
        } label: {
            Text(title)
                .font(Theme.label(10, weight: selected ? .medium : .regular))
                .foregroundStyle(selected ? Theme.ivory : Theme.ivory.opacity(0.35))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
