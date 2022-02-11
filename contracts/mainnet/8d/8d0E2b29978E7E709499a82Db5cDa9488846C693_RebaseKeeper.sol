// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract RebaseKeeper is KeeperCompatibleInterface {
	address public DAO;
	address public immutable stakingContract;

	modifier onlyDAO() {
		require(msg.sender == DAO, "RK: DAO ONLY");
		_;
	}

	constructor(address DAO_, address stakingContract_) {
		require(DAO_ != address(0), "RK: DAO ADDR ZERO!");
		(, , , uint256 rebaseEndTime) = IVSQStaking(stakingContract_).epoch();
    require(rebaseEndTime != 0, "RK: SC INV");
		DAO = DAO_;
    stakingContract = stakingContract_;
	}

	/**
	 * @dev chainlink keeper checkUpKeep
	 * @notice check staking contract to see whether been called or not
	 * @return upkeepNeeded - True (if upkeep needed) / False (non meet condition)
	 */
	function checkUpkeep(
		bytes calldata /* checkData */
	) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
    (, , , uint256 rebaseEndTime) = IVSQStaking(stakingContract).epoch();
		if (block.timestamp > rebaseEndTime) {
      upkeepNeeded = true;
    }
	}

	/**
	 * @dev chainlink keeper performUpkeep
	 * @notice if condition met, call rebase function
	 */
	function performUpkeep(bytes calldata /* performData */) external override {
		// check whether rebase been called or not
    (, , , uint256 rebaseEndTime) = IVSQStaking(stakingContract).epoch();
    require(block.timestamp > rebaseEndTime, "RK: ONLY TIME ALLOWED");
    // perform keeper call
		IVSQStaking(stakingContract).rebase();
	}

	/**
	 * @dev set DAO
	 * @notice only DAO can set the new DAO and it need to be pre added to pendingDAO
	 */
	function setDAO(address _newDAO) external onlyDAO {
		require(_newDAO != address(0), "RK: set _DAO to the zero address");
		DAO = _newDAO;
	}
}

interface IVSQStaking {
	function epoch()
		external
		view
		returns (
			uint256 number,
			uint256 distribute,
			uint256 length,
			uint256 endTime
		);

	function rebase() external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
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