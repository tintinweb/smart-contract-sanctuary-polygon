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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDistributor {
    address public admin;
    mapping(address => uint256) private balances;
    IERC20 public token;

    constructor() {
        admin = msg.sender;
    }

    function setToken(address _token) external onlyAdmin {
        token = IERC20(_token);
    }

    function assignTokens(
        address[] memory participants,
        uint256[] memory percentages
    ) public onlyAdmin {
        require(
            address(token) != 0x0000000000000000000000000000000000000000,
            "Token need setup"
        );
        uint256 percentDiv = 1000;
        require(
            participants.length == percentages.length,
            "Percentages number must be equal to Users number"
        );

        uint256 totalPercentage = 0;

        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }

        require(totalPercentage == percentDiv, "Percent sum must be 1000");
        uint256 totalBalance = token.balanceOf(address(this));

        for (uint256 i = 0; i < participants.length; i++) {
            uint256 amount = (totalBalance * percentages[i]) / percentDiv;
            balances[participants[i]] += amount;
            // token.transfer(participants[i], amount);
        }
    }

    function withdrawTokens() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "You have no Token to claim");
        balances[msg.sender] = 0;
        token.transfer(msg.sender, balance);
    }

    function checkClaimable() public view returns (uint256 claimable) {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "You have no Token to claim");
        return balances[msg.sender];
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin of the contract.");
        _;
    }
}