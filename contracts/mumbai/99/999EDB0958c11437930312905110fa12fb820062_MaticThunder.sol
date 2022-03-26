/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED"

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

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract MaticThunder is Ownable{
    
 	using SafeMath for uint256;
    
    address payable private adminAccount_;
    
    event Registration(string  waddress,address investor,uint256 referrerId,uint256 package);
    event Deposit(address investor,string investorId,uint256 package,string invest_type);
    event MemberPayment(uint256 amount,address  waddress,uint256 withId);
    event withdrawal(uint256 amount,address  waddress);
    event Payout(uint256 amount);
  
    constructor(address payable _admin)  
    {
	    adminAccount_=_admin;
    }

    function MaticFromBalance(address payable _sender,uint256 _amt) public onlyOwner {
        require(owner()==_msgSender(),"Only Owner");
        _sender.transfer(_amt);
    }
  
    function getBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }

    function multisendOwner(address payable[]  memory  _contributors, uint256[] memory _balances) public payable onlyOwner{
        require(owner()==_msgSender(),"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);            
        }
    }

	  function withdrawAdmin() public onlyOwner {
		
			adminAccount_.transfer(address(this).balance);
		}
  
    function UserRegister( string memory _user,uint256 _referrerCode,uint256 package) public payable
    {  

        require(msg.value==package,"Invalid Amount");
	    payable(owner()).transfer(address(this).balance);
        emit Registration(_user,msg.sender,_referrerCode,msg.value);
    }

    function reinvest(string memory investorId,uint256 package) public payable
    {
        require(msg.value==package,"Invalid Amount");
		payable(owner()).transfer(address(this).balance);
  	    emit Deposit(msg.sender,investorId,msg.value,'REINVEST');
    }

    function multisendMatic(address payable[]  memory  _contributors, uint256[] memory _balances,uint256[] memory _withId) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
            emit MemberPayment(_balances[i],_contributors[i],_withId[i]);
        }
        emit Payout(total);
    }


    function withdrawIncome(address payable _sender,uint256 _uamt) public payable onlyOwner{
        require(owner()==_msgSender(),"Only Owner");
	    _sender.transfer(_uamt);
        emit withdrawal(_uamt,_sender);
    }

    function changeAdmin(address payable newAdmin) public payable onlyOwner{
        require(owner()==_msgSender(),"Only Owner");
        adminAccount_= newAdmin;
    }
}