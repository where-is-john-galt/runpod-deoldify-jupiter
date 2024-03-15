# handler.py
import os
from deoldify import device
from deoldify.device_id import DeviceId
from deoldify.visualize import get_image_colorizer
import torch
import warnings
import runpod
from runpod.serverless.utils import rp_download, upload_file_to_bucket, upload_in_memory_object
from runpod.serverless.utils.rp_validator import validate
from rp_schemas import INPUT_SCHEMA

# Suppress specific warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*?Your .*? set is empty.*?")

# Initialize DeOldify device
device.set(device=DeviceId.GPU0)
torch.backends.cudnn.benchmark = True

def colorize_image(source_url, render_factor=35, watermarked=True, artistic=True):
    colorizer = get_image_colorizer(artistic=artistic)

    if source_url:
        result_path = colorizer.plot_transformed_image_from_url(url=source_url, render_factor=render_factor, compare=True, watermarked=watermarked)
    else:
        raise ValueError("Source URL must be provided.")

    return result_path

def handler(job):
    job_input = job.get('input', {})
    validated_input = validate(job_input, INPUT_SCHEMA)

    if 'errors' in validated_input:
        return {"errors": validated_input['errors']}

    source_url = validated_input['validated_input'].get('source_url')
    render_factor = validated_input['validated_input'].get('render_factor')
    watermarked = validated_input['validated_input'].get('watermarked')

    try:
        result_path = colorize_image(source_url=source_url, render_factor=render_factor, watermarked=watermarked)
        file_name = os.path.basename(result_path)

        presigned_url = upload_file_to_bucket(file_name=file_name, file_location=result_path, prefix="your_prefix_here")

        os.remove(result_path)
        
        return {"result_url": presigned_url}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})