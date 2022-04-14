/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

/**
   https://gigahashgaming.com/
   https://t.me/GigaHashGaming
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

contract VRFRequestIDBase {
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
  
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract GigaHash is Context, IERC20, Ownable, VRFConsumerBase{
    using SafeMath for uint256;
    using Address for address;

    address payable public treasureyAddress;
    address payable public devAddress;
    address deadAddress = 0x0000000000000000000000000000000000000777; // This is the lottery address
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blacklist;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private  _tTotal = 10000000000  * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private  _name = "GigaHash Gaming";
    string private  _symbol = "GHG";
    uint8 private  _decimals = 9;

    uint256 public _burnFee = 2; // Lottery Burn
    uint256 private _previousburnFee = _burnFee;
    uint256 public _taxFee = 2; // Reflection
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 2; // Dev / Marketing
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _maxTxAmount = 10000000000 * 10**9;

    //Lottery Decs
    event Winner(address indexed _addr, uint256 _value);
    event Total_Fees(address _from, uint256 amount_of_fees);
    uint256 public btimes = 0;
    uint256 public btimem = 0;
    uint256 public btimel = 0;
    bool public _lottery_off;
    uint256 public min_token;  // Amount of tokens to buy a ticket
    address public lastwinner; // Last winner
    address[] private players; // Total number of lottery players
               
    uint256 winsmall = 300000 * 10**9;  //Set the winning amounts for lotteries, remember we have to add 9 digits after the decimal
    uint256 winmed = 1500000 * 10**9;
    uint256 winlarge = 10000000 * 10**9;
    IERC20 public GHG_ticket;

    //Chainlink Decs
    // variables
    bytes32 private s_keyHash;
    uint256 private s_fee;
    event Lottery_Triggered(bytes32 indexed requestId);
    event Lottery_Random(uint256 randomness);
    bytes32 _requestId;

    constructor () 
    VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) // VRF and then LINK Token
    {
        _rOwned[_msgSender()] = _rTotal.div(100).mul(40);
        _rOwned[deadAddress] = _rTotal.div(100).mul(60);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadAddress] = true;
        treasureyAddress = payable(0xfa5a5Fae27Be9F41454F2c6e21Fa2A1C2f398A44);
        devAddress = payable(0x8A1c2FE7f7502a88cE44Fbce45aA5A7D1C5D5D36);

        _lottery_off = true;
         min_token = 10000 * 10**9;  // For lottery
        //Sets initial jackpot times
         btimel = block.number + 262957;
         btimem = block.number + 37565;
         btimes = block.number + 6261;
         GHG_ticket =IERC20(0xED1b0F7d8859B6405DE959Cfa821301E18d21aF1);

        s_keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        s_fee = 100000000000000;

        emit Transfer(address(0), _msgSender(), _tTotal.mul(40).div(100));
        emit Transfer(address(0), deadAddress, _tTotal.mul(60).div(100));

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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function balanceOf777() public view returns (uint256) {
        if (_isExcluded[deadAddress]) return _tOwned[deadAddress];
        return tokenFromReflection(_rOwned[deadAddress]);
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

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _blocktime() public view returns (uint256) {
           return uint(block.number);
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
        require(_blacklist[from] != true,"This Wallet Is Black Listed");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
        lottery();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee(); 
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity,tAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity,tAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity,tAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity,tAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256 ,uint256, uint256) {
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
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 _amount) private {
        uint256 currentRate =  _getRate(); 
        uint256 tliqfee = _amount.mul(_liquidityFee).div(10**2);
        uint256 rLiquidity = tliqfee.mul(currentRate);
        uint256 rLiquidity2 = tliqfee.mul(currentRate);

        _rOwned[address(treasureyAddress)] = _rOwned[address(treasureyAddress)].add(rLiquidity).div(2);
        if(_isExcluded[address(treasureyAddress)])
           {_tOwned[address(treasureyAddress)] = _tOwned[address(treasureyAddress)].add(tliqfee).div(2);}

        _rOwned[address(devAddress)] = _rOwned[address(devAddress)].add(rLiquidity2).div(2);
        if(_isExcluded[address(devAddress)])
           {_tOwned[address(devAddress)] = _tOwned[address(devAddress)].add(tliqfee).div(2);}
            
        uint256 tburn = tLiquidity - tliqfee;
        uint256 rburn = tburn.mul(currentRate);
        _rOwned[address(deadAddress)] = _rOwned[address(deadAddress)].add(rburn);
        if(_isExcluded[address(deadAddress)])
           {_tOwned[address(deadAddress)] = _tOwned[address(deadAddress)].add(tburn);}
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256 _totalamount) {
        uint256 liqfee = _amount.mul(_liquidityFee).div(10**2);
        uint256 cbfee = _amount.mul(_burnFee).div(10**2);
        return _totalamount.add(liqfee).add(cbfee);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousburnFee = _burnFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousburnFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

             ////////////////////////////////////////////////
            ////////The Lottery Function////////////////////
           ////////////////////////////////////////////////

    function lottery() internal {
        if (!_lottery_off)    // Emergency function to turn lottery off
            {
            require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");

            if (btimel < block.number||btimem < block.number||btimes < block.number) {
            bytes32 requestId = requestRandomness(s_keyHash, s_fee);
            emit Lottery_Triggered(requestId);
            }        
        }
    }

    function lotterytest() external onlyOwner() {
            require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
            bytes32 requestId = requestRandomness(s_keyHash, s_fee);
            emit Lottery_Triggered(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit Lottery_Random(randomness);
        if (!_lottery_off)    // Emergency function to turn lottery off
            {
            //Priority to pay large lotteries first then smaller ones
            //We dont want to pay all three at once
            //Check block time to see if it is time to pay a winner yet
            //If time to pay, select winner and pay them
            _requestId = requestId;

            if (btimel < block.number) {
            address winner = _pickWinner(randomness);
                emit Winner(winner, winlarge);
                _tokenTransfer(deadAddress, winner, winlarge,false);
                btimel = block.number + 262957;
                lastwinner = winner;
            }

            else if (btimem < block.number) {
            address winner = _pickWinner(randomness);
                emit Winner(winner, winmed);
                _tokenTransfer(deadAddress, winner, winmed,false);
                btimem = block.number + 37565;
                lastwinner = winner;
            }

            else if (btimes < block.number) {
            address winner = _pickWinner(randomness);
                emit Winner(winner, winsmall);
                _tokenTransfer(deadAddress, winner, winsmall,false);
                btimes = block.number + 6261;
                lastwinner = winner;

            }
        }
    }
    
    //Add chain gateway stuff here
    function _pickWinner(uint256 randomness) internal view returns (address winner) { 
         uint listnumber=(randomness % getEntityCount()) + 1; 
         // We pick the winner, then look up the ticket owners address in array. 
         winner = getwinner(listnumber); 
    }

    // Thanks for the gifting idea Liam
    function buy_ticket(address _toaddress, uint256 _amount) external {
        require(balanceOf(msg.sender) > min_token.mul(_amount), "Not Enough Tokens To Purchase Ticket");
        require(_amount != 0, "You need to buy atleast 1 ticket!");
        _tokenTransfer(msg.sender,deadAddress,min_token.mul(_amount),false); //false for no fees
        //Loop the newentity function to add each ticket into the ticket list
        uint256 i = _amount; // i is total tickets to add for that address
        do{
            _newEntity(_toaddress); //Add the address to the tickets list
            i = i.sub(1); //Each time a ticket is added reduce remaining tickets to add by 1
            }
        while(i > 0);
        //Once there are no more ticket to add then continue
        GHG_ticket.transfer(_toaddress, (_amount* 10**9)); //Send them the tickets
        return;
    }
    
    //////// End Lottery Stuff/////////////

    function _newEntity(address entityAddress) internal returns(bool success) {
        players.push(entityAddress);
        return true;
    }

    function getwinner(uint i) internal view returns (address) {
        return players[i];
    }

    function getEntityCount() public view returns(uint entityCount) {
            return players.length;
    }

    function getArr() public view returns (address[] memory) {
        return players;
    }

    function isEntity(address entityAddress) public view returns(bool) {
          uint256 i = 0;
          do{
              if( players[i] == entityAddress)
                  { return true; }
              else {i++;}
            }
          while( i <= players.length.sub(1));
          return false;
    }

    // Management Functions ***Owner Only*** //

    function pauselottery(bool lottery_off) external onlyOwner() {
          _lottery_off = lottery_off;
    }

    function set_min_token(uint256 _min_token) external onlyOwner() {
          min_token = _min_token;     //For Lottery Tickets
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setFees(uint256 burnfee, uint256 taxfee, uint256 liquidityFee) external onlyOwner() {
        _burnFee = burnfee;
        _previousburnFee = _burnFee;
        _taxFee = taxfee;
        _liquidityFee = liquidityFee;
    }

    function overridelotteryblock(uint256 _btimes, uint256 _btimem, uint256 _btimel)external onlyOwner() {
        btimes = _btimes;
        btimem = _btimem;
        btimel = _btimel;
    }
    
    function overridelotterysize(uint256 _winsmall, uint256 _winmed, uint256 _winlarge)external onlyOwner() {
        winsmall = _winsmall;  
        winmed = _winmed;
        winlarge = _winlarge;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function setMarketingAddress(address _treasureyAddress, address _devAddress) external onlyOwner() {
        treasureyAddress = payable(_treasureyAddress);
        devAddress = payable(_devAddress);
    }

    function set_blacklist(address account, bool active) public onlyOwner() {
        _blacklist[account] = active; // True = blacklisted
    }

    //If idiots accidentlly send Eth or GHG to contract use these functions to remove it so we can return to the idiots
    function removeETH(uint256 amount) external onlyOwner() {
        treasureyAddress.transfer(amount);
    }

    function removeGHG(uint256 total) external onlyOwner() {
        bool takeFEE = false;
        _tokenTransfer(address(this),treasureyAddress,total,takeFEE);
    }
}