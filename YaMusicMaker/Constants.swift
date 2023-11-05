//
//  Constants.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import UIKit
import RxSwift

struct Constants {
    
    static let sampleRate: Double = 44100
    
    static let baseSampleTempo: Int = 120
    static let minTempo: Int = 30
    static let maxTempo: Int = 240
}

func getMockedSampleSelectorViewModels(sampleSelectedHandler: AnyObserver<Sample>) -> [SampleSelectorViewModel] {
    let pianoIcon = UIImage(named: "piano_icon")!
    let drumsIcon = UIImage(named: "drums_icon")!
    let brassIcon = UIImage(named: "brass_icon")!
    return [
        .init(
            name: "Пианино",
            icon: pianoIcon,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "piano1.wav", ofType:nil)!
                    ),
                    icon: pianoIcon
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "piano2.wav", ofType:nil)!
                    ),
                    icon: pianoIcon
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "piano3.wav", ofType:nil)!
                    ),
                    icon: pianoIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        ),
        .init(
            name: "Барабаны",
            icon: drumsIcon,
            samples: [
                .init(
                    name: "Хэт",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
                    ),
                    icon: drumsIcon
                ),
                .init(
                    name: "Снейр",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    ),
                    icon: drumsIcon
                ),
                .init(
                    name: "Кик",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    ),
                    icon: drumsIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        ),
        .init(
            name: "Духовые",
            icon: brassIcon,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "brass1.wav", ofType:nil)!
                    ),
                    icon: brassIcon
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "brass2.wav", ofType:nil)!
                    ),
                    icon: brassIcon
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "brass3.wav", ofType:nil)!
                    ),
                    icon: brassIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        )
    ]
}
