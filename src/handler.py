# handler.py
import os
import base64
from io import BytesIO
from PIL import Image
from deoldify import device
from deoldify.device_id import DeviceId
from deoldify.visualize import get_image_colorizer
import torch
import warnings
import runpod
from runpod.serverless.utils import rp_download, upload_file_to_bucket, upload_in_memory_object, rp_cleanup
from runpod.serverless.utils.rp_validator import validate
from rp_schemas import INPUT_SCHEMA
import re
import functools
from fastai.basic_train import Recorder

# Add safe globals for PyTorch 2.6+
safe_globals = [
    functools.partial,
    Recorder
]
torch.serialization.add_safe_globals(safe_globals)

# Suppress specific warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*?Your .*? set is empty.*?")

# Initialize DeOldify device
device.set(device=DeviceId.GPU0)
torch.backends.cudnn.benchmark = True

def is_url(s):
    """Check if string is URL."""
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    return url_pattern.match(s) is not None

def decode_base64_image(base64_string):
    try:
        # Remove header if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        image_data = base64.b64decode(base64_string)
        return Image.open(BytesIO(image_data))
    except Exception as e:
        raise ValueError(f"Invalid base64 image: {str(e)}")

def save_and_upload_image(image, job_id, filename="output.png"):
    """Save image and return URL or base64 based on environment configuration."""
    os.makedirs(f"/{job_id}", exist_ok=True)
    image_path = os.path.join(f"/{job_id}", filename)
    image.save(image_path)

    result = None
    if os.environ.get("BUCKET_ENDPOINT_URL", False):
        result = upload_file_to_bucket(
            file_name=filename,
            file_location=image_path,
            prefix=job_id
        )
    else:
        with open(image_path, "rb") as image_file:
            image_data = base64.b64encode(image_file.read()).decode("utf-8")
            result = f"data:image/png;base64,{image_data}"

    rp_cleanup.clean([f"/{job_id}"])
    return result

def colorize_image(source, job_id, render_factor=35, watermarked=True, artistic=True):
    colorizer = get_image_colorizer(artistic=artistic)

    if is_url(source):
        # For URLs, use DeOldify's built-in URL handling
        result_path = colorizer.plot_transformed_image_from_url(
            url=source,
            render_factor=render_factor,
            compare=True,
            watermarked=watermarked
        )
        # Convert the result to PIL Image
        result_image = Image.open(result_path)
        os.remove(result_path)
    else:
        # For base64, convert to PIL Image first
        input_image = decode_base64_image(source)
        # Save temporarily for DeOldify
        temp_path = f"/{job_id}/input.jpg"
        os.makedirs(f"/{job_id}", exist_ok=True)
        input_image.save(temp_path)
        
        result_path = colorizer.plot_transformed_image(
            path=temp_path,
            render_factor=render_factor,
            compare=True,
            watermarked=watermarked
        )
        # Convert the result to PIL Image
        result_image = Image.open(result_path)
        os.remove(result_path)
        os.remove(temp_path)

    return result_image

def handler(job):
    job_input = job.get('input', {})
    validated_input = validate(job_input, INPUT_SCHEMA)

    if 'errors' in validated_input:
        return {"errors": validated_input['errors']}

    image = validated_input['validated_input'].get('image')
    render_factor = validated_input['validated_input'].get('render_factor')
    watermarked = validated_input['validated_input'].get('watermarked')

    try:
        job_id = job['id']
        result_image = colorize_image(
            source=image,
            job_id=job_id,
            render_factor=render_factor,
            watermarked=watermarked
        )

        result = save_and_upload_image(result_image, job_id)
        return {"output": result}
            
    except Exception as e:
        if job_id:
            rp_cleanup.clean([f"/{job_id}"])
        return {"error": str(e)}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})