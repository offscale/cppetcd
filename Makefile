.PHONY: all clean pb test install

TEST_SOURCES=$(wildcard test/*.cc)

TEST_RUNNER=test_runner
TEST_OBJECTS=$(TEST_SOURCES:.cc=.o)
CC_OBJECTS=src/cppetcd.o src/etcd/etcdserver/etcdserverpb/rpc.pb.o src/etcd/etcdserver/etcdserverpb/rpc.grpc.pb.o \
src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.o src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.grpc.pb.o \
src/gogoproto/gogo.pb.o src/google/api/http.pb.o src/google/api/annotations.pb.o \
src/etcd/auth/authpb/auth.pb.o src/etcd/mvcc/mvccpb/kv.pb.o
CC_TARGET=libcppetcd.so
CC_SHARED=-shared

INCLUDES=`pkg-config --cflags protobuf grpc++ grpc`
override INCLUDES += -I./src
override CXXFLAGS += -std=c++11 -fPIC

LIBS=`pkg-config --libs protobuf grpc++ grpc`
override LDFLAGS += -lgrpc++_reflection -ldl -lglog

all: ${CC_TARGET}

${CC_TARGET}: ${CC_OBJECTS}
	$(CXX) $(LDFLAGS) $(LIBS) $(CC_OBJECTS) $(CC_SHARED) -o $@

test: ${TEST_RUNNER}
	@echo "To run test, locally-running etcd is required."
	LD_LIBRARY_PATH=. ./$< --gmock_verbose=info --gtest_stack_trace_depth=10

${TEST_RUNNER}: ${TEST_OBJECTS} $(CC_TARGET)
	${CXX} ${TEST_OBJECTS} -o $@ -L. -lcppetcd  -lgtest $(LDFLAGS) $(LIBS)

clean:
	-find ./ -name *.pb.h -exec rm -vf {} \;
	-find ./ -name *.pb.cc -exec rm -vf {} \;
	-rm -f $(CC_OBJECTS) $(TEST_OBJECTS) submodules

install: ${CC_TARGET}
	install -D ${CC_TARGET} $(prefix)/lib/${CC_TARGET}
	install -D src/cppetcd.h $(prefix)/include/cppetcd.h
## TODO: install protobuf headers here too

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -I. -c -o $@ $<

PROTOC=`which protoc`
PROTOC_GRPC_CPP_PLUGIN=`which grpc_cpp_plugin`
PROTOBUF_PROTOPATH=protobuf
GOOGLEAPIS_PROTOPATH=googleapis

PROTOC_OPT=--proto_path=$(PROTOBUF_PROTOPATH) \
	--plugin=protoc-gen-grpc=$(PROTOC_GRPC_CPP_PLUGIN) \
	--proto_path=$(GOOGLEAPIS_PROTOPATH) \
	--proto_path=. \
	--cpp_out=src --grpc_out=src

submodules:
	git submodule init
	git submodule update
	touch submodules

PROTOS=etcd/etcdserver/etcdserverpb/rpc.proto etcd/etcdserver/api/v3lock/v3lockpb/v3lock.proto \
protobuf/gogoproto/gogo.proto etcd/mvcc/mvccpb/kv.proto etcd/auth/authpb/auth.proto \
googleapis/google/api/annotations.proto googleapis/google/api/http.proto

${PROTOS}: submodules

src/cppetcd.cc: src/etcd/etcdserver/etcdserverpb/rpc.pb.h \
		 src/gogoproto/gogo.pb.h \
		 src/etcd/mvcc/mvccpb/kv.pb.h \
		 src/etcd/auth/authpb/auth.pb.h \
		 src/google/api/annotations.pb.h \
		 src/google/api/http.pb.h \
		 src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.h

src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.h : etcd/etcdserver/api/v3lock/v3lockpb/v3lock.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/etcd/etcdserver/etcdserverpb/rpc.pb.h : etcd/etcdserver/etcdserverpb/rpc.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/gogoproto/gogo.pb.h : protobuf/gogoproto/gogo.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/etcd/mvcc/mvccpb/kv.pb.h : etcd/mvcc/mvccpb/kv.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/etcd/auth/authpb/auth.pb.h : etcd/auth/authpb/auth.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/google/api/annotations.pb.h : googleapis/google/api/annotations.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/google/api/http.pb.h : googleapis/google/api/http.proto
	$(PROTOC) $(PROTOC_OPT) $<

src/etcd/etcdserver/etcdserverpb/rpc.pb.o : src/etcd/etcdserver/etcdserverpb/rpc.pb.cc
src/etcd/etcdserver/etcdserverpb/rpc.grpc.pb.o : src/etcd/etcdserver/etcdserverpb/rpc.pb.cc
src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.o : src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.cc
src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.grpc.pb.o : src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.cc
src/gogoproto/gogo.pb.o : src/gogoproto/gogo.pb.cc
src/google/api/http.pb.o : src/google/api/http.pb.cc
src/google/api/annotations.pb.o : src/google/api/annotations.pb.cc
src/etcd/auth/authpb/auth.pb.o : src/etcd/auth/authpb/auth.pb.cc
src/etcd/mvcc/mvccpb/kv.pb.o : src/etcd/mvcc/mvccpb/kv.pb.cc

src/etcd/etcdserver/etcdserverpb/rpc.pb.cc : src/etcd/etcdserver/etcdserverpb/rpc.pb.h
src/etcd/etcdserver/etcdserverpb/rpc.grpc.pb.cc : src/etcd/etcdserver/etcdserverpb/rpc.pb.h
src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.cc : src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.h
src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.grpc.pb.cc : src/etcd/etcdserver/api/v3lock/v3lockpb/v3lock.pb.h
src/gogoproto/gogo.pb.cc : src/gogoproto/gogo.pb.h
src/google/api/http.pb.cc : src/google/api/http.pb.h
src/google/api/annotations.pb.cc : src/google/api/annotations.pb.h
src/etcd/auth/authpb/auth.pb.cc : src/etcd/auth/authpb/auth.pb.h
src/etcd/mvcc/mvccpb/kv.pb.cc : src/etcd/mvcc/mvccpb/kv.pb.h

