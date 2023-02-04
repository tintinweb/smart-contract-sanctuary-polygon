/**
 *Submitted for verification at polygonscan.com on 2023-02-04
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

/**
  * @title Dint Distributor version 1.0
  *
  * @author DintApp
  */
contract DintDistributor is Ownable {
    /// @dev Address of dint token ERC20 smart contract
    address public immutable dintToken;

    /// @dev Address of fee collection wallet
    address public feeCollector;

    /// @dev Holds user info of user address
    struct UserInfo {
      bool isRegistered;
      bool isManaged;
      bool isReferrer;
      bool blockedReferrer;
      uint64 startedReferringAt;
      address tipReceiverToReferrer;
    }
    
    /// @dev A record of user info for given user address
    mapping(address => UserInfo) public user;
    
    /// @dev A record of reward sent status for given post id
    mapping(uint256 => bool) public isRewardSent;

    /// @dev Fired in sendDint() function when sender sent tip to receiver
    event tipSent(address _sender, address _recipient, uint256 _amount);

    /// @dev Fired in reward() function when reward sent to receiver for given post id
    event rewardSent(address indexed _recipient, uint256 _amount, uint256 _id);

    /**
	    * @dev Creates / deploys Dint Distributor version 1.0
	    *
	    * @param _dintToken address of dint token ERC20 smart contract
	    */
    constructor(address _dintToken) {
      require(_dintToken != address(0), "Invalid address");
      feeCollector = _msgSender();
      dintToken = _dintToken;
    }

    /**
	    * @dev Registers user into dintApp
	    *
      * @notice Restricted access function, should be called by owner only
      * 
      * @param _user address to register
	    * @param _referrer address of referrer to be registered for given user
      * @param _isManaged whether user is managed or not
	    */
    function register(
      address _user,
      address _referrer,
      bool _isManaged
    ) external onlyOwner {
      require(!user[_user].isRegistered, "User already registered");
      require(user[_referrer].isReferrer || _referrer == address(0), "Unknown referrer");
      user[_user].isRegistered = true;
      user[_user].tipReceiverToReferrer = _referrer;
      user[_user].isManaged = _isManaged;
    }

    /**
	    * @dev Allows to change referrer status if tx sender is not blocked by owner
	    *
      * @param _isReferrer whether address is referrer or not
	    */
    function changeReferrerState(bool _isReferrer) external {
      require(user[_msgSender()].isReferrer != _isReferrer, "Value updated to same");
      require(!user[_msgSender()].blockedReferrer, "Please refer to admin");
      user[_msgSender()].isReferrer = _isReferrer;
      if (_isReferrer && user[_msgSender()].startedReferringAt == 0) {
        user[_msgSender()].startedReferringAt = uint64(block.timestamp);
      }
    }

    /**
	    * @dev Allows to block / unblock given referrer address
	    *
      * @notice Restricted access function, should be called by owner only
      * 
      * @param _referrer address of referrer to be blocked / unblocked
      * @param _blocked whether user is blocked or unblocked
	    */
    function blockUnblockReferrer(address _referrer, bool _blocked) external onlyOwner {
      user[_referrer].blockedReferrer = _blocked;
      if (_blocked) {
        user[_referrer].isReferrer = false;
      }
    }

    /**
	    * @dev Sets fee collector address
	    *
      * @notice Restricted access function, should be called by owner only
      * 
      * @param _feeCollector address of fee collector wallet
      */
    function setFeeCollector(address _feeCollector) external onlyOwner {
      require(_feeCollector != feeCollector, "Value updated to same");
      feeCollector = _feeCollector;
    }

    /**
	    * @dev Changes managed state of given user
	    *
      * @notice Restricted access function, should be called by owner only
      * 
      * @param _user address of user to be managed / unmanaged
      * @param _isManaged whether user is managed or not
	    */
    function changeManagedState(address _user, bool _isManaged) external onlyOwner {
      require(user[_user].isManaged != _isManaged, "Value updated to same");
      user[_user].isManaged = _isManaged;
    }

    /**
	    * @dev Unregisters user from dintApp
	    *
      * @notice Restricted access function, should be called by owner only
      * 
      * @param _user address of user to be unregistered
      */
    function unRegister(address _user) external onlyOwner {
      require(user[_user].isRegistered, "User not registered");
      user[_user].isRegistered = false;
      user[_user].tipReceiverToReferrer = address(0);
      user[_user].isManaged = false;
    }
    
    /**
	    * @dev Returns validation status of given referrer
	    *
      * @param _referrer address of referrer
      */
    function isValidReffrer(address _referrer) internal view returns(bool) {
      return user[_referrer].isReferrer;
    }

    /**
	    * @dev Sends tip to given user
	    *
      * @param _sender address of tip sender
      * @param _recipient address of user / tip receiver 
      * @param _amount dint token amount to be sent as tip
	    */
    function sendDint(address _sender, address _recipient, uint256 _amount) external onlyOwner {
      require(user[_sender].isRegistered, "sender not registered");
      require(user[_recipient].isRegistered, "recipient not registered");
      require(_amount != 0, "Zero amount error");

      address[4] memory referrer;
      uint16[4] memory forReferral;
      uint16 forDintApp = 2000;
      uint16 forUser = 8000;
      uint8 count;

      if(isValidReffrer(user[_recipient].tipReceiverToReferrer)) {
        referrer[0] = user[_recipient].tipReceiverToReferrer;
        forReferral[0] = 400;
        forDintApp -= 400;
        count++;
            
        if(isValidReffrer(user[referrer[0]].tipReceiverToReferrer)) {
          referrer[1] = user[referrer[0]].tipReceiverToReferrer;
          forReferral[1] = 200;
          forDintApp -= 200;
          count++;

          if(isValidReffrer(user[referrer[1]].tipReceiverToReferrer)) {
            referrer[2] = user[referrer[1]].tipReceiverToReferrer;
            forReferral[2] = 100;
            forDintApp -= 100;
            count++;
                
            if(isValidReffrer(user[referrer[2]].tipReceiverToReferrer)) {
              referrer[3] = user[referrer[2]].tipReceiverToReferrer;
              forReferral[3] = 100;
              forDintApp -= 100;
              count++;
            }
          }
        }
      }  

      if(user[_recipient].isManaged) {
        forUser -= 1500;
        forDintApp += 1500;
      }

      IERC20(dintToken).transferFrom(_sender, _recipient, (_amount * forUser / 10000));
      IERC20(dintToken).transferFrom(_sender, feeCollector, (_amount * forDintApp / 10000));

      for(uint8 i; i < count; i++) {
        IERC20(dintToken).transferFrom(_sender, referrer[i], (_amount * forReferral[i] / 10000));
      }
      
      emit tipSent(_sender, _recipient, _amount);
    }

    /**
	    * @dev Sends rewards to given user
	    *
      * @notice Restricted access function, should be called by owner only
      *
      * @param _user address of user
      * @param _amount dint token amount to be sent as reward 
      * @param _postId id of post for which reward is sent
	    */
    function reward(address _user, uint256 _amount, uint256 _postId) external onlyOwner {
      require(user[_user].isRegistered, "User not registered");
      require(_amount != 0, "Zero amount error");
      require(!isRewardSent[_postId], "Reward already sent");
      
      IERC20(dintToken).transferFrom(feeCollector, _user, _amount);
      isRewardSent[_postId] = true;

      emit rewardSent(_user, _amount, _postId);
    }

    /**
	    * @dev Withdraws tokens from smart contract 
	    *
      * @notice Restricted access function, should be called by owner only
      *
      * @param _token address of token to be withdrawn from smart contract
      * @param _amount token amount to be withdrawn
      * @param _to address of receiver 
      */
    function withdrawToken(
      address _token,
      uint256 _amount,
      address _to
    ) external onlyOwner {
      IERC20(_token).transfer(_to, _amount);
    }
}