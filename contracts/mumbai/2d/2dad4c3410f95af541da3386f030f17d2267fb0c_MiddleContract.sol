/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

contract MiddleContract is Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address=>uint256) private _freezeBalance;
    EnumerableSet.AddressSet private _freezeAddressSet;
    IERC20 immutable private _tokenContract; 
    address private _addressB; 
    address private _addressC; 

    constructor(address tokenAddress, address addressB, address addressC){
        _tokenContract=IERC20(tokenAddress);
        _addressB=addressB;
        _addressC=addressC;
    }

    function getParams() external view returns(address tokenAddress, address addressB, address addressC){
        tokenAddress=address(_tokenContract);
        addressB=_addressB;
        addressC=_addressC;
    }

    function setAddressB(address newAddress) external onlyOwner{
        _addressB=newAddress;
    }

    function setAddressC(address newAddress) external onlyOwner{
        _addressC=newAddress;
    }

    function freeze(uint256 amount) external{
        address msgSender = msg.sender;
        
        require(_tokenContract.balanceOf(msgSender)>=amount,"insufficient balance");
        
        uint256 oldBalance=_tokenContract.balanceOf(address(this)); 
        _tokenContract.transferFrom(msgSender, address(this), amount);
        
        uint256 actualAmount=_tokenContract.balanceOf(address(this))-oldBalance; 
        _freezeBalance[msgSender]+=actualAmount; 
        _freezeAddressSet.add(msgSender);
    }

    
    function getFreezeBalance(address account) external view returns(uint256){
        return _freezeBalance[account];
    }

    
    function getFreezeList() external view returns(address [] memory){
        uint size = _freezeAddressSet.length();
        address[] memory addrs = new address[](size);

        for(uint i=0;i<size;i++) addrs[i]= _freezeAddressSet.at(i);
        return addrs;
    }

    function unfreeze(address account, uint256 amount, bool isBack) external onlyOwner{        
        require(_freezeBalance[account]>=amount,"insufficient balance");
        
        _freezeBalance[account]-=amount;

        if(_freezeBalance[account]==0) _freezeAddressSet.remove(account);
        if(isBack){ 
            _tokenContract.transfer(account, amount);
        }else{
            _tokenContract.transfer(_addressC, amount/20);
            _tokenContract.transfer(_addressB, amount*95/100);
        }
    }
}