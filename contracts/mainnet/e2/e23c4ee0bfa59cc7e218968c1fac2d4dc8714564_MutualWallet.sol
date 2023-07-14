// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MutualWallet {

    address[6] private feesAccount = [
    0x97aF6F12C0933C8be02E3A92328f889BE3DbaDcD,
    0xF0e4762f5Df383D5c4f22f84f84ACED0911363Fa,
    0x6fF2CC077B2D9429de59159c851ef8622438055C,
    0x4f53A881f730133f84BD1c91B104b9E2fa7648b6,
    0x2854e0B6002bbCe698B963b61b42e58B7E49a842,
    0x37693B9E195D5A5e1f1619F112AEDa4CF9aCe459];

    receive() external payable {}

    address public tokenAddr;

    constructor() {
    }

    function receiveAmount() external {
        uint256 receiveAmt = IERC20(tokenAddr).balanceOf(address(this));
        if (receiveAmt == 0) {
            return;
        }
        uint256 avgAmt = receiveAmt / feesAccount.length;
        for (uint i = 0; i < feesAccount.length; i++) {
            IERC20(tokenAddr).transfer(feesAccount[i],avgAmt);
        }
    }

    function pendingReceive() external view returns(uint256) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    function withdrawETH(address payable to, uint256 amount) external {
        to.transfer(amount);
    }

    function setUSDT(address usdt_) external{
        if (tokenAddr == address(0)) {
            tokenAddr = usdt_;
        }
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