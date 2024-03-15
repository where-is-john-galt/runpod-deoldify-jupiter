# rp_schemas.py
INPUT_SCHEMA = {
    'source_url': {
        'type': str,
        'required': True
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
    },
}