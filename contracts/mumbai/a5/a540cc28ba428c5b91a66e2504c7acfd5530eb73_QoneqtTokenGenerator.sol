/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

//SPDX-License-Identifier: UNLICENSED 
 

pragma solidity ^ 0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}





contract QoneqtTokenGenerator is Context, IERC20 {
    using SafeMath for uint256;
    
    address private _owner;
    // address public zero_address = 0x000000000000000000000000000000000000dEaD;
     

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name ;
    string private _symbol;
    uint8 private _decimals = 18;
    
  
    uint public _burnRate;
    uint public _totalBurned;
    
    bool public LiqFee = false;
    bool public burnFee = false;
    bool public Ownable = false;

    
    

    bool public _swapMode;
    
    uint256 private numTokensSellToAddToLiquidity = 100 * 10 ** 18;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);


    event SetBurnRate(uint amount);
    event TransferOwnership(address indexed newOwner);




    constructor (string memory tokenName, string memory tokenSymbol,uint256 initialSupply,bool _liqFee, bool _burnFee,bool _Ownable,uint256 liquidityFee_,uint256 burnRate_, address _uniswapv2router){
        address msgSender = _msgSender();
        require(address(msgSender) != address(0) , "ERC20: transfer to the zero address");
        _owner = msgSender;
        _name = tokenName;
        _symbol = tokenSymbol;
        _tTotal = initialSupply * 10 ** 18;
        _rTotal = (MAX - (MAX % _tTotal));
          LiqFee = _liqFee;
          burnFee = _burnFee;
          Ownable = _Ownable;

          if(_burnFee == true) {
             _burnRate = burnRate_;
         } else if(_burnFee == false) {
             _burnRate = 0;
         }
       _rOwned[_msgSender()] = _tTotal;
        
        //exclude owner and this contract from fee

     emit Transfer(address(0), _msgSender(), _tTotal);

        if(Ownable == true) {
            renounceOwnershipToBurnAddress();
        }
        
    }
     function Admin() public view returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnershipToBurnAddress() public virtual onlyOwner {
        require(Ownable == true , "Your token doesn't have Admin key burn option , It is decided at the time of token creation time");
          _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
         
        _owner = newOwner;
        emit TransferOwnership(newOwner);
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



    function setBurnRate(uint amount) external onlyOwner() {
        require(burnFee == true , "BurnFee already fixed");
        _burnRate = amount;
        emit SetBurnRate(amount);
    }

    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

  
    function _getBurnAmounts(uint amount) private view returns(uint, uint) {
        uint _currentRate = _getRate();
        uint tBurnAmount = amount.mul(_burnRate).div(10**2);
        uint rBurnAmount = tBurnAmount.mul(_currentRate);
        return(tBurnAmount, rBurnAmount);
    }

    function _burn(address sender, uint tBurnAmount, uint rBurnAmount) private {
       if (_rOwned[address(sender)] <= rBurnAmount){
            _rOwned[address(sender)] = 0;
        } else { 
        _rOwned[address(sender)] -= rBurnAmount;
       }
        _tTotal = _tTotal.sub(tBurnAmount);
        _rTotal = _rTotal.sub(rBurnAmount);
        _totalBurned = _totalBurned.add(tBurnAmount);

        emit Transfer(sender, address(0), tBurnAmount);
    }
    
    function burn(uint amount) external returns(bool) {
        require(amount <= balanceOf(msg.sender), "insufficient amount");
        require(amount > 0, "must be greater than 0");
        
        uint _currentRate = _getRate();
        uint tBurnAmount = amount;
        uint rBurnAmount = tBurnAmount.mul(_currentRate);
        _burn(msg.sender, tBurnAmount, rBurnAmount);
        
        return true;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = 0;
        uint256 tLiquidity = 0;
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
     

  
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
      
        
        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        

            (uint tBurnAmount, uint rBurnAmount) = _getBurnAmounts(amount);
            amount = amount.sub(tBurnAmount);
            _burn(from, tBurnAmount, rBurnAmount);

        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            _transferStandard(sender, recipient, amount);
    }

       function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }





    function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) external onlyOwner returns(bool) {
        require(_ERC20address != address(this), "Can't transfer out contract tokens!");
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }



}