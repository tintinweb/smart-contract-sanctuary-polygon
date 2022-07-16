/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// -----------------------------------------

// This interface defines the methods for making an ERC20 token
interface ERC20Interface {
    // These 3 methods must be used to make an ERC20 token partially compliant
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    // These 3 methods are not compulsory but they can be used to make a token fully ERC20 complaint
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Buddha is ERC20Interface {
    // State variables that are ERC20 complaint
    string public name = "Buddha";
    string public symbol = "BUDDHA";
    uint public decimals = 0;
    uint public override totalSupply;
    address public founder;
    
    // Holds the balances of each address
    mapping(address => uint) public balances;
    // Holds the allowed tokens that can be transferred from the tokenOwner
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    // Returns the balance of a token owner
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    // Transfers the tokens from the sender address to the recipient
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }

    // Sets the allowed maximum tokens that can be transfered from a tokenOwner to a spender
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    // Approves the allowance 
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    // Transfers from a sender to recipient and updates the allowed variable appropriately
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         emit Transfer(from, to, tokens);
         
         return true;
     }

}

contract BuddhaICO is Buddha{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.1 ether;  // 1 ETH = 10 Buddha, 1 Buddha = 0.1
    uint public hardCap = 3000 ether;
    uint public raisedAmount; // this value will be in wei
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 1209600; //two weeks
    
    uint public tokenTradeStart = saleEnd + 1209600; //transferable in a week after saleEnd
    uint public maxInvestment = 30 ether;
    uint public minInvestment = 3 ether;
    
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public icoState;
    
    constructor(address payable _deposit){
        deposit = _deposit; 
        admin = msg.sender; 
        icoState = State.beforeStart;
    }
 
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    
    // emergency stop
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
 
 
    event Invest(address investor, uint value, uint tokens);
    
    
    // function called when sending eth to the contract
    function invest() payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value / tokenPrice;
 
        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
   
   
   // this function is called automatically when someone sends ETH to the contract's address
   receive () payable external{
        invest();
    }
  
    
    // burning unsold tokens
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
        
    }
    
    
    function transfer(address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
        
        // calling the transfer function of the base contract
        super.transfer(to, tokens);  // same as Cryptos.transfer(to, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
       
        Buddha.transferFrom(from, to, tokens);  // same as super.transferFrom(to, tokens);
        return true;
     
    }
}