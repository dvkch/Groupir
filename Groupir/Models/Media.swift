//
//  Media.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import Foundation
import Photos
import BrightFutures

struct Media {
    let asset: PHAsset
    let date: Date
    let size: UInt64

    init?(asset: PHAsset) {
        guard let date = [asset.creationDate, asset.modificationDate].compactMap({ $0 }).min() else { return nil }

        self.asset = asset
        self.date = date
        
        if let size = CacheManager.shared.fileSizes[asset.localIdentifier] {
            self.size = size
        }
        else {
            let resources = PHAssetResource.assetResources(for: asset)
            self.size = resources.compactMap { $0.value(forKey: "fileSize") as? CLong }.compactMap { UInt64($0) }.reduce(0, +)
        }
    }
/*
    func obtainExportURL(allowRetry: Bool = true) -> Future<URL, Error> {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        switch asset.mediaType {
        case .video:
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetPassthrough) { session, info in

                // TODO: find original filename
                let tempPath = docsDir.appendingPathComponent(asset.localIdentifier)

                NSURL *outputURL = [NSURL fileURLWithPath:videoPath];
                NSLog(@"Final path %@",outputURL);
                exportSession.outputFileType=AVFileTypeQuickTimeMovie;
                exportSession.outputURL=outputURL;

                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    if (exportSession.status == AVAssetExportSessionStatusFailed) {
                        NSLog(@"failed");
                    } else if(exportSession.status == AVAssetExportSessionStatusCompleted){
                        NSLog(@"completed!");
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            NSArray *activityItems = [NSArray arrayWithObjects:outputURL, nil];

                            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                            activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                                NSError *error;
                                if ([manager fileExistsAtPath:videoPath]) {
                                    BOOL success = [manager removeItemAtPath:videoPath error:&error];
                                    if (success) {
                                        NSLog(@"Successfully removed temp video!");
                                    }
                                }
                                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                            };
                            [weakSelf presentViewController:activityViewController animated:YES completion:nil];
                        });
                    }
                }];            }

        case .image:
            //
        }
    }*/
}

extension Media: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.asset == rhs.asset
    }
}

extension Media: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.date < rhs.date
    }
}
