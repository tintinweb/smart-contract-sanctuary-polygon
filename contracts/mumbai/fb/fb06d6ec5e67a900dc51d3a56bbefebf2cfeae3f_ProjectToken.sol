/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;



library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }
    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
interface IERC20Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    struct lockupPlanInfo {
        uint32 lockupPlanIndex;
        uint128 lockupPlanAmount;
    }
    struct lockupInfo {
        uint8 lockupIndex;
        uint128 lockupAmount; 
        uint128 lockupPlanTotalAmount;
        uint128[] lockupPlanList;
        mapping(uint128 => lockupPlanInfo) _lockupPlan;
    }    
    struct lockInfo {
        bool whitelistWhether;
        uint32[] lockupList;
    }  
    mapping(address => mapping(uint32 => lockupInfo)) private _initialLock;
    mapping(address => lockInfo) private _lock;
    mapping(address => bool) private _freezingStatus;
    address[] _whitelist;
    event lock(address account,uint32 lockupTime,uint128 lockupAmount);
    event unlock(address account,uint32 lockupTime,uint128 releaseAmount);
    event freeze(address account);
    event unfreeze(address account);


    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    } 
    function _transfer(address from, address to, uint256 amount) FreezeStatus(from,to) internal virtual {
        if (_lock[from].lockupList.length != 0) {
            uint128 lockupAmount_Total;    
            uint128 unlockedAmount_Total; 
            for (uint8 i=0; i<_lock[from].lockupList.length;){ 
                uint32 i_initialLockTime = _lock[from].lockupList[i];
                uint128 i_lockupAmount = _initialLock[from][i_initialLockTime].lockupAmount;
                uint128 i_unlockedAmount ;   
                uint256 i_lockupPlanListLength = _initialLock[from][i_initialLockTime].lockupPlanList.length;
                unchecked { lockupAmount_Total += i_lockupAmount;}
                for (uint8 j=0; j< i_lockupPlanListLength;){
                    uint128 lockTime = _initialLock[from][i_initialLockTime].lockupPlanList[j];
                    if (lockTime < block.timestamp) {
                        unchecked { i_unlockedAmount += _initialLock[from][i_initialLockTime]._lockupPlan[lockTime].lockupPlanAmount;}
                    }
                    unchecked {j ++;}
                }
                if ((i_unlockedAmount == i_lockupAmount) || (i_lockupPlanListLength == 0 && i_initialLockTime < block.timestamp) ) {
                    emit unlock(from,i_initialLockTime,i_lockupAmount);
                    i_unlockedAmount = i_lockupAmount;
                    delete _lock[from].lockupList[i]; 
                    delete _initialLock[from][i_initialLockTime];
                }
                unchecked {unlockedAmount_Total += i_unlockedAmount;}
                unchecked {i ++;}
            }
            if (lockupAmount_Total == unlockedAmount_Total) {
                delete _lock[from].lockupList;
            }
            require(_balances[from]-(lockupAmount_Total-unlockedAmount_Total) >= amount,"Transferable amount exceeded");  
        }
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve( address owner, address spender, uint256 amount) FreezeStatus(owner,spender) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    /*==================================================================
                            화이트 리스트
    ==================================================================*/
    function whitelist() external view returns (address[] memory) {
        return _whitelist;
    }
    /*==================================================================
                                잠금 정보
    ==================================================================*/
    function lockup_info(address account) external view returns (uint32[] memory lockup_time) {
        lockup_time = _lock[account].lockupList;
    }  
    /*==================================================================
                                잠금플랜 정보
    ==================================================================*/ 
    function lockupPlan_info(address account, uint32 lockupTime) external view returns (uint128[] memory lockupPlan_time, uint128[] memory lockupPlan_amount, uint128 lockup_amount,uint128 lockupPlanTotal_amount, uint128 amount_available) {
        uint128[] memory TimeList = _initialLock[account][lockupTime].lockupPlanList;
        uint128[] memory AmountList = _initialLock[account][lockupTime].lockupPlanList;
        uint128 allowable; 
        for (uint8 i=0; i<TimeList.length;){
            uint128 Plan_amount = _initialLock[account][lockupTime]._lockupPlan[TimeList[i]].lockupPlanAmount;
            if (TimeList[i] < block.timestamp) {
                unchecked{ allowable += Plan_amount; }
            }
            AmountList[i] = Plan_amount;
            unchecked{ i++; }
        }
        lockupPlan_time = TimeList;
        lockupPlan_amount = AmountList;
        lockup_amount = _initialLock[account][lockupTime].lockupAmount;
        lockupPlanTotal_amount = _initialLock[account][lockupTime].lockupPlanTotalAmount;
        if (TimeList.length == 0 && lockupTime < block.timestamp) {
            allowable = lockup_amount;
        }
        amount_available = allowable;
    } 
    /*==================================================================
                            전송하고 잠금설정  
    ==================================================================*/
    function transferAndLockup(address to, uint32 lockupTime, uint128 lockupAmount) external returns (bool) { 
        _ProjectFunctions();
        require(_initialLock[to][lockupTime].lockupAmount == 0 && lockupTime > block.timestamp,"lockupTime is not correct");
        require(lockupAmount != 0,"Incorrect lockupAmount");
        if (!_lock[to].whitelistWhether){
            _lock[to].whitelistWhether = true;
            _whitelist.push(to);
        }
        _initialLock[to][lockupTime].lockupIndex = uint8(_lock[to].lockupList.length); 
        _lock[to].lockupList.push(lockupTime);
        _initialLock[to][lockupTime].lockupAmount = lockupAmount; 
        _transfer(_msgSender(), to, lockupAmount);
        emit lock(to,lockupTime,lockupAmount);
        return true;
    }  
    // /*==================================================================
    //                         잠금 삭제 
    // ==================================================================*/
    function lockupDelete(address account,uint32 lockupTime) external returns (bool) { 
        _ProjectFunctions();
        uint128 lockupAmount = _initialLock[account][lockupTime].lockupAmount;
        require(lockupAmount != 0,"Incorrect lockupTime");
        delete _lock[account].lockupList[_initialLock[account][lockupTime].lockupIndex];
        for (uint32 i=0; i<_initialLock[account][lockupTime].lockupPlanList.length;){
            delete _initialLock[account][lockupTime]._lockupPlan[_initialLock[account][lockupTime].lockupPlanList[i]];
            unchecked{ i++; }
        }
        delete _initialLock[account][lockupTime];
        emit unlock(account,lockupTime,lockupAmount);
        return true;
    }
    /*==================================================================
                            잠금플랜 설정
    ==================================================================*/ 
    function lockupPlanSet(address account, uint32 lockupTime, uint128[] calldata lockupPlanTime, uint128[] calldata lockupPlanAmount) external returns (bool) {
        _ProjectFunctions();
        uint128 lockTotalAmount = _initialLock[account][lockupTime].lockupPlanTotalAmount;
        uint128 lockup_Amount = _initialLock[account][lockupTime].lockupAmount;
        require(lockup_Amount != 0,"Incorrect lockupTime");
        require(lockupPlanTime.length == lockupPlanAmount.length ,"Incorrect lockupPair");
        if (lockupTime < block.timestamp){
            require(_initialLock[account][lockupTime].lockupPlanList.length != 0,"lockupTime over");
        }
        uint128 addAmount;
        for (uint32 i=0; i<lockupPlanTime.length;){
            uint128 i_lockupPlanAmount = lockupPlanAmount[i];
            require((_initialLock[account][lockupTime]._lockupPlan[lockupPlanTime[i]].lockupPlanAmount == 0) && (lockupPlanTime[i] >= lockupTime) && (lockupPlanTime[i] >= block.timestamp) ,"Incorrect lockupPlanTime");
            require(i_lockupPlanAmount != 0,"Incorrect lockupPlanAmount");
            unchecked{addAmount += i_lockupPlanAmount;}
            _initialLock[account][lockupTime]._lockupPlan[lockupPlanTime[i]] = lockupPlanInfo(uint32(_initialLock[account][lockupTime].lockupPlanList.length),i_lockupPlanAmount);
            _initialLock[account][lockupTime].lockupPlanList.push(lockupPlanTime[i]);
            unchecked{ i++; }
        }
        require(lockup_Amount >= lockTotalAmount+addAmount ,"lockupAmount exceeded");
        _initialLock[account][lockupTime].lockupPlanTotalAmount = lockTotalAmount+addAmount;
        return true;
    }
    /*==================================================================
                            잠금플랜 삭제 
    ==================================================================*/
    function lockupPlanDelete(address account,uint32 lockupTime,uint32 lockupPlanTime) external returns (bool) {
        _ProjectFunctions();
        uint128 addLockAmount = _initialLock[account][lockupTime]._lockupPlan[lockupPlanTime].lockupPlanAmount;
        require(addLockAmount != 0 && lockupPlanTime > block.timestamp,"Incorrect lockupPlanTime");
        _initialLock[account][lockupTime].lockupPlanTotalAmount = _initialLock[account][lockupTime].lockupPlanTotalAmount-addLockAmount;
        delete _initialLock[account][lockupTime].lockupPlanList[_initialLock[account][lockupTime]._lockupPlan[lockupPlanTime].lockupPlanIndex];
        delete _initialLock[account][lockupTime]._lockupPlan[lockupPlanTime];
        return true;
    }
    // /*==================================================================
    //                         지갑 동결 or 동결해제
    // ==================================================================*/
    function addressFreeze(address account) external { 
        _ProjectFunctions();
        require(!_freezingStatus[account], "already frozen");
        _freezingStatus[account] = true;
        emit freeze(account);
    }
    function addressUnfreeze(address account) external { 
        _ProjectFunctions();
        require(_freezingStatus[account], "already unfrozen");
        _freezingStatus[account] = false;
        emit unfreeze(account);
    }

    modifier FreezeStatus(address from,address to) {
        require(!_freezingStatus[from], "frozen from address");
        require(!_freezingStatus[to], "frozen to Address");
        _;
    }





    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from,address to, uint256 amount) internal virtual {}
    function _ProjectFunctions() internal virtual {}
    uint256[41] private __gap;
}
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }
    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }
    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }
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
    uint256[49] private __gap;
}
contract ProjectToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        _mint(msg.sender, 20000000000 * 10 ** decimals());
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
    function _ProjectFunctions() internal onlyOwner override {
        super._ProjectFunctions();
    }

}