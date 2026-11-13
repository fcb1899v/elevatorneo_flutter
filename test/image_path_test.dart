// Photo paths: what is saved, and how a saved path is resolved after the Documents path changes.
// Documents is pointed at a temporary folder, so the app's real Documents is never touched.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letselevatorneo/image_manager.dart';
import 'package:letselevatorneo/constant.dart';

const String oldDocuments = "/var/mobile/Containers/Data/Application/OLD/Documents";
const String photoName = "image_cropper_a.jpg";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("storedImagePath and resolvedImagePath", () {
    test("T16: storedImagePath keeps bundled paths and keeps only the file name of photos", () {
      expect(storedImagePath("assets/images/room/01parking.jpg"),
        "assets/images/room/01parking.jpg");
      expect(storedImagePath("$oldDocuments/$photoName"), photoName);
      expect(storedImagePath(photoName), photoName);
    });

    test("T17: resolvedImagePath keeps bundled paths and joins photos to the current Documents", () {
      const newDocuments = "/NEW/Documents";
      expect(resolvedImagePath("assets/images/room/01parking.jpg", newDocuments),
        "assets/images/room/01parking.jpg");
      expect(resolvedImagePath(photoName, newDocuments), "$newDocuments/$photoName");
      expect(resolvedImagePath("$oldDocuments/$photoName", newDocuments),
        "$newDocuments/$photoName");
    });
  });

  group("ImageManager with a temporary Documents folder", () {
    late Directory documents;

    setUp(() async {
      documents = await Directory.systemTemp.createTemp("image_path_test_");
    });

    tearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });

    ImageManager managerFor(String documentsPath) =>
      ImageManager(documentsPathProvider: () async => documentsPath);

    test("T18: getImagesList resolves an old full path to the current Documents", () async {
      // The file sits in the current Documents; the stored path points at an old one
      await File(path.join(documents.path, photoName)).writeAsString("photo");
      SharedPreferences.setMockInitialValues({
        "floorsKey": [
          "$oldDocuments/$photoName",
          for (int i = 1; i < initialFloorImages.length; i++) initialFloorImages[i],
        ],
      });

      final images = await managerFor(documents.path).getImagesList();
      expect(images[0], path.join(documents.path, photoName));
      expect(images.sublist(1), initialFloorImages.sublist(1));
    });

    test("T18: a photo whose file is missing falls back to the first image", () async {
      SharedPreferences.setMockInitialValues({
        "floorsKey": [
          for (int i = 0; i < initialFloorImages.length; i++)
            i == 0 ? "$oldDocuments/$photoName" : initialFloorImages[i],
        ],
      });

      final images = await managerFor(documents.path).getImagesList();
      expect(images[0], initialFloorImages[0]);
    });

    test("T19: saveImagePath stores every entry as a bundled path or a file name only", () async {
      SharedPreferences.setMockInitialValues({});
      final current = [
        "$oldDocuments/$photoName",
        ...initialFloorImages.sublist(1),
      ];
      // The new photo is passed as a full path, as the crop step returns it
      final newPhoto = "/NEW/Documents/image_cropper_b.jpg";
      final manager = managerFor(documents.path);
      await manager.saveImagePath(
        currentList: current,
        newValue: newPhoto,
        newIndex: 1,
      );

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList("floorsKey")!;
      expect(stored[0], photoName);
      expect(stored[1], "image_cropper_b.jpg");
      expect(stored.sublist(2), initialFloorImages.sublist(2));
      for (final value in stored) {
        if (!isBundledImage(value)) {
          expect(path.basename(value), value, reason: "not a file name: $value");
        }
      }
    });
  });
}
