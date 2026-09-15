# 🚨 Degrees of Escape: Mandatory Continuous Coding & Git Workflow

Whenever coding or developing in this repository, you MUST follow these four non-negotiable steps:

1. **Update `GAME_DEV_LOG.md`:**
   - Record a detailed new session log entry with design rationale, files modified, mechanics added, bug fixes, and test results.

2. **Update `HOW_WE_CODE.md`:**
   - Update the technical architecture manual (`HOW_WE_CODE.md`) so all scripts, mechanics, shaders, systems, and conventions stay completely in sync with the codebase.

3. **Verify with Automated Headless Tests:**
   - Run the Godot verification test suite (`tools/verify_route.gd`, `tools/verify_new_features.gd`, `tools/verify_full_flow.gd`) to confirm full pass rates before finalizing.

4. **Always Push to Git:**
   - Stage all changes, create a clean, descriptive Git commit, and run `git push origin master` to sync with the remote repository at `https://github.com/TalhaKun07-ipe/Degrees-of-Escape.git`.
