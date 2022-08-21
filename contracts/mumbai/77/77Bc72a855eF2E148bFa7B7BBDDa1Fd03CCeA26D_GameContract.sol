// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameContract{

    address payable[] public players;
    address payable public recentWinner;
    uint256 public fee;
    address immutable owner;
    address immutable wneoAddress;

    enum GAME_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    GAME_STATE public game_state;
    event GameEnded(address winnersAddress);
    error MaximumPlayersLimitReached();

     constructor(uint256 _fee, address _token) {
        game_state = GAME_STATE.CLOSED;
        fee = _fee;
        owner = msg.sender;
        wneoAddress = _token;
    }

     modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    function enterGame(uint256 amount) public {
        if(palyersInAMatch()==2){
            game_state = GAME_STATE.CLOSED;
            revert MaximumPlayersLimitReached();
        }
        require(game_state == GAME_STATE.OPEN, "There's an ongoing game now!");
        require(amount >= fee, "Not enough NEO!");
        IERC20(wneoAddress).transferFrom(msg.sender, address(this), amount);
        players.push(payable(msg.sender));
    }

    function startGame() public onlyOwner {
        require(
            game_state == GAME_STATE.CLOSED,
            "Can't start a new game yet!"
        );
        game_state = GAME_STATE.OPEN;
    }

    function endGame(address payable winnersAddress) public onlyOwner {
        game_state = GAME_STATE.CALCULATING_WINNER;
        emit GameEnded(winnersAddress);
        recentWinner = winnersAddress;
        game_state = GAME_STATE.CLOSED;
        IERC20(wneoAddress).transfer(winnersAddress,IERC20(wneoAddress).balanceOf(address(this)));
    }

    function palyersInAMatch() public view returns(uint256){
        return players.length;
    }

    function updateFee(uint256 _fee) public onlyOwner{
        fee = _fee;
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