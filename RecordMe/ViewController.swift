//
//  ViewController.swift
//  RecordMe
//
//  Created by Michael Gornik on 2021-01-07.
//

import UIKit
import AVFoundation

/**
 Gets last item in the array
 */
extension Array {
    var last: Any{
        return self[self.endIndex - 1]
    }
}

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {
    var recordSession: AVAudioSession!
    var audioRec:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var recordCounter:Int = 0
    var recordedCellArry = [Int]()
    
    
    
    @IBOutlet var recordBtn: UIButton!
    
    @IBOutlet var recordTBview: UITableView!
    
    @IBOutlet var pauseBtn: UIButton!
    
    @IBOutlet var editBtn: UIBarButtonItem!
    
    
    /**
     Return number of cells
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        recordedCellArry.count - 1
    }
    
    /**
     Reuse cell if needded
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        
        cell.textLabel?.text = String(indexPath.row + 1)
        return cell
    }
    
    /**
     Make sure the given row can be moved to another location
     */
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /**
     Allows reordering of cells
     */
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = recordedCellArry[sourceIndexPath.row]
        recordedCellArry.remove(at: sourceIndexPath.row)
        recordedCellArry.insert(item, at: destinationIndexPath.row)
        
    }
    
    /**
     Changing button title based on if user is in editing mode.
     */
    @IBAction func editBtnClicked(_ sender: Any) {
        recordTBview.isEditing = !recordTBview.isEditing
        
        switch recordTBview.isEditing {
        case true:
            editBtn.title = "done"
        case false:
            editBtn.title = "edit"
        }
    }
    
    /**
     Delete cells and thier stored voice recordings
     */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        _ = FileManager.default
        let docDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let filePath = docDir.appendingPathComponent("\(indexPath.row + 1).m4a")
        if editingStyle == UITableViewCell.EditingStyle.delete
        {
            
            let path = getDir().appendingPathComponent("\(indexPath.row + 1).m4a")
            print(path)
            
            do{
                recordedCellArry.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                recordCounter -= 1
                
                try FileManager.default.removeItem(at: filePath)
                        print("\(indexPath.row + 1).m4a deleted")
                recordTBview.reloadData()
                        
                
            }catch{
                
            }
            
            recordTBview.reloadData()
        }
    }
    
    /**
     Play voice recrding when user clicks on it.
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = getDir().appendingPathComponent("\(indexPath.row + 1).m4a")
        print(path)
        
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }catch{
            
        }
    }
    
    /**
     Entry point of the program
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        //setup session for recording
        recordSession = AVAudioSession.sharedInstance()
     
        
       
        //check if we have the last number in user defaults
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission {
                print("Gained Access to record")
            }else{
                print("Access denied")
            }
        }
        
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).count - 1
            
            UserDefaults.standard.setValue(fileURLs, forKey: "number")
            print("\(fileURLs) filesss")
            
            for i in 0...fileURLs{
                recordedCellArry.insert(fileURLs, at: i)
            }
            
            if let number: Int = UserDefaults.standard.object(forKey: "number") as? Int
            {
                recordCounter = number
            }
            // process filesr
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    /**
     When user press record button thier voice will be recorded and stored in memory.
     */
    @IBAction func startRecording(_ sender: UIButton) {
        //check if there is an ongoing audio recoding
        if audioRec == nil{
            recordCounter += 1 //add to record counter
            
            
            //give the recording a name and path
            let fileName = getDir().appendingPathComponent("\(recordCounter).m4a")
            recordTBview.reloadData()
            
            //define settings define the format, sample rare, number of channels and the quality
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            //start recording
            do{
                audioRec = try AVAudioRecorder(url: fileName, settings: settings)
                audioRec.delegate = self
                audioRec.record()
                
                recordBtn.setImage(UIImage(named: "stop-record"), for: .normal)
            }catch{
                displayAlert(title: "Error!", message: "Recording failed")
            }
            
            
        }else{
            //if we get here meaning we are in the middle of a session
            audioRec.stop()
            audioRec = nil
            
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).count - 1
                print("\(fileURLs) filesss")
                
                UserDefaults.standard.setValue(fileURLs, forKey: "number")
                
                    //insert last record at the end of the array
                    recordedCellArry.insert(fileURLs, at: recordedCellArry.last!)
                
                // process filesr
            } catch {
                print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            }
            //refresh tableView after stopped recording
            recordBtn.setImage(UIImage(named: "record-button"), for: .normal)
            recordTBview.reloadData()
            
        }
    }
    
    /**
     Pause button functionality
     When clicking on pause button, voice recording will be pasued.
     Voice recording will be resumed when user clicks on pause button again.
     */
    @IBAction func pauseRecording(_ sender: Any) {
        
  
            if let currentPauseButtonImage = pauseBtn.image(for: .normal),
                let pauseButtonAppuyerImage = UIImage(named: "record-button"),
                currentPauseButtonImage.pngData() == pauseButtonAppuyerImage.pngData()
            {
                audioRec.record()
                pauseBtn.setImage(UIImage(named: "pause-record"), for: .normal)
            } else {
                
                if let currentButtonImage = recordBtn.image(for: .normal),
                    let buttonAppuyerImage = UIImage(named: "stop-record"),
                    currentButtonImage.pngData() == buttonAppuyerImage.pngData()
                {
                    audioRec.pause()
                    pauseBtn.setImage(UIImage(named: "record-button"), for: .normal)
                } else {
                    displayAlert(title: "ERROR", message: "Cannot pause recording if recording didnt start.")
                    
                }
                
            }
    }
    
    /**
     Path to the recordings directory
     */
    func getDir() -> URL
    {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir = path[0]
        print(path)
        print(documentDir)
        return documentDir
        
       
        
    }
    
    /**
     Alert.
     Will be displayed when there is an error.
     */
    func displayAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
   

}

