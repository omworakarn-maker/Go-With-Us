import Resizer from "react-image-file-resizer";

export const resizeImage = (file: File): Promise<string> =>
  new Promise((resolve) => {
    Resizer.imageFileResizer(
      file,
      1200, // max width
      1200, // max height
      "JPEG", // format
      80, // quality 0-100
      0, // rotation
      (uri) => {
        resolve(uri as string);
      },
      "base64" // output type
    );
  });
