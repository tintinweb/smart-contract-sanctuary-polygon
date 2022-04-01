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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "../../loans/ILoanNFT.sol";

abstract contract LoanKeepersJob is KeeperCompatibleInterface, Ownable {
  uint256 public maxLoansToUpdate;
  address public loanNFTAddress;
  mapping(uint256 => uint256) failedToUpdate;

  event LoanFailedToUpdate(uint256 indexed _loanID);

  constructor(address _loanNFTAddress, uint256 _maxLoansToUpdate) {
    loanNFTAddress = _loanNFTAddress;
    maxLoansToUpdate = _maxLoansToUpdate;
  }

  function setMaxLoansToUpdate(uint256 _maxLoansToUpdate) external onlyOwner {
    maxLoansToUpdate = _maxLoansToUpdate;
  }

  function setLoanNFT(address _loanNFTAddress) external onlyOwner {
    loanNFTAddress = _loanNFTAddress;
  }

  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    ILoanNFT loanNFT = ILoanNFT(loanNFTAddress);
    uint256 numLoans = loanNFT.getNumLoans();
    uint256[] memory loanIDs = new uint256[](maxLoansToUpdate);
    uint256 numLoansToUpdate = 0;
    uint256 currLoanID = 0;

    while (numLoansToUpdate < loanIDs.length && currLoanID < numLoans) {
      if (_shouldUpdateLoan(currLoanID)) {
        loanIDs[numLoansToUpdate] = currLoanID;
        numLoansToUpdate += 1;
      }
      currLoanID += 1;
    }

    upkeepNeeded = numLoansToUpdate > 0;
    performData = abi.encode(numLoansToUpdate, loanIDs);
  }

  function performUpkeep(bytes calldata performData) external override {
    (uint256 numLoansToUpdate, uint256[] memory loanIDs) = abi.decode(performData, (uint256, uint256[]));
    for (uint256 i = 0; i < numLoansToUpdate; i++) {
      uint256 loanID = loanIDs[i];
      address lpAddress = (ILoanNFT(loanNFTAddress)).getLoanOwner(loanID);
      if (!_processLoan(loanID, lpAddress)) {
        failedToUpdate[loanID] = block.timestamp;
        emit LoanFailedToUpdate(loanID);
      }
    }
  }

  function _shouldUpdateLoan(uint256 _loanID) internal view virtual returns (bool);

  function _processLoan(uint256 _loanID, address _lpAddress) internal virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "../../loans/ILoanNFT.sol";
import "../../lendingPool/ILendingPool.sol";
import "./LoanKeepersJob.sol";

contract LoanValueUpdater is LoanKeepersJob {
  constructor(address _loanNFTAddress, uint256 _maxLoansToUpdate) LoanKeepersJob(_loanNFTAddress, _maxLoansToUpdate) {}

  function _shouldUpdateLoan(uint256 _loanID) internal view override returns (bool) {
    Loan memory loan = (ILoanNFT(loanNFTAddress)).getLoan(_loanID);
    return
      loan.status == LoanStatus.DISBURSED &&
      (loan.balances.lastUpdatedAt == 0 || block.timestamp >= loan.balances.lastUpdatedAt + 1 days);
  }

  function _processLoan(uint256 _loanID, address _lpAddress) internal override returns (bool) {
    try (ILendingPool(_lpAddress)).updateLoan(_loanID) {
      return true;
    } catch {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../loans/ILoanNFT.sol";

enum Tranche {
  JUNIOR,
  SENIOR
}

interface ILendingPool {
  function init(address _jCopToken, address _sCopToken) external;

  function registerLoan(LoanRegistrationParams calldata _loanParams) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function updateLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function getOriginator() external view returns (address);

  function updateSeniorObligation() external;

  function getLastUpdatedAt() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LoanRegistrationParams {
  uint256 repaymentDate;
  uint256 principal;
  uint256 lateFee;
  uint256 timeDisbursed;
  uint256 dailyRate;
  address borrowerAddress;
  string purpose;
  string description;
}

struct LoanBalances {
  uint256 outstanding;
  uint256 fee;
  uint256 late;
  uint256 balance;
  uint256 netValue;
  uint256 lastUpdatedAt;
}

enum LoanStatus {
  REGISTERED,
  DISBURSED,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 repaymentDate;
  uint256 principal;
  uint256 amountRepaid;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  uint256 dailyRate;
  address borrower;
  LoanBalances balances;
  LoanStatus status;
}

interface ILoanNFT {
  function mintNewLoan(LoanRegistrationParams calldata _loanParams) external returns (uint256);

  function updateMultipleLoanValues(uint256[] calldata _loanIDs) external;

  function updateLoanValue(uint256 _loanID) external;

  function getTotalLoanValue(address _loanOwner) external view returns (uint256);

  function getLoan(uint256 _loanId) external view returns (Loan memory);

  function updateAmountPaid(uint256 _loanId, uint256 _loanRepayment)
    external
    returns (
      uint256 _amountToPool,
      uint256 _amountToOriginator,
      uint256 _amountToGovernance
    );

  function disburse(uint256 _loanID) external;

  function setStatus(uint256 _loanID, LoanStatus _newStatus) external;

  function getNumLoans() external view returns (uint256);

  function getLoanOwner(uint256 _loanID) external view returns (address);
}