
# Usage: add_crossbuild_executable(target_name SOURCE_PATH ${CHERIBSD_ROOT}/contrib/foo SOURCES ${SOUCES} ...)
function(add_crossbuild_executable _target) #  _srcs
    # add the crossbuilt version
    # only build the bootstrap libraries if BUILDING_BOOTSTRAP is set
    string(TOUPPER "${_target}" _target_upper_tmp)
    string(REPLACE "-" "_" _target_upper "${_target_upper_tmp}")
    cmake_parse_arguments(ACE "" "SOURCE_PATH" "SOURCES;LINK_LIBRARIES" ${ARGN})
    if(NOT ACE_SOURCES)
        message(FATAL_ERROR "add_crossbuild_executable() needs at least a SOURCES parameter")
    endif()
    set(_real_srcs "")
    foreach(_src ${ACE_SOURCES})
        if(ACE_SOURCE_PATH AND NOT IS_ABSOLUTE "${_src}")
            if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_src}")
                message(STATUS "${_src} exists")
                set(_src "${CMAKE_CURRENT_SOURCE_DIR}/${_src}")
            else()
                set(_src "${ACE_SOURCE_PATH}/${_src}")
            endif()
        endif()
        list(APPEND _real_srcs ${_src})
    endforeach()
    message(STATUS "${_real_srcs}")
    add_executable(${_target} ${_real_srcs})
    if(ACE_SOURCE_PATH)
        target_include_directories(${_target} PRIVATE ${ACE_SOURCE_PATH})
    endif()
    if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
        # link to libbsd
        target_link_libraries(${_target} Bootstrap::LibBSD)
        target_include_directories(${_target} SYSTEM BEFORE PRIVATE ${CMAKE_SOURCE_DIR}/crossbuild/include /usr/include)
        target_compile_definitions(${_target} PRIVATE LIBBSD_OVERLAY=1 _GNU_SOURCE=1 _ISOC11_SOURCE=1 _XOPEN_SOURCE=800)
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        # needed to get access to some APIs (e.g. pwcache)
        target_compile_definitions(${_target} PRIVATE -D_DARWIN_C_SOURCE=1)
        target_compile_options(${_target} PRIVATE -include ${CMAKE_SOURCE_DIR}/include/mac/pre-include.h)
    endif()
    if(ACE_LINK_LIBRARIES)
        target_link_libraries(${_target} ${ACE_LINK_LIBRARIES})
    endif()
    install(TARGETS ${_target} RUNTIME DESTINATION bin)
endfunction()

function(add_crossbuild_library _target)
    add_library(${_target} ${ARGN})
    if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
        # link to libbsd
        target_link_libraries(${_target} Bootstrap::LibBSD)
        target_include_directories(${_target} SYSTEM BEFORE PRIVATE ${CMAKE_SOURCE_DIR}/crossbuild/include /usr/include)
        target_compile_definitions(${_target} PRIVATE LIBBSD_OVERLAY=1 _GNU_SOURCE=1 _ISOC11_SOURCE=1 _XOPEN_SOURCE=800)
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        # needed to get access to some APIs (e.g. pwcache)
        target_compile_definitions(${_target} PRIVATE -D_DARWIN_C_SOURCE=1)
        target_compile_options(${_target} PRIVATE -include ${CMAKE_SOURCE_DIR}/include/mac/pre-include.h)
    endif()
endfunction()