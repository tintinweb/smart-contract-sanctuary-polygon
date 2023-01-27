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
// Copyright (c) 2022 xxxxxx xxxxxxxxxxxx xxx. All Rights Reserved
pragma solidity 0.8.x;

import {Base64} from "./Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract MetadataGenerator {

    string[] _topRight;
    string[] _topLeft;
    string[] _bottomRight;

    string curve = "curve: exp";
    string delta = "delta: 0.05%";
    string fee = "fee: 0.05%";
    string nft = "nft_symbol: 10,000";
    string xymbol = "token_symbol_: 1,000,000";

    /**
     * plants
     */
    function setTopRight(string memory svg_) external {
        _topRight.push(svg_);
    }

    /**
     * squiggle
     */
    function setTopLeft(string memory svg_) public {
        _topLeft.push(svg_);
    }

    /**
     * spaceship
     */
    function setBottomRight(string memory svg_) public {
        _bottomRight.push(svg_);
    }

    function _getComponent0() public view returns (string memory) {
        string memory svg00 = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1125 1125">' 
                '<defs>'
                    '<style>'
                        '.colorCore {',
                            bytes.concat(bytes('fill: #'),"ff00cd",bytes(';')), 
                        '}'
                        '.colorAccent00 {',
                            bytes.concat(bytes('fill: #'),"0091ff",bytes(';')),
                        '}'
                        '.colorAccent01 {',
                            bytes.concat(bytes('fill: #'),"ff89de",bytes(';')),
                        '}'
                        '.colorAccent02 {',
                            bytes.concat(bytes('fill: #'),"ff4300",bytes(';')),
                        '}'
                    '</style>'
                '</defs>'
            '<rect width="100%" height="100%" fill="black"/>',
            _topRight[0],
            '<path transform="translate(-15,-40)" id="curve" fill="transparent" d="M625.6,103.9c-45.4,97.4-50.2,212.3-3.9,324.8,80,194.3,288.1,321.2,503.4,323.5"/>'
            '<text width="1000" font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#curve" fill="white">',
            msg.sender,
            '</textPath>'
            '</text>'
            '<path id="xurve" transform="translate(-13,-20)" fill="transparent" d="M701,53.3c-61,88-72.5,242.4-30.6,344,72.3,175.5,260.2,290.1,454.7,292.2"/>'
            '<text width="1000" font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#xurve" class="colorCore">',
            address(this),
            '</textPath>'
            '</text>'));
        return svg00;
    }

    function _getComponent1() public view returns (string memory) {
        string memory svg01 = string(abi.encodePacked(
            '<path class="colorCore" d="m177.47,584.01h-41.4v-41.5h41.4v41.5Zm-39.4-2h37.4v-37.5h-37.4v37.5Z" transform="translate(-90,0)"/>'
            '<path class="colorCore" d="m176.37,543.41c0,8.8,0,28.9-20.6,36.4-2.7,1-5.7,1.7-9.2,2.2-2.9.4-6.1.6-9.6.6v.2h39.5l-.1-39.4h0Z" transform="translate(-90,0)"/>'
            '<text x="95" y="575" font-family="monospace" font-size="1.75em" fill="white">',
            curve,
            '</text>'
            '<polygon class="colorCore" points="176.47 631.72 137.07 631.72 156.77 592.31 176.47 631.72" transform="translate(-90,5)"/>'
            '<text x="95" y="629" font-family="monospace" font-size="1.75em" fill="white">',
            delta,
            '</text>'
            '<ellipse class="colorCore" cx="67" cy="656.82" rx="19.75" ry="5.61"/>'
            '<path class="colorCore" transform="translate(-90,10)" d="m137.07,650.34v24.77c0,3.1,8.84,5.61,19.75,5.61s19.75-2.51,19.75-5.61v-24.77c-4.09,3.14-13.56,4.09-19.75,4.09s-15.66-.94-19.75-4.09Z"/>'
            '<text x="95" y="683" font-family="monospace" font-size="1.75em" fill="white"> ',
            fee,
            '</text>'
            '<rect class="colorCore" x="47" y="732.51" width="39.5" height="39.5"/>'
            '<text x="95" y="763" font-family="monospace" font-size="1.75em" fill="white">',
            nft,
            '</text>'
            ));
        return svg01;
    }

    function _getComponent2() public view returns (string memory) {
        string memory svg02 = string(abi.encodePacked(
            '<path class="colorCore" d="m156.77,784.22h0c10.9,0,19.7,8.8,19.7,19.7h0c0,10.9-8.8,19.7-19.7,19.7h0c-10.9,0-19.7-8.8-19.7-19.7h0c0-10.9,8.8-19.7,19.7-19.7Z" transform="translate(-90,0)"/>'
            '<text x="95" y="816" font-family="monospace" font-size="1.75em" fill="white">',
            xymbol,
            '</text>',
            _topLeft[0],
            '<path d="M1087 779.7H602.3a37.3 37.3 0 0 1-37.3-37.3v-705A37.3 37.3 0 0 1 602.3 0H565V0h-42.3A37.3 37.3 0 0 1 560 37.4v271h-.3a37.3 37.3 0 0 1-37.3 37.3S0 345.6 0 345.6v5h522.5a37.3 37.3 0 0 1 37.2 37.3h.3v699.9a37.3 37.3 0 0 1-37.3 37.2h79.5a37.3 37.3 0 0 1-37.2-37.3V822a37.3 37.3 0 0 1 37.3-37.3h485.4A37.3 37.3 0 0 1 1125 822v-79.6a37.3 37.3 0 0 1-37.3 37.3Z" fill="white"/>',
            _bottomRight[0],
            '<path d="M664.1 576.7c0-49.6-35.7-91-82.8-99.8A37.3 37.3 0 0 1 565 446h-5c0 12.7-6.5 24-16.3 30.7a101.8 101.8 0 0 0-20 193.8h-1 1c6 2.5 12.4 4.4 18.9 5.7A37.3 37.3 0 0 1 560 708h5c0-13.3 7-25 17.4-31.6 6.6-1.3 12.8-3.2 18.8-5.7h1-.9a101.8 101.8 0 0 0 62.8-93.9Zm-78.9 93.9h-45.4a96.8 96.8 0 0 1-2-187.3h49.5c41.3 11 71.8 48.7 71.8 93.4s-31.5 83.7-73.9 93.9Z" fill="white"/>'
            '<circle cx="50%" cy="51.26%" r="99"/>'
            '<circle cx="50%" cy="51.26%" r="65" class="colorCore"/>'
            '<path d="M590.2 532.7c-2.8-2.4.4-6.7 3.5-4.8a53 53 0 0 1 16 16.3c8.6 13.5 9 30.7 3.2 30.7-4.6 0-8.6-1-8.6-15.1a36 36 0 0 0-14.1-27.1ZM571.4 520.7c4-.5 8 0 11.7 1.7 1.4.6 2.8 1.4 3.2 2.8a4 4 0 0 1-.4 2.7c-.2.3-.4.7-.7.8-.4.2-.7.2-1.1 0-1.4-.3-2.8-1-4-1.8a25 25 0 0 0-8.5-2.7c-.7 0-1.4-.2-1.8-.6-.6-.5-.5-1.5-.2-2.1.5-.8 1.5-1.3 1.7-.8ZM504.7 583a45.6 45.6 0 0 0 30.9 31.7c11.6 2.8 17-7.2 8.6-10.1-6-2.1-8.8 2-20.8-2.9-8-3.1-12.6-8.2-18.7-18.6ZM519 613.6a60.6 60.6 0 0 0 51.9 23.2 43 43 0 0 1-1.5-7c-1.5.5-3.1.6-4.7.6a71.4 71.4 0 0 1-45.7-16.8ZM572.1 629.9c.9 2 1.6 4 2 6.1 4.6-.8 9.1-2.2 13.2-4.2a20.5 20.5 0 0 1-2.5-7c-4 1.9-8.3 3.5-12.7 5Z" fill="white"/>'
            '<path d="M596 585c0 18.7-11 30-31.4 30-6.1 0-11.5-1-16-3 10.3-4.5 15.8-14 15.8-27v-5.6c0-.6-.6-1.1-1.2-1.1h-30.6v-36.8h4.5c1.6 3.2 4 5.7 6.8 7.6 2.2-3.4 5.3-6 9.4-7.6h.2c1.6 3.2 4 5.7 6.8 7.6 2.1-3.2 5-5.7 8.7-7.3 4.1.4 7.9 1.3 11.1 2.7-10.2 4.5-15.7 14-15.7 27v5c0 .9.8 1.7 1.8 1.7h30l-.1 6.7Z"/>'
            '</svg>'));
        return svg02;
    }

    /**
     * 
     */
    function generateImage(uint256 tokenId) view internal returns (string memory) {
        string memory svg = string(abi.encodePacked(
            _getComponent0(),
            _getComponent1(),
            _getComponent2()
            ));
        return svg;
    }

    /**
     * TODO: write a more comprehensive description
     */
    function _payloadTokenURI(uint256 tokenId, string memory name) view internal returns (string memory) {
        
        string memory description = "This NFT represents a liquidity position.";
        
        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            name,
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(tokenId))),
                        '"}'
                    )))
            ));
    }




}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 xxxxxx xxxxxxxxxxxx xxx. All Rights Reserved
pragma solidity 0.8.x;

// import "hardhat/console.sol";

import {MetadataGenerator} from "./MetadataGenerator.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";

contract TestNft is ERC721, MetadataGenerator{

    constructor() ERC721("TestNft", "TNFT") {
    }

    /**
     * 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _payloadTokenURI(tokenId, name);
    }

    /**
     */
    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            buffer[--index] = bytes1(uint8(48 + uint256(temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    //function tokenURI(uint256 id) public view virtual returns (string memory);
    function tokenURI(uint256 id) public virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}