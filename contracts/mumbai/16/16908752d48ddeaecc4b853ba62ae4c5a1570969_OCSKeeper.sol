/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// File: IOnChainStrategies.sol


pragma solidity ^0.8.17;

interface IOnChainStrategies {
    struct BaseStrategy {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 poolFee;
        uint256 allocation;
    }

    struct Interval {
        uint256 interval;
        uint256 lastTimestamp;
    }

    struct AggregatorChange {
        address aggregator;
        int256 change;
        uint80 lastRoundId;
        uint80 frequency;
    }

    function totalSupply() external view returns (uint256);

    function mint(uint256 strategyType, address recepient, bool approved, BaseStrategy memory baseStrategy, bytes memory data) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;

    function setAllocation(uint256 tokenId, uint256 allocation) external;
    function setUpkeepApproval(uint256 tokenId, bool approved) external;

    function checkStrategies(uint256 startId, uint256 length) external view returns (uint256[] memory);
    function upkeepStrategies(uint256[] memory ids) external;
}
// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol


pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: OCSKeeper.sol


pragma solidity ^0.8.17;



contract OCSKeeper is AutomationCompatibleInterface {
    IOnChainStrategies public immutable OnChainStrategies;

    constructor(address onchainStrategies) {
        OnChainStrategies = IOnChainStrategies(onchainStrategies);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 checkLength = abi.decode(checkData, (uint256));
        uint256 supply = OnChainStrategies.totalSupply();
        uint256 startId;
        
        if(checkLength > supply) {
            checkLength = supply;
        } else {
            startId = (block.timestamp % (supply / checkLength)) * checkLength;
        
            if(startId + checkLength > supply) {
                checkLength = supply - startId;
            }
        }

        uint256[] memory ids = OnChainStrategies.checkStrategies(startId, checkLength);

        upkeepNeeded = ids.length > 0;
        performData = abi.encode(ids);
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256[] memory ids = abi.decode(performData, (uint256[]));
        OnChainStrategies.upkeepStrategies(ids);
    }
}