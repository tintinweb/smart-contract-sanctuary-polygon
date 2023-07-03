/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

// File: contracts/DoraTokenSale.sol


pragma solidity ^0.8.0;




contract DoraTokenSale {
    IERC20 public token;
    AggregatorV3Interface public priceFeed;
    address public beneficiary;
    uint256 public tokenPrice;
    uint256 public tokenAmount;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;

    event TokenPurchase(address indexed buyer, uint256 amount, uint256 totalPrice);

    constructor(address _token, address _beneficiary, address _priceFeed, uint256 _tokenAmount) {
        token = IERC20(_token);
        beneficiary = _beneficiary;
        priceFeed = AggregatorV3Interface(_priceFeed);
        tokenAmount = _tokenAmount  * 10 ** 4;
        updateTokenPrice();
    }

    function buyTokens() external payable {
        uint256 amount = msg.value;
        uint256 tokens = (amount * 1e18) / tokenPrice;
        require(tokens > 0, "Minimum purchase amount not reached");

        require(totalRaised + tokens <= tokenAmount, "Presale limit reached");

        contributions[msg.sender] += tokens;
        totalRaised += tokens;

        emit TokenPurchase(msg.sender, tokens, amount);

        // Transfer tokens to the buyer
        require(token.transfer(msg.sender, tokens), "Token transfer failed");

        // Transfer the funds to the beneficiary
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Beneficiary transfer failed");
    }

    function updateTokenPrice() public {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        tokenPrice = uint256(price);
    }
}