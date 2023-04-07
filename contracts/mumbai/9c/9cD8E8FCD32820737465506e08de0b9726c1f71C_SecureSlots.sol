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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SecureSlots {
    uint256 private constant NUM_RANGE = 10;
    uint256[3] private ALLOWED_BETS = [
        1000000000000000000, // 1 token
        3000000000000000000, // 3 tokens
        5000000000000000000  // 5 tokens
    ];
    
    address private owner;
    IERC20 private token;
    uint256 private nonce;

    event SpinResult(address indexed player, uint256 bet, uint256[4] numbers, bool win);

    constructor(IERC20 _token) {
        owner = msg.sender;
        token = _token;
    }

    function random(uint256 max) private returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, nonce))) % max + 1;
    }

    function isAllowedBet(uint256 bet) private view returns (bool) {
        for (uint256 i = 0; i < ALLOWED_BETS.length; i++) {
            if (bet == ALLOWED_BETS[i]) {
                return true;
            }
        }
        return false;
    }

    function spin(uint256 betAmount) external {
        require(isAllowedBet(betAmount), "You must bet 1, 3, or 5 of the token");

        uint256[4] memory numbers;

        numbers[0] = random(NUM_RANGE);
        numbers[1] = random(NUM_RANGE);
        numbers[2] = random(NUM_RANGE);
        numbers[3] = random(NUM_RANGE);

        bool win = (numbers[0] == numbers[1] && numbers[1] == numbers[2] && numbers[2] == numbers[3]);

        if (win) {
            uint256 prize = betAmount * 2;
            require(token.balanceOf(address(this)) >= prize, "Not enough funds in the contract to pay the prize");
            token.transferFrom(msg.sender, address(this), betAmount);
            token.transfer(msg.sender, prize);
        } else {
            token.transferFrom(msg.sender, address(this), betAmount);
        }

        emit SpinResult(msg.sender, betAmount, numbers, win);
    }

    function deposit(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can deposit tokens");
        require(amount > 0, "You must deposit a positive amount of tokens");
        token.transferFrom(msg.sender, address(this), amount);
    }

    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Only the contract owner should be able to withdraw the accumulated tokens
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can withdraw tokens");
        require(amount <= token.balanceOf(address(this)), "Requested amount exceeds contract balance");
        token.transfer(msg.sender, amount);
    }
}