/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract SPMudraICO{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 100;  // 1 Matic = 100 SP Mudra
    uint public raisedAmount; // this value will be in wei
    mapping(address => uint256) public balances;
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public icoState;
    IBEP20 tokenInstance;
    address tokenAddress;

    constructor(address payable _deposit){
        deposit = _deposit; 
        admin = msg.sender; 
        icoState = State.running;
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

    function setTokenPrice(uint256 price) public onlyAdmin{
        tokenPrice = price;
    }
    
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }
        else{
            return State.running;
        }
    }
    
 
    event Invest(address investor, uint value, uint tokens);
    
    
    // function called when sending eth to the contract
    function invest(address payable sponsor) payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);

        raisedAmount += msg.value;
        uint tokens = msg.value * tokenPrice;
        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += tokens;
        // transfer tokens to the msg.sender
        tokenInstance.transfer(msg.sender, tokens);

        uint sponsorCommission = tokens * 10/100;

        // send commission to user sponsor
 
        tokenInstance.transfer(sponsor, sponsorCommission);

        balances[admin] -= tokens; 
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
   
    // this function is called automatically when someone sends ETH to the contract's address
    receive () payable external{
    }
  

     function setToken(address contractAddress) public onlyAdmin {
        tokenAddress = contractAddress;
        tokenInstance = IBEP20(tokenAddress);
    }
}