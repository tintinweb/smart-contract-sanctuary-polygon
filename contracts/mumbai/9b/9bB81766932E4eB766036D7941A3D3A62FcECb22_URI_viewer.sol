// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Base64.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "./utils/tools.sol";
contract URI_viewer
{
    struct Box {
        uint256 id;
        string name;
        uint256 mintedSupply; //added this to allow for tracking from 0
        uint256 supply;
        uint256 price;
        string uri;
        uint16 probability_rare;
        uint16 probability_epic;
        uint16 probability_legendary;
    }
    struct Card {
        string name;
        string uri;
        Tools.CardType cardType;
        bool genesis;
        uint256 date;
        uint256 id;
    }
    address private immutable contract_address;
    constructor(
        address _contract_address
    ) {
        // _initializeEIP712(name);
        contract_address=_contract_address;
    }
    function generate_uri(uint256 tokenId) public view returns (string memory) {
        (bool success, bytes memory data) = contract_address.staticcall(
            abi.encodeWithSignature("MAXIMUM_CASE")
        );
        uint256 MAXIMUM_CASE = abi.decode(data, (uint256));
        if(tokenId<=MAXIMUM_CASE){
            (success, data) = contract_address.staticcall(
                abi.encodeWithSignature("boxes(uint256)",tokenId)
            );
            Box memory box = abi.decode(data, (Box));
            return string(abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(abi.encodePacked(
                    '{"description":"hate u","image":"',box.uri,'","name":"',box.name,
                    '","attributes":[{"trait_type":"type","value":"Box"},{"display_type":"boost_percentage","trait_type":"Rare drop","value":',convertToPercentage(box.probability_rare),
                    '},{"display_type":"boost_percentage","trait_type":"Epic drop","value":',convertToPercentage(box.probability_epic),
                    '},{"display_type":"boost_percentage","trait_type":"Legendary drop","value":',convertToPercentage(box.probability_legendary),
                    '},{"trait_type":"Minted","value":',convertToPercentage(box.supply),',"max_value":',Strings.toString(box.mintedSupply),
                    '}]}'
                ))
            ));
        }
        (success, data) = contract_address.staticcall(
            abi.encodeWithSignature("cards(uint256)",tokenId)
        );
        Card memory card = abi.decode(data, (Card));
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(abi.encodePacked(
                '{"description":"hate u","image":"',card.uri,'","name":"',card.name,
                '","attributes":[{"trait_type":"type","value":"Card"},{"trait_type":"rarity","value":"',rarity2string(card.cardType),
                '"},{"trait_type":"genesis","value":"',bool2string(card.genesis),
                '"},{"display_type":"date","trait_type":"creation","value":',Strings.toString(card.date),'}]}'
            ))
        ));
    }
    function bool2string(bool b) internal pure returns (string memory) {
        return b ? "true" : "false";
    }
    function rarity2string(Tools.CardType _rarity) internal pure returns(string memory){
        if(_rarity==Tools.CardType.UNOBTAINABLE) return "UNOBTAINABLE";
        if(_rarity==Tools.CardType.LEGENDARY) return "LEGENDARY";
        if(_rarity==Tools.CardType.EPIC) return "EPIC";
        if(_rarity==Tools.CardType.RARE) return "RARE";
        return "COMMON";
    }
    function convertToPercentage(uint256 number) public pure returns (string memory) {
        uint256 percentage = (number * 100) / 65535;
        uint256 decimalPart = (percentage * 100) % 100;

        return string(
            abi.encodePacked(
                Strings.toString(percentage),
                ".",
                Strings.toString(decimalPart)
            )
        );
    }
}
// if(tokenId<=MAXIMUM_CASE) return string(abi.encodePacked(
        //     'data:application/json;base64,',
        //     Base64.encode(abi.encodePacked(
        //         '{"description":"hate u","image":"',
        //         boxes[tokenId].uri,
        //         '","name":"',
        //         boxes[tokenId].name,
        //         '"}'
        //     ))
        // ));
        // // string(abi.encodePacked(boxes[tokenId].uri));
        // // Card memory item = _tokenCard[tokenId];
        // return string(abi.encodePacked(
        //     'data:application/json;base64,',
        //     Base64.encode(abi.encodePacked(
        //         '{"description":"hate u","image":"',
        //         _tokenCard[tokenId].uri,
        //         '","name":"',
        //         _tokenCard[tokenId].name,
        //         '","attributes":[{"trait_type":"rarity","value":"'
        //         ,Strings.toString(uint(_tokenCard[tokenId].cardType)),
        //         '"}]}'
        //     ))
        // ));//TODO: isgenesis
/*
{
   "description":"Cool Cats is a collection of 9,999 randomly generated and stylistically curated NFTs that exist on the Ethereum Blockchain. Cool Cat holders can participate in exclusive events such as NFT claims, raffles, community giveaways, and more. Remember, all cats are cool, but some are cooler than others. Visit [www.coolcatsnft.com](https://www.coolcatsnft.com/) to learn more.",
   "image":"https://ipfs.io/ipfs/QmXHPUiqx7a1BtxibC3kSjn8vi6eVt2jtx7zpjMJjcPcSf",
   "name":"Cool Cat #1782",
   "attributes":[
      {
         "trait_type":"body",
         "value":"blue cat skin"
      },
      {
         "trait_type":"hats",
         "value":"hat visor blue"
      },
      {
         "trait_type":"shirt",
         "value":"combat black"
      },
      {
         "trait_type":"face",
         "value":"smirk"
      },
      {
         "trait_type":"tier",
         "value":"classy_1"
      }
   ],
   "points":{
      "Body":0,
      "Hats":2,
      "Shirt":4,
      "Face":1
   }
}*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Tools {
    using SafeMath for uint256;

    enum CardType {
        COMMON,
        RARE,
        EPIC,
        LEGENDARY,
        UNOBTAINABLE
    }
    function concatenateUint48(uint16 a, uint16 b, uint16 c) public pure returns (uint48) {
        uint48 result = (uint48(a) << 32) | (uint48(b) << 16) | uint48(c);
        return result;
    }

    function reverseConcatenation(uint48 value) public pure returns (uint16, uint16, uint16) {
        uint16 a = uint16(value >> 32);
        uint16 b = uint16((value >> 16) & 65535);
        uint16 c = uint16(value & 65535);
        return (a, b, c);
    }
    function extractBits(uint256 value) public pure returns (uint256, uint256) {        
        return (value >> (256-24), value & ((1 << (256-24)) - 1));
    }
    function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        }else if (exponent == 1) {
            return base;
        }else if (base == 0 && exponent != 0) {
            return 0;
        }else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++){
                z = z.mul(base);
            }
            return z;
        }
    }
    function getRarity (uint256 random,uint48 value) public pure returns (CardType) {
        uint256 rarity = (random & 65535);
        if (rarity < (value & 65535)) {
            return CardType.LEGENDARY;
        }else if (rarity < ((value >> 16) & 65535)) {
            return CardType.EPIC;
        }else if(rarity < (value >> 32)){
            return CardType.RARE;
        } else{
            return CardType.COMMON;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}