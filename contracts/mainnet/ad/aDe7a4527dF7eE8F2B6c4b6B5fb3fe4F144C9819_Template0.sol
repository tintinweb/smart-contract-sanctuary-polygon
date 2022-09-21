// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../VVords/0_diamond/libraries/AppStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../VVords/5_Onchain_Metadata/utils/UintToFloatString.sol";
import "../VVords/5_Onchain_Metadata/utils/SVGTextValidator.sol";

library Template0 {
    using UintUtils for uint;
    using SVGTextValidator for string;

    function image(uint256 tokenId) public view returns (string memory) {
        AppStorage.Word storage w = AppStorage.layout().words[tokenId];

        require(w.info.blockNumber != 0, "ERC721Metadata: URI query for nonexistent token");

        return string.concat('data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(
            _template({
                word1 : w.word[0].validate(),
                word2 : w.word[1].validate(),
                word3 : w.word[2].validate()
            })
        )));
    }

    function _template(
        string memory word1,
        string memory word2,
        string memory word3
    ) private pure returns(string memory) {      
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><style>@font-face {font-family: "C";src: url("data:font/woff2;charset=utf-8;base64,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") format("woff2"); font-weight: 500; font-style: normal; font-display: swap;}.f { width: 100%; height: 100%; }.b { fill: whitesmoke; }.a { animation: o 2s ease-out forwards; }@keyframes o { 10% { opacity: 1; } 100% { opacity: 0; } }tspan { fill: black; font-family: "C"; font-size: 50px; text-anchor: middle; }.small { font-size: 25px;  }</style><rect class="b f" /><svg y="455" overflow="visible"><text><tspan x="500">',
            word1,
            '</tspan><tspan x="500" dy="1em">',
            word2,
            '</tspan><tspan class="small" x="500" dy="4em">',
            word3,
            '</tspan></text></svg><rect class="b f a" /></svg>'
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library AppStorage {

    bytes32 constant APP_STORAGE_POSITION = keccak256("APP_STORAGE_POSITION");

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    struct Layout {
        Setting setting;
        Global global;
        mapping(uint256 => Word) words;
        mapping(address => User) users;
        mapping(bytes32 => WordHash) wordHashes;
        mapping(uint256 => Template) templates;
    }

// global -------------------------------------
    struct Global {
        uint256 initialBlock;
        uint256 nextTokenId;
        uint256 totalValue;
        uint256 totalPower;
    }

// setting -------------------------------------
    struct Setting{
        uint256 minInitialValue;
        uint256 minDomValue;
        uint256 withdrawableValueFraction; //denominator is 10,000
        uint256 votingPowerFraction; //denominator is 10,000
        uint256 timeToFullVotingPower;
        string defaultExternalURL;
        string notification1;
        string notification2;
        bool inviteRequired;
    }

// words --------------------------------------
    struct Word {
        string[] word;
        WordInfo info;
        WordValues values;
        mapping(bytes32 => EternalStorage) es;
        uint256 domsCount;
        mapping(uint256 => Dom) doms;
    }

    struct EternalStorage {
        bool varBool;
        uint256 varUint;
        int256 varInt;
        address varAddr;
        string varStr;
    }

    struct WordInfo {
        string tags;
        string externalURL;
        address author;
        uint256 blockNumber;
        uint256 randomResult;
        uint256 template;
    }

    struct WordValues{
        uint256 initialValue;
        uint256 initialPower;
        uint256 value;
        uint256 power;
    }

    struct Dom{
        address dommer;
        uint256 amount;
        string mention;
    }

// User ---------------------------------------------
    struct User {
        uint256 power;
        uint256 lastVotingPowerRecorded;
        uint256 lastTransferTimestamp;
        uint256 votingPowerSpent;
    }

// WordHash ---------------------------------------------
    struct WordHash {
        mapping(uint256 => uint256) indexToId;
        mapping(uint256 => uint256) idToIndex;
        uint256 wordHashCounter;
    }

// Template ---------------------------------------------
    struct Template {
        address contAddr;
        address creator;
        uint256 price;
        string description;
        uint[] charCount;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@solidstate/contracts/utils/UintUtils.sol';

/**
 * @author https://www.linkedin.com/in/renope/
 */
library UintToFloatString {
    using UintUtils for uint;

    function floatString(
        uint256 number, 
        uint8 inDecimals,
        uint8 outDecimals
    ) internal pure returns(string memory h) {
        h = string.concat(
            (number / 10 ** inDecimals).toString(),
            outDecimals > 0 ? '.': ''
        );
        while(outDecimals > 0){
            h = string.concat(
                h,
                inDecimals > 0 ?
                (number % 10 ** (inDecimals--) / 10 ** (inDecimals-1)).toString()
                : '0'
            );
            outDecimals--;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SVGTextValidator {

    function validate(string memory input) internal pure returns(string memory output) {
        bytes memory inBytes = bytes(input);
        bool has;
        for (uint16 i; i < inBytes.length; i++) {
            if (inBytes[i] == 0x26){
                has = true;
            }
        }
        if(!has) {
            return input;
        } else {
            bytes memory outBytes;
            for (uint16 i; i < inBytes.length; i++) {
                outBytes = bytes.concat(outBytes, inBytes[i]);
                if(inBytes[i] == 0x26) {
                    outBytes = bytes.concat(outBytes, "amp;");
                }
            }
            return string(outBytes);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}