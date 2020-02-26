
if("${TARS_CPP_COMMON}" STREQUAL "")

set(TARS_CPP_COMMON "1")

set(TARS_VERSION "2.0.0")
add_definitions(-DTARS_VERSION="${TARS_VERSION}")

if(WIN32)
option(TARS_MYSQL "option for mysql" OFF)
else()
option(TARS_MYSQL "option for mysql" ON)
endif()

option(TARS_SSL "option for ssl" OFF)
option(TARS_HTTP2 "option for http2" OFF)
option(TARS_PROTOBUF "option for protocol" OFF)
#option(TARS_ZLIB "option for zip" OFF)

if(TARS_MYSQL)
add_definitions(-DTARS_MYSQL=1)
endif()

if(TARS_SSL)
add_definitions(-DTARS_SSL=1)
endif()

if(TARS_HTTP2)
add_definitions(-DTARS_HTTP2=1)
endif()

if(TARS_PROTOBUF)
add_definitions(-DTARS_PROTOBUF=1)
endif()

#if(TARS_ZLIB)
#add_definitions(-DTARS_ZLIB=1)
#endif()

set(CMAKE_VERBOSE_MAKEFILE off)

#for coverage statistics
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -g -O2 -Wall -Wno-deprecated -fprofile-arcs -ftest-coverage")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -O2 -Wall -Wno-deprecated -fprofile-arcs -ftest-coverage")

#set(CMAKE_BUILD_TYPE "Debug")

set(CMAKE_BUILD_TYPE "Release" CACHE STRING "set build type to release default")
IF (CMAKE_BUILD_TYPE STREQUAL "")
    set(CMAKE_BUILD_TYPE "Release")
ENDIF()


#编译的可执行程序输出目录
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(_USE_OPENTRACKING $ENV{_USE_OPENTRACKING})
if(_USE_OPENTRACKING)
set(OPENTRACKING_INC "/usr/local/include")
add_definitions(-D_USE_OPENTRACKING=${_USE_OPENTRACKING})
endif()

#-------------------------------------------------------------

if("${INSTALL_PREFIX}" STREQUAL "")
IF (UNIX)
set(INSTALL_PREFIX "/usr/local/tars/cpp")
ELSE()
set(INSTALL_PREFIX "c:\\tars\\cpp")
ENDIF()
set(CMAKE_INSTALL_PREFIX ${INSTALL_PREFIX})
endif()


#-------------------------------------------------------------

set(THIRDPARTY_PATH "${CMAKE_BINARY_DIR}/src")
if(TARS_MYSQL)
    set(MYSQL_DIR_INC "${THIRDPARTY_PATH}/mysql-lib/include")
    set(MYSQL_DIR_LIB "${THIRDPARTY_PATH}/mysql-lib/libmysql")
    include_directories(${MYSQL_DIR_INC})
    link_directories(${MYSQL_DIR_LIB})
endif()

if(TARS_PROTOBUF)
    set(PROTOBUF_DIR_INC "${THIRDPARTY_PATH}/protobuf-lib/src")
    set(PROTOBUF_DIR_LIB "${THIRDPARTY_PATH}/protobuf-lib")
    include_directories(${PROTOBUF_DIR_INC})
    link_directories(${PROTOBUF_DIR_LIB})
endif()

#if(TARS_ZLIB)
#    set(ZLIB_DIR_INC "${THIRDPARTY_PATH}/z-lib")
#    set(ZLIB_DIR_LIB "${THIRDPARTY_PATH}/z-lib")
#    include_directories(${ZLIB_DIR_INC})
#    link_directories(${ZLIB_DIR_LIB})
#endif()

if(TARS_HTTP2)
    set(NGHTTP2_DIR_INC "${THIRDPARTY_PATH}/nghttp2-lib/lib/includes/")
    set(NGHTTP2_DIR_LIB "${THIRDPARTY_PATH}/nghttp2-lib/lib")
    include_directories(${NGHTTP2_DIR_INC})
    link_directories(${NGHTTP2_DIR_LIB})
endif()

if(TARS_SSL)
    set(SSL_DIR_INC "${THIRDPARTY_PATH}/openssl-lib/include/")
    set(SSL_DIR_LIB "${THIRDPARTY_PATH}/openssl-lib")
    include_directories(${SSL_DIR_INC})
    link_directories(${SSL_DIR_LIB})
