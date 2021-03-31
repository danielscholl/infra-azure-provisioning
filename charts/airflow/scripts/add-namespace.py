#!/usr/bin/env python

import yaml
import sys

def addNamespace(namespace, manifest):
    if 'metadata' in manifest and 'namespace' not in manifest['metadata'] and 'Namespace' not in manifest['kind']:
        manifest['metadata']['namespace'] = namespace
    if 'subjects' in manifest:
        manifest['subjects'][0]['namespace'] = namespace
def removeReplicasFromWorkerStatefulSet(manifest):
    # This function removes replicas property if autoscaling is enabled.
    # This is done to make sure kubernetes does not reset the pod count when autoscaling is enabled
    if manifest['kind'] == 'StatefulSet' and manifest['metadata']['name'] == 'airflow-worker':
        if manifest['metadata']['labels']['autoscalingEnabled']:
            del manifest['spec']['replicas']


def addingNamespace(namespace):
    for manifest in yaml.load_all(sys.stdin, Loader=yaml.FullLoader):
        if manifest:
            addNamespace(namespace, manifest)
            removeReplicasFromWorkerStatefulSet(manifest)
            print ('---')
            print (yaml.dump(manifest, default_flow_style=False, sort_keys=False))

namespace="osdu"
addingNamespace(namespace)
