// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function coverPossibleStrategyLoss(uint earned, uint lost) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);

  function strategies(uint i) external view returns (address);

  function strategiesLength() external view returns (uint);

  function HARDWORK_DELAY() external view returns (uint);

  function lastHardWorks(address strategy) external view returns (uint);

  function pausedStrategies(address strategy) external view returns (bool);

  function pauseInvesting(address strategy) external;

  function continueInvesting(address strategy, uint apr) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function strategySpecificName() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external returns (uint strategyLoss);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external returns (uint strategyLoss);

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// @param amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint amount_,
    bool updateTotalAssetsBeforeInvest_
  ) external returns (
    uint strategyLoss
  );

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

  /// @notice Max amount that can be deposited to the strategy (its internal capacity), see SCB-593.
  ///         0 means no deposit is allowed at this moment
  function capacity() external view returns (uint);

  /// @notice {performanceFee}% of total profit is sent to the {performanceReceiver} before compounding
  function performanceReceiver() external view returns (address);

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev use FEE_DENOMINATOR
  function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRebalancingStrategy {
    function needRebalance() external view returns (bool);
    function rebalance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/ISplitter.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IStrategyV2.sol";
import "../interfaces/IRebalancingStrategy.sol";

/// @title Gelato resolver for rebalancing strategies
/// @author a17
contract RebalanceResolver {
  // --- CONSTANTS ---

  string public constant VERSION = "2.0.0";

  // --- VARIABLES ---

  address public immutable strategy;
  address public owner;
  address public pendingOwner;
  uint public delay;
  uint public lastRebalance;
  mapping(address => bool) public operators;

  // --- INIT ---

  constructor(address strategy_) {
    owner = msg.sender;
    delay = 1 minutes;
    strategy = strategy_;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  // --- OWNER FUNCTIONS ---

  function offerOwnership(address value) external onlyOwner {
    pendingOwner = value;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "!pendingOwner");
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function setDelay(uint value) external onlyOwner {
    delay = value;
  }

  function changeOperatorStatus(address operator, bool status) external onlyOwner {
    operators[operator] = status;
  }

  // --- MAIN LOGIC ---

  function call() external {
    require(operators[msg.sender], "!operator");

    try IRebalancingStrategy(strategy).rebalance() {} catch Error(string memory _err) {
      revert(string(abi.encodePacked("Strategy error: 0x", _toAsciiString(strategy), " ", _err)));
    } catch (bytes memory _err) {
      revert(string(abi.encodePacked("Strategy low-level error: 0x", _toAsciiString(strategy), " ", string(_err))));
    }
    lastRebalance = block.timestamp;
  }

  function checker() external view returns (bool canExec, bytes memory execPayload) {
    address strategy_ = strategy;
    ISplitter splitter = ISplitter(IStrategyV2(strategy_).splitter());
    if (
      !splitter.pausedStrategies(strategy_)
      && lastRebalance + delay < block.timestamp
      && IRebalancingStrategy(strategy_).needRebalance()
    ) {
      return (true, abi.encodeWithSelector(RebalanceResolver.call.selector));
    }

    return (false, bytes("Not ready to rebalance"));
  }

  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(s);
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}