endif()

#-------------------------------------------------------------

set(LIB_MYSQL)
set(LIB_HTTP2)
set(LIB_SSL)
set(LIB_CRYPTO)
#set(LIB_ZLIB)
set(LIB_PROTOBUF)

IF (WIN32)
    if(TARS_MYSQL)
        set(LIB_MYSQL "libmysql")
    endif()
    if(TARS_HTTP2)
        set(LIB_HTTP2 "libnghttp2_static")
    endif()
    if(TARS_SSL)
        set(LIB_SSL "libssl")
        set(LIB_CRYPTO "libcrypto")
    endif()
ELSE()
    link_libraries(pthread dl)
    if(TARS_MYSQL)
        set(LIB_MYSQL "mysqlclient")
    endif()

    if(TARS_HTTP2)
        set(LIB_HTTP2 "nghttp2_static")
    endif()
    
    if(TARS_SSL)
        set(LIB_SSL "ssl")
        set(LIB_CRYPTO "crypto")
    endif()

    if(TARS_PROTOBUF)
        set(LIB_PROTOBUF "protoc")
    endif()    
ENDIF()

#-------------------------------------------------------------

if(TARS_HTTP2)
    link_libraries(${LIB_HTTP2})
endif()

if(TARS_SSL)
    link_libraries(${LIB_SSL} ${LIB_CRYPTO})
endif()

include(ExternalProject)

if(TARS_PROTOBUF)
ExternalProject_Add(${LIB_PROTOBUF}
    URL http://cdn.tarsyun.com/src/protobuf-cpp-3.11.3.tar.gz
    PREFIX    ${CMAKE_BINARY_DIR}
    INSTALL_DIR ${CMAKE_SOURCE_DIR}
    CONFIGURE_COMMAND cmake cmake
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/protobuf-lib
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make -j4 libprotoc
    LOG_CONFIGURE 1
    LOG_BUILD 1
    INSTALL_COMMAND ${CMAKE_COMMAND} -E echo "install"
    URL_MD5 fb59398329002c98d4d92238324c4187
    )
endif()

if(TARS_MYSQL)
ExternalProject_Add(${LIB_MYSQL}
        URL http://cdn.tarsyun.com/src/mysql-5.6.26.tar.gz
        PREFIX    ${CMAKE_BINARY_DIR}
        INSTALL_DIR ${CMAKE_SOURCE_DIR}
        CONFIGURE_COMMAND cmake . -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DDISABLE_SHARED=1
        SOURCE_DIR ${CMAKE_BINARY_DIR}/src/mysql-lib
        BUILD_IN_SOURCE 1
        BUILD_COMMAND make mysqlclient
        LOG_CONFIGURE 1
        LOG_BUILD 1
        INSTALL_COMMAND ${CMAKE_COMMAND} -E echo "install"
        URL_MD5 c537c08c1276abc79d76e8e562bbcea5
        #URL_MD5 9d225528742c882d5b1e4a40b0877690
        )

INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/mysql-lib/include/mysql DESTINATION include)
if(WIN32)
    INSTALL(FILES ${CMAKE_BINARY_DIR}/src/mysql-lib/libmysql/${LIB_MYSQL}.dll DESTINATION lib)
else()
    INSTALL(FILES ${CMAKE_BINARY_DIR}/src/mysql-lib/libmysql/lib${LIB_MYSQL}.a DESTINATION lib)
endif()

endif()

if(TARS_HTTP2)
ExternalProject_Add(${LIB_HTTP2}
    URL http://cdn.tarsyun.com/src/nghttp2-1.40.0.tar.gz
    PREFIX    ${CMAKE_BINARY_DIR}
    INSTALL_DIR ${CMAKE_SOURCE_DIR}
    CONFIGURE_COMMAND cmake . -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON -DENABLE_LIB_ONLY=ON
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/nghttp2-lib
    BUILD_IN_SOURCE 1
    LOG_BUILD 1
    LOG_CONFIGURE 1
    BUILD_COMMAND make
    INSTALL_COMMAND ${CMAKE_COMMAND} -E echo "install"
    URL_MD5 5df375bbd532fcaa7cd4044b54b1188d
#    URL_MD5 9521689460b4a57912acd3f88f301a3a
    )

INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/nghttp2-lib/lib/includes/nghttp2 DESTINATION include)
INSTALL(FILES ${CMAKE_BINARY_DIR}/src/nghttp2-lib/lib/lib${LIB_HTTP2}.a DESTINATION lib)    

endif()

if(TARS_SSL)
ExternalProject_Add(${LIB_SSL}
    DEPENDS ${LIB_ZLIB}
    URL http://cdn.tarsyun.com/src/openssl-1.1.1d.tar.gz
    PREFIX    ${CMAKE_BINARY_DIR}
    INSTALL_DIR ${CMAKE_SOURCE_DIR}
    CONFIGURE_COMMAND ./config
    SOURCE_DIR ${CMAKE_BINARY_DIR}/src/openssl-lib
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make
    LOG_CONFIGURE 1
    LOG_BUILD 1
    INSTALL_COMMAND ${CMAKE_COMMAND} -E echo "install"
    URL_MD5 3be209000dbc7e1b95bcdf47980a3baa
    #URL_MD5 15e21da6efe8aa0e0768ffd8cd37a5f6
    )

INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/openssl-lib/include/openssl DESTINATION include)
INSTALL(FILES 
    ${CMAKE_BINARY_DIR}/src/openssl-lib/lib${LIB_SSL}.a 
    ${CMAKE_BINARY_DIR}/src/openssl-lib/lib${LIB_CRYPTO}.a 
    DESTINATION lib)


endif()

add_custom_target(thirdparty DEPENDS ${LIB_MYSQL} ${LIB_HTTP2} ${LIB_SSL})

#-------------------------------------------------------------
IF (APPLE)
link_libraries(iconv)
ENDIF(APPLE)

set(PLATFORM)
IF (UNIX)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -std=c++11  -Wno-deprecated -fno-strict-aliasing -Wno-overloaded-virtual")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-builtin-macro-redefined -D__FILE__='\"$(notdir $(abspath $<))\"'")
    
    set(CMAKE_CXX_FLAGS_DEBUG "$ENV{CXXFLAGS} -Wall -g")
    set(CMAKE_CXX_FLAGS_RELEASE "$ENV{CXXFLAGS} -O2 -Wall -fno-strict-aliasing")

    set(PLATFORM "linux")
    IF(APPLE)
        set(PLATFORM "mac")
        SET(CMAKE_C_ARCHIVE_CREATE   "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
        SET(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
        SET(CMAKE_C_ARCHIVE_FINISH   "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
        SET(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
    ENDIF(APPLE)

ELSEIF (WIN32)
    set(PLATFORM "window")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4101 /wd4244 /wd4996 /wd4091 /wd4503 /wd4819 /wd4200 /wd4800")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /bigobj " )

ELSE ()
    MESSAGE(STATUS "================ ERROR: This platform is unsupported!!! ================")
ENDIF (UNIX)

#-------------------------------------------------------------
IF(WIN32)
set(TARS2CPP "${CMAKE_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/tars2cpp.exe")
ELSE()
set(TARS2CPP "${CMAKE_BINARY_DIR}/bin/tars2cpp")
ENDIF()

#-------------------------------------------------------------

IF(WIN32)
include_directories(${CMAKE_SOURCE_DIR}/util/src/epoll_windows)
ENDIF()

message("----------------------------------------------------")

message("CMAKE_SOURCE_DIR:          ${CMAKE_SOURCE_DIR}")
message("CMAKE_BINARY_DIR:          ${CMAKE_BINARY_DIR}")
message("PROJECT_SOURCE_DIR:        ${PROJECT_SOURCE_DIR}")
message("CMAKE_BUILD_TYPE:          ${CMAKE_BUILD_TYPE}")
message("PLATFORM:                  ${PLATFORM}")
message("INSTALL_PREFIX:            ${INSTALL_PREFIX}")
message("BIN:                       ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}") 
message("TARS2CPP:                  ${TARS2CPP}") 
#-------------------------------------------------------------

message("----------------------------------------------------")
message("TARS_MYSQL:                ${TARS_MYSQL}")
message("TARS_HTTP2:                ${TARS_HTTP2}")
message("TARS_SSL:                  ${TARS_SSL}")
#message("TARS_ZLIB:                 ${TARS_ZLIB}")
message("TARS_PROTOBUF:             ${TARS_PROTOBUF}")

endif()
