//
//  ShieldConfigurationExtension.swift
//  LockedShield
//
//  Created by Brandon Scott on 2025-06-12.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60, weight: .regular))?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "Locked", color: .white),
            subtitle: ShieldConfiguration.Label(text: "\(application.localizedDisplayName ?? "This App") Is Locked", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 60, weight: .regular))?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "Locked", color: .white),
            subtitle: ShieldConfiguration.Label(text: "\(webDomain.domain ?? "This Site") Is Locked", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
