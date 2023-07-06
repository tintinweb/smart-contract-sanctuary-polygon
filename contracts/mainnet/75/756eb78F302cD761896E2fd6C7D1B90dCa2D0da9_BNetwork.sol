/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

//SPDX-License-Identifier: MIT
//import "hardhat/console.sol";
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface ERC20In{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);

 }


contract BNetwork is Context {


  uint plannetPlanID;  // for plan entry 
  uint32 userID;          // for user unique ID


  //============Prices==================


    uint constant directSponserRate=50;
    uint constant levelRate=30;
    uint constant upgradeRate=50;

    address tokenAddress;

    uint32 index;


    uint32 nextPoolParent;


    struct autoPool
    { 
        uint32 userID;
        uint32 autoPoolParent;

    }




   struct userInfo {


        uint32      id;             // user id.
  
        uint32      partnersCount;   // partener Count
        address     referrer;       // user sponser address. 

        mapping(uint=>uint) plannetPurchase; // this will contain plannet id with number of time they purchase 
    }


     struct userGain{
       
        uint128 sponserGains; // direct gains.
        uint128 slotSponsorGains; // Slot Sponsor gains.
        uint128 metaP6Gain;// P6 matrix gain
        uint128 uniLevelGains; // Unilevel gains.
        uint128 infinityGains;// infinity club income.
        
        uint128 dividendGains; // how much you get dividend.
        uint128 dividendLimit; // how much you get dividend.
        
        uint128 boosterSponsorGains; //Active Royality.
        uint128 boosterGains; //Active Royality.
        uint128 boosterLimit; //Active Royality.
        uint128 lastBoosterPay;//  Last Booster paid.

        uint32  booster_Count;//   who much booster 
        
    }


    // -----------------------MAPPING DATA STORAGE-------------------


    struct parentInfo{

        uint fillLeg;
    }

    struct poolInfo {

        uint32 nextPoolParent;
        uint16 maxLeg;
    }


    mapping(uint=>uint) public plannetPlans;

    mapping(address=>userInfo) public userInfos;

    mapping(uint=>address) public userAddressByID;

    mapping(uint=>uint) public distLevelPrice;

    mapping(uint=>mapping(uint=>parentInfo)) public parentInfos;  // --parent id levvel --> fill leg

    mapping(uint=>autoPool[]) public autoPoolDataList;  // levels-->--data

    // uint[6] nextPoolParent;

    mapping(uint=>poolInfo) public poolInfos;
    
    


//--------------------------------EVENT SECTION --------------------------------------


      // FINANCIAL EVENT
    event regUserEv(address user, address referral,uint id);
    event sponsorDirectEv(address from_user,address to_user,uint amount);

    event levelEv(address _from , address _to,uint level,uint amount);

    event upgradeEv(address _from , address _to,uint level,uint amount);

    event autopoolPosition(uint16 level, uint index,uint32 parent,address user);

    event autopoolPay (uint16 level,address receiver, uint amount);

    event newPlanEv(uint planID,uint planAmount);




    constructor(address _defaultUser){



        //------default plannet plans with price ---------------

        userID++;

        userInfos[_defaultUser].id = userID; 
    
        userAddressByID[userID] = _defaultUser;
        
  
       



        // this is just for reference 


        /*


        PLAN ID ==> 1 ==> Mercury

        PLAN ID ==> 2 ==> Venus

        PLAN ID ==> 3 ==> Earth

        PLAN ID ==> 4 ==> Moon

        PLAN ID ==> 5 ==> Mars

        PLAN ID ==> 6 ==> Jupiter

        PLAN ID ==> 7 ==> Saturn

        PLAN ID ==> 8 ==> Uranus

        PLAN ID ==> 9 ==> Neptune

        PLAN ID ==> 10 ==> Pluto


        */


        distLevelPrice[1]= 0.10 ether;
        distLevelPrice[2]= 0.09 ether;
        distLevelPrice[3]= 0.08 ether;
        distLevelPrice[4]= 0.07 ether;
        distLevelPrice[5]= 0.06 ether;
        distLevelPrice[6]= 0.05 ether;
        distLevelPrice[7]= 0.05 ether;
        distLevelPrice[8]= 0.05 ether;
        distLevelPrice[9]= 0.05 ether;
        distLevelPrice[10]= 0.05 ether;
        distLevelPrice[11]= 0.15 ether;
        distLevelPrice[12]= 0.15 ether;
        distLevelPrice[13]= 0.15 ether;
        distLevelPrice[14]= 0.20 ether;
        distLevelPrice[15]= 0.20 ether;



        poolInfos[1].maxLeg=2; // level 1 leg
        poolInfos[2].maxLeg=4;
        poolInfos[3].maxLeg=8;
        poolInfos[4].maxLeg=16;
        poolInfos[5].maxLeg=32;
        poolInfos[6].maxLeg=64;


        for (uint i=1;i<=10;i++){


            uint lastPlanAmount = plannetPlans[plannetPlanID];

            plannetPlanID++;


            if (i%3==0){ 

                plannetPlans[plannetPlanID]=(lastPlanAmount*2)+(lastPlanAmount/2);

            }else {

                plannetPlans[plannetPlanID]=lastPlanAmount<1?5e18:(lastPlanAmount*2);
            }



        }


    }




    //----------------------------For receving matic--------------------------------------

    fallback () external {


    }


    receive () external payable {
        
    }



    //===============REGISTRAION======================>


    function registrations( address referrerAddress) public  {  

        address userAddress = _msgSender();  
        uint amount = plannetPlans[1];

        require(!isUserExists(userAddress) && isUserExists(referrerAddress), "user already exisit/invalid referral");
        require(tokenAddress!=address(0),"Please set token address first");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "Invalid User wallet");


        userID++;
        
        userInfos[userAddress].id = userID; 
        userInfos[userAddress].referrer = referrerAddress;
        userAddressByID[userID] = userAddress;
        
        
        
        userInfos[referrerAddress].partnersCount++;

        receiveFund(userAddress,amount);


        plannetSponserIncome();  

        _buyPlannet(1);    

      
    }



    function buyPlannet(uint plannetID) public  returns(bool){
        
        require(isUserExists(_msgSender()),"You are not Joined");
     
        require( plannetID>0 && plannetID <= plannetPlanID, "Invalid level");
       
       require(tokenAddress!=address(0),"Please set token address first");

         uint amount = plannetPlans[1];

          receiveFund(_msgSender(),amount);


        //plannetSponserIncome(msg.value);

        _buyPlannet(plannetID);
         plannetUpgradeIncome(_msgSender(),plannetID);
        return true;

    }


    function _buyPlannet(uint pid) internal {

        userInfos[_msgSender()].plannetPurchase[pid]+=1;

        uint amount = plannetPlans[pid];

        autoPoolPosition(_msgSender(),amount);

        plannetLevelIncome(_msgSender());

    }





    function plannetUpgradeIncome(address user, uint pid) internal {


        address receiver = userInfos[user].referrer;

        uint amount = plannetPlans[pid]*upgradeRate/100;

       for (uint i = 1;i<pid;i++){

        
           if (receiver==address(0) || userInfos[receiver].plannetPurchase[pid]<1){

               receiver= userAddressByID[1];

                break;
           }

            receiver= userInfos[receiver].referrer;

       }



       transferIncome(receiver,amount);
       //emit

       emit upgradeEv(user , receiver,pid,amount);


    }


    function autoPoolPosition(address user,uint amount) internal {


        autoPool memory pool; // create a local copy of autopool
        pool.userID = userInfos[user].id;

        (uint32 lastMember,uint16 lastLevel) = getLastMember();

        uint32 parentIndex = lastMember;
        pool.autoPoolParent = parentIndex;  

        uint16 level = lastLevel;

        autoPoolDataList[level].push(pool);

        syncPoolIndex(level,parentIndex);


        //dist need pid

        // just for test purpose 

         amount = amount*20/100;

        address receiver = userAddressByID[autoPoolDataList[level][parentIndex].userID];

        if (receiver==address(0)){

            receiver = userAddressByID[1];
        }

        transferIncome(receiver,amount); // send to 

        emit  autopoolPosition(level, autoPoolDataList[level].length ,parentIndex,receiver);


        emit autopoolPay(level,receiver,amount);

      
        
    }



    function syncPoolIndex(uint16 level,uint32 parent) internal {

        uint levelMaxLeg = poolInfos[level].maxLeg;

        uint parentFill = parentInfos[parent][level].fillLeg;

        if (parentFill<levelMaxLeg){

            parentInfos[parent][level].fillLeg++;
            
        }else{

             if (level==6){ //last lellvel

                  poolInfos[1].nextPoolParent++;
             }
             
            
        }                


    }

    function getLastMember() internal view returns(uint32 parent,uint16 level){

        for (uint16 i=1;i<=6;i++){

             level = i;

             parent = poolInfos[i].nextPoolParent;

            // check parent legs

            uint levelMaxLeg = poolInfos[i].maxLeg;

            uint parentFill = parentInfos[parent][i].fillLeg;

            if (parentFill<levelMaxLeg){

                return (parent,level);
            }

        }

    }


    function plannetSponserIncome() internal {


       address receiver =  userInfos[_msgSender()].referrer;

        uint _tranferableAmnt = msg.value*directSponserRate/100;

        transferIncome(receiver,_tranferableAmnt);

        emit sponsorDirectEv(_msgSender(),receiver,_tranferableAmnt);

    }


    function plannetLevelIncome(address user) internal {

        address receiver = userInfos[user].referrer;

        uint amount;

       for(uint i=1;i<=15;i++){

           if (receiver==address(0)){

               
                amount+=distLevelPrice[i];

                emit levelEv(user, userAddressByID[1],i,distLevelPrice[i]);

           }else{

               transferIncome(receiver,distLevelPrice[i]);
              emit levelEv(user, receiver,i,distLevelPrice[i]);

           }


            receiver=userInfos[receiver].referrer;
           
       }

       if (amount>0){

           //transferIncome(userAddressByID[1],amount); // send fund to default id
       }

    }



     function isUserExists(address user) public view returns (bool) {
        return (userInfos[user].id != 0);
    }



    function transferIncome(address to , uint amount) internal{

        payable(to).transfer(amount);

    }


    function receiveFund(address from, uint amount) internal{

        ERC20In(tokenAddress).transferFrom(from,address(this),amount);

    }


   function addTokenAddress(address _token) public  {

       require(_msgSender()==userAddressByID[1],"invalid authentication");

       tokenAddress= _token;

   }


    function addNewPlan(uint planAmount) public  {

       require(_msgSender()==userAddressByID[1],"invalid authentication");

       plannetPlanID++;

        plannetPlans[plannetPlanID]=planAmount;

        emit newPlanEv(plannetPlanID,planAmount);

   }


}