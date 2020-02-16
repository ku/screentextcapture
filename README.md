
screentextcapture
====

convert selected area into text by Google [Cloud Vision API](https://cloud.google.com/vision/).


# How to use

- https://cloud.google.com/vision/docs/quickstart
  - make sure `gcloud ml vision detect-text` command works
    - [install gcloud](https://cloud.google.com/sdk/docs/quickstart-macos)
      - `gcloud` command is supposed to be installed `/usr/local/bin`
    - `gcloud auth login` to login to your account to use
    - [enable ML Vision API](https://console.developers.google.com/iam-admin/iam/project)
- run screentextcapture.app
  - result text will be sent to the clipboard
