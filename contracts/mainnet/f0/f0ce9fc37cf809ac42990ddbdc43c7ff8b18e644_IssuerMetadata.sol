pragma solidity ^0.8.0;

import "../interface/ITask.sol";
import "../interface/IOrder.sol";
import "../interface/IStage.sol";
import "../interface/IMetadata.sol";
import "../interface/IMetaComm.sol";
import "../libs/MyStrings.sol";
import "base64-sol/base64.sol";
import "../libs/uint12a4.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IssuerMetadata is IMetadata {
    using MyStrings for string;
    using uint12a4 for uint48;

    ITask public taskAddr;
    address public orderAddr;
    IMetaComm public metaComm;

    constructor(address _task, address _order, address _metaComm) {
        taskAddr = ITask(_task);
        orderAddr = _order;

        metaComm = IMetaComm(_metaComm);
    }

    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        return generateTokenUri(tokenId);
    }

    function genAttributes(
        uint orderId,
        uint48 taskskills,
        string memory attachment
    ) internal view returns (string memory) {

        Order memory order = IOrder(orderAddr).getOrder(orderId);
        uint startTs = order.startDate;
        uint endTs = startTs + IStage(orderAddr).totalStagePeriod(orderId);

        string memory valueStr = metaComm.tokenAmountApprox(
            order.amount,
            order.token,
            false
        );

        return
            string(
                abi.encodePacked(
                    metaComm.skillAttributes(taskskills, 0),
                    metaComm.skillAttributes(taskskills, 1),
                    metaComm.skillAttributes(taskskills, 2),
                    '{"trait_type": "Amount",',
                    '"value": "',
                    valueStr,
                    '"},',
                    '{"trait_type": "Start",',
                    '"value": "',
                    metaComm.dateTime(startTs),
                    '"},',
                    '{"trait_type": "End",',
                    '"value": "',
                    metaComm.dateTime(endTs),
                    '"},',
                    '{"trait_type": "IPFS",',
                    '"value": "',
                    attachment,
                    '"}'
                )
            );
    }

    // refer: https://docs.opensea.io/docs/metadata-standards
    function generateTokenUri(
        uint orderId
    ) internal view returns (string memory) {
        uint taskId;
        {
            Order memory order = IOrder(orderAddr).getOrder(orderId);
            taskId = order.taskId;
        }

        string memory svg = generateSVGBase64(generateSVG(taskId));
        (
            string memory title,
            string memory attachment,
            ,
            ,
            ,
            uint48 taskskills,
            ,

        ) = taskAddr.getTaskInfo(taskId);

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "DeTask Issuer #',
            Strings.toString(orderId),
            '",',
            '"title": "',
            title,
            '",',
            '"description": " More details on: https://detask.xyz/order/',
            Strings.toString(orderId),
            '",', // on ...
            '"image": "',
            svg,
            '",',
            '"attributes": [',
            genAttributes(orderId, taskskills, attachment),
            "]",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function skillSVGs(uint48 taskskills) internal view returns (string memory svgString){
        uint pos = 36;
        string memory curSVG = "";
        for(uint i = 0; i < 4; i++) {
            (curSVG, pos) = skillSVG(taskskills, i, pos);
            svgString = string(abi.encodePacked(svgString, curSVG));
        }
        
    }

    function skillSVG(
        uint48 taskskills,
        uint i, 
        uint posStart
    ) internal view returns (string memory svgString, uint pos) {
        uint skill = taskskills.get(i);
        if (skill > 0) {
            string memory label = metaComm.skills(skill);
           
            svgString = string(
                    abi.encodePacked(
                        '<text class="c7" transform="translate(',
                        Strings.toString(posStart),
                        ' 146.48)">',
                        label,
                        "</text>"
                    )
                );

            (uint slen, uint blen) = label.strlen();
            pos = posStart + slen * 5 + 10;
        } else {
            pos = posStart;
            svgString = "";
        }
    }

    function generateSVG(uint orderId) public view returns (bytes memory svg) {
        Order memory order = IOrder(orderAddr).getOrder(orderId);
        uint taskId = order.taskId;
        (
            string memory title,
            string memory attachment,
            ,
            ,
            ,
            uint48 taskskills,
            ,

        ) = taskAddr.getTaskInfo(taskId);

        string memory valueStr = metaComm.tokenAmountApprox(
            order.amount,
            order.token,
            true
        );

        return
            abi.encodePacked(
                '<svg id="l1" data-name="L1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 470 268">',
                "<defs>",
                '<linearGradient id="a4" x1="1.42" y1="134" x2="468.44" y2="134" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#dcff65"/><stop offset="1" stop-color="#fff"/></linearGradient>',
                '<linearGradient id="b3" x1="298.21" y1="218.48" x2="329.4" y2="218.48" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#da0035"/><stop offset=".99" stop-color="#ff766e"/><stop offset="1" stop-color="#ff776f"/></linearGradient>',
                '<linearGradient id="b4" x1="298.21" y1="168.51" x2="457.31" y2="168.51" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#da0035"/><stop offset=".52" stop-color="#ed7575"/><stop offset="1" stop-color="#ffe6b2"/></linearGradient>',
                '<linearGradient id="b6" x1="292.21" y1="224.48" x2="323.4" y2="224.48" xlink:href="#b3"/>',
                '<linearGradient id="b5" x1="292.21" y1="174.51" x2="451.31" y2="174.51" xlink:href="#b4"/>',
                '<clipPath id="clip-path"><path d="M0 0h410.59A46.41 46.41 0 0 1 457 46.41v161.18A46.41 46.41 0 0 1 410.59 254H0V0Z" style="fill:none"/>    </clipPath>',
                "<style>.c6,.c7{fill:#fff;font-size:9.04px}.c6{font-family:PingFangSC-Light,PingFang SC}.c7{font-family:PingFangSC-Medium,PingFang SC}.c11{clip-path:url(#clip-path)}</style>",
                "</defs>",
                '<path style="fill:url(#a4)" d="M-.01 0h469.99v268H-.01z"/>',
                '<path d="M410.59 254H0V0h410.59A46.41 46.41 0 0 1 457 46.41v161.18A46.41 46.41 0 0 1 410.59 254Z" style="fill:#1f1e2e"/>',
                '<g style="opacity:.2"><text transform="rotate(-90 109.85 76.4)" style="font-family:PingFangSC-Semibold,PingFang SC;fill:#fff;font-size:41.17px;letter-spacing:.05em">ISSUER</text></g>',
                '<text transform="translate(11.97 71.69)" style="font-size:28.52px;font-family:PingFangSC-Semibold,PingFang SC;fill:#fff">',
                title,
                "</text>",
                '<text class="c6" transform="translate(36 132.92)">Skill:</text>',
                skillSVGs(taskskills),
                '<text class="c6" transform="translate(36 164.3)">Token ID:</text><text class="c7" transform="translate(36 176.96)">',
                Strings.toString(orderId),
                '</text><text class="c6" transform="translate(36 101.95)">Task:</text>  <text class="c7" transform="translate(36 115.6)">',
                attachment,
                '</text><text class="c6" transform="translate(36 195.23)">Amount:</text><text class="c7" transform="translate(36 207.89)">',
                valueStr,
                "</text>",
                '<g style="opacity:.5"><path d="M328.84 236.5a17 17 0 0 1-17 17h-13.07v-53.07a17 17 0 0 1 17-17h13.08Z" style="stroke:url(#b3);stroke-miterlimit:10;stroke-width:1.12px;fill:none"/> <path d="M373.76 83.52h-57.85a17.14 17.14 0 0 0-17.14 17.14v48.87h95.03a12.57 12.57 0 0 1 12.57 12.57v8.8a12.57 12.57 0 0 1-12.57 12.57h-31v70.06h11a83 83 0 0 0 83-83v-4a83 83 0 0 0-83.04-83.01Z" style="stroke:url(#b4);stroke-miterlimit:10;stroke-width:1.12px;fill:none"/></g>',
                '<path d="M322.84 242.5a17 17 0 0 1-17 17h-13.07v-53.07a17 17 0 0 1 17-17h13.08Z" style="stroke:url(#b6);stroke-miterlimit:10;stroke-width:1.12px;fill:none" class="c11"/>',
                '<path d="M367.76 89.52h-57.85a17.14 17.14 0 0 0-17.14 17.14v48.87h95.03a12.57 12.57 0 0 1 12.57 12.57v8.8a12.57 12.57 0 0 1-12.57 12.57h-31v70.06h11a83 83 0 0 0 83-83v-4a83 83 0 0 0-83.04-83.01Z" style="stroke:url(#b5);stroke-miterlimit:10;stroke-width:1.12px;fill:none" class="c11"/>',
                "</svg>"
            );
    }

    function generateSVGBase64(bytes memory svgFormat)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgFormat)
            )    
        );
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct TaskInfo {
    string title;
    string attachment;
    uint8 currency;
    uint128 budget;
    uint32 period;
    uint48 skills;    // uint8[6]
    uint32 timestamp;
    bool disabled;
}


