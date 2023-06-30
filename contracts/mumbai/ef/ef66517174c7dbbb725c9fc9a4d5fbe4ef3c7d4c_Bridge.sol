/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Bridge is Ownable {

    mapping(address => bool) public isOperator;

    event DepositEvent(address User, address TokenAddress, uint TokenAmount, uint DepositTime);
    event WithdrawEvent(address User, address TokenAddress, uint TokenAmount, uint WithdrawTime);

    constructor() {
        isOperator[msg.sender] = true;
    }

    function deposit(address _tokenAddress, uint _amount) external payable {
        if(_tokenAddress == address(0x0)){
            require(msg.value == _amount,"invalid coin amount");
        } else {
            IBEP20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);
        }

        emit DepositEvent(_msgSender(), _tokenAddress, _amount, block.timestamp);
    }

    function withdraw(address _tokenAddress,address _receiver, uint _amount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_receiver).send(_amount),"coin transfer failed");
        } else {
            IBEP20(_tokenAddress).transfer(_receiver, _amount);
        }

        emit WithdrawEvent(_msgSender(), _tokenAddress, _amount, block.timestamp);
    }

    function setOperator(address _account, bool _status) external onlyOwner {
        isOperator[_account] = _status;
    }

    
}