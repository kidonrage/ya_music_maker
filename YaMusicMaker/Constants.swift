//
//  Constants.swift
//  YaMusicMaker
//
//  Created by Vlad Eliseev on 04.11.2023.
//

import UIKit
import RxSwift

func getMockedSampleSelectorViewModels(sampleSelectedHandler: AnyObserver<Sample>) -> [SampleSelectorViewModel] {
    return [
        .init(
            name: "Гитара",
            icon: UIImage(named: "guitar_icon")!,
            samples: [
                .init(
                    name: "Сэмпл 1",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "hihat.wav", ofType:nil)!
                    )
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    )
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    )
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
                    )
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    )
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    )
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
                    )
                ),
                .init(
                    name: "Сэмпл 2",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "snare.wav", ofType:nil)!
                    )
                ),
                .init(
                    name: "Сэмпл 3",
                    urlToFile: URL(
                        fileURLWithPath: Bundle.main.path(forResource: "kick.wav", ofType:nil)!
                    )
                ),
            ],
            sampleSelectedHandler: sampleSelectedHandler
        )
    ]
}
