// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildeventHook} from "../../interfaces/IWildeventHook.sol";
import {LibEncode} from "../../libraries/LibEncode.sol";

contract LinkedSocialWildeventHook is IWildeventHook {
    event SocialLinked(uint32 wildfileId, string platform);

    // exactly one Wildfile is allowed to be linked to a social per Wildevent
    error ExactlyOneWildfile();
    error PlatformAlreadyLinked();

    address public immutable wildeventsContract;
    mapping(uint32 => mapping(string => bool)) public wildfileIdToPlatformToIsLinked;

    constructor(address _wildeventsContract) {
        wildeventsContract = _wildeventsContract;
    }

    function onlyWildeventsContract(address msgSender) public view override {
        if (msgSender != wildeventsContract) {
            revert OnlyWildeventsContract();
        }
    }

    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external override {
        // make sure caller is the Wildevents contract
        onlyWildeventsContract(msg.sender);

        if (wildfileIds.length != 1) {
            revert ExactlyOneWildfile();
        }

        uint32 wildfileId = wildfileIds[0];
        (string memory platform) = decode(data);

        // each Wildfile can only link to each platform once
        bool alreadyLinked = wildfileIdToPlatformToIsLinked[wildfileId][platform];
        if (alreadyLinked) {
            revert PlatformAlreadyLinked();
        }

        wildfileIdToPlatformToIsLinked[wildfileId][platform] = true;

        emit SocialLinked(wildfileIds[0], platform);
    }

    function encode(string memory platform) public pure returns (bytes memory) {
        return LibEncode.encodeString(platform);
    }

    function decode(bytes memory data) public pure returns (string memory) {
        (string memory platform,) = LibEncode.decodeString(data, 0);
        return platform;
    }

    function isPlatformLinked(uint32 wildfileId, string calldata platform) public view returns (bool) {
        return wildfileIdToPlatformToIsLinked[wildfileId][platform];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildeventHook {
    error OnlyWildeventsContract();

    function onlyWildeventsContract(address msgSender) external view;
    /// @dev each hook should check that the msgSender is the Wildevents contract in onWildevent, and revert with OnlyWildeventsContract if not
    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library LibEncode {
    /**
     * @notice Tightly encodes a string. The first 4 bytes of the data store the length of the string. For example:
     * "abc" is encoded as 0x00000003616263
     * 0x00000003616263
     *   ^^^^^^^^         string length = 3
     *           ^^       "a" hex encoded
     *             ^^     "b" hex encoded
     *               ^^   "c" hex encoded
     * @param str string to be encoded
     */
    function encodeString(string memory str) internal pure returns (bytes memory data) {
        // The first four bytes stores the length of the string
        uint32 stringLength = uint32(bytes(str).length);
        data = bytes.concat(data, bytes4(stringLength));
        data = bytes.concat(data, abi.encodePacked(str));
    }

    /**
     * @notice Decodes a string that was previously encoded by encodeString
     * @param data raw bytes data
     * @param offsetBytes offset in the bytes data where the string starts (0-indexed)
     */
    function decodeString(bytes memory data, uint40 offsetBytes) internal pure returns (string memory, uint40) {
        uint32 stringLength = uint32(bytes4(slice(data, offsetBytes, 4)));
        string memory s = string(slice(data, offsetBytes + 4, stringLength));
        return (s, offsetBytes + 4 + stringLength);
    }

    /*//////////////////////////////////////////////////////////////
                            UINTs
    //////////////////////////////////////////////////////////////*/

    function encodeUint8(uint8 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint8(bytes memory data, uint40 offsetBytes) internal pure returns (uint8, uint40) {
        uint256 sizeBytes = 1; // uint8 is 1 byte
        uint8 decodedVal = uint8(bytes1(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    function encodeUint16(uint16 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint16(bytes memory data, uint40 offsetBytes) internal pure returns (uint16, uint40) {
        uint256 sizeBytes = 2; // uint16 is 2 bytes
        uint16 decodedVal = uint16(bytes2(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    function encodeUint32(uint32 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint32(bytes memory data, uint40 offsetBytes) internal pure returns (uint32, uint40) {
        uint256 sizeBytes = 4; // uint32 is 4 bytes
        uint32 decodedVal = uint32(bytes4(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    function encodeUint64(uint64 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint64(bytes memory data, uint40 offsetBytes) internal pure returns (uint64, uint40) {
        uint256 sizeBytes = 8; // uint64 is 8 bytes
        uint64 decodedVal = uint64(bytes8(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    function encodeUint128(uint128 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint128(bytes memory data, uint40 offsetBytes) internal pure returns (uint128, uint40) {
        uint256 sizeBytes = 16; // uint128 is 16 bytes
        uint128 decodedVal = uint128(bytes16(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    function encodeUint256(uint256 val) internal pure returns (bytes memory) {
        return abi.encodePacked(val);
    }

    function decodeUint256(bytes memory data, uint40 offsetBytes) internal pure returns (uint256, uint40) {
        uint256 sizeBytes = 32; // uint256 is 32 bytes
        uint256 decodedVal = uint256(bytes32(slice(data, offsetBytes, sizeBytes)));
        return (decodedVal, uint40(offsetBytes + sizeBytes));
    }

    /*//////////////////////////////////////////////////////////////
                            UINT ARRAYs
    //////////////////////////////////////////////////////////////*/

    function encodeUint16Array(uint16[] memory array) internal pure returns (bytes memory) {
        uint8 sizeBytes = 2; // uint16 is 2 bytes
        bytes32[] memory bytes32Array = new bytes32[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            bytes32Array[i] = bytes32(bytes2(array[i]));
        }

        return encodeArray(bytes32Array, sizeBytes);
    }

    function decodeUint16Array(bytes memory data, uint40 offsetBytes) internal pure returns (uint16[] memory, uint40) {
        uint8 sizeBytes = 2; // uint16 is 2 bytes
        (bytes32[] memory bytes32Array, uint40 newOffsetBytes) = decodeArray(data, sizeBytes, offsetBytes);
        uint16[] memory uint16Array = new uint16[](bytes32Array.length);
        for (uint256 i = 0; i < bytes32Array.length; i++) {
            uint16Array[i] = uint16(bytes2(bytes32Array[i]));
        }

        return (uint16Array, newOffsetBytes);
    }

    /**
     * @notice Tightly encodes an array. The first 4 bytes of the data store the length of the array.
     * The array itself is a bytes32 type to support encoding various uint sizes.
     * For example, to encode a uint16 array with values [6, 5, 4]:
     * - You first need to cast each element in the array to bytes32 (this left-packs the data):
     *   - ex. bytes32(bytes2(uint16(6))) => 0x00060000000....
     *   - do this for each element in the array
     * - Then call this function `encodeArray(yourArray, 2)`
     *   - the 2 is because each uint16 element in your original array is 2 bytes
     * - This function will return:
     * 0x00000003000600050004
     *   ^^^^^^^^               array length = 3
     *           ^^^^           uint16 value 6 encoded
     *               ^^^^       uint16 value 5 encoded
     *                   ^^^^   uint16 value 4 encoded
     * @param array bytes32 array data. The type is bytes32 to support various other data types like different uint sizes
     * @param sizeBytes The size in bytes of each element in the array. ex. uint16 array = 2, uint32 array = 4, etc.
     */
    function encodeArray(bytes32[] memory array, uint8 sizeBytes) internal pure returns (bytes memory data) {
        // The first four bytes stores the length of the array
        uint32 arrayLength = uint32(array.length);
        data = bytes.concat(data, bytes4(arrayLength));

        // Tightly pack the remaining array elements
        for (uint256 i = 0; i < arrayLength; i++) {
            // Assume right-padded (data is in leftmost bytes)
            data = bytes.concat(data, slice(abi.encode(array[i]), 0, sizeBytes));
        }
    }

    /**
     * @notice Decodes an array that was previously encoded by encodeArray
     * @param data raw bytes data
     * @param sizeBytes The size in bytes of each element in the array. ex. uint16 array = 2, uint32 array = 4, etc.
     * @param offsetBytes offset in the bytes data where the array starts (0-indexed)
     */
    function decodeArray(bytes memory data, uint8 sizeBytes, uint40 offsetBytes)
        internal
        pure
        returns (bytes32[] memory, uint40)
    {
        uint32 arrayLength = uint32(bytes4(slice(data, offsetBytes, 4)));
        bytes32[] memory array = new bytes32[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            array[i] = bytes32(slice(data, uint256(offsetBytes) + 4 + (uint256(sizeBytes) * i), sizeBytes));
        }
        return (array, offsetBytes + 4 + arrayLength * sizeBytes);
    }

    // Bytes slicing utility, taken shamelessly from BytesLib https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    // by:  @author Gonçalo Sá <[email protected]>
    // BytesLib code is under the Unlicense so this is okay
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}