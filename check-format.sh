#!/bin/sh
set -ex

exitCode=0
# Make sure target branch exists
revisionArg=${1}; shift
revision=$(git rev-parse --verify "origin/${revisionArg}" 2>/dev/null) || {
    git fetch "--depth=${FETCH_DEPTH:-50}" origin "${revisionArg}"
    revision=$(git rev-parse --verify "origin/${revisionArg}" 2>/dev/null || \
        git rev-parse --verify "${revisionArg}" 2>/dev/null) || {
            echo "Can't find merge target '${revision}'!" >&2
            return 1
        }
}

[ -n "${revision}" ] || { echo "Error: Programmer is an idiot" >&2; exit 1; }

for commit in $(git rev-list --reverse "HEAD...^${revision}"); do
    printf "%s" "${commit}..."
    cfOutput="$(git -c color.ui=always clang-format --diff "${commit}^" "${commit}" -- "$@")";
    if [ -z "${cfOutput}" ] || [ "${cfOutput}" = "no modified files to format" ]; then
        printf "%b" "\e[32mPASSED\e[0m"
    else
        printf "%b" "\e[31;1mFAILED\e[0m"
        exitCode=1
        commitMessage=$(git log -1 --oneline --no-decorate "${commit}");
        echo "Commit ${commitMessage} introduces invalid format:";
        echo "${cfOutput}"
    fi
done
exit ${exitCode}
