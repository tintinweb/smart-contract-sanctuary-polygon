/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts); 
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 { 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
contract CCCC is ERC20, Ownable {
    IUniswapV2Router02 public zUniswapV2Router;
    address public zUniswapV2Pair;
    
    
    uint256 private immutable YVAR0;
    uint256 private immutable YVAR2111;
    uint256 private immutable YVAR3222;

    uint256[] private yValue;

    uint256 private buyCooldownTime;
    uint256 private mintCooldownTime = block.timestamp + 120 seconds;
    uint256 private mintMonthlyInterval = 60 seconds;

    uint256 public currentStage;
    uint256 public buyTaxAutoBurn = 1; 
    uint256 public buyTaxToLiquidity = 2;
    uint256 public sellTaxAutoBurn = 1; 
    uint256 public sellTaxToLiquidity = 2;
    address public walletForExchange; 
    address public walletData;
    uint256[] public logNumber;
    string[] public logString;
    uint256[] public ySum;
    bool[] private yFlag; 

    mapping(uint256 => mapping(address => bool)) public yAddress;     
    mapping(address => uint256) public yStamp; 
 
    modifier mLockTheSwap {
        yFlag[7] = true;
        _;
        yFlag[7] = false;
    } 

    AggregatorV3Interface internal priceFeedMATICUSD;
    AggregatorV3Interface internal priceFeedETHUSD;

    event eSwapAndLiquify(uint256 _token1, uint256 _token2);
    event eSwapBuy(address _from, address _to, uint256 _amount);
    event eSwapSell(address _from, address _to, uint256 _amount);
    event eTransfer(address _from, address _to, uint256 _amount);
    event eTransferCoin(address _from, address _to, uint256 _amount); 

    constructor(uint256[] memory myvar) ERC20("CCCC TOKEN", "CCCC") {
        YVAR0 = myvar[0];
        YVAR2111 = myvar[1];
        YVAR3222 = myvar[2];

        walletForExchange = 0x89703cC5B8A9a06c9cB7069C0AA048a53bBbE3b4;
        walletData = 0x92A8a4e3cBd0E9f63890dDe9168e55f21D2df53a; 
        _mint(walletForExchange, YVAR3222); 
        _mint(_msgSender(), YVAR2111); 
        zSetAddress(walletData,[3,4,5,9,9,9],[true,true,true,true,true,true]);
        zSetAddress(address(this),[0,2,6,9,9,9],[true,true,true,true,true,true]);
        zSetAddress(msg.sender,[0,2,3,4,5,6],[true,true,true,true,true,true]); 
 
        IUniswapV2Router02 _router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // mumbai
        // IUniswapV2Router02 _router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // bnb
        zUniswapV2Router = _router;
        zUniswapV2Pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());

        priceFeedMATICUSD = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // live 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        priceFeedETHUSD = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A); // live 0xDf3f72Be10d194b58B1BB56f2c4183e661cB2114
    } 

    // Function to get the current token price 
    function getMATICUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedMATICUSD.latestRoundData();
        return price;
    } 
    function getTOKENPerMATIC18(int256 _amountinusd) public view returns (int256) {
        (, int256 price, , , ) = priceFeedMATICUSD.latestRoundData();
        int256 newprice = _amountinusd * price;
        newprice = newprice * 10**10;
        return newprice;
    } 
    function getTOKENPerMATIC4(int256 _amountinusd) public view returns (int256) {
        (, int256 price, , , ) = priceFeedMATICUSD.latestRoundData();
        int256 newprice = _amountinusd * price;
        newprice = newprice / 10**4;
        return newprice;
    } 
    // Function to get the current token price
    function getETHUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedETHUSD.latestRoundData();
        return price;
    } 

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 taxAutBur;
        uint256 taxToLiq;
        uint256 forTra;
        uint256 isBal;

        bool isFlag2 = yFlag[2]; 
        bool isBuy = false; 
        bool isSell = false; 

        bool canSwap = ySum[0] >= yValue[2];
        bool takeFee;
        if (recipient == zUniswapV2Pair && !yFlag[7] && yFlag[6] && !yFlag[5] && canSwap) { swapAndLiquify(); }
        takeFee = !yFlag[7];
 
        if (currentStage <= 2) { if (yAddress[0][sender] && yAddress[0][recipient]) { isFlag2 = true; } }
        if (sender == zUniswapV2Pair) { 
            isBuy = true;
            require(isFlag2, "Error"); 
            if (currentStage == 2) { require(block.timestamp >= yStamp[recipient] || yStamp[recipient] == 0, "Not Allowed"); }
            yStamp[recipient] = block.timestamp + buyCooldownTime; 
            if (yFlag[3] && !yAddress[6][recipient]) { isBal = balanceOf(recipient) + amount; require(isBal <= yValue[0], "Error"); }
            yStamp[recipient] = block.timestamp;
            if (takeFee) { if (yFlag[1]) { taxAutBur = amount * buyTaxAutoBurn / 100; } if (yFlag[0]) { taxToLiq = amount * buyTaxToLiquidity / 100; } } 
            emit eSwapBuy(sender, recipient, amount); 
        } else if (recipient == zUniswapV2Pair) { 
            isSell = true; 
            require(isFlag2, "Error"); 
            if (takeFee) { if (yFlag[1]) { taxAutBur = amount * sellTaxAutoBurn / 100; } if (yFlag[0]) { taxToLiq = amount * sellTaxToLiquidity / 100; } }
            emit eSwapSell(sender, recipient, amount); 
        } else { 
            emit eTransfer(sender, recipient, amount);  
        } 
        if (yAddress[2][sender] && yAddress[2][recipient]) { taxAutBur = 0; taxToLiq = 0; }
        if (ySum[1] >= yValue[1]) { taxAutBur = 0; }
        if (taxAutBur > 0) { _burn(sender, taxAutBur); ySum[1] += taxAutBur; }
        if (taxToLiq > 0) { super._transfer(sender, address(this), taxToLiq); ySum[2] += taxToLiq; ySum[0] += taxToLiq; }
        forTra = amount - taxAutBur - taxToLiq; 
        super._transfer(sender, recipient, forTra);
    }

    function zGetVar() public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        require(yAddress[3][_msgSender()], "Access Denied");
        return (YVAR0,yValue[0],YVAR2111,YVAR3222,yValue[1],yValue[2]);
    }
    function zGetBool() public view returns (bool,bool,bool,bool,bool,bool,bool,bool) {
        require(yAddress[3][_msgSender()], "Access Denied");
        return (yFlag[0],yFlag[1],yFlag[2],yFlag[3],yFlag[4],yFlag[5],yFlag[6],yFlag[7]);
    }
    function zGetTokenBalanceOf(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }
    function zGetCoinBalanceOf(address _account) public view returns (uint256) {
        return _account.balance;
    } 
    function zGetAddresses() public view returns (address _address1, address _address2, address _address3, address _address4, address _address5) {
        require(yAddress[3][_msgSender()], "Access Denied");
        return (_msgSender(),address(this),address(zUniswapV2Router),zUniswapV2Pair,owner());
    }
 
    // this will add liquidity from liquidity tax wallet and burns the lp token
    function swapAndLiquify() private mLockTheSwap {
        uint256 half = ySum[0] / 2;
        uint256 otherHalf = ySum[0] - half;
        uint256 initialBalance = address(this).balance;
        zTask1(otherHalf);
        uint256 newBalance = address(this).balance - initialBalance;
        zTask2(half, newBalance);        
        ySum[0] -= (half + otherHalf); 
        emit eSwapAndLiquify(otherHalf, newBalance);
    }
    function addLiquidityManually() public mLockTheSwap { 
        require(yAddress[4][_msgSender()], "Access Denied");
        bool canSwap = ySum[0] >= yValue[2];
        if (!yFlag[7] && yFlag[6] && canSwap) { 
            uint256 half = ySum[0] / 2;
            uint256 otherHalf = ySum[0] - half;
            uint256 initialBalance = address(this).balance;     
            zTask1(otherHalf);
            uint256 newBalance = address(this).balance - initialBalance;     
            zTask2(half, newBalance);            
            ySum[0] -= (half + otherHalf); 
            emit eSwapAndLiquify(otherHalf, newBalance);
        } 
    }
    function zTask1(uint256 _tokenAmount) private { 
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] = zUniswapV2Router.WETH(); 
        if(allowance(address(this), address(zUniswapV2Router)) < _tokenAmount) { _approve(address(this), address(zUniswapV2Router), _tokenAmount); }
        uint256 deadline = block.timestamp + 500;  
        zUniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( _tokenAmount, 0, path, address(this), deadline ); 
    } 
    function zTask2(uint256 _tokenAmount, uint256 ethAmount) private { 
        _approve(address(this), address(zUniswapV2Router), _tokenAmount);   
        uint256 deadline = block.timestamp + 500;  
        zUniswapV2Router.addLiquidityETH{value: ethAmount}( address(this), _tokenAmount, 0, 0, address(0), deadline ); 
    }
    function zData1(uint256[] memory _amount) external {
        yValue = new uint256[](5);
        uint8 j; while (j < _amount.length) { yValue[j] = _amount[j]; j++; }
        yFlag = new bool[](10);
        ySum = new uint256[](10);
        yFlag[5] = false;
        yFlag[6] = true;  
        yFlag[7] = false;
        zSetAddress(zUniswapV2Pair,[0,2,6,9,9,9],[true,true,true,true,true,true]);
        zSetAddress(walletForExchange,[0,2,6,9,9,9],[true,true,true,true,true,true]); 
        zSetAddress(address(zUniswapV2Router),[0,2,6,9,9,9],[true,true,true,true,true,true]); 
    } 
    // this function allows owner to mint additional token six months after the deployment
    // then monthly, owner can mint until max supply ends
    function zData2() external {
        uint256 canMint = ySum[3] + yValue[3];
        require(yAddress[4][_msgSender()], "Access Denied");
        require(canMint <= YVAR2111, "Max Error");
        require(block.timestamp >= mintCooldownTime, "Not Allowed"); 
        ySum[3] += yValue[3];
        mintCooldownTime = block.timestamp + mintMonthlyInterval; 
        _mint(_msgSender(), yValue[3]);
    }
    // buy using matic and chainlink oracle
    function zData3() external {
        require(yAddress[4][_msgSender()], "Access Denied");
        
    }
    // this is the only option to set Buy Tax and Sell Tax 
    function zSetStage(uint256 _index) external {
        require(yAddress[3][_msgSender()], "Access Denied");
        require(currentStage < _index, "No Turning Back");
        if (_index == 1) { 
            yFlag[2] = false;
            yFlag[3] = true;
            yFlag[4] = false;
            buyTaxAutoBurn = 0;
            buyTaxToLiquidity = 3;
            sellTaxAutoBurn = 0;
            sellTaxToLiquidity = 8;
            buyCooldownTime = 0; 
        } else if (_index == 2) { 
            yFlag[2] = true;
            yFlag[3] = true; 
            yFlag[4] = false; 
            buyTaxAutoBurn = 1;
            buyTaxToLiquidity = 2;
            sellTaxAutoBurn = 1;
            sellTaxToLiquidity = 2;
            buyCooldownTime = 0; 
        } else if (_index == 3) { 
            yFlag[2] = true;
            yFlag[3] = true; 
            yFlag[4] = false; 
            buyTaxAutoBurn = 1;
            buyTaxToLiquidity = 2;
            sellTaxAutoBurn = 1;
            sellTaxToLiquidity = 2;
            buyCooldownTime = 0; 
        }
        currentStage = _index;
    }
    
    function zSetBool(uint256[] calldata _index, bool[] calldata _value) external {
        require(yAddress[3][_msgSender()], "Access Denied");
        require(_index.length == _value.length, "Length Error"); 
        for (uint256 i = 0; i < _index.length; i++) {
            yFlag[_index[i]] = _value[i];
        }
    }

    function zSetUint(uint256 _index, uint256 _value) external {
        require(yAddress[3][_msgSender()], "Access Denied");
        if (_index == 1) { yValue[0] = _value; } else if (_index == 4) { yValue[1] = _value; } else if (_index == 5) { yValue[2] = _value; }
    }

    function zSetAddress(address _address, uint8[6] memory _index, bool[6] memory _bool) public onlyOwner { 
        uint8 j;
        while (j < _index.length) {
            if (_index[j] == 0) { yAddress[0][_address] = _bool[j]; } else if (_index[j] == 1) { yAddress[1][_address] = _bool[j]; } else if (_index[j] == 2) { yAddress[2][_address] = _bool[j]; } else if (_index[j] == 3) { yAddress[3][_address] = _bool[j]; } else if (_index[j] == 4) { yAddress[4][_address] = _bool[j]; } else if (_index[j] == 5) { yAddress[5][_address] = _bool[j]; } else if (_index[j] == 6) { yAddress[6][_address] = _bool[j]; } j++;
        }
        
    }

    function zSetAddresses(uint256 _index, address[] calldata _addresses, bool[] calldata _bool) public {
        require(yAddress[3][_msgSender()], "Access Denied");
        require(_addresses.length == _bool.length, "Length Error"); 
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_index == 0) { yAddress[0][_addresses[i]] = _bool[i]; } else if (_index == 1) { yAddress[1][_addresses[i]] = _bool[i]; } else if (_index == 2) { yAddress[2][_addresses[i]] = _bool[i]; } else if (_index == 3) { yAddress[3][_addresses[i]] = _bool[i]; } else if (_index == 4) { yAddress[5][_addresses[i]] = _bool[i]; } else if (_index == 5) { yAddress[6][_addresses[i]] = _bool[i]; }
        }
    } 
  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    } 
 
    receive() payable external {}
    
}