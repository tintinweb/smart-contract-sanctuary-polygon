/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.12;

/******************************************************************************
* File:     TokenPriceController.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: IERC20Metadata.sol, ITokenPriceManagerMinimal.sol
* License:  Apache 2.0
******************************************************************************/

/// @title Address database for TokenPriceManagers
/// @author Peter T. Flynn
/// @notice Allows for access to TokenPriceManagers by their primary token's symbol, with
/// easy upgradeability in mind.
contract TokenPriceController {
    /// @notice Current owner
    address public owner;
    /// @notice New owner for ownership transfer
    /// @dev May contain the max address for unlocking contract destruction
    address public ownerNew;
    /// @notice Timestamp for ownership transfer timeout
    uint256 public ownerTransferTimeout;
    /// @notice Stores contract addresses, accessible by the primary token's symbol
    mapping(string => address) private symbolToAddress;

	/// @notice Emitted when a new manager is added to the controller
	/// @param sender The transactor
	/// @param manager The address of the manager
	/// @param symbol The manager's primary token's symbol
	event ManagerAdd(address indexed sender, address indexed manager, string indexed symbol);
	/// @notice Emitted when a manager is upgraded within the controller
	/// @param sender The transactor
	/// @param manager The address of the manager
	/// @param symbol The manager's primary token's symbol
	event ManagerUpgrade(address indexed sender, address indexed manager, string indexed symbol);
	/// @notice Emitted when a manager is removed from the controller
	/// @param sender The transactor
	/// @param manager The address of the manager
	/// @param symbol The manager's primary token's symbol
	event ManagerRemove(address indexed sender, address indexed manager, string indexed symbol);
    /// @notice Emitted when an ownership transfer has been initiated
    /// @param sender The transactor
    /// @param newOwner The address designated as the potential new owner
    event OwnerTransfer(address indexed sender, address newOwner);
    /// @notice Emitted when an ownership transfer is confirmed
    /// @param sender The transactor, and new owner
    /// @param oldOwner The old owner
    event OwnerConfirm(address indexed sender, address oldOwner);
    /// @notice Emitted when the contract is destroyed
    /// @param sender The transactor
    event SelfDestruct(address sender);

    /// @notice Returned when the sender is not authorized to call a specific function
    error Unauthorized();
    /// @notice Returned when the block's timestamp is passed the expiration timestamp for
    /// the requested action
    error TimerExpired();
    /// @notice Returned when the requested contract destruction requires an unlock
    error UnlockDestruction();
	/// @notice Returns when an address provided does not correspond to a
	/// functioning TokenPriceManager
    error BadManager();
	/// @notice Returns when a TokenPriceManager with the same primary token symbol already exists
	/// within the controller
    error AlreadyExists();
	/// @notice Returns when the requested TokenPriceManager does not exist within the controller,
	/// or if the primary token's symbol has changed.
    error DoesntExist();

	// Prevents unauthorized calls
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

	// Sets the contract creator to the initial owner
    constructor() {
        owner = msg.sender;
    }

	/// @notice Adds a manager to the controller
    function managerAdd(address manager) external onlyOwner {
        (string memory symbol, bool notExists) = getSymbol(manager);
        if (!notExists) revert AlreadyExists();
        symbolToAddress[symbol] = manager;
		emit ManagerAdd(msg.sender, manager, symbol);
    }

	/// @notice Upgrades a manager within the controller
    function managerUpgrade(address manager) external onlyOwner {
        (string memory symbol, bool notExists) = getSymbol(manager);
        if (notExists) revert DoesntExist();
        symbolToAddress[symbol] = manager;
		emit ManagerUpgrade(msg.sender, manager, symbol);
    }

	/// @notice Removes a manager from the controller
    function managerRemove(address manager) external onlyOwner {
        (string memory symbol, bool notExists) = getSymbol(manager);
        if (notExists) revert DoesntExist();
        delete symbolToAddress[symbol];
		emit ManagerRemove(msg.sender, manager, symbol);
    }

	/// @notice Removes a manager from the controller, given the primary token's symbol
	/// @param symbol The primary token's symbol, formatted identically to its contract variable
    function symbolRemove(string calldata symbol) external onlyOwner {
        if (symbolToAddress[symbol] == address(0)) revert DoesntExist();
		emit ManagerRemove(msg.sender, symbolToAddress[symbol], symbol);
        delete symbolToAddress[symbol];
    }

    /// @notice Initiates an ownership transfer, but the new owner must call ownerConfirm()
    /// within 36 hours to finalize (Can only be called by the owner)
    /// @param _ownerNew The new owner's address
    function ownerTransfer(address _ownerNew) external onlyOwner {
        ownerNew = _ownerNew;
        ownerTransferTimeout = block.timestamp + 36 hours;
        emit OwnerTransfer(msg.sender, _ownerNew);
    }

    /// @notice Finalizes an ownership transfer (Can only be called by the new owner)
    function ownerConfirm() external {
        if (msg.sender != ownerNew) revert Unauthorized();
        if (block.timestamp > ownerTransferTimeout) revert TimerExpired();
        address _ownerOld = owner;
        owner = ownerNew;
        ownerNew = address(0);
        ownerTransferTimeout = 0;
        emit OwnerConfirm(msg.sender, _ownerOld);
    }

    /// @notice Destroys the contract when it's no longer needed (Can only be called by the owner)
    /// @dev Only allows selfdestruct() after the variable [ownerNew] has been set to its
    /// max value, in order to help mitigate human error
    function destroyContract() external onlyOwner {
        address payable _owner = payable(owner);
        if (ownerNew != 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
            revert UnlockDestruction();
        emit SelfDestruct(_owner);
        selfdestruct(_owner);
    }

    /// @notice Gets the address of a TokenPriceManager, given the primary token's symbol
	/// @param symbol The primary token's symbol, formatted identically to its contract variable
    function getManager(string calldata symbol)
        external
        view
        returns (address)
    {
        return symbolToAddress[symbol];
    }

	/// @dev "notExists" rather than "exists" to save gas
    function getSymbol(address manager)
        private
        view
        returns (string memory symbol, bool notExists)
    {
        symbol = IERC20Metadata(
            ITokenPriceManagerMinimal(manager).getTokenPrimary()
        ).symbol();
        if (bytes(symbol).length == 0) revert BadManager();
        notExists = symbolToAddress[symbol] == address(0);
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     ITokenPriceManagerMinimal.sol
* Author:   Peter T. Flynn
* Location: Local
* License:  Apache 2.0
******************************************************************************/

/// @title Price maintainer for arbitrary tokens
/// @author Peter T. Flynn
/// @notice Maintains a common interface for requesting the price of the given token, with
/// special functionality for TokenSets.
/// @dev Contract must be initialized before use. Price should always be requested using 
/// getPrice(bool), rather than viewing the [price] variable. Price returned is dependent
/// on the transactor's SWD balance. Constants require adjustment for deployment outside Polygon. 
interface ITokenPriceManagerMinimal {
    /// @notice Gets the current price of the primary token, denominated in [tokenDenominator]
    /// @dev Returns a different value, depending on the SWD balance of tx.origin's wallet.
    /// If the balance is over the threshold, getPrice() will return the price unmodified,
    /// otherwise it adds the dictated fee. Tx.origin is purposefully used over msg.sender,
    /// so as to be compatible with DEx aggregators. As a side effect, this makes it incompatible
    /// with relays. Price is always returned with 18 decimals of precision, regardless of token
    /// decimals. Manual adjustment of precision must be done later for [tokenDenominator]s
    /// with less precision.
    /// @param _buySell "True" for selling, "false" for buying.
    /// @return uint256 Current price in [tokenDenominator], per primary token.
    /// @return address Current [tokenDenominator]
    function getPrice(bool _buySell) external view returns (uint256, address);

    /// @return address Current [tokenPrimary]
    function getTokenPrimary() external view returns (address);

    /// @return address Current [tokenDenominator]
    function getTokenDenominator() external view returns (address);
}

/*****************************************************************************/




/******************************************************************************
* File:     IERC20.sol
* Author:   OpenZeppelin
* Location: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/
*           contracts/token/ERC20/IERC20.sol
* License:  MIT
******************************************************************************/

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

/*****************************************************************************/




/******************************************************************************
* File:     IERC20Metadata.sol
* Author:   OpenZeppelin
* Location: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/
*           contracts/token/ERC20/extensions/IERC20Metadata.sol
* Requires: IERC20.sol
* License:  MIT
******************************************************************************/

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

/*****************************************************************************/