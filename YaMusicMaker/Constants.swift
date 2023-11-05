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
    let guitarIcon = UIImage(named: "guitar_icon")!
    return [
        .init(
            name: "Гитара",
            icon: guitarIcon,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        ),
        .init(
            name: "Гитара",
            icon: UIImage(named: "guitar_icon")!,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        ),
        .init(
            name: "Гитара",
            icon: UIImage(named: "guitar_icon")!,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    ),
                    icon: guitarIcon
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        )
    ]
}
