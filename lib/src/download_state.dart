abstract class DownloadState {}

class Paused implements DownloadState {
  const Paused();
}

class Downloading implements DownloadState {
  const Downloading();
}

class Cancelled implements DownloadState {
  const Cancelled();
}

class Completed implements DownloadState {
  const Completed();
}
