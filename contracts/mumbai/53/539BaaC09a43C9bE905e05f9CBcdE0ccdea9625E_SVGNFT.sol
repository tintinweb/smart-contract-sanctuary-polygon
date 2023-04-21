// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8, memmove, memcmp, memeq, mstoreN, leftMask } from "./utils/mem.sol";
import { memchr, memrchr } from "./utils/memchr.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

import { SliceIter, SliceIter__ } from "./SliceIter.sol";

/**
 * @title A view into a contiguous sequence of 1-byte items.
 */
type Slice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error Slice__OutOfBounds();
error Slice__LengthMismatch();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library Slice__ {
    /**
     * @dev Converts a `bytes` to a `Slice`.
     * The bytes are not copied.
     * `Slice` points to the memory of `bytes`, right after the length word.
     */
    function from(bytes memory b) internal pure returns (Slice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(b, 0x20)
        }
        return fromRawParts(_ptr, b.length);
    }

    /**
     * @dev Creates a new `Slice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(PackPtrLen.pack(_ptr, _len));
    }

    /**
     * @dev Like `fromRawParts`, but does NO validity checks.
     * _ptr and _len MUST fit into uint128.
     * The caller MUST guarantee memory-safety.
     * Primarily for internal use.
     */
    function fromUnchecked(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(
            (_ptr << 128) | (_len & PackPtrLen.MASK_LEN)
        );
    }
}

/**
 * @dev Alternative to Slice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for bytes;
 * ```
 */
function toSlice(bytes memory b) pure returns (Slice slice) {
    return Slice__.from(b);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    ptr, len, isEmpty,
    // conversion
    toBytes, toBytes32,
    keccak,
    // concatenation
    add, join,
    // copy
    copyFromSlice, copyFromValue, copyFromValueRightAligned,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    get, first, last,
    splitAt, getSubslice, getBefore, getAfter, getAfterStrict,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    // iteration
    iter
} for Slice global;

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes.
 */
function len(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(Slice self) pure returns (bool) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `Slice` to a new `bytes`.
 * The `Slice` will NOT point to the new `bytes`.
 */
function toBytes(Slice self) view returns (bytes memory b) {
    b = new bytes(self.len());
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), self.len());
    return b;
}

/**
 * @dev Fills a `bytes32` (value type) with the first 32 bytes of `Slice`.
 * Goes from left(MSB) to right(LSB).
 * If len < 32, the leftover bytes are zeros.
 */
function toBytes32(Slice self) pure returns (bytes32 b) {
    uint256 selfPtr = self.ptr();

    // mask removes any trailing bytes
    uint256 selfLen = self.len();
    uint256 mask = leftMask(selfLen);

    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(selfPtr), mask)
    }
    return b;
}

/**
 * @dev Returns keccak256 of all the bytes of `Slice`.
 * Note that for any `bytes memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(Slice self) pure returns (bytes32 result) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    /// @solidity memory-safe-assembly
    assembly {
        result := keccak256(selfPtr, selfLen)
    }
}

/**
 * @dev Concatenates two `Slice`s into a newly allocated `bytes`.
 */
function add(Slice self, Slice other) view returns (bytes memory b) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();

    b = new bytes(selfLen + otherLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), selfLen);
    memmove(bPtr + selfLen, other.ptr(), otherLen);
    return b;
}

/**
 * @dev Flattens an array of `Slice`s into a single newly allocated `bytes`,
 * placing `self` as the separator between each.
 *
 * TODO this is the wrong place for this method, but there are no other places atm
 * (since there's no proper chaining/reducers/anything)
 */
function join(Slice self, Slice[] memory slices) view returns (bytes memory b) {
    uint256 slicesLen = slices.length;
    if (slicesLen == 0) return "";

    uint256 selfLen = self.len();
    uint256 repetitionLen;
    // -1 is safe because of ==0 check earlier
    unchecked {
        repetitionLen = slicesLen - 1;
    }
    // add separator repetitions length
    uint256 totalLen = selfLen * repetitionLen;
    // add slices length
    for (uint256 i; i < slicesLen; i++) {
        totalLen += slices[i].len();
    }

    b = new bytes(totalLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }
    for (uint256 i; i < slicesLen; i++) {
        Slice slice = slices[i];
        // copy slice
        memmove(bPtr, slice.ptr(), slice.len());
        bPtr += slice.len();
        // copy separator (skips the last cycle)
        if (i < repetitionLen) {
            memmove(bPtr, self.ptr(), selfLen);
            bPtr += selfLen;
        }
    }
}

/**
 * @dev Copies all elements from `src` into `self`.
 * The length of `src` must be the same as `self`.
 */
function copyFromSlice(Slice self, Slice src) view {
    uint256 selfLen = self.len();
    if (selfLen != src.len()) revert Slice__LengthMismatch();

    memmove(self.ptr(), src.ptr(), selfLen);
}

/**
 * @dev Copies `length` bytes from `value` into `self`, starting from MSB.
 */
function copyFromValue(Slice self, bytes32 value, uint256 length) pure {
    if (length > self.len() || length > 32) {
        revert Slice__OutOfBounds();
    }

    mstoreN(self.ptr(), value, length);
}

/**
 * @dev Shifts `value` to MSB by (32 - `length`),
 * then copies `length` bytes from `value` into `self`, starting from MSB.
 * (this is for right-aligned values like uint32, so you don't have to shift them to MSB yourself)
 */
function copyFromValueRightAligned(Slice self, bytes32 value, uint256 length) pure {
    if (length > self.len() || length > 32) {
        revert Slice__OutOfBounds();
    }
    if (length < 32) {
        // safe because length < 32
        unchecked {
            value <<= (32 - length) * 8;
        }
    }

    mstoreN(self.ptr(), value, length);
}

/**
 * @dev Compare slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(Slice self, Slice other) pure returns (int256 result) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();
    uint256 minLen = selfLen;
    if (otherLen < minLen) {
        minLen = otherLen;
    }

    result = memcmp(self.ptr(), other.ptr(), minLen);
    if (result == 0) {
        // the longer slice is greater than its prefix
        // (lengths take only 16 bytes, so signed sub is safe)
        unchecked {
            return int256(selfLen) - int256(otherLen);
        }
    }
    // if not equal, return the diff sign
    return result;
}

/// @dev self == other
/// Note more efficient than cmp
function eq(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return false;
    return memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev self != other
/// Note more efficient than cmp
function ne(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return true;
    return !memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev `self` < `other`
function lt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Returns the byte at `index`.
 * Reverts if index is out of bounds.
 */
function get(Slice self, uint256 index) pure returns (uint8 item) {
    if (index >= self.len()) revert Slice__OutOfBounds();

    // ptr and len are uint128 (because PackPtrLen); index < len
    unchecked {
        return mload8(self.ptr() + index);
    }
}

/**
 * @dev Returns the first byte of the slice.
 * Reverts if the slice is empty.
 */
function first(Slice self) pure returns (uint8 item) {
    if (self.len() == 0) revert Slice__OutOfBounds();
    return mload8(self.ptr());
}

/**
 * @dev Returns the last byte of the slice.
 * Reverts if the slice is empty.
 */
function last(Slice self) pure returns (uint8 item) {
    uint256 selfLen = self.len();
    if (selfLen == 0) revert Slice__OutOfBounds();
    // safe because selfLen > 0 (ptr+len is implicitly safe)
    unchecked {
        return mload8(self.ptr() + (selfLen - 1));
    }
}

