// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract IReleases {
    struct Release {
        bool frozenMetadata;
        uint256 maxSupply;
        string uri;
    }

    function releaseExists(uint256 __id) external view virtual returns (bool);

    function mint(
        address __account,
        uint256 __id,
        uint256 __amount
    ) external virtual;

    function maxSupply(uint __id) external virtual returns (uint256);
}

contract Claims is Ownable, Pausable {
    error AccountsAndAmountsDoNotMatch();
    error AmountExceedsAvailableClaims();
    error AmountsDoNotMatchMaxSupply();
    error ClaimNotFound();
    error EndIsInvalid();
    error FreebieIsPaused();
    error Forbidden();
    error HasNotStarted();
    error HasEnded();
    error InvalidAmount();
    error InvalidClaims();
    error InvalidStart();
    error ReleaseNotFound();

    struct Freebie {
        bool paused;
        uint256 start;
        uint256 end;
    }

    mapping(uint256 => Freebie) private _freebies;
    mapping(uint256 => mapping(address => uint256)) private _claims;

    IReleases private _releasesContract;

    constructor(address __releasesContractAddress) {
        _releasesContract = IReleases(__releasesContractAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if sender is EOA.
     *
     * Requirements:
     *
     * - Sender must be EOA.
     */
    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert Forbidden();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    function createFreebie(
        uint256 __releaseID,
        uint256 __start,
        uint256 __end,
        address[] memory __accounts,
        uint256[] memory __amounts
    ) external onlyOwner {
        if (!_releasesContract.releaseExists(__releaseID)) {
            revert ReleaseNotFound();
        }

        if (__start > __end) {
            revert InvalidStart();
        }

        if (__accounts.length != __amounts.length) {
            revert AccountsAndAmountsDoNotMatch();
        }

        uint256 total = 0;
        for (uint256 i = 0; i < __amounts.length; i++) {
            total += __amounts[i];
        }

        if (_releasesContract.maxSupply(__releaseID) != total) {
            revert AmountsDoNotMatchMaxSupply();
        }

        for (uint256 i = 0; i < __accounts.length; i++) {
            _claims[__releaseID][__accounts[i]] = __amounts[i];
        }

        _freebies[__releaseID] = Freebie({
            paused: false,
            start: __start,
            end: __end
        });
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pauseFreebie(uint256 __releaseID) external onlyOwner {
        _freebies[__releaseID].paused = true;
    }

    function unpauseFreebie(uint256 __releaseID) external onlyOwner {
        _freebies[__releaseID].paused = false;
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    function claimFreebie(
        uint256 __releaseID,
        uint __amount
    ) external whenNotPaused onlyEOA {
        if (!_releasesContract.releaseExists(__releaseID)) {
            revert ReleaseNotFound();
        }

        if (__amount == 0) {
            revert InvalidAmount();
        }

        address account = _msgSender();

        if (__amount > availableClaims(account, __releaseID)) {
            revert AmountExceedsAvailableClaims();
        }

        Freebie memory freebie = _freebies[__releaseID];

        if (freebie.paused) {
            revert FreebieIsPaused();
        }

        if (freebie.start == 0) {
            revert ClaimNotFound();
        }

        if (block.timestamp < freebie.start) {
            revert HasNotStarted();
        }

        if (block.timestamp > freebie.end) {
            revert HasEnded();
        }

        _releasesContract.mint(account, __releaseID, __amount);

        _claims[__releaseID][account] -= __amount;
    }

    ////////////////////////////////////////////////////////////////////////////
    // AVAILABLE CLAIMS
    ////////////////////////////////////////////////////////////////////////////

    function availableClaims(
        address __account,
        uint256 __releaseID
    ) public view returns (uint256) {
        return _claims[__releaseID][__account];
    }
}