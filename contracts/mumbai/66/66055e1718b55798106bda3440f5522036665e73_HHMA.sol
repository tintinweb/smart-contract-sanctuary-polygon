pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC20Auction {
    function transfer(address recipient, uint256 amount) external returns (bool ok);
	function transferFrom(address from, address to, uint256 value) external returns (bool ok);
}

contract HHMA is Ownable{

    using SafeMath for uint256;
	
    string public _name = "HHM Auction";
    string public _symbol = "HHMA";

    uint public _tokenID = 0;
    address public _lastBidder = address(0);
    uint256 public _lastBidAmt = 0;
    
    function setTokenID(uint tokenid) public onlyOwner{
        _tokenID = tokenid;
    }

	function bid(ERC20Auction token, uint256 amount) public{
        _refund(token);
        token.transferFrom(msg.sender, address(this), amount);
        _lastBidder = msg.sender;
        _lastBidAmt = amount;
    }
	
    function _refund(ERC20Auction token) internal {
        if(_lastBidAmt != 0 && _lastBidder != address(0)){
            token.transfer(_lastBidder, _lastBidAmt);
        }
    }

    function withdrawTokenToAll(ERC20Auction token, address[] memory _to, uint256[] memory _value) public onlyOwner returns(bool){
		require(_to.length == _value.length);
		for (uint8 i = 0; i < _to.length; i++) {
			token.transfer(_to[i], _value[i]);
		}
        return true;
    }
}