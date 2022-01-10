# Container Registry Pocket Edition

[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)


Container pull-only registry on mobile devices

```mermaid
%%{init:{'theme':'base'}}%%
flowchart LR
    subgraph internet ["Internet"]
        registry("Container<br>Registry")
        deployment_center["Deployments<br>Center"]
        crpe((crpe))
    end
    
    subgraph intranet ["Intranet"]
        crpe_intranet((crpe))
        
        subgraph cluster ["k8s/k3s cluster"]
            cluster_registry("Cluster<br>Container<br>Registry")
            mainfests_watcher("Mainfests<br>Watcher")
            pods("Pods")
        end
    end
    
    deployment_center -->|"mainfests && images list"| crpe
    registry -->|pull && cache| crpe
    
    crpe -..- crpe_intranet
    
    crpe_intranet 
        -->|sync images| cluster_registry 
        -->|pull| pods
        
    crpe_intranet
        -->|sync manifests| mainfests_watcher    
        -->|create| pods
```

## Spec `KubePkg.json`

```typescript
interface KubePkg {
    // pkg name 
    name: string
    // semver for upgrade checking
    version: string
    // images with tag may with digest
    // when digest exists, tag the digest instead of pulling always
    images: { [imagetag: string]: string | "" }
    // manifests of k8s
    manifests: string[]
}
```

```json
{
  "name": "demo",
  "version": "0.0.1",
  "images": {
    "docker.io/library/nginx:alpine": "sha256:da9c94bec1da829ebd52431a84502ec471c8e548ffb2cedbf36260fd9bd1d4d3",
    "docker.io/querycapistio/proxyv2:1.13.0-distroless": "sha256:5f69524bc2739d87030080adb7508cfe12cbc29ef0936c6d1300c69b31727dbb"
  },
  "manifests": [
  ]
}
```

