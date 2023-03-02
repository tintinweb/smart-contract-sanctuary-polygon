/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/lib/BasicMetaTransaction.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BasicMetaTransaction {
  using SafeMath for uint256;

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) nonces;

  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Main function to be called when user wants to execute meta transaction.
   * The actual function to be called should be passed as param with name functionSignature
   * Here the basic signature recovery is being used. Signature is expected to be generated using
   * personal_sign method.
   * @param userAddress Address of user trying to do meta transaction
   * @param functionSignature Signature of the actual function to be called via meta transaction
   * @param sigR R part of the signature
   * @param sigS S part of the signature
   * @param sigV V part of the signature
   */
  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    require(
      verify(
        userAddress,
        nonces[userAddress],
        getChainID(),
        functionSignature,
        sigR,
        sigS,
        sigV
      ),
      "Signer and signature do not match"
    );
    nonces[userAddress] = nonces[userAddress].add(1);

    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );

    require(success, "Function call not successfull");
    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );
    return returnData;
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function verify(
    address owner,
    uint256 nonce,
    uint256 chainID,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public view returns (bool) {
    bytes32 hash = prefixed(
      keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
    );
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return (owner == signer);
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      return msg.sender;
    }
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/Admin.sol

pragma solidity ^0.8.0;

contract Admin is Ownable {
  // Contract level admins
  mapping(address => bool) addressToIsAdmin;
  address[] public admins;

  function isAdmin(address _user) internal view returns (bool) {
    return addressToIsAdmin[_user];
  }

  function addAdmin(address _newAdmin) external onlyOwner {
    addressToIsAdmin[_newAdmin] = true;
    admins.push(_newAdmin);
  }

  function getAdmins() external view returns (address[] memory) {
    return admins;
  }

  function removeAdmin(address _removeAdmin) external onlyOwner {
    addressToIsAdmin[_removeAdmin] = false;

    for (uint256 i = 0; i < admins.length; i++) {
      if (admins[i] == _removeAdmin) {
        admins[i] = admins[admins.length - 1];
        admins.pop(); //always pop last element
        break;
      }
    }
  }
}

// File: contracts/IXP.sol

pragma solidity ^0.8.0;

interface IXP {
  enum ProjectStatus {
    NonExistant,
    Running,
    Paused
  }

  enum Direction {
    increase,
    decrease
  }

  struct Scoreboard {
    mapping(string => uint256) scores;
  }

  struct Project {
    bytes32 id;
    string name;
    mapping(string => Action) nameToAction;
    Action[] actions;
    address[] owners;
    mapping(address => bool) isAddressOwner; // used to check if an address is an owner
    address[] updaters; // contracts and wallets allowed to update the score
    mapping(address => bool) isAddressUpdater; // used to check if an address is an updater
    ProjectStatus status; // allow the owner of this to pause project updates
    mapping(address => Scoreboard) addressToScoreboard;
    mapping(bytes32 => bool) updateIdToDoesExist;
    mapping(string => bool) scoreTypeToDoesExist;
    string[] scoreTypes;
  }

  struct Action {
    string name;
    uint256 points;
    Direction direction;
    bool isValid;
  }

  function updateScore(
    bytes32 _updateId,
    bytes32 _projectId,
    string memory _actionName,
    string memory _scoreType,
    address _targetWallet
  ) external;

  function getScore(
    bytes32 _projectId,
    string memory _scoreType,
    address _targetWallet
  ) external view returns (uint256);

  function getScoreTypesFromProject(bytes32 _projectId)
    external
    view
    returns (string[] memory);

  function getActionsFromProjectId(bytes32 _projectId)
    external
    view
    returns (Action[] memory);

  // mapping(bytes32 => Project) public idToProject;
  // function idToProject() public view returns (Project memory);
}

// File: contracts/RedeemablesStorage.sol

pragma solidity ^0.8.0;





// ActivePurchase = Redeemable is active and must be purchased
// ActiveEarn = Redeemable is active and must be earned
enum Status {
  ActivePurchase,
  ActiveEarn,
  Paused,
  Ended
}

struct Redeemable {
  bytes32 id;
  bytes32 projectId;
  uint256 token;
  uint256 amount;
  address creator;
  string name;
  address contractAddress;
  Status status;
  uint256 points;
  string actionName;
  string scoreType;
  bool requiresPurchase;
}

contract RedeemablesStorage is Pausable, Admin, BasicMetaTransaction {
  using SafeMath for uint256;

  event CreatedRedeemable(
    bytes32 redeemableId,
    bytes32 projectId,
    uint256 token,
    uint256 amount,
    string name,
    uint256 points,
    string actionName,
    string scoreType,
    address contractAddress,
    address creator,
    bool requiresPurchase
  );

  event RemovedRedeemable(bytes32 redeemableId, bytes32 projectId);

  event ResumedRedeemable(bytes32 redeemableId, Status status);

  event PausedRedeemable(bytes32 redeemableId);

  event UpdatedRedeemableAction(
    bytes32 redeemableId,
    uint256 points,
    string actionName,
    string scoreType
  );

  event UpdatedRedeemableAmount(bytes32 redeemableId, uint256 amount);

  event UpdatedRedeemableStatus(bytes32 redeemableId, Status status);

  address[] public functionsContracts;
  address public xpContract;

  bytes32[] redeemableIds;
  mapping(bytes32 => Redeemable) public idToRedeemable;
  mapping(bytes32 => address) public idToContract;

  constructor(address _xpContract) {
    xpContract = _xpContract;
  }

  modifier onlyFunctionsContract() {
    bool isFunctionContract = false;

    for (uint8 i = 0; i < functionsContracts.length; i++) {
      if (msgSender() == functionsContracts[i]) {
        isFunctionContract = true;
      }
    }
    require(
      isFunctionContract == true,
      "Can only be called by registered contract."
    );
    _;
  }

  function setFunctionsContract(address _functionsContract) external onlyOwner {
    functionsContracts.push(_functionsContract);
  }

  function removeFunctionsContract(address _functionsContract)
    external
    onlyOwner
  {
    for (uint8 i = 0; i < functionsContracts.length; i++) {
      if (_functionsContract == functionsContracts[i]) {
        delete functionsContracts[i];
      }
    }
  }

  function pause() external onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() external onlyOwner whenPaused {
    _unpause();
  }

  function checkIfActionExists(
    bytes32 _projectId,
    string memory _actionName,
    uint256 _points
  ) internal view returns (bool) {
    IXP.Action[] memory actions = IXP(xpContract).getActionsFromProjectId(
      _projectId
    );

    bool actionCorrect = false;

    for (uint8 i = 0; i < actions.length; i++) {
      if (
        keccak256(abi.encodePacked(actions[i].name)) ==
        keccak256(abi.encodePacked(_actionName))
      ) {
        if (actions[i].points == _points) {
          actionCorrect = true;
        }
        break;
      }
    }

    return actionCorrect;
  }

  function checkIfScoreTypeExists(bytes32 _projectId, string memory _scoreType)
    internal
    view
    returns (bool)
  {
    string[] memory scoreTypes = IXP(xpContract).getScoreTypesFromProject(
      _projectId
    );

    bool scoreTypeExists = false;

    for (uint8 i = 0; i < scoreTypes.length; i++) {
      if (
        keccak256(abi.encodePacked(scoreTypes[i])) ==
        keccak256(abi.encodePacked(_scoreType))
      ) {
        scoreTypeExists = true;
      }
    }

    return scoreTypeExists;
  }

  function createRedeemable(
    bytes32 _redeemableId,
    bytes32 _projectId,
    uint256 _token,
    uint256 _amount,
    string memory _name,
    uint256 _points,
    string memory _actionName,
    string memory _scoreType,
    address _contract,
    address _creator,
    bool _requiresPurchase
  ) public whenNotPaused onlyFunctionsContract {
    require(_amount > 0, "Amount must be greater than zero.");
    require(_points > 0, "Points must be greater than zero.");

    require(
      idToRedeemable[_redeemableId].id != _redeemableId,
      "Redeemable ID already in use."
    );

    if (_requiresPurchase == true) {
      require(
        checkIfActionExists(_projectId, _actionName, _points),
        "Action does not exist in the given project or the points provided are incorrect."
      );
    }
    require(
      checkIfScoreTypeExists(_projectId, _scoreType),
      "Score type does not exist in the given project."
    );

    Redeemable storage _redeemable = idToRedeemable[_redeemableId];

    _redeemable.id = _redeemableId;
    _redeemable.projectId = _projectId;
    _redeemable.token = _token;
    _redeemable.amount = _amount;
    _redeemable.creator = _creator;
    _redeemable.name = _name;
    _redeemable.points = _points;
    _redeemable.actionName = _actionName;
    _redeemable.scoreType = _scoreType;
    _redeemable.contractAddress = _contract;
    _redeemable.requiresPurchase = _requiresPurchase;
    if (_requiresPurchase == true) {
      _redeemable.status = Status.ActivePurchase;
    } else {
      _redeemable.status = Status.ActiveEarn;
    }

    idToContract[_redeemableId] = _contract;

    redeemableIds.push(_redeemableId);

    emit CreatedRedeemable(
      _redeemableId,
      _projectId,
      _token,
      _amount,
      _name,
      _points,
      _actionName,
      _scoreType,
      _contract,
      _creator,
      _requiresPurchase
    );
  }

  function removeRedeemable(bytes32 _redeemableId) public {
    require(
      idToRedeemable[_redeemableId].creator == msgSender() ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true,
      "Must be creator of redeemable to remove redeemable."
    );

    // Alternative, just set status to ended:
    // idToRedeemable[_redeemableId].status = Status.Ended;

    delete idToRedeemable[_redeemableId];
    delete idToContract[_redeemableId];

    emit RemovedRedeemable(
      _redeemableId,
      idToRedeemable[_redeemableId].projectId
    );
  }

  function pauseRedeemable(bytes32 _redeemableId) public {
    require(
      idToRedeemable[_redeemableId].creator == msgSender() ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true,
      "Must be creator of redeemable to pause redeemable."
    );

    idToRedeemable[_redeemableId].status = Status.Paused;

    emit PausedRedeemable(_redeemableId);
  }

  function resumeRedeemable(bytes32 _redeemableId) public {
    require(
      idToRedeemable[_redeemableId].creator == msgSender() ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true,
      "Must be creator of redeemable to pause redeemable."
    );

    Status _status;

    if (idToRedeemable[_redeemableId].requiresPurchase == true) {
      idToRedeemable[_redeemableId].status = Status.ActivePurchase;
      _status = Status.ActivePurchase;
    } else {
      idToRedeemable[_redeemableId].status = Status.ActiveEarn;
      _status = Status.ActiveEarn;
    }

    emit ResumedRedeemable(_redeemableId, _status);
  }

  function updateRedeemableAction(
    bytes32 _redeemableId,
    uint256 _points,
    string memory _actionName,
    string memory _scoreType
  ) public {
    require(
      idToRedeemable[_redeemableId].creator == msgSender() ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true,
      "Must be creator of redeemable to remove redeemable."
    );
    require(
      checkIfActionExists(
        idToRedeemable[_redeemableId].projectId,
        _actionName,
        _points
      ),
      "Action does not exist in the given project."
    );
    require(
      checkIfScoreTypeExists(
        idToRedeemable[_redeemableId].projectId,
        _scoreType
      ),
      "Score type does not exist in the given project."
    );

    idToRedeemable[_redeemableId].points = _points;
    idToRedeemable[_redeemableId].actionName = _actionName;
    idToRedeemable[_redeemableId].scoreType = _scoreType;

    emit UpdatedRedeemableAction(
      _redeemableId,
      _points,
      _actionName,
      _scoreType
    );
  }

  function updateRedeemableAmount(bytes32 _redeemableId, uint256 _amount)
    public
    onlyFunctionsContract
  {
    idToRedeemable[_redeemableId].amount = _amount;

    emit UpdatedRedeemableAmount(_redeemableId, _amount);
  }

  function updateRedeemableStatus(bytes32 _redeemableId, Status _status)
    public
    onlyFunctionsContract
  {
    idToRedeemable[_redeemableId].status = _status;

    emit UpdatedRedeemableStatus(_redeemableId, _status);
  }

  function getRedeemableProjectId(bytes32 _redeemableId)
    external
    view
    returns (bytes32 _projectId)
  {
    return idToRedeemable[_redeemableId].projectId;
  }

  function getRedeemable(bytes32 _redeemableId)
    external
    view
    returns (
      bytes32 _projectId,
      uint256 _token,
      uint256 _amount,
      string memory _name,
      address _creator,
      uint256 _points,
      string memory _actionName,
      string memory _scoreType,
      address _contract,
      Status _status,
      bool _requiresPurchase
    )
  {
    Redeemable storage _redeemable = idToRedeemable[_redeemableId];

    return (
      _redeemable.projectId,
      _redeemable.token,
      _redeemable.amount,
      _redeemable.name,
      _redeemable.creator,
      _redeemable.points,
      _redeemable.actionName,
      _redeemable.scoreType,
      _redeemable.contractAddress,
      _redeemable.status,
      _redeemable.requiresPurchase
    );
  }
}