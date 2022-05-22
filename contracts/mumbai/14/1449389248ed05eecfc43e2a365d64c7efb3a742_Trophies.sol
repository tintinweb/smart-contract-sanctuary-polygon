/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

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

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    _ownerOf[address(this).id()] = msg.sender;
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

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

/// @notice Flexible and target agnostic role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/MultiRolesAuthority.sol)
contract MultiRolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                     CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(bytes4 => bool) public isCapabilityPublic;

    mapping(bytes4 => bytes32) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(uint8 role, bytes4 functionSig) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        Authority customAuthority = getTargetCustomAuthority[target];

        if (address(customAuthority) != address(0)) return customAuthority.canCall(user, target, functionSig);

        return
            isCapabilityPublic[functionSig] || bytes32(0) != getUserRoles[user] & getRolesWithCapability[functionSig];
    }

    /*///////////////////////////////////////////////////////////////
               CUSTOM TARGET AUTHORITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setTargetCustomAuthority(address target, Authority customAuthority) public virtual requiresAuth {
        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, customAuthority);
    }

    /*//////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }
}

abstract contract Challenge {
  function challenge(address program) external virtual returns (bool);
}

contract Challenges is ERC721, MultiRolesAuthority {
  using Id for address;
  using Id for uint;
  using Hexadecimal for address;

  event AcceptChallenge(uint indexed id, bool accepted, bytes message);
  mapping (uint => bool) public accepted;
  mapping (uint => bytes) public descriptionOf;

  constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) MultiRolesAuthority(msg.sender, Authority(address(0))) {
    setPublicCapability(Challenges.reviewChallenge.selector, false);
    setRoleCapability(1, Challenges.reviewChallenge.selector, true);
  }

  function tokenURI(uint id) public view override returns (string memory) {
    // Reverts on nonexistent token
    ownerOf(id);

    bytes memory addr = id.addr().hexadecimal();
    bytes memory desc = descriptionOf[id];
    bytes memory status = bytes(accepted[id] ? "Accepted" : "Pending");

    bytes[] memory keys = new bytes[](1);
    bytes[] memory values = new bytes[](1);
    keys[0] = "Status";
    values[0] = bytes.concat("\"", status, "\"");

    return string(
      ERC721MetadataJSON.uriBase64(
        ERC721MetadataJSON.json(
          bytes.concat("Challenge ", addr),
          desc,
          SVG.uriBase64(
            SVG.svg(
              bytes.concat(
                SVG.text("Challenge", 20, 20),
                SVG.text(bytes.concat("Address: ", addr), 20, 40),
                SVG.text(bytes.concat("Description: ", desc), 20, 60),
                SVG.text(bytes.concat("Status: ", status), 20, 80)
              ),
              480,
              120
            )
          ),
          keys,
          values
        )
      )
    );
  }

  function requestChallenge(address challenge, bytes calldata description) external requiresAuth {
    descriptionOf[challenge.id()] = description;
    _safeMint(msg.sender, challenge.id());
  }

  function reviewChallenge(uint id, bool _accepted, bytes calldata message) external requiresAuth {
    if (_accepted) {
      accepted[id] = true;
    } else {
      _burn(id);
      delete descriptionOf[id];
    }
    emit AcceptChallenge(id, _accepted, message);
  }
}

struct Trophy {
  uint gasUsed;
  address challenge;
  address program;
}

struct RecordStruct {
  uint size;
  uint gas;
}

