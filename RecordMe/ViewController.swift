//
//  ViewController.swift
//  RecordMe
//
//  Created by Michael Gornik on 2021-01-07.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {
    //next step - add pause button and maybe create prittier buttons instead.
    
    var recordSession: AVAudioSession!
    var audioRec:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var recordCounter:Int = 0
    var recordedCellArry = [Int]()
    
    @IBOutlet var recordBtn: UIButton!
    
    @IBOutlet var recordTBview: UITableView!
    
    @IBOutlet var pauseBtn: UIButton!
    
    @IBOutlet var editBtn: UIBarButtonItem!
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordedCellArry.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        
        cell.textLabel?.text = String(indexPath.row + 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = recordedCellArry[sourceIndexPath.row]
        recordedCellArry.remove(at: sourceIndexPath.row)
        recordedCellArry.insert(item, at: destinationIndexPath.row)
        
    }
    
    @IBAction func editBtnClicked(_ sender: Any) {
        recordTBview.isEditing = !recordTBview.isEditing
        
        switch recordTBview.isEditing {
        case true:
            editBtn.title = "done"
        case false:
            editBtn.title = "edit"
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete
        {
            recordedCellArry.remove(at: indexPath.row)
            recordTBview.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = getDir().appendingPathComponent("\(indexPath.row + 1).m4a")
        
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }catch{
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //setup session for recording
        recordSession = AVAudioSession.sharedInstance()
     
       
        //check if we have the last number in user defaults
        if let number: Int = UserDefaults.standard.object(forKey: "number") as? Int
        {
            recordCounter = number
        }
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission {
                print("Gained Access to record")
            }else{
                print("Access denied")
            }
        }
        
        for i in 0...recordCounter{
            recordedCellArry.insert(recordCounter, at: i)
        }
    }
    
    
    @IBAction func startRecording(_ sender: UIButton) {
        //check if there is an ongoing audio recoding
        if audioRec == nil{
            recordCounter += 1 //add to record counter
            
            recordTBview.reloadData()
            //give the recording a name and path
            let fileName = getDir().appendingPathComponent("\(recordCounter).m4a")
            
            
            //define settings define the format, sample rare, number of channels and the quality
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            //start recording
            do{
                audioRec = try AVAudioRecorder(url: fileName, settings: settings)
                audioRec.delegate = self
                audioRec.record()
                
                //recordBtn.setTitle("Stop recording", for: .normal)
                recordBtn.setImage(UIImage(named: "stop-record"), for: .normal)
            }catch{
                displayAlert(title: "Error!", message: "Recording failed")
            }
            
            
        }else{
            //if we get here meaning we are in the middle of a session
            audioRec.stop()
            audioRec = nil
            
            UserDefaults.standard.setValue(recordCounter, forKey: "number")
            //refresh tableView after stopped recording
            recordTBview.reloadData()
            recordBtn.setImage(UIImage(named: "record-button"), for: .normal)
        }
    }
    
    func getDir() -> URL
    {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir = path[0]
        
        return documentDir
        
        
    }
    
    func displayAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    

}

