// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ukeeperAutomation/AutomationCompatible.sol";
import "../interface/IVaultSortedList.sol";
import "../interface/IVaultImplementation.sol";
contract VaultListKeeper is AutomationCompatibleInterface {

    address public constant SortedVaultListAddr = 0x86C6389cE6B243561144cD8356c94663934d127a;
    IVaultSortedList public constant sortedVaultList = IVaultSortedList(SortedVaultListAddr); 

    function getList() external view returns(uint){
        return sortedVaultList.listSize();
    }
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        if(sortedVaultList.listSize()>0) {
        (uint256 earliestDate, ) = sortedVaultList.getEarlistEndOfDate();
        upkeepNeeded = earliestDate < block.timestamp;
        }else{
            upkeepNeeded = false;
        }
     
    }

    function performUpkeep(bytes calldata /* performData */) external override {
         (uint256 earliestDate, address vaultAddress) = sortedVaultList.getEarlistEndOfDate();
        if (earliestDate < block.timestamp) {
            IVaultImplementation(vaultAddress).removeDepositFromAAVE();
            emit WithdrawDepositFromUpkeepr(earliestDate,block.timestamp,vaultAddress);
        }
       
    }

    event WithdrawDepositFromUpkeepr(uint256 _endOfTimeToWithdraw, uint256 _currentTime, address _vaultAddress);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IVaultSortedList {
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external ;
    function timeToWithdraw(address _vault) external returns(uint256);
    function addEndOfDate(address _vaultAddress, uint256 _epochTime) external;
    function getEarlistEndOfDate() external view returns(uint,address); 
    function removeVault(address _vaultAddress) external;
    function listSize() external view returns(uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IVaultImplementation {
    function removeDepositFromAAVE() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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