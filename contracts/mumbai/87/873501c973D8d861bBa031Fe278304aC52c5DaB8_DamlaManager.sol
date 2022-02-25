// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDamlaManager.sol";
import "./interfaces/IDAMLA.sol";
import "./utils/Governable.sol";

/**
 * @title DamlaManagerContract
 * @author softtech
 * @notice The contract manages the `DAMLA` token flows.  
 */
contract DamlaManager is IDamlaManager, Governable, ReentrancyGuard {

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice user id => amount mapping.
    mapping(string => uint256) private _balances;

    /// @notice Keep tracks of the user count who has balance.
    uint256 public userCount;

    /// @notice `DAMLA` token contract.
    IDAMLA private _damlaToken;

    /// @notice paused.
    bool public paused;

    /***************************************
    MODIFIERS
    ***************************************/

    modifier whileUnpaused() {
        require(!paused, "!paused");
        _;
    }

    /**
     * @notice Constructs the `DamlaManager` contract.
     * @param _governance The address of the governance.
     * @param _damla The address of the `DAMLA` token.
     */
    constructor(address _governance, address _damla) Governable(_governance) {
        require(_damla != address(0), "zero address damla");
        _damlaToken = IDAMLA(_damla);
    }

    /***************************************
    MUTUATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Mints `DAMLA` token for the user.
     * @param userID The user id to mint token.
     * @param to The address to send the minted tokens.
     * @param amount The amount value to mint.
    */
    function mintToken(string memory userID, address to, uint256 amount) external override onlyGovernance whileUnpaused nonReentrant {
        require(bytes(userID).length > 0, "invalid user id");
        require(to != address(0), "zero address destination");

        if (_balances[userID] == 0)
            userCount++;
        
        _balances[userID] += amount;
        _damlaToken.mint(to, amount);
        emit DamlaMinted(userID, to, amount);
    }

    /**
     * @notice Burns `DAMLA` token from the user.
     * @param userID The user id to burn token.
     * @param from The address to send the burned tokens.
     * @param amount The amount value to burn.
    */
    function burnToken(string memory userID, address from, uint256 amount) external override onlyGovernance whileUnpaused nonReentrant {
        require(bytes(userID).length > 0, "invalid user id");
        require(from != address(0), "zero address from");
        require(balanceOf(userID) >= amount, "insufficient amount");

        _balances[userID] -= amount;
        _damlaToken.burn(from, amount);

        if (_balances[userID] == 0)
            userCount--;
        emit DamlaBurned(userID, from, amount);
    }

    /**
     * @notice Pauses or unpauses manager.
     * @param _paused True to pause, false to unpause.
     */
     function setPaused(bool _paused) external override onlyGovernance {
        paused = _paused;
        emit PauseSet(_paused);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns user `DAMLA` balance.
     * @param userID The user id to query balance.
     * @return amount The token amount.
    */
    function balanceOf(string memory userID) public view override returns (uint256 amount) {
        return _balances[userID];
    }

    /**
     * @notice Returns `DAMLA` token address.
     * @return damla The address of the damla token.
    */
    function damlaToken() external view override returns (address damla) {
        return address(_damlaToken);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


interface IDamlaManager {

    /***************************************
    EVENTS
    ***************************************/
    
    /// @notice Emitted when a `DAMLA` is minted.
    event DamlaMinted(string userID, address to, uint256 amount);

    /// @notice Emitted when a `DAMLA` is burned.
    event DamlaBurned(string userID, address from, uint256 amount);

    /// @notice Emitted when paused is set.
    event PauseSet(bool paused);

    /***************************************
    MUTUATOR FUNCTIONS
    ***************************************/

    /**
     * @notice The function mints `DAMLA` token for the user.
     * @param userID The user id to mint token.
     * @param to The address to send the minted tokens.
     * @param amount The amount value to mint.
    */
    function mintToken(string memory userID, address to, uint256 amount) external;

    /**
     * @notice Burns `DAMLA` token from the user.
     * @param userID The user id to burn token.
     * @param from The address to send the burned tokens.
     * @param amount The amount value to burn.
    */
    function burnToken(string memory userID, address from, uint256 amount) external;

    /**
     * @notice Pauses or unpauses manager.
     * @param paused True to pause, false to unpause.
     */
     function setPaused(bool paused) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns user `DAMLA` balance.
     * @param userID The user id to query balance.
     * @return amount The token amount.
    */
    function balanceOf(string memory userID) external view returns (uint256 amount);

    /**
     * @notice Returns `DAMLA` token address.
     * @return damla The address of the damla token.
    */
    function damlaToken() external view returns (address damla);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IDAMLA is IERC20Metadata {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a manager is added.
    event ManagerAdded(address indexed manager);

    /// @notice Emitted when a manager is removed.
    event ManagerRemoved(address indexed manager);

    /***************************************
    MINT FUNCTIONS
    ***************************************/

    /**
     * @notice Returns true if `account` is authorized to mint [**DAMLA**](../DAMLA).
     * @param account Account to query.
     * @return status True if `account` can mint, false otherwise.
     */
    function isManager(address account) external view returns (bool status);

    /**
     * @notice Mints new [**DAMLA**](../DAMLA) to the receiver account.
     * Can only be called by authorized managers.
     * @param account The receiver of new tokens.
     * @param amount The number of new tokens.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Burns [**DAMLA**](./DAMLA) from account.
     * @param account The address to burn from.
     * @param amount The amount to burn.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Adds a new manager.
     * Can only be called by the current governance.
     * @param manager The new manager.
     */
    function addManager(address manager) external;

    /**
     * @notice Removes a manager.
     * Can only be called by the current governance.
     * @param manager The manager to remove.
     */
    function removeManager(address manager) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../interfaces/IGovernable.sol";

/**
 * @title Governable
 * @author softtech
 * @notice Enforces access control for importan functions to governor.
*/
contract Governable is IGovernable {

    /***************************************
    STATE VARIABLES
    ***************************************/
    
    /// @notice governor.
    address private _governance;

    /// @notice governance to take over
    address private _pendingGovernance;

    /// @notice governance locking status.
    bool private _locked;

    /***************************************
    MODIFIERS
    ***************************************/

    /** 
     * Can only be called by governor.
     * Can only be called while unlocked.
    */
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    /** 
     * Can only be called by pending governor.
     * Can only be called while unlocked.
    */
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /**
     * @notice Contructs the governable constract.
     * @param governance The address of the governor.
    */
    constructor(address governance) {
        require(governance != address(0x0), "zero address governance");
        _governance = governance;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external override onlyGovernance {
        _pendingGovernance = pendingGovernance;
        emit GovernancePending(pendingGovernance);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external override onlyPendingGovernance {
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IGovernable
 * @author softtech
 * @notice Enforces access control for important functions to governance.
*/
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);

    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);

    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view returns (address governor);

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view returns (address pendingGovernor);

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view returns (bool status);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external;
}