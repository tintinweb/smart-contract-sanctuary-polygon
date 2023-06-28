/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

  
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    
    address private _owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function ownable_init(address __owner) internal {
        _owner = __owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function owner() public view returns(address) {
        return _owner;
    }
}

contract Initializable {

    bool private _initialized;

    bool private _initializing;

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

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract VolcanoMoney is Ownable, Initializable, Pausable {
    
    using SafeERC20 for IERC20;

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint coinwallet;
        uint directIncome;
        uint personalIncome;
        uint matrixIncome;
        mapping(uint8=>uint) holdAmount;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
    }
    
    uint8 public LAST_LEVEL;
    address public coinwallet;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    uint public lastUserId;
    
    mapping(uint8 => uint) public levelPrice;

    IERC20 public depositToken;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event UserIncome(address indexed sender, address indexed receiver , uint level ,uint amount , string incomeType);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller,  uint8 level);
    event ReinvestDeduction(address indexed user, address indexed currentReferrer, uint level, uint amount);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint level, uint place);

    function initialize(address _ownerAddress, IERC20 _depositToken, address _coinWallet) external initializer {

        LAST_LEVEL = 12;
        levelPrice[1] = 10e18;
        coinwallet = _coinWallet;
        for (uint8 i = 2; i <= 12; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }  

        users[_ownerAddress].id = 1;
        idToAddress[1] = _ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_ownerAddress].activeX6Levels[i] = true;
            emit Upgrade(_ownerAddress,address(0),i);
        }
        
        lastUserId = 2;
        ownable_init(_ownerAddress);
        depositToken = _depositToken;

        emit Registration(_ownerAddress, address(0), 1, 0);

    }
    
    function registrationExt(address referrerAddress) external whenNotPaused {
        registration(msg.sender, referrerAddress);
    }

    function registrationFor(address userAddress, address referrerAddress) external whenNotPaused {
        registration(userAddress, referrerAddress);
    }
    
    function buyNewLevel(uint8 level) external whenNotPaused {
        //require(depositToken.allowance(msg.sender,address(this))>=levelPrice[level],"ERC20: allowance exceed! ");
        //depositToken.transferFrom(msg.sender,address(this),levelPrice[level]);
      
        _buyNewLevel(msg.sender,  level);
        if(users[msg.sender].holdAmount[level-1] != 0) {
            users[msg.sender].personalIncome += users[msg.sender].holdAmount[level-1];
             //depositToken.transfer(msg.sender,users[msg.sender].holdAmount[level-1]);
            emit UserIncome(address(0), msg.sender, level-1 ,users[msg.sender].holdAmount[level-1] , "personalIncome");
            users[msg.sender].holdAmount[level-1] = 0;
        }
    }

    function buyNewLevelFor(address userAddress,  uint8 level) external whenNotPaused {
        _buyNewLevel(userAddress, level);
        if(users[userAddress].holdAmount[level-1] != 0) {
            users[userAddress].personalIncome += users[userAddress].holdAmount[level-1];
             //depositToken.transfer(userAddress,users[userAddress].holdAmount[level-1]);
            emit UserIncome(address(0), userAddress, level-1 ,users[userAddress].holdAmount[level-1] , "personalIncome");
            users[userAddress].holdAmount[level-1] = 0;
        }
    }

    function _buyNewLevel(address user, uint8 level) internal {
        require(isUserExists(user), "user is not exists. Register first.");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        require(users[user].activeX6Levels[level-1], "buy previous level first");
        require(!users[user].activeX6Levels[level], "level already activated"); 

        if (users[user].x6Matrix[level-1].blocked) {
            users[user].x6Matrix[level-1].blocked = false;
        }

        users[user].coinwallet += levelPrice[level]*10/100;
        //depositToken.transfer(coinwallet,levelPrice[level]*10/100);
        emit UserIncome(address(0) , user , 0 ,levelPrice[level]*10/100, "coin Wallet");

        address freeX6Referrer = findFreeX6Referrer(user, level);
        users[freeX6Referrer].directIncome += levelPrice[level]*30/100;
        //depositToken.safeTransfer( freeX6Referrer, levelPrice[level]*30/100);
        emit UserIncome(user ,freeX6Referrer , 0 ,levelPrice[level]*30/100,"PersonalIntroducer");
        
        users[user].activeX6Levels[level] = true;
        updateX6Referrer(user, freeX6Referrer, level);
        
        emit Upgrade(user, freeX6Referrer,  level);
        
    }    
    
    function registration(address userAddress, address referrerAddress) private {
         //require(depositToken.allowance(msg.sender,address(this))>=levelPrice[1],"ERC20: allowance exceed! ");
          //depositToken.safeTransferFrom(msg.sender, address(this), levelPrice[1]);

        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        idToAddress[lastUserId] = userAddress;
    
        users[userAddress].activeX6Levels[1] = true;
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        emit UserIncome(address(0) , userAddress , 0 ,levelPrice[1]*10/100, "coin Wallet");
        users[userAddress].coinwallet += levelPrice[1]*10/100;
        //depositToken.safeTransfer(coinwallet,levelPrice[1]*10/100);
        // sending direct income
        
        users[referrerAddress].directIncome += levelPrice[1]*30/100;
         //depositToken.safeTransfer( referrerAddress, levelPrice[1]*30/100);
        emit UserIncome(userAddress , referrerAddress , 0 ,levelPrice[1]*30/100, "PersonalIntroducer");
       
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
         emit Upgrade(userAddress,  findFreeX6Referrer(userAddress, 1),  1);
        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
       
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            if(users[referrerAddress].activeX6Levels[level+1]){
                users[referrerAddress].personalIncome += levelPrice[level]*1332/10000;
                 //depositToken.safeTransfer( referrerAddress, levelPrice[level]*1332/10000);
                emit UserIncome( userAddress, referrerAddress ,  level , levelPrice[level]*1332/10000 , "personalIncome");
            }else{
                users[referrerAddress].holdAmount[level]+= levelPrice[level]*1332/10000;
            }
            emit ReinvestDeduction(userAddress,referrerAddress,  level,  levelPrice[level]*1668/10000 );
            emit NewUserPlace(userAddress, referrerAddress, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            autoUpgrade(referrerAddress,  level , level+1); 
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner()) {
                // return sendETHDividends(referrerAddress, userAddress, 2, level);
                return;
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;  
           if(users[ref].activeX6Levels[level+1]) {
                users[ref].personalIncome += levelPrice[level]*1332/10000;
                 //depositToken.safeTransfer( ref, levelPrice[level]*1332/10000);
                emit UserIncome( userAddress, ref ,  level , levelPrice[level]*1332/10000 , "personalIncome");
            } else {
                users[ref].holdAmount[level]+= levelPrice[level]*1332/10000;
            }       
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            autoUpgrade(ref,  level , level+1);

            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref,  level, 5);
                } else {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref, level, 3);
                } else {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref,  level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref,  level, 5);
                } else {
                    emit ReinvestDeduction(userAddress,ref,  level,  levelPrice[level]*1668/10000 );
                    emit NewUserPlace(userAddress, ref,  level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        if(users[referrerAddress].activeX6Levels[level+1]) {
            users[referrerAddress].personalIncome += levelPrice[level]*1332/10000;
             //depositToken.safeTransfer( referrerAddress,  levelPrice[level]*1332/10000);
            emit UserIncome( userAddress, referrerAddress ,  level , levelPrice[level]*1332/10000 , "personalIncome");
        } else {
            users[referrerAddress].holdAmount[level]+= levelPrice[level]*1332/10000;
        }
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);
        autoUpgrade(referrerAddress,  level , level+1);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length < 2) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);

    }

    function autoUpgrade(address _user, uint8 _currentLevel , uint8 _nextLevel) internal {
        if(users[_user].holdAmount[_currentLevel]>=levelPrice[_nextLevel]){
            _buyNewLevel(_user,_nextLevel);
            users[_user].holdAmount[_currentLevel]-=levelPrice[_nextLevel];
            users[_user].personalIncome+=users[_user].holdAmount[_currentLevel];
             //depositToken.transfer(_user,users[_user].holdAmount[_currentLevel]);
            emit UserIncome(address(0), _user , _currentLevel ,users[_user].holdAmount[_currentLevel], "personalIncome");
            users[_user].holdAmount[_currentLevel] = 0;                   
        } 
    }

    function withdrawHolding(address _user,uint8 _level) external {
        if(users[_user].holdAmount[_level]>0) {
            users[_user].personalIncome+=users[_user].holdAmount[_level];
            //depositToken.transfer(_user,users[_user].holdAmount[_level]-((users[_user].holdAmount[_level]*2492)/10000));
            //depositToken.transfer(owner(),((users[_user].holdAmount[_level]*2492)/10000));
            emit UserIncome(address(0), _user ,  _level ,users[_user].holdAmount[_level], "personalIncome");
            users[_user].holdAmount[_level] = 0;
        }

    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            if(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].activeX6Levels[level+1]) {
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].personalIncome += levelPrice[level]*1332/10000;
                 //depositToken.safeTransfer( users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] , levelPrice[level]*1332/10000);
                emit UserIncome( userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ,  level , levelPrice[level]*1332/10000 , "personalIncome");
            } else {
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].holdAmount[level]+= levelPrice[level]*1332/10000;
            }
            emit ReinvestDeduction(userAddress,users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],  level,  levelPrice[level]*1668/10000 );
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit ReinvestDeduction(userAddress,referrerAddress,  level,  levelPrice[level]*1668/10000 );
            emit NewUserPlace(userAddress, referrerAddress,  level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
            autoUpgrade(users[referrerAddress].x6Matrix[level].firstLevelReferrals[0],  level , level+1); 
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            if(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].activeX6Levels[level+1]) {
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].personalIncome += levelPrice[level]*1332/10000;
                 //depositToken.safeTransfer( users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], levelPrice[level]*1332/10000);
                emit UserIncome( userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] ,  level , levelPrice[level]*1332/10000 , "personalIncome");
            } else {
                users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].holdAmount[level]+= levelPrice[level]*1332/10000;
            }
            // users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].holdAmount[level]+= levelPrice[level]*1332/10000;
            emit ReinvestDeduction(userAddress,users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],  level,  levelPrice[level]*1668/10000 );
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],  level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit ReinvestDeduction(userAddress,referrerAddress,  level,  levelPrice[level]*1668/10000 );
            emit NewUserPlace(userAddress, referrerAddress,  level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
            autoUpgrade(users[referrerAddress].x6Matrix[level].firstLevelReferrals[1],  level , level+1); 
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            // return sendETHDividends(referrerAddress, userAddress, 2, level);
            return;
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].coinwallet += levelPrice[level]*10/100;
        //depositToken.safeTransfer(coinwallet, (levelPrice[level]*10/100));
        emit UserIncome(address(0) , userAddress , 0 ,levelPrice[level]*10/100, "coin Wallet");
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner()) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner(), address(0), userAddress, level);
            // sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function userX6HoldAmount(address userAddress , uint8 level) public view returns (uint) {
        return users[userAddress].holdAmount[level];
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, uint, address) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount,
                users[userAddress].x6Matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }


    function withdrawToken(address _token,uint amount) external onlyOwner {
        IERC20(_token).transfer(owner(),amount);
    }

    function withdraw(uint amount) external onlyOwner {
       payable(owner()).transfer(amount);
    }
}