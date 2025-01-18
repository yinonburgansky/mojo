# ===----------------------------------------------------------------------=== #
# Copyright (c) 2024, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #
"""The utilities provided in this module help normalize the access
to data elements in arrays."""

from sys.intrinsics import _type_is_eq


@always_inline
fn normalize_index[
    I: Indexer, ContainerType: Sized, //, container_name: StringLiteral
](idx: I, container: ContainerType) -> UInt:
    """Normalize the given index value to a valid index value for the given container length.

    If the provided value is negative, the `index + container_length` is returned.

    Parameters:
        I: A type that can be used as an index.
        ContainerType: The type of the container. Must have a `__len__` method.
        container_name: The name of the container. Used for the error message.

    Args:
        idx: The index value to normalize.
        container: The container to normalize the index for.

    Returns:
        The normalized index value.
    """
    debug_assert[assert_mode="safe", cpu_only=True](
        len(container) > 0,
        "indexing into a ",
        container_name,
        " that has 0 elements",
    )

    @parameter
    if _type_is_eq[I, UInt]():
        var i = rebind[UInt](idx)
        debug_assert[assert_mode="safe", cpu_only=True](
            i < len(container),
            container_name,
            " index out of bounds: ",
            i,
            " should be less than ",
            len(container),
        )
        return i
    else:
        var i = Int(idx)
        debug_assert[assert_mode="safe", cpu_only=True](
            -len(container) <= i < len(container),
            container_name,
            " has length: ",
            len(container),
            " index out of bounds: ",
            i,
            " should be between ",
            -len(container),
            " and ",
            len(container) - 1,
        )
        if i >= 0:
            return i
        return i + len(container)
