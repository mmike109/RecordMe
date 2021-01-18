//
//  ViewController.swift
//  RecordMe
//
//  Created by Michael Gornik on 2021-01-07.
//

import UIKit
import AVFoundation

extension Array {
    var last: Any{
        return self[self.endIndex - 1]
    }
}

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
        
        recordedCellArry.count - 1
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
                //print("\(FileManager.default.value(forKey: "number")) files available")
                        
                
            }catch{
                
            }
            
            recordTBview.reloadData()
            //UserDefaults.standard.setValue(recordedCellArry.count, forKey: "number")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = getDir().appendingPathComponent("\(indexPath.row + 1).m4a")
        print(path)
        
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
                
                //recordBtn.setTitle("Stop recording", for: .normal)
                recordBtn.setImage(UIImage(named: "stop-record"), for: .normal)
                //recordTBview.reloadData()
            }catch{
                displayAlert(title: "Error!", message: "Recording failed")
            }
            
            
        }else{
            //if we get here meaning we are in the middle of a session
            audioRec.stop()
            audioRec = nil
            
            //UserDefaults.standard.setValue(recordCounter, forKey: "number")
            
            
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
    
    @IBAction func pauseRecording(_ sender: Any) {
        
        do
        {
            
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
        }catch
        {
            displayAlert(title: "ERROR", message: "Opps an unkown error has occured.")
        }
    }
    
    
    func getDir() -> URL
    {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDir = path[0]
        print(path)
        print(documentDir)
        return documentDir
        
       
        
    }
    
    func displayAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
   

}

