pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/BasicMetaTransaction.sol";
import "./Admin.sol";

// Potential statuses of an asset
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

library XPUtils {
  using SafeMath for uint256;

  function createProject(
    Project storage _project,
    bytes32[] storage _projectIds,
    bytes32 _projectId,
    string memory _name,
    Action[] memory _inputActions,
    string[] memory _scoreTypes,
    address[] memory _owners,
    address[] memory _updaters
  ) external {
    require(_inputActions.length <= 20, "Can submit up to 20 actions");
    require(_scoreTypes.length <= 20, "Can submit up to 20 score types");

    _project.id = _projectId;
    _project.name = _name;
    _project.scoreTypes = _scoreTypes;
    _project.owners = _owners;
    _project.updaters = _updaters;
    _project.status = ProjectStatus.Running;

    for (uint256 i = 0; i < _scoreTypes.length; i++) {
      _project.scoreTypeToDoesExist[_scoreTypes[i]] = true;
    }

    // Loops through and add actions 1 by 1, limit actions list to 20
    for (uint256 i = 0; i < _inputActions.length; i++) {
      _project.actions.push(
        Action(
          _inputActions[i].name,
          _inputActions[i].points,
          _inputActions[i].direction,
          true
        )
      );
      // Mapping points each name to the action object associated
      _project.nameToAction[_inputActions[i].name] = Action(
        _inputActions[i].name,
        _inputActions[i].points,
        _inputActions[i].direction,
        true
      );
    }

    for (uint256 j = 0; j < _owners.length; j++) {
      // Owners array placed into mapping
      _project.isAddressOwner[_owners[j]] = true;
    }
    for (uint256 k = 0; k < _updaters.length; k++) {
      // Owners array placed into mapping
      _project.isAddressUpdater[_updaters[k]] = true;
    }

    _projectIds.push(_projectId);
  }

  function addActions(Project storage _project, Action[] memory _inputActions)
    external
  {
    require(
      _project.status != ProjectStatus.NonExistant,
      "Project does not exist"
    );
    require(_inputActions.length <= 20, "Can submit up to 20 actions");

    // Loops through and add actions 1 by 1, limit actions list to 20
    for (uint256 i = 0; i < _inputActions.length; i++) {
      if (_project.nameToAction[_inputActions[i].name].isValid) {
        // Action exists, only need to update
        _project.nameToAction[_inputActions[i].name] = Action(
          _inputActions[i].name,
          _inputActions[i].points,
          _inputActions[i].direction,
          true
        );
      } else {
        //Action does not exist so update it in the mapping as well as the actions list
        _project.actions.push(
          Action(
            _inputActions[i].name,
            _inputActions[i].points,
            _inputActions[i].direction,
            true
          )
        ); //List of actions to loop through.
        _project.nameToAction[_inputActions[i].name] = Action(
          _inputActions[i].name,
          _inputActions[i].points,
          _inputActions[i].direction,
          true
        );
      }
    }
  }

  function addProjectOwner(Project storage _project, address _newOwner)
    external
  {
    _project.isAddressOwner[_newOwner] = true;
    _project.owners.push(_newOwner);
  }

  function removeProjectOwner(Project storage _project, address _owner)
    external
  {
    require(_project.owners.length > 1, "Cannot delete last remaining owner");
    _project.isAddressOwner[_owner] = false;

    for (uint256 i = 0; i < _project.owners.length; i++) {
      if (_project.owners[i] == _owner) {
        delete _project.owners[i];
        break;
      }
    }
  }

  function addProjectUpdater(Project storage _project, address _newUpdater)
    external
  {
    _project.isAddressUpdater[_newUpdater] = true;
    _project.updaters.push(_newUpdater);
  }

  function removeProjectUpdater(Project storage _project, address _updater)
    external
  {
    _project.isAddressUpdater[_updater] = false;

    for (uint256 i = 0; i < _project.updaters.length; i++) {
      if (_project.updaters[i] == _updater) {
        delete _project.updaters[i];
        break;
      }
    }
  }

  function addScoreTypes(Project storage _project, string[] memory _scoreTypes)
    external
  {
    for (uint256 i = 0; i < _scoreTypes.length; i++) {
      _project.scoreTypes.push(_scoreTypes[i]);
    }
  }

  function removeScoreType(Project storage _project, string memory _scoreType)
    external
  {
    string[] memory existingScoreTypes = _project.scoreTypes;

    for (uint256 i = 0; i < existingScoreTypes.length; i++) {
      if (
        keccak256(abi.encodePacked(_scoreType)) ==
        keccak256(abi.encodePacked(existingScoreTypes[i]))
      ) {
        delete _project.scoreTypes[i];
        _project.scoreTypeToDoesExist[_scoreType] = false;
        break;
      }
    }
  }

  function updateScore(
    Project storage _project,
    bytes32 _updateId,
    Scoreboard storage currScoreboard,
    Action memory currAction,
    string memory _scoreType
  ) external returns (bool) {
    require(_project.status == ProjectStatus.Running, "Project is not active");
    require(currAction.isValid, "Action must exist");
    require(
      _project.scoreTypeToDoesExist[_scoreType] == true,
      "Score type does not exist in this project"
    );

    if (_project.updateIdToDoesExist[_updateId] == false) {
      _project.updateIdToDoesExist[_updateId] = true;

      if (currAction.direction == Direction.increase) {
        currScoreboard.scores[_scoreType] = currScoreboard
          .scores[_scoreType]
          .add(currAction.points);
      } else if (currAction.direction == Direction.decrease) {
        //check if score will go below zero, if so then set it to 0 (lower limit);
        if (currAction.points >= currScoreboard.scores[_scoreType]) {
          currScoreboard.scores[_scoreType] = uint256(0);
        } else {
          currScoreboard.scores[_scoreType] = currScoreboard
            .scores[_scoreType]
            .sub(currAction.points);
        }
      } else {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }
}

contract XP is Pausable, BasicMetaTransaction, Admin {
  using SafeMath for uint256;

  event ProjectCreated(
    bytes32 indexed projectId,
    string name,
    address creator,
    Action[] actions,
    string[] _scoreTypes,
    address[] owners,
    address[] updaters
  );

  event NewActions(bytes32 projectId, Action[] actions);

  event NewScoreTypes(
    bytes32 projectId,
    string[] scoreTypesAdded,
    string[] allScoreTypes
  );

  event RemoveScoreType(
    bytes32 projectId,
    string scoreTypeRemoved,
    string[] allScoreTypes
  );

  event UpdateScore(
    bytes32 updateId,
    bytes32 projectId,
    address targetAddress,
    uint256 newPoints,
    uint256 pointChange,
    Direction direction,
    string actionName,
    string scoreType,
    string[] scoreTypes // All score types for the project
  );

  event UpdateScoreFailed(
    bytes32 updateId,
    bytes32 projectId,
    address targetAddress
  );

  event ProjectOwnerAdded(bytes32 projectId, address newOwner);

  event ProjectOwnerRemoved(bytes32 projectId, address ownerRemoved);

  event ProjectUpdaterAdded(bytes32 projectId, address newUpdater);

  event ProjectUpdaterRemoved(bytes32 projectId, address updaterRemoved);

  /*
    A project is an instance of an XP system
  */

  bytes32[] projectIds; // keeps track of all project ids

  // Mapping of all the exists projects
  mapping(bytes32 => Project) public idToProject;

  // ************************    OWNER ONLY CALLABLE FUNCTIONS     *******************************

  function pause() external onlyOwner whenNotPaused {
    _pause(); // from Pausable.sol
  }

  function unpause() external onlyOwner whenPaused {
    _unpause(); //from Pausable.sol
  }

  // ************************ END ---- OWNER ONLY CALLABLE FUNCTIONS ----- END *******************************

  function createProject(
    bytes32 _projectId,
    string memory _name,
    Action[] memory _inputActions,
    string[] memory _scoreTypes,
    address[] memory _owners,
    address[] memory _updaters
  ) public whenNotPaused {
    require(
      idToProject[_projectId].status == ProjectStatus.NonExistant,
      "Project already exists"
    );

    XPUtils.createProject(
      idToProject[_projectId],
      projectIds,
      _projectId,
      _name,
      _inputActions,
      _scoreTypes,
      _owners,
      _updaters
    );

    emit ProjectCreated(
      _projectId,
      _name,
      msgSender(),
      idToProject[_projectId].actions,
      _scoreTypes,
      _owners,
      _updaters
    );
  }

  function addProjectOwner(bytes32 _projectId, address _newOwner)
    public
    whenNotPaused
  {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );

    XPUtils.addProjectOwner(idToProject[_projectId], _newOwner);

    emit ProjectOwnerAdded(_projectId, _newOwner);
  }

  function removeProjectOwner(bytes32 _projectId, address _owner)
    public
    whenNotPaused
  {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );
    require(
      idToProject[_projectId].isAddressOwner[_owner] == true,
      "This address is not an owner."
    );
    XPUtils.removeProjectOwner(idToProject[_projectId], _owner);

    emit ProjectOwnerRemoved(_projectId, _owner);
  }

  function addProjectUpdater(bytes32 _projectId, address _newUpdater)
    public
    whenNotPaused
  {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );

    XPUtils.addProjectUpdater(idToProject[_projectId], _newUpdater);

    emit ProjectUpdaterAdded(_projectId, _newUpdater);
  }

  function removeProjectUpdater(bytes32 _projectId, address _updater)
    public
    whenNotPaused
  {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );
    require(
      idToProject[_projectId].isAddressUpdater[_updater] == true,
      "This address is not an updater."
    );
    XPUtils.removeProjectUpdater(idToProject[_projectId], _updater);

    emit ProjectUpdaterRemoved(_projectId, _updater);
  }

  function pauseProject(bytes32 _projectId) public whenNotPaused {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );
    idToProject[_projectId].status = ProjectStatus.Paused;
  }

  function resumeProject(bytes32 _projectId) public whenNotPaused {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project"
    );
    idToProject[_projectId].status = ProjectStatus.Running;
  }

  function addScoreTypes(bytes32 _projectId, string[] memory _scoreTypes)
    public
    whenNotPaused
  {
    require(
      idToProject[_projectId].status != ProjectStatus.NonExistant,
      "Project does not exist"
    );
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project to update actions"
    );
    require(_scoreTypes.length <= 20, "Can submit up to 20 actions");

    XPUtils.addScoreTypes(idToProject[_projectId], _scoreTypes);

    emit NewScoreTypes(
      _projectId,
      _scoreTypes,
      idToProject[_projectId].scoreTypes
    );
  }

  function removeScoreType(bytes32 _projectId, string memory _scoreType)
    public
    whenNotPaused
  {
    require(
      idToProject[_projectId].status != ProjectStatus.NonExistant,
      "Project does not exist"
    );
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project to update actions"
    );
    XPUtils.removeScoreType(idToProject[_projectId], _scoreType);

    emit RemoveScoreType(
      _projectId,
      _scoreType,
      idToProject[_projectId].scoreTypes
    );
  }

  /*
    Add new action types to project Scoreboards
  */
  function addActions(bytes32 _projectId, Action[] memory _inputActions)
    public
    whenNotPaused
  {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be an owner of the project to update actions"
    );

    XPUtils.addActions(idToProject[_projectId], _inputActions);

    emit NewActions(_projectId, _inputActions);
  }

  function updateScore(
    bytes32 _updateId,
    bytes32 _projectId,
    string memory _actionName,
    string memory _scoreType,
    address _targetWallet
  ) public whenNotPaused {
    require(
      (idToProject[_projectId].isAddressOwner[msgSender()] ||
        idToProject[_projectId].isAddressUpdater[msgSender()] ||
        owner() == msgSender() ||
        isAdmin(msgSender()) == true),
      "You must be either an owner or an updater to use this function"
    );

    bool updated = XPUtils.updateScore(
      idToProject[_projectId],
      _updateId,
      idToProject[_projectId].addressToScoreboard[_targetWallet],
      idToProject[_projectId].nameToAction[_actionName],
      _scoreType
    );

    if (updated) {
      emit UpdateScore(
        _updateId,
        _projectId,
        _targetWallet,
        idToProject[_projectId].addressToScoreboard[_targetWallet].scores[
          _scoreType
        ],
        idToProject[_projectId].nameToAction[_actionName].points,
        idToProject[_projectId].nameToAction[_actionName].direction,
        _actionName,
        _scoreType,
        idToProject[_projectId].scoreTypes
      );
    } else {
      emit UpdateScoreFailed(_updateId, _projectId, _targetWallet);
    }
  }

  /*
    Returns specific score for a user (must specift score type)
  */
  function getScore(
    bytes32 _projectId,
    string memory _scoreType,
    address _targetWallet
  ) external view returns (uint256) {
    return
      idToProject[_projectId].addressToScoreboard[_targetWallet].scores[
        _scoreType
      ];
  }

  function getScoreTypesFromProject(bytes32 _projectId)
    external
    view
    returns (string[] memory)
  {
    return idToProject[_projectId].scoreTypes;
  }

  function getActionsFromProjectId(bytes32 _projectId)
    external
    view
    returns (Action[] memory)
  {
    return idToProject[_projectId].actions;
  }

  function getUpdatersFromProjectId(bytes32 _projectId)
    external
    view
    returns (address[] memory)
  {
    return idToProject[_projectId].updaters;
  }

  function getOwnersFromProjectId(bytes32 _projectId)
    external
    view
    returns (address[] memory)
  {
    return idToProject[_projectId].owners;
  }
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

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

  function removeAdmin(address _removeAdmin) external onlyOwner {
    addressToIsAdmin[_removeAdmin] = false;

    for (uint256 i = 0; i < admins.length; i++) {
      if (admins[i] == _removeAdmin) {
        delete admins[i];
        break;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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