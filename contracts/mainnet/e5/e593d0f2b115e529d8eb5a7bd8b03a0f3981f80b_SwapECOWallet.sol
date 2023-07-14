// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapECOWallet {

    address[] private ecoSysAccounts = [
    0xF803B2e659f1263c4C6C75e5EED61D50a62eB1E4,
    0xc5F46F185CbC62e31a0Aea9841Ae5250528C7a30,
    0xc81420edEB44f070C8ade158d007ADA168BC8Ee0,
    0x89615D826FDC4A71C6e61CD902947E230075D227,
    0xC170AeE62fD4C32e0b5dF7d3Ba4e86EB5fB3e76B,
    0x96Eb19637680A70be07a2e2B79778A870062Fdc5];


    receive() external payable {}

    address public tokenAddr;

    constructor() {
    }

    function receiveAmount() external {
        uint256 receiveAmt = IERC20(tokenAddr).balanceOf(address(this));
        if (receiveAmt == 0) {
            return;
        }
        uint256 avgAmt = receiveAmt / ecoSysAccounts.length;
        for (uint i = 0; i < ecoSysAccounts.length; i++) {
            IERC20(tokenAddr).transfer(ecoSysAccounts[i],avgAmt);
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