/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// File: utils/Base64.sol

library Base64 {

    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
                                            
    function encode(string memory _str) internal pure returns (string memory) {
        uint i = 0;                                 // Counters & runners
        uint j = 0;

        uint padlen = bytes(_str).length;           // Lenght of the input string "padded" to next multiple of 3
        if (padlen%3 != 0) padlen+=(3-(padlen%3));

        bytes memory _bs = bytes(_str);
        bytes memory _ms = new bytes(padlen);       // extra "padded" bytes in _ms are zero by default
        // copy the string
        for (i=0; i<_bs.length; i++) {              // _ms = input string + zero padding
            _ms[i] = _bs[i];
        }
 
        uint res_length = (padlen/3) * 4;           // compute the length of the resulting string = 4/3 of input
        bytes memory res = new bytes(res_length);   // create the result string

        for (i=0; i < padlen; i+=3) {
            uint c0 = uint(uint8(_ms[i])) >> 2;
            uint c1 = (uint(uint8(_ms[i])) & 3) << 4 |  uint(uint8(_ms[i+1])) >> 4;
            uint c2 = (uint(uint8(_ms[i+1])) & 15) << 2 | uint(uint8(_ms[i+2])) >> 6;
            uint c3 = (uint(uint8(_ms[i+2])) & 63);

            res[j]   = base64stdchars[c0];
            res[j+1] = base64stdchars[c1];
            res[j+2] = base64stdchars[c2];
            res[j+3] = base64stdchars[c3];

            j += 4;
        }

        // Adjust trailing empty values
        if ((padlen - bytes(_str).length) >= 1) { res[j-1] = base64stdchars[64];}
        if ((padlen - bytes(_str).length) >= 2) { res[j-2] = base64stdchars[64];}
        return string(res);
    }


    function decode(string memory _str) internal pure returns (string memory) {
        require( (bytes(_str).length % 4) == 0, "Length not multiple of 4");
        bytes memory _bs = bytes(_str);

        uint i = 0;
        uint j = 0;
        uint dec_length = (_bs.length/4) * 3;
        bytes memory dec = new bytes(dec_length);

        for (; i< _bs.length; i+=4 ) {
            (dec[j], dec[j+1], dec[j+2]) = dencode4(
                bytes1(_bs[i]),
                bytes1(_bs[i+1]),
                bytes1(_bs[i+2]),
                bytes1(_bs[i+3])
            );
            j += 3;
        }
        while (dec[--j]==0)
            {}

        bytes memory res = new bytes(j+1);
        for (i=0; i<=j;i++)
            res[i] = dec[i];

        return string(res);
    }


    function dencode4 (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) private pure returns (bytes1 a0, bytes1 a1, bytes1 a2)
    {
        uint pos0 = charpos(b0);
        uint pos1 = charpos(b1);
        uint pos2 = charpos(b2)%64;
        uint pos3 = charpos(b3)%64;

        a0 = bytes1(uint8(( pos0 << 2 | pos1 >> 4 )));
        a1 = bytes1(uint8(( (pos1&15)<<4 | pos2 >> 2)));
        a2 = bytes1(uint8(( (pos2&3)<<6 | pos3 )));
    }

    function charpos(bytes1 char) private pure returns (uint pos) {
        for (; base64stdchars[pos] != char; pos++) 
            {}    //for loop body is not necessary
        require (base64stdchars[pos]==char, "Illegal char in string");
        return pos;
    }

}
// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: DynamicNftUriGetter.sol

pragma solidity ^0.8.0;

abstract contract DynamicNftUriGetter {
    function uri(uint256 tokenId) external view virtual returns(string memory) {}
}

// File: nfts/BlockchainPolygon.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




contract BlockchainPolygon is DynamicNftUriGetter {
    using Strings for uint256;
    using Strings for uint128;

    constructor() {
    }

    function _attributes(string memory blockNumberString) private pure returns(string memory) {
        return string(
            abi.encodePacked(
                '[',
                    '{"trait_type":"Block Number","value":"',blockNumberString,'"}'
                ']'
            )
        );
    }

    function _point(bytes32 seed) private pure returns(string memory) {
        bytes16[2] memory xy = [bytes16(0), 0];
        assembly {
            mstore(xy, seed)
            mstore(add(xy, 16), seed)
        }
        
        return string(
            abi.encodePacked(
                (uint128(xy[0]) % 2048).toString(),",",(uint128(xy[1]) % 2048).toString()," "
            )
        );
    }

    function _svg() private view returns(string memory) {
        string memory points = "";

        for (uint256 i = 16; i > 0;)
            points = string(
                abi.encodePacked(
                    points,
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--)),
                    _point(blockhash(block.number - i--))
                )
            );


        return string(
            abi.encodePacked(
                "<svg width='2048' height='2048' viewPort='0 0 2048 2048' style='background:#181a21' xmlns='http://www.w3.org/2000/svg'>",
                "<polygon filter='url(#f)' points='",points,"' style='fill:none;stroke:#8247e5;stroke-width:50'/>",
                "<defs><filter id='f' width='200%' height='200%'><feGaussianBlur result='blurOut' in='offOut' stdDeviation='50'/><feBlend in='SourceGraphic' in2='blurOut' mode='normal'/></filter></defs>",
                "</svg>"
            )
        );
    }

    function uri(uint256) public view override returns (string memory) {
        string memory blockNumberString = block.number.toString();
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(string(abi.encodePacked(
                        '{"name":"Blockchain Polygon",', 
                        '"description":"A dynamic NFT, changing dynamically based on the 16 most recent blocks on the chain.\\n',
                            'Every point of this polygon representing a block, positioned based on the block hash.\\n\\n',
                            'All of the item metadata of this NFT lives on the blockchain.",',  
                        '"image_data":', '"', _svg(), '",',
                        '"attributes":', _attributes(blockNumberString), 
                        '}')))
                )
            );
    }
}