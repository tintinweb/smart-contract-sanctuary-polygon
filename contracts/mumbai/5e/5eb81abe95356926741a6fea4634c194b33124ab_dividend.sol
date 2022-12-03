/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// IRC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
// dividend contract 
contract dividend {
    address private admin;
    uint contractBalance;
    mapping (address =>uint256) public gameId;
    uint day =450;
    uint collect;
    address constant tokenAddress = 0x23A9298fBefF739BaDCF4Bea36163e672926134C;
    mapping(address =>uint)startime;
    uint totalSpended;
    mapping(address =>uint)playerEnergie;
    struct Game{
        address treasury;
        uint balance ;
        bool locked;
        bool spent;
    }
   mapping(address => mapping(uint256 => Game)) public balances;

   constructor(){
       admin=msg.sender;
       gameId[msg.sender]=0;
       playerEnergie[msg.sender]=10;
       day=0;
       startime[msg.sender]=0;
   }
   
    modifier onlyAdmin(){
       require(msg.sender==admin);
       _;
   }
   // check if the address is a contract
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
    // game statistic
   function gameState(uint _gameId)public view returns(uint256, bool,address){
        return (
            balances[msg.sender][_gameId].balance,
            balances[msg.sender][_gameId].locked,
            balances[msg.sender][_gameId].treasury
        );}
    // add energie
    function setEnergie()public{
        require(block.timestamp >startime[msg.sender]+day);
        playerEnergie[msg.sender]=10;
        day=450;
        startime[msg.sender]=block.timestamp;
    }
    // get the energie of the address
    function getEnergy()public view returns(uint){
        return playerEnergie[msg.sender];
        
    }
    // when start game
   function startgame()public  returns (bool) {
        require(playerEnergie[msg.sender]>0); // player should have energie
        gameId[msg.sender]++;   // add a new state
        balances[msg.sender][gameId[msg.sender]].balance=10; // add the balance must get if won
        balances[msg.sender][gameId[msg.sender]].locked=true; // locke the balance
        balances[msg.sender][gameId[msg.sender]].spent=false; 
        balances[msg.sender][gameId[msg.sender]].treasury=address(this);    //treasury address
        playerEnergie[msg.sender]--;
        return true;
   }
   // if the player won
   function wonGame() public{
        balances[msg.sender][gameId[msg.sender]].locked=false;
        balances[msg.sender][gameId[msg.sender]].spent=false;
   }
   // if the player lost
   function lostGame() public{
        balances[msg.sender][gameId[msg.sender]].balance=0;
        balances[msg.sender][gameId[msg.sender]].locked=true;
        balances[msg.sender][gameId[msg.sender]].spent=false;  
   }
   // get contract balance (only available for the admin)
    function GetContractBalance()public view  onlyAdmin returns (uint){
        return IERC20(tokenAddress).balanceOf(address(this))/10**18;
    }
    // get player balance
    function getBalance()public view returns(uint){
        return IERC20(tokenAddress).balanceOf(msg.sender);

    }
    // windraw the balnace of erc20 if the player won
   function withdraw()public returns(bool){
        require(!isContract(msg.sender));
        require(GetContractBalance()>0,'No fund exsit');
        require(
            balances[msg.sender][gameId[msg.sender]].locked == false,
            "This escrow is still locked"
        );
        require(
            balances[msg.sender][gameId[msg.sender]].spent == false,
            "Already withdrawn"
        );
        IERC20(tokenAddress).transfer(msg.sender, balances[msg.sender][gameId[msg.sender]].balance*10**18);
        totalSpended+=balances[msg.sender][gameId[msg.sender]].balance;
        balances[msg.sender][gameId[msg.sender]].spent=true;
        return true;
   }
     }