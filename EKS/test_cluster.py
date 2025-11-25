#!/usr/bin/env python3
"""
EKS Cluster Testing Script
Tests the deployed EKS cluster and application
"""

import subprocess
import json
import time
import sys
import requests
from urllib.parse import urlparse

def run_command(cmd, check=True):
    """Execute shell command and return output"""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, check=check
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {cmd}")
        print(f"Error: {e.stderr}")
        if check:
            sys.exit(1)
        return None

def test_kubectl_connection():
    """Test kubectl connection to cluster"""
    print("\n" + "="*60)
    print("TEST 1: Testing kubectl connection to EKS cluster")
    print("="*60)
    
    result = run_command("kubectl cluster-info", check=False)
    if result:
        print("✓ kubectl is connected to the cluster")
        print(result)
        return True
    else:
        print("✗ kubectl connection failed")
        return False

def get_cluster_nodes():
    """Get cluster node information"""
    print("\n" + "="*60)
    print("TEST 2: Checking cluster nodes")
    print("="*60)
    
    result = run_command("kubectl get nodes -o wide")
    print(result)
    
    # Get detailed node info
    result_json = run_command("kubectl get nodes -o json")
    nodes_data = json.loads(result_json)
    print(f"\nTotal nodes: {len(nodes_data['items'])}")
    
    for node in nodes_data['items']:
        node_name = node['metadata']['name']
        status = node['status']['conditions'][-1]['type']
        print(f"  - {node_name}: {status}")
    
    return True

def check_namespaces():
    """Check available namespaces"""
    print("\n" + "="*60)
    print("TEST 3: Checking namespaces")
    print("="*60)
    
    result = run_command("kubectl get namespaces")
    print(result)
    return True

def check_deployments():
    """Check deployments in demo-app namespace"""
    print("\n" + "="*60)
    print("TEST 4: Checking application deployments")
    print("="*60)
    
    result = run_command("kubectl get deployments -n demo-app")
    print(result)
    
    # Wait for pods to be ready
    print("\nWaiting for pods to be ready...")
    for i in range(30):
        result = run_command("kubectl get pods -n demo-app")
        print(f"\nAttempt {i+1}/30:")
        print(result)
        
        # Check if all pods are running
        pods_json = run_command("kubectl get pods -n demo-app -o json", check=False)
        if pods_json:
            pods_data = json.loads(pods_json)
            running_pods = [p for p in pods_data['items'] if p['status']['phase'] == 'Running']
            if len(running_pods) == len(pods_data['items']) and len(running_pods) > 0:
                print(f"\n✓ All {len(running_pods)} pods are running!")
                break
        time.sleep(2)
    else:
        print("\n⚠ Some pods may still be starting")
    
    return True

def get_service_info():
    """Get LoadBalancer service information"""
    print("\n" + "="*60)
    print("TEST 5: Checking LoadBalancer service")
    print("="*60)
    
    result = run_command("kubectl get svc -n demo-app")
    print(result)
    
    # Get external IP/URL
    print("\nWaiting for LoadBalancer to get external endpoint...")
    for i in range(60):
        svc_json = run_command("kubectl get svc nginx-service -n demo-app -o json", check=False)
        if svc_json:
            svc_data = json.loads(svc_json)
            ingress = svc_data.get('status', {}).get('loadBalancer', {}).get('ingress', [])
            if ingress:
                external_host = ingress[0].get('hostname') or ingress[0].get('ip')
                print(f"\n✓ LoadBalancer endpoint: http://{external_host}")
                return external_host
        time.sleep(5)
        if i % 5 == 0:
            print(f"  Waiting... ({i*5} seconds)")
    
    print("\n⚠ LoadBalancer endpoint not ready yet")
    return None

def test_http_endpoint(url):
    """Test HTTP endpoint"""
    print("\n" + "="*60)
    print("TEST 6: Testing HTTP endpoint")
    print("="*60)
    
    if not url:
        print("⚠ No endpoint available to test")
        return False
    
    try:
        response = requests.get(f"http://{url}", timeout=10)
        print(f"✓ HTTP Request successful!")
        print(f"  Status Code: {response.status_code}")
        print(f"  Response Headers: {dict(list(response.headers.items())[:5])}")
        print(f"  Content Length: {len(response.content)} bytes")
        return True
    except Exception as e:
        print(f"✗ HTTP Request failed: {e}")
        return False

def get_pod_logs():
    """Get logs from a pod"""
    print("\n" + "="*60)
    print("TEST 7: Getting pod logs")
    print("="*60)
    
    pods = run_command("kubectl get pods -n demo-app -o json")
    pods_data = json.loads(pods)
    
    if pods_data['items']:
        pod_name = pods_data['items'][0]['metadata']['name']
        print(f"Getting logs from pod: {pod_name}")
        logs = run_command(f"kubectl logs {pod_name} -n demo-app --tail=10")
        print(logs)
        return True
    else:
        print("No pods found")
        return False

def main():
    print("\n" + "="*60)
    print("EKS CLUSTER TESTING SUITE")
    print("="*60)
    
    tests = [
        test_kubectl_connection,
        get_cluster_nodes,
        check_namespaces,
        check_deployments,
        get_service_info,
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"\n✗ Test failed with error: {e}")
            results.append(False)
    
    # Test HTTP endpoint if available
    external_host = get_service_info()
    if external_host:
        test_http_endpoint(external_host)
    
    get_pod_logs()
    
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"Tests passed: {sum(results)}/{len(results)}")
    
    if all(results):
        print("\n✓ All tests completed successfully!")
    else:
        print("\n⚠ Some tests had issues. Check output above.")

if __name__ == "__main__":
    main()

