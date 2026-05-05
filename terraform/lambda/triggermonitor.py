import json
import urllib3
import os

def lambda_handler(event, context):
    GITHUB_TOKEN = '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'
    REPO = 'madhukummari/myProjects'
    WORKFLOW = 'monitor-workflow.yaml'  # e.g., my-workflow.yml

    url = f"https://api.github.com/repos/{REPO}/actions/workflows/{WORKFLOW}/dispatches"
    
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    payload = {
        "ref": "master"
    }

    http = urllib3.PoolManager()
    r = http.request("POST", url, body=json.dumps(payload), headers=headers)

    return {
        "statusCode": r.status,
        "body": r.data.decode("utf-8")
    }
