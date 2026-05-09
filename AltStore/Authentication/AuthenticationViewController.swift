//
//  AuthenticationViewController.swift
//  AltStore
//
//  Created by Riley Testut on 9/5/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

import AltSign

final class AuthenticationViewController: UIViewController
{
    var authenticationHandler: ((String, String, @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void) -> Void)?
    var completionHandler: (((ALTAccount, ALTAppleAPISession, String)?) -> Void)?
    
    private weak var toastView: ToastView?
    
    @IBOutlet private var appleIDTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var signInButton: UIButton!
    
    @IBOutlet private var appleIDBackgroundView: UIView!
    @IBOutlet private var passwordBackgroundView: UIView!
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var contentStackView: UIStackView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // fetch anisette servers asap when loading Auth Screen (if list is empty
        if(UserDefaults.standard.menuAnisetteServersList.isEmpty){
            Task{
                let sourceURL = UserDefaults.standard.menuAnisetteList
                do{
                    _ = try await AnisetteViewModel.getListOfServers(serverSource: sourceURL)
                    print("AuthenticationViewController: Server list refresh request completed for sourceURL: \(sourceURL)")
                }catch{
                    print("AuthenticationViewController: Server list refresh request Failed for sourceURL: \(sourceURL) Error: \(error)")
                }
            }
        }
        
        self.signInButton.activityIndicatorView.style = .medium
        self.signInButton.activityIndicatorView.color = .white
        
        for view in [self.appleIDBackgroundView!, self.passwordBackgroundView!, self.signInButton!]
        {
            view.clipsToBounds = true
            view.layer.cornerRadius = 16
        }

        self.applyFluxAuthenticationChrome()

        if UIScreen.main.isExtraCompactHeight
        {
            self.contentStackView.spacing = 20
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.textFieldDidChangeText(_:)), name: UITextField.textDidChangeNotification, object: self.appleIDTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.textFieldDidChangeText(_:)), name: UITextField.textDidChangeNotification, object: self.passwordTextField)
        
        self.update()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.styleNavigationBarForFlux()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        self.signInButton.isIndicatingActivity = false
        self.toastView?.dismiss()
    }
}

private extension AuthenticationViewController
{
    func styleNavigationBarForFlux()
    {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .altBackground
        appearance.shadowColor = UIColor.fluxCardBorder
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        self.navigationController?.navigationBar.tintColor = .altPrimary
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
    }

    func applyFluxAuthenticationChrome()
    {
        self.view.backgroundColor = .altBackground
        self.scrollView.backgroundColor = .altBackground
        self.scrollView.indicatorStyle = .default

        self.appleIDBackgroundView?.backgroundColor = .fluxCardBackground
        self.appleIDBackgroundView?.layer.borderWidth = 1
        self.appleIDBackgroundView?.layer.borderColor = UIColor.fluxCardBorder.cgColor

        self.passwordBackgroundView?.backgroundColor = .fluxCardBackground
        self.passwordBackgroundView?.layer.borderWidth = 1
        self.passwordBackgroundView?.layer.borderColor = UIColor.fluxCardBorder.cgColor

        self.appleIDTextField?.textColor = .label
        self.appleIDTextField?.tintColor = .altPrimary
        self.appleIDTextField?.keyboardAppearance = .default
        if let ph = self.appleIDTextField?.placeholder
        {
            self.appleIDTextField?.attributedPlaceholder = NSAttributedString(
                string: ph,
                attributes: [.foregroundColor: UIColor.fluxSecondaryText]
            )
        }

        self.passwordTextField?.textColor = .label
        self.passwordTextField?.tintColor = .altPrimary
        self.passwordTextField?.keyboardAppearance = .default
        if let ph = self.passwordTextField?.placeholder
        {
            self.passwordTextField?.attributedPlaceholder = NSAttributedString(
                string: ph,
                attributes: [.foregroundColor: UIColor.fluxSecondaryText]
            )
        }

        self.signInButton?.backgroundColor = .altPrimary
        self.signInButton?.setTitleColor(.white, for: .normal)
        self.signInButton?.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .disabled)
        self.signInButton.activityIndicatorView.color = .white

        self.applyFluxLabels(inSubtreeOf: self.scrollView)
    }

    func applyFluxLabels(inSubtreeOf root: UIView)
    {
        for subview in root.subviews
        {
            if let label = subview as? UILabel
            {
                if label.font.pointSize >= 28
                {
                    label.textColor = .label
                }
                else if label.font.fontDescriptor.symbolicTraits.contains(.traitBold), label.font.pointSize >= 17
                {
                    label.textColor = .label
                }
                else
                {
                    label.textColor = .fluxSecondaryText
                }
            }
            else
            {
                self.applyFluxLabels(inSubtreeOf: subview)
            }
        }
    }

    func update()
    {
        if let _ = self.validate()
        {
            self.signInButton.isEnabled = true
            self.signInButton.alpha = 1.0
        }
        else
        {
            self.signInButton.isEnabled = false
            self.signInButton.alpha = 0.6
        }
    }
    
    func validate() -> (String, String)?
    {
        guard
            let emailAddress = self.appleIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !emailAddress.isEmpty,
            let password = self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty
        else { return nil }
        
        return (emailAddress, password)
    }
}

private extension AuthenticationViewController
{
    @IBAction func authenticate()
    {
        guard let (emailAddress, password) = self.validate() else { return }
        
        self.appleIDTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        self.signInButton.isIndicatingActivity = true
        
        self.authenticationHandler?(emailAddress, password) { (result) in
            switch result
            {
            case .failure(ALTAppleAPIError.requiresTwoFactorAuthentication):
                // Ignore
                DispatchQueue.main.async {
                    self.signInButton.isIndicatingActivity = false
                }
                
            case .failure(let error as NSError):
                DispatchQueue.main.async {
                    let error = error.withLocalizedTitle(NSLocalizedString("Failed to Log In", comment: ""))
                    let toastView = ToastView(error: error)
                    toastView.show(in: self)
                    toastView.backgroundColor = .white
                    toastView.textLabel.textColor = .altPrimary
                    toastView.detailTextLabel.textColor = .altPrimary
                    self.toastView = toastView
                    
                    self.signInButton.isIndicatingActivity = false
                }
                
            case .success((let account, let session)):
                self.completionHandler?((account, session, password))
            }
            
            DispatchQueue.main.async {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: -self.view.safeAreaInsets.top), animated: true)
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem)
    {
        self.completionHandler?(nil)
    }
}

extension AuthenticationViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch textField
        {
        case self.appleIDTextField: self.passwordTextField.becomeFirstResponder()
        case self.passwordTextField: self.authenticate()
        default: break
        }
        
        self.update()
        
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        guard UIScreen.main.isExtraCompactHeight else { return }
        
        // Position all the controls within visible frame.
        var contentOffset = self.scrollView.contentOffset
        contentOffset.y = 44
        self.scrollView.setContentOffset(contentOffset, animated: true)
    }
}

extension AuthenticationViewController
{
    @objc func textFieldDidChangeText(_ notification: Notification)
    {
        self.update()
    }
}
