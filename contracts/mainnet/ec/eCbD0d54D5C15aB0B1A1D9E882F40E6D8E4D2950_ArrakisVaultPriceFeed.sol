// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceFeed {
  function token() external view returns (address);

  function price() external view returns (uint256);

  function pricePoint() external view returns (uint256);

  function emitPriceSignal() external;

  event PriceUpdate(address token, uint256 price, uint256 average);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";

interface ITokenPriceFeed is IOwnable {
  struct TokenInfo {
    address priceFeed;
    uint256 mcr;
    uint256 mrf; // Maximum Redemption Fee
  }

  function tokenPriceFeed(address) external view returns (address);

  function tokenPrice(address _token) external view returns (uint256);

  function mcr(address _token) external view returns (uint256);

  function mrf(address _token) external view returns (uint256);

  function setTokenPriceFeed(
    address _token,
    address _priceFeed,
    uint256 _mcr,
    uint256 _maxRedemptionFeeBasisPoints
  ) external;

  function emitPriceUpdate(
    address _token,
    uint256 _priceAverage,
    uint256 _pricePoint
  ) external;

  event NewTokenPriceFeed(address _token, address _priceFeed, string _name, string _symbol, uint256 _mcr, uint256 _mrf);
  event PriceUpdate(address token, uint256 priceAverage, uint256 pricePoint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./chainlink-price-feed.sol";

interface IArrakisVault is IERC20 {
  function getUnderlyingBalances() external view returns (uint256 amount0Current, uint256 amount1Current);

  function token0() external view returns (address);
}

contract ArrakisVaultPriceFeed is IPriceFeed, Constants {
  IArrakisVault public immutable vault;
  // token must be implemented by pricefeed and it will be cheapest as an immutable
  address public immutable override token;
  IPriceFeed public immutable priceFeed;
  bool public immutable isToken0;
  uint256 public immutable precision;

  constructor(address _vault, address _priceFeed) {
    require(_vault != address(0x0), "e2637b vault must not be address 0x0");
    require(_priceFeed != address(0x0), "e2637b priceFeed must not be address 0x0");
    vault = IArrakisVault(_vault);
    address _token = IPriceFeed(_priceFeed).token();
    token = _vault;
    priceFeed = IPriceFeed(_priceFeed);
    isToken0 = IArrakisVault(_vault).token0() == _token;
    precision = 10**IERC20Metadata(_token).decimals();
  }

  function price() public view override returns (uint256) {
    uint256 avTokenSupply = vault.totalSupply();
    (uint256 t0Balance, uint256 t1Balance) = vault.getUnderlyingBalances();
    // normalise balance to 18 decimals
    uint256 tBalance = ((isToken0 ? t0Balance : t1Balance) * DECIMAL_PRECISION) / precision;
    return (priceFeed.price() * tBalance) / avTokenSupply;
  }

  function pricePoint() public view override returns (uint256) {
    return price();
  }

  function emitPriceSignal() public {
    emit PriceUpdate(token, price(), price());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/ITokenPriceFeed.sol";
import "../utils/constants.sol";

contract ChainlinkPriceFeed is IPriceFeed, Constants {
  AggregatorV2V3Interface public immutable oracle;
  address public immutable override token;
  uint256 public immutable precision;

  constructor(address _oracle, address _token) {
    require(_oracle != address(0x0), "e2637b _oracle must not be address 0x0");
    require(_token != address(0x0), "e2637b _token must not be address 0x0");
    token = _token;
    oracle = AggregatorV2V3Interface(_oracle);
    uint8 decimals = oracle.decimals();
    require(decimals > 0, "e2637b decimals must be a positive number");
    precision = 10**decimals;
  }

  function price() public view virtual override returns (uint256) {
    return (uint256(oracle.latestAnswer()) * DECIMAL_PRECISION) / precision;
  }

  function pricePoint() public view override returns (uint256) {
    return price();
  }

  function emitPriceSignal() public override {
    emit PriceUpdate(token, price(), price());
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Constants {
  uint256 public constant DECIMAL_PRECISION = 1e18;
  uint256 public constant LIQUIDATION_RESERVE = 1e18;
  uint256 public constant MAX_INT = 2**256 - 1;

  uint256 public constant PERCENT = (DECIMAL_PRECISION * 1) / 100; // 1%
  uint256 public constant PERCENT10 = PERCENT * 10; // 10%
  uint256 public constant PERCENT_05 = PERCENT / 2; // 0.5%
  uint256 public constant BORROWING_RATE = PERCENT_05;
  uint256 public constant MAX_BORROWING_RATE = (DECIMAL_PRECISION * 5) / 100; // 5%
}