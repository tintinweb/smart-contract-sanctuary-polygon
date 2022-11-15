/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
  //  function allowance(address tokenOwner, address spender) external view returns (uint remaining);
  //  function approve(address spender, uint tokens) external returns (bool success);
  //  function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
   //  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CanathToken is ERC20Interface {
    string public name = "Canath";
    string public symbol = "CANA";
    uint public decimals = 18;
    uint public override totalSupply;

    //address public founder;
    address payable public founder;

    mapping(address => uint) public balances;

    constructor(){
        totalSupply = 100000000000000000000000000;

        //founder = msg.sender;
        founder = payable(msg.sender);
        
        balances[founder] = totalSupply;       
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
  
 
    function transfer(address to, uint tokens) public override returns (bool success){
        require(balances[msg.sender]>= tokens);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);

        return true;
    } 

    function destroy() public onlyOwner {
        selfdestruct(founder);
    }

    modifier onlyOwner {
        require(msg.sender == founder, "Only the creator of the token can call this function");
        _;
    }

}