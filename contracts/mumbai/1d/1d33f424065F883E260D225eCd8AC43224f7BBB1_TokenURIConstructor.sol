// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ITokenURIConstructor.sol";
import "./utils/LibURIConstructor.sol";


contract TokenURIConstructor is ITokenURIConstructor {

    function getTokenURI(
        uint256 tokenId, 
        address owner, 
        string memory image, 
        string memory contractURI
    ) external pure returns(string memory) {
        return LibURIConstructor.constructTokenURI(
            LibURIConstructor.ConstructTokenURIParams(
                tokenId, 
                owner, 
                image, 
                contractURI
            )
        );
    }
}

pragma solidity ^0.8.12;


library Strings  {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    function concat(string memory str1, string memory str2) internal pure returns(string memory) {
        return string.concat(str1,str2);
    }
    function concat(string memory str1, string memory str2, string memory str3) internal pure returns(string memory) {
        return string.concat(str1,str2,str3);
    }
    function concat(string memory str1, string memory str2, string memory str3, string memory str4) internal pure returns(string memory) {
        return string.concat(str1,str2,str3,str4);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return toHexString((uint256(uint160(addr))), 20);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.12;
pragma abicoder v2;

import './String.sol';
import './Base64.sol';

library LibURIConstructor {
    using Strings for *;

    string private constant prefix = "data:application/json;base64,";

    struct ConstructTokenURIParams {
        uint256 tokenId;
        address owner;
        string image;
        string contractURI;
    }

    function constructTokenURI(ConstructTokenURIParams memory params) internal pure returns (string memory) {
        string memory desc = generateDescription(params);

        return prefix.concat(
                Base64.encode(
                    string.concat(
                        '{"tokenId:"',
                        params.tokenId.toString(),
                        '", owner":"',
                        params.owner.addressToString(),
                        '", "description":"',
                        desc,
                        '", "image": "',
                        params.image,
                        '"}'
                    )
                )
            );
    }

    function generateDescription(ConstructTokenURIParams memory params)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'Capneo DI-NFT ',
                    params.tokenId.toString(),
                    ' represents (rounded down) ',
                    params.tokenId / 10_000,
                    ' cm^2. To learn more about the represented object, check the contract metadata at: ',
                    params.contractURI
                )
            );
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }

    function encode(string memory str) internal pure returns(string memory) {
        return encode(bytes(str));
    }
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;


interface ITokenURIConstructor {
    function getTokenURI(
        uint256 tokenId, 
        address owner, 
        string memory image, 
        string memory contractURI
    ) external pure returns(string memory);
}