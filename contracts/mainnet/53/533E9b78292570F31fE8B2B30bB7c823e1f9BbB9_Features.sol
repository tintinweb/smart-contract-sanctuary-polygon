// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';

import './PausableFeature.sol';
import './FreezableFeature.sol';
import "./AutoburnFeature.sol";

/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract Features is PausableFeature, FreezableFeature, AutoburnFeature, Ownable {
  uint8 public features;
  uint8 public constant ForceTransfer = 0x01;
  uint8 public constant Pausable = 0x02;
  uint8 public constant AccountBurning = 0x04;
  uint8 public constant AccountFreezing = 0x08;
  uint8 public constant TransferRules = 0x10;
  uint8 public constant AutoBurn = 0x20;

  modifier enabled(uint8 feature) {
    require(isEnabled(feature), 'Features: Token feature is not enabled');
    _;
  }

  event FeaturesUpdated(
    bool forceTransfer,
    bool tokenFreeze,
    bool accountFreeze,
    bool accountBurn,
    bool transferRules,
    bool autoburn
  );

  constructor(address _owner, uint8 _features, bytes memory _options) {
    _enable(_features, _options);
    transferOwnership(_owner);
  }

  function _enable(uint8 _features, bytes memory _options) internal {
    features = _features;
    emit FeaturesUpdated(
      _features & ForceTransfer != 0,
      _features & Pausable != 0,
      _features & AccountBurning != 0,
      _features & AccountFreezing != 0,
      _features & TransferRules != 0,
      _features & AutoBurn != 0
    );

    if (_features & AutoBurn != 0) {
      _setAutoburnTs(_options);
    }
  }

  function isEnabled(uint8 _feature) public view returns (bool) {
    return features & _feature != 0;
  }

  function isAutoburned() public view returns (bool) {
    return isEnabled(AutoBurn) && _isAutoburned();
  }

  function checkTransfer(address _from, address _to) external view returns (bool) {
    return !_isAccountFrozen(_from) && !_isAccountFrozen(_to) && !paused && !isAutoburned();
  }

  function isAccountFrozen(address _account) external view returns (bool) {
    return _isAccountFrozen(_account);
  }

  function freezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _freezeAccount(_account);
  }

  function unfreezeAccount(address _account) external enabled(AccountFreezing) onlyOwner {
    _unfreezeAccount(_account);
  }

  function pause() external enabled(Pausable) onlyOwner {
    _pause();
  }

  function unpause() external enabled(Pausable) onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract PausableFeature {
  bool public paused;

  event Paused(address account);
  event Unpaused(address account);

  constructor() {
    paused = false;
  }

  function _pause() internal {
    paused = true;
    emit Paused(msg.sender);
  }

  function _unpause() internal {
    paused = false;
    emit Unpaused(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract FreezableFeature {
  mapping(address => bool) private frozen;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  function _freezeAccount(address _account) internal {
    frozen[_account] = true;
    emit AccountFrozen(_account);
  }

  function _unfreezeAccount(address _account) internal {
    frozen[_account] = false;
    emit AccountUnfrozen(_account);
  }

  function _isAccountFrozen(address _account) internal view returns (bool) {
    return frozen[_account];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract AutoburnFeature {
  uint256 public autoburnTs;

  event AutoburnTsSet(uint256 ts);

  function _setAutoburnTs(bytes memory _options) internal {
    (autoburnTs) = abi.decode(_options, (uint256));
    emit AutoburnTsSet(autoburnTs);
  }

  function _isAutoburned() internal view returns (bool) {
    return block.timestamp >= autoburnTs;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}