/**
 * @dev Divides one slice into two at an index.
 */
function splitAt(Slice self, uint256 mid) pure returns (Slice, Slice) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    if (mid > selfLen) revert Slice__OutOfBounds();
    return (Slice__.fromUnchecked(selfPtr, mid), Slice__.fromUnchecked(selfPtr + mid, selfLen - mid));
}

/**
 * @dev Returns a subslice [start:end] of `self`.
 * Reverts if start/end are out of bounds.
 */
function getSubslice(Slice self, uint256 start, uint256 end) pure returns (Slice) {
    if (!(start <= end && end <= self.len())) revert Slice__OutOfBounds();
    // selfPtr + start is safe because start <= selfLen (pointers are implicitly safe)
    // end - start is safe because start <= end
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + start, end - start);
    }
}

/**
 * @dev Returns a subslice [:index] of `self`.
 * Reverts if `index` > length.
 */
function getBefore(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    return Slice__.fromUnchecked(self.ptr(), index);
}

/**
 * @dev Returns a subslice [index:] of `self`.
 * Reverts if `index` > length.
 */
function getAfter(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    // safe because index <= selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns a non-zero subslice [index:] of `self`.
 * Reverts if `index` >= length.
 */
function getAfterStrict(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index >= selfLen) revert Slice__OutOfBounds();
    // safe because index < selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 offsetPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    // low-level alternative to `first()` (safe because patLen != 0)
    uint8 patFirst = mload8(patPtr);

    while (true) {
        uint256 index = memchr(offsetPtr, offsetLen, patFirst);
        // not found
        if (index == type(uint256).max) return type(uint256).max;

        // move pointer to the found byte
        // safe because index < offsetLen (ptr+len is implicitly safe)
        unchecked {
            offsetPtr += index;
            offsetLen -= index;
        }
        // can't find, pattern won't fit after index
        if (patLen > offsetLen) {
            return type(uint256).max;
        }

        if (memeq(offsetPtr, patPtr, patLen)) {
            // found, return offset index
            return (offsetPtr - self.ptr());
        } else if (offsetLen == 1) {
            // not found and this was the last character
            return type(uint256).max;
        } else {
            // not found and can keep going;
            // increment pointer, memchr shouldn't receive what it returned (otherwise infinite loop)
            unchecked {
                // safe because offsetLen > 1 (see offsetLen -= index, and index < offsetLen)
                offsetPtr++;
                offsetLen--;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 selfPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    uint8 patLast = pattern.last();
    // using indexes instead of lengths saves some gas on redundant increments/decrements
    uint256 patLastIndex;
    // safe because of patLen == 0 check earlier
    unchecked {
        patLastIndex = patLen - 1;
    }

    while (true) {
        uint256 endIndex = memrchr(selfPtr, offsetLen, patLast);
        // not found
        if (endIndex == type(uint256).max) return type(uint256).max;
        // can't find, pattern won't fit after index
        if (patLastIndex > endIndex) return type(uint256).max;

        // (endIndex - patLastIndex is safe because of the check just earlier)
        // (selfPtr + startIndex is safe because startIndex <= endIndex < offsetLen <= selfLen)
        // (ptr+len is implicitly safe)
        unchecked {
            // need startIndex, but memrchr returns endIndex
            uint256 startIndex = endIndex - patLastIndex;

            if (memeq(selfPtr + startIndex, patPtr, patLen)) {
                // found, return index
                return startIndex;
            } else if (endIndex > 0) {
                // not found and can keep going;
                // "decrement pointer", memrchr shouldn't receive what it returned
                // (index is basically a decremented length already, saves an op)
                // (I could even use 1 variable for both, but that'd be too confusing)
                offsetLen = endIndex;
                // an explicit continue is better for optimization here
                continue;
            } else {
                // not found and this was the last character
                return type(uint256).max;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this `bytes` slice.
 */
function contains(Slice self, Slice pattern) pure returns (bool) {
    return self.find(pattern) != type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a prefix of this slice.
 */
function startsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice prefix = self;
    // make prefix's length equal patLen
    if (selfLen > patLen) {
        prefix = self.getBefore(patLen);
    }
    return prefix.eq(pattern);
}

/**
 * @dev Returns true if the given pattern matches a suffix of this slice.
 */
function endsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice suffix = self;
    // make suffix's length equal patLen
    if (selfLen > patLen) {
        suffix = self.getAfter(selfLen - patLen);
    }
    return suffix.eq(pattern);
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    (Slice prefix, Slice suffix) = self.splitAt(patLen);

    if (prefix.eq(pattern)) {
        return suffix;
    } else {
        return self;
    }
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    uint256 index;
    // safe because selfLen >= patLen
    unchecked {
        index = selfLen - patLen;
    }
    (Slice prefix, Slice suffix) = self.splitAt(index);

    if (suffix.eq(pattern)) {
        return prefix;
    } else {
        return self;
    }
}

/**
 * @dev Returns an iterator over the slice.
 * The iterator yields items from either side.
 */
function iter(Slice self) pure returns (SliceIter memory) {
    return SliceIter__.from(self);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8 } from "./utils/mem.sol";
import { Slice, Slice__ } from "./Slice.sol";

/**
 * @title Slice iterator.
 * @dev This struct is created by the iter method on `Slice`.
 * Iterates only 1 byte (uint8) at a time.
 */
struct SliceIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error SliceIter__StopIteration();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library SliceIter__ {
    /**
     * @dev Creates a new `SliceIter` from `Slice`.
     * Note the `Slice` is assumed to be memory-safe.
     */
    function from(Slice slice) internal pure returns (SliceIter memory) {
        return SliceIter(slice.ptr(), slice.len());
    }
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, ptr, len, isEmpty, next, nextBack } for SliceIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asSlice(SliceIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(SliceIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes.
 */
function len(SliceIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(SliceIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next value.
 * Reverts if len == 0.
 */
function next(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe and 1<=len)
    unchecked {
        // advance the iterator
        self._ptr = selfPtr + 1;
        self._len = selfLen - 1;
    }

    return mload8(selfPtr);
}

/**
 * @dev Advances the iterator from the back and returns the next value.
 * Reverts if len == 0.
 */
function nextBack(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe)
    unchecked {
        // advance the iterator
        self._len = selfLen - 1;

        return mload8(selfPtr + (selfLen - 1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { isValidUtf8 as _isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { decodeUtf8, encodeUtf8 } from "./utils/unicode.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title A single UTF-8 encoded character.
 * @dev Internally it is stored as UTF-8 encoded bytes starting from left/MSB.
 */
type StrChar is bytes32;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrChar__InvalidUTF8();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrChar__ {
    /**
     * @dev Converts the first 1-4 bytes of `bytes32` to a `StrChar`.
     * Starts from left/MSB, reverts if not valid UTF-8.
     * @param b UTF-8 encoded character in the most significant bytes.
     */
    function from(bytes32 b) internal pure returns (StrChar char) {
        uint256 charLen = _isValidUtf8(b);
        if (charLen == 0) revert StrChar__InvalidUTF8();
        return fromUnchecked(b, charLen);
    }

    /**
    * @dev Converts a unicode code point to a `StrChar`.
    * E.g. for '€' code point = 0x20AC; wheareas UTF-8 = 0xE282AC.
    */
    function fromCodePoint(uint256 code) internal pure returns (StrChar char) {
        return StrChar.wrap(encodeUtf8(code));
    }

    /**
     * @dev Like `from`, but does NO validity checks.
     * Uses provided `_len` instead of calculating it. This allows invalid/malformed characters.
     *
     * MSB of `bytes32` SHOULD be valid UTF-8.
     * And `bytes32` SHOULD be zero-padded after the first UTF-8 character.
     * Primarily for internal use.
     */
    function fromUnchecked(bytes32 b, uint256 _len) internal pure returns (StrChar char) {
        return StrChar.wrap(bytes32(
            // zero-pad after the character
            uint256(b) & leftMask(_len)
        ));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { 
    len,
    toBytes32, toString, toCodePoint,
    cmp, eq, ne, lt, lte, gt, gte,
    isValidUtf8,
    isAscii
} for StrChar global;

/**
 * @dev Returns the character's length in bytes (1-4).
 * Returns 0 for some (not all!) invalid characters (e.g. due to unsafe use of fromUnchecked).
 */
function len(StrChar self) pure returns (uint256) {
    return utf8CharWidth(
        // extract the leading byte
        uint256(uint8(StrChar.unwrap(self)[0]))
    );
}

/**
 * @dev Converts a `StrChar` to its underlying bytes32 value.
 */
function toBytes32(StrChar self) pure returns (bytes32) {
    return StrChar.unwrap(self);
}

/**
 * @dev Converts a `StrChar` to a newly allocated `string`.
 */
function toString(StrChar self) pure returns (string memory str) {
    uint256 _len = self.len();
    str = new string(_len);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(add(str, 0x20), self)
    }
    return str;
}

/**
 * @dev Converts a `StrChar` to its unicode code point (aka unicode scalar value).
 */
function toCodePoint(StrChar self) pure returns (uint256) {
    return decodeUtf8(StrChar.unwrap(self));
}

/**
 * @dev Compare characters lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrChar self, StrChar other) pure returns (int256 result) {
    uint256 selfUint = uint256(StrChar.unwrap(self));
    uint256 otherUint = uint256(StrChar.unwrap(other));
    if (selfUint > otherUint) {
        return 1;
    } else if (selfUint < otherUint) {
        return -1;
    } else {
        return 0;
    }
}

/// @dev `self` == `other`
function eq(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) == uint256(StrChar.unwrap(other));
}

/// @dev `self` != `other`
function ne(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) != uint256(StrChar.unwrap(other));
}

/// @dev `self` < `other`
function lt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) < uint256(StrChar.unwrap(other));
}

/// @dev `self` <= `other`
function lte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) <= uint256(StrChar.unwrap(other));
}

/// @dev `self` > `other`
function gt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) > uint256(StrChar.unwrap(other));
}

/// @dev `self` >= `other`
function gte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) >= uint256(StrChar.unwrap(other));
}

/**
 * @dev Returns true if `StrChar` is valid UTF-8.
 * Can be false if it was formed with an unsafe method (fromUnchecked, wrap).
 */
function isValidUtf8(StrChar self) pure returns (bool) {
    return _isValidUtf8(StrChar.unwrap(self)) != 0;
}

/**
 * @dev Returns true if `StrChar` is within the ASCII range.
 */
function isAscii(StrChar self) pure returns (bool) {
    return StrChar.unwrap(self)[0] < 0x80;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__ } from "./Slice.sol";
import { StrSlice } from "./StrSlice.sol";
import { SliceIter, SliceIter__, SliceIter__StopIteration } from "./SliceIter.sol";
import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "./StrChar.sol";
import { isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title String chars iterator.
 * @dev This struct is created by the iter method on `StrSlice`.
 * Iterates 1 UTF-8 encoded character at a time (which may have 1-4 bytes).
 *
 * Note StrCharsIter iterates over UTF-8 encoded codepoints, not unicode scalar values.
 * This is mostly done for simplicity, since solidity doesn't care about unicode anyways.
 *
 * TODO think about actually adding char and unicode awareness?
 * https://github.com/devstein/unicode-eth attempts something like that
 */
struct StrCharsIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrCharsIter__ {
    /**
     * @dev Creates a new `StrCharsIter` from `StrSlice`.
     * Note the `StrSlice` is assumed to be memory-safe.
     */
    function from(StrSlice slice) internal pure returns (StrCharsIter memory) {
        return StrCharsIter(slice.ptr(), slice.len());

        // TODO I'm curious about gas differences
        // return StrCharsIter(SliceIter__.from(str.asSlice()));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asStr,
    ptr, len, isEmpty,
    next, nextBack, unsafeNext,
    count, validateUtf8, unsafeCount
} for StrCharsIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asStr(StrCharsIter memory self) pure returns (StrSlice slice) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice()
    ));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrCharsIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrCharsIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(StrCharsIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function next(StrCharsIter memory self) pure returns (StrChar) {
    if (self._len == 0) revert SliceIter__StopIteration();
    (bytes32 b, uint256 charLen) = self._nextRaw(true);
    // safe because _nextRaw guarantees charLen <= selfLen as long as selfLen != 0.
    unchecked {
        // charLen > 0 because of `revertOnInvalid` flag
        self._len -= charLen;
    }
    // safe because _nextRaw reverts on invalid UTF-8
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Advances the iterator from the back and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function nextBack(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    // _self shares memory with self!
    SliceIter memory _self = self._sliceIter();

    bool isValid;
    uint256 b;
    for (uint256 i; i < 4; i++) {
        // an example of what's going on in the loop:
        // b = 0x0000000000..00
        // nextBack = 0x80
        // b = 0x8000000000..00 (not valid UTF-8)
        // nextBack = 0x92
        // b = 0x9280000000..00 (not valid UTF-8)
        // nextBack = 0x9F
        // b = 0x9F92800000..00 (not valid UTF-8)
        // nextBack = 0xF0
        // b = 0xF09F928000..00 (valid UTF-8, break)

        // safe because i < 4
        unchecked {
            // free the space in MSB
            b = (b >> 8) | (
                // get 1 byte in LSB
                uint256(_self.nextBack())
                // flip it to MSB
                << (31 * 8)
            );
        }
        // break if the char is valid
        if (isValidUtf8(bytes32(b)) != 0) {
            isValid = true;
            break;
        }
    }
    if (!isValid) revert StrChar__InvalidUTF8();

    // construct the character;
    // wrap is safe, because UTF-8 was validated,
    // and the trailing bytes are 0 (since the loop went byte-by-byte)
    char = StrChar.wrap(bytes32(b));
    // the iterator was already advanced by `_self.nextBack()`
    return char;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Does NOT validate iterator length. It could underflow!
 * Does NOT revert on invalid UTF-8.
 * WARNING: for invalid UTF-8 bytes, advances by 1 and returns an invalid `StrChar` with len 0!
 */
function unsafeNext(StrCharsIter memory self) pure returns (StrChar char) {
    // _nextRaw guarantees charLen <= selfLen IF selfLen != 0
    (bytes32 b, uint256 charLen) = self._nextRaw(false);
    if (charLen > 0) {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= charLen;
        }
        // ALWAYS produces a valid character
        return StrChar__.fromUnchecked(b, charLen);
    } else {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= 1;
        }
        // NEVER produces a valid character (this is always a single 0x80-0xFF byte)
        return StrChar__.fromUnchecked(b, 1);
    }
}

/**
 * @dev Consumes the iterator, counting the number of UTF-8 characters.
 * Note O(n) time!
 * Reverts on invalid UTF-8.
 */
function count(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        self._nextRaw(true);
        // +1 is safe because 2**256 cycles are impossible
        unchecked {
            result += 1;
        }
    }
    // _nextRaw does NOT modify len to allow optimizations like setting it once at the end
    self._len = 0;
    return result;
}

/**
 * @dev Consumes the iterator, validating UTF-8 characters.
 * Note O(n) time!
 * Returns true if all are valid; otherwise false on the first invalid UTF-8 character.
 */
function validateUtf8(StrCharsIter memory self) pure returns (bool) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        (, uint256 charLen) = self._nextRaw(false);
        if (charLen == 0) return false;
    }
    return true;
}

/**
 * @dev VERY UNSAFE - a single invalid UTF-8 character can severely alter the result!
 * Consumes the iterator, counting the number of UTF-8 characters.
 * Significantly faster than safe `count`, especially for long mutlibyte strings.
 *
 * Note `count` is actually a bit more efficient than `validateUtf8`.
 * `count` is much more efficient than calling `validateUtf8` and `unsafeCount` together.
 * Use `unsafeCount` only when you are already certain that UTF-8 is valid.
 * If you want speed and no validation, just use byte length, it's faster and more predictably wrong.
 *
 * Some gas usage metrics:
 * 1 ascii char:
 *   count:       571 gas
 *   unsafeCount: 423 gas
 * 100 ascii chars:
 *   count:       27406 gas
 *   unsafeCount: 12900 gas
 * 1000 chinese chars (3000 bytes):
 *   count:       799305 gas
 *   unsafeCount: 178301 gas
 */
function unsafeCount(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        uint256 leadingByte;
        // unchecked mload
        // (unsafe, the last character could move the pointer past the boundary, but only once)
        /// @solidity memory-safe-assembly
        assembly {
            leadingByte := byte(0, mload(
                // load self._ptr (this is an optimization trick, since it's 1st in the struct)
                mload(self)
            ))
        }
        unchecked {
            // this is a very unsafe version of `utf8CharWidth`,
            // basically 1 invalid UTF-8 character can severely change the count result
            // (no real infinite loop risks, only one potential corrupt memory read)
            if (leadingByte < 0x80) {
                self._ptr += 1;
            } else if (leadingByte < 0xE0) {
                self._ptr += 2;
            } else if (leadingByte < 0xF0) {
                self._ptr += 3;
            } else {
                self._ptr += 4;
            }
            // +1 is safe because 2**256 cycles are impossible
            result += 1;
        }
    }
    self._len = 0;

    return result;
}

/*//////////////////////////////////////////////////////////////////////////
                            FILE-LEVEL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, _nextRaw, _sliceIter } for StrCharsIter;

/**
 * @dev Views the underlying data as a `bytes` subslice of the original data.
 */
function asSlice(StrCharsIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Used internally to efficiently reuse iteration logic. Has a lot of caveats.
 * NEITHER checks NOR modifies iterator length.
 * (Caller MUST guarantee that len != 0. Caller MUST modify len correctly themselves.)
 * Does NOT form the character properly, and returns raw unmasked bytes and length.
 * Does advance the iterator pointer.
 *
 * Validates UTF-8.
 * For valid chars advances the pointer by charLen.
 * For invalid chars behaviour depends on `revertOnInvalid`:
 * revertOnInvalid == true: revert.
 * revertOnInvalid == false: advance the pointer by 1, but return charLen 0.
 *
 * @return b raw unmasked bytes; if not discarded, then charLen SHOULD be used to mask it.
 * @return charLen length of a valid UTF-8 char; 0 for invalid chars.
 * Guarantees that charLen <= self._len (as long as self._len != 0, which is the caller's guarantee)
 */
function _nextRaw(StrCharsIter memory self, bool revertOnInvalid)
    pure
    returns (bytes32 b, uint256 charLen)
{
    // unchecked mload
    // (isValidUtf8 only checks the 1st character, which exists since caller guarantees len != 0)
    /// @solidity memory-safe-assembly
    assembly {
        b := mload(
            // load self._ptr (this is an optimization trick, since it's 1st in the struct)
            mload(self)
        )
    }
    // validate character (0 => invalid; 1-4 => valid)
    charLen = isValidUtf8(b);

    if (charLen > self._len) {
        // mload didn't check bounds,
        // so a character that goes out of bounds could've been seen as valid.
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else if (charLen == 0) {
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else {
        // safe because of the `charLen > self._len` check earlier
        unchecked {
            self._ptr += charLen;
        }
        // valid
        return (b, charLen);
    }
}

/**
 * @dev Returns the underlying `SliceIter`.
 * AVOID USING THIS EXTERNALLY!
 * Advancing the underlying slice could lead to invalid UTF-8 for StrCharsIter.
 */
function _sliceIter(StrCharsIter memory self) pure returns (SliceIter memory result) {
    assembly {
        result := self
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__, Slice__OutOfBounds } from "./Slice.sol";
import { StrChar, StrChar__ } from "./StrChar.sol";
import { StrCharsIter, StrCharsIter__ } from "./StrCharsIter.sol";
import { isValidUtf8 } from "./utils/utf8.sol";
import { memIsAscii } from "./utils/memascii.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

/**
 * @title A string slice.
 * @dev String slices must always be valid UTF-8.
 * Internally `StrSlice` uses `Slice`, adding only UTF-8 related logic on top.
 */
type StrSlice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrSlice__InvalidCharBoundary();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrSlice__ {
    /**
     * @dev Converts a `string` to a `StrSlice`.
     * The string is not copied.
     * `StrSlice` points to the memory of `string`, right after the length word.
     */
    function from(string memory str) internal pure returns (StrSlice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(str, 0x20)
        }
        return fromRawParts(_ptr, bytes(str).length);
    }

    /**
     * @dev Creates a new `StrSlice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (StrSlice slice) {
        return StrSlice.wrap(Slice.unwrap(
            Slice__.fromRawParts(_ptr, _len)
        ));
    }

    /**
     * @dev Returns true if the byte slice starts with a valid UTF-8 character.
     * Note this does not validate the whole slice.
     */
    function isBoundaryStart(Slice slice) internal pure returns (bool) {
        bytes32 b = slice.toBytes32();
        return isValidUtf8(b) != 0;
    }
}

/**
 * @dev Alternative to StrSlice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for string;
 * ```
 */
function toSlice(string memory str) pure returns (StrSlice slice) {
    return StrSlice__.from(str);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asSlice,
    ptr, len, isEmpty,
    // conversion
    toString,
    keccak,
    // concatenation
    add, join,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    isCharBoundary,
    get,
    splitAt, getSubslice,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    splitOnce, rsplitOnce,
    replacen,
    // iteration
    chars,
    // ascii
    isAscii
} for StrSlice global;

/**
 * @dev Returns the underlying `Slice`.
 * WARNING: manipulating `Slice`s can break UTF-8 for related `StrSlice`s!
 */
function asSlice(StrSlice self) pure returns (Slice) {
    return Slice.wrap(StrSlice.unwrap(self));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(StrSlice self) pure returns (bool) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `StrSlice` to a newly allocated string.
 * The `StrSlice` will NOT point to the new string.
 */
function toString(StrSlice self) view returns (string memory) {
    return string(self.asSlice().toBytes());
}

/**
 * @dev Returns keccak256 of all the bytes of `StrSlice`.
 * Note that for any `string memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(StrSlice self) pure returns (bytes32 result) {
    return self.asSlice().keccak();
}

/**
 * @dev Concatenates two `StrSlice`s into a newly allocated string.
 */
function add(StrSlice self, StrSlice other) view returns (string memory) {
    return string(self.asSlice().add(other.asSlice()));
}

/**
 * @dev Flattens an array of `StrSlice`s into a single newly allocated string,
 * placing `self` as the separator between each.
 */
function join(StrSlice self, StrSlice[] memory strs) view returns (string memory) {
    Slice[] memory slices;
    assembly {
        slices := strs
    }
    return string(self.asSlice().join(slices));
}

/**
 * @dev Compare string slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrSlice self, StrSlice other) pure returns (int256 result) {
    return self.asSlice().cmp(other.asSlice());
}

/// @dev `self` == `other`
/// Note more efficient than cmp
function eq(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().eq(other.asSlice());
}

/// @dev `self` != `other`
/// Note more efficient than cmp
function ne(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().ne(other.asSlice());
}

/// @dev `self` < `other`
function lt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Checks that `index`-th byte is safe to split on.
 * The start and end of the string (when index == self.len()) are considered to be boundaries.
 * Returns false if index is greater than self.len().
 */
function isCharBoundary(StrSlice self, uint256 index) pure returns (bool) {
    if (index < self.len()) {
        return isValidUtf8(self.asSlice().getAfter(index).toBytes32()) != 0;
    } else if (index == self.len()) {
        return true;
    } else {
        return false;
    }
}

/**
 * @dev Returns the character at `index` (in bytes).
 * Reverts if index is out of bounds.
 */
function get(StrSlice self, uint256 index) pure returns (StrChar char) {
    bytes32 b = self.asSlice().getAfterStrict(index).toBytes32();
    uint256 charLen = isValidUtf8(b);
    if (charLen == 0) revert StrSlice__InvalidCharBoundary();
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Divides one string slice into two at an index.
 * Reverts when splitting on a non-boundary (use isCharBoundary).
 */
function splitAt(StrSlice self, uint256 mid) pure returns (StrSlice, StrSlice) {
    (Slice lSlice, Slice rSlice) = self.asSlice().splitAt(mid);
    if (!StrSlice__.isBoundaryStart(lSlice) || !StrSlice__.isBoundaryStart(rSlice)) {
        revert StrSlice__InvalidCharBoundary();
    }
    return (
        StrSlice.wrap(Slice.unwrap(lSlice)),
        StrSlice.wrap(Slice.unwrap(rSlice))
    );
}

/**
 * @dev Returns a subslice [start..end) of `self`.
 * Reverts when slicing a non-boundary (use isCharBoundary).
 */
function getSubslice(StrSlice self, uint256 start, uint256 end) pure returns (StrSlice) {
    Slice subslice = self.asSlice().getSubslice(start, end);
    if (!StrSlice__.isBoundaryStart(subslice)) revert StrSlice__InvalidCharBoundary();
    if (end != self.len()) {
        (, Slice nextSubslice) = self.asSlice().splitAt(end);
        if (!StrSlice__.isBoundaryStart(nextSubslice)) revert StrSlice__InvalidCharBoundary();
    }
    return StrSlice.wrap(Slice.unwrap(subslice));
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().find(pattern.asSlice());
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().rfind(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this string slice.
 */
function contains(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().contains(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a prefix of this string slice.
 */
function startsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().startsWith(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a suffix of this string slice.
 */
function endsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().endsWith(pattern.asSlice());
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripPrefix(pattern.asSlice())
    ));
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripSuffix(pattern.asSlice())
    ));
}

/**
 * @dev Splits a slice into 2 on the first match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be the entire string and `suffix` will be empty.
 */
function splitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().find(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, self, StrSlice.wrap(0));
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * @dev Splits a slice into 2 on the last match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be empty and `suffix` will be the entire string.
 */
function rsplitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().rfind(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, StrSlice.wrap(0), self);
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * *EXPERIMENTAL*
 * @dev Replaces first `n` matches of a pattern with another string slice.
 * Returns the result in a newly allocated string.
 * Note this does not modify the string `self` is a slice of.
 * WARNING: Requires 0 < pattern.len() <= to.len()
 */
function replacen(
    StrSlice self,
    StrSlice pattern,
    StrSlice to,
    uint256 n
) view returns (string memory str) {
    uint256 patLen = pattern.len();
    uint256 toLen = to.len();
    // TODO dynamic string; atm length can be reduced but not increased
    assert(patLen >= toLen);
    assert(patLen > 0);

    str = new string(self.len());
    Slice iterSlice = self.asSlice();
    Slice resultSlice = Slice__.from(bytes(str));

    uint256 matchNum;
    while (matchNum < n) {
        uint256 index = iterSlice.find(pattern.asSlice());
        // break if no more matches
        if (index == type(uint256).max) break;
        // copy prefix
        if (index > 0) {
            resultSlice
                .getBefore(index)
                .copyFromSlice(
                    iterSlice.getBefore(index)
                );
        }

        uint256 indexToEnd;
        // TODO this is fine atm only because patLen <= toLen
        unchecked {
            indexToEnd = index + toLen;
        }

        // copy replacement
        resultSlice
            .getSubslice(index, indexToEnd)
            .copyFromSlice(to.asSlice());

        // advance slices past the match
        iterSlice = iterSlice.getAfter(index + patLen);
        resultSlice = resultSlice.getAfter(indexToEnd);

        // break if iterSlice is done
        if (iterSlice.len() == 0) {
            break;
        }
        // safe because of `while` condition
        unchecked {
            matchNum++;
        }
    }

    uint256 realLen = resultSlice.ptr() - StrSlice__.from(str).ptr();
    // copy suffix
    uint256 iterLen = iterSlice.len();
    if (iterLen > 0) {
        resultSlice
            .getBefore(iterLen)
            .copyFromSlice(iterSlice);
        realLen += iterLen;
    }
    // remove extra length
    if (bytes(str).length != realLen) {
        // TODO atm only accepting patLen <= toLen
        assert(realLen <= bytes(str).length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, realLen)
        }
    }
    return str;
}

/**
 * @dev Returns an character iterator over the slice.
 * The iterator yields items from either side.
 */
function chars(StrSlice self) pure returns (StrCharsIter memory) {
    return StrCharsIter(self.ptr(), self.len());
}

/**
 * @dev Checks if all characters are within the ASCII range.
 * 
 * Note this does NOT explicitly validate UTF-8.
 * Whereas ASCII certainly is valid UTF-8, non-ASCII *could* be invalid UTF-8.
 * Use `StrCharsIter` for explicit validation.
 */
function isAscii(StrSlice self) pure returns (bool) {
    return memIsAscii(self.ptr(), self.len());
}

/*//////////////////////////////////////////////////////////////////////////
                              FILE FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { _splitFound } for StrSlice;

/**
 * @dev Splits a slice into [:index] and [index+patLen:].
 * CALLER GUARANTEE: `index` < self.len()
 * For internal use by split/rsplit.
 *
 * This is mostly just a faster alternative to `getBefore`+`getAfter`.
 */
function _splitFound(StrSlice self, uint256 index, uint256 patLen)
    pure
    returns (bool, StrSlice prefix, StrSlice suffix)
{
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    uint256 indexAfterPat;
    // safe because caller guarantees index to be < selfLen
    unchecked {
        indexAfterPat = index + patLen;
        if (indexAfterPat > selfLen) revert Slice__OutOfBounds();
    }
    // [:index] (inlined `getBefore`)
    prefix = StrSlice.wrap(Slice.unwrap(
        Slice__.fromUnchecked(selfPtr, index)
    ));
    // [(index+patLen):] (inlined `getAfter`)
    // safe because indexAfterPat <= selfLen
    unchecked {
        suffix = StrSlice.wrap(Slice.unwrap(
            Slice__.fromUnchecked(selfPtr + indexAfterPat, selfLen - indexAfterPat)
        ));
    }
    return (true, prefix, suffix);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/**
 * @dev Load 1 byte from the pointer.
 * The result is in the least significant byte, hence uint8.
 */
function mload8(uint256 ptr) pure returns (uint8 item) {
    /// @solidity memory-safe-assembly
    assembly {
        item := byte(0, mload(ptr))
    }
    return item;
}

/**
 * @dev Copy `n` memory bytes.
 * WARNING: Does not handle pointer overlap!
 */
function memcpy(uint256 ptrDest, uint256 ptrSrc, uint256 length) pure {
    // copy 32-byte chunks
    while (length >= 32) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(ptrDest, mload(ptrSrc))
        }
        // safe because total addition will be <= length (ptr+len is implicitly safe)
        unchecked {
            ptrDest += 32;
            ptrSrc += 32;
            length -= 32;
        }
    }
    // copy the 0-31 length tail
    // (the rest is an inlined `mstoreN`)
    uint256 mask = leftMask(length);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(mload(ptrSrc), mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev mstore `n` bytes (left-aligned) of `data`
 */
function mstoreN(uint256 ptrDest, bytes32 data, uint256 n) pure {
    uint256 mask = leftMask(n);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(data, mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev Copy `n` memory bytes using identity precompile.
 */
function memmove(uint256 ptrDest, uint256 ptrSrc, uint256 n) view {
    /// @solidity memory-safe-assembly
    assembly {
        pop(
            staticcall(
                gas(),   // gas (unused is returned)
                0x04,    // identity precompile address
                ptrSrc,  // argsOffset
                n,       // argsSize: byte size to copy
                ptrDest, // retOffset
                n        // retSize: byte size to copy
            )
        )
    }
}

/**
 * @dev Compare `n` memory bytes lexicographically.
 * Returns 0 for equal, < 0 for less than and > 0 for greater than.
 *
 * https://doc.rust-lang.org/std/cmp/trait.Ord.html#lexicographical-comparison
 */
function memcmp(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (int256) {
    // binary search for the first inequality
    while (n >= 32) {
        // safe because total addition will be <= n (ptr+len is implicitly safe)
        unchecked {
            uint256 nHalf = n / 2;
            if (memeq(ptrSelf, ptrOther, nHalf)) {
                ptrSelf += nHalf;
                ptrOther += nHalf;
                // (can't do n /= 2 instead of nHalf, some bytes would be skipped)
                n -= nHalf;
                // an explicit continue is better for optimization here
                continue;
            } else {
                n -= nHalf;
            }
        }
    }

    uint256 mask = leftMask(n);
    int256 diff;
    /// @solidity memory-safe-assembly
    assembly {
        // for <32 bytes subtraction can be used for comparison,
        // just need to shift away from MSB
        diff := sub(
            shr(8, and(mload(ptrSelf), mask)),
            shr(8, and(mload(ptrOther), mask))
        )
    }
    return diff;
}

/**
 * @dev Returns true if `n` memory bytes are equal.
 *
 * It's faster (up to 4x) than memcmp, especially on medium byte lengths like 32-320.
 * The benefit gets smaller for larger lengths, for 10000 it's only 30% faster.
 */
function memeq(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (bool result) {
    /// @solidity memory-safe-assembly
    assembly {
        result := eq(keccak256(ptrSelf, n), keccak256(ptrOther, n))
    }
}

/**
 * @dev Left-aligned byte mask (e.g. for partial mload/mstore).
 * For length >= 32 returns type(uint256).max
 *
 * length 0:   0x000000...000000
 * length 1:   0xff0000...000000
 * length 2:   0xffff00...000000
 * ...
 * length 30:  0xffffff...ff0000
 * length 31:  0xffffff...ffff00
 * length 32+: 0xffffff...ffffff
 */
function leftMask(uint256 length) pure returns (uint256) {
    unchecked {
        return ~(
            type(uint256).max >> (length * 8)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { leftMask } from "./mem.sol";

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/// @dev 32 0x80 bytes. 0x80 = 1000_0000
uint256 constant ASCII_MASK = 0x80 * (type(uint256).max / type(uint8).max);

/**
 * @dev Efficiently checks if all bytes are within the ASCII range.
 */
function memIsAscii(uint256 textPtr, uint256 textLen) pure returns (bool) {
    uint256 tailLen;
    uint256 endPtr;
    // safe because tailLen <= textLen (ptr+len is implicitly safe)
    unchecked {
        tailLen = textLen % 32;
        endPtr = textPtr + (textLen - tailLen);
    }

    // check 32 byte chunks with the ascii mask
    uint256 b;
    while (textPtr < endPtr) {
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(textPtr)
        }
        // break if any non-ascii byte is found
        if (b & ASCII_MASK != 0) {
            return false;
        }
        // safe because textPtr < endPtr, and endPtr = textPtr + n*32 (see tailLen)
        unchecked {
            textPtr += 32;
        }
    }

    // this mask removes any trailing bytes
    uint256 trailingMask = leftMask(tailLen);
    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(endPtr), trailingMask)
    }
    // check tail with the ascii mask
    return b & ASCII_MASK == 0;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 *
 * Loosely based on https://doc.rust-lang.org/1.65.0/core/slice/memchr/
 */

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256 index) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memchrWord(ptrText, lenText, x);
    }

    uint256 ptrStart = ptrText;
    uint256 lenTail;
    uint256 ptrEnd;
    // safe because lenTail <= lenText (ptr+len is implicitly safe)
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        ptrEnd = ptrText + (lenText - lenTail);
    }
    uint256 repeatedX = repeatByte(x);
    while (ptrText < ptrEnd) {
        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(ptrText), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because ptrText >= ptrStart (ptrText = ptrStart + 32*n)
            // + is safe because index + offsetLen < lenText
            // (ptr+len is implicitly safe)
            unchecked {
                return
                    // index
                    memchrWord(ptrText, 32, x)
                    // + offsetLen
                    + (ptrText - ptrStart);
            }
        }

        // safe because ptrText < ptrEnd, and ptrEnd = ptrText + n*32 (see lenTail)
        unchecked {
            ptrText += 32;
        }
    }

    if (lenTail == 0) return type(uint256).max;

    index = memchrWord(ptrEnd, lenTail, x);
    if (index == type(uint256).max) {
        return type(uint256).max;
    } else {
        // - is safe because ptrEnd >= ptrStart (ptrEnd = ptrStart + lenText - lenTail)
        // + is safe because index + offsetLen < lenText
        // (ptr+len is implicitly safe)
        unchecked {
            return index
                // + offsetLen
                + (ptrEnd - ptrStart);
        }
    }
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memrchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memrchrWord(ptrText, lenText, x);
    }

    uint256 lenTail;
    uint256 offsetPtr;
    // safe because pointers are guaranteed to be valid by the caller
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        offsetPtr = ptrText + lenText;
    }

    if (lenTail != 0) {
        // remove tail length
        // - is safe because lenTail <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= lenTail;
        }
        // return if there is a matching byte
        uint256 index = memrchrWord(offsetPtr, lenTail, x);
        if (index != type(uint256).max) {
            // - is safe because offsetPtr > ptrText (offsetPtr = ptrText + lenText - lenTail)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return index
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }

    uint256 repeatedX = repeatByte(x);
    while (offsetPtr > ptrText) {
        // - is safe because 32 <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= 32;
        }

        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(offsetPtr), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because offsetPtr > ptrText (see the while condition)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return
                    // index
                    memrchrWord(offsetPtr, 32, x)
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memchr after its chunk search.
 */
function memchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    uint256 i;
    if (lenText > 32) {
        lenText = 32;
    }

    ////////binary search start
    // Some manual binary searches, cost ~50gas, could save up to ~1500
    // (comment them out and the function will work fine)
    if (lenText >= 16 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint128).max) == 0) {
            i = 16;

            if (lenText >= 24 + 2) {
                if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint64).max) == 0) {
                    i = 24;
                }
            }
        } else if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    } else if (lenText >= 8 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    }
    ////////binary search end
    
    // ++ is safe because lenText <= 32
    unchecked {
        for (i; i < lenText; i++) {
            uint8 b;
            assembly {
                b := byte(i, chunk)
            }
            if (b == x) return i;
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memrchr after its chunk search.
 */
function memrchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText > 32) {
        lenText = 32;
    }
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    while (lenText > 0) {
        // -- is safe because lenText > 0
        unchecked {
            lenText--;
        }
        uint8 b;
        assembly {
            b := byte(lenText, chunk)
        }
        if (b == x) return lenText;
    }
    // not found
    return type(uint256).max;
}

/// @dev repeating low bit for containsZeroByte
uint256 constant LO_U256 = 0x0101010101010101010101010101010101010101010101010101010101010101;
/// @dev repeating high bit for containsZeroByte
uint256 constant HI_U256 = 0x8080808080808080808080808080808080808080808080808080808080808080;

/**
 * @dev Returns a non-zero value if `x` contains any zero byte.
 * (returning a bool would be less efficient)
 *
 * From *Matters Computational*, J. Arndt:
 *
 * "The idea is to subtract one from each of the bytes and then look for
 * bytes where the borrow propagated all the way to the most significant bit."
 */
function nonZeroIfXcontainsZeroByte(uint256 x) pure returns (uint256) {
    unchecked {
        return (x - LO_U256) & (~x) & HI_U256;
    }
    /*
     * An example of how it works:
     *                                              here is 00
     * x    0x0101010101010101010101010101010101010101010101000101010101010101
     * x-LO 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
     * ~x   0xfefefefefefefefefefefefefefefefefefefefefefefefffefefefefefefefe
     * &1   0xfefefefefefefefefefefefefefefefefefefefefefefeff0000000000000000
     * &2   0x8080808080808080808080808080808080808080808080800000000000000000
     */
}

/// @dev Repeat byte `b` 32 times
function repeatByte(uint8 b) pure returns (uint256) {
    // safe because uint8 can't cause overflow:
    // e.g. 0x5A * 0x010101..010101 = 0x5A5A5A..5A5A5A
    // and  0xFF * 0x010101..010101 = 0xFFFFFF..FFFFFF
    unchecked {
        return b * (type(uint256).max / type(uint8).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error PackedPtrLen__PtrOverflow();
error PackedPtrLen__LenOverflow();

/**
 * @title Pack ptr and len uint128 values into 1 uint256.
 * @dev ptr is left/MSB. len is right/LSB.
 */
library PackPtrLen {
    uint256 constant MAX = type(uint128).max;

    uint256 constant MASK_PTR = uint256(type(uint128).max) << 128;
    uint256 constant MASK_LEN = uint256(type(uint128).max);

    function pack(uint256 ptr, uint256 len) internal pure returns (uint256 packed) {
        if (ptr > MAX) revert PackedPtrLen__PtrOverflow();
        if (len > MAX) revert PackedPtrLen__LenOverflow();
        return (ptr << 128) | (len & MASK_LEN);
    }

    function getPtr(uint256 packed) internal pure returns (uint256) {
        return packed >> 128;
    }

    function getLen(uint256 packed) internal pure returns (uint256) {
        return packed & MASK_LEN;
    }

    function setPtr(uint256 packed, uint256 ptr) internal pure returns (uint256) {
        return (packed & MASK_PTR) | (ptr << 128);
    }

    function setLen(uint256 packed, uint256 len) internal pure returns (uint256) {
        return (packed & MASK_LEN) | (len);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { utf8CharWidth } from "./utf8.sol";

/*
 * IMPORTANT: Here `uint256` represents 1 code point (aka unicode scalar values),
 * NOT a UTF-8 encoded character!
 * E.g. for '€' code point = 0x20AC; wheareas UTF-8 encoding = 0xE282AC.
 *
 * Only conversion to/from UTF-8 is addressed here.
 * Note that UTF-16 surrogate halves are invalid code points even if UTF-16 was supported.
 */

error Unicode__InvalidCode();

/// @dev The highest valid code point.
uint256 constant MAX = 0x10FFFF;

// UTF-8 ranges
uint256 constant MAX_ONE_B = 0x80;
uint256 constant MAX_TWO_B = 0x800;
uint256 constant MAX_THREE_B = 0x10000;
// and tags for encoding characters
uint256 constant TAG_CONT = 0x80;
uint256 constant TAG_TWO_B = 0xC0;
uint256 constant TAG_THREE_B = 0xE0;
uint256 constant TAG_FOUR_B = 0xF0;
// and continuation byte mask
uint256 constant MASK_CONT = 0x3F;

/**
 * @dev Encodes a unicode code point as UTF-8.
 * Reverts if the code point is invalid.
 * The result is 1-4 bytes starting at MSB.
 */
function encodeUtf8(uint256 code) pure returns (bytes32) {
    if (code < MAX_ONE_B) {
        return bytes32(
            (code                                ) << (31 * 8)
        );
    } else if (code < MAX_TWO_B) {
        return bytes32(
            (code >> 6              | TAG_TWO_B  ) << (31 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (30 * 8)
        );
    } else if (code < MAX_THREE_B) {
        if (code & 0xF800 == 0xD800) {
            // equivalent to `code >= 0xD800 && code <= 0xDFFF`
            // U+D800–U+DFFF are invalid UTF-16 surrogate halves
            revert Unicode__InvalidCode();
        }
        return bytes32(
            (code >> 12             | TAG_THREE_B) << (31 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (29 * 8)
        );
    } else if (code <= MAX) {
        return bytes32(
            (code >> 18             | TAG_FOUR_B ) << (31 * 8) |
            (code >> 12 & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (29 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (28 * 8)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Decodes a UTF-8 character into its code point.
 * Validates ONLY the leading byte, use `isValidCodePoint` on the result if UTF-8 wasn't validated.
 * The input is 1-4 bytes starting at MSB.
 */
function decodeUtf8(bytes32 str) pure returns (uint256) {
    uint256 leadingByte = uint256(uint8(str[0]));
    uint256 width = utf8CharWidth(leadingByte);

    if (width == 1) {
        return leadingByte;
    } else if (width == 2) {
        uint256 byte1 = uint256(uint8(str[1]));
        return uint256(
            // 0x1F = 0001_1111
            (leadingByte & 0x1F     ) << 6 |
            (byte1       & MASK_CONT)
        );
    } else if (width == 3) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        return uint256(
            // 0x0F = 0000_1111
            (leadingByte & 0x0F     ) << 12 |
            (byte1       & MASK_CONT) << 6  |
            (byte2       & MASK_CONT)
        );
    } else if (width == 4) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        uint256 byte3 = uint256(uint8(str[3]));
        return uint256(
            // 0x07 = 0000_0111
            (leadingByte & 0x07     ) << 18 |
            (byte1       & MASK_CONT) << 12 |
            (byte2       & MASK_CONT) << 6  |
            (byte3       & MASK_CONT)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Returns the length of a code point in UTF-8 encoding.
 * Does NOT validate it.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function lenUtf8(uint256 code) pure returns (uint256) {
    if (code < MAX_ONE_B) {
        return 1;
    } else if (code < MAX_TWO_B) {
        return 2;
    } else if (code < MAX_THREE_B) {
        return 3;
    } else {
        return 4;
    }
}

/**
 * @dev Returns true if the code point is valid.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function isValidCodePoint(uint256 code) pure returns (bool) {
    // U+D800–U+DFFF are invalid UTF-16 surrogate halves
    if (code < 0xD800) {
        return true;
    } else {
        return code > 0xDFFF && code <= MAX;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns the byte length for a UTF-8 character with the leading byte.
 * Returns 0 for invalid leading bytes.
 */
function utf8CharWidth(uint256 leadingByte) pure returns (uint256) {
    if (leadingByte < 0x80) {
        return 1;
    } else if (leadingByte < 0xC2) {
        return 0;
    } else if (leadingByte < 0xE0) {
        return 2;
    } else if (leadingByte < 0xF0) {
        return 3;
    } else if (leadingByte < 0xF5) {
        return 4;
    } else {
        return 0;
    }
}

/**
 * @dev Returns true if `b` is a valid UTF-8 leading byte.
 */
function isLeadingByte(uint256 b) pure returns (bool) {
    return utf8CharWidth(b) > 0;
}

/**
 * @dev Returns character length if the 1-4 bytes at MSB are a valid UTF-8 encoded character.
 * Returns 0 for invalid characters.
 * (utf8CharWidth validates ONLY the leading byte, not the whole character)
 *
 * Note if MSB is 0x00, this will return 1, since 0x00 is valid UTF-8.
 * Works faster for smaller code points.
 *
 * https://www.rfc-editor.org/rfc/rfc3629#section-4
 * UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
 * UTF8-1      = %x00-7F
 * UTF8-2      = %xC2-DF UTF8-tail
 * UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
 *               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
 * UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
 *               %xF4 %x80-8F 2( UTF8-tail )
 * UTF8-tail   = %x80-BF
 */
function isValidUtf8(bytes32 b) pure returns (uint256) {
    // TODO you can significantly optimize comparisons with bitmasks,
    // some stuff to look at:
    // https://github.com/zwegner/faster-utf8-validator/blob/master/z_validate.c
    // https://github.com/websockets/utf-8-validate/blob/master/src/validation.c
    // https://github.com/simdutf/simdutf/blob/master/src/scalar/utf8.h

    uint8 first = uint8(b[0]);
    // UTF8-1 = %x00-7F
    if (first <= 0x7F) {
        // fast path for ascii
        return 1;
    }

    uint256 w = utf8CharWidth(first);
    if (w == 2) {
        // UTF8-2
        if (
            // %xC2-DF UTF8-tail
            0xC2 <= first && first <= 0xDF
            && _utf8Tail(uint8(b[1]))
        ) {
            return 2;
        } else {
            return 0;
        }
    } else if (w == 3) {
        uint8 second = uint8(b[1]);
        // UTF8-3
        bool valid12 =
            // = %xE0 %xA0-BF UTF8-tail
            first == 0xE0
            && 0xA0 <= second && second <= 0xBF
            // / %xE1-EC 2( UTF8-tail )
            || 0xE1 <= first && first <= 0xEC
            && _utf8Tail(second)
            // / %xED %x80-9F UTF8-tail
            || first == 0xED
            && 0x80 <= second && second <= 0x9F
            // / %xEE-EF 2( UTF8-tail )
            || 0xEE <= first && first <= 0xEF
            && _utf8Tail(second);

        if (valid12 && _utf8Tail(uint8(b[2]))) {
            return 3;
        } else {
            return 0;
        }
    } else if (w == 4) {
        uint8 second = uint8(b[1]);
        // UTF8-4
        bool valid12 =
            // = %xF0 %x90-BF 2( UTF8-tail )
            first == 0xF0
            && 0x90 <= second && second <= 0xBF
            // / %xF1-F3 3( UTF8-tail )
            || 0xF1 <= first && first <= 0xF3
            && _utf8Tail(second)
            // / %xF4 %x80-8F 2( UTF8-tail )
            || first == 0xF4
            && 0x80 <= second && second <= 0x8F;

        if (valid12 && _utf8Tail(uint8(b[2])) && _utf8Tail(uint8(b[3]))) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

/// @dev UTF8-tail = %x80-BF
function _utf8Tail(uint256 b) pure returns (bool) {
    // and,cmp should be faster than cmp,cmp,and
    // 0xC0 = 0b1100_0000, 0x80 = 0b1000_0000
    return b & 0xC0 == 0x80;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "base64-sol/base64.sol";
import {StrSlice, toSlice, len} from "@dk1a/solidity-stringutils/src/StrSlice.sol";

contract SVGNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using {toSlice} for string;

    Counters.Counter private _tokenIdCounter;

    string private svg;
    uint8[] private pointpos;

    mapping(uint256 => uint16) private _points;

    constructor(string memory _svg, uint8[] memory _pointpos) ERC721("SVGNFT", "SVG") {
        require(bytes(_svg).length > 0);
        svg = _svg;
        pointpos = _pointpos;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function addPoints(uint256 tokenId, uint16 points) public onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: nonexistent token id");
        require(_points[tokenId] < 0x7fff - points);
        _points[tokenId] += points;
    }

    function redeem(uint256 tokenId, uint16 points) public onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: nonexistent token id");
        require(_points[tokenId] >= points);
        _points[tokenId] -= points;
    }

    function getTotalPoints(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "ERC721URIStorage: nonexistent token id");
        if (_points[tokenId] > 100) {
            return 100;
        }
        return uint16(_points[tokenId]);
    }

    function getTotalRealPoints(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "ERC721URIStorage: nonexistent token id");
        return _points[tokenId];
    }

    function getSvg(uint tokenId) private view returns (string memory) {
        uint16 points = _points[tokenId];
        if (points > 99) {
            points = 99;
        }
        uint16 index = uint16(points / 5);
        uint8 ppos = pointpos[index];
        string memory svg2 = _replace(svg, "@", Strings.toString(ppos));
        string memory svg3 = _replace(svg2, "PPP", Strings.toString(_points[tokenId]));
        return svg3;
    }

    function _replace(
        string memory ostr,
        string memory pat,
        string memory nv
    ) private view returns (string memory) {
        StrSlice name = ostr.toSlice();
        (, StrSlice prefix, StrSlice suffix) = name.splitOnce(
            string(pat).toSlice()
        );
        if (len(suffix) == 0) {
            return ostr;
        }
        return prefix.add(toSlice(nv)).toSlice().add(suffix);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {

        require(_exists(tokenId), "ERC721URIStorage: nonexistent token id");

        bytes memory name = abi.encodePacked(name(), " #", Strings.toString(tokenId));
        string memory svgData = getSvg(tokenId);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "a dynamic SVG NFT", "image_data": "',
                svgData,
                '", "attributes": {"points":',
                Strings.toString(uint256(_points[tokenId])),
                '}}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}