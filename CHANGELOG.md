## 0.0.1

* Initial release.

## 0.0.2

* Adds `deleteIfDownloadedFilePathExists` to give option to delete file at download path if it exists before saving downloaded file to that path.

## 0.0.2+1

* Trigger robust cancel event with cancel token in error handler to fix future not returning in some cases.

## 0.0.3

* Adds Cache to manage files saved to the cache directory. Adds option to retry failed downloads.

## 0.0.4

* Adds connectivity listener to auto pause and resume downloads based on connection state

## 0.0.5

* Bumps http dependency version and Dart SDK constraints