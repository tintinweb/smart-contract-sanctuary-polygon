// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapWallet {
    address public zbc;

    uint256 constant private base = 1000;
    uint256 constant private eco = 125;
    uint256 constant private nftPool = 250;
    uint256 constant private mutual = 625;

    address[] private ecoSysAccounts = [
    0xa4FBdf6715367B9e80b970d23eE3641f61F8A08B,
    0x45a8823E655eB63cccC6c85CAD979fd3B642E6dD,
    0xfbB66777Adf855c39eaEE91455f7DF08aceFd6a5,
    0xeaf3fe0ae40ADCb1Bd30907edA34267BD6Ef0259,
    0x62e3D00e20A3B2b7B04B32E0C60C0F5a61b7EDc5,
    0x0749b487E1f4486d106B69a9710445A5FBEa119d];


    uint256 private balances;

    address private tokenAddr;

    constructor() {
        zbc = msg.sender;
    }

    receive() external payable {}

    function withdraw(address token, address to, uint256 amount) external {
        require(msg.sender == zbc, "RewardPool: FORBIDDEN"); // sufficient check
        IERC20(token).transfer(to, amount);
    }

    function withdrawBatch(address token, address[] memory tos) external {
        require(msg.sender == zbc, "RewardPool: FORBIDDEN"); // sufficient check
        require(tos.length == 8, "RewardPool: FORBIDDEN"); // sufficient check

        if (tokenAddr == address(0)) {
            tokenAddr = token;
        }

        uint256 swapOutAmount = IERC20(token).balanceOf(address(this));
        if (swapOutAmount == 0) {
            return;
        }

        uint256 ecoTotalAmount = swapOutAmount * eco / base;
        uint256 nftPoolAmount = swapOutAmount * nftPool / base;
        uint256 mutualAmount = swapOutAmount * mutual / base;

        balances += ecoTotalAmount;

        IERC20(token).transfer(tos[6], nftPoolAmount);
        IERC20(token).transfer(tos[7], mutualAmount);
    }

    function receiveAmount() external {
        uint256 receiveAmt = balances;
        if (receiveAmt == 0) {
            return;
        }
        balances = 0;
        uint256 avgAmt = receiveAmt / ecoSysAccounts.length;
        for (uint i = 0; i < ecoSysAccounts.length; i++) {
            IERC20(tokenAddr).transfer(ecoSysAccounts[i],avgAmt);
        }
    }

    function pendingReceive() external view returns(uint256) {
        return balances;
    }

    function withdrawETH(address payable to, uint256 amount) external {
        require(msg.sender == zbc, "RewardPool: FORBIDDEN"); // sufficient check
        to.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}