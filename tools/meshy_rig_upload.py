"""Submit a local character GLB to Meshy auto-rigging (5 credits per call).

    MESHY_API_KEY=... python3 tools/meshy_rig_upload.py <model.glb> [height_meters]

The Meshy MCP server only uploads images, so local models go to the REST API
as a GLB data URI (max 100 MB encoded). Prepare the model first with
tools/blender/prepare_rig_source.py (textured, rest pose, facing +Z).
Prints the rigging task id; continue with the meshy_animate MCP tool.
"""
import base64
import json
import os
import sys
import urllib.request

path = sys.argv[1]
height = float(sys.argv[2]) if len(sys.argv) > 2 else 1.7
with open(path, "rb") as f:
    uri = "data:application/octet-stream;base64," + base64.b64encode(f.read()).decode()
if len(uri) > 100 * 1024 * 1024:
    sys.exit("encoded model exceeds Meshy's 100 MB data URI limit")
request = urllib.request.Request(
    "https://api.meshy.ai/openapi/v1/rigging",
    data=json.dumps({"model_url": uri, "height_meters": height}).encode(),
    headers={"Authorization": "Bearer " + os.environ["MESHY_API_KEY"], "Content-Type": "application/json"},
    method="POST",
)
with urllib.request.urlopen(request, timeout=600) as response:
    print(json.load(response))
