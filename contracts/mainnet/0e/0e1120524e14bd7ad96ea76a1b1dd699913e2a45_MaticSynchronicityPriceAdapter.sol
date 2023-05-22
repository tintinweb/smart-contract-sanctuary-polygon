// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {IMaticRateProvider} from '../interfaces/IMaticRateProvider.sol';

/**
 * @title MaticSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (Asset / Base) pair by using
 * @notice Chainlink Data Feed for (MATIC / Base) and rate provider for (Asset / MATIC).
 * @notice For example it can be used to calculate stMATIC / USD
 * @notice based on MATIC / USD and stMATIC / MATIC rate provider contract.
 */
contract MaticSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (MATIC / Base) pair
   */
  IChainlinkAggregator public immutable MATIC_TO_BASE;

  /**
   * @notice Price feed for (MATIC / Base) pair
   */
  IMaticRateProvider public immutable RATE_PROVIDER;

  /**
   * @notice Number of decimals for wstETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  string private _description;

  /**
   * @param maticToBaseAggregatorAddress the address of MATIC / BASE feed
   * @param rateProviderAddress the address of the rate provider
   * @param pairName name identifier
   */
  constructor(
    address maticToBaseAggregatorAddress,
    address rateProviderAddress,
    string memory pairName
  ) {
    MATIC_TO_BASE = IChainlinkAggregator(maticToBaseAggregatorAddress);
    RATE_PROVIDER = IMaticRateProvider(rateProviderAddress);

    DECIMALS = MATIC_TO_BASE.decimals();

    _description = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return _description;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 maticToPegPrice = MATIC_TO_BASE.latestAnswer();
    int256 ratio = int256(RATE_PROVIDER.getRate());

    if (maticToPegPrice <= 0 || ratio <= 0) {
      return 0;
    }

    return (maticToPegPrice * ratio) / int256(10 ** RATIO_DECIMALS);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLSynchronicityPriceAdapter {
  /**
   * @notice Calculates the current answer based on the aggregators.
   * @return int256 latestAnswer
   */
  function latestAnswer() external view returns (int256);

  /**
   * @notice Returns the description of the feed
   * @return string desciption
   */
  function description() external view returns (string memory);

  /**
   * @notice Returns the feed decimals
   * @return uint8 decimals
   */
  function decimals() external view returns (uint8);

  error DecimalsAboveLimit();
  error DecimalsNotEqual();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMaticRateProvider {
  function getRate() external view returns (uint256);
}