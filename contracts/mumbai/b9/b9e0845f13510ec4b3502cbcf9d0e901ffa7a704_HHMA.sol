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

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) _balances;

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function refund(address recipient, uint256 amount) public returns (bool) {
        _transfer(address(this), recipient, amount);
        return true;
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
		
        emit Transfer(sender, recipient, amount);
    }
	
	function balanceOf(address bidder) public view returns (uint256) {
        return _balances[bidder];
    }
}

contract HHMA is ERC20Auction, Ownable{

    using SafeMath for uint256;
	
    string private _name = "HHM Auction";
    string private _symbol = "HHMA";

    uint private _tokenID = 0;
    address private _lastBidder = address(0);
    uint256 private _lastBidAmt = 0;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function getTokenID() public view returns (uint) {
        return _tokenID;
    }
    
    function setTokenID(uint tokenid) public{
        _tokenID = tokenid;
    }

    function getLastBidder() public view returns (address) {
        return _lastBidder;
    }

    function getLastBidAmt() public view returns (uint256) {
        return _lastBidAmt;
    }

    function setLastBidder(address bidder, uint256 amount) public{
        _lastBidder = bidder;
        _lastBidAmt = amount;
    }
	
	function bid(ERC20Auction token, address bidder, uint256 amount) public{
        _safeRefund(token);
        token.transfer(address(this), amount);
        setLastBidder(bidder, amount);
    }
	
    function _safeRefund(ERC20Auction token) internal {
        uint256 _bidAmt = getLastBidAmt();
        address _bidder = getLastBidder();
        require(_bidder != address(0), "Bidder: transfer from the zero address");
        require(_bidAmt != 0, "Amount cannot be zero");
        token.refund(_bidder, _bidAmt);
    }
	
    function withdrawTokenToAll(ERC20Auction token, address payable[] memory _to, uint256[] memory _value) public onlyOwner returns(bool){
		require(_to.length == _value.length);
		for (uint8 i = 0; i < _to.length; i++) {
			token.transfer(_to[i], _value[i]);
		}
        return true;
    }
}