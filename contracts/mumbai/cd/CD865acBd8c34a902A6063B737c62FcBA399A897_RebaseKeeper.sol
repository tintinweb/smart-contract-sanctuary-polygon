// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.7/KeeperCompatible.sol";
import "./interfaces/IStaking.sol";

contract RebaseKeeper is KeeperCompatibleInterface {
    
    address public Owner;
    bool public paused;
    bytes32 constant encodedMsg = 0x50b058e9b5320e58880d88223c9801cd9eecdcf90323d5c2318bc1b6b916e862;

    IStaking public StakingContract;
    event LogContractUpdated(address stakingContract);
    event LogOwnerChange(address oldOwner, address newOwner);

    modifier onlyOwner() {
      require(msg.sender == Owner, "Not Owner");
      _;
    }    

    constructor() {
      Owner = msg.sender;
      paused = true;
    }

    function toggleUpkeep() onlyOwner external {
      paused = !paused;
    }

    function changeOwnership(address _newOwner) onlyOwner external {      
      require(_newOwner != Owner, "");
      Owner = _newOwner;
      
      emit LogOwnerChange(msg.sender, _newOwner);
    }

    function setStakingContract(address _stakingContract) onlyOwner external {      
      StakingContract = IStaking(_stakingContract);
      emit LogContractUpdated(_stakingContract);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
      StakingContract.rebase();
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {

      if (!paused) {
        try StakingContract.secondsToNextEpoch() returns (uint256) {} catch Error(string memory err) {
          if (encodedMsg == keccak256(bytes(err))) upkeepNeeded = true;
        }
      }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.0;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

     function secondsToNextEpoch() external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
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

pragma solidity ^0.7.0;

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