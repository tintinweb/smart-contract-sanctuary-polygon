/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

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

// File: swap.sol


pragma solidity ^0.8.15;



interface IOracleContract {
  function index() external returns(uint256);
}

contract LonSwap {
  IERC20 public _usd;
  IERC20 public _lon;

  IOracleContract priceOracle;
  AggregatorV3Interface internal gbpPriceFeed;
  uint256 public indexPrice;

  mapping(address=>bool) public whitelistedUsers;
  address owner;

  event Swap(address indexed _from, address token1, uint256 amount1, address token2, uint256 amount2, uint256 fees);

  constructor (address usd, address _priceOracle, address _gbpPriceFeed) {
    _usd = IERC20(usd);
    priceOracle = IOracleContract(_priceOracle);
    gbpPriceFeed = AggregatorV3Interface(_gbpPriceFeed);
    owner = msg.sender;
  }

  modifier onlyOwner(){
    require(msg.sender==owner, "User is not owner");
    _;
  }

  modifier onlyUser(){
    require(whitelistedUsers[msg.sender] == true, "User is not whitelisted");
    _;
  }

  modifier checkUsdAllowance(uint256 amount) {
    require(_usd.allowance(msg.sender, address(this)) >= amount, "Insufficient USDC allowance");
    _;
  }

  modifier checkLonAllowance(uint256 amount) {
    require(_lon.allowance(msg.sender, address(this)) >= amount, "Insufficient LON allowance");
    _;
  }

  function setLonAddress(address lonAddress) onlyOwner() public {
    require(address(_lon) == address(0), "LON Token Address already set");
    _lon = IERC20(lonAddress);
  }

  function withdrawExcessUsd() onlyOwner() public {
    uint256 usdToGbpPrice = getUsdToGbpRate();
    uint256 usdIndexPrice = indexPrice * usdToGbpPrice / (10 ** 8);

    uint256 circulation = _lon.totalSupply() - _lon.balanceOf(address(this));
    uint256 amountOwed = circulation * usdIndexPrice / (10**30);
    require(_usd.transfer(owner, _usd.balanceOf(address(this)) - amountOwed), "Error withdrawing USDC");
  }

  function updateRate() public {
    indexPrice = priceOracle.index();
  }

  function getUsdToGbpRate() public view returns (uint256) {
    (, int price,,,) = gbpPriceFeed.latestRoundData();
    // price is to 8 decimals
    return uint256(price);
  }

  function swap(uint256 _amount) checkUsdAllowance(_amount) onlyUser() public {
    uint256 userBalance = _lon.balanceOf(msg.sender);
    uint256 usdToGbpPrice = getUsdToGbpRate();

    // Fees are 0.5%
    uint256 fees = _amount / 200;
    uint256 amountToSwap = _amount - fees;
    uint256 usdIndexPrice = indexPrice * usdToGbpPrice / (10 ** 8);

    // User can only have a maximum of $10 worth of LON tokens
    require((userBalance * usdIndexPrice / (10 ** 18)) + amountToSwap * (10 ** 12) <= 10 * (10 ** 18), "Swap would cause user to exceed $10 in LON holdings");
    require(_usd.transferFrom(msg.sender, address(this), amountToSwap), "User has insufficient USDC");
    require(_usd.transferFrom(msg.sender, msg.sender, fees), "User has insufficient USDC");
    require(_lon.transfer(msg.sender, (amountToSwap * (10 ** 30)) / usdIndexPrice), "Contract has insufficient LON");

    emit Swap(msg.sender, address(_usd), amountToSwap, address(_lon), amountToSwap * (10 ** 30) / usdIndexPrice, fees);
  }

  function redeem(uint256 _amount) checkLonAllowance(_amount) onlyUser() public {
    uint256 usdToGbpPrice = getUsdToGbpRate();
    uint256 usdIndexPrice = indexPrice * usdToGbpPrice / (10 ** 8);
    // Fees are 0.5%
    uint256 usdcToReturnBeforeFees = _amount * usdIndexPrice / (10 ** 30);
    uint256 fees = usdcToReturnBeforeFees / 200;
    uint256 usdcToReturn = usdcToReturnBeforeFees - fees;

    require(_lon.transferFrom(msg.sender, address(this), _amount), "User has insufficient LON");
    require(_usd.transfer(msg.sender, usdcToReturn), "Contract has insufficient USDC");
    require(_usd.transfer(msg.sender, fees), "Contract has insufficient USDC");

    emit Swap(msg.sender, address(_lon), _amount, address(_usd), usdcToReturn, fees);
  }

  function addUser(address userAddr) onlyOwner() public {
    whitelistedUsers[userAddr] = true;
  }
}