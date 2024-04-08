//
//  DriverRunRideViewModel.swift
//  taxi_driver
//
//  Created by CodeForAny on 08/04/24.
//

import SwiftUI
import MapKit

class BStatus {
    static var bsPending = 0
    static var bsAccept = 1
    static var bsGoUser = 2
    static var bsWaitUser = 3
    static var bsStart = 4
    static var bsComplete = 5
    static var bsCancel = 6
    static var bsDriverNotFound = 7
}

class DriverRunRideViewModel: ObservableObject {
    
    static var shared = DriverRunRideViewModel()
    let rm = RoadManager()
    
    @Published var rideObj : NSDictionary = [:]
    
    @Published var pickupLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @Published var dropLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    @Published var pickUpPinIcon = "pickup_pin"
    @Published var dropPinIcon = "drop_pin"
    
    @Published var isOpen = true
    @Published var showCancel = false
    @Published var showCancelReason = false
    
    @Published var rateUser: Int = 4
    @Published var showToll = false
    @Published var txtToll = ""
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    @Published var showRunningRide = false
    
    
    @Published var rideStatusName = ""
    @Published var rideStatusText = ""
    @Published var rideStatusColor = Color.blue
    @Published var displayAddress = ""
    @Published var displayAddressIcon = ""
    @Published var estDuration = 0.0
    @Published var estDistance = 0.0
    @Published var btnName = ""
    
    init() {
        apiHome()
    }
    
    //MARK: Action
    func actionStatusChange(){
            
        let rideStatusId = rideObj.value(forKey: "booking_status") as? Int ?? 0
        
        if(rideStatusId == BStatus.bsGoUser) {
            apiDriverWaituser(parameter: ["booking_id": self.rideObj.value(forKey: "booking_id") ?? "" ])
        }else{
            
        }
        
    }
    
    //MARK: ApiCalling
    func apiHome() {
            
        ServiceCall.post(parameter: [:], path: Globs.svHome, isTokenApi: true) { responseObj in
            if let responseObj = responseObj {
                if responseObj.value(forKey: KKey.status) as? String ?? "" == "1" {
                        
                    let payloadObj = responseObj.value(forKey: KKey.payload) as? NSDictionary ?? [:]
                    
                    self.setRideData(obj: payloadObj.value(forKey: "running") as? NSDictionary ?? [:] )
                   
                }
            }
        } failure: { error in
            self.errorMessage = error?.localizedDescription ?? MSG.fail
            self.showError = true
        }
    }
    
    func apiDriverWaituser(parameter: NSDictionary) {
            
        ServiceCall.post(parameter: parameter, path: Globs.svDriverWaitUser, isTokenApi: true) { responseObj in
            if let responseObj = responseObj {
                if responseObj.value(forKey: KKey.status) as? String ?? "" == "1" {
                    let payloadObj = responseObj.value(forKey: KKey.payload) as? NSDictionary ?? [:]
                    self.setRideData(obj: payloadObj)
                    
                    self.errorMessage = responseObj.value(forKey: KKey.message) as? String ?? MSG.success
                    self.showError = true
                }else{
                    self.errorMessage = responseObj.value(forKey: KKey.message) as? String ?? MSG.fail
                    self.showError = true
                }
            }
        } failure: { error in
            self.errorMessage = error?.localizedDescription ?? MSG.fail
            self.showError = true
        }
    }
    
    func setRideData(obj: NSDictionary) {
        self.rideObj = obj
        if(self.rideObj.count > 0) {
            
            self.rideStatusName = statusName()
            self.rideStatusText = statusText()
            self.rideStatusColor  = statusColor()
            
            self.loadRideRoadData()
            if(!self.showRunningRide) {
                self.showRunningRide = true
            }
        }
    }
    
