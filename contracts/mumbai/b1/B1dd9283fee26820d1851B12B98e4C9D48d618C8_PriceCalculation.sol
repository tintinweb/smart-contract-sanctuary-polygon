// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./PriceConsumerV3.sol";
import "./interfaces/IDbiliaToken.sol";
import "./interfaces/IPriceCalculation.sol";

contract PriceCalculation is PriceConsumerV3, IPriceCalculation {
  using SafeMath for uint256;

  IDbiliaToken public dbiliaToken;

  constructor(address _tokenAddress) {
    dbiliaToken = IDbiliaToken(_tokenAddress);
  }

  /**
   * Validate purchasing/bidding in ETH matches with USD conversion using chainlink
   *
   * @param _fiatPrice dollar value
   * @param _wethAmount buyer total amount
   */
  function validateAmount(uint256 _fiatPrice, uint256 _wethAmount)
    external
    view
  {
    uint256 buyerTotalToWei = getPriceInWethAmount(_fiatPrice);
    require(_wethAmount >= buyerTotalToWei, "not enough of ETH being sent");
  }

  /**
   * Pay flat fees to Dbilia
   * i.e. buyer fee + seller fee
   *
   * @param _wethAmount amount of weth
   */
  function calcBuyerSellerFee(uint256 _wethAmount)
    external
    view
    returns (uint256)
  {
    uint256 feePercent = dbiliaToken.feePercent();
    uint256 buyerFee = _wethAmount.mul(feePercent).div(feePercent.add(1000));
    uint256 sellerAmount = _wethAmount.sub(buyerFee);
    uint256 sellerFee = sellerAmount.mul(feePercent).div(feePercent.add(1000));
    uint256 totalFee = buyerFee.add(sellerFee);
    return totalFee;
  }

  /**
   * Pay royalty to creator
   * Dbilia receives on creator's behalf
   *
   * @param _tokenId token id
   * @param _wethAmount amount of weth
   */
  function calcRoyalty(uint256 _tokenId, uint256 _wethAmount)
    external
    view
    returns (uint256, address)
  {
    uint256 feePercent = dbiliaToken.feePercent();
    (address receiver, uint16 percentage) = dbiliaToken.getRoyaltyReceiver(
      _tokenId
    );
    uint256 buyerFee = _wethAmount.mul(feePercent).div(feePercent.add(1000));
    uint256 royalty = _wethAmount.sub(buyerFee).mul(percentage).div(100);
    return (royalty, receiver);
  }

  /**
   * For purchase and bid, Frontend calls this function to get the token price in WETH amount
   * instead of manual converting from fiat to WETH
   *
   * @param _fiatPrice dollar value
   */
  function getPriceInWethAmount(uint256 _fiatPrice)
    public
    view
    returns (uint256)
  {
    int256 currentPriceOfETHtoUSD = getCurrentPriceOfETHtoUSD();
    uint256 buyerFee = _fiatPrice.mul(dbiliaToken.feePercent()).div(1000);
    uint256 buyerTotal = _fiatPrice.add(buyerFee).mul(10**18);
    uint256 buyerTotalToWei = buyerTotal.div(uint256(currentPriceOfETHtoUSD));
    return buyerTotalToWei;
  }

  /**
   * Get current price of ETH to USD in wei
   */
  function getCurrentPriceOfETHtoUSD() public view returns (int256) {
    return getThePriceEthUsd() / 10**8;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeedEthUsd;
  AggregatorV3Interface internal priceFeedEurUsd;

  int256 private ethUsdPriceFake = 2000 * 10**8; // remember to divide by 10 ** 8

  // 1.181
  int256 private eurUsdPriceFake = 1181 * 10**5; // remember to divide by 10 ** 8

  constructor() {
    // Ethereum mainnet
    if (block.chainid == 1) {
      priceFeedEthUsd = AggregatorV3Interface(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
      );

      priceFeedEurUsd = AggregatorV3Interface(
        0xb49f677943BC038e9857d61E7d053CaA2C1734C1
      );
    } else if (block.chainid == 42) {
      // Kovan
      priceFeedEthUsd = AggregatorV3Interface(
        0x9326BFA02ADD2366b30bacB125260Af641031331
      );

      priceFeedEurUsd = AggregatorV3Interface(
        0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13
      );
    } else if (block.chainid == 5) {
      // Goerli priceFeedEthUsd is not available!!
      // Thus, no need to set "priceFeedEthUsd"

      priceFeedEurUsd = AggregatorV3Interface(
        0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13
      );
    } else if (block.chainid == 137) {
      // Matic mainnet
      priceFeedEthUsd = AggregatorV3Interface(
        0xF9680D99D6C9589e2a93a78A04A279e509205945
      );

      priceFeedEurUsd = AggregatorV3Interface(
        0x73366Fe0AA0Ded304479862808e02506FE556a98
      );
    } else if (block.chainid == 80001) {
      // Matic testnet
      priceFeedEthUsd = AggregatorV3Interface(
        0x0715A7794a1dc8e42615F059dD6e406A6594651A
      );

      // Matic testnet priceFeedEurUsd is not available!!
      // Thus, no need to set "priceFeedEurUsd"
    } else {
      // Unit-test and thus take it from Kovan
      priceFeedEthUsd = AggregatorV3Interface(
        0x9326BFA02ADD2366b30bacB125260Af641031331
      );

      // Unit-test and thus take it from Matic mainnet
      priceFeedEurUsd = AggregatorV3Interface(
        0x73366Fe0AA0Ded304479862808e02506FE556a98
      );
    }
  }

  /**
   * Returns the latest price of ETH / USD
   */
  function getThePriceEthUsd() public view returns (int256) {
    if (
      block.chainid == 1 ||
      block.chainid == 42 ||
      block.chainid == 137 ||
      block.chainid == 80001
    ) {
      (, int256 price, , , ) = priceFeedEthUsd.latestRoundData();
      return price;
    } else {
      return ethUsdPriceFake;
    }
  }

  /**
   * Returns the latest price of EUR / USD
   */
  function getThePriceEurUsd() public view returns (int256) {
    if (block.chainid == 1 || block.chainid == 42 || block.chainid == 137) {
      (, int256 price, , , ) = priceFeedEurUsd.latestRoundData();
      return price;
    } else {
      return eurUsdPriceFake;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControl.sol";

interface IDbiliaToken is IAccessControl {
  function feePercent() external view returns (uint256);

  function getRoyaltyReceiver(uint256) external view returns (address, uint16);

  function getTokenOwnership(uint256)
    external
    view
    returns (
      bool,
      address,
      string memory
    );

  function changeTokenOwnership(
    uint256,
    address,
    string memory
  ) external;

  function ownerOf(uint256) external view returns (address);

  function isApprovedForAll(address, address) external view returns (bool);

  function safeTransferFrom(
    address,
    address,
    uint256
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceCalculation {
  function validateAmount(uint256, uint256) external view;

  function calcBuyerSellerFee(uint256) external view returns (uint256);

  function calcRoyalty(uint256, uint256)
    external
    view
    returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessControl {
  function owner() external view returns (address);

  function dbiliaTrust() external view returns (address);

  function dbiliaFee() external view returns (address);

  function dbiliaAirdrop() external view returns (address);

  function isMaintaining() external view returns (bool);

  function isAuthorizedAddress(address) external view returns (bool);
}