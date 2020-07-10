# GoogleCloudDatastore

This project is WIP and should not be used in production.

A  Swift package as client for [Google Cloud Datastore](https://cloud.google.com/datastore).

## Development

### Updating gRPC-generated Swift-soruces.

1. Make sure the submodule `googleapis` is checked out.
2. Make sure executable `protoc` is installed.
3. Make sure swift plugins for protoc is installed (`protoc-gen-swift` and `protoc-gen-swiftgrpc`)
4. 
```bash
cd googleapis/
protoc google/datastore/v1/*.proto google/type/latlng.proto \
  --swift_out=. \
  --swiftgrpc_out=Client=true,Server=false:.

rm ../Sources/GoogleCloudDatastore/gRPC\ Generated/*.swift
mv google/datastore/v1/*.swift \
   google/type/*.swift \
   ../Sources/GoogleCloudDatastore/gRPC\ Generated

```
