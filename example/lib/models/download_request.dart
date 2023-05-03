class DownloadRequest {
  final String url;
  final bool canPlay;

  const DownloadRequest({
    required this.url,
    this.canPlay = false,
  });

  //Credits:
  //https://gist.github.com/jsturgis/3b19447b304616f18657
  //https://www.soundhelix.com/audio-examples
  static List<DownloadRequest> requests = const [
    DownloadRequest(
      url:
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    ),
    DownloadRequest(
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      canPlay: true,
    ),
    DownloadRequest(
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3",
      canPlay: true,
    ),
    DownloadRequest(
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
      canPlay: true,
    ),
    DownloadRequest(
      url:
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    ),
  ];
}
