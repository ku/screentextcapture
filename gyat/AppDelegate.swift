//
//  AppDelegate.swift
//  gyat
//
//  Created by ku KUMAGAI Kentaro on 2019/03/23.
//  Copyright © 2019 ku KUMAGAI Kentaro. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func executeScript() {
        let bundle = Bundle.main

        guard let path = bundle.path(forResource: "main", ofType: "rb") else { return } //(forResource: "main", withExtension: "rb") else { return }

        guard let ruby = URL(string: "file:///usr/bin/ruby") else { return }

        guard let task = try? NSUserUnixTask(url: ruby) else { return }
        task.execute(withArguments: [path], completionHandler: { error in
            guard let error = error else {
                NSApp.terminate(nil)
                return
            }
            print(error.localizedDescription)
        })
/*
        // Call Ruby script
        NSTask *             task = [ [ NSTask alloc ] init ];
        NSPipe *          pipeErr = [ NSPipe pipe ];
        NSMutableString* curPath  = [ NSMutableString string ];
        NSMutableString* scrPath  = [ NSMutableString string ];

        // Set error pipe
        [ task setStandardError : pipeErr ];

        // Get path
        [ curPath setString : [ [ NSBundle mainBundle ] bundlePath ] ];
        [ curPath setString : [ curPath stringByDeletingLastPathComponent ] ];

        [ scrPath setString    : [ [ NSBundle mainBundle ] bundlePath ] ];
        [ scrPath appendString : @"/Contents/Resources/script" ];


        // Execute
        [ task setLaunchPath           : @"/usr/bin/ruby" ];
        [ task setCurrentDirectoryPath : curPath ];
        if (filename == nil){
            [ task setArguments:[NSArray arrayWithObjects:scrPath,scrPath,nil ] ];
        }else{
            [ task setArguments:[NSArray arrayWithObjects:scrPath,scrPath,filename,nil ] ];
        }
        [ task launch ];
        [ task waitUntilExit ];

        { // Read from pipe

            NSData*   dataErr = [ [ pipeErr fileHandleForReading ] availableData ];
            NSString* strErr  = [ NSString stringWithFormat : @"%s", [ dataErr bytes ] ];
            NSLog( @"%@",strErr );

        }
        return( [ task terminationStatus ] );
*/

    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        executeScript()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        NSApp.terminate(nil)
    }
}

