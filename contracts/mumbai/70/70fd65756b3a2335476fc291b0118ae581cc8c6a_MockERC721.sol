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

    function tokenURI(uint256 id) public view virtual returns (string memory);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from '../../lib/solmate/src/tokens/ERC721.sol';
import {SVGUtil} from './utils/SVGUtil.sol';

contract MockERC721 is ERC721('RLTY', 'LTY'), SVGUtil {
    address public owner = 0xF108412695bDe69025fdCC7DA7048f4fFa43BC59;

    function tokenURI(uint256 id) public pure override returns (string memory) {
        return _uri(id, keccak256(abi.encodePacked(id)), 'R', 'L');
    }

    function mint(uint256 id, address to) public {
        _mint(to, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base64} from './Base64.sol';
import {Strings} from './Strings.sol';

contract SVGUtil {
    using Strings for uint8;
    using Strings for uint256;

    function _upper() internal pure returns (string memory) {
        return
            "<svg width='200' height='200' xmlns='http://www.w3.org/2000/svg'><defs><radialGradient id='gradient' cx='50%' cy='35%'>";
    }

    function _colors(bytes32 seed)
        internal
        pure
        returns (
            string memory c1,
            string memory c2,
            string memory c3
        )
    {
        c1 = string.concat(
            'rgb(',
            uint8(seed[0]).toString(),
            ',',
            uint8(seed[1]).toString(),
            ',',
            uint8(seed[2]).toString(),
            ')'
        );
        c2 = string.concat(
            'rgb(',
            uint8(seed[10]).toString(),
            ',',
            uint8(seed[11]).toString(),
            ',',
            uint8(seed[12]).toString(),
            ')'
        );
        c3 = string.concat(
            'rgb(',
            uint8(seed[20]).toString(),
            ',',
            uint8(seed[21]).toString(),
            ',',
            uint8(seed[22]).toString(),
            ')'
        );
    }

    function _stops(bytes32 seed)
        internal
        pure
        returns (
            string memory stop1,
            string memory stop2,
            string memory stop3
        )
    {
        (string memory c1, string memory c2, string memory c3) = _colors(seed);

        stop1 = string.concat(
            "<stop offset='0%' stop-color='",
            c1,
            "'><animate attributeName='stop-color' values='",
            c1,
            ';',
            c2,
            ';',
            c3,
            ';',
            c1,
            "' dur='2s' repeatCount='indefinite'></animate></stop>"
        );
        stop2 = string.concat(
            "<stop offset='50%' stop-color='",
            c2,
            "'><animate attributeName='stop-color' values='",
            c2,
            ';',
            c3,
            ';',
            c1,
            ';',
            c2,
            "' dur='2s' repeatCount='indefinite'></animate></stop>"
        );
        stop3 = string.concat(
            "<stop offset='100%' stop-color='",
            c3,
            "'><animate attributeName='stop-color' values='",
            c3,
            ';',
            c1,
            ';',
            c2,
            ';',
            c3,
            "' dur='2s' repeatCount='indefinite'></animate></stop>"
        );
    }

    function _lower() internal pure returns (string memory) {
        return
            "</radialGradient></defs><circle cx='50%' cy='50%' r='100' fill=\"url('#gradient')\"/><text x='32%' y='70%' font-size='150' rotate='90%' fill='black'>)</text>";
    }

    function _eyes(string memory left, string memory right)
        internal
        pure
        returns (string memory)
    {
        if (bytes(left).length == 0) {
            left = '.';
        }

        if (bytes(right).length == 0) {
            right = '.';
        }

        return
            string.concat(
                "<text x='17.5%' y='60%' font-size='40' fill='black' text-anchor='middle'>",
                left,
                "</text><text x='82.5%' y='60%' font-size='40' fill='black' text-anchor='middle'>",
                right,
                '</text></svg>'
            );
    }

    function _image(
        bytes32 seed,
        string memory left,
        string memory right
    ) internal pure returns (string memory) {
        (
            string memory stop1,
            string memory stop2,
            string memory stop3
        ) = _stops(seed);
        return
            string.concat(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            _upper(),
                            stop1,
                            stop2,
                            stop3,
                            _lower(),
                            _eyes(left, right)
                        )
                    )
                )
            );
    }

    function _uri(
        uint256 id,
        bytes32 seed,
        string memory left,
        string memory right
    ) internal pure returns (string memory) {
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":"ORB #',
                            id.toString(),
                            '", "image":"',
                            _image(seed, left, right),
                            '"}'
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}