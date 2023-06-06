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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

/**
 * @title Automation contract for of execution process for the DAO
 * @author Lruquaf ---> github.com/Lruquaf
 * @notice this Chainlink Automation compatible contract executes
 * a passed and ready proposal in Governance.sol automatically
 */

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGovernance.sol";

contract Automation is AutomationCompatibleInterface, Ownable {
    IGovernance public governance; // address of governance contract

    event UpkeepPerformed(uint256 proposalId, bytes32 descirption);

    /**
     *
     * @param _governance sets governance contract.
     * @notice This function can be accessible by owner of this contract
     */

    function setGovernance(address _governance) public onlyOwner {
        require(
            address(governance) == address(0),
            "Governance contract has already set!"
        );
        governance = IGovernance(_governance);
    }

    /**
     *
     * @param "checkData" is not used
     * @return upkeepNeeded is whether upkeep conditions are fulfilled or not
     * @return performData is not used
     * @notice checks whether the conditions for a proposal to execution are fulfilled or not
     * @dev overrides interface AutomationCompatibleInterface.sol
     */

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint256 proposalId = governance.getProposalId();
        uint256 executionTime = governance.getExecutionTime();
        upkeepNeeded =
            (proposalId != 0) &&
            (governance.isReadyToExecution()) &&
            (executionTime <= block.timestamp);
    }

    /**
     *
     * @param "performdata" is not used
     * @dev overrides interface AutomationCompatibleInterface.sol
     * @notice performs the execution of current proposal
     */

    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 proposalId = governance.getProposalId();
        uint256 executionTime = governance.getExecutionTime();
        require(
            (proposalId != 0) &&
                (executionTime <= block.timestamp) &&
                (governance.isReadyToExecution()),
            "Execution is not ready yet!"
        );
        governance.execute(
            governance.getTargets(),
            governance.getValues(),
            governance.getCalldatas(),
            governance.getDescription()
        );
        emit UpkeepPerformed(proposalId, governance.getDescription());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IGovernance {
    struct CurrentProposal {
        uint256 proposalId;
        uint256 executionTime;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32 description;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable returns (uint256);

    function getProposalId() external view returns (uint256);

    function getExecutionTime() external view returns (uint256);

    function getTargets() external view returns (address[] memory);

    function getValues() external view returns (uint256[] memory);

    function getCalldatas() external view returns (bytes[] memory);

    function getDescription() external view returns (bytes32);

    function isReadyToExecution() external view returns (bool);
}