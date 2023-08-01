/**
 *Submitted for verification at polygonscan.com on 2023-07-29
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
        uint32      partnersCount;   // partner Count
        address     referrer;       // user sponser address. 
        uint32      recentPackage;  // 
        bool        isFullCycleCompleted;// indicate autopool cycle 
        mapping(uint=>uint) plannetPurchase; // this will contain plannet id with number of time they purchase 

        uint        poolCycleTeam;
       
    }


    // -----------------------MAPPING DATA STORAGE-------------------



    struct poolInfo {

        uint32 nextPoolParent;
        uint fillLeg;
    }


    mapping(uint=>uint) public plannetPlans;

    mapping(address=>userInfo) public userInfos;

    mapping(uint=>address) public userAddressByID;

    mapping(uint=>uint) public distLevelPrice;


    mapping(uint=>autoPool[]) public autoPoolDataList;  // package=>level=>data

    // uint[6] nextPoolParent;

    mapping(uint=>poolInfo) public poolInfos;
    


//--------------------------------EVENT SECTION --------------------------------------


      // FINANCIAL EVENT
    event regUserEv(address user, address referral,uint id);
    event sponsorDirectEv(address from_user,address to_user,uint amount);

    event plannetBuy(address user, uint plannetId);

    event levelEv(address _from , address _to,uint level,uint amount);

    event upgradeEv(address _from , address _to,uint level,uint amount);

    event autopoolPosition(uint level, uint index,uint32 parent,address immediateParentAddress);

    event autoPoolPayEv (uint timestamp, uint level,address receiver, address paidFrom, uint amount);

  

    event newPlanEv(uint planID,uint planAmount);




    constructor(address _defaultUser){



        //------default plannet plans with price ---------------

        userID++;

        userInfos[_defaultUser].id = userID; 
    
        userAddressByID[userID] = _defaultUser;


        autoPoolPosition(_defaultUser,1,true);
        


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


        plannetSponserIncome(amount);  

        _buyPlannet(1,false);    

        plannetLevelIncome(_msgSender());

        emit regUserEv(userAddress, referrerAddress,userID);

      
    }



    function buyPlannet(uint32 plannetID) public  returns(bool){
        
        require(isUserExists(_msgSender()),"You are not Joined");

        uint lastLevel = userInfos[_msgSender()].recentPackage;
     
        require( plannetID>0 && plannetID <= plannetPlanID && plannetID<=lastLevel+1 , "Invalid level");
       
       require(tokenAddress!=address(0),"Please set token address first");

         uint amount = plannetPlans[plannetID];

          receiveFund(_msgSender(),amount);


        _buyPlannet(plannetID,false);

         plannetUpgradeIncome(_msgSender(),plannetID);
         
        if (plannetID==1){

             plannetLevelIncome(_msgSender());
        }
        return true;

    }


    function _buyPlannet(uint32 pid, bool defaultReg) internal {

        userInfos[_msgSender()].plannetPurchase[pid]+=1;

        autoPoolPosition(_msgSender(),pid,defaultReg);

        userInfos[_msgSender()].recentPackage=pid;

        emit plannetBuy(_msgSender(),pid);

    }




    function plannetUpgradeIncome(address user, uint pid) internal {


        address receiver = userInfos[user].referrer;

        uint amount = plannetPlans[pid]*upgradeRate/100;

       for (uint i = 1;i<pid;i++){

        
           if (receiver==address(0) || userInfos[user].isFullCycleCompleted  ){

               receiver= userAddressByID[1];

                break;
           }

            receiver= userInfos[receiver].referrer;

       }

       

        if (userInfos[receiver].plannetPurchase[pid]<1){

            // receiver is not eligible

            for(uint level=1;level<=10;level++){


                        
                if (receiver==address(0) || userInfos[user].isFullCycleCompleted  ){

                    receiver= userAddressByID[1];

                    break;
                }else{


                    if (userInfos[receiver].plannetPurchase[pid]>0){

                        break;
                    }
                }



                receiver= userInfos[receiver].referrer;

            }


            if (userInfos[receiver].plannetPurchase[pid]<1){

                receiver= userAddressByID[1];

            }


        }


       transferIncome(receiver,amount);
       //emit

       emit upgradeEv(user , receiver,pid,amount);


    }


    function getLegFillInLevel(uint level) pure public returns(uint){

        if (level==1){

            return 2;
        }else if (level==2){

            return 4;
        }else if (level==3){

            return 8;
        }else if (level==4){

            return 16;
        }else if (level==5){

            return 32;
        }else{

            return 64;
        }

    }


    function getAutopoolDistPrice(uint level) pure public returns(uint){

        if (level>0 && level<=2){

            return 10;

        }else if (level>=3 && level<=6){

            return 20;
        }

        return 0;

    }


    function getPackageRecycleCount(address user ,uint packageId)  public view returns (uint) {


        return userInfos[user].plannetPurchase[packageId];

    }


    function autoPoolPosition(address user,uint pid, bool defaultReg) internal {


        autoPool memory pool; // create a local copy of autopool
        pool.userID = userInfos[user].id;


        if (userInfos[user].isFullCycleCompleted){

            userInfos[user].isFullCycleCompleted=false;
        }

        (uint32 indx) = getLastMember(pid);

        uint32 parentIndex = indx;
        pool.autoPoolParent = parentIndex;  



        autoPoolDataList[pid].push(pool);


        if (!defaultReg){

             // autoPoolPay section Here ..

            uint autopoolDistRate = pid==1?20:50;

            uint amount = plannetPlans[pid]*autopoolDistRate/100;

            address  usr = userAddressByID[autoPoolDataList[pid][indx].userID];

           
            if(usr == address(0)) usr = userAddressByID[1];

            for(uint i=0;i<6;i++)
            {
                uint payAmount = amount*getAutopoolDistPrice(i+1)/100;
         
                emit autoPoolPayEv(block.timestamp, i+1, usr, user,payAmount);

                // transfer amount as well

                 transferIncome(usr,payAmount); // send to 

                indx = autoPoolDataList[pid][indx].autoPoolParent; 
                usr = userAddressByID[autoPoolDataList[pid][indx].userID];

                if (usr!=address(0) || usr != userAddressByID[1]){

                    userInfos[usr].poolCycleTeam++;
                }

                if(usr == address(0) || userInfos[usr].isFullCycleCompleted==true ) usr = userAddressByID[1];


                if ( userInfos[usr].poolCycleTeam>=64 && usr !=userAddressByID[1]){

                    userInfos[usr].isFullCycleCompleted=true;
                }
            }


           
           
        }


         address imidiateParent = userAddressByID[autoPoolDataList[pid][indx].userID];


        emit  autopoolPosition(pid, autoPoolDataList[pid].length ,parentIndex,imidiateParent);


     
      
        
    }



    function autoPoolLength(uint16 pid) public view returns (uint) {

            return autoPoolDataList[pid].length;  

    }

    function getLastMember(uint pid) internal  returns(uint32 parent){

  
             uint legs = poolInfos[pid].fillLeg;

            uint32 oldParent = poolInfos[pid].nextPoolParent;

            if (legs==0){

                poolInfos[pid].fillLeg=1;

            }

            else{

                poolInfos[pid].nextPoolParent++;

                poolInfos[pid].fillLeg=0;

            }

            return oldParent;
            

    }


    function plannetSponserIncome(uint amount) internal {


       address receiver =  userInfos[_msgSender()].referrer;

        uint _tranferableAmnt = amount*directSponserRate/100;

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

           transferIncome(userAddressByID[1],amount); // send fund to default id
       }

    }



     function isUserExists(address user) public view returns (bool) {
        return (userInfos[user].id != 0);
    }



    function transferIncome(address to , uint amount) internal{

        ERC20In(tokenAddress).transfer(to,amount);

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