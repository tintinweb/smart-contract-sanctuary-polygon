// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// @author     https://twitter.com/ClubRebelNFTs
/**
    Utility class for keeping Ticket Model, and SVG generation algo
 */

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library RebelRaffleUtil {
    using Strings for uint32;

    struct Ticket {
        string ownerName;
        bool isWinner; // to declare winner
        uint32 winningTimestamp;
        bool isClaimed; // reward is consumed
        uint32 claimTimestamp;
        string rewardDetail;// whats the reward given to this particular Ticket on winning
    }


    /// @dev Function creates Token URI in base64 json encoded format for NFT getting minted
    /// @param tokenId Id of current token 
    /// @param ticketDetail Details of Volunteer who's certificate to mint
    function getTokenURI(
        uint tokenId,
        Ticket storage ticketDetail
    ) public view returns (string memory) {
        
        bytes memory dataURI = abi.encodePacked(
            '{"name": "Rebel Raffle Ticket #', uint32(tokenId).toString(), 
            '","description": "The Rebel Club Raffle Ticket, that is a gateway to various rewards, is allocated to ', ticketDetail.ownerName, '","image": "', 
            generateSVG(tokenId, ticketDetail), '"'     
        );
        if (ticketDetail.isWinner) {            
            bytes memory tokenAttribs = getTokenTraits(ticketDetail);
            dataURI = abi.encodePacked(dataURI, ",", tokenAttribs);
        }
        dataURI = abi.encodePacked(dataURI, '}');
        return string(abi.encodePacked( "data:application/json;base64,", Base64.encode(dataURI)));
    }

    /**
        Generates metadata for a given Ticket
     */
    function getTokenTraits(Ticket storage ticketDetail) public view returns(bytes memory) {
        bytes memory tokenTraits = abi.encodePacked('');
        if (ticketDetail.isWinner || ticketDetail.isClaimed) {            
            if(ticketDetail.isWinner) {
                tokenTraits = abi.encodePacked(
                    tokenTraits,
                    '{"trait_type": "Winning Date", "display_type": "date", "value": ', (uint32(ticketDetail.winningTimestamp)).toString(), '},'
                    '{"trait_type": "Rewarded By", "value": "', ticketDetail.rewardDetail  , '"}'
                );
            }
            if(ticketDetail.isClaimed) {
                if (tokenTraits.length > 0) {
                    tokenTraits = abi.encodePacked(tokenTraits, ",");    
                }
                tokenTraits = abi.encodePacked(
                        tokenTraits,
                        '{"trait_type": "Claiming Date", "display_type": "date", "value": ', (uint32(ticketDetail.claimTimestamp)).toString(), '}'
                );
            }
            tokenTraits = abi.encodePacked('"attributes": [', tokenTraits, ']');
        }
        return tokenTraits;
    }

    /// @dev This function creates the SVG image on-chain for the Raffle Ticket NFT
    /// @param tokenId Ticket id of the token (same as token id)
    /// @param ticketDetail ticket details to print in the SVG
    function generateSVG(
        uint tokenId,
        Ticket storage ticketDetail
    ) private view returns (string memory) {
        bytes memory svg = abi.encodePacked(

            '<?xml version="1.0" encoding="UTF-8"?>'
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="570pt" height="200pt" viewBox="0 0 570 200">'
                '<style> text { text-transform: uppercase; letter-spacing: 4px; fill: #ffffff; font-family: "Cocomat Pro", "Gill Sans", "Gill Sans MT", Calibri, "Trebuchet MS", sans-serif; } .font-color-red { fill: #ff1616; } .text-anchor-middle { text-anchor: middle; } .font-size-small { font-size: 10px; } .font-size-medium { font-size: 15px; } .font-size-large { font-size: 30px; } </style>',
                '<rect width="570" height="200" x="0" y="0"/><rect width="70" height="200" x="500" y="0" class="font-color-red"/><path d="M 530, 0 V 200" id="NamePath"/>',
                '<text class="text-anchor-middle font-size-medium" x="100" y="50"><textPath href="#NamePath">', ticketDetail.ownerName, '</textPath></text>',
                ((ticketDetail.isWinner) ? '<text class="text-anchor-middle font-size-medium" x="20" y="20">&#11088;</text>': ''),
                '<text class="text-anchor-middle font-size-medium" x="275" y="60">THE REBEL CLUB</text>',
                '<text class="text-anchor-middle font-size-large" x="275" y="100">RAFFLE TICKET</text>',
                '<text class="text-anchor-middle font-size-medium" x="275" y="130">GATEWAY TO GIVEAWAY</text>',
                ((ticketDetail.isClaimed) ? '<text class="text-anchor-middle font-color-red font-size-medium" x="275" y="180">CLAIMED</text>': ''),
                '<text class="font-size-small" x="20" y="180"># ', uint32(tokenId).toString() ,'</text>',
            '</svg>'
        );
        return string(abi.encodePacked( "data:image/svg+xml;base64,", Base64.encode(svg)));
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