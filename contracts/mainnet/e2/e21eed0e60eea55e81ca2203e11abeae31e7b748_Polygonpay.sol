/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol

pragma solidity ^0.6.11;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.6.11;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.6.11;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}


contract Polygonpay is Initializable, OwnableUpgradeable {
  using SafeMath for uint256;
  event regLevelEvent(
      address indexed _user,
      address indexed _referrer,
      uint256 _time
  );
  event buyLevelEvent(address indexed _user, uint256 _level, uint256 _time);

  mapping(uint256 => uint256) public LEVEL_PRICE;
  uint256 REFERRER_1_LEVEL_LIMIT;

  uint256 directpercentage;
  uint256 indirectpercentage;

  struct UserStruct {
      bool isExist;
      uint256 id;
      uint256 referrerID;
      uint256 currentLevel;
      uint256 earnedAmount;
      uint256 totalearnedAmount;
      address[] referral;
      address[] allDirect;
      uint256 childCount;
      uint256 upgradeAmount;
      uint256 upgradePending;
      mapping(uint256 => uint256) levelEarningmissed;
  }

  mapping(address => UserStruct) public users;

  mapping(uint256 => address) public userList;

  uint256 public currUserID;
  uint256 public totalUsers;
  address public ownerWallet;
  uint256 public adminFee;
  address[] public joinedAddress;
  mapping(address => uint256) public userJoinTimestamps;
  uint256 public totalProfit;
  uint256 public minwithdraw;
  Polygonpay public oldPolygonPay;
  uint256 public totalDays;

    uint256 public initialRoi;
    uint256 public allRoi;
    uint256 public roiLaunchTime;
    mapping(address => uint256) public userUpgradetime;
    mapping(address => uint256) public roiEndTime;

    function initialize(address _ownerAddress) public initializer {
        __Ownable_init();
        ownerWallet = _ownerAddress;
        REFERRER_1_LEVEL_LIMIT = 3;
        currUserID = 1;
        totalUsers = 1;
        directpercentage = 2000; //20%
        indirectpercentage = 1200; //12%
        adminFee = 10 * 1e18; // 10Matic
        minwithdraw = 5 * 1e18; // 5 Matic

        LEVEL_PRICE[1] = 10 * 1e18; // 10Matic
        LEVEL_PRICE[2] = 30 * 1e18;
        LEVEL_PRICE[3] = 90 * 1e18;
        LEVEL_PRICE[4] = 1000 * 1e18;
        LEVEL_PRICE[5] = 3000 * 1e18;
        LEVEL_PRICE[6] = 9000 * 1e18;
        LEVEL_PRICE[7] = 25000 * 1e18;
        LEVEL_PRICE[8] = 75000 * 1e18;

        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            currentLevel: 8,
            earnedAmount: 0,
            totalearnedAmount: 0,
            referral: new address[](0),
            allDirect : new address[](0),
            childCount: 0,
            upgradeAmount:0,
            upgradePending : 0
        });

        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        userList[currUserID] = ownerWallet;
        oldPolygonPay = Polygonpay(0x6b2E8542a54F590c1444240159aF08FD6225841f);
    }

    function regUser(address _referrer) public payable {
       require(!users[msg.sender].isExist, "User exist");
       require(users[_referrer].isExist, "Invalid referal");

       uint256 _referrerID = users[_referrer].id;

       require(msg.value == LEVEL_PRICE[1] * 3, "Incorrect Value");

       if (
           users[userList[_referrerID]].referral.length >=
           REFERRER_1_LEVEL_LIMIT
       ) {
           _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
       }

       UserStruct memory userStruct;
       currUserID++;
       totalUsers++;

       userStruct = UserStruct({
           isExist: true,
           id: currUserID,
           referrerID: _referrerID,
           earnedAmount: 0,
           totalearnedAmount: 0,
           referral: new address[](0),
           allDirect: new address[](0),
           currentLevel: 1,
           childCount: 0,
           upgradeAmount : 0,
           upgradePending : 0
       });

       users[msg.sender] = userStruct;
       users[msg.sender].levelEarningmissed[2] = 0;
       users[msg.sender].levelEarningmissed[3] = 0;
       users[msg.sender].levelEarningmissed[4] = 0;
       users[msg.sender].levelEarningmissed[5] = 0;
       users[msg.sender].levelEarningmissed[6] = 0;
       users[msg.sender].levelEarningmissed[7] = 0;
       users[msg.sender].levelEarningmissed[8] = 0;
       userList[currUserID] = msg.sender;
       users[userList[_referrerID]].referral.push(msg.sender);
       joinedAddress.push(msg.sender);
       users[_referrer].allDirect.push(msg.sender);
       users[_referrer].childCount = users[_referrer].childCount.add(1);
       payReferal(_referrer);
       payForLevel(1,msg.sender);
       userJoinTimestamps[msg.sender] = block.timestamp;
       userUpgradetime[msg.sender] = block.timestamp;
       roiEndTime[msg.sender] = block.timestamp + 100 days;
       emit regLevelEvent(msg.sender, userList[_referrerID], now);
   }


   function payReferal(address _referrer) internal {
       uint256 indirectRefId = users[_referrer].referrerID;
       address indirectRefAddr = userList[indirectRefId];
       if (indirectRefAddr == 0x0000000000000000000000000000000000000000) {
           indirectRefAddr = ownerWallet;
       }
       uint256 levelPrice = LEVEL_PRICE[1] * 3;
       uint256 directAmount = (levelPrice* directpercentage) / 10000;
       uint256 indirectAmount = (levelPrice * indirectpercentage) / 10000;
       payable(ownerWallet).transfer(adminFee);
       users[ownerWallet].totalearnedAmount += adminFee;

       if(users[_referrer].currentLevel < 8){
         users[_referrer].upgradeAmount += directAmount/2;
         users[_referrer].earnedAmount += directAmount/2;
       }else{
         users[_referrer].earnedAmount += directAmount;
       }
       totalProfit +=directAmount;

       if(users[indirectRefAddr].currentLevel < 8){
         users[indirectRefAddr].upgradeAmount += indirectAmount/2;
         users[indirectRefAddr].earnedAmount += indirectAmount/2;
       }else{
         users[indirectRefAddr].earnedAmount += indirectAmount;
       }

       totalProfit +=indirectAmount;

   }

      function payForLevel(uint256 _level, address _user) internal {
          address referer;
          address referer1;
          address referer2;
          address referer3;
          if (_level == 1 || _level == 5) {
              referer = userList[users[_user].referrerID];
          } else if (_level == 2 || _level == 6) {
              referer1 = userList[users[_user].referrerID];
              referer = userList[users[referer1].referrerID];
          } else if (_level == 3 || _level == 7) {
              referer1 = userList[users[_user].referrerID];
              referer2 = userList[users[referer1].referrerID];
              referer = userList[users[referer2].referrerID];
          } else if (_level == 4 || _level == 8) {
              referer1 = userList[users[_user].referrerID];
              referer2 = userList[users[referer1].referrerID];
              referer3 = userList[users[referer2].referrerID];
              referer = userList[users[referer3].referrerID];
          }
          uint256 upgradedAmount = 0;
          if(users[msg.sender].upgradePending >= LEVEL_PRICE[_level]){
              users[msg.sender].currentLevel =  _level;
              uint256 oldupgrade = users[msg.sender].upgradePending - users[msg.sender].upgradeAmount;
              users[msg.sender].upgradeAmount = users[msg.sender].upgradePending - LEVEL_PRICE[_level];
              users[msg.sender].upgradePending = 0;
              upgradedAmount = LEVEL_PRICE[_level] - oldupgrade;

              //update old Roi into earning
               uint256 _checkRoiupto = checkRoiUpto(msg.sender);
               users[msg.sender].earnedAmount +=  _checkRoiupto;
               userUpgradetime[_user] = block.timestamp;
               totalProfit += _checkRoiupto;

          }else{
            upgradedAmount = users[msg.sender].upgradeAmount;
            users[msg.sender].upgradeAmount = 0;
          }

          if (users[_user].levelEarningmissed[_level] > 0 && users[msg.sender].currentLevel >= _level) {
              users[_user].earnedAmount += users[_user].levelEarningmissed[_level]/2;
              users[_user].upgradeAmount += users[_user].levelEarningmissed[_level]/2;
              users[_user].levelEarningmissed[_level] = 0;
              totalProfit += users[_user].levelEarningmissed[_level];
          }

          bool isSend = true;
          if (!users[referer].isExist) {
              isSend = false;
          }
          if (isSend) {
              if (users[referer].currentLevel >= _level) {
                  if(users[referer].currentLevel < 8){
                    if(_level == 1){
                      users[referer].upgradeAmount += LEVEL_PRICE[_level];
                      totalProfit += LEVEL_PRICE[_level];
                    }else{
                      users[referer].upgradeAmount += upgradedAmount/2;
                      users[referer].earnedAmount += upgradedAmount/2;
                      totalProfit += upgradedAmount;
                    }
                  }else{
                    uint256 missedAmount = (_level == 1) ? LEVEL_PRICE[_level] : upgradedAmount;
                    users[referer].earnedAmount += missedAmount;
                    totalProfit += missedAmount;
                  }
              } else {
                  users[referer].levelEarningmissed[_level] += upgradedAmount;
              }
          }else{
              uint256 missedAmount = (_level == 1) ? LEVEL_PRICE[_level] : upgradedAmount;
              users[ownerWallet].earnedAmount += missedAmount;
          }
      }

      function upgradeNextLevel() public {
        require(users[msg.sender].upgradeAmount >= 0,"Insufficient amount");
        uint256 currentLevel = users[msg.sender].currentLevel;
        uint256 nextLevel = currentLevel+1;
        if(nextLevel <= 8){
          users[msg.sender].upgradePending += users[msg.sender].upgradeAmount;
          payForLevel(nextLevel, msg.sender);
        }
      }

      function claimRewards() public {
          uint256 _checkRoiupto = checkRoiUpto(msg.sender);
          users[msg.sender].earnedAmount += _checkRoiupto;
          totalProfit += _checkRoiupto;
          userUpgradetime[msg.sender] = block.timestamp;
          uint256 claimAmount = users[msg.sender].earnedAmount;
          if (claimAmount > 0) {
              require(users[msg.sender].upgradeAmount == 0 || users[msg.sender].currentLevel >= 8,"Upgrade first then process claim");
              require(claimAmount >= minwithdraw,"Minimum 5 Matic");
              payable(msg.sender).transfer(claimAmount);
              users[msg.sender].totalearnedAmount += claimAmount;
              users[msg.sender].earnedAmount = 0;
          }
      }

      function findFreeReferrer(address _user) public view returns (address) {
          if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
              return _user;
          }
          address[] memory referrals = new address[](600);
          referrals[0] = users[_user].referral[0];
          referrals[1] = users[_user].referral[1];
          referrals[2] = users[_user].referral[2];
          address freeReferrer;
          bool noFreeReferrer = true;

          for (uint256 i = 0; i < 600; i++) {
              if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                  if (i < 120) {
                      referrals[(i + 1) * 3] = users[referrals[i]].referral[0];
                      referrals[(i + 1) * 3 + 1] = users[referrals[i]].referral[
                          1
                      ];
                      referrals[(i + 1) * 3 + 2] = users[referrals[i]].referral[
                          2
                      ];
                  }
              } else {
                  noFreeReferrer = false;
                  freeReferrer = referrals[i];
                  break;
              }
          }
          require(!noFreeReferrer, "No Free Referrer");
          return freeReferrer;
      }

      function viewUserReferral(
          address _user
      ) public view returns (address[] memory) {
          return users[_user].referral;
      }

      function getmissedvalue(address _userAddress, uint256 _level)
      public
      view
      returns(uint256)
      {
          return users[_userAddress].levelEarningmissed[_level];
      }

      function viewallDirectUserReferral(
          address _user
      ) public view returns (address[] memory) {
          return users[_user].allDirect;
      }

      function getUsersJoinedLast24Hours() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < totalUsers; i++) {
            address userAddress = userList[i];
            if (userJoinTimestamps[userAddress] != 0 && block.timestamp - userJoinTimestamps[userAddress] <= 86400) {
                count++;
            }
        }
        return count;
      }

      fallback() external payable {}

    function checkTime(address _user) public view returns(uint256){
      uint256 startTime = userUpgradetime[_user];
      if(userUpgradetime[_user] == 0){
        startTime = roiLaunchTime;
      }
      uint diff = 0;
      if(block.timestamp <= roiEndTime[_user]){
        uint256 startDate = startTime;
        uint256 endDate = block.timestamp;
        diff = (endDate - startDate) / 60 / 6;
      }else{
        if(roiEndTime[_user] > startTime){
          uint256 startDate = startTime;
          uint256 endDate = roiEndTime[_user];
          diff = (endDate - startDate) / 60 / 6;
        }
      }
        return diff;
    }

    function checkRoiUpto(address _user) public view returns(uint256){
        uint256 startTime = userUpgradetime[_user];
        if(userUpgradetime[_user] == 0){
          startTime = roiLaunchTime;
        }
        uint256 dailyroi = 0;
        uint diff = 0;
        if(block.timestamp <= roiEndTime[_user]){
          uint256 startDate = startTime;
          uint256 endDate = block.timestamp;
          diff = (endDate - startDate) / 60 / 60 / 24;
        }else{
          if(roiEndTime[_user] > startTime){
            uint256 startDate = startTime;
            uint256 endDate = roiEndTime[_user];
            diff = (endDate - startDate) / 60 / 60 / 24;
          }
        }
          // check user level

           if(users[_user].currentLevel == 1){
              dailyroi = (LEVEL_PRICE[2] * initialRoi)/100;
           }else{
             uint256 useramount = 0;
             if(users[_user].currentLevel > 1 && users[_user].currentLevel <=4){
               useramount = LEVEL_PRICE[users[_user].currentLevel];
             }else{
               useramount = LEVEL_PRICE[4];
             }
             dailyroi = (useramount * allRoi)/100;
           }
          uint256 uptoroi = diff.mul(dailyroi).div(1000);
          return uptoroi;
        }

        function roiInitiate() public onlyOwner {
          initialRoi = 1500;
          allRoi = 2000;
          roiLaunchTime = block.timestamp + 900;
        }

}