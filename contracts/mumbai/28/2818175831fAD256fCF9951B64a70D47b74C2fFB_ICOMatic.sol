/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
// File: contracts/ICOMatic.sol


pragma solidity ^0.8.11;



contract ICOMatic {
    AggregatorV3Interface internal priceFeed;
    IERC20 public tokenNova;

    bool public isActive;

    uint public RATE;

    address public owner;

    constructor(address _aggregator, address _nova) {
        priceFeed = AggregatorV3Interface(_aggregator);
        tokenNova = IERC20(_nova);
        owner = msg.sender;
    }

    modifier whenIsActive {
        require(isActive == true);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function buyTokens() public payable whenIsActive {
        //payable(msg.sender);
        uint _wei = msg.value;
        uint _usd = getConversionRate(_wei);
        uint _tokensToTransfer = _usd * RATE;
        tokenNova.transfer(msg.sender, _tokensToTransfer);
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setActive() public onlyOwner {
        isActive = true;
    }

    /* GETTERS */

    function getPrice() public view returns (uint) {
         (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getTestBuy(uint _amount) public view returns (uint) {
        uint _usd = getConversionRate(_amount);
        uint _tokensToTransfer = _usd * RATE;
        return _tokensToTransfer;
    }

    function getConversionRate(uint _amount) public view returns (uint) {
        uint _maticPrice = getPrice();
        uint _maticInUSD = (_maticPrice * _amount) / 1000000000000000000;
        return _maticInUSD;
    }

    function getBalance() public view returns (uint) {
        uint _balance = tokenNova.balanceOf(address(this));
        return _balance;
    }
}