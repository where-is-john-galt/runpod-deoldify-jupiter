# rp_schemas.py

INPUT_SCHEMA = {
    'image': {
        'type': str,
        'required': True,
        'description': 'URL or base64 encoded image'
    },
    'render_factor': {
        'type': int,
        'required': False,
        'default': 35,
        'constraints': lambda x: 7 <= x <= 40
    },
    'watermarked': {
        'type': bool,
        'required': False,
        'default': False
    }
}