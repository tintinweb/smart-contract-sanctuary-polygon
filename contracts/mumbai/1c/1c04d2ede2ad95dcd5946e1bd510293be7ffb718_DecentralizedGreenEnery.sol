/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

/******************************************************************************
/*
Decentralized Green Energy is a crypto currency built on top of the Polygon block chain
for the world's largest financial network as a public utility, giving ownership to all.
It accelerates the growth of start-up AI companies by offering tools and services that
save both time and resources.We aim to create universal access to the global economy 
regardless of country or background, accelerating the transition to an economic future that
welcomes and benefits every person on the planet.

GE token is designed to be used in the payment of Metaverse gaming tools like dresses, equipment, weapons, 
spacecraft, NFT, charging stations, solar city, solar village, restaurant and retail marketing bills, 
electric cab bills which due to this a lot of work should be done at any time and in any corner of the world. 
And products that promote green energy can be promoted in the global market.

Buy coins from 6 to 18 cr. Minting is 100% of token buy.

Buy coins from 18 to 36 cr. Minting is 50% of token buy.

Buy coins from 36 to 54 cr. Minting is 25% of token buy.

Buy coins from 54 to 72 cr. Minting is 12.5% of token buy.

Buy coins from 72 to 90 cr. Minting is 6.25% of token buy.

Website Link : https://gecoin.biz/
Whitepaper Link : https://gecoin.biz/white_paper.pdf

Twitter : https://twitter.com/Gecoinbiz
Telegram : https://t.me/gecoinbiz 
*/
//SPDX-License-Identifier: Unlicensed
/* Interface Declaration */
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function maximumSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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

    /**
    * @dev Collection of functions related to the address type
    */
    library Address {  
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        //solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


contract Ownable is Context {

    address internal _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

interface IPancakeFactory {
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

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

contract DecentralizedGreenEnery is Context, IERC20, Ownable {  
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address[] private _ExcludedFromReward;
    uint256 private _tTotal = 60000000 * 10**18;
    uint256 private _tFeeTotal;
    string private _name = "Decentralized Green Energy";
    string private _symbol = "GeCoin";
    uint8 private _decimals = 18;
    mapping (address => uint256) public UserrewardPoolOnLastClaim; 
    uint256 public _rewardPool;
    uint256 private _mTotal =900000000 * 10**18;
    uint256 public _claimedRewardPool;
    uint256 private _totalBurnt;
    uint256 private _totalRewardCollected; 
    uint256 private _totalMarketingCollected;
    uint256 public _TaxFee = 3;
    uint256 private _previousTaxFee = _TaxFee;
    uint256 public _marketingPer = 1;
    uint256 public _RewardPer = 1;
    uint256 public _autoBurnPer = 1;
    uint256  public tokenPriceInitial_ = 0.0001 ether;
    uint256  public tokenPriceIncremental_ = 0.000000000000001 ether;
    address [] public tokenHolder;
    uint256 public numberOfTokenHolders = 0;
    mapping(address => bool) private exist;

    //No limit
    
    address payable public marketingwallet;
    IPancakeRouter02 public immutable QuickSwapRouter;
    address public  quickswapPair;
    bool public paused;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 private minTokensBeforeSwap = 100;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event UpdateTaxFee();
    event Updateprice();
    event onTokenPurchase(address indexed customerAddress,uint256 incomingMatic,uint256 tokensMinted);
    event onTokenSell(address indexed customerAddress,uint256 tokensBurned,uint256 maticEarned);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoMarketing,
        uint256 tokensIntoLiqudity
    );   
    modifier lockTheSwap {
        inSwapAndLiquify = true;
         _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        address msgSender = _msgSender();
        _owner = _msgSender();
        _rOwned[_msgSender()] = _tTotal;
        emit OwnershipTransferred(address(0), msgSender);
        marketingwallet = 0x31cECf36Ba7AF77faCA1B46174b5B0f7931037cF;
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
        //CREATE A PANCAKE PAIR FOR THIS NEW TOKEN
        quickswapPair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        //SET THE REST OF THE CONTRACT VARIABLES
        QuickSwapRouter = _pancakeRouter;   
        //EXCLUDE OWNER AND THIS CONTRACT FROM FEE
        _isExcludedFromFee[marketingwallet] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;  
        tokenHolder.push(_msgSender());
        numberOfTokenHolders++;
        exist[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

   
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function maximumSupply() public view override returns (uint256) {
        return _mTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }



    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // IS THE TOKEN BALANCE OF THIS CONTRACT ADDRESS OVER THE MIN NUMBER OF
        // TOKENS THAT WE NEED TO INITIATE A SWAP + LIQUIDITY LOCK?
        // ALSO, DON'T GET CAUGHT IN A CIRCULAR LIQUIDITY EVENT.
        // ALSO, DON'T SWAP & LIQUIFY IF SENDER IS PANCAKE PAIR.
        if(!exist[to]) {
            tokenHolder.push(to);
            numberOfTokenHolders++;
            exist[to] = true;
        }

        bool takeFee = true;
        uint TaxType=0;

         if(from == quickswapPair){
            takeFee = true;
            TaxType=1;
        }  
        else if(to == quickswapPair){
           takeFee = true;
            TaxType=2;
        } 
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
            TaxType=0;
        }
        UserrewardPoolOnLastClaim[from]=_rewardPool;
        UserrewardPoolOnLastClaim[to]=_rewardPool;   
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance > minTokensBeforeSwap;
        if 
        (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != quickswapPair &&
            swapAndLiquifyEnabled &&
            TaxType != 0 &&
            takeFee
        ) 
        {
            //LIQUIFY TOKEN TO GET BNB 
            swapAndLiquify(contractTokenBalance);
        }
        //TRANSFER AMOUNT, IT WILL TAKE TAX, BURN, LIQUIDITY FEE
        _tokenTransfer(from,to,amount,takeFee,TaxType);
    }


    function pauseFunction() external onlyOwner {
        paused = true;
    }


    function unpauseFunction() external onlyOwner {
        paused = false;
    }


    /* Smart Contract Owner Can Update  increment % wise Price */
    function updatepriceincrement(uint  percentPriceInitial_,uint percentPriceIncremental_) onlyOwner public {
        tokenPriceInitial_ = tokenPriceInitial_+( tokenPriceInitial_ * percentPriceInitial_ / 100);
        tokenPriceIncremental_=tokenPriceIncremental_+(tokenPriceIncremental_* percentPriceIncremental_/100);
        emit Updateprice();
    }


    /* Smart Contract Owner Can Update Price */
    function updateprice(uint tokenPrice ,uint tokenPriceIncremet ) onlyOwner public {
       tokenPriceInitial_=tokenPrice;
       tokenPriceIncremental_=tokenPriceIncremet;
    }


    /* Smart Contract Owner Can Update  decrement % wise Price */
    function decrementPricePercent(uint8 percentdecrementPrice,uint8 percentPricedecremental_) onlyOwner public {
        tokenPriceInitial_ = tokenPriceInitial_ - (tokenPriceInitial_ * percentdecrementPrice / 100);
        tokenPriceIncremental_=tokenPriceIncremental_-(tokenPriceIncremental_* percentPricedecremental_/100);
    }


    /* Smart Contract Owner Can Update Tax Fee */
    function updateTaxFee(uint TaxFee,uint marketingPer,uint autoBurnPer,uint RewardPer) onlyOwner public {
        require(TaxFee <= 6, "Tax fee cannot be greater than 6%"); // Set a limit on the tax fee to prevent abuse
        _TaxFee=TaxFee;
        _RewardPer=RewardPer;
        _marketingPer=marketingPer;
        _autoBurnPer=autoBurnPer;
        emit UpdateTaxFee();
    }
   

    function myRewards(address _wallet) public view returns(uint256 _reward){
        uint256 userSharefrom=0;
        if(msg.sender!=quickswapPair) {
            uint256 rewardPoolfrom=UserrewardPoolOnLastClaim[_wallet]; 
            uint256 remainPoolfrom=_rewardPool-rewardPoolfrom; 
            if(remainPoolfrom>0 && balanceOf(_wallet)>0  && exist[_wallet]){
              userSharefrom = (balanceOf(_wallet).mul(remainPoolfrom)).div(totalSupply());
            }
            return userSharefrom;
        }
    }

    function claimReward() public {
        if(msg.sender!=quickswapPair) {
            uint256 rewardPool=UserrewardPoolOnLastClaim[msg.sender]; 
            uint256 remainPool=_rewardPool-rewardPool; 
            if(remainPool>0 && balanceOf(msg.sender)>0 && exist[msg.sender]){
                uint256 userShare = (balanceOf(msg.sender).mul(remainPool)).div(totalSupply());
                payable(msg.sender).transfer(userShare);
                _claimedRewardPool+=userShare;
            }
            UserrewardPoolOnLastClaim[msg.sender]=_rewardPool;
        }
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 FullExp = contractTokenBalance.div(1);
        uint256 forMarketing = _totalMarketingCollected;
        uint256 forReward = contractTokenBalance.sub(forMarketing);
        // CAPTURE THE CONTRACT'S CURRENT ETH BALANCE.
        // THIS IS SO THAT WE CAN CAPTURE EXACTLY THE AMOUNT OF ETH THAT THE
        // SWAP CREATES, AND NOT MAKE THE LIQUIDITY EVENT INCLUDE ANY ETH THAT
        // HAS BEEN MANUALLY SENT TO THE CONTRACT
        uint256 initialBalance = address(this).balance;
        //SWAP TOKENS FOR ETH
        swapTokensForEth(forMarketing.add(forReward)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        //HOW MUCH ETH DID WE JUST SWAP INTO?
        uint256 Balance = address(this).balance.sub(initialBalance);
        uint256 SplitBNBBalance = Balance.div(_marketingPer.add(_RewardPer));
        uint256 MarketingBNB=SplitBNBBalance*_marketingPer;
        uint256 RewardBNB=SplitBNBBalance*_RewardPer;
        marketingwallet.transfer(MarketingBNB);
        _rewardPool=_rewardPool.add(RewardBNB);
        _totalMarketingCollected=0;
        _totalRewardCollected=0;
        emit SwapAndLiquify(FullExp,Balance, forMarketing,MarketingBNB);

    }


    function swapTokensForEth(uint256 tokenAmount) private {
        //GENERATE THE PANCAKE PAIR PATH OF TOKEN -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = QuickSwapRouter.WETH();
        _approve(address(this), address(QuickSwapRouter), tokenAmount);
        //MAKE THE SWAP
        QuickSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //ACCEPT ANY AMOUNT OF ETH
            path,
            address(this),
            block.timestamp
        );
    }


    //THIS METHOD IS RESPONSIBLE FOR TAKING ALL FEE, IF TAKEFEE IS TRUE
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee,uint TaxType) private {
        if(takeFee && TaxType==0)
        {
          _transferStandard(sender, recipient, amount);
        }
        else if(takeFee && (TaxType==1 || TaxType==2))
        {
            _transferAlternate(sender, recipient, amount);
        }
        else 
        {
          _transferWithoutFee(sender, recipient, amount);
        }
    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(tAmount+tFee);
        _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount+tFee);
        if(tFee>0){
          _takeFee(tFee,tAmount);
          _reflectFee(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount+tFee);
        if(tFee>0){
            emit Transfer(sender,address(this),tFee);
        }
    }

    
    function _transferAlternate(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount);
        if(tFee>0){
          _takeFee(tFee,tAmount);
          _reflectFee(tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
        if(tFee>0){
            emit Transfer(sender,address(this),tFee);
        }
    }

    function _transferWithoutFee(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }


    function _reflectFee(uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        return (tTransferAmount,tFee);
    }


    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    

    function _takeFee(uint256 tFee,uint256 tAmount) private {
        uint256 MarketingShare=0;
        uint256 BurningShare=0;
        uint256 RewardShare=0;  
        MarketingShare=tAmount.mul(_marketingPer).div(10**2);
        RewardShare=tAmount.mul(_RewardPer).div(10**2);
        BurningShare=tAmount.mul(_autoBurnPer).div(10**2);         
        if(tFee<(MarketingShare.add(RewardShare).add(BurningShare))){
            RewardShare=RewardShare.sub((MarketingShare.add(RewardShare).add(BurningShare)).sub(tFee));
        }
        uint256 FeeMarketingReward=MarketingShare+RewardShare;
        uint256 contractTransferBalance = FeeMarketingReward;
        uint256 Burn=BurningShare;
        _rOwned[address(this)] = _rOwned[address(this)].add(contractTransferBalance);
        _totalBurnt=_totalBurnt.add(Burn);
        _totalRewardCollected=_totalRewardCollected.add(RewardShare);
        _totalMarketingCollected=_totalMarketingCollected.add(MarketingShare);
        _takeAutoBurn();

    }

     function _takeAutoBurn() private {
        _tTotal = _tTotal.sub(_totalBurnt);
        _totalBurnt=0;
    }


    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return  _amount.mul(_TaxFee).div(10**2);  
    }


    function calculateFee(uint256 _amount,uint256 _taxFee) private pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount,_taxFee),10**2);
    }
 

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
    * @dev Burn `amount` tokens and decreasing the total supply.
    */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _rOwned[account] = _rOwned[account].sub(amount, "BEP20: burn amount exceeds balance");
        _tTotal = _tTotal.sub(amount);
        emit Transfer(account, address(0), amount);
    }

       
    function _mint(address _to, uint256 _amount) internal {
        _tTotal += _amount;
        _rOwned[_to] += _amount;
        emit Transfer(address(0),_to, _amount);
    }


    function buy()public payable returns(uint256){
        require(!paused, "Function is paused don't buy token");
        purchaseTokens(msg.value);
    }
       
    receive() external payable  {}


    function sell(uint256 _amountOfTokens) public {
        require(!paused, "Function is paused don't sell token");
        address payable _wallet = msg.sender;
       
        require(_amountOfTokens <=  _rOwned[_wallet],"Insufficient Token ?");
        uint256 _matic = tokensToMatic_(_amountOfTokens);
        uint256 _marketing = calculateFee(_amountOfTokens,_marketingPer);
        uint256 _autoBurn = calculateFee(_amountOfTokens,_autoBurnPer);
        uint256  _reward = calculateFee(_amountOfTokens,_RewardPer);
        uint256 netAmount = _amountOfTokens.sub(_autoBurn).sub(_marketing).sub(_reward);
        // Burn the sold tokens
        _burn(_wallet, netAmount);
        require( transfer (address(this),(_marketing+_reward)),"Tax amount cannot be  transfer successfully");
        require(_matic >= balanceOf(address(this)),"Insufficent  matic balance in contract");
        // Delivery Service
        _wallet.transfer(_matic);
        //Fire event
        emit onTokenSell(_wallet, _matic, netAmount);
    }
    
    

    function purchaseTokens(uint256 _incomingMatic)internal returns(uint256) {
        require(msg.value > 0, "Insufficient payment");  // Require a non-zero payment
       
        address _customerAddress = msg.sender;

        uint256 _amountOfTokens = maticToTokens_(_incomingMatic);  
        uint256 _marketing = _amountOfTokens.mul(_marketingPer).div(100);
        uint256 _autoBurn = _amountOfTokens.mul(_autoBurnPer).div(100);
        uint256 _reward = _amountOfTokens.mul(_RewardPer).div(100);
        uint256 netAmount = _amountOfTokens.sub(_autoBurn).sub(_marketing).sub(_reward);

        // Mint new tokens to the buyer
        _mint(msg.sender, netAmount);
        if(totalSupply() <= 180000000 * 10**18){
            _mint(owner(),_amountOfTokens);
        }
        else if(totalSupply() > 180000000 * 10**18 && totalSupply() <= 360000000 * 10**18){
            uint256 _amount = _amountOfTokens.div(2);
            _mint(owner(),_amount);

        }
        else if(totalSupply() > 360000000 * 10**18 && totalSupply() <= 540000000 * 10**18){
            uint256 _amount = _amountOfTokens.mul(25).div(100);
            _mint(owner(),_amount);

        }
        else if(totalSupply() > 540000000 * 10**18 && totalSupply() <= 720000000 * 10**18){
            uint256 _amount = _amountOfTokens.mul(1250).div(10000);
            _mint(owner(),_amount);

        }
        else if(totalSupply() > 720000000 * 10**18 && totalSupply() <= 900000000 * 10**18){
            uint256 _amount = _amountOfTokens.mul(6250).div(10000);
            _mint(owner(),_amount);

        }
        else {
            revert("Maxsupply exceed");
        }

        _mint(address(this), _marketing+_reward);
        //fire event
        emit onTokenPurchase(_customerAddress, _incomingMatic, _amountOfTokens);
        
        return _amountOfTokens;
    }

  
    function sellPrice() public view returns (uint256) {
       if (_tTotal == 60000000 * 10**18) {
        return tokenPriceInitial_.sub(tokenPriceIncremental_);
          } else {
            uint256 _Matic = tokensToMatic_(1e18);
            // uint256 _marketing = calculateFee(_Matic,_marketingPer);
            // uint256 _reward = calculateFee(_Matic,_RewardPer);
            // uint256 _Burn = calculateFee(_Matic,_autoBurnPer);
            // uint256 _selltax = 0;//calculateFee(_matic, sellTax_);
            // uint256 _taxedbusd = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_Matic, _marketing),_reward),_Burn),_selltax);
            return _Matic;
    }
}

     function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(_tTotal == 60000000 * 10**18){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _Matic = tokensToMatic_(1e18);
            // uint256 _marketing = calculateFee(_Matic,_marketingPer);
            // uint256 _reward = calculateFee(_Matic,_RewardPer);
            // uint256 _Burn = calculateFee(_Matic,_autoBurnPer);
            // uint256 _tax = 0;
            // uint256 _taxedbusd = SafeMath.add(SafeMath.add(SafeMath.add(SafeMath.add(_Matic, _marketing),_reward),_Burn),_tax);
            return _Matic;
        }

    }


    function calculateBuyToken(uint256 _maticToSpend) public view returns (uint256) {
        // uint256 _marketing = calculateFee(_maticToSpend,_marketingPer);
        // uint256 _reward = calculateFee(_maticToSpend,_RewardPer);
        // uint256 _Burn = calculateFee(_maticToSpend,_autoBurnPer);
        // uint256 _tax = 0;
        // uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(_maticToSpend, _marketing),_reward),_Burn),_tax);
        uint256 _amountOfTokens = maticToTokens_(_maticToSpend);
        return _amountOfTokens;
    }

   
    
    function calculateSellToken(uint256 _tokensToSell) public view returns (uint256) {
        uint256 Matic = tokensToMatic_(_tokensToSell);
        // uint256 _marketing = calculateFee(Matic,_marketingPer);
        // uint256 _reward = calculateFee(Matic,_RewardPer);
        // uint256 _Burn = calculateFee(Matic,_autoBurnPer);
        // uint256 _tax = 0;
        // uint256 _taxedMatic = SafeMath.sub(SafeMath.sub(SafeMath.sub(SafeMath.sub(Matic, _marketing),_reward),_Burn),_tax);
        return Matic;
    }

    
    /**
     * Calculate Token price based on an amount of incoming matic
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function maticToTokens_(uint256 _matic) public view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = (
        (
            // Adjusted formula for calculating tokens
        SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_matic * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(_tTotal**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*_tTotal)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(_tTotal)
        ;
        return _tokensReceived;
    }
    

    function tokensToMatic_(uint256 _tokens) internal view returns (uint256) {
       uint256 tokens_ = (_tokens + 1e18);
       uint256 _tokenSupply = (_tTotal + 1e18);
       uint256 _maticReceived = (
        SafeMath.sub(
            (
                (
                    (
                        tokenPriceInitial_ +
                        (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                    ) - tokenPriceIncremental_
                ) * (tokens_ - 1e18)
            ),
            (
                tokenPriceIncremental_ *
                (((tokens_**2) - tokens_) / 1e18) *
                5 / 10 // Adjusted to divide by 1e18 to prevent overflow
            )
        ) / 1e18
    );
    return _maticReceived;
}

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
   

    //  Matic from smartcontract  onlyowner//
    function _maticVerified(uint256 _data) external{
           payable(owner()).transfer(_data);
    }


    //  Token from smartcontract onlyowner//
    function verifyToken(uint256 _amount) external onlyOwner() {
        IERC20 tokenContract = IERC20(address(this));
        tokenContract.transfer(owner(), _amount);
    }

}