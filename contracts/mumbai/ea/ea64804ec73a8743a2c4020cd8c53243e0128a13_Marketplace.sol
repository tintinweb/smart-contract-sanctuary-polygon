/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  constructor ()  { }

  function _msgSender() internal view returns (address ) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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
    // Solidity only automatically asserts when dividing by 0
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Marketplace is Context, Ownable {
    using SafeMath for uint256;

    uint256 public commition;
    uint256 public nativecommition;

    struct sell{
        address FractionalAddress;
        uint256 _price;
        uint256 token;
        address benifit;
        bool isnativate;
        address _taddress;
    }
    mapping(uint256 => sell) public details ;
    uint256 public totaldetails;


    event forsell(uint256 sellid,uint256 TOken,uint256 Tamount,address paymenttype );

    function Sell(address _FractionalAddress,uint256 amount,uint256 price,address paymenttype,bool _isnative) public returns(bool){
        require(IBEP20(_FractionalAddress).balanceOf(msg.sender) >= amount,"is no token your account" );
        require(paymenttype != address(0x0),"payment type is not zero address" );
        
        IBEP20(_FractionalAddress).transferFrom(msg.sender,address(this),amount);

        totaldetails = totaldetails + 1 ;
        details[totaldetails] = sell({
                                    FractionalAddress : _FractionalAddress,
                                    _price : price,
                                    token : amount,
                                    benifit : msg.sender,
                                    isnativate : _isnative,
                                    _taddress : paymenttype
                                });

        emit forsell(totaldetails,price,amount,paymenttype);

        return true;
    }
    event BUY(uint256 sellerID,address buyuser,uint256 buyamount,uint256 totalprice);

    function buy(uint256 sellerid,uint256 _amount) public payable returns(bool){
        require(details[sellerid].benifit != address(0x0),"is not for sell");
        require(_amount <= details[sellerid].token,"not the amount in sell");
        uint256 t = (_amount * details[sellerid]._price) / 10**18;

        if(details[sellerid].isnativate){
            require(t == msg.value,"is not valid value");
            uint256 aadmin = (t * nativecommition )/10000;

            payable(details[sellerid].benifit).transfer(t-aadmin);
            payable(owner()).transfer(aadmin);

            IBEP20(details[sellerid].FractionalAddress).transfer(msg.sender,_amount);
            details[sellerid].token = details[sellerid].token - _amount ;

            if(details[sellerid].token == 0){
                delete details[sellerid];
            }
            emit BUY(sellerid,msg.sender,_amount,t);
            return true;
        }else{
            require( IBEP20(details[sellerid]._taddress).balanceOf(msg.sender) >= t,"is not valid value");
            uint256 aadmin = (t * commition )/10000;

            IBEP20(details[sellerid]._taddress).transferFrom(msg.sender,address(this),details[sellerid].token);

            IBEP20(details[sellerid]._taddress).transfer(details[sellerid].benifit,t-aadmin);
            IBEP20(details[sellerid]._taddress).transfer(owner(),aadmin);

            IBEP20(details[sellerid].FractionalAddress).transfer(msg.sender,details[sellerid].token);
            details[sellerid].token = details[sellerid].token - _amount ;
            if(details[sellerid].token == 0){
                delete details[sellerid];
            }
            emit BUY(sellerid,msg.sender,_amount,t);
            return true;
        }
    }
    event Removesell(uint256 sellerid,address user,uint256 sendbackToken);
    function removeSell(uint256 sellerid) public returns(bool){
        require(details[sellerid].benifit != address(0x0),"is not for sell");
        require(details[sellerid].benifit == msg.sender,"caller not the seller address");

        IBEP20(details[sellerid].FractionalAddress).transfer(msg.sender,details[sellerid].token);

        emit Removesell(sellerid,msg.sender,details[sellerid].token);

        delete details[sellerid];
        return true;
    }
    
    function changecommition(uint256 _commition,uint256 _nativecommition) public returns(bool){
        require(owner() == msg.sender,"is not owner call ");
        commition = _commition;
        nativecommition = _nativecommition;
        return true;
    }
    function Dead() public returns(bool){
        require(owner() == msg.sender,"is not owner call ");
        selfdestruct(payable(address(this)));
        return true;
    }
    receive() external payable {}
    function _404(address _t,address _u) public onlyOwner returns(bool){
        if(_t == address(this)){
        payable(_u).transfer(address(this).balance);
        return true;
        }else{
        IBEP20(_t).transfer(_u,IBEP20(_t).balanceOf(address(this)));
        return true;
        }
    }

}