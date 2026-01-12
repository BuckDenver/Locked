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
        // Modern gradient colors
        let gradientStart = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0) // Purple
        let gradientEnd = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)   // Blue
        
        // Use custom lock icon from the shield extension's bundle
        let icon = UIImage(named: "WhiteLockedLock", in: Bundle(for: Self.self), compatibleWith: nil)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: gradientStart.withAlphaComponent(0.95),
            icon: icon,
            title: ShieldConfiguration.Label(
                text: "Time for a Break",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "\(application.localizedDisplayName ?? "This app") is currently locked",
                color: UIColor.white.withAlphaComponent(0.85)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue.withAlphaComponent(0.3),
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Modern gradient colors
        let gradientStart = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0) // Purple
        let gradientEnd = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)   // Blue
        
        // Use custom lock icon from assets
        let icon = UIImage(named: "WhiteLockedLock")
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: gradientStart.withAlphaComponent(0.95),
            icon: icon,
            title: ShieldConfiguration.Label(
                text: "Site Blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "\(webDomain.domain ?? "This site") is currently locked",
                color: UIColor.white.withAlphaComponent(0.85)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue.withAlphaComponent(0.3),
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
