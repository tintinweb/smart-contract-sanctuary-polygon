/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-**-**
 */

pragma solidity ^0.8.9;

// SPDX-License-Identifier: Unlicensed

interface IERC20 {
  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

abstract contract Context {
  //function _msgSender() internal view virtual returns (address payable) {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract dintDistributer is Ownable {
  IERC20 public dintToken = IERC20(0x97df2760193Df86af0A5248D7DFc0AA0b52AC2F5); //

  address public feeCollector;

  mapping(address => bool) public isRegistered;
  mapping(address => bool) public isManaged;

  mapping(address => bool) public isReferrer;
  mapping(address => bool) public blockedReferrer;
  mapping(address => uint256) public startedReferringAt;
  mapping(address => address) public tipRecieverToReferrer;

  event tipSent(address _sender, address _recipient);

  constructor() {
    feeCollector = _msgSender();
  }

  function register(
    address _user,
    address _referrer,
    bool _isManaged
  ) external onlyOwner {
    require(!isRegistered[_user], "User already registered");
    require(isReferrer[_referrer] || _referrer == address(0), "Unknown referrer");
    isRegistered[_user] = true;
    tipRecieverToReferrer[_user] = _referrer;
    isManaged[_user] = _isManaged;
  }

  function changeReferrerState(bool _isReferrer) external {
    require(isReferrer[_msgSender()] != _isReferrer, "Value updated to same");
    require(!blockedReferrer[_msgSender()], "Please refer to admin");
    isReferrer[_msgSender()] = _isReferrer;
    if (_isReferrer && startedReferringAt[_msgSender()] == 0) {
      startedReferringAt[_msgSender()] = block.timestamp;
    }
  }

  function blockUnblockReferrer(address _referrer, bool _blocked) external onlyOwner {
    blockedReferrer[_referrer] = true;
    if (_blocked) {
      isReferrer[_referrer] = false;
    }
  }

  function setFeeCollector(address _feeCollector) external onlyOwner {
    require(_feeCollector != feeCollector, "Value updated to same");
    feeCollector = _feeCollector;
  }

  function changeManagedState(address _user, bool _isManaged) external onlyOwner {
    require(isManaged[_user] != _isManaged, "Value updated to same");
    isManaged[_user] = _isManaged;
  }

  function unRegister(address _user) external onlyOwner {
    require(isRegistered[_user], "User not registered");
    isRegistered[_user] = false;
    tipRecieverToReferrer[_user] = address(0);
    isManaged[_user] = false;
  }

  // approving this contract to use balance is needed in order to execute the erc20 transferFrom
  function sendDint(address _recipient, uint256 _amount) external {
    address _sender = _msgSender();
    require(isRegistered[_sender], "sender not registered");
    require(isRegistered[_recipient], "recipient not registered");
    require(_amount > 0, "Zero amount error");
    address _referrer = tipRecieverToReferrer[_recipient];
    uint256 forDintApp;
    uint256 forReferrer;
    uint256 forRecipient;
    if (isRegistered[_referrer] && _referrer != address(0) && (block.timestamp - startedReferringAt[_referrer]) < 315360000) {
      // 315360000 is number of seconds in 10 years
      forDintApp = (_amount * 15) / 100;
      forReferrer = (_amount * 5) / 100;
      forRecipient = _amount - forDintApp - forReferrer;
    } else {
      forDintApp = (_amount * 20) / 100;
      forRecipient = _amount - forDintApp - forReferrer;
    }
    uint256 forManaging = isManaged[_recipient] ? (_amount * 10) / 100 : 0;
    forDintApp += forManaging;
    forRecipient -= forManaging;

    dintToken.transferFrom(_sender, feeCollector, forDintApp);
    if (forReferrer > 0) {
      dintToken.transferFrom(_sender, _referrer, forReferrer);
    }

    dintToken.transferFrom(_sender, _recipient, forRecipient);

    emit tipSent(_sender, _recipient);
  }

  function reward(address _user, uint256 _amount) external onlyOwner {
    require(isRegistered[_user], "User not registered");
    require(_amount > 0, "Zero amount error");
    address _referrer = tipRecieverToReferrer[_user];
    uint256 forDintApp;
    uint256 forReferrer;
    uint256 forRecipient;
    if (_referrer != address(0) && (block.timestamp - startedReferringAt[_referrer]) < 315360000) {
      // 315360000 is number of seconds in 10 years
      forDintApp = (_amount * 15) / 100;
      forReferrer = (_amount * 5) / 100;
      forRecipient = _amount - forDintApp - forReferrer;
    } else {
      forDintApp = (_amount * 20) / 100;
      forRecipient = _amount - forDintApp - forReferrer;
    }
    uint256 forManaging = isManaged[_user] ? (_amount * 10) / 100 : 0;
    forDintApp += forManaging;
    forRecipient -= forManaging;

    dintToken.transfer(feeCollector, forDintApp);
    if (forReferrer > 0) {
      dintToken.transfer(_referrer, forReferrer);
    }

    dintToken.transfer(_user, forRecipient);
  }

  function withdrawToken(
    address _token,
    uint256 _amount,
    address _to
  ) external onlyOwner {
    IERC20(_token).transfer(_to, _amount);
  }
}