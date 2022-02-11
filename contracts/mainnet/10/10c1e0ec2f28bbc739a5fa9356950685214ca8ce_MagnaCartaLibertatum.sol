// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

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

contract MagnaCartaLibertatum is ERC721, ERC721Enumerable, Ownable {
    mapping(string => bool) private takenNames;
    mapping(uint256 => Attr) public attributes;

    struct Attr {
        string name;
        string article;
        uint8 articleno; 
    }

    constructor() ERC721("Magna Carta Libertatum 1215", "MCL") {}

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to, 
        uint256 tokenId, 
        string memory _name, 
        string memory _article,  
        uint8 _articleno) 
    public onlyOwner {
        _safeMint(to, tokenId);
        attributes[tokenId] = Attr(_name, _article, _articleno);
    }

    function getSvg(uint tokenId) private view returns (string memory) {
        string memory svg;
        svg = "<svg width='500px' height='500px' viewBox='0 0 500 500' xmlns='http://www.w3.org/2000/svg'> <path fill='#ffd05b' d='M500.001 250A250 250 0 0 1 250 500.001 250 250 0 0 1 0 250a250 250 0 0 1 500.001 0z'/> <path fill='#e6e4e5' d='M235.937 135.547h28.126v246.094h-28.126V135.547z'/> <path fill='#324a5e' d='M190.625 358.203h118.359v26.172H190.625v-26.172zm-71.094-229.297L64.063 267.579l6.64 3.124 44.922-112.109v110.547h7.812V158.594l44.532 112.109 7.031-3.124Z'/> <path fill='#f1543f' d='M64.063 269.531c0 31.25 25 56.25 55.469 56.25s55.469-25.391 55.469-56.25v-1.953H64.063v1.953z'/> <path fill='#324a5e' d='m380.469 128.906 55.468 138.673-6.64 3.124-44.922-112.109v110.547h-7.812V158.594l-44.532 112.109-7.031-3.124Z'/> <path fill='#f1543f' d='M435.937 269.531c0 31.25-25 56.25-55.469 56.25s-55.469-25.391-55.469-56.25v-1.953h110.937v1.953z'/> <path fill='#2b3b4e' d='M168.36 380.078h163.281v26.172H168.36v-26.172z'/> <path fill='#efefef' d='M373.438 121.093c-17.969-1.953-92.579-49.219-123.437-14.844-30.86-34.765-105.468 12.891-123.437 14.453-17.969 1.953-27.734-14.453-27.734-14.453l10.547 29.296h281.639l10.547-29.296c0 .001-9.766 16.408-28.125 14.844z'/> </svg>";
        return svg;
    }    

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', attributes[tokenId].name, '",',
                    '"image_data": "', getSvg(tokenId), '",',
                    '"attributes": [{"trait_type": "Article No", "value": ', uint2str(attributes[tokenId].articleno), '},',
                    '{"trait_type": "Article", "value": "', attributes[tokenId].article, '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
}