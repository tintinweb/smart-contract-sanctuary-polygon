// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./EcowattToken.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");
        
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
    
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IStakingToken {
    function setStartTime(uint startTime) external returns (bool);

    function setStakingPercent(uint typeStake, uint256 newPercent) external returns (bool);

    function setMaxAmountForStaking(uint typeStake, uint256 newMaxAmount) external returns (bool);

    function setMinAmountForStaking(uint typeStake, uint256 newMinAmount) external returns (bool);

    function isStakeholder(address account, uint typeStake) external view returns (bool);

    function getAmountOfStake(address account, uint typeStake) external view returns (uint256);

    function getEndTime(address account, uint typeStake) external view returns (uint);

    function createStake(uint256 stake, uint typeStake) external returns (bool);

    function isItRewardTime(address account, uint typeStake) external view returns (bool);

    function calculateReward(address account, uint typeStake) external view returns(uint256, uint256);

    function getReward(uint typeStake) external returns (bool);
    
    event OnStake(address indexed sender, uint typeStake, uint256 amount, uint endTime);

    event OnReward(address indexed sender, uint typeStake, uint256 tokens, uint256 reward);
}

contract StakingToken is ERC20('Ecowatt Carbon Token', 'EWCT', 8), Initializable, Ownable, IStakingToken {
    using SafeMath for uint256;

    ST_Mintable_Burnable_Token private ecowattToken;
    address public ecowattTokenAddress;

    struct StakingUserData {  
        uint256 amountForStakes;
        uint    endStakeTime;
        bool    exist;
    }

    mapping(address => StakingUserData) public stake90DaysHolders;
    mapping(address => StakingUserData) public stake180DaysHolders;
    mapping(address => StakingUserData) public stake360DaysHolders;

    mapping(uint => uint256) public percentStaking;
    mapping(uint => uint256) public maxAmountForStaking;
    mapping(uint => uint256) public minAmountForStaking;
    
    uint public startTime;
    
    enum StackingStatus { On, Off }
    StackingStatus public stackingStatus;

    modifier whenStakingActive {
        require(startTime != 0 && block.timestamp > startTime, "whenStakingActive: Staking not yet started.");
        require(stackingStatus == StackingStatus.On, "whenStakingActive: Staking is now stopped.");
        _;
    }
    
    function initialize(address _ecowattTokenAddress, uint256 amount) public initializer onlyOwner {
        require (_ecowattTokenAddress != address (0), "initialize: ecowattToken is the addres of 0");
        require(amount >= 0, "initialize: amount must be greater than or equal to 0");

        ecowattToken = ST_Mintable_Burnable_Token(_ecowattTokenAddress);
        ecowattTokenAddress = _ecowattTokenAddress;

        _mint(msg.sender, amount * 10 ** decimals());

        _setStakingPercentRate();
    }

    function setStackingStatus() public onlyOwner returns(StackingStatus) {
        if (stackingStatus == StackingStatus.On) {
            stackingStatus = StackingStatus.Off;
            return stackingStatus;
        } else {
            stackingStatus = StackingStatus.On;
            return stackingStatus;
        }
    }
    
    function setStartTime(uint _startTime) override public onlyOwner returns (bool) {
        require(_startTime != 0 && _startTime > block.timestamp, "setStartTime: Staking not yet started.");
        startTime = _startTime;
        return true;
    }

    function _setStakingPercentRate() private {        
        percentStaking[90] = 20; // 20 %
        maxAmountForStaking[90] = 2**256 - 1; // infinity Ecowatt
        minAmountForStaking[90] = 100 * 10 ** ecowattToken.decimals(); // 100 Ecowatt
        
        percentStaking[180] = 45; // 45 %
        maxAmountForStaking[180] = 2**256 - 1; // infinity Ecowatt
        minAmountForStaking[180] = 100 * 10 ** ecowattToken.decimals(); // 100 Ecowatt
        
        percentStaking[360] = 100; // 100 %
        maxAmountForStaking[360] = 2**256 - 1; // infinity Ecowatt
        minAmountForStaking[360] = 100 * 10 ** ecowattToken.decimals(); // 100 Ecowatt
    }

    function setStakingPercent(uint typeStake, uint256 newPercent) override public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setStakingPercent: The staking type must be 90, 180 or 360 days");
        require(newPercent > 0, "setStakingPercent: newPercent must be greater than than 0");
        percentStaking[typeStake] = newPercent;
        return true;
    }

    function setMaxAmountForStaking(uint typeStake, uint256 newMaxAmount) override public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setMaxAmountForStaking: The staking type must be 90, 180 or 360 days");
        require(newMaxAmount >= 100, "setMaxAmountForStaking: newMaxAmount must be greater than than 100");
        maxAmountForStaking[typeStake] = newMaxAmount;
        return true;
    }

    function setMinAmountForStaking(uint typeStake, uint256 newMinAmount) override public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setMinAmountForStaking: The staking type must be 90, 180 or 360 days");
        require(newMinAmount >= 100, "setMinAmountForStaking: newMinAmount must be greater than than 100");
        minAmountForStaking[typeStake] = newMinAmount;
        return true;
    }

    function isStakeholder(address account, uint typeStake) override public view returns (bool) {
        require(account != address(0), "isStakeHolder: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "isStakeHolder: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].exist;
        }
        if (typeStake == 180) {
            return stake180DaysHolders[account].exist;
        }
        if (typeStake == 360) {
            return stake360DaysHolders[account].exist;
        }

        return false;
    }

    function _addStakeholder(address account, uint typeStake, uint256 amount, uint endTime) private {
        require(account != address(0), "_addStakeholder: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "_addStakeholder: The staking type must be 90, 180 or 360 days");
        
        bool stakeholderExists = isStakeholder(account, typeStake);
        
        if (!stakeholderExists) {
            if (typeStake == 90) {
                stake90DaysHolders[account] = StakingUserData(
                    amount,
                    endTime,
                    true
                );
            }
            if (typeStake == 180) {
                stake180DaysHolders[account] = StakingUserData(
                    amount,
                    endTime,
                    true
                );
            }
            if (typeStake == 360) {
                stake360DaysHolders[account] = StakingUserData(
                    amount,
                    endTime,
                    true
                );
            }
        }
    }

    function _removeStakeholder(address account, uint typeStake) private {
        require(account != address(0), "_removeStakeholder: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "_removeStakeholder: The staking type must be 90, 180 or 360 days");

        bool stakeholderExists = isStakeholder(account, typeStake);

        if (stakeholderExists) {
            if (typeStake == 90) {
                stake90DaysHolders[account] = StakingUserData(
                    0,
                    0,
                    false
                );
            }
            if (typeStake == 180) {
                stake180DaysHolders[account] = StakingUserData(
                    0,
                    0,
                    false
                );
            }
            if (typeStake == 360) {
                stake360DaysHolders[account] = StakingUserData(
                    0,
                    0,
                    false
                );
            }
        }
    }

    function getAmountOfStake(address account, uint typeStake) override public view returns (uint256) {
        require(account != address(0), "getAmountOfStake: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "getAmountOfStake: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].amountForStakes;
        }
        if (typeStake == 180) {
            return stake180DaysHolders[account].amountForStakes;
        }
        if (typeStake == 360) {
            return stake360DaysHolders[account].amountForStakes;
        }

        return 0;
    }

    function getEndTime(address account, uint typeStake) override public view returns (uint) {
        require(account != address(0), "getAmountOfStake: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "getAmountOfStake: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].endStakeTime;
        }
        if (typeStake == 180) {
            return stake180DaysHolders[account].endStakeTime;
        }
        if (typeStake == 360) {
            return stake360DaysHolders[account].endStakeTime;
        }

        return 0;
    }

    function createStake(uint256 stake, uint typeStake) override public whenStakingActive returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "createStake: The staking type must be 90, 180 or 360 days");
        require(stake >= minAmountForStaking[typeStake], "createStake: The amount of tokens is less than the staking minimum"); 
        require(stake <= maxAmountForStaking[typeStake], "createStake: The amount of tokens is greater than the staking maximum");
        require(ecowattToken.balanceOf(msg.sender) >= stake, "createStake: Cannt stake more tokens than you hold unstaked");
        require(isStakeholder(msg.sender, typeStake) == false, "createStake: User is a stakeholder");
        
        uint durationOfStaking;
        if (typeStake == 90) {
            durationOfStaking = 90 days;
        } 
        if (typeStake == 180) {
            durationOfStaking = 180 days;
        } 
        if (typeStake == 360) {
            durationOfStaking = 360 days;
        }

        bool completed = ecowattToken.transferFrom(msg.sender, address (this), stake);
        if(completed == true) {
            _addStakeholder(msg.sender, typeStake, stake, block.timestamp + durationOfStaking);
            
            emit OnStake(msg.sender, typeStake, stake, block.timestamp + durationOfStaking);
            return true;
        }

        return false;
    }

    function isItRewardTime(address account, uint typeStake) override public view returns (bool) {
        require(account != address(0), "isItRewardTime: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "isItRewardTime: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return (stake90DaysHolders[account].endStakeTime <= block.timestamp && stake90DaysHolders[account].endStakeTime != 0);
        }
        if (typeStake == 180) {
            return (stake180DaysHolders[account].endStakeTime <= block.timestamp && stake180DaysHolders[account].endStakeTime != 0);
        }
        if (typeStake == 360) {
            return (stake360DaysHolders[account].endStakeTime <= block.timestamp && stake360DaysHolders[account].endStakeTime != 0);
        } 

        return false;   
    }

    function calculateReward(address account, uint typeStake) override public view returns(uint256, uint256) {
        require(account != address(0), "calculateReward: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "calculateReward: The staking type must be 90, 180 or 360 days");
        
        uint256 amount;
        if (typeStake == 90) {
            amount = stake90DaysHolders[msg.sender].amountForStakes;
        } 
        if (typeStake == 180) {
            amount = stake180DaysHolders[msg.sender].amountForStakes;
        } 
        if (typeStake == 360) {
            amount = stake360DaysHolders[msg.sender].amountForStakes;
        }
        
        if (amount == 0) {
            return (0, 0);
        } 

        uint256 percent = percentStaking[typeStake];
        
        return (amount, amount.mul(10 ** decimals()).div(10 ** ecowattToken.decimals()).div(100).mul(percent));
    }

    function getReward(uint typeStake) override public returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "getReward: The staking type must be 90, 180 or 360 days");
        require(isStakeholder(msg.sender, typeStake) == true, "createStake: User is not a stakeholder");

        uint endTime;
        if (typeStake == 90) {
            endTime = stake90DaysHolders[msg.sender].endStakeTime;
        } 
        if (typeStake == 180) {
            endTime = stake180DaysHolders[msg.sender].endStakeTime;
        } 
        if (typeStake == 360) {
            endTime = stake360DaysHolders[msg.sender].endStakeTime;
        }

        require(endTime != 0, "getReward: endTime can't be zero");
        require(block.timestamp > endTime, "getReward: Too early to withdraw");
            
        (uint256 tokens, uint256 reward) = calculateReward(msg.sender, typeStake);
        
        require(tokens != 0, "getReward: tokens cannt be zero");
        require(reward != 0, "getReward: reward cannt be zero");
        require(ecowattToken.balanceOf(address (this)) >= tokens, "getReward: contract doesnt have enough tokens");
        
        bool completed = ecowattToken.transfer(msg.sender, tokens);
        if (completed) {
            _mint(msg.sender, reward);

            _removeStakeholder(msg.sender, typeStake);
            
            emit OnReward(msg.sender, typeStake, tokens, reward);
            return true;
        }

        return false;
    }
}