contract Trophies is ERC721 {
  using Id for address;
  using Hexadecimal for address;
  using Decimal for uint;

  event Funded(address indexed challenge, uint value);
  event Payed(address indexed winner, address indexed challenge, uint value);
  event Record(address indexed challenge, address indexed program, uint size, uint gas);

  uint public totalSupply;
  mapping (uint => Trophy) trophies;
  mapping (address => uint) public funds;
  mapping (address => RecordStruct) public records;

  Challenges challenges;

  constructor (string memory _name, string memory _symbol, address _challenges) ERC721(_name, _symbol) {
    challenges = Challenges(_challenges);
  }

  function _mint(address to) internal returns (uint id) {
    id = totalSupply++;
    _mint(to, id);
  }

  function _safeMint(address to) internal returns (uint id) {
    id = _mint(to);
    require(
      to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function tokenURI(uint id) public view override returns (string memory) {
    bytes[] memory keys = new bytes[](6);
    bytes[] memory values = new bytes[](6);
    bytes memory lines;

    {
      Trophy memory trophy = trophies[id];

      {
        bytes memory challenge = trophy.challenge.hexadecimal();
        keys[0] = "Challenge";
        values[0] = bytes.concat("\"", challenge, "\"");
        lines = SVG.text(bytes.concat("Challenge: ", challenge), 20, 40);
      }
      {
        bytes memory program = trophy.program.hexadecimal();
        keys[1] = "Program";
        values[1] = bytes.concat("\"", program, "\"");
        lines = bytes.concat(lines, SVG.text(bytes.concat("Program:   ", program), 20, 60));
      }
      {
        uint sizeValue = trophy.program.code.length;
        bytes memory size = sizeValue.decimal();
        bool sizeRecord = sizeValue == records[trophy.challenge].size;

        keys[4] = "Size";
        values[4] = size;
        keys[5] = "Size Record";
        values[5] = bytes(sizeRecord ? "true" : "false");
        lines = bytes.concat(lines, SVG.text(bytes.concat("Size: ", size, bytes(sizeRecord ? unicode" ⭐" : "")), 20, 80));
      }
      {
        bytes memory gas = trophy.gasUsed.decimal();
        bool gasRecord = trophy.gasUsed == records[trophy.challenge].gas;
        keys[2] = "Gas";
        values[2] = gas;
        keys[3] = "Gas Record";
        values[3] = bytes(gasRecord ? "true" : "false");
        lines = bytes.concat(lines, SVG.text(bytes.concat("Gas: ", gas, bytes(gasRecord ? unicode" ⭐" : "")), 20, 100));
      }
    }

    bytes memory title = bytes.concat(bytes(name), " #", id.decimal());

    return string(
      ERC721MetadataJSON.uriBase64(
        ERC721MetadataJSON.json(
          title,
          title,
          SVG.uriBase64(
            SVG.svg(
              bytes.concat(
                SVG.text(title, 20, 20),
                lines
              ),
              480,
              140
            )
          ),
          keys,
          values
        )
      )
    );
  }

  function isRecord(Trophy memory trophy) public view returns (bool, bool) {
    return (
      trophy.program.code.length == records[trophy.challenge].size,
      trophy.gasUsed == records[trophy.challenge].gas
    );
  }

  function isRecord(uint id) public view returns (bool, bool) {
    return isRecord(trophies[id]);
  }

  function fund(address challenge) external payable {
    require(challenges.accepted(challenge.id()), "CHALLENGE_NOT_ACCEPTED");
    require(msg.value > 0, "NO_VALUE");
    funds[challenge] += msg.value;
    emit Funded(challenge, msg.value);
  }

  function submit(address challenge, address program) external returns (uint id) {
    require(challenges.accepted(challenge.id()), "CHALLENGE_NOT_ACCEPTED");
    uint gas = gasleft();
    bool result = Challenge(challenge).challenge(program);
    gas -= gasleft();
    require(result, "CHALLENGE_FAILED");
    id = _safeMint(msg.sender);

    trophies[id] = Trophy(
      gas,
      challenge,
      program
    );
   
    {
      RecordStruct memory record = records[challenge];
      bool _isRecord;
      uint size = program.code.length;
      if (size < record.size || record.size == 0) {
        _isRecord = true;
        record.size = size;
      }
      if (gas < record.gas || record.gas == 0) {
        _isRecord = true;
        record.gas = gas;
      }

      if (_isRecord) {
        emit Record(challenge, program, size, gas);
        records[challenge] = record;
      }
    }

    uint value = funds[challenge];
    if (value > 0) {
      payable(msg.sender).transfer(value);
      funds[challenge] = 0;
      emit Payed(msg.sender, challenge, value);
    }
  }
}