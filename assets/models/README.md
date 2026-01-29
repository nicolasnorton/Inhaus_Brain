# LiteRT Models

This directory stores the on-device AI models used by LiteRT (formerly TensorFlow Lite).

## Required Models

1. **Gemma 2B IT (Quantized)**
   - Filename: `gemma_2b_it_gpu.bin` (or .tflite)
   - Usage: Text generation, polishing, summaries.
   - Source: [Kaggle Models](https://www.kaggle.com/models/google/gemma) or convert via `scripts/setup_litert_models.sh`.

2. **Veo 3 Fast (Preview)**
   - Filename: `veo_3_fast_preview.tflite`
   - Usage: Low-res video/image previews.
   - Source: Internal Google bucket (check `setup_litert_models.sh`).

## Setup

Run the setup script to download and verify models:

```bash
./scripts/setup_litert_models.sh
```

## Note on Git

These models are ignored by `.gitignore` to prevent repository bloat. Do not commit them.
