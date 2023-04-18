/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: swap.sol

pragma solidity ^0.8.0;


contract BuySellContract {
    address public tokenAddress = 0x0893e7637bE8D05105625D6F5F59584118970FCE;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(tokenAddress);
    uint256 public feePercentage = 2;

    event Buy(address indexed buyer, uint256 tokensBought, uint256 ethSpent);
    event Sell(address indexed seller, uint256 tokensSold, uint256 ethReceived);

    function buy() external payable {
        uint256 totalEthInContract = address(this).balance - msg.value;
        uint256 totalTokensSupply = token.totalSupply() - token.balanceOf(burnAddress);

        uint256 price = getPrice(totalEthInContract, totalTokensSupply);
        uint256 tokensToBuy = (msg.value * (100 - feePercentage) * price) / 100;

        require(token.transfer(msg.sender, tokensToBuy), "Transfer failed");
        emit Buy(msg.sender, tokensToBuy, msg.value);
    }

    function sell(uint256 tokensToSell) external {
        uint256 totalEthInContract = address(this).balance;
        uint256 totalTokensSupply = token.totalSupply() - token.balanceOf(burnAddress) + tokensToSell;

        uint256 price = getPrice(totalEthInContract, totalTokensSupply);
        uint256 ethToReceive = ((tokensToSell * price) * (100 - feePercentage)) / 100;

        require(token.transferFrom(msg.sender, address(this), tokensToSell), "Transfer failed");
        payable(msg.sender).transfer(ethToReceive);
        emit Sell(msg.sender, tokensToSell, ethToReceive);
    }

    function getPrice(uint256 totalEthInContract, uint256 totalTokensSupply) public pure returns (uint256) {
        return totalEthInContract / totalTokensSupply;
    }

    function depositEth() external payable {
        require(msg.value > 0, "No ETH sent");
    }

    receive() external payable {
        require(msg.value > 0, "No ETH received");
    }
}