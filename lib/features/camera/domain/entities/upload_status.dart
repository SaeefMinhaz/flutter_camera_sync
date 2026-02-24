/// Upload status for a captured image or a whole batch.
///
/// This lives in the camera domain because batches start their life
/// when the user is taking photos, but it is equally useful to the
/// sync feature which will import this type.
enum UploadStatus {
  pending,
  uploading,
  uploaded,
  failed,
}