interface ITask {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tasks(uint256 tokenId)  external view returns (TaskInfo memory);
    function getTaskInfo(uint256 tokenId)  external view returns (string memory title,
        string memory attachment,
        uint8 currency,
        uint128 budget,
        uint32 period,
        uint48 skills,    // uint8[6]
        uint32 timestamp,
        bool disabled);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


enum OrderProgess {
    Init,
    Staged,
    Ongoing,
    IssuerAbort,
    WokerAbort,
    Done
}

enum PaymentType {
    Unknown,
    Due,   // by Due
    Confirm // by Confirm , if has pre pay
}



struct Order {
    uint taskId;
    address issuer;
    uint96 amount;
    
    address worker;
    uint96 payed;

    address token;
    OrderProgess progress;   // PROG_*
    PaymentType payType;
    uint32 startDate;
}

interface IOrder {
    function getOrder(uint orderId) external view returns (Order memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStage {
  function stagesLength(uint orderId) external view returns(uint len);
  function setStage(uint _orderId, uint[] memory _amounts, uint[] memory _periods) external;
  function prolongStage(uint _orderId, uint _stageIndex, uint newPeriod) external;
  function appendStage(uint _orderId, uint _amount, uint _period) external;
  function totalAmount(uint orderId) external view returns(uint total);
  function totalStagePeriod(uint orderId) external view returns(uint total);
  function startOrder(uint _orderId) external;
  function withdrawStage(uint _orderId, uint _nextStage) external;
  function confirmDelivery(uint _orderId, uint _stageIndex) external;
  function abortOrder(uint _orderId, bool issuerAbort) external returns(uint currStageIndex, uint issuerAmount, uint workerAmount);
  function pendingWithdraw(uint _orderId) external view returns (uint pending, uint nextStage);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMetaComm {
    function skills(uint i) external view returns (string memory);
    function skillAttributes(uint48 taskskills, uint i) external view returns (string memory);
    function dateTime(uint ts) external view returns (string memory datatime);
    function amountApprox(uint taskbudget, uint8 currency, bool escape) external view returns (string memory budget);
    function tokenAmountApprox(uint amount, address token, bool escape) external view returns (string memory budget);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BytesLib.sol";

library MyStrings {
    using BytesLib for bytes;


    function strlen(string memory s) internal pure returns (uint256 len, uint256 bytelength) {
        uint256 i = 0;
        bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
    }

    function shorten(string memory origin, uint256 maxlength)
        internal
        view
        returns (string memory)
    {
        if (maxlength < 5) return origin;
        bytes memory b = bytes(origin);
        uint256 len = b.length;

        if (len <= maxlength) return origin;

        uint256 kickLength = len - maxlength + 3; // ...

        uint256 mid = (maxlength - 3) / 2;
        uint256 start = (maxlength - 3) / 2;
        if (mid * 2 + 3 != maxlength) {
            start++;
        }
        uint256 end = start + kickLength;

        bytes memory part1 = b.slice(0, start);
        string memory ellipse = "...";
        bytes memory part2 = b.slice(end, len - end);

        return string(abi.encodePacked(string(part1), ellipse, string(part2)));
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

pragma solidity >=0.8.0;

// uint12[4]
library uint12a4 {
    uint constant bits = 12;
    uint constant elements = 4;
    
    uint constant range = 1 << bits;
    uint constant max = range - 1;

    function get(uint va, uint index) internal pure returns (uint) {
        require(index < elements, "index invalid");
        return (va >> (bits * index)) & max;
    }

    function set(uint va, uint index, uint value) internal pure returns (uint) {
        require(index < elements, "index invalid");
        require(value < range, "value invalid");
        uint pos = index * bits;
        return (va & ~(max << pos)) | (value << pos);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
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
                } {
                    mstore(mc, mload(cc))
                }

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