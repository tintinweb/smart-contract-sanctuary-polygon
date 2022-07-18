/**
 *Submitted for verification at polygonscan.com on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    
    //Returns the amount of tokens in existence. This function is a getter and does not modify the state of the contract. 
    function totalSupply() external view returns (uint256);

   // Returns the amount of tokens owned by an address (account).
    function balanceOf(address account) external view returns (uint256);

    //The ERC-20 standard allows an address to give an allowance to another address to be able to retrieve tokens from it. 
    function allowance(address owner, address spender) external view returns (uint256);

    
    //Moves the amount of tokens from the function caller address (msg.sender) to the recipient address. 
    //This function emits the Transfer event defined later. It returns true if the transfer was possible.
    function transfer(address recipient, uint256 amount) external returns (bool);

    //Miint token to the invoker address 
    //This function emits the Transfer event defined later. It returns true if the transfer was possible.
    function mint(uint256 amount) external returns (bool);

    //Set the amount of allowance the spender is allowed to transfer from the function caller (msg.sender) balance. 
    //This function emits the Approval event. The function returns whether the allowance was successfully set.
    function approve(address spender, uint256 amount) external returns (bool);

    //Moves the amount of tokens from sender to recipient using the allowance mechanism. 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

   //This event is emitted when the amount of tokens (value) is sent from the from address to the to address.
   //In the case of minting new tokens, the transfer is usually from the 0x00..0000 address 
   //while in the case of burning tokens the transfer is to 0x00..0000.
    event Transfer(address indexed from, address indexed to, uint256 value);


    //This event is emitted when the amount of tokens (value) is approved by the owner to be used by the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract H2GreenToken is IERC20 {

    string public constant name = "H2Green";
    string public constant symbol = "H2G";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 100000 ether;


   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function mint(uint256 numTokens) public override returns (bool) {
        require(numTokens > 0, "ERC20: mint 0 tokens");
        balances[msg.sender] = balances[msg.sender]+numTokens;
        totalSupply_ +=numTokens;
        emit Transfer(address(0), msg.sender, numTokens);
        return true;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function burn(uint256 amount) public override returns (bool) {
        address account = msg.sender;
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totalSupply_ -= amount;
        }

        emit Transfer(account, address(0), amount);
        return true;
    }

}