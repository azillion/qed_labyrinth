#!/bin/bash
# Ensure the output directory exists
mkdir -p ./schemas_generated

# Run the Python protoc compiler
python -m grpc_tools.protoc \
  -I../schemas \
  --python_out=./schemas_generated \
  ../schemas/ai_comms.proto

# Create the __init__.py file to make it a package
touch ./schemas_generated/__init__.py
