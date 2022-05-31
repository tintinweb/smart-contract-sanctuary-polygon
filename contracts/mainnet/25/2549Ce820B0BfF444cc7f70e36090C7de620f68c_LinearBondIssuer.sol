/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

/******************************************************************************
* File:     IERC20.sol
* Author:   OpenZeppelin
* Location: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/
*           contracts/token/ERC20/IERC20.sol
* License:  MIT
******************************************************************************/

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

/*****************************************************************************/




/******************************************************************************
* File:     LinearBondIssuer.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: IERC20.sol
* License:  Apache 2.0
******************************************************************************/

interface ICustomBalancerPoolMinimal is IERC20 {
	/// @notice Gets pricing information for both the BPT, and SWD
	/// @return bptValue The BPT's current price (in USD with 18-decimals of precision)
	/// @return swdValue SWD's current price (in USD with 18-decimals of precision)
	function getValue() external view returns (uint bptValue, uint swdValue);
}

/// @title SW DAO linear bond issuer
/// @author Peter T. Flynn
/// @notice Facilitates the sale of liquidity tokens in exchange for time-locked SWD; plus a
/// bonus which increases over time, and resets upon each sale
/// @dev Some configuration is performed using the constants below
contract LinearBondIssuer {
	// Useful in preserving precision when dividing integers
	uint constant EIGHTEEN_DECIMALS = 1e18;

	ICustomBalancerPoolMinimal constant BPT =
		ICustomBalancerPoolMinimal(0x24Ec3C300Ff53b96937c39b686844dB9E471421e);
	IERC20 constant SWD = IERC20(0xaeE24d5296444c007a532696aaDa9dE5cE6caFD0);
	uint constant TIME_TO_MATURITY = 104 weeks; // Two years
	uint constant TIME_TO_MAX_BONUS = 8 weeks;
	
	struct Slot0 {
		// Tally of all SWD within the contract that's unbonded
		uint80 totalBalanceRemaining;
		// The minimum bond bonus (percent)
		uint8 bonusMin;
		// The maximum bond bonus (percent)
		uint8 bonusMax;
		// A calculated value, used to linearly change the bonus over a period of time:
		// of length [TIME_TO_MAX_BONUS]
		uint112 bonusModifier;
		// The timestamp upon which the bonus was last reset
		uint48 bonusResetDate;
	}
	struct Bond {
		// The timestamp upon which the bond was issued
		uint96 creationDate;
		// The total SWD sold in the bond
		uint80 balance;
		// The SWD already paid out by the bond
		uint80 withdrawn;
	}

	/// @notice Gas-saving storage slot
	Slot0 public slot0;
	/// @notice Maps a given user's address to a list of issued bonds for that user
	mapping(address => Bond[]) public bonds;
	/// @notice Current contract owner
	address public owner;
	/// @notice New owner for ownership transfer
	/// @dev May contain the max address for unlocking contract destruction
	address public ownerNew;
	/// @notice Timestamp for ownership transfer timeout
	uint public ownerTransferTimeout;

	/// @notice Emitted when a bond is issued to a user
	/// @param sender The transactor
	/// @param bpt The amount of liquidity tokens purchased by the contract
	/// @param swd The amount of SWD sold by the contract
	event Stake(address indexed sender, uint bpt, uint swd);
	/// @notice Emitted when a user withdraws SWD which are owed to them
	/// @param sender The transactor
	/// @param amount The amount of SWD withdrawn
	event Withdraw(address indexed sender, uint amount);
	/// @notice Emitted when the contract owner adds SWD to the bondable balance
	/// @param sender The transactor
	/// @param amount The amount of SWD added to the balance
	event AddBalance(address indexed sender, uint amount);
	/// @notice Emitted when the minimum, and maximum bond bonuses are changed.
	/// @param sender The transactor
	/// @param bonusMin The new minimum bonus
	/// @param bonusMax The new maximum bonus
	event SetBonus(address indexed sender, uint8 bonusMin, uint8 bonusMax);
	/// @notice Emitted when an ownership transfer has been initiated
	/// @param sender The transactor
	/// @param newOwner The address designated as the potential new owner
	event OwnerTransfer(address indexed sender, address newOwner);
	/// @notice Emitted when an ownership transfer is confirmed
	/// @param sender The transactor, and new owner
	/// @param oldOwner The old owner
	event OwnerConfirm(address indexed sender, address oldOwner);
	/// @notice Emitted when a mis-sent token is rescued from the contract
	/// @param sender The transactor
	/// @param token The token rescued
	event WithdrawToken(address indexed sender, address indexed token);

	/// @notice Returned when the sender is not authorized to call a specific function
	error Unauthorized();
	/// @notice Returned when the block's timestamp is passed the expiration timestamp for
	/// the requested action
	error TimerExpired();
	/// @notice Returned when the requested token can not be transferred
	error TransferFailed();
	/// @notice Returned when there is an insufficient balance for the requested action
	error NotAvailable();
	/// @notice Returned when multiplication overflows
	error MathOverflow();
	/// @notice Returned during a setBonus() if the minimum is above the maximum
	error MinAboveMax();

	/// @dev Prevents calls from anyone besides the owner
	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}

	/// @dev Sets the initial bonus min/max, as well as the initial owner to msg.sender
	/// @param bonusMin The initial minimum bonus (percent)
	/// @param bonusMax The initial maximum bonus (percent)
	constructor(uint8 bonusMin, uint8 bonusMax) {
		if (bonusMin > bonusMax)
			revert MinAboveMax();
		owner = msg.sender;
		Slot0 memory _slot0 = slot0;
		_slot0.bonusMin = bonusMin;
		_slot0.bonusMax = bonusMax;
		_slot0.bonusModifier = 
			uint112(safeMul(bonusMax - bonusMin, EIGHTEEN_DECIMALS) / TIME_TO_MAX_BONUS);
		_slot0.bonusResetDate = uint48(block.timestamp);
		slot0 = _slot0;
		emit OwnerConfirm(msg.sender, address(0));
		emit SetBonus(msg.sender, bonusMin, bonusMax);
	}

	/// @notice Creates a bond for the user, using the specified amount of liquidity tokens
	/// @dev Named as such to make its intention less ambiguous
	/// @param amount The amount of liquidity tokens for the user to sell in the bond
	function stake(uint amount) external {
		if (amount == 0)
			revert NotAvailable();
		Slot0 memory _slot0 = slot0;
		if (_slot0.totalBalanceRemaining == 0)
			revert NotAvailable();
		uint swdReceived;
		{
			(uint bptValue, uint swdValue) = BPT.getValue();
			swdReceived = safeMul(amount, bptValue) / swdValue;
		}
		{
			uint bonusPercent = block.timestamp >= _slot0.bonusResetDate + TIME_TO_MAX_BONUS ? 
				_slot0.bonusMax :
				(	safeMul(
						block.timestamp - _slot0.bonusResetDate,
						_slot0.bonusModifier
					) / EIGHTEEN_DECIMALS
				) + _slot0.bonusMin;
			swdReceived = safeMul(swdReceived, 100 + bonusPercent) / 100;
		}
		if (swdReceived > _slot0.totalBalanceRemaining)
			revert NotAvailable();
		if (swdReceived < TIME_TO_MATURITY) // Prevents division rounding to zero
			revert NotAvailable();
		bonds[msg.sender].push(
			Bond(
				uint96(block.timestamp),
				uint80(swdReceived),
				0
			)
		);
		_slot0.totalBalanceRemaining -= uint80(swdReceived);
		_slot0.bonusResetDate = uint48(block.timestamp);
		slot0 = _slot0;
		if (!BPT.transferFrom(msg.sender, address(this), amount))
			revert TransferFailed();
		emit Stake(msg.sender, amount, swdReceived);
	}

	/// @notice Performs the same action as stake(), but claims the remaining SWD in the contract
	/// @dev The bonus is accounted for in calculations, to ensure that stake(), and
	/// stakeForRemaining() are functionally equivalent
	function stakeForRemaining() external {
		Slot0 memory _slot0 = slot0;
		if (_slot0.totalBalanceRemaining == 0)
			revert NotAvailable();
		uint bptAmount;
		{
			uint bonusPercent = block.timestamp >= _slot0.bonusResetDate + TIME_TO_MAX_BONUS ? 
				_slot0.bonusMax :
				(	safeMul(
						block.timestamp - _slot0.bonusResetDate,
						_slot0.bonusModifier
					) / EIGHTEEN_DECIMALS
				) + _slot0.bonusMin;
			uint swdWithoutBonus =
				safeMul(_slot0.totalBalanceRemaining, 100) / (100 + bonusPercent);
			(uint bptValue, uint swdValue) = BPT.getValue();
			bptAmount = safeMul(swdWithoutBonus, swdValue) / bptValue;
		}
		bonds[msg.sender].push(
			Bond(
				uint96(block.timestamp),
				_slot0.totalBalanceRemaining,
				0
			)
		);
		_slot0.totalBalanceRemaining = 0;
		_slot0.bonusResetDate = uint48(block.timestamp);
		slot0 = _slot0;
		if (!BPT.transferFrom(msg.sender, address(this), bptAmount))
			revert TransferFailed();
		emit Stake(msg.sender, bptAmount, _slot0.totalBalanceRemaining);
	}

	/// @notice Withdraws all available SWD for the user at the moment of the transaction
	function withdraw() external {
		Bond[] storage userBonds = bonds[msg.sender];
		uint swdAvailable;
		{
			uint userBondsLength = userBonds.length;
			uint i;
			while (i < userBondsLength) {
				Bond memory bond = userBonds[i];
				if (bond.balance == bond.withdrawn) {
					unchecked { ++i; }
					continue;
				}
				uint bondSwdAvailable = block.timestamp >= bond.creationDate + TIME_TO_MATURITY ?
					bond.balance :
					safeMul(
						bond.balance / TIME_TO_MATURITY,
						block.timestamp - bond.creationDate
					);
				if (bondSwdAvailable > bond.balance)
					bondSwdAvailable = bond.balance;
				bondSwdAvailable -= bond.withdrawn;
				bond.withdrawn += uint80(bondSwdAvailable);
				swdAvailable += bondSwdAvailable;
				userBonds[i] = bond;
				unchecked { ++i; }
			}
		}
		if (swdAvailable == 0)
			revert NotAvailable();
		SWD.transfer(msg.sender, swdAvailable);
		emit Withdraw(msg.sender, swdAvailable);
	}

	/// @notice Adds SWD to the bondable balance of the contract
	/// @param amount The amount of SWD to transfer for bonding
	function addBalance(uint80 amount) external onlyOwner {
		if (amount == 0)
			revert NotAvailable();
		Slot0 memory _slot0 = slot0;
		_slot0.totalBalanceRemaining += amount;
		_slot0.bonusResetDate = uint48(block.timestamp);
		slot0 = _slot0;
		if (!SWD.transferFrom(msg.sender, address(this), amount))
			revert TransferFailed();
		emit AddBalance(msg.sender, amount);
	}

	/// @notice Sets both the minimum, and maximum bonuses for bonding
	/// @param bonusMin The minimum bonus
	/// @param bonusMax The maximum bonus
	function setBonus(uint8 bonusMin, uint8 bonusMax) external onlyOwner {
		if (bonusMin > bonusMax)
			revert MinAboveMax();
		Slot0 memory _slot0 = slot0;
		_slot0.bonusMin = bonusMin;
		_slot0.bonusMax = bonusMax;
		_slot0.bonusModifier = 
			uint112(safeMul(bonusMax - bonusMin, EIGHTEEN_DECIMALS) / TIME_TO_MAX_BONUS);
		slot0 = _slot0;
		emit SetBonus(msg.sender, bonusMin, bonusMax);
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

	/// @notice Used to withdraw balances, or rescue mis-sent tokens from the contract address
	/// (Can only be called by the contract owner)
	/// @param token The address of the token to be withdrawn
	function withdrawToken(IERC20 token) external {
		address _owner = owner;
		if (msg.sender != _owner)
			revert Unauthorized();
		Slot0 memory _slot0 = slot0;
		bool isSwd = token == SWD;
		uint balance = isSwd ?
			_slot0.totalBalanceRemaining :
			token.balanceOf(address(this));
		if (isSwd)
			_slot0.totalBalanceRemaining = 0;
		if (!token.transfer(_owner, balance))
			revert TransferFailed();
		emit WithdrawToken(_owner, address(token));
	}

	/// @notice Returns the number of SWD available to a user for withdrawal at the moment
	/// @param wallet The address of the user
	/// @return swdAvailable The amount of SWD available for withdrawal
	function balanceAvailable(address wallet) external view returns (uint swdAvailable) {
		Bond[] storage userBonds = bonds[wallet];
		uint userBondsLength = userBonds.length;
		uint i;
		while (i < userBondsLength) {
			Bond memory bond = userBonds[i];
			if (bond.balance == bond.withdrawn) {
				unchecked { ++i; }
				continue;
			}
			uint bondSwdAvailable = block.timestamp >= bond.creationDate + TIME_TO_MATURITY ?
				bond.balance :
				safeMul(
					bond.balance / TIME_TO_MATURITY,
					block.timestamp - bond.creationDate
				);
			if (bondSwdAvailable > bond.balance)
				bondSwdAvailable = bond.balance;
			bondSwdAvailable -= bond.withdrawn;
			swdAvailable += bondSwdAvailable;
			unchecked { ++i; }
		}
	}

	/// @notice Returns the number of SWD that will be available to a user upon maturity of all
	/// their bonds
	/// @param wallet The address of the user
	/// @return swdAvailable The amount of SWD eventually available for withdrawal
	function balanceAvailableFuture(address wallet) external view returns (uint swdAvailable) {
		Bond[] storage userBonds = bonds[wallet];
		uint userBondsLength = userBonds.length;
		uint i;
		while (i < userBondsLength) {
			Bond memory bond = userBonds[i];
			if (bond.balance == bond.withdrawn) {
				unchecked { ++i; }
				continue;
			}
			swdAvailable += bond.balance - bond.withdrawn;
			unchecked { ++i; }
		}
	}

	// Multiplication technique by Remco Bloemen.
	// https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
	function safeMul(uint256 x, uint256 y) private pure returns (uint256 r0) {
		uint256 r1;
		assembly {
			let mm := mulmod(x, y, not(0))
			r0 := mul(x, y)
			r1 := sub(sub(mm, r0), lt(mm, r0))
		}
		if (r1 != 0) revert MathOverflow();
	}
}

/*****************************************************************************/