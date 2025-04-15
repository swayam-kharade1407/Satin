//
//  ControlViewController+Extensions.swift
//  Example
//
//  Created by Reza Ali on 8/8/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

import Foundation

extension ControlViewController {
    override public func loadView() {
        setupView()
        setupStackView()
        setupParameters()
    }

    func setupParameterGroupSubscriptions() {
        parameterGroupSubscriptions.removeAll()

        guard let parameters else { return }

        parameters.parameterAddedPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.setupParameters()
        }.store(in: &parameterGroupSubscriptions)

        parameters.parameterRemovedPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.setupParameters()
        }.store(in: &parameterGroupSubscriptions)

        parameters.clearedPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.setupParameters()
        }.store(in: &parameterGroupSubscriptions)

        parameters.loadedPublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.setupParameters()
        }.store(in: &parameterGroupSubscriptions)
    }

    func setupParameters() {
        removeAll()

        guard let parameters else { return }

        for param in parameters.params {
            if param is FloatParameter || param is IntParameter || param is DoubleParameter {
                switch param.controlType {
                    case .slider:
                        addSlider(param)
                        addSpacer()
                    case .inputfield:
                        addNumberInput(param)
                        addSpacer()
                    default:
                        break
                }
            }
            if param is Int2Parameter || param is Int3Parameter || param is Int4Parameter || param is Float2Parameter || param is Float3Parameter || param is Float4Parameter {
                if param is Float4Parameter || param is Float3Parameter, param.controlType == .colorpicker {
                    addColorPicker(param)
                    addSpacer()
                }
                else if param is Float2Parameter || param is Int2Parameter, param.controlType == .xypad {
                    addXYPad(param)
                    addSpacer()
                }
                else {
                    switch param.controlType {
                        case .inputfield:
                            addMultiNumberInput(param)
                            addSpacer()
                        case .colorpalette:
                            addColorPalette(param)
                        default:
                            break
                    }
                }
            }
            else if param is BoolParameter {
                let boolParam = param as! BoolParameter
                switch param.controlType {
                    case .toggle:
                        addToggle(boolParam)
                        addSpacer()
                    case .button:
                        addButton(boolParam)
                        addSpacer()
                    default:
                        break
                }
            }
            else if param is StringParameter {
                let stringParam = param as! StringParameter
                switch param.controlType {
                    case .dropdown:
                        addDropDown(stringParam)
                        addSpacer()
                    case .label:
                        addLabel(stringParam)
                        addSpacer()
                    case .inputfield:
                        addInput(stringParam)
                        addSpacer()
                    default:
                        break
                }
            }
        }
    }

    func addColorPicker(_ parameter: any Parameter) {
        let vc = ColorPickerViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addColorPalette(_ parameter: any Parameter) {
        var vc: ColorPaletteViewController
        if let pvc = controls.last as? ColorPaletteViewController {
            vc = pvc
        }
        else {
            vc = ColorPaletteViewController()
            addControl(vc)
            addSpacer()
        }

        vc.parameters.append(parameter)
    }

    func addNumberInput(_ parameter: any Parameter) {
        let vc = NumberInputViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addXYPad(_ parameter: any Parameter) {
        let vc = XYPadViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addSlider(_ parameter: any Parameter) {
        let vc = SliderViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addToggle(_ parameter: BoolParameter) {
        let vc = ToggleViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addButton(_ parameter: BoolParameter) {
        let vc = ButtonViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addLabel(_ parameter: StringParameter) {
        let vc = LabelViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addDropDown(_ parameter: StringParameter) {
        let vc = DropDownViewController()
        vc.parameter = parameter
        vc.options = parameter.options
        addControl(vc)
    }

    func addMultiNumberInput(_ parameter: any Parameter) {
        let vc = MultiNumberInputViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addInput(_ parameter: StringParameter) {
        let vc = StringInputViewController()
        vc.parameter = parameter
        addControl(vc)
    }

    func addDropDown(_ parameter: StringParameter, options: [String]) {
        let vc = DropDownViewController()
        vc.options = options
        vc.parameter = parameter
        addControl(vc)
    }

    func removeAll() {
        if let stack {
            for view in stack.subviews {
                view.removeFromSuperview()
            }
        }
        controls = []
    }
}
