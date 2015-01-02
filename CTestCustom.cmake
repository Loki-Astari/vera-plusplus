set(CTEST_CUSTOM_COVERAGE_EXCLUDE
  ${CTEST_CUSTOM_COVERAGE_EXCLUDE}
  # exclude cpptcl - this is an external lib used by vera++
  "/cpptcl"
  "/boost-prefix"
  "/lua-prefix"
  "/luabind-prefix"
)

SET(CTEST_CUSTOM_WARNING_EXCEPTION
  # ASM warnings generated by the compiler on the raspberry pi
  "Warning: swp.b. use is deprecated for this architecture"
  # non fixable boost configuration warning
  "warning: Graph library does not contain MPI-based parallel components."
)
