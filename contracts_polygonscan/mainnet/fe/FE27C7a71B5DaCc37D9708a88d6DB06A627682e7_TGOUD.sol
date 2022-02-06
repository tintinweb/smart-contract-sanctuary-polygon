/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TGOUD is IERC20 {

    string public constant name = "TGoud";
    string public constant symbol = "TG";
    uint256 public constant decimals = 6;  

    address public  owner;
    address public minter;


    event OwnerChangedEvent(address indexed newOwner);
    event addDappEvent(address indexed dapp);
    event removeDappEvent(address indexed dapp);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    address[] public acceptedDapps;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor()  {  
        owner = msg.sender;
        acceptedDapps.push(msg.sender);
    }  

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized: not owner");
        _;
    }

    modifier onlyDapp() {
        require( isDappAccepted (msg.sender) == true, "unauthorized: not minter");
        _;
    }

      modifier onlyDappOrOwner() {
        require(msg.sender == minter || msg.sender == owner , "unauthorized: not minter or owner");
        _;
    }


    

    /// Change who holds the `owner` role.
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerChangedEvent(newOwner);
    }

    /// Change who holds the `minter` role.
    function addDapp(address newDapp) external onlyOwner returns(bool) {
        acceptedDapps.push(newDapp);
        emit addDappEvent(newDapp);
        return true;
    }

    function removeDapp(uint i) public onlyOwner returns (bool){
        address dapp = acceptedDapps[i];
        delete acceptedDapps[i];
        emit removeDappEvent(dapp);
        return true;
    }
 
    
    function isDappAccepted(address dapp_) internal view returns (bool)  {
            
            for (uint i=0; i < acceptedDapps.length; i++) {

                    address dapp = acceptedDapps[i];

                    if(dapp == dapp_ ) {
                        return true;
                    }
            }

            return false;
    }
 

    function totalSupply() public override view returns (uint256) {
	    return totalSupply_;
    }
    

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner_, address delegate) public override view returns (uint) {
        return allowed[owner_][delegate];
    }

    function transferFrom(address owner_, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner_]);    
        require(numTokens <= allowed[owner_][msg.sender]);
    
        balances[owner_] = balances[owner_].sub(numTokens);
        allowed[owner_][msg.sender] = allowed[owner_][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner_, buyer, numTokens);
        return true;
    }

    function deposit(address _to, uint _amount) public onlyDapp  returns(bool){
		totalSupply_+=_amount;
		balances[_to]+=_amount;
        return true;
	}

	function withdraw(address _from,uint _amount) public onlyDapp  returns(bool){
		totalSupply_-=_amount;
		balances[_from]-=_amount;
        return true;
	}

    function sendTo(address _from, address _to, uint _amount) public onlyDapp  returns(bool){
		balances[_from] -=_amount;
		balances[_to] +=_amount;
        return true;
	}
}

library SafeMath { 
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