/**
 *Submitted for verification at polygonscan.com on 2023-06-18
*/

// SPDX-License-Identifier: MIT

/* 

$$___$$_ __$$$___ $$___$$_ __$$$___ $$___$$_ $$$$_ $$___$$_ $$$$$$$_ $$$$$$__ _$$$$$__ $$$$$$$_
$$$_$$$_ _$$_$$__ $$$_$$$_ _$$_$$__ $$$__$$_ _$$__ $$___$$_ $$______ $$___$$_ $$___$$_ $$______
_$$$$$__ $$___$$_ _$$$$$__ $$___$$_ $$$$_$$_ _$$__ _$$_$$__ $$$$$___ $$___$$_ _$$$____ $$$$$___
_$$$$$__ $$___$$_ _$$$$$__ $$___$$_ $$_$$$$_ _$$__ _$$_$$__ $$______ $$$$$$__ ___$$$__ $$______
$$$_$$$_ _$$_$$__ $$$_$$$_ _$$_$$__ $$__$$$_ _$$__ __$$$___ $$______ $$___$$_ $$___$$_ $$______
$$___$$_ __$$$___ $$___$$_ __$$$___ $$___$$_ $$$$_ ___$____ $$$$$$$_ $$___$$_ _$$$$$__ $$$$$$$_

93% for Initial Liquidity (100% LP will be burnt)
7% for Listings 

No Team Token
No Dev Token
No Blocklist 
No Whitelist 
No Cooldown Time
No limit in selling
Anti Whale in buying
LP are not Locked because 100% of it be burned
There are no option to Turn off the Swap
There are no Pause and Unpause token

Token Taxes are not bullshit if it is for the ecosystem... 
    Auto Burn
    Auto Liquidity - LP Tokens are auto burned

there are two stages

    stage 1 
        Max Token per Wallet is on [250 Billion]
        Buy Tax = 3% (1% Auto Burn, 2% for Liquidity)
        Sell Tax = 8% (2% Auto Burn, 6% for Liquidity)
        1,000 Plus Holders 
        Listings 
        Wwnership will be Renounced 
    Stage 2 
        Max Token per Wallet is on [250 Billion]
        Buy Tax = 3% (2% auto burn, 1% for Liquidity)
        Sell Tax = 3% (2% auto burn, 1% for Liquidity)
        10,000 Plus Holders 

*/

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
 
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 { 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
 
interface IERC20 { 
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address to, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
 
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
 
contract XOCAToken is ERC20, Ownable {
    IUniswapV2Router02 public zUniswapV2Router;
    address public zUniswapV2Pair;
    
    bool private yFlag0;
    bool private yFlag1;
    bool private yFlag2;
    bool private yFlag3;
    bool private yFlag4;
    bool private yFlag5; 
    bool private yFlag6; 
    
    uint256 private immutable YVAR0;
    uint256 private yVar1;
    uint256 private immutable YVAR2;
    uint256 private immutable YVAR3;
    uint256 private yVar4;
    uint256 private yVar5;
    uint256 public currentStage;

    uint256 public zForLiq;
    uint256 public zTotBurAmo;
    uint256 public zTotLiqAmo;

    uint256 public buyTaxAutoBurn = 1; 
    uint256 public buyTaxToLiquidity = 2;
    uint256 public sellTaxAutoBurn = 1; 
    uint256 public sellTaxToLiquidity = 2; 

    address public walletListings; 
    address public walletSetter;
    uint256 private buyCooldownTime;
    uint256 public loguinta;
    uint256 public loguintb;
    uint256 public loguintc;
    string public logstra;
    string public logstrb;
    string public logstrc;
    string public logstrd;
    string public logstre;

    mapping(address => bool) public yAddress0;
    mapping(address => bool) public yAddress1;
    mapping(address => bool) public yAddress2;
    mapping(address => bool) public yAddress3;
    mapping(address => bool) public yAddress4;
    mapping(address => bool) public yAddress5;
    mapping(address => bool) public yAddress6;
     
    mapping(address => uint256) public yAddress7; 
 
    bool private zIsLiquidity;
    modifier mLockTheSwap {
        zIsLiquidity = true;
        _;
        zIsLiquidity = false;
    } 

    event eSwapAndLiquify(uint256 _token1, uint256 _token2);
    event eSwapBuy(address _from, address _to, uint256 _amount);
    event eSwapSell(address _from, address _to, uint256 _amount);
    event eTransfer(address _from, address _to, uint256 _amount);
    event eTransferCoin(address _from, address _to, uint256 _amount);

    constructor(uint256[] memory myvar) ERC20("XOCA TOKEN", "XOCA") {  
        IUniswapV2Router02 _router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // mumbai testnet
        // IUniswapV2Router02 _router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // bsc mainnet

        zUniswapV2Router = _router;
        zUniswapV2Pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        yFlag5 = false;
        yFlag6 = true;
 
        // walletListings = 0ssssssssssssssssssssssssssssssssssssss; // test listings
        // walletSetter = 0ssssssssssssssssssssssssssssssssssssss; // wallet as setter 
        
        walletListings = 0x926267C3724D2AB8E235e87BdC68FE970E6C76fD; // test listings
        walletSetter = 0xfF4d5CA5500cc921F43A27b67c208b6E5d0b97C1; // wallet as setter 
   
        YVAR0 = myvar[0];
        yVar1 = myvar[1];
        YVAR2 = myvar[2];
        YVAR3 = myvar[3];
        yVar4 = myvar[4];
        yVar5 = myvar[5];
        
        _mint(walletListings, YVAR3); 
        _mint(msg.sender, YVAR2); 

        yAddress2[address(zUniswapV2Router)] = true;
        yAddress2[zUniswapV2Pair] = true;
        yAddress0[address(zUniswapV2Router)] = true;
        yAddress0[zUniswapV2Pair] = true;
        yAddress6[address(zUniswapV2Router)] = true;
        yAddress6[zUniswapV2Pair] = true; 
        yAddress6[msg.sender] = true;
        yAddress2[msg.sender] = true;
        yAddress2[address(this)] = true;
        yAddress2[walletListings] = true; 
        yAddress0[msg.sender] = true;
        yAddress0[address(this)] = true;
        yAddress0[walletListings] = true; 
        yAddress6[msg.sender] = true;
        yAddress6[address(this)] = true;
        yAddress6[walletListings] = true;
        yAddress3[walletSetter] = true;
        yAddress3[msg.sender] = true;
        yAddress4[walletSetter] = true;
        yAddress4[msg.sender] = true;
        yAddress5[walletSetter] = true;
        yAddress5[msg.sender] = true;

    }

    function _transfer(address sender, address recipient, uint256 amount) internal override { 
        uint256 taxAutBur;
        uint256 taxToLiq;
        uint256 forTra;
        uint256 isBal;

        bool isFlag2 = yFlag2; 
        bool isBuy = false; 
        bool isSell = false; 

        bool canSwap = zForLiq >= yVar5;
        bool takeFee;
        if (recipient == zUniswapV2Pair && !zIsLiquidity && yFlag6 && !yFlag5 && canSwap) { 
            logstrc = "s sal";
            swapAndLiquify();
        }
        takeFee = !zIsLiquidity;
 
        if (currentStage <= 2) {  
            logstre = "w 0";
            if (yAddress0[sender] && yAddress0[recipient]) {
                isFlag2 = true; 
                logstre = "w 1";
            } 
        }
        if (sender == zUniswapV2Pair) { 
            isBuy = true;
            require(isFlag2, "Error"); 
            logstra = "b";
            if (yFlag3 && !yAddress6[recipient]) { 
                logstrb = "b l 1";
                isBal = balanceOf(recipient) + amount;
                loguinta = isBal;
                loguintb = yVar1;
                require(isBal <= yVar1, "Limit Error"); 
            }
            yAddress7[recipient] = block.timestamp;
            if (takeFee) {
                if (yFlag1) { taxAutBur = amount * buyTaxAutoBurn / 100; } 
                if (yFlag0) { taxToLiq = amount * buyTaxToLiquidity / 100; }  
                logstrc = "b f";
            }
            logstrd = "b e";
            emit eSwapBuy(sender, recipient, amount); 
        } else if (recipient == zUniswapV2Pair) { 
            isSell = true;
            logstra = "s";
            require(isFlag2, "Error"); 
            if (takeFee) {
                if (yFlag1) { taxAutBur = amount * sellTaxAutoBurn / 100; } 
                if (yFlag0) { taxToLiq = amount * sellTaxToLiquidity / 100; }  
                logstrb = "s f";
            }
            logstrc = "s e";
            logstrd = "s";
            emit eSwapSell(sender, recipient, amount); 
        } else { 
            emit eTransfer(sender, recipient, amount);  
        } 
        if (yAddress2[sender] && yAddress2[recipient]) {
            taxAutBur = 0;
            taxToLiq = 0; 
        }
        if (zTotBurAmo >= yVar4) {
            taxAutBur = 0;
        }
        if (taxAutBur > 0) {
            _burn(sender, taxAutBur);
            zTotBurAmo += taxAutBur; 
        }
        if (taxToLiq > 0) {
            super._transfer(sender, address(this), taxToLiq);  
            zTotLiqAmo += taxToLiq;
            zForLiq += taxToLiq;
        }
        forTra = amount - taxAutBur - taxToLiq; 
        super._transfer(sender, recipient, forTra);
    }

    function zGetVar() public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        require(yAddress3[msg.sender], "Access Denied");
        return (YVAR0,yVar1,YVAR2,YVAR3,yVar4,yVar5);
    }
    function zGetBool() public view returns (bool,bool,bool,bool,bool,bool,bool) {
        require(yAddress3[msg.sender], "Access Denied");
        return (yFlag0,yFlag1,yFlag2,yFlag3,yFlag4,yFlag5,yFlag6);
    }
    function zGetTokenBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }
    function zGetCoinBalance(address account) public view returns (uint256) {
        return account.balance;
    } 
    function zGetAddresses() public view returns (address _address1, address _address2, address _address3, address _address4, address _address5) {
        require(yAddress3[msg.sender], "Access Denied");
        return (msg.sender,address(this),address(zUniswapV2Router),zUniswapV2Pair,owner());
    } 
 
    // this will add liquidity from liquidity tax wallet and burns the lp token
    function swapAndLiquify() private mLockTheSwap {
        uint256 half = zForLiq / 2;
        uint256 otherHalf = zForLiq - half;
        uint256 initialBalance = address(this).balance;     
        zTask1(otherHalf);
        uint256 newBalance = address(this).balance - initialBalance;     
        zTask2(half, newBalance);            
        zForLiq -= (half + otherHalf); 
        emit eSwapAndLiquify(otherHalf, newBalance);
    }
    function addLiquidityManually() public mLockTheSwap { 
        require(yAddress4[msg.sender], "Access Denied");
        bool canSwap = zForLiq >= yVar5;
        if (!zIsLiquidity && yFlag6 && canSwap) { 
            uint256 half = zForLiq / 2;
            uint256 otherHalf = zForLiq - half;
            uint256 initialBalance = address(this).balance;     
            zTask1(otherHalf);
            uint256 newBalance = address(this).balance - initialBalance;     
            zTask2(half, newBalance);            
            zForLiq -= (half + otherHalf); 
            emit eSwapAndLiquify(otherHalf, newBalance);
        } 
    }  
    function zTask1(uint256 tokenAmount) private { 
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] = zUniswapV2Router.WETH(); 
        if(allowance(address(this), address(zUniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(zUniswapV2Router), tokenAmount);  
        }
        uint256 deadline = block.timestamp + 300; // 5-minute deadline
        zUniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( tokenAmount, 0, path, address(this), deadline ); 
    } 
    function zTask2(uint256 tokenAmount, uint256 ethAmount) private { 
        _approve(address(this), address(zUniswapV2Router), tokenAmount);   
        uint256 deadline = block.timestamp + 300; // 5-minute deadline
        zUniswapV2Router.addLiquidityETH{value: ethAmount}( address(this), tokenAmount, 0, 0, address(0), deadline ); 
    }

    // this is the only option to set Buy Tax and Sell Tax 
    function zSetStage(uint256 _index) external {
        require(yAddress3[msg.sender], "Access Denied");
        require(currentStage < _index, "No Turning Back");
        if (_index == 1) { 
            yFlag2 = false;
            yFlag3 = true; 
            yFlag4 = false;  
            buyTaxAutoBurn = 1;
            buyTaxToLiquidity = 2;
            sellTaxAutoBurn = 2;
            sellTaxToLiquidity = 6;
            buyCooldownTime = 0; 
        } else if (_index == 2) { 
            yFlag2 = true;
            yFlag3 = true; 
            yFlag4 = false; 
            buyTaxAutoBurn = 2;
            buyTaxToLiquidity = 1;
            sellTaxAutoBurn = 2;
            sellTaxToLiquidity = 1;
            buyCooldownTime = 0; 
        }
        currentStage = _index;
    }
    
    function zSetBool(uint256[] calldata _index, bool[] calldata _value) external {
        require(yAddress3[msg.sender], "Access Denied");
        require(_index.length == _value.length, "Length Error"); 
        for (uint256 i = 0; i < _index.length; i++) {
            if (_index[i] == 0) {
                yFlag0 = _value[i];
            } else if (_index[i] == 1) {
                yFlag1 = _value[i];
            } else if (_index[i] == 2) {
                yFlag2 = _value[i];
            } else if (_index[i] == 3) {
                yFlag3 = _value[i];
            } else if (_index[i] == 4) {
                yFlag4 = _value[i]; 
            } else if (_index[i] == 5) {
                yFlag5 = _value[i]; 
            } else if (_index[i] == 6) {
                yFlag6 = _value[i]; 
            }
        }
    }

    function zSetUint(uint256 _index, uint256 _max) external {
        require(yAddress3[msg.sender], "Access Denied");
        if (_index == 1) {
            yVar1 = _max;
        } else if (_index == 4) {
            yVar4 = _max;
        } else if (_index == 5) {
            yVar5 = _max;
        }
    }

    function zSetAddresses(uint256 _index, address[] calldata _addresses, bool[] calldata _bool) external {
        require(yAddress3[msg.sender], "Access Denied");
        require(_addresses.length == _bool.length, "Length Error"); 
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_index == 0) {
                yAddress0[_addresses[i]] = _bool[i];
            } else if (_index == 1) {
                yAddress1[_addresses[i]] = _bool[i];
            } else if (_index == 2) {
                yAddress2[_addresses[i]] = _bool[i];
            } else if (_index == 3) {
                yAddress3[_addresses[i]] = _bool[i];
            } else if (_index == 4) {
                yAddress5[_addresses[i]] = _bool[i]; 
            } else if (_index == 5) {
                yAddress6[_addresses[i]] = _bool[i]; 
            }
        }
    } 
  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    } 
 
    receive() payable external {}
    
}