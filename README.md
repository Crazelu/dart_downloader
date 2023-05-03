# dart_downloader

DartDownloader is a Dart library for downloading files from the internet with pause, resume and cancel features.

## Install 🚀

In the `pubspec.yaml` of your Flutter/Dart project, add the following dependency:

```yaml 
dependencies:
  dart_downloader:
    git:
        url: https://github.com/Crazelu/dart_downloader.git
```

## Import the package in your project 📥

```dart
import 'package:dart_downloader/dart_downloader.dart';
```

## How to use 🏗️

```dart
final downloader = DartDownloader();
downloader.download(url);

//Listen to pause notifier to know if this download can be paused.
//File servers that don't accept ranges don't support pausing/resuming downloads.

ValueListenableBuilder<bool>(
        valueListenable: downloader.canPauseNotifier,
        builder: (context, canPause, _) {
            //show pause icon
        },
);

//Pause download
downloader.pause();

//Resume download
downloader.resume();

//Cancel download
downloader.cancel();

//listen to download state
StreamBuilder<DownloadState>(
        stream: downloader.downloadState,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            switch(snapshot.data!){
                 case Paused():
                 //download is paused
                 break;
                 case Cancelled():
                 //download is cancelled
                 break;
                 case Completed():
                  //download is complete
                 break;
                 case Downloading():
                  //download is in progress
                 break;
                
            }
          }
        }
);

```

## Features ✨

- [x] Pause downloads
- [x] Resume downloads
- [x] Cancel downloads
- [x] Download state stream (downloading, paused, cancelled, completed)
- [x] Download progress stream (raw bytes and formatted string)
- [ ] Connectivity listener to pause downloads when internet connection is lost and resume when connection is regained.

## Contributions 🫱🏾‍🫲🏼

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an [issue](https://github.com/Crazelu/dart_downloader/issues).  
If you fixed a bug or implemented a feature, please send a [pull request](https://github.com/Crazelu/dart_downloader/pulls).