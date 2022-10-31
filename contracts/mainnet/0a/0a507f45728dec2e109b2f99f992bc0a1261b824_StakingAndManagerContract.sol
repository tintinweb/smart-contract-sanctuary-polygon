/**
 *Submitted for verification at polygonscan.com on 2022-10-31
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20 {
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

contract EWCTToken is ERC20('Ecowatt Carbon Token', 'EWCT', 8), Ownable {
    
    mapping(address => uint256) public tokensBurnedByWallet;
    mapping(address => uint256) public tokensMintedByWallet;
    uint256 public totalTokensBurned;
    uint256 public totalTokensMinted;

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        tokensMintedByWallet[account] += amount;
        totalTokensMinted += amount;
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        tokensBurnedByWallet[account] += amount;
        totalTokensBurned += amount;
    }
}

contract StakingAndManagerContract is Ownable {
    
    IERC20 public immutable ecowattToken;
    EWCTToken public immutable ecowattCarbonToken;

    constructor(address ewtAddress){
        ecowattToken = IERC20(ewtAddress);
        ecowattCarbonToken = new EWCTToken();
        _setStakingPercentRate();
        ecowattCarbonToken.mint(msg.sender, 85 * 1e6 * 1e8);
    }

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

    event OnStake(address indexed sender, uint typeStake, uint256 amount, uint endTime);

    event OnWithdraw(address indexed sender, uint typeStake, uint256 tokens);
    
    bool public stakingActive = false;

    modifier whenStakingActive {
        require(stakingActive, "whenStakingActive: Staking is now stopped.");
        _;
    }
    
    function setStakingActive(bool _stakingActive) external onlyOwner {
        stakingActive = _stakingActive;
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

    function setStakingPercent(uint typeStake, uint256 newPercent) public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setStakingPercent: The staking type must be 90, 180 or 360 days");
        require(newPercent > 0, "setStakingPercent: newPercent must be greater than than 0");
        percentStaking[typeStake] = newPercent;
        return true;
    }

    function setMaxAmountForStaking(uint typeStake, uint256 newMaxAmount) public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setMaxAmountForStaking: The staking type must be 90, 180 or 360 days");
        require(newMaxAmount >= 100, "setMaxAmountForStaking: newMaxAmount must be greater than than 100");
        maxAmountForStaking[typeStake] = newMaxAmount;
        return true;
    }

    function setMinAmountForStaking(uint typeStake, uint256 newMinAmount) public onlyOwner returns (bool) {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "setMinAmountForStaking: The staking type must be 90, 180 or 360 days");
        require(newMinAmount >= 100, "setMinAmountForStaking: newMinAmount must be greater than than 100");
        minAmountForStaking[typeStake] = newMinAmount;
        return true;
    }

    function isStakeholder(address account, uint typeStake) public view returns (bool) {
        require(account != address(0), "isStakeHolder: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "isStakeHolder: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].exist;
        }
        else if (typeStake == 180) {
            return stake180DaysHolders[account].exist;
        }
        else {
            return stake360DaysHolders[account].exist;
        }
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
            else if (typeStake == 180) {
                stake180DaysHolders[account] = StakingUserData(
                    amount,
                    endTime,
                    true
                );
            }
            else {
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
            else if (typeStake == 180) {
                stake180DaysHolders[account] = StakingUserData(
                    0,
                    0,
                    false
                );
            }
            else {
                stake360DaysHolders[account] = StakingUserData(
                    0,
                    0,
                    false
                );
            }
        }
    }

    function getAmountOfStake(address account, uint typeStake) public view returns (uint256) {
        require(account != address(0), "getAmountOfStake: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "getAmountOfStake: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].amountForStakes;
        }
        else if (typeStake == 180) {
            return stake180DaysHolders[account].amountForStakes;
        }
        else {
            return stake360DaysHolders[account].amountForStakes;
        }
    }

    function getEndTime(address account, uint typeStake) public view returns (uint) {
        require(account != address(0), "getEndTime: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "getEndTime: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return stake90DaysHolders[account].endStakeTime;
        }
        else if (typeStake == 180) {
            return stake180DaysHolders[account].endStakeTime;
        }
        else {
            return stake360DaysHolders[account].endStakeTime;
        }
    }

    function createStake(uint256 stake, uint typeStake) external whenStakingActive {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "createStake: The staking type must be 90, 180 or 360 days");
        require(stake >= minAmountForStaking[typeStake], "createStake: The amount of tokens is less than the staking minimum"); 
        require(stake <= maxAmountForStaking[typeStake], "createStake: The amount of tokens is greater than the staking maximum");
        require(ecowattToken.balanceOf(msg.sender) >= stake, "createStake: Cannot stake more tokens than you hold unstaked");
        require(isStakeholder(msg.sender, typeStake) == false, "createStake: User is a stakeholder");
        
        uint durationOfStaking;
        if (typeStake == 90) {
            durationOfStaking = 90 days;
        } 
        else if (typeStake == 180) {
            durationOfStaking = 180 days;
        } 
        else {
            durationOfStaking = 360 days;
        }

        ecowattToken.transferFrom(msg.sender, address (this), stake);
        _addStakeholder(msg.sender, typeStake, stake, block.timestamp + durationOfStaking);
        emit OnStake(msg.sender, typeStake, stake, block.timestamp + durationOfStaking);
        (,uint256 reward) = calculateReward(msg.sender, typeStake);
        ecowattCarbonToken.mint(msg.sender, reward);
    }

    function isItWithdrawTime(address account, uint typeStake) public view returns (bool) {
        require(account != address(0), "createStake: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "createStake: The staking type must be 90, 180 or 360 days");

        if (typeStake == 90) {
            return (stake90DaysHolders[account].endStakeTime <= block.timestamp && stake90DaysHolders[account].endStakeTime != 0);
        }
        
        else if (typeStake == 180) {
            return (stake180DaysHolders[account].endStakeTime <= block.timestamp && stake180DaysHolders[account].endStakeTime != 0);
        }
        else {
            return (stake360DaysHolders[account].endStakeTime <= block.timestamp && stake360DaysHolders[account].endStakeTime != 0);
        } 
    }

    function calculateReward(address account, uint typeStake) public view returns(uint256, uint256) {
        require(account != address(0), "calculateReward: account is the zero address");
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "calculateReward: The staking type must be 90, 180 or 360 days");
        
        uint256 amount;
        if (typeStake == 90) {
            amount = stake90DaysHolders[msg.sender].amountForStakes;
        } 
        else if (typeStake == 180) {
            amount = stake180DaysHolders[msg.sender].amountForStakes;
        } 
        else {
            amount = stake360DaysHolders[msg.sender].amountForStakes;
        }
        
        if (amount == 0) {
            return (0, 0);
        } 

        uint256 percent = percentStaking[typeStake];
        
        return (amount, amount * (10 ** ecowattCarbonToken.decimals()) * 1e18 * percent / (10 ** ecowattToken.decimals()) / 1e18 / 100);
    }

    function withdrawTokens(uint typeStake) external {
        require(typeStake == 90 || typeStake == 180 || typeStake == 360, "withdrawTokens: The staking type must be 90, 180 or 360 days");
        require(isStakeholder(msg.sender, typeStake) == true, "withdrawTokens: User is not a stakeholder");

        uint endTime;
        if (typeStake == 90) {
            endTime = stake90DaysHolders[msg.sender].endStakeTime;
        } 
        else if (typeStake == 180) {
            endTime = stake180DaysHolders[msg.sender].endStakeTime;
        } 
        else {
            endTime = stake360DaysHolders[msg.sender].endStakeTime;
        }

        require(endTime != 0, "withdrawTokens: endTime can't be zero");
        require(block.timestamp > endTime, "withdrawTokens: Too early to withdraw");
            
        (uint256 tokens,) = calculateReward(msg.sender, typeStake);
        
        require(tokens != 0, "withdrawTokens: tokens cannt be zero");
        require(ecowattToken.balanceOf(address (this)) >= tokens, "withdrawTokens: contract doesnt have enough tokens");
        
        ecowattToken.transfer(msg.sender, tokens);
        _removeStakeholder(msg.sender, typeStake);
        emit OnWithdraw(msg.sender, typeStake, tokens);
    }

    function burnCarbonTokens(uint256 amount) external {
        require(ecowattCarbonToken.balanceOf(msg.sender) >= amount, "burnCarbonTokens: Not enough tokens to burn");
        require(ecowattCarbonToken.allowance(msg.sender, address(this)) >= amount, "burnCarbonTokens: Not enough allowance to burn.  Please do a token approval to enable burning of msg.sender's tokens.");
        ecowattCarbonToken.burn(msg.sender, amount);
    }
}