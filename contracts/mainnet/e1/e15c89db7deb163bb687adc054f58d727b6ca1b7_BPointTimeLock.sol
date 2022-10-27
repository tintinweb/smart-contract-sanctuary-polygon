/**
 *Submitted for verification at polygonscan.com on 2022-10-27
*/

// SPDX-License-Identifier: MIT
// Developed by Barter Smart Thailand Co.,Ltd.

pragma solidity 0.8.11;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

   
    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

contract BPointTimeLock{


uint public days_to_release;
   
    address payable public owner;
    address payable public Right_address;
    address payable public FinalAddress;
    
   
    uint public EachRedemptionAmount = 1000000000000000000000000;

    bool public timestampSet;
   
    uint public timePeriod1;
    uint public timePeriod2;
    uint public timePeriod3;
    uint public timePeriod4;
    uint public timePeriod5;

    bool public Deposited;

    bool public Released1;bool public Released2;bool public Released3;bool public Released4;bool public Released5;
    uint public ContractBalance;
    
    mapping(address => uint) public balances;
  
    IERC20 public BigPoint_Contract;

     constructor(IERC20 _BIGP_contract_address) {
       
        owner = payable(msg.sender);
              
        require(address(_BIGP_contract_address) != address(0), "_erc20_contract_address address can not be zero");
        BigPoint_Contract = _BIGP_contract_address;
         
        timestampSet = false;
       
        Released1 = false;Released2 = false; Released3 = false; Released4 = false;Released5 = false;

        Deposited = false; 
     } 

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier OnlyRightAddress {
        require((msg.sender == owner)||(msg.sender==Right_address));
        _;
    }  

    function SetRightPerson(address payable _rightPerson) OnlyRightAddress public {
        Right_address = _rightPerson;
    }

    function SetFinalAddress(address payable _FinalAddress) OnlyRightAddress public {
        FinalAddress = _FinalAddress;
    }

   
    function setTimestamp1() public OnlyRightAddress returns(uint,uint,uint,uint,uint){
        require(timePeriod1==0);
        
        timePeriod1 = 1716181200;//May 20th, 2024
        timePeriod2 = 1779253200;//May 20th, 2026
        timePeriod3 = 1842411600;//May 20th, 2028
        timePeriod4 = 1905483600;//May 20th, 2030
        timePeriod5 = 1968642000;//May 20th, 2032
        timestampSet = true;
        
        return (timePeriod1,timePeriod2,timePeriod3,timePeriod4,timePeriod5);
    }

   

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender]>=tokens, "Not enough BiGP");
        balances[msg.sender] = balances[msg.sender]-tokens;
        balances[to] = balances[to]+tokens;
        //emit Transfer(msg.sender, to, tokens);
        return true;
    }

   function CheckContractBalance()public returns(uint){
       ContractBalance = IERC20(BigPoint_Contract).balanceOf(address(this));
       if (ContractBalance >=1000000000000000000000000){
           Deposited =true;
       }

       if (ContractBalance <1000000000000000000000000){
           Deposited =false;
       }
       return ContractBalance;     
   }

    function ReleaseBIGP1() public OnlyRightAddress returns (bool success) {
         require(block.timestamp >= timePeriod1, "Not completed deposited time yet");
         require(Released1==false,"First time redemption was completed");
        
        //string memory Round1_Released = "Big Point First Redemption";
        Released1=true;
        return IERC20(BigPoint_Contract).transfer(FinalAddress, EachRedemptionAmount);        
        //emit TokensUnlocked(FinalAddress,FirstRedemption, Round1_Released);
    }

    function ReleaseBIGP2() public OnlyRightAddress returns (bool success) {
         require(block.timestamp >= timePeriod2, "Not completed deposited time yet");
         require(Released2==false,"Second time redemption was completed");
        
        //string memory Round1_Released = "Big Point First Redemption";
        Released2=true;
        return IERC20(BigPoint_Contract).transfer(FinalAddress, EachRedemptionAmount);        
        //emit TokensUnlocked(FinalAddress,FirstRedemption, Round1_Released);
    }

    function ReleaseBIGP3() public OnlyRightAddress returns (bool success) {
         require(block.timestamp >= timePeriod3, "Not completed deposited time yet");
         require(Released3==false,"Third redemption was completed");
        
        //string memory Round1_Released = "Big Point First Redemption";
        Released3=true;
        return IERC20(BigPoint_Contract).transfer(FinalAddress, EachRedemptionAmount);        
        //emit TokensUnlocked(FinalAddress,FirstRedemption, Round1_Released);
    }

    function ReleaseBIGP4() public OnlyRightAddress returns (bool success) {
         require(block.timestamp >= timePeriod4, "Not completed deposited time yet");
         require(Released4==false,"Fourth redemption was completed");
        
        //string memory Round1_Released = "Big Point First Redemption";
        Released4=true;
        return IERC20(BigPoint_Contract).transfer(FinalAddress, EachRedemptionAmount);        
        //emit TokensUnlocked(FinalAddress,FirstRedemption, Round1_Released);
    }

    function ReleaseBIGP5() public OnlyRightAddress returns (bool success) {
         require(block.timestamp >= timePeriod5, "Not completed deposited time yet");
         require(Released5==false,"Fifth redemption was completed");
        
        //string memory Round1_Released = "Big Point First Redemption";
        Released5=true;
        return IERC20(BigPoint_Contract).transfer(FinalAddress, EachRedemptionAmount);        
        //emit TokensUnlocked(FinalAddress,FirstRedemption, Round1_Released);
    }

    function CheckDayRemainRedemption(uint _roundRedemption)public returns(uint){
          require((_roundRedemption<=5)&&(_roundRedemption>0));
          uint today = block.timestamp;
          if (_roundRedemption==1){
              uint seconds_to_release = timePeriod1-today;
              
              days_to_release = seconds_to_release/86400;
          }

          if (_roundRedemption==2){
              uint seconds_to_release = timePeriod2-today;
              
              days_to_release = seconds_to_release/86400;
          }

          if (_roundRedemption==3){
              uint seconds_to_release = timePeriod3-today;
              
              days_to_release = seconds_to_release/86400;
          }

          if (_roundRedemption==4){
              uint seconds_to_release = timePeriod4-today;
              
              days_to_release = seconds_to_release/86400;
          }

          if (_roundRedemption==5){
              uint seconds_to_release = timePeriod5-today;
              
              days_to_release = seconds_to_release/86400;
          }

          return days_to_release;
    }
     

}