pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract TokenERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HHMA{

    using SafeMath for uint256;
	
    string private _name = "HHM Auction";
    string private _symbol = "HHMA";

    mapping (address => mapping (address => uint256)) private _allowances;
	
    mapping (uint => address) _allowanceBuyers;

    uint _approveCounter = 0;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event resetAllowance(address indexed owner, address indexed spender, uint value);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function approveCounter() public view returns (uint) {
        return _approveCounter;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
		
		if(_approveCounter > 0){
			address buyer = _allowanceBuyers[_approveCounter];
			_allowances[msg.sender][buyer] = 0;
           emit resetAllowance(msg.sender, buyer, 0);
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
           emit resetAllowance(msg.sender, buyer, 0);
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