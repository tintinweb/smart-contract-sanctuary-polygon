/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/******************************************/
/*        GreenMigration starts here        */
/******************************************/

contract GreenMigration is Ownable{

    IERC20 public GREEN; 
    IERC20 public DINO;

    uint256 public unlockPeriod = 6935000;              // 6 months at 38,000 blocks per day.
    uint256 public unlockShift = unlockPeriod / 10;     // 10% initial position.
    uint256 public swapRatio = 100;                     // 100:1 reverse split.
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public unlockBlock;

    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
    }

    event SwapIn(address user, uint256 amountIn, uint256 disbursement, uint256 allocation);
    event Withdraw(address user, uint256 amountOut);

    /**
     * @dev Populate allocations.
     */
    constructor(address _DINO, address _GREEN, uint256 _unlockBlock)
    {
        DINO = IERC20(_DINO);
        GREEN = IERC20(_GREEN);
        unlockBlock = _unlockBlock;
        startBlock = unlockBlock - unlockShift;
        endBlock = startBlock + unlockPeriod;
    }

    /**
     * @dev Swap DINO to GREEN.
     */
    function swapIn(uint256 amount) external 
    {
        require(amount > 0, "Empty amount.");
        require(block.number >= unlockBlock, "Migration has not yet started.");
        uint256 disbursement;
        uint256 sharePerBlock;
        uint256 unlockedBlock;
        DINO.transferFrom(msg.sender, address(this), amount);
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        if (allocations[msg.sender].lastWithdrawalBlock == 0) {
            allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;
        } else {
            if(allocations[msg.sender].lastWithdrawalBlock < endBlock) _withdrawShare(msg.sender);
        }
        uint256 withdrawnBlocks = unlockedBlock - startBlock;
        uint256 outstandingBlocks = endBlock - unlockedBlock;
        disbursement = amount * withdrawnBlocks / unlockPeriod;
        if(outstandingBlocks > 0) {
            sharePerBlock = (amount - disbursement) / outstandingBlocks / swapRatio; 
            allocations[msg.sender].sharePerBlock += sharePerBlock;
        }
        GREEN.transfer(msg.sender, disbursement / swapRatio);

        emit SwapIn(msg.sender, amount, disbursement / swapRatio, sharePerBlock * outstandingBlocks);
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external
    {
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        _withdrawShare(msg.sender);
    }

    /**
     * @dev Internal unlock shares.
     */
    function _withdrawShare(address user) internal
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[user].lastWithdrawalBlock;
        allocations[user].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[user].sharePerBlock * (unlockedBlock - tempLastWithdrawalBlock);
        GREEN.transfer(user, unlockedShares);

        emit Withdraw(user, unlockedShares);
    }

    /**
     * @dev Get the disbursement and allocation amounts on swap.
     */
    function getSwapIn(uint256 amount) external view returns(uint256, uint256)
    {
        uint256 disbursement;
        uint256 sharePerBlock;
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 withdrawnBlocks = unlockedBlock - startBlock;
        uint256 outstandingBlocks = endBlock - unlockedBlock;
        disbursement = amount * withdrawnBlocks / unlockPeriod;
        if(outstandingBlocks > 0) {
            sharePerBlock = (amount - disbursement) / outstandingBlocks / swapRatio;
        }
         
        return (disbursement / swapRatio, sharePerBlock * outstandingBlocks);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares(address user) external view returns(uint256)
    {
        return allocations[user].sharePerBlock * (endBlock - allocations[user].lastWithdrawalBlock);
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares(address user) external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[user].sharePerBlock * (unlockedBlock - allocations[user].lastWithdrawalBlock);
    }

    /**
     * @dev Withdraw Green tokens (use to close the swap).
     */
    function withdrawGreen(address target) external onlyOwner
    {
        require(GREEN.balanceOf(address(this)) > 0, "Green balance is zero.");
        GREEN.transfer(target, GREEN.balanceOf(address(this)));
    }
}