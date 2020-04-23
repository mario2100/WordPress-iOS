import UIKit
import WordPressAuthenticator


protocol SignupEpilogueCellDelegate {
    func updated(value: String, forType: EpilogueCellType)
    func changed(value: String, forType: EpilogueCellType)
    func usernameSelected()
}

enum EpilogueCellType: Int {
    case displayName
    case username
    case password
}

class SignupEpilogueCell: UITableViewCell {

    // MARK: - Properties

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellField: LoginTextField!

    // Used to layout cellField when cellLabel is shown or hidden.
    @IBOutlet var cellFieldLeadingConstraintWithLabel: NSLayoutConstraint!
    @IBOutlet var cellFieldLeadingConstraintWithoutLabel: NSLayoutConstraint!

    private var cellType: EpilogueCellType?
    open var delegate: SignupEpilogueCellDelegate?

    // MARK: - UITableViewCell

    override func prepareForReuse() {
        super.prepareForReuse()

        accessoryType = .none
        cellField.textContentType = nil
        isAccessibilityElement = false
    }

    override var accessibilityLabel: String? {
        get {
            let emptyValue = NSLocalizedString("Empty", comment: "Accessibility value presented in the signup epilogue for an empty value.")
            let secureTextValue = NSLocalizedString("Secure text", comment: "Accessibility value presented in the signup epilogue for a password value.")

            let labelValue = cellLabel.text ?? emptyValue

            let fieldValue: String
            if let cellText = cellField.text, !cellText.isEmpty {
                if cellType == .password {
                    fieldValue = secureTextValue    // let's refrain from reading the password aloud
                } else {
                    fieldValue = cellText
                }
            } else {
                fieldValue = emptyValue
            }

            let value = "\(labelValue), \(fieldValue)"

            return value
        }
        set {
            super.accessibilityLabel = newValue
        }
    }

    // MARK: - Public Methods

    func configureCell(forType newCellType: EpilogueCellType,
                       labelText: String? = nil,
                       fieldValue: String? = nil,
                       fieldPlaceholder: String? = nil) {

        cellType = newCellType

        cellLabel.text = labelText
        cellLabel.textColor = .text

        cellField.text = fieldValue
        cellField.placeholder = fieldPlaceholder
        cellField.delegate = self

        configureForPassword()

        selectionStyle = .none

        configureAccessoryType(for: newCellType)
        configureTextContentTypeIfNeeded(for: newCellType)
        configureAccessibility(for: newCellType)

        addBottomBorder(withColor: .divider)
    }

    // MARK: - Private behavior

    private func configureForPassword() {
        let isPassword = (cellType == .password)
        cellLabel.isHidden = isPassword

        cellField.isSecureTextEntry = isPassword
        cellField.showSecureTextEntryToggle = isPassword
        cellField.textAlignment = isPassword ? .left : .right
        cellField.textColor = isPassword ? .text : .textSubtle

        cellFieldLeadingConstraintWithLabel.isActive = !isPassword
        cellFieldLeadingConstraintWithoutLabel.isActive = isPassword
    }

    private func configureAccessibility(for cellType: EpilogueCellType) {
        if cellType == .username {
            accessibilityTraits.insert(.button) // selection transitions to SignupUsernameViewController
            isAccessibilityElement = true       // this assures double-tap properly captures cell selection
        }

        switch cellType {
        case .displayName:
            cellField.accessibilityIdentifier = "Display Name Field"
        case .username:
            cellField.accessibilityIdentifier = "Username Field"
        case .password:
            cellField.accessibilityIdentifier = "Password Field"
        }
    }

    private func configureAccessoryType(for cellType: EpilogueCellType) {
        if cellType == .username {
            accessoryType = .disclosureIndicator
        } else {
            accessoryType = .none
        }
    }

    private func configureTextContentTypeIfNeeded(for cellType: EpilogueCellType) {
        guard #available(iOS 12, *) else {
            return
        }

        switch cellType {
        case .displayName:
            cellField.textContentType = .name
        case .username:
            cellField.textContentType = .username
        case .password:
            cellField.textContentType = .newPassword
        }
    }

}


extension SignupEpilogueCell: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let cellType = cellType, cellType == .displayName || cellType == .password {
            let updatedText = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            delegate?.changed(value: updatedText, forType: cellType)
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if let cellType = cellType,
            let updatedText = textField.text {
            delegate?.updated(value: updatedText, forType: cellType)
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let cellType = cellType,
            cellType == .username {
            delegate?.usernameSelected()
            return false
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cellField.endEditing(true)
        return true
    }
}
