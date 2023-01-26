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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    error OverFlow();

    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        if (x >= (1 << 248)) revert OverFlow();

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        if (x >= (1 << 224)) revert OverFlow();

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        if (x >= (1 << 192)) revert OverFlow();

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        if (x >= (1 << 160)) revert OverFlow();

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        if (x >= (1 << 128)) revert OverFlow();

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        if (x >= (1 << 96)) revert OverFlow();

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        if (x >= (1 << 64)) revert OverFlow();

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        if (x >= (1 << 32)) revert OverFlow();

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        if (x >= (1 << 24)) revert OverFlow();

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        if (x >= (1 << 16)) revert OverFlow();

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        if (x >= (1 << 8)) revert OverFlow();

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Owned} from "solbase/auth/Owned.sol";
import {SafeCastLib} from "solbase/utils/SafeCastLib.sol";
import {Math} from "./libraries/Math.sol";

/// @author Modified from Solbase
contract RebasingERC20 is Owned {
    using SafeCastLib for uint256;

    struct RebaseParameters {
        uint128 totalShares;
        uint128 lastTotalSupply;
        uint32 change;
        uint32 startTime;
        uint32 endTime;
        uint32 minDuration;
        uint32 maxIncrease;
        uint32 maxDecrease;
    }

    uint256 internal constant REBASE_CHANGE_PRECISION = 100_000;
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    /// @dev Instead of keeping track of user balances, we keep track of the user's share of the total supply.
    mapping(address => uint256) internal _shares;
    /// @dev Allowances are nominated in token amounts, not token shares.
    mapping(address => mapping(address => uint256)) public allowance;
    RebaseParameters public rebase;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Rebase(uint32 change, uint32 startTime, uint32 endTime);

    error InvalidTimeFrame();
    error RebaseTooLarge();

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner) Owned(_owner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        rebase.change = uint32(REBASE_CHANGE_PRECISION);
        rebase.minDuration = 1 hours;
        rebase.maxIncrease = 115_000;
        rebase.maxDecrease = 85_000;
    }

    function totalSupply() public view returns (uint256) {
        uint256 previousValue = rebase.lastTotalSupply;
        uint256 nextValue = previousValue * rebase.change / REBASE_CHANGE_PRECISION;
        uint256 currentTime = block.timestamp;
        if (currentTime <= rebase.startTime) {
            return previousValue;
        }
        if (currentTime >= rebase.endTime) {
            return nextValue;
        }
        ///@dev We linearly interpolate the result between the start and end times.
        return Math.interpolate(
            previousValue, nextValue, currentTime - rebase.startTime, rebase.endTime - rebase.startTime
        );
    }

    function totalShares() public view returns (uint256) {
        return rebase.totalShares;
    }

    function getSharesForTokenAmount(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return amount;
        return amount * totalShares() / _totalSupply;
    }

    function getTokenAmountForShares(uint256 shares) public view returns (uint256) {
        uint256 _totalShares = totalShares();
        if (_totalShares == 0) return shares;
        return shares * totalSupply() / _totalShares;
    }

    function balanceOf(address account) public view returns (uint256) {
        return getTokenAmountForShares(_shares[account]);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        uint256 shares = getSharesForTokenAmount(amount);
        _shares[from] -= shares;
        unchecked {
            // Cannot overflow because the sum of all user
            // shares can't exceed the max uint256 value.
            _shares[to] += shares;
        }
        emit Transfer(from, to, amount);
    }

    function setRebaseLimits(uint32 minDuration, uint32 maxIncrease, uint32 maxDecrease) public onlyOwner {
        if (minDuration != 0) rebase.minDuration = minDuration;
        if (maxIncrease != 0) rebase.maxIncrease = maxIncrease;
        if (maxDecrease != 0) rebase.maxDecrease = maxDecrease;
    }

    function setRebase(uint32 change, uint32 startTime, uint32 endTime) public onlyOwner {
        if (startTime < block.timestamp || startTime >= endTime || endTime - startTime < rebase.minDuration) {
            revert InvalidTimeFrame();
        }
        uint256 _totalSupply = totalSupply();
        if (
            change > rebase.maxIncrease || change < rebase.maxDecrease
                || _totalSupply * change / REBASE_CHANGE_PRECISION > type(uint128).max
        ) {
            revert RebaseTooLarge();
        }
        rebase = RebaseParameters({
            totalShares: totalShares().safeCastTo128(),
            lastTotalSupply: _totalSupply.safeCastTo128(),
            change: change,
            startTime: startTime,
            endTime: endTime,
            minDuration: rebase.minDuration,
            maxIncrease: rebase.maxIncrease,
            maxDecrease: rebase.maxDecrease
        });
        emit Rebase(change, startTime, endTime);
    }

    function _mint(address to, uint256 amount) internal {
        uint256 shares = getSharesForTokenAmount(amount);
        rebase.totalShares += shares.safeCastTo128();
        rebase.lastTotalSupply += amount.safeCastTo128();
        unchecked {
            // Cannot underflow because user's shares
            // will never be larger than the total shares.
            _shares[to] += shares;
        }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        uint128 shares = getSharesForTokenAmount(amount).safeCastTo128();
        rebase.totalShares -= shares;
        rebase.lastTotalSupply -= amount.safeCastTo128();
        _shares[from] -= shares;
        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {RebasingERC20} from "./RebasingERC20.sol";
import {EIP712} from "solbase/utils/EIP712.sol";

contract RebasingERC20Permit is RebasingERC20, EIP712 {
    error PermitExpired();
    error InvalidSigner();

    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner)
        RebasingERC20(_name, _symbol, _decimals, _owner)
        EIP712(_name, "1")
    {}

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
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
pragma solidity ^0.8.17;

import {RebasingERC20Permit} from "./RebasingERC20Permit.sol";
import {Whitelist} from "./Whitelist.sol";

contract Token is RebasingERC20Permit {
    Whitelist public immutable whitelist;

    bool public paused = true;

    error Paused();
    error NotWhitelisted();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier isWhitelisted(address account) {
        if (!whitelist.isWhitelisted(account)) revert NotWhitelisted();
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner, Whitelist _whitelist)
        RebasingERC20Permit(_name, _symbol, _decimals, _owner)
    {
        whitelist = _whitelist;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function mint(address to, uint256 amount) public onlyOwner isWhitelisted(to) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused isWhitelisted(to) {
        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "solbase/auth/Owned.sol";
import "./libraries/MerkleVerifier.sol";

contract Whitelist is Owned {
    mapping(address => bool) public isWhitelisted;

    bytes32 public merkleRoot;

    event Whitelisted(address indexed account, bool whitelisted);

    error InvalidProof();
    error MisMatchArrayLength();

    constructor(address owner) Owned(owner) {}

    function verify(bytes32[] memory proof, address user, uint256 index) public view returns (bool) {
        return MerkleVerifier.verify(proof, merkleRoot, keccak256(abi.encodePacked(user)), index);
    }

    function whitelistAddress(bytes32[] memory proof, address user, uint256 index) external {
        if (!verify(proof, user, index)) revert InvalidProof();
        isWhitelisted[user] = true;
        emit Whitelisted(user, true);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setDirectWhitelist(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
        emit Whitelisted(account, whitelisted);
    }

    function setDirectWhitelistBatch(address[] calldata accounts, bool[] calldata whitelisted) external onlyOwner {
        if (accounts.length != whitelisted.length) revert MisMatchArrayLength();
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = whitelisted[i];
            emit Whitelisted(accounts[i], whitelisted[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Math {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function interpolate(uint256 firstValue, uint256 secondValue, uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        uint256 difference = diff(firstValue, secondValue);
        difference = difference * numerator / denominator;
        return firstValue > secondValue ? firstValue - difference : firstValue + difference;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MerkleVerifier {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index) internal pure returns (bool) {
        bytes32 node = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }

            index = index / 2;
        }

        return node == root;
    }
}