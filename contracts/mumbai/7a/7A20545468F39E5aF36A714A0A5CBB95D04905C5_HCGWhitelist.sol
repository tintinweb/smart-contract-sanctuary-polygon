//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error HCGWhiteList__TransferFailed();
error HCGWhiteList__Close();
error HCGWhiteList__Owner();

contract HCGWhitelist {
    IERC20 private immutable token;
    address public immutable owner;

    address[] private whitelist;

    mapping(address => uint256) private balances;

    uint256 public total;

    constructor(
        address _token,
        address[] memory _whitelist,
        uint256[] memory _balances
    ) {
        owner = msg.sender;
        token = IERC20(_token);
        whitelist = _whitelist;
        importWhitelistBalance(_balances);
    }

    function importWhitelistBalance(uint256[] memory _balances) private {
        for (uint256 i = 0; i < whitelist.length; i++) {
            balances[whitelist[i]] = _balances[i];
            total += _balances[i];
        }
    }

    function redeemToken() public {
        if (total == 0) {
            revert HCGWhiteList__Close();
        }

        if (msg.sender != owner) {
            revert HCGWhiteList__Owner();
        }

        require(
            token.allowance(msg.sender, address(this)) >= total,
            "Insuficient Allowance"
        );

        for (uint256 i = 0; i < whitelist.length; i++) {
            address wallet = whitelist[i];
            uint256 amount = balances[wallet];

            balances[wallet] = 0;
            total -= amount;

            bool success = token.transferFrom(msg.sender, wallet, amount);
            if (!success) {
                revert HCGWhiteList__TransferFailed();
            }
        }
    }

    function getTotalBalance() public view returns (uint256) {
        return total;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}