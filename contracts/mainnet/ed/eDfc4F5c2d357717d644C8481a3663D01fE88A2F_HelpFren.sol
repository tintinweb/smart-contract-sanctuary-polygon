// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.13;

contract HelpFren{
	address owner;
	string public constant name = "HelpFren";
	string public constant symbol = "HFWAD";
	uint256 public constant totalSupply = 1000000 ether;
	uint256 public constant decimals = 18;
	uint256 immutable EXPIRE_DATE;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner(){
    	require(msg.sender == owner, "owner required.");
    	_;
    }

	constructor(){
		owner = msg.sender;
		EXPIRE_DATE = block.timestamp + 30 days;
	}

	function transfer(address to, uint256 amount) public returns(bool){
		balanceOf[msg.sender] -= amount;
		balanceOf[to] += amount;
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) external returns(bool){
		allowance[from][to] -= amount;
		balanceOf[from] -= amount;
		balanceOf[to] += amount;
		emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns(bool){
    	allowance[msg.sender][spender] = amount;
    	emit Approval(msg.sender, spender, amount);
    	return true;
    }

    function transferOwnership(address to) external onlyOwner returns(bool){
    	owner = to;
    	return true;
    }

    function buyToken(uint256 amount) external payable returns(bool){
    	require(block.timestamp <= EXPIRE_DATE, "EXPIRED");
    	uint256 price = 0.1 ether;
    	uint256 totalPrice = price * amount;
    	require(msg.value >= totalPrice, "unmatched");
    	payable(owner).send(msg.value);
    	transfer(msg.sender, amount);
    	return true;
    }

}