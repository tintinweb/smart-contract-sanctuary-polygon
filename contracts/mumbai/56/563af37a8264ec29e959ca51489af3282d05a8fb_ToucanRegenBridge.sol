// SPDX-License-Identifier:  GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IContractRegistry.sol";
import "./interfaces/ITCO2.sol";
import "./interfaces/INCTPool.sol";

/**
 * @dev Implementation of the smart contract for Regen Ledger self custody bridge.
 *
 * See README file for more information about the functionality
 */
contract ToucanRegenBridge is Ownable, Pausable {
    /// @notice total amount of tokens burned and signalled for transfer
    uint256 public totalTransferred;

    /// @notice mapping TCO2s to burnt tokens; acts as a limiting
    /// mechanism during the minting process
    mapping(address => uint256) public tco2Limits;

    /// @notice address of the bridge wallet authorized to issue TCO2 tokens.
    address public tokenIssuer;

    /// @notice address of the NCT pool to be able to check TCO2 eligibility
    INCTPool public immutable nctPool;

    /// @dev map of requests to ensure uniqueness
    mapping(string => bool) public origins;

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    /// @notice emited when we bridge tokens from TCO2 to Regen Ledger
    event Bridge(address sender, string recipient, address tco2, uint256 amount);
    /// @notice emited when we bridge tokens back from Regen Ledger and issue on TCO2 contract
    event Issue(string sender, address recipient, address tco2, uint256 amount);
    /// @notice emited when the token issuer is updated
    event TokenIssuerUpdated(address oldIssuer, address newIssuer);

    // ----------------------------------------
    //      Modifiers
    // ----------------------------------------

    modifier isRegenAddress(bytes calldata account) {
        // verification: checking if account starts with "regen1"
        require(account.length >= 44, "regen address is at least 44 characters long");
        bytes memory prefix = "regen1";
        for (uint8 i = 0; i < 6; ++i)
            require(prefix[i] == account[i], "regen address must start with 'regen1'");
        _;
    }

    // ----------------------------------------
    //      Constructor
    // ----------------------------------------

    constructor(address tokenIssuer_, INCTPool nctPool_) Ownable() {
        tokenIssuer = tokenIssuer_;
        nctPool = nctPool_;
        if (tokenIssuer_ != address(0)) {
            emit TokenIssuerUpdated(address(0), tokenIssuer_);
        }
    }

    // ----------------------------------------
    //      Functions
    // ----------------------------------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Enable the contract owner to rotate the
     * token issuer.
     * @param newIssuer Token issuer to be set
     */
    function setTokenIssuer(address newIssuer) external onlyOwner {
        address oldIssuer = tokenIssuer;
        require(oldIssuer != newIssuer, "already set");

        tokenIssuer = newIssuer;
        emit TokenIssuerUpdated(oldIssuer, newIssuer);
    }

    /**
     * @dev bridge tokens to Regen Network.
     * Burns Toucan TCO2 compatible tokens and signals a bridge event.
     * @param recipient Regen address to receive the TCO2
     * @param tco2 TCO2 address to burn
     * @param amount TCO2 amount to burn
     */
    function bridge(
        string calldata recipient,
        address tco2,
        uint256 amount
    ) external whenNotPaused isRegenAddress(bytes(recipient)) {
        require(amount > 0, "amount must be positive");
        require(nctPool.checkEligible(tco2), "TCO2 not eligible for NCT pool");

        //slither-disable-next-line divide-before-multiply
        uint256 precisionTest = (amount / 1e12) * 1e12;
        require(amount == precisionTest, "Only precision up to 6 decimals allowed");

        totalTransferred += amount;
        tco2Limits[tco2] += amount;

        emit Bridge(msg.sender, recipient, tco2, amount);
        ITCO2(tco2).bridgeBurn(msg.sender, amount);
    }

    /**
     * @notice issues TCO2 tokens back from Regen Network.
     * This functions must be called by a bridge account.
     * @param sender Regen address to send the TCO2
     * @param recipient Polygon address to receive the TCO2
     * @param tco2 TCO2 address to mint
     * @param amount TCO2 amount to mint
     * @param origin Random string provided to ensure uniqueness for this request
     */
    function issueTCO2Tokens(
        string calldata sender,
        address recipient,
        address tco2,
        uint256 amount,
        string calldata origin
    ) external whenNotPaused isRegenAddress(bytes(sender)) {
        require(amount > 0, "amount must be positive");
        require(msg.sender == tokenIssuer, "invalid caller");
        require(!origins[origin], "duplicate origin");
        origins[origin] = true;

        // Limit how many tokens can be minted per TCO2; this is going to underflow
        // in case we try to mint more for a TCO2 than what has been burnt so it will
        // result in reverting the transaction.
        tco2Limits[tco2] -= amount;

        emit Issue(sender, recipient, tco2, amount);
        ITCO2(tco2).bridgeMint(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier:  GPL-3.0

pragma solidity ^0.8.4;

interface IContractRegistry {
    function checkERC20(address _address) external view returns (bool);
}

// SPDX-License-Identifier:  GPL-3.0

pragma solidity ^0.8.4;

interface ITCO2 {
    function bridgeBurn(address account, uint256 amount) external;

    function bridgeMint(address account, uint256 amount) external;
}

// SPDX-License-Identifier:  GPL-3.0

pragma solidity ^0.8.4;

interface INCTPool {
    function checkEligible(address erc20Addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}