// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title GameRegistry
 * @notice This stores all games in the Oparcade
 * @author David Lee
 */
contract GameRegistry is OwnableUpgradeable {
  event GameAdded(address indexed by, uint256 indexed gid, string gameName);
  event GameRemoved(address indexed by, uint256 indexed gid, string gameName);
  event DepositAmountUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed token,
    uint256 oldAmount,
    uint256 newAmount
  );
  event DistributableAmountUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed token,
    bool oldStatus,
    bool newStatus
  );

  /// @dev Game name array
  string[] public games;

  /// @dev Game ID -> Deposit token list
  mapping(uint256 => address[]) public depositTokenList;

  /// @dev Game ID -> Tournament ID -> Token address -> Deposit amount
  mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public depositTokenAmount;

  /// @dev Game ID -> Distributable token list
  mapping(uint256 => address[]) public distributableTokenList;

  /// @dev Game ID -> Token address -> Bool
  mapping(uint256 => mapping(address => bool)) public distributable;

  /// @dev Game ID -> Bool
  mapping(uint256 => bool) public isDeprecatedGame;

  modifier onlyValidGID(uint256 _gid) {
    require(_gid < games.length, "Invalid game index");
    _;
  }

  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @notice Add new game
   * @param _gameName Game name to add
   */
  function addGame(string memory _gameName) external onlyOwner returns (uint256 gid) {
    games.push(_gameName);
    gid = games.length - 1;

    emit GameAdded(msg.sender, gid, _gameName);
  }

  /**
   * @notice Remove game
   * @dev Game is not removed from the games array, just set it deprecated
   */
  function removeGame(uint256 _gid) external onlyOwner onlyValidGID(_gid) {
    // remove game
    isDeprecatedGame[_gid] = true;

    emit GameRemoved(msg.sender, _gid, games[_gid]);
  }

  /**
   * @notice Update deposit token amount
   * @dev Only owner
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function updateDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external onlyOwner onlyValidGID(_gid) {
    emit DepositAmountUpdated(msg.sender, _gid, _token, depositTokenAmount[_gid][_tid][_token], _amount);

    // update deposit token list
    if (_amount > 0) {
      if (depositTokenAmount[_gid][_tid][_token] == 0) {
        // add token to the list only if it's added newly
        depositTokenList[_gid].push(_token);
      }
    } else {
      for (uint256 i; i < depositTokenList[_gid].length; i++) {
        if (_token == depositTokenList[_gid][i]) {
          depositTokenList[_gid][i] = depositTokenList[_gid][depositTokenList[_gid].length - 1];
          depositTokenList[_gid].pop();
        }
      }
    }

    // update deposit token amount
    depositTokenAmount[_gid][_tid][_token] = _amount;
  }

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function updateDistributableTokenAddress(
    uint256 _gid,
    address _token,
    bool _isDistributable
  ) external onlyOwner onlyValidGID(_gid) {
    emit DistributableAmountUpdated(msg.sender, _gid, _token, distributable[_gid][_token], _isDistributable);

    // update distributable token list
    if (_isDistributable) {
      if (!distributable[_gid][_token]) {
        // add token to the list only if it's added newly
        distributableTokenList[_gid].push(_token);
      }
    } else {
      for (uint256 i; i < distributableTokenList[_gid].length; i++) {
        if (_token == distributableTokenList[_gid][i]) {
          distributableTokenList[_gid][i] = distributableTokenList[_gid][distributableTokenList[_gid].length - 1];
          distributableTokenList[_gid].pop();
        }
      }
    }

    // update distributable token amount
    distributable[_gid][_token] = _isDistributable;
  }

  function getDepositTokenList(uint256 _gid) external view returns (address[] memory) {
    return depositTokenList[_gid];
  }

  function getDistributableTokenList(uint256 _gid) external view returns (address[] memory) {
    return distributableTokenList[_gid];
  }

  /**
   * @notice Returns the number of games added in games array
   */
  function gameLength() external view returns (uint256) {
    return games.length;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}