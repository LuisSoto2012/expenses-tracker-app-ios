//
//  AccountRow.swift
//  ExpensesTracker
//
//  Created by Luis Angel Soto Flores on 31/01/25.
//

import SwiftUI

struct AccountRow: View {
    let account: Account
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack {
                Text(account.name)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}
