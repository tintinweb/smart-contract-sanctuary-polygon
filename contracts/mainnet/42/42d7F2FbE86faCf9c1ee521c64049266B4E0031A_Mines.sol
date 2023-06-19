// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IMines.sol";
import "IERC20.sol";

contract Mines is IMines {
    struct Game {
        address player;
        uint256 wager;
        address wagerToken;
        uint8 revealedNum;
    }

    uint256 public nextGameId;
    mapping(uint256 => Game) public games;

    function startAndReveal(uint8 minesNum, uint256 wager, uint8 selectionIndex, address tokenAddress) external payable {
        require(wager > 0, "Mines: wanna play - gotta pay!");
        if (tokenAddress == address(0)) {
            require(wager == msg.value, "Mines: value must be equal to wager!");
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), wager);
        }
        uint256 gameId = nextGameId ++;
        games[gameId].player = msg.sender;
        games[gameId].wager = msg.value;
        bool success = nextGameId % 5 != 0;
        if (success) {
            games[gameId].revealedNum ++;
        }
        emit GameStarted(gameId);
        emit Revealed(gameId, selectionIndex, success);
    }

    function reveal(uint256 gameId, uint8 selectionIndex) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        bool success = nextGameId % 3 != 0;
        if (success) {
            games[gameId].revealedNum ++;
        }
        emit Revealed(gameId, selectionIndex, success);
    }

    function cashout(uint256 gameId) external {
        require(msg.sender == games[gameId].player, "Mines: you can do this only in games you started!");
        uint256 prize = games[gameId].wager * 99 * 25 / (25 - games[gameId].revealedNum) / 100;
        emit Cashout(gameId, prize, games[gameId].wagerToken);
        if (games[gameId].wagerToken == address(0)) {
            payable(msg.sender).transfer(prize);
        } else {
            IERC20(games[gameId].wagerToken).transfer(msg.sender, prize);
        }
    }

    function collapse() external {
        IERC20 usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        uint256 usdcBalance = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender, usdcBalance);
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMines {
    event GameStarted(uint256 indexed gameId);
    event Revealed(uint256 indexed gameId, uint8 selectionIndex, bool success);
    event Cashout(uint256 indexed gameId, uint256 amount, address token);

    function startAndReveal(uint8 minesNum, uint256 wager, uint8 selectionIndex, address tokenAddress) external payable;

    function reveal(uint256 gameId, uint8 selectionIndex) external;

    function cashout(uint256 gameId) external;
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