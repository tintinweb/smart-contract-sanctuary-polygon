// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC20 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC20/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Metadata Storage
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /// -----------------------------------------------------------------------
    /// ERC20 Storage
    /// -----------------------------------------------------------------------

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Logic
    /// -----------------------------------------------------------------------

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

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
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

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "../../../tokens/ERC20/ERC20.sol";
import {EIP712} from "../../../utils/EIP712.sol";

/// @notice ERC20 + EIP-2612 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC20/extensions/ERC20Permit.sol)
abstract contract ERC20Permit is ERC20, EIP712 {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error PermitExpired();

    error InvalidSigner();

    /// -----------------------------------------------------------------------
    /// EIP-2612 Constants
    /// -----------------------------------------------------------------------

    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// -----------------------------------------------------------------------
    /// EIP-2612 Storage
    /// -----------------------------------------------------------------------

    mapping(address => uint256) public nonces;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) EIP712(_name, "1") {}

    /// -----------------------------------------------------------------------
    /// EIP-2612 Logic
    /// -----------------------------------------------------------------------

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert PermitExpired();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                computeDigest(keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0)) revert InvalidSigner();

            if (recoveredAddress != owner) revert InvalidSigner();

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas-optimized implementation of EIP-712 domain separator and digest encoding.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
abstract contract EIP712 {
    /// -----------------------------------------------------------------------
    /// Domain Constants
    /// -----------------------------------------------------------------------

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    bytes32 internal immutable HASHED_DOMAIN_NAME;

    bytes32 internal immutable HASHED_DOMAIN_VERSION;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    uint256 internal immutable INITIAL_CHAIN_ID;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory domainName, string memory version) {
        HASHED_DOMAIN_NAME = keccak256(bytes(domainName));

        HASHED_DOMAIN_VERSION = keccak256(bytes(version));

        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        INITIAL_CHAIN_ID = block.chainid;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 Logic
    /// -----------------------------------------------------------------------

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, HASHED_DOMAIN_NAME, HASHED_DOMAIN_VERSION, block.chainid, address(this))
            );
    }

    function computeDigest(bytes32 hashStruct) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {ERC20Permit} from "solbase/tokens/ERC20/extensions/ERC20Permit.sol";
import {Owned} from "solbase/auth/Owned.sol";

contract Voucher is ERC20Permit("Volatility", "VOL", 18), Owned {
    mapping(address => bool) public isBlacklisted;

    event SetBlacklisted(address indexed user, bool blacklisted);

    error Blacklisted();

    modifier notBlacklisted(address user) {
        if (isBlacklisted[user]) revert Blacklisted();
        _;
    }

    constructor(address owner, uint256 totalSupply) Owned(owner) {
        _mint(msg.sender, totalSupply);
    }

    function transfer(address to, uint256 amount)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function mint(address to, uint256 amount) onlyOwner notBlacklisted(to) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external notBlacklisted(msg.sender) {
        _burn(msg.sender, amount);
    }

    function addToBlacklist(address[] memory users) external onlyOwner {
        _setBlacklist(users, true);
    }

    function removeFromBlacklist(address[] memory users) external onlyOwner {
        _setBlacklist(users, false);
    }

    function _setBlacklist(address[] memory users, bool value) internal {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            isBlacklisted[user] = value;
            emit SetBlacklisted(user, value);
        }
    }
}