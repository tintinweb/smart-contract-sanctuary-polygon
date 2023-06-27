/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIXED








pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}







pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
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
}







pragma solidity ^0.8.1;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                
                
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        
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







pragma solidity ^0.8.2;


abstract contract Initializable {
    
    uint8 private _initialized;

    
    bool private _initializing;

    
    event Initialized(uint8 version);

    
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}







pragma solidity ^0.8.0;


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}







pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}







pragma solidity ^0.8.0;




contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
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

    
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            
            
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            
            _balances[account] += amount;
        }
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
            
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}





pragma solidity ^0.8.0;


contract DodoCoin is ERC20 {

  constructor(address initialAccount, uint256 _initialSupply) ERC20("DodoCoin", "DDC") {
    uint256 initialSupply = _initialSupply * (10**decimals());
    _mint(initialAccount, initialSupply);
  }

}





pragma solidity >=0.4.22 <0.9.0;

struct PlayerData {
    uint256 dataVersion; 
    uint256 gameTimes; 
    uint256 casinoTimes; 
    uint256 incomeLevel; 
    uint256 bonusLevel; 
    uint256 bonus; 
}

struct PlayerStorage {
    PlayerData data;
    mapping (string => uint256) extraData;
}

interface DodoStorageInterface {

    function getPlayerExtraData(address player, string memory key) external view returns (uint256);

    function setPlayerExtraData(address player, string memory key, uint256 value) external;

    function getPlayerData(address player) external view returns (PlayerData memory);

    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) external;

    function transferCoin(address to, uint256 amount) external;

}





pragma solidity >=0.4.22 <0.9.0;





 contract DodoLogicV1 is Initializable {

  
  address private dataContract; 
  address private tokenContract; 
  address private owner; 

  
  uint256 public fee; 
  uint256 public incomeBase; 

  
  event makeMoneyEvent(address player, uint256 reward); 

  function initialize(address _dataContract, address _tokenContract, address _owner) public initializer {
    
    dataContract = _dataContract;
    
    tokenContract = _tokenContract;
    
    owner = _owner;
    
    fee = 0.0000001 ether; 
    
    incomeBase = 1 ether; 
  }

  function getDataContract() public view returns (address) {
    return dataContract;
  }

  function getTokenContract() public view returns (address) {
    return tokenContract;
  }

  
  function getCapital() public view returns (uint256) {
    return IERC20(tokenContract).balanceOf(dataContract);
  }

  
  function getPlayerData() public view returns (uint256, uint256, uint256, uint256, uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(msg.sender);
    return (playerData.gameTimes, playerData.casinoTimes, playerData.incomeLevel, playerData.bonusLevel, playerData.bonus);
  }

  
  function getGameTokenBalance() public view returns (uint256) {
    return IERC20(tokenContract).balanceOf(msg.sender);
  }

  
  function getIncome() public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(msg.sender);
    return incomeBase * (playerData.incomeLevel *10 + 100) / 100; 
  }

  
  function getBonus() public view returns (uint256) {
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(msg.sender);
    return incomeBase * (playerData.bonusLevel *10) / 100; 
  }

  
  function makeMoney() public payable {
    
    require(msg.value == fee, "MakeMoneyGameLogic: fee error");
    address player = msg.sender;
    
    PlayerData memory playerData = DodoStorageInterface(dataContract).getPlayerData(player);
    uint256 reward = getIncome();
    
    DodoStorageInterface(dataContract).transferCoin(player, reward);
    
    uint256 bonus = getBonus();
    DodoStorageInterface(dataContract).updatePlayerData(
      player,  
      playerData.dataVersion, 
      1, 
      0, 
      0, 
      0, 
      int256(bonus) 
    );
    
    emit makeMoneyEvent(player, reward);
    
    payable(owner).transfer(fee);
  }

 }





pragma solidity >=0.4.22 <0.9.0;




contract DodoStorage is Ownable, DodoStorageInterface {
  mapping(address => PlayerStorage) private playerStorage; 
  address public gameContract; 
  address public tokenContract; 

    
    modifier onlyGameContract() {
        require(
            msg.sender == gameContract,
            "MakeMoneyGameData: caller is not the game contract"
        );
        _;
    }

    
    function setGameContract(address _gameContract) public onlyOwner {
        gameContract = _gameContract;
    }

    
    function setTokenContract(address _tokenAddress) public onlyOwner {
        tokenContract = _tokenAddress;
    }

    
    function getPlayerData(address player) public view returns (PlayerData memory) {
        return playerStorage[player].data;
    }

    
    function updatePlayerData(
        address player,
        uint256 dataVersion,
        int256 gameTimesDelta,
        int256 casinoTimesDelta,
        int256 incomeLevelDelta,
        int256 bonusLevelDelta,
        int256 bonusDelta
    ) public onlyGameContract {
        PlayerData memory _data = playerStorage[player].data;
        require(_data.dataVersion == dataVersion, "MakeMoneyGameData: data version error"); 
        if(gameTimesDelta < 0) {
            playerStorage[player].data.gameTimes -= uint256(-gameTimesDelta);
        } else {
            playerStorage[player].data.gameTimes += uint256(gameTimesDelta);
        }
        if(casinoTimesDelta < 0) {
            playerStorage[player].data.casinoTimes -= uint256(-casinoTimesDelta);
        } else {
            playerStorage[player].data.casinoTimes += uint256(casinoTimesDelta);
        }
        if(incomeLevelDelta < 0) {
            playerStorage[player].data.incomeLevel -= uint256(-incomeLevelDelta);
        } else {
            playerStorage[player].data.incomeLevel += uint256(incomeLevelDelta);
        }
        if(bonusLevelDelta < 0) {
            playerStorage[player].data.bonusLevel -= uint256(-bonusLevelDelta);
        } else {
            playerStorage[player].data.bonusLevel += uint256(bonusLevelDelta);
        }
        if(bonusDelta < 0) {
            playerStorage[player].data.bonus -= uint256(-bonusDelta);
        } else {
            playerStorage[player].data.bonus += uint256(bonusDelta);
        }
        playerStorage[player].data.dataVersion += 1;
    }

    
    function getPlayerExtraData(address player, string memory key) public view returns (uint256) {
        return playerStorage[player].extraData[key];
    }

    
    function setPlayerExtraData(address player, string memory key, uint256 value) public onlyGameContract {
        playerStorage[player].extraData[key] = value;
    }

    
    function transferCoin(address to, uint256 amount) public onlyGameContract {
        IERC20(tokenContract).transfer(to, amount);
    }
}





pragma solidity ^0.8.9;




contract Lock {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        
        

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}