    func loadRideRoadData(){
        let rideStatusId = rideObj.value(forKey: "booking_status") as? Int ?? 0
            
        if (rideStatusId == BStatus.bsGoUser || rideStatusId == BStatus.bsWaitUser) {
            btnName = rideStatusId == BStatus.bsGoUser ? "ARRIVED" : "START"
            
            displayAddress = rideObj.value(forKey: "pickup_address") as? String ?? ""
            displayAddressIcon = "pickup_pin_1"
            pickUpPinIcon = "target"
            dropPinIcon = "pickup_pin"
            
            pickupLocation = CLLocationCoordinate2D(latitude: LocationManagerViewModel.shared.location.coordinate.latitude , longitude:  LocationManagerViewModel.shared.location.coordinate.longitude)
            
            dropLocation = CLLocationCoordinate2D(latitude: Double( rideObj.value(forKey: "pickup_lat") as? String ?? "0.0" ) ?? 0.0 , longitude: Double( rideObj.value(forKey: "pickup_long") as? String ?? "0.0" ) ?? 0.0)
            
            rm.getRoad(wayPoints: [ "\(self.pickupLocation.longitude),\(self.pickupLocation.latitude)", "\(dropLocation.longitude),\(dropLocation.latitude)"  ], typeRoad: .bike) { roadData in
                
                    
                DispatchQueue.main.async {
                    
                    if let roadData = roadData {
                        self.estDistance = roadData.distance // in Km
                        self.estDuration = roadData.duration / 60.0 // in min
                    
                    }
                    
                }
                
            }
        }else{
            btnName = "COMPLETE"
            
            displayAddress = rideObj.value(forKey: "drop_address") as? String ?? ""
            displayAddressIcon = "drop_pin_1"
            pickUpPinIcon = "target"
            dropPinIcon = "drop_pin"
            
            pickupLocation = CLLocationCoordinate2D(latitude: LocationManagerViewModel.shared.location.coordinate.latitude , longitude:  LocationManagerViewModel.shared.location.coordinate.longitude)
            
            dropLocation = CLLocationCoordinate2D(latitude: Double( rideObj.value(forKey: "drop_lat") as? String ?? "0.0" ) ?? 0.0 , longitude: Double( rideObj.value(forKey: "drop_long") as? String ?? "0.0" ) ?? 0.0)
            
            rm.getRoad(wayPoints: [ "\(self.pickupLocation.longitude),\(self.pickupLocation.latitude)", "\(dropLocation.longitude),\(dropLocation.latitude)"  ], typeRoad: .bike) { roadData in
                
                    
                DispatchQueue.main.async {
                    
                    if let roadData = roadData {
                        self.estDistance = roadData.distance // in Km
                        self.estDuration = roadData.duration / 60.0 // in min
                    
                    }
                    
                }
                
            }
            
        }
        
        
    }
    
    func statusName() -> String {
            
        switch rideObj.value(forKey: "booking_status")  as? Int ?? 0 {
        case 2:
            return "Pickup Up \( rideObj.value(forKey: "name") ?? "" )"
        case 3:
            return "Waiting For \( rideObj.value(forKey: "name") ?? "" )"
        case 4:
            return "Ride Started With \( rideObj.value(forKey: "name") ?? "" )"
        case 5:
            return "Ride Complete With \( rideObj.value(forKey: "name") ?? "" )"
        case 6:
            return "Ride Cancel \( rideObj.value(forKey: "name") ?? "" )"
        default:
            return             "Finding Driver Near By"
        }
        
    }
    
    func statusText() -> String {
            
        switch rideObj.value(forKey: "booking_status")  as? Int ?? 0 {
        case 2:
            return "On Way"
        case 3:
            return "Waiting"
        case 4:
            return "Started"
        case 5:
            return "Completed"
        case 6:
            return "Cancel"
        case 7:
            return "No Drivers"
        default:
            return "Pending"
        }
        
    }
    
    func statusColor() -> Color {
            
        switch rideObj.value(forKey: "booking_status")  as? Int ?? 0 {
        case 2:
            return Color.green
        case 3:
            return Color.orange
        case 4:
            return Color.green
        case 5:
            return Color.green
        case 6:
            return Color.red
        case 7:
            return Color.red
        default:
            return Color.blue
        }
        
    }
    
}
