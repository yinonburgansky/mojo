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
    IdxType: Indexer, //, container_name: StringLiteral
](idx: IdxType, length: UInt) -> UInt:
    """Normalize the given index value to a valid index value for the given container length.

    If the provided value is negative, the `index + container_length` is returned.

    Parameters:
        IdxType: A type that can be used as an index.
        container_name: The name of the container. Used for the error message.

    Args:
        idx: The index value to normalize.
        length: The container length to normalize the index for.

    Returns:
        The normalized index value.
    """

    @parameter
    if (
        _type_is_eq[IdxType, UInt]()
        or _type_is_eq[IdxType, UInt8]()
        or _type_is_eq[IdxType, UInt16]()
        or _type_is_eq[IdxType, UInt32]()
        or _type_is_eq[IdxType, UInt64]()
    ):
        var i = UInt(index(idx))
        debug_assert[assert_mode="safe", cpu_only=True](
            i < length,
            container_name,
            " index out of bounds: ",
            i,
            " should be less than ",
            length,
        )
        return i
    else:
        # Optimize for the common case:
        # Proper comparison between Int and UInt is slower and containers with
        # more than Int.MAX elements are rare.
        # Don't use "safe" since this is considered an overflow error.
        debug_assert(
            length <= UInt(Int.MAX),
            "Overflow Error: ",
            container_name,
            " length is grater than Int.MAX (",
            length,
            "). Consider indexing with the UInt type.",
        )
        var i = Int(idx)
        # TODO: Consider a way to construct the error message after the assert has failed
        # something like "Indexing into an empty container" if length == 0 else "..."
        debug_assert[assert_mode="safe", cpu_only=True](
            -Int(length) <= i < Int(length),
            container_name,
            " has length: ",
            length,
            " index out of bounds: ",
            i,
            " should be between ",
            -Int(length),
            " and ",
            length - 1,
        )
        if i >= 0:
            return i
        return i + length


@always_inline
fn normalize_index[
    IdxType: Indexer, //, container_name: StringLiteral
](idx: IdxType, length: Int) -> Int:
    """Normalize the given index value to a valid index value for the given container length.

    If the provided value is negative, the `index + container_length` is returned.

    Parameters:
        IdxType: A type that can be used as an index.
        container_name: The name of the container. Used for the error message.

    Args:
        idx: The index value to normalize.
        length: The container length to normalize the index for.

    Returns:
        The normalized index value.
    """
    return Int(normalize_index[container_name](idx, UInt(length)))
