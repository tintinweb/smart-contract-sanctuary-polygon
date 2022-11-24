// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/**
 * @notice This is a benchmark contract part of a performance comparison of
 * smart contract automation solutions. It has a target or window of opportunity
 * and tests the ability to execute in timely manner.
 */
contract Target is AutomationCompatible {
    // Interval of blocks between each servicing opportunity
    uint256 public immutable i_interval;

    // Number of blocks defining the window of opportunity
    uint256 public immutable i_window;

    // Window number of last execution by network
    mapping(bytes32 => uint256) public s_lastWindow;

    /**
     * @notice Captures an execution with details required to compare solutions
     * @param success Indicates whether the execution was within the target window
     * @param latency Elapsed blocks from when a trigger condition is met
     * @param network Name of competitor solution servicing the contract
     */
    event Executed(
        bool indexed success,
        uint256 indexed latency,
        bytes32 indexed network
    );

    event PerformInfo(
        uint256 indexed blockNumber,
        uint256 indexed windowNumber,
        address indexed txOrigin
    );

    constructor(uint256 interval, uint256 window) {
        i_interval = interval;
        i_window = window;
    }

    /**
     * @notice Command that needs to be serviced by the competing automation solutions
     * @dev Even if the target has been missed the tx does not revert and always
     * emits an event so it can be easily queried.
     * @param network Name of the solution servicing the contract
     */
    function exec(bytes32 network) public {
        s_lastWindow[network] = getWindow(block.number);

        uint256 latency = block.number % i_interval;
        bool success = latency <= i_window;

        emit Executed(success, latency, network);
    }

    /**
     * @notice The condition based on which solutions trigger execution
     * @dev Prevents from triggering execution more than once per window
     * @param network Name of competitor solution servicing the contract
     * @return Indicates whether the contract should be serviced
     */
    function shouldExec(bytes32 network) public view returns (bool) {
        uint256 nextBlock = block.number + 1;
        uint256 currentWindow = getWindow(nextBlock);

        return currentWindow != s_lastWindow[network];
    }

    function getWindow(uint256 blockNumber) public view returns (uint256) {
        return blockNumber / i_interval;
    }

    // CHAINLINK AUTOMATION

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = shouldExec("CHAINLINK");
        performData = abi.encode(
            block.number,
            getWindow(block.number + 1),
            tx.origin
        );
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint256 blockNumber, uint256 windowNumber, address txOrigin) = abi
        .decode(performData, (uint256, uint256, address));
        emit PerformInfo(blockNumber, windowNumber, txOrigin);

        exec("CHAINLINK");
    }

    // GELATO OPS

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = shouldExec("GELATO");
        execPayload = abi.encodeCall(this.exec, "GELATO");
    }
}