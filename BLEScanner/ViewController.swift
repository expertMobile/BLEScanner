//
//  ViewController.swift
//  BLEScanner
//
//  Created by iOS on 28/05/15.
//  Copyright (c) 2015 iOS. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var valueLabel: UILabel!
    
    let SERVICE_UUID : NSString = "FFFO"
    let CHARACTERISTIC_UUID : NSString = "FFF3"
    
    var centralManager : CBCentralManager!
    var discoveredPeripheral : CBPeripheral!
    var bluetoothOn : Bool!
    
    func verboseMode() -> Bool{
        return (self.segmentControl.selectedSegmentIndex != 0)
    }
    
    func tLog(msg : NSString){
        self.outputTextView.text = "\r\n\r\n".stringByAppendingString(self.outputTextView.text)
        self.outputTextView.text = msg.stringByAppendingString(self.outputTextView.text)
    }
    
    @IBAction func startBtnClicked(sender: AnyObject) {
        if (!self.bluetoothOn){
            self.tLog("Bluetooth is OFF")
            return
        }
        
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tLog("Bluetooth LE Device Scanner\r\n\r\nProgramming the Internet of Things for iOS")
        self.bluetoothOn = false
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        let localData = advertisementData as NSDictionary
        var localName : NSString!
        
        if (localData.objectForKey(CBAdvertisementDataLocalNameKey) == nil)
        {
            localName = ""
        }
        else{
            localName = localData.objectForKey(CBAdvertisementDataLocalNameKey) as NSString
        }
        
        self.tLog(NSString(format: "Discovered %@, RSSI: %@\n", localName, RSSI))
        self.discoveredPeripheral = peripheral
        
        if (self.verboseMode())
        {
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        self.tLog("Failed to connect")
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if (error != nil){
            self.tLog(error.description)
            return
        }
        
        for service in peripheral.services {
            self.tLog(NSString(format: "Discovered service: %@", service.description))
            peripheral.discoverCharacteristics(nil, forService: service as! CBService)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (error != nil){
            self.tLog(error.description)
            return
        }
        
        /************************************************************************************************/
        for characteristic in service.characteristics{
            self.tLog(NSString(format: "Characteristic found: %@", characteristic.description))
            
            if (characteristic.UUIDString == CHARACTERISTIC_UUID){
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
            }
        }
        /************************************************************************************************/
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if (error != nil){
            self.tLog(error.description)
            return
        }
        
        let stringFromData = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)!
        self.tLog(NSString(format: "Characteristic updated: %@", stringFromData))
        self.valueLabel.text = stringFromData as String;
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if (central.state != CBCentralManagerState.PoweredOn)
        {
            self.tLog("Bluetooth OFF")
            self.bluetoothOn = false;
        }
        else{
            self.tLog("Bluetooth ON")
            self.bluetoothOn = true;
        }
    }

}

