include(${TINYREFL_SOURCE_DIR}/utils.cmake)

function(tinyrefl_tool)
    cmake_parse_arguments(
        ARGS
        ""
        "TARGET"
        "HEADERS;COMPILE_OPTIONS;COMPILE_DEFINITIONS"
        ${ARGN}
    )

    if(NOT ARGS_TARGET)
        message(FATAL_ERROR "No TARGET given to tinyrefl tool driver")
    endif()
    if(NOT ARGS_HEADERS)
        message(FATAL_ERROR "No HEADERS given to tinyrefl tool driver")
    endif()

    target_link_libraries(${ARGS_TARGET} PUBLIC tinyrefl)

    get_target_include_directories(${ARGS_TARGET} target_includes)
    clangxx_stdlib_includes(stdlibc++ stdlib_includes)
    get_target_property(interface_target_options ${ARGS_TARGET} INTERFACE_COMPILE_OPTIONS)
    get_target_property(interface_target_definitions ${ARGS_TARGET} INTERFACE_COMPILE_DEFINITIONS)
    get_target_property(target_options ${ARGS_TARGET} COMPILE_OPTIONS)
    get_target_property(target_definitions ${ARGS_TARGET} COMPILE_DEFINITIONS)
    set(compile_options ${ARGS_COMPILE_OPTIONS})
    set(compile_definitions ${ARGS_COMPILE_DEFINITIONS})

    if(interface_target_options)
        list(APPEND compile_options ${interface_target_options})
    endif()
    if(target_options)
        list(APPEND compile_options ${target_options})
    endif()
    if(interface_target_definitions)
        list(APPEND compile_definitions ${interface_target_definitions})
    endif()
    if(target_definitions)
        list(APPEND compile_definitions ${target_definitions})
    endif()

    if(TINYREFL_CROSS_BUILDING)
        set(system_includes "/usr/include")
        foreach(incl ${system_includes})
            list(APPEND sysroot_system_includes "${CMAKE_SYSROOT}${incl}")
        endforeach()
    endif()

    foreach(include ${target_includes} ${stdlib_includes} ${sysroot_system_includes})
        list(APPEND includes "-I${include}")
    endforeach()

    foreach(definition ${compile_definitions})
        list(APPEND definitions "-D${definition}")
    endforeach()

    foreach(header ${ARGS_HEADERS})
        add_prebuild_command(TARGET ${ARGS_TARGET}
            NAME "tinyrefl_tool_${ARGS_TARGET}_${header}"
            COMMAND ${TINYREFL_TOOL_EXECUTABLE} ${header} -std=c++${CMAKE_CXX_STANDARD} ${definitions} ${includes} ${compile_options}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Generating tinyrefl metadata for ${ARGS_TARGET}/${header}"
            DEPENDS ${TINYREFL_TOOL_TARGET}
        )
    endforeach()

    string(REGEX REPLACE ";" " " header_list "${ARGS_HEADERS}")
    string(REGEX REPLACE ";" " " includes_list "${includes}")
    string(REGEX REPLACE ";" " " options_list "${compile_options}")
    string(REGEX REPLACE ";" " " definitions_list "${definitions}")
    message(STATUS ">> Tinyrefl driver on ${ARGS_TARGET}: tinyrefl ${header_list} -std=c++${CMAKE_CXX_STANDARD} ${definitions_list} ${includes_list} ${options_list}")
endfunction()

