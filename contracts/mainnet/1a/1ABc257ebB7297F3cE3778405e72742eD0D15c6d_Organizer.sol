//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./organizer/OperatorManager.sol";
import "./organizer/ApprovalMatrix.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./organizer/DealManager.sol";

/// @title Organizer - A utility smart contract for DAOs to define and manage their Organizational structure.
/// @author Sriram Kasyap Meduri - <[email protected]>
/// @author Krishna Kant Sharma - <[email protected]>

contract Organizer is ApprovalMatrix, OperatorManager, Pausable, DealManager {
  //  Events
  //  DAO Onboarded
  event DAOOnboarded(
    address indexed daoAddress,
    address[] indexed operators,
    address[] operators2
  );

  //  new DAO operator added
  //  DAO  Operators modified
  //  DAO  Operators removed
  //  Deal created
  //  Payout created
  //  Payout executed
  //  Payout cancelled
  //  Deal cancelled
  //  DAO Offboarded
  event DAOOffboarded(address indexed daoAddress);

  //  Onboard A DAO
  function onboard(address[] calldata _operators) external {
    address safeAddress = msg.sender;
    // TODO: verify that safeAddress is Gnosis Multisig

    require(_operators.length > 0, "CS000");

    address currentoperator = SENTINEL_ADDRESS;

    daos[safeAddress].operatorCount = 0;

    // Set Default Approval Matrix for native token : 1 approval required for 0-inf
    daos[safeAddress].approvalMatrices[address(0)].push(
      ApprovalLevel(0, type(uint256).max, 1)
    );

    for (uint256 i = 0; i < _operators.length; i++) {
      // operator address cannot be null.
      address operator = _operators[i];
      require(
        operator != address(0) &&
          operator != SENTINEL_ADDRESS &&
          operator != address(this) &&
          currentoperator != operator,
        "CS002"
      );
      // No duplicate operators allowed.
      require(daos[safeAddress].operators[operator] == address(0), "CS003");
      daos[safeAddress].operators[currentoperator] = operator;
      currentoperator = operator;

      // TODO: emit Operator added event
      daos[safeAddress].operatorCount++;
    }
    daos[safeAddress].operators[currentoperator] = SENTINEL_ADDRESS;
    emit DAOOnboarded(safeAddress, _operators, _operators);
  }

  // Off-board a DAO
  function offboard(address _safeAddress)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    // Remove all operators in DAO
    address currentoperator = daos[_safeAddress].operators[SENTINEL_ADDRESS];
    while (currentoperator != SENTINEL_ADDRESS) {
      address nextoperator = daos[_safeAddress].operators[currentoperator];
      delete daos[_safeAddress].operators[currentoperator];
      currentoperator = nextoperator;
    }

    delete daos[_safeAddress];
    emit DAOOffboarded(_safeAddress);
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Modifiers.sol";

/// @title Operator Manager for Organizer Contract
abstract contract OperatorManager is Modifiers {
  // Get DAO operators
  function getOperators(address _safeAddress)
    public
    view
    returns (address[] memory)
  {
    address[] memory array = new address[](daos[_safeAddress].operatorCount);

    uint8 i = 0;
    address currentOp = daos[_safeAddress].operators[SENTINEL_ADDRESS];
    while (currentOp != SENTINEL_ADDRESS) {
      array[i] = currentOp;
      currentOp = daos[_safeAddress].operators[currentOp];
      i++;
    }

    return array;
  }

  // Get DAO operator count
  function getOperatorCount(address _safeAddress)
    external
    view
    returns (uint256)
  {
    return daos[_safeAddress].operatorCount;
  }

  //  Modify operators in a DAO
  function modifyOperators(
    address _safeAddress,
    address[] calldata _addressesToAdd,
    address[] calldata _addressesToRemove
  ) public onlyOnboarded(_safeAddress) onlyMultisig(_safeAddress) {
    for (uint256 i = 0; i < _addressesToAdd.length; i++) {
      address _addressToAdd = _addressesToAdd[i];
      require(
        _addressToAdd != address(0) &&
          _addressToAdd != SENTINEL_ADDRESS &&
          _addressToAdd != address(this) &&
          _addressToAdd != _safeAddress,
        "CS002"
      );
      require(
        daos[_safeAddress].operators[_addressToAdd] == address(0),
        "CS003"
      );

      _addOpreator(_safeAddress, _addressToAdd);
    }

    for (uint256 i = 0; i < _addressesToRemove.length; i++) {
      address _addressToRemove = _addressesToRemove[i];
      require(
        _addressToRemove != address(0) &&
          _addressToRemove != SENTINEL_ADDRESS &&
          _addressToRemove != address(this) &&
          _addressToRemove != _safeAddress,
        "CS002"
      );
      require(
        daos[_safeAddress].operators[_addressToRemove] != address(0),
        "CS018"
      );

      _removeOperator(_safeAddress, _addressToRemove);
    }
  }

  // Add an operator to a DAO
  function _addOpreator(address _safeAddress, address _operator) internal {
    daos[_safeAddress].operators[_operator] = daos[_safeAddress].operators[
      SENTINEL_ADDRESS
    ];
    daos[_safeAddress].operators[SENTINEL_ADDRESS] = _operator;
    daos[_safeAddress].operatorCount++;
  }

  // Remove an operator from a DAO
  function _removeOperator(address _safeAddress, address _operator) internal {
    address cursor = SENTINEL_ADDRESS;
    while (daos[_safeAddress].operators[cursor] != _operator) {
      cursor = daos[_safeAddress].operators[cursor];
    }
    daos[_safeAddress].operators[cursor] = daos[_safeAddress].operators[
      _operator
    ];
    daos[_safeAddress].operators[_operator] = address(0);
    daos[_safeAddress].operatorCount--;
  }
}

//contracts/organizer/ApprovalMatrix.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Modifiers.sol";

contract ApprovalMatrix is Modifiers {
  // Approval Matrix allows DAOs to define their approval matrix for deals and payouts
  // The approval matrix is a list of approval levels with the following properties:
  // 1. Each approval level has a minimum amount and a maximum amount
  // 2. Each approval level has a number of approvals required
  // 3. The approval matrix is sorted by minimum amount in ascending order
  //
  // Methods
  //
  //  Generate approval Matrix
  function _generateApprovalMatrix(
    uint256[] calldata _minAmounts,
    uint256[] calldata _maxAmounts,
    uint8[] calldata _approvalsRequired
  ) internal pure returns (ApprovalLevel[] memory) {
    require(
      _maxAmounts.length > 0 &&
        _minAmounts.length > 0 &&
        _approvalsRequired.length > 0,
      "CS026"
    );

    require(
      _minAmounts.length == _maxAmounts.length &&
        _minAmounts.length == _approvalsRequired.length,
      "CS020"
    );

    ApprovalLevel[] memory approvalMatrix = new ApprovalLevel[](
      _minAmounts.length
    );

    for (uint256 i = 0; i < _minAmounts.length; i++) {
      require(_minAmounts[i] < _maxAmounts[i], "CS021");
      require(_approvalsRequired[i] > 0, "CS022");

      approvalMatrix[i] = ApprovalLevel(
        _minAmounts[i],
        _maxAmounts[i],
        _approvalsRequired[i]
      );
    }

    return approvalMatrix;
  }

  // Set Approval Matrix on a DAO
  function setApprovalMatrix(
    address _safeAddress,
    address _tokenAddress,
    uint256[] calldata _minAmounts,
    uint256[] calldata _maxAmounts,
    uint8[] calldata _approvalsRequired
  ) public onlyOnboarded(_safeAddress) onlyOperatorOrMultisig(_safeAddress) {
    ApprovalLevel[] memory _approvalMatrix = _generateApprovalMatrix(
      _minAmounts,
      _maxAmounts,
      _approvalsRequired
    );

    // Loop because Copying of type struct memory[] to storage not yet supported
    for (uint256 i = 0; i < _approvalMatrix.length; i++) {
      if (
        daos[_safeAddress].approvalMatrices[_tokenAddress].length > i &&
        daos[_safeAddress].approvalMatrices[_tokenAddress][i].maxAmount > 0
      ) {
        daos[_safeAddress].approvalMatrices[_tokenAddress][i] = _approvalMatrix[
          i
        ];
      } else {
        daos[_safeAddress].approvalMatrices[_tokenAddress].push(
          _approvalMatrix[i]
        );
      }
    }
  }

  // Bulk set Approval Matrices on a DAO
  function bulkSetApprovalMatrices(
    address _safeAddress,
    address[] calldata _tokenAddresses,
    uint256[][] calldata _minAmounts,
    uint256[][] calldata _maxAmounts,
    uint8[][] calldata _approvalsRequired
  ) public onlyOnboarded(_safeAddress) onlyOperatorOrMultisig(_safeAddress) {
    require(
      _tokenAddresses.length == _minAmounts.length &&
        _tokenAddresses.length == _maxAmounts.length &&
        _tokenAddresses.length == _approvalsRequired.length,
      "CS024"
    );

    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      setApprovalMatrix(
        _safeAddress,
        _tokenAddresses[i],
        _minAmounts[i],
        _maxAmounts[i],
        _approvalsRequired[i]
      );
    }
  }

  // Get Approval Matrix of DAO
  function getApprovalMatrix(address _safeAddress, address _tokenAddress)
    external
    view
    returns (ApprovalLevel[] memory)
  {
    return daos[_safeAddress].approvalMatrices[_tokenAddress];
  }

  //   Get Required Approval count for a payout
  function getRequiredApprovalCount(
    address _safeAddress,
    address _tokenAddress,
    uint256 _amount
  ) external view returns (uint256 requiredApprovalCount) {
    requiredApprovalCount = _getRequiredApprovalCount(
      _safeAddress,
      _tokenAddress,
      _amount
    );
    require(requiredApprovalCount > 0, "CS025");
  }

  //   Get Required Approval count for a payout
  function _getRequiredApprovalCount(
    address _safeAddress,
    address _tokenAddress,
    uint256 _amount
  ) internal view returns (uint256 requiredApprovalCount) {
    ApprovalLevel[] memory approvalMatrix = daos[_safeAddress].approvalMatrices[
      _tokenAddress
    ];

    require(approvalMatrix.length > 0, "CS023");

    for (uint256 i = 0; i < approvalMatrix.length; i++) {
      if (
        _amount >= approvalMatrix[i].minAmount &&
        _amount <= approvalMatrix[i].maxAmount
      ) {
        requiredApprovalCount = approvalMatrix[i].approvalsRequired;
        break;
      }
    }
  }

  // Remove an approval matrix from a DAO
  function removeApprovalMatrix(address _safeAddress, address _tokenAddress)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    require(
      daos[_safeAddress].approvalMatrices[_tokenAddress].length > 0,
      "CS023"
    );
    delete daos[_safeAddress].approvalMatrices[_tokenAddress];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ApprovalMatrix.sol";
import "./OperatorManager.sol";
import "../interfaces/index.sol";
import "../validator/Signature.sol";

/// @title Operator Manager for Organizer Contract
contract DealManager is ApprovalMatrix, OperatorManager, SignatureEIP712 {
  //
  //  Events
  //
  event DealCreated(
    address indexed safeAddress,
    uint256 indexed dealNonce,
    address indexed recipient,
    address creator
  );

  event DealExecuted(
    address indexed safeAddress,
    uint256 indexed dealNonce,
    address indexed executor,
    address[] targets,
    uint256[] values,
    bytes[] data,
    Operation[] operations,
    uint256[] payouts,
    uint256[] payoutNonces
  );

  event PayoutValidated(
    address indexed safeAddress,
    uint256 indexed dealNonce,
    uint256 indexed payoutNonce,
    address[] operators,
    address recipient,
    address tokenAddress,
    uint256 amount
  );

  event ApprovalAdded(
    address indexed safeAddress,
    uint256 indexed dealNonce,
    uint256 indexed payoutNonce,
    address operators,
    address recipient,
    address tokenAddress,
    uint256 amount
  );

  event PayoutExecuted(
    address indexed safeAddress,
    uint256 dealNonce,
    uint256 payoutNonce,
    address indexed claimaint,
    address indexed tokenAddress,
    uint256 amount
  );

  /// @notice Create a deal
  /// @param _safeAddress Safe Address
  /// @param _recipient Recipient Address
  function createDeal(address _safeAddress, address _recipient)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    require(_safeAddress != address(0) || _recipient != address(0), "CS004");

    //  Set first payout nonce for Deal
    deals[_safeAddress][nextDealNonce] = Deal({
      nextPayoutNonce: SENTINEL_UINT,
      isActive: true
    });

    emit DealCreated(_safeAddress, nextDealNonce, _recipient, msg.sender);
    nextDealNonce++;
  }

  //   Invalidate a Deal
  function invalidateDeal(address _safeAddress, uint256 _dealNonce)
    external
    onlyOnboarded(_safeAddress)
    onlyOperatorOrMultisig(_safeAddress)
  {
    require(deals[_safeAddress][_dealNonce].isActive, "CS027");

    //  Set deal as inactive
    deals[_safeAddress][_dealNonce].isActive = false;
  }

  function addApproval(
    uint256 _dealId,
    uint256 payoutNonce,
    uint96 amount,
    address tokenAddress,
    address recipient,
    address safeAddress,
    address approver
  ) internal {
    require(
      !payouts[_dealId][payoutNonce].approvals[approver],
      "Approval already added"
    );

    payouts[_dealId][payoutNonce].approvals[approver] = true;
    payouts[_dealId][payoutNonce].approvalCount += 1;

    emit ApprovalAdded(
      safeAddress,
      _dealId,
      payoutNonce,
      approver,
      recipient,
      tokenAddress,
      amount
    );

    if (
      payouts[_dealId][payoutNonce].approvalCount >=
      _getRequiredApprovalCount(safeAddress, tokenAddress, amount)
    ) {
      payouts[_dealId][payoutNonce].isValidated = true;
      daos[safeAddress].claimables[tokenAddress][recipient] += amount;

      emit PayoutValidated(
        safeAddress,
        _dealId,
        payoutNonce,
        getOperators(safeAddress),
        recipient,
        tokenAddress,
        amount
      );
    }
  }

  /// @notice Function validates the Payout Approval Matrix and Signature of operators
  function validatePayout(
    uint256 _dealId,
    uint256 payoutNonce,
    uint96 amount,
    address tokenAddress,
    address recipient,
    uint256 networkId,
    address safeAddress,
    address[] memory approvers,
    bytes[] memory signatures
  ) external {
    require(
      signatures.length >=
        _getRequiredApprovalCount(safeAddress, tokenAddress, amount),
      "No of approvals mismatch from approval matrix"
    );

    for (uint256 i = 0; i < signatures.length; i++) {
      address approver = validateSingleDealSignature(
        approvers[i],
        _dealId,
        payoutNonce,
        amount,
        tokenAddress,
        recipient,
        networkId,
        safeAddress,
        signatures[i]
      );

      require(
        isOperator(safeAddress, approver),
        "Payout is not approved by a valid operator"
      );

      addApproval(
        _dealId,
        payoutNonce,
        amount,
        tokenAddress,
        recipient,
        safeAddress,
        approver
      );
    }
  }

  function bulkValidatePayout(
    uint256[] memory dealIds,
    uint256[] memory payoutNonces,
    uint96[] memory amounts,
    address[] memory tokenAddresses,
    address[] memory recipients,
    uint256[] memory networkIds,
    address[] memory safeAddresses,
    address approver,
    bytes memory signature
  ) external {
    require(
      dealIds.length == payoutNonces.length &&
        payoutNonces.length == amounts.length &&
        amounts.length == tokenAddresses.length &&
        tokenAddresses.length == recipients.length &&
        recipients.length == safeAddresses.length,
      "Approvals are mismatch"
    );

    address signer = validateBulkDealSignature(
      approver,
      dealIds,
      payoutNonces,
      amounts,
      tokenAddresses,
      recipients,
      networkIds,
      safeAddresses,
      signature
    );

    for (uint256 index = 0; index < dealIds.length; index++) {
      require(
        isOperator(safeAddresses[index], signer),
        "Payout is not approved by a valid operator"
      );
      addApproval(
        dealIds[index],
        payoutNonces[index],
        amounts[index],
        tokenAddresses[index],
        recipients[index],
        safeAddresses[index],
        signer
      );
    }
  }

  function claim(
    address _safeAddress,
    address tokenAddress,
    uint256 dealId,
    uint256 payoutNonce,
    address delegate,
    bytes memory signature
  ) external {
    require(
      payouts[dealId][payoutNonce].isValidated,
      "Payout does not have required approvals"
    );

    address payable to = payable(msg.sender);

    payouts[dealId][payoutNonce].isExecuted = true;

    AlowanceModule allowance = AlowanceModule(ALLOWANCE_MODULE);

    allowance.executeAllowanceTransfer(
      GnosisSafe(_safeAddress),
      tokenAddress,
      to,
      daos[_safeAddress].claimables[tokenAddress][msg.sender],
      0x0000000000000000000000000000000000000000,
      0,
      delegate,
      signature
    );

    emit PayoutExecuted(
      _safeAddress,
      dealId,
      payoutNonce,
      to,
      tokenAddress,
      daos[_safeAddress].claimables[tokenAddress][msg.sender]
    );
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Validators.sol";

/// @title Modifiers for Organizer Contract
abstract contract Modifiers is Validators {
  //
  //  Modifiers
  //
  //  Only Onboarded can do this
  modifier onlyOnboarded(address _safeAddress) {
    require(isDAOOnboarded(_safeAddress), "CS014");
    _;
  }

  //  Only Multisig can do this
  modifier onlyMultisig(address _safeAddress) {
    require(msg.sender == _safeAddress, "CS015");
    _;
  }

  //  Only Operators
  modifier onlyOperator(address _safeAddress) {
    require(isOperator(_safeAddress, msg.sender), "CS016");
    _;
  }

  modifier onlyOperatorOrMultisig(address _safeAddress) {
    require(
      isOperator(_safeAddress, msg.sender) || msg.sender == _safeAddress,
      "CS017"
    );
    _;
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Storage.sol";

/// @title Validators for Organizer Contract
abstract contract Validators is Storage {
  // Is operator?
  function isOperator(address _safeAddress, address _addressToCheck)
    public
    view
    returns (bool)
  {
    require(_addressToCheck != address(0), "CS002");
    require(isDAOOnboarded(_safeAddress), "CS014");
    return daos[_safeAddress].operators[_addressToCheck] != address(0);
  }

  // Is DAO onboarded?
  function isDAOOnboarded(address _addressToCheck) public view returns (bool) {
    require(_addressToCheck != address(0), "CS004");
    return daos[_addressToCheck].operatorCount > 0;
  }
}

//contracts/Organizer.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Storage for Organizer Contract
abstract contract Storage {
  //  Structs
  struct DAO {
    uint256 operatorCount;
    mapping(address => address) operators;
    //  Approval Matrices : Token Address => ApprovalMatrix
    mapping(address => ApprovalLevel[]) approvalMatrices;
    // token approvals
    // tokenAddress => recipeint address => amount
    mapping(address => mapping(address => uint96)) claimables;
  }

  address ALLOWANCE_MODULE = 0xCFbFaC74C26F8647cBDb8c5caf80BB5b32E43134;

  struct ApprovalLevel {
    uint256 minAmount;
    uint256 maxAmount;
    uint8 approvalsRequired;
  }

  struct Deal {
    uint256 nextPayoutNonce;
    bool isActive;
  }

  struct Payout {
    bool isValidated;
    bool isExecuted;
    mapping(address => bool) approvals;
    uint256 approvalCount;
  }

  enum Operation {
    Call,
    DelegateCall
  }

  //  Sentrinel to use with linked lists
  address internal constant SENTINEL_ADDRESS = address(0x1);
  uint256 internal constant SENTINEL_UINT = 1;

  //  //  Storage

  // Next Deal Nonce : Unique across all DAOs
  uint256 public nextDealNonce = SENTINEL_UINT;

  //  List of DAOs using the organizer
  //  Safe Address => DAO
  mapping(address => DAO) daos;

  // Deals
  // Safe Address => Deal Nonce => Deal
  mapping(address => mapping(uint256 => Deal)) public deals;

  // Payout Nonces
  // Deal Nonce => Payout Nonce => Is Used
  mapping(uint256 => mapping(uint256 => Payout)) public payouts;
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
pragma solidity ^0.8.0;

interface GnosisSafe {
  /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
  /// @param to Destination address of module transaction.
  /// @param value Ether value of module transaction.
  /// @param data Data payload of module transaction.
  /// @param operation Operation type of module transaction.
  function execTransactionFromModule(
    address to,
    uint256 value,
    bytes calldata data,
    uint256 operation
  ) external returns (bool success);
}

interface AlowanceModule {
  struct Allowance {
    uint96 amount;
    uint96 spent;
    uint16 resetTimeMin; // Maximum reset time span is 65k minutes
    uint32 lastResetMin;
    uint16 nonce;
  }

  function executeAllowanceTransfer(
    GnosisSafe safe,
    address token,
    address payable to,
    uint96 amount,
    address paymentToken,
    uint96 payment,
    address delegate,
    bytes memory signature
  ) external;

  function getTokenAllowance(
    address safe,
    address delegate,
    address token
  ) external view returns (uint256[5] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureEIP712 {
  using ECDSA for bytes32;

  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  struct DealSignedStructure {
    uint256 dealId;
    uint256 payoutNonce;
    uint96 amount;
    address tokenAddress;
    address recipient;
    uint256 networkId;
    address safeAddress;
    address approver;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
      bytes(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
      )
    );

  bytes32 internal constant DEAL_SIGNATURE_TYPEHASH =
    keccak256(
      bytes(
        "DealSignedStructure(uint256 dealId,uint256 payoutNonce,uint96 amount,address tokenAddress,address recipient,uint256 networkId,address safeAddress,address approver)"
      )
    );

  struct DealSignedBulkStructure {
    uint256[] dealIds;
    uint256[] payoutNonces;
    uint96[] amounts;
    address[] tokenAddresses;
    address[] recipients;
    uint256[] networkIds;
    address[] safeAddresses;
    address approver;
  }

  bytes32 internal constant DEAL_SIGNATURE_BULK_TYPEHASH =
    keccak256(
      bytes(
        "DealSignedBulkStructure(uint256[] dealId,uint256[] payoutNonces,uint96[] amounts,address[] tokenAddresses,address[] recipients,uint256[] networkIds,address[] safeAddresses[],address approver)"
      )
    );

  bytes32 internal DOMAIN_SEPARATOR =
    keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes("DealManager")),
        keccak256(bytes("1.0")),
        1, // mainnet
        address(this)
      )
    );

  function validateSignature(
    uint256 _dealId,
    uint256 payoutNonce,
    uint96 amount,
    bytes memory signature
  ) external pure returns (address) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(_dealId, payoutNonce, amount)
    );

    address approver = messageHash.toEthSignedMessageHash().recover(signature);
    return approver;
  }

  function validateBulkPayout(
    uint256[] memory _dealIds,
    uint256[] memory payoutNonces,
    uint96[] memory amounts,
    bytes memory signature
  ) external pure returns (address) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(_dealIds, payoutNonces, amounts)
    );

    address approver = messageHash.toEthSignedMessageHash().recover(signature);
    return approver;
  }

  function validateSingleDealSignature(
    address approver,
    uint256 _dealId,
    uint256 _payoutNonce,
    uint96 _amount,
    address _tokenAddress,
    address _recipient,
    uint256 _networkId,
    address _safeAddress,
    bytes memory signature
  ) internal view returns (address) {
    DealSignedStructure memory dealTx = DealSignedStructure({
      dealId: _dealId,
      payoutNonce: _payoutNonce,
      amount: _amount,
      tokenAddress: _tokenAddress,
      recipient: _recipient,
      networkId: _networkId,
      safeAddress: _safeAddress,
      approver: approver
    });

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            DEAL_SIGNATURE_TYPEHASH,
            dealTx.dealId,
            dealTx.payoutNonce,
            dealTx.amount,
            dealTx.tokenAddress,
            dealTx.recipient,
            dealTx.networkId,
            dealTx.safeAddress,
            dealTx.approver
          )
        )
      )
    );

    require(approver != address(0), "invalid-address-0");
    address signer = digest.recover(signature);
    return signer;
  }

  function validateBulkDealSignature(
    address approver,
    uint256[] memory _dealIds,
    uint256[] memory _payoutNonces,
    uint96[] memory _amounts,
    address[] memory _tokenAddresses,
    address[] memory _recipients,
    uint256[] memory _networkIds,
    address[] memory _safeAddresses,
    bytes memory signature
  ) internal view returns (address) {
    DealSignedBulkStructure memory dealTx = DealSignedBulkStructure({
      dealIds: _dealIds,
      payoutNonces: _payoutNonces,
      amounts: _amounts,
      tokenAddresses: _tokenAddresses,
      recipients: _recipients,
      networkIds: _networkIds,
      safeAddresses: _safeAddresses,
      approver: approver
    });

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            DEAL_SIGNATURE_BULK_TYPEHASH,
            dealTx.dealIds,
            dealTx.payoutNonces,
            dealTx.amounts,
            dealTx.tokenAddresses,
            dealTx.recipients,
            dealTx.networkIds,
            dealTx.safeAddresses,
            dealTx.approver
          )
        )
      )
    );

    require(approver != address(0), "invalid-address-0");
    address signer = digest.recover(signature);
    return signer;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}