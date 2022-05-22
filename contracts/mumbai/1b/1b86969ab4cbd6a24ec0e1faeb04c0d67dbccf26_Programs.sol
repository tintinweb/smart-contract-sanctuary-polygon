/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

library Create2 {
  function create2Address(address parent, uint salt, bytes memory _text) internal pure returns (address) {
    return address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                parent,
                salt,
                keccak256(abi.encodePacked(_text))
              )
            )
          )
        )
    );
  }

  function create2(uint salt, bytes memory _text) internal returns (address store) {
    assembly {
      store := create2(0, add(_text, 0x20), mload(_text), salt)
    }
  }
}

/**
 * @author evmgolf
 * @dev String operations.
 * @author Based on OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/String.sol)
 */
library Decimal {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function decimal(uint256 value) internal pure returns (bytes memory buffer) {
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
        buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
    }
}

/**
 * @author evmgolf
 * @dev String operations.
 * @author Based on OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/String.sol)
 */
library Hexadecimal {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function hexadecimal(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return hexadecimal(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function hexadecimal(uint256 value, uint256 length) internal pure returns (bytes memory buffer) {
        buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Hexadecimal:ZERO_LENGTH");
        return buffer;
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function hexadecimal(address addr) internal pure returns (bytes memory) {
        return hexadecimal(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
 * @author evmgolf
 * @author Based on OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Base64.sol)
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    bytes internal constant _TABLE = bytes("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function base64(bytes memory data) internal pure returns (bytes memory result) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        bytes memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        result = new bytes(4 * ((data.length + 2) / 3));

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
    }
}

library DataURI {
  using Base64 for bytes;

  // according to: https://datatracker.ietf.org/doc/html/rfc2397
  function dataURIBase64(bytes memory text, bytes memory mediaType) internal pure returns (bytes memory) {
    return bytes.concat("data:", mediaType, ";base64,", text.base64());
  }
}

library SVG {
  using Decimal for uint;
  using DataURI for bytes;

  function tag(bytes memory name, bytes memory body) internal pure returns (bytes memory) {
    return bytes.concat("<", name, ">", body, "</", name, ">");
  }

  function tag(bytes memory name, bytes memory body, bytes[] memory keys, bytes[] memory values) internal pure returns (bytes memory _text) {
    _text = bytes.concat("<", name);

    for (uint i=0; i<keys.length; i++) {
      _text = bytes.concat(_text, " ", keys[i], "=\"", values[i], "\"");
    }
    return bytes.concat(_text, ">", body, "</", name, ">");
  }

  function svg(bytes memory body, uint width, uint height) internal pure returns (bytes memory) {
    bytes[] memory keys = new bytes[](2);
    keys[0] = "xmlns";
    keys[1] = "viewBox";
    bytes[] memory values = new bytes[](2);
    values[0] = "http://www.w3.org/2000/svg";
    values[1] = bytes.concat("0 0 ", width.decimal(), " ", height.decimal());
    // return bytes.concat("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", tag("svg", body, keys, values));
    return tag("svg", body, keys, values);
  }

  function uriBase64(bytes memory _text) internal pure returns (bytes memory) {
    return _text.dataURIBase64("image/svg+xml");
  }

  function text(bytes memory body, uint x, uint y) internal pure returns (bytes memory) {
    bytes[] memory keys = new bytes[](2);
    bytes[] memory values = new bytes[](2);
    keys[0] = "x";
    values[0] = x.decimal();
    keys[1] = "y";
    values[1] = y.decimal();
    return tag("text", body, keys, values);
  }
}

library ERC721MetadataJSON {
  using DataURI for bytes;

  function json(bytes memory name, bytes memory description, bytes memory image) internal pure returns (bytes memory) {
    return bytes.concat(
        "{\"name\":\"",
        name,
        "\",\"description\":\"",
        description,
        "\",\"image\":\"",
        image,
        "\"}"
    );
  }
  function json(bytes memory name, bytes memory description, bytes memory image, bytes[] memory keys, bytes[] memory values) internal pure returns (bytes memory text) {
    text = bytes.concat(
        "{\"name\":\"",
        name,
        "\",\"description\":\"",
        description,
        "\",\"image\":\"",
        image,
        "\",\"attributes\":["
    );

    if (keys.length > 0) {
      text = bytes.concat(text, "{\"trait_type\":\"", keys[0], "\",\"value\":", values[0], "}");
      for (uint i=1; i<keys.length; i++) {
        text = bytes.concat(text, ",{\"trait_type\":\"", keys[i], "\",\"value\":", values[i], "}");
      }
    }
    text = bytes.concat(text, "]}");
  }

  function uriBase64(bytes memory _text) internal pure returns (bytes memory) {
    return _text.dataURIBase64("application/json");
  }
}

error ProgramExists();

library Id {
  function id(address a) internal pure returns (uint) {
    return uint(uint160(a));
  }
  function addr(uint i) internal pure returns (address) {
    return address(uint160(i));
  }
}

contract Programs is ERC721 {
  using Id for uint;
  using Id for address;
  using Hexadecimal for address;
  using Decimal for uint;

  uint constant public salt = 0;
  address public admin;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _ownerOf[address(this).id()] = msg.sender;
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function setAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }

  function tokenURI(address program) public view returns (string memory) {
    require(ownerOf(program.id()) != address(0), "TOKEN_DOESNT_EXIST");

    bytes memory addr = program.hexadecimal();
    bytes memory size = program.code.length.decimal();
    bytes[] memory keys = new bytes[](1);
    bytes[] memory values = new bytes[](1);
    keys[0] = "size";
    values[0] = size;

    return string(
      ERC721MetadataJSON.uriBase64(
        ERC721MetadataJSON.json(
          bytes.concat("Program ", addr),
          bytes.concat("Program at ", addr),
          SVG.uriBase64(
            SVG.svg(
              bytes.concat(
                SVG.text("Program", 20, 20),
                SVG.text(bytes.concat("Address: ", addr), 20, 40),
                SVG.text(bytes.concat("Size: ", size), 20, 60)
              ),
              480,
              100
            )
          ),
          keys,
          values
        )
      )
    );
  }

  function tokenURI(uint id) public view override returns (string memory) {
    return tokenURI(id.addr());
  }

  function write (bytes memory creationCode) external returns (address program) {
    program = Create2.create2(salt, creationCode);
    if (program == address(0)) {
      revert ProgramExists();
    }

    _mint(msg.sender, program.id());
  }
}