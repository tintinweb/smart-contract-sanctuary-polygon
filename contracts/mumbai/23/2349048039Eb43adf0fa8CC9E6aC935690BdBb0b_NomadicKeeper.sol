// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract NomadicKeeper is KeeperCompatibleInterface {
    event ConfigUpdated(bytes32 config);

    address public vault;
    address public owner;
    uint256 lastRunDay = 0;
    bytes32 public config; // we use bytes for saving gas

    constructor(
        bytes32 config_,
        address vault_
    ) {
        vault = vault_;
        config = config_;
        owner = msg.sender;
    }

    function setConfig(bytes32 config_) external {
        require(msg.sender == owner);
        config = config_;
        emit ConfigUpdated(config);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (bool runCheck) = _shouldRun();
        upkeepNeeded = (runCheck);
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool runCheck) = _shouldRun();
        if (runCheck) {
            // write today, so that we only run once per day
            lastRunDay = (block.timestamp / 86400);
        }
        
    
        // Both commands run and do not revert if they fail so that the last run
        // day is still written, and the keepers do not empty their gas running
        // the failing method over and over again.

        // Collect and rebase first, so that the allocate can allocate dripped rewards
        if (runCheck) {
            vault.call(abi.encodeWithSignature("checkDeadlines()"));
        }
        
    }

    function _shouldRun()
        internal
        view
        returns (bool runCheck)
    {
        bytes32 _config = config; // Gas savings

        // Have we run today?
        uint256 day = block.timestamp / 86400;
        if (lastRunDay >= day) {
            return (false);
        }

        // Load schedule
        uint8 checkDays = uint8(_config[0]); // day of week bits

        // Weekday
        uint8 weekday = uint8((day + 4) % 7);

        // Need a runCheck?
        if (((checkDays >> weekday) & 1) != 0) {
            runCheck = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
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