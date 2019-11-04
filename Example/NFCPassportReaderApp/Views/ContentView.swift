//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Andy Qua on 04/06/2019.
//  Copyright © 2019 Andy Qua. All rights reserved.
//

import SwiftUI
import Combine
import NFCPassportReader

// A View that just uses the UIColor systemBackground allowing
// For light.dark mode support - willo be removed once this makes its way into SwiftUI properly
struct BackgroundView : UIViewRepresentable {
    
    var color: UIColor = .systemBackground
    
    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }
    
    func updateUIView(_ view: UIView, context: Context) {
        view.backgroundColor = color
    }
}



struct ContentView : View {
    @State var passportDetails = PassportDetails()

    @State private var showingAlert = false
    @State private var showDetails = false
    @State private var alertTitle : String = ""
    @State private var alertMessage : String = ""
    @State var page = 0

    private let passportReader = PassportReader()

    var body: some View {
        ZStack {
            VStack {
                Text( "Enter passport details" )
                    .foregroundColor(Color.secondary)
                    .font(.title)
                    .padding(0)

                TextField("Passport number",
                          text: $passportDetails.passportNumber)
                    .textContentType(.name)
                    .foregroundColor(Color.primary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .trailing])
                
                TextField("Date of birth",
                          text: $passportDetails.dateOfBirth)
                    .foregroundColor(Color.primary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .trailing])
                
                TextField("Passport expiry date",
                          text: $passportDetails.expiryDate)
                    .foregroundColor(Color.primary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .trailing])

                
                Button(action: {
                    self.scanPassport()
                }) {
                    Text("Scan Passport")
                        .font(.largeTitle)
                    .foregroundColor(passportDetails.isValid ? .secondary : Color.secondary.opacity(0.25))
                    }
                    .disabled( !passportDetails.isValid )
                Picker(selection: $page, label: Text("View?")) {
                    Text("Passport").tag(0)
                    Text("Details").tag(1)
                }.pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom,20)
                
                if page == 0 && showDetails {
                    PassportView(passportDetails:$passportDetails)
                        .frame(width: UIScreen.main.bounds.width-20, height: 220)
                } else if page == 1 && showDetails {
                    DetailsView(passportDetails:$passportDetails)
                }
                Spacer()
            }
            

        }.alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message:
                    Text(alertMessage), dismissButton: .default(Text("Got it!")))
    }
     .background(BackgroundView())
    }
}

extension ContentView {
    func scanPassport( ) {
        self.showDetails = false
        let mrzKey = self.passportDetails.getMRZKey()

        // Set the masterListURL on the Passport Reader to allow auto passport verification
        let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
        passportReader.setMasterListURL( masterListURL )

        let dataGroups : [DataGroupId] = [.COM, .DG1, .DG2, .SOD]
//        let dataGroups : [DataGroupId] = [.COM, .DG1, .SOD]
        passportReader.readPassport(mrzKey: mrzKey, tags: dataGroups, completed: { (passport, error) in
            if let passport = passport {
                // All good, we got a passport

                DispatchQueue.main.async {
                    self.passportDetails.passport = passport
                    self.showDetails = true
                }

            } else {
                self.alertTitle = "Oops"
                self.alertTitle = "\(error?.localizedDescription ?? "Unknown error")"
                self.showingAlert = true
            }
        })

    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let pptData = "P<GBRTEST<<TEST<TEST<<<<<<<<<<<<<<<<<<<<<<<<1234567891GBR8001019M2106308<<<<<<<<<<<<<<04"
//        let passport = Passport( passportMRZData: pptData, image:UIImage(named: "head")!, signed: true, dataValid: true )
        let passport = NFCPassportModel()
        let pd = PassportDetails()
        pd.passport = passport
        
        
        return Group {
            ContentView(passportDetails: pd).environment( \.colorScheme, .light).environmentObject(pd)
            ContentView(passportDetails: pd).environment( \.colorScheme, .dark).environmentObject(pd)
        }
    }
}
#endif


