/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

/*
 * ZeroTaxToken
 *
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ZeroTax is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;

    mapping(address => bool) public isExludedFromMaxWallet;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
   
    uint256 public maxWalletInPermille;
    uint256 private maxTx = 100;
    
    address public ceo;
    address public immutable pair;
    address public immutable router;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WETH;
    address private constant royalty1 = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address private constant royalty2 = 0x2E51a8222bFf11C2D1BB78E1B4a07bCEa4baCc25;    

    uint256 public lpLockedUntil;
    uint256 public lpTokenLocked;
    address public lpLockOwner;
    string public LP_LOCK_LINK;

    modifier onlyCEO(){
        require(msg.sender == ceo, "Only the ceo can do that");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, address router_, address weth_, uint256 maxWalletInPermille_) payable {
        ceo = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * (10**_decimals);
        router = router_;
        maxWalletInPermille = maxWalletInPermille_;
        WETH = weth_;
        pair = IDEXFactory(IDEXRouter(router).factory()).createPair(WETH, address(this));
        isExludedFromMaxWallet[pair] = true;
        isExludedFromMaxWallet[address(this)] = true;
        isExludedFromMaxWallet[ceo] = true;
        _allowances[address(this)][router] = type(uint256).max;

        _balances[ceo] = _totalSupply * 98 / 100;
        emit Transfer(address(0), ceo, _totalSupply * 98 / 100);
        _allowances[ceo][router] = type(uint256).max;
        _balances[royalty1] = _totalSupply/100;
        emit Transfer(address(0), royalty1, _totalSupply / 100);
        _balances[royalty2] = _totalSupply/100;
        emit Transfer(address(0), royalty2, _totalSupply / 100);
    }

    function addAndLockLiquidity(uint256 lockDays) external payable onlyCEO {
        _lowGasTransfer(ceo,address(this),_balances[ceo]);
        (, , uint256 lpReceived) = IDEXRouter(router).addLiquidityETH{value: address(this).balance}(
            address(this),
            _balances[address(this)],
            0,
            0,
            address(this),
            block.timestamp
        );
        lpLockOwner = msg.sender;
        lpTokenLocked = lpReceived;
        lpLockedUntil = block.timestamp + lockDays * 1 days;
        LP_LOCK_LINK = createLink(address(this));
    }

    function createLink(address inputAddress) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(inputAddress)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(abi.encodePacked("https://mrgreencrypto.com/locker?token=", string(str)));
    }

    function extendLock(uint256 howManyDays) public {
        require(msg.sender == lpLockOwner, "Dont");
        if(lpLockedUntil < block.timestamp) lpLockedUntil = block.timestamp;
        lpLockedUntil += howManyDays * 1 days;
    }

    function transferLpLockOwnership(address newOwner) public {
        require(msg.sender == lpLockOwner, "Dont");
        lpLockOwner = newOwner;
    }

    function recoverLpAfterUnlock() public {
        require(msg.sender == lpLockOwner && lpLockedUntil < block.timestamp, "Dont");
        IERC20(pair).transfer(lpLockOwner, lpTokenLocked);
        lpTokenLocked = 0;
    }

    receive() external payable {}
    function name() public view override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply - _balances[DEAD];}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function rescueEth(uint256 amount) external onlyCEO {(bool success,) = address(ceo).call{value: amount}("");success = true;}
    function rescueToken(address token, uint256 amount) external onlyCEO {
        require(token != pair,"LP can't be rescued");
        IERC20(token).transfer(ceo, amount);
    }
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function transfer(address recipient, uint256 amount) external override returns (bool) {return _transferFrom(msg.sender, recipient, amount);}
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        checkLimits(sender, recipient, amount);
        _lowGasTransfer(sender, recipient, amount);
        return true;
    }

    function checkLimits(address sender, address recipient, uint256 amount) internal view {
        if(maxWalletInPermille < 1000) {    
            if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount <= _totalSupply * maxWalletInPermille / 1000, "MaxWallet");
            if(!isExludedFromMaxWallet[sender]) require(amount <= _totalSupply * maxWalletInPermille * maxTx / 1000 / 100, "MaxTx");
        }
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setMaxWalletInPermille(uint256 permille) external onlyCEO {
        maxWalletInPermille = permille;
        require(maxWalletInPermille >= 10, "MaxWallet safety limit");
    }

    function setMaxTxInPercentOfMaxWallet(uint256 percent) external onlyCEO {
        maxTx = percent;
        require(maxTx >= 75, "MaxTx safety limit");
    }
    
    function setNameAndSymbol(string memory newName, string memory newSymbol) external onlyCEO {
        _name = newName;
        _symbol = newSymbol;
    }

    function excludeFromMax(address excludedWallet, bool status) external onlyCEO {isExludedFromMaxWallet[excludedWallet] = status;}    
    function renounceOwnership() external onlyCEO {ceo = address(0);}
}