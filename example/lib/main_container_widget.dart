import 'dart:io';

import 'package:camera_macos_plus/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'input_image.dart';

class MainContainerWidget extends StatefulWidget {
  const MainContainerWidget({super.key});

  @override
  MainContainerWidgetState createState() => MainContainerWidgetState();
}

class MainContainerWidgetState extends State<MainContainerWidget> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  GlobalKey cameraKey = GlobalKey();
  List<CameraMacOSDevice> videoDevices = [];
  String? selectedVideoDevice;
  PictureResolution selectedPictureResolution = PictureResolution.max;
  AudioQuality selectedAudioQulaity = AudioQuality.min;
  PictureFormat selectedPictureFormat = PictureFormat.tiff;
  CameraOrientation selectedOrientation = CameraOrientation.orientation0deg;
  VideoFormat selectedVideoFormat = VideoFormat.mp4;
  AudioFormat selectedAudioFormat = AudioFormat.kAudioFormatAppleLossless;
  File? lastPictureTaken;

  List<CameraMacOSDevice> audioDevices = [];
  String? selectedAudioDevice;

  bool enableAudio = true;
  bool enableTorch = false;
  bool usePlatformView = false;
  bool streamImage = false;
  bool isVideoMirrored = true;

  CameraImageData? streamedImage;

  double zoom = 1.0;

  List<DropdownMenuItem<String>> add = [];

  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.photo;
    durationValue = 15;
    durationController = TextEditingController(text: '$durationValue');
    durationController.addListener(() {
      setState(() {
        double? textFieldContent = double.tryParse(durationController.text);
        if (textFieldContent == null) {
          durationValue = 15;
          durationController.text = '$durationValue';
        } else {
          durationValue = textFieldContent;
        }
      });
    });

    for (int i = 0; i < AudioFormat.values.length; i++) {
      add.add(DropdownMenuItem(
        value: '$i',
        child: Text(AudioFormat.values[i].name.replaceAll('kAudioFormat', '')),
      ));
    }
  }

  String get cameraButtonText {
    String label = 'Do something';
    switch (cameraMode) {
      case CameraMacOSMode.photo:
        label = 'Take Picture';
        break;
      case CameraMacOSMode.video:
        if (macOSController?.isRecording ?? false) {
          label = 'Stop recording';
        } else {
          label = 'Record video';
        }
        break;
    }
    return label;
  }

  Future<String> get imageFilePath async => path.join(
      (await getApplicationDocumentsDirectory()).path,
      'P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_'
      '${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.'
      '${selectedPictureFormat.name.replaceAll('PictureFormat.', '')}');

  Future<String> get videoFilePath async => path.join(
      (await getApplicationDocumentsDirectory()).path,
      'V_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_'
      '${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.'
      '${selectedVideoFormat.name.replaceAll('VideoFormat.', '')}');

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera MacOS Example'),
      ),
      body: SizedBox(
          width: size.width,
          height: size.height,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video Devices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: DropdownButton<String>(
                                  elevation: 3,
                                  isExpanded: true,
                                  value: selectedVideoDevice,
                                  underline:
                                      Container(color: Colors.transparent),
                                  items: videoDevices
                                      .map((CameraMacOSDevice device) {
                                    return DropdownMenuItem(
                                      value: device.deviceId,
                                      child: Text(device.deviceId),
                                    );
                                  }).toList(),
                                  onChanged: (String? newDeviceID) {
                                    setState(() {
                                      selectedVideoDevice = newDeviceID;
                                    });
                                  },
                                ),
                              ),
                            ),
                            MaterialButton(
                              color: Colors.lightBlue,
                              textColor: Colors.white,
                              onPressed: listVideoDevices,
                              child: const Text('List video devices'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio Devices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: DropdownButton<String>(
                                  elevation: 3,
                                  isExpanded: true,
                                  value: selectedAudioDevice,
                                  underline:
                                      Container(color: Colors.transparent),
                                  items: audioDevices
                                      .map((CameraMacOSDevice device) {
                                    return DropdownMenuItem(
                                      value: device.deviceId,
                                      child: Text(device.deviceId),
                                    );
                                  }).toList(),
                                  onChanged: (String? newDeviceID) {
                                    setState(() {
                                      selectedAudioDevice = newDeviceID;
                                    });
                                  },
                                ),
                              ),
                            ),
                            MaterialButton(
                              color: Colors.lightBlue,
                              textColor: Colors.white,
                              onPressed: listAudioDevices,
                              child: const Text('List audio devices'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        selectedVideoDevice != null &&
                                selectedVideoDevice!.isNotEmpty
                            ? SizedBox(
                                width: (size.width - 24),
                                height: (size.width - 24) * (9 / 16),
                                child: GestureDetector(
                                    onTapDown: (t) {
                                      macOSController?.setFocusPoint(Offset(
                                          t.localPosition.dx /
                                              (size.width - 24),
                                          t.localPosition.dy /
                                              ((size.width - 24) * (9 / 16))));
                                    },
                                    child: Stack(
                                        alignment: Alignment.topLeft,
                                        children: [
                                          Positioned(
                                              left: 0,
                                              child: SizedBox(
                                                  height: (size.width - 24) *
                                                      (9 / 16),
                                                  child: RotatedBox(
                                                      quarterTurns: 1,
                                                      child: Slider(
                                                        activeColor: Colors.red,
                                                        value: zoom,
                                                        min: 1.0,
                                                        max: 8.0,
                                                        onChanged: (value) {
                                                          macOSController
                                                              ?.setZoomLevel(
                                                                  value);
                                                          setState(() =>
                                                              zoom = value);
                                                        },
                                                      )))),
                                          Container(
                                              margin: const EdgeInsets.only(
                                                  left: 40),
                                              child: CameraMacOSView(
                                                key: cameraKey,
                                                deviceId: selectedVideoDevice,
                                                audioDeviceId:
                                                    selectedAudioDevice,
                                                fit: BoxFit.fitWidth,
                                                cameraMode:
                                                    CameraMacOSMode.photo,
                                                resolution:
                                                    selectedPictureResolution,
                                                audioQuality:
                                                    selectedAudioQulaity,
                                                pictureFormat:
                                                    selectedPictureFormat,
                                                orientation:
                                                    selectedOrientation,
                                                videoFormat:
                                                    selectedVideoFormat,
                                                audioFormat:
                                                    selectedAudioFormat,
                                                isVideoMirrored:
                                                    isVideoMirrored,
                                                onCameraInizialized:
                                                    (CameraMacOSController
                                                        controller) {
                                                  setState(() {
                                                    macOSController =
                                                        controller;
                                                  });
                                                },
                                                onCameraDestroyed: () {
                                                  return const Text(
                                                      'Camera Destroyed!');
                                                },
                                                toggleTorch: enableTorch
                                                    ? Torch.on
                                                    : Torch.off,
                                                enableAudio: enableAudio,
                                                usePlatformView:
                                                    usePlatformView,
                                              ))
                                        ])))
                            : const Center(
                                child: Text('Tap on List Devices first'),
                              ),
                        lastImagePreviewData != null
                            ? InkWell(
                                onTap: openPicture,
                                child: Container(
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                        color: Colors.lightBlue,
                                        width: 10,
                                      ),
                                    ),
                                  ),
                                  child: Image.memory(
                                    lastImagePreviewData!,
                                    height: 50,
                                    width: 90,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (streamedImage != null)
                      SizedBox(
                          width: (size.width - 24),
                          height: (size.width - 24) * (9 / 16),
                          child:
                              Image.memory(argb2bitmap(streamedImage!).bytes)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Camera Orientation',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton<String>(
                            elevation: 3,
                            isExpanded: true,
                            value: selectedOrientation.index.toString(),
                            underline: Container(color: Colors.transparent),
                            padding: const EdgeInsets.only(left: 10),
                            items: const [
                              DropdownMenuItem(
                                value: '0',
                                child: Text('0'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('90'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('180'),
                              ),
                              DropdownMenuItem(
                                value: '3',
                                child: Text('270'),
                              )
                            ],
                            onChanged: (String? or) {
                              setState(() {
                                selectedOrientation =
                                    CameraOrientation.values[int.parse(or!)];
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Picture Resolution',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton<String>(
                            elevation: 3,
                            isExpanded: true,
                            value: selectedPictureResolution.index.toString(),
                            underline: Container(color: Colors.transparent),
                            padding: const EdgeInsets.only(left: 10),
                            items: const [
                              DropdownMenuItem(
                                value: '0',
                                child: Text('low'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('medium'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('high'),
                              ),
                              DropdownMenuItem(
                                value: '3',
                                child: Text('very high'),
                              ),
                              DropdownMenuItem(
                                value: '4',
                                child: Text('ultra high'),
                              ),
                              DropdownMenuItem(
                                value: '5',
                                child: Text('max'),
                              )
                            ],
                            onChanged: (String? or) {
                              setState(() {
                                selectedPictureResolution =
                                    PictureResolution.values[int.parse(or!)];
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Audio Quality',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton<String>(
                            elevation: 3,
                            isExpanded: true,
                            value: selectedAudioQulaity.index.toString(),
                            underline: Container(color: Colors.transparent),
                            padding: const EdgeInsets.only(left: 10),
                            items: const [
                              DropdownMenuItem(
                                value: '0',
                                child: Text('min'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('low'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('medium'),
                              ),
                              DropdownMenuItem(
                                value: '3',
                                child: Text('high'),
                              ),
                              DropdownMenuItem(
                                value: '4',
                                child: Text('max'),
                              )
                            ],
                            onChanged: (String? q) {
                              setState(() {
                                selectedAudioQulaity =
                                    AudioQuality.values[int.parse(q!)];
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Video Format',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 80,
                          child: DropdownButton<String>(
                            elevation: 3,
                            isExpanded: true,
                            value: selectedVideoFormat.index.toString(),
                            underline: Container(color: Colors.transparent),
                            padding: const EdgeInsets.only(left: 10),
                            items: const [
                              DropdownMenuItem(
                                value: '0',
                                child: Text('mv4'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('mov'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('mp4'),
                              )
                            ],
                            onChanged: (String? q) {
                              setState(() {
                                selectedVideoFormat =
                                    VideoFormat.values[int.parse(q!)];
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Audio Format',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButton<String>(
                            elevation: 3,
                            isExpanded: true,
                            value: selectedAudioFormat.index.toString(),
                            underline: Container(color: Colors.transparent),
                            padding: const EdgeInsets.only(left: 10),
                            items: add,
                            onChanged: (String? q) {
                              setState(() {
                                selectedAudioFormat =
                                    AudioFormat.values[int.parse(q!)];
                              });
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 90,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                value: enableAudio,
                                contentPadding: EdgeInsets.zero,
                                tristate: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Enable Audio'),
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    enableAudio = newValue ?? false;
                                  });
                                },
                              ),
                              CheckboxListTile(
                                value: usePlatformView,
                                contentPadding: EdgeInsets.zero,
                                tristate: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'Use Platform View '
                                  '(Experimental - Not Working)',
                                ),
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    usePlatformView = newValue ?? false;
                                  });
                                },
                              ),
                              CheckboxListTile(
                                value: enableTorch,
                                contentPadding: EdgeInsets.zero,
                                tristate: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Toggle Torch'),
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    enableTorch = newValue ?? false;
                                    macOSController?.toggleTorch(
                                        !enableTorch ? Torch.on : Torch.off);
                                  });
                                },
                              ),
                              CheckboxListTile(
                                value: isVideoMirrored,
                                contentPadding: EdgeInsets.zero,
                                tristate: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Mirror video'),
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    isVideoMirrored = newValue ?? false;
                                    macOSController
                                        ?.setVideoMirrored(isVideoMirrored);
                                  });
                                },
                              ),
                              CheckboxListTile(
                                value: streamImage,
                                contentPadding: EdgeInsets.zero,
                                tristate: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text('Stream Image'),
                                onChanged: (bool? newValue) {
                                  if (macOSController != null) {
                                    setState(() {
                                      streamImage = newValue ?? false;

                                      if (streamImage == true) {
                                        macOSController
                                            ?.startImageStream((image) {
                                          streamedImage = image;
                                          setState(() {});
                                        });
                                      } else {
                                        macOSController?.stopImageStream();
                                        streamedImage = null;
                                      }
                                    });
                                  }
                                },
                              ),
                              const Text(
                                'Camera mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RadioGroup<CameraMacOSMode>(
                                groupValue: cameraMode,
                                onChanged: (CameraMacOSMode? newMode) {
                                  setState(() {
                                    if (newMode != null) {
                                      cameraMode = newMode;
                                    }
                                  });
                                },
                                child: Column(
                                  children: [
                                    const RadioListTile(
                                      title: Text('Photo'),
                                      contentPadding: EdgeInsets.zero,
                                      value: CameraMacOSMode.photo,
                                    ),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: RadioListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text('Video'),
                                            value: CameraMacOSMode.video,
                                          ),
                                        ),
                                        Visibility(
                                          visible: cameraMode ==
                                              CameraMacOSMode.video,
                                          child: Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12.0),
                                              child: TextField(
                                                controller: durationController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Video Length',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 10),
                      ],
                    ),
                    Container(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MaterialButton(
                          color: Colors.red,
                          textColor: Colors.white,
                          onPressed: destroyCamera,
                          child: Builder(
                            builder: (context) {
                              String buttonText = 'Destroy';
                              if (macOSController != null &&
                                  macOSController!.isDestroyed) {
                                buttonText = 'Reinitialize';
                              }
                              return Text(buttonText);
                            },
                          ),
                        ),
                        MaterialButton(
                          color: Colors.lightBlue,
                          textColor: Colors.white,
                          onPressed: onCameraButtonTap,
                          child: Text(cameraButtonText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Future<void> startRecording() async {
    try {
      String urlPath = await videoFilePath;
      await macOSController!.recordVideo(
        maxVideoDuration: durationValue,
        url: urlPath,
        enableAudio: enableAudio,
        onVideoRecordingFinished:
            (CameraMacOSFile? result, CameraMacOSException? exception) {
          setState(() {});
          if (exception != null) {
            showAlert(message: exception.toString());
          } else if (result != null) {
            showAlert(
              title: 'SUCCESS',
              message: 'Video saved at ${result.url}',
            );
          }
        },
      );
    } catch (e) {
      await showAlert(message: e.toString());
    } finally {
      setState(() {});
    }
  }

  Future<void> listVideoDevices() async {
    try {
      List<CameraMacOSDevice> videoDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      setState(() {
        this.videoDevices = videoDevices;
        if (videoDevices.isNotEmpty) {
          selectedVideoDevice = videoDevices.first.deviceId;
        }
      });
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> listAudioDevices() async {
    try {
      List<CameraMacOSDevice> audioDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.audio,
      );
      setState(() {
        this.audioDevices = audioDevices;
        if (audioDevices.isNotEmpty) {
          selectedAudioDevice = audioDevices.first.deviceId;
        }
      });
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  void changeCameraMode() {
    setState(() {
      cameraMode = cameraMode == CameraMacOSMode.photo
          ? CameraMacOSMode.video
          : CameraMacOSMode.photo;
    });
  }

  Future<void> destroyCamera() async {
    try {
      if (macOSController != null) {
        if (macOSController!.isDestroyed) {
          setState(() {
            cameraKey = GlobalKey();
          });
        } else {
          await macOSController?.destroy();
          setState(() {});
        }
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> onCameraButtonTap() async {
    try {
      if (macOSController != null) {
        switch (cameraMode) {
          case CameraMacOSMode.photo:
            CameraMacOSFile? imageData = await macOSController!.takePicture();
            if (imageData != null) {
              setState(() {
                lastImagePreviewData = imageData.bytes;
                savePicture(lastImagePreviewData!);
              });
              await showAlert(
                title: 'SUCCESS',
                message: 'Image successfully created',
              );
            }
            break;
          case CameraMacOSMode.video:
            if (macOSController!.isRecording) {
              CameraMacOSFile? videoData =
                  await macOSController!.stopRecording();
              if (videoData != null) {
                setState(() {
                  lastRecordedVideoData = videoData.bytes;
                });
                await showAlert(
                  title: 'SUCCESS',
                  message: 'Video saved at ${videoData.url}',
                );
              }
            } else {
              await startRecording();
            }
            break;
        }
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> savePicture(Uint8List photoBytes) async {
    try {
      String filename = await imageFilePath;
      File f = File(filename);
      if (f.existsSync()) {
        f.deleteSync(recursive: true);
      }
      f
        ..createSync(recursive: true)
        ..writeAsBytesSync(photoBytes);
      lastPictureTaken = f;
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> openPicture() async {
    try {
      if (lastPictureTaken != null) {
        Uri uriPath = Uri.file(lastPictureTaken!.path);
        if (await canLaunchUrl(uriPath)) {
          await launchUrl(uriPath);
        }
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> openOutputFolder() async {
    try {
      Uri uriPath =
          Uri.directory((await getApplicationDocumentsDirectory()).path);
      if (await canLaunchUrl(uriPath)) {
        await launchUrl(uriPath);
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  void startImageStream() async {
    try {
      if (macOSController != null && !macOSController!.isStreamingImageData) {
        debugPrint('Started streaming');
        setState(() {
          macOSController!.startImageStream(
            (p0) {
              debugPrint(p0.toString());
            },
            onError: (dynamic err) {
              debugPrint(err.toString());
            },
          );
        });
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  void stopImageStream() async {
    try {
      if (macOSController != null && macOSController!.isStreamingImageData) {
        setState(() {
          macOSController!.stopImageStream();
          debugPrint('Stopped streaming');
        });
      }
    } catch (e) {
      await showAlert(message: e.toString());
    }
  }

  Future<void> showAlert({
    String title = 'ERROR',
    String message = '',
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
