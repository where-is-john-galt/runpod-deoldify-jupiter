# 🎨 DeOldify Worker for RunPod

A serverless worker for **image colorization** using [DeOldify](https://github.com/jantic/DeOldify), deployed on [RunPod](https://www.runpod.io). This worker takes a black-and-white image URL and returns a colorized version using a deep learning model.

---

## ✨ Features

- ✅ Colorizes black-and-white images using DeOldify
- 🎛️ Configurable rendering quality (`render_factor`)
- 💧 Optional watermarking
- ⚙️ Compatible with RunPod Serverless
- 🖼️ Uses artistic model by default for vibrant results
- ☁️ Output delivered via pre-signed download URL

---

## 📥 Input Parameters

| Parameter      | Type   | Required | Default | Description |
|----------------|--------|----------|---------|-------------|
| `source_url`   | string | ✅ Yes    | —       | Publicly accessible URL to the image to be colorized |
| `render_factor`| int    | ❌ No     | `35`    | Quality setting from 7 to 40 (higher = better color, slower) |
| `watermarked`  | bool   | ❌ No     | `false` | Whether to apply a DeOldify watermark to the result |

---

## 🚀 Usage Examples

### 🔹 Basic Colorization

```json
{
  "input": {
    "source_url": "https://example.com/image.jpg"
  }
}
```

---

### 🔹 Custom Render Factor & Watermarking

```json
{
  "input": {
    "source_url": "https://example.com/image.jpg",
    "render_factor": 40,
    "watermarked": true
  }
}
```

---

## 📤 Output Format

Successful responses will return a JSON object containing a URL to download the processed file:

```json
{
  "result_url": "https://your-bucket.s3.amazonaws.com/your_prefix_here/colorized_image.jpg?X-Amz-..."
}
```

In case of validation or processing errors:

```json
{
  "errors": ["source_url is required"]
}
```

or

```json
{
  "error": "Something went wrong during processing"
}
```

---

## ⚙️ Deployment (RunPod)

1. Clone the repository:

```bash
git clone https://github.com/your-username/worker-deoldify
cd worker-deoldify
```

2. Build the Docker image:

```bash
docker build -t worker-deoldify .
```

3. Push to a container registry (like Docker Hub or GHCR), then deploy to RunPod via [RunPod Serverless Workers](https://www.runpod.io/serverless/docs).

4. Register the `handler` function as the job entry point.

---

## 📂 Project Structure

```txt
worker-deoldify/
├── handler.py           # Main logic for handling jobs
├── rp_schemas.py        # Input validation schema
├── Dockerfile           # RunPod-compatible Dockerfile
├── requirements.txt     # Python dependencies
└── README.md            # This file
```

---

## 🧪 Tips for Best Results

- Use **high-quality images** with clear subjects.
- A `render_factor` between `30–40` gives the best color fidelity.
- Enable watermarking if you want to acknowledge DeOldify’s authors.

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [DeOldify](https://github.com/jantic/DeOldify) — deep learning magic by Jason Antic
- [RunPod](https://www.runpod.io) — serverless AI compute platform
- This worker wraps and serves DeOldify with scalable inference

---

Would you like me to generate a matching `Dockerfile` or `runpod.yaml` for this as well?
