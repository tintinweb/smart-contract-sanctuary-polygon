/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-12
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
/*       GreenAllocation starts here      */
/******************************************/

contract GreenAllocation {

    IERC20 public GREEN; 

    uint256 public startBlock;
    uint256 public endBlock;
    bool initialized;

    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
    }

    /**
     * @dev Populate allocations.
     */
    constructor(IERC20 _GREEN, uint256 _startBlock)
    {
        startBlock = _startBlock;
        endBlock = startBlock + 13870000;   // 1 year at 38,000 blocks per day.
        GREEN = _GREEN;

        // 1
        allocations[0xD534B942A243e6fc69C66d1ec3AbcD55991bE24C] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 2
        allocations[0x267A6E6d9e4cD70aA0382B02E9b5cDcE67807a93] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 3
        allocations[0x1e3b57C256Ff6119210D30973244cBB1dEa089f2] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 4
        allocations[0x482B8fba49B4B0cfFD6475aC9365236dD44B6Dbf] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 5
        allocations[0x4D6945c269195Ab9ef821ed67baEeC7c16B5002E] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 6
        allocations[0x350661d34c58a8eb8ec7e3aD5bc809753B60FD59] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 7
        allocations[0x4a7fAA271539b039C72c15bC085802e19EA25432] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });

        // 8
        allocations[0x1814b585Db8ACefAa4ebf96240Ed28528B8CC958] = Allocation({
            sharePerBlock: 2253064167267480,
            lastWithdrawalBlock: startBlock
        });
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external
    {
        require(block.number >= startBlock, "Shares distribution has not yet started.");
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[msg.sender].lastWithdrawalBlock;
        allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[msg.sender].sharePerBlock * (unlockedBlock - tempLastWithdrawalBlock);
        GREEN.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (endBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[msg.sender].sharePerBlock * (unlockedBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (allocations[msg.sender].lastWithdrawalBlock - startBlock);
    }

    /**
     * @dev Get the total shares of shareholder.
     */
    function getTotalShares(address shareholder) external view returns(uint256)
    {
        return allocations[shareholder].sharePerBlock * 13870000;
    }

}