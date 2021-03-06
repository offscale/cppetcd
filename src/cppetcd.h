#pragma once

#include <string>
#include <vector>
#include <grpc++/grpc++.h>

namespace etcd {
  struct KeyValueEvent {
    std::string key;
    std::string value;
    long long int version;
    long long int lease;
    enum EventType { PUT = 0, DELETE } event_type;

    KeyValueEvent(const std::string& key, const std::string& value,
                  long long int version, long long int lease,
                  enum EventType event_type):
      key(key), value(value), version(version), lease(lease), event_type(event_type){
    }
  };

  class EventWatcher {
  public:
    EventWatcher(){}
    virtual ~EventWatcher(){}

    virtual void HandleEvents(const std::vector<KeyValueEvent>&) = 0;
    virtual bool StopHandling() const = 0;
  };

  class Client final {
  public:
    Client(const std::vector<std::string>&);
    ~Client();

    // Connect to etcd
    grpc::Status Connect();
    grpc::Status Disconnect();
    bool Connected() const ;

    long long LeaseId() const;

    // only single key with exact match, returning version
    grpc::Status Get(const std::string& key, std::string& value, long long * rev);
    // overwrite any key
    grpc::Status Put(const std::string& key, const std::string& value, long long rev,
                     bool ephemeral=true);
    grpc::Status Delete(const std::string& key, long long rev);
    grpc::Status List(const std::string& prefix, std::vector<std::pair<std::string, std::string>>&);

    grpc::Status Watch(const std::string& prefix, EventWatcher& watcher);

    grpc::Status Lock(const std::string& name, unsigned int timeout_ms);
    grpc::Status Unlock(const std::string& name);
    bool HasLock(const std::string& name);
    // Wait is also needed, but can be replaced with periodic polling for my use case.
    // Someday someone wraps it.
    grpc::Status KeepAlive(bool forever=true);
  private:
    Client();

    long long lease_id_;
    unsigned long lease_limit_; // lease limit in absolute milliseconds
    std::vector<std::string> hosts_;
    std::shared_ptr<grpc::ChannelInterface> channel_;
    enum state { DISCONNECTED, CONNECTED } state_;;

    std::map<std::string, std::string> lock_keys_;
  };

  // returns current epoch time in milliseconds from monotonic clock
  // using clock_gettime(2) with CLOCK_BOOTTIME
  unsigned long now();
};
