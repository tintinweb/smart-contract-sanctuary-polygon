/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract qwe {
     address public ownerWallet;
      address public devWallet;
      uint public currUserID = 0;

       uint[11] poolcurrRegisterUserID;
       uint[11] poolactiveUserID;
      
      

      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
       uint referralEarning;
       uint autopoolInvestEarning;
       uint incomeOnIncome;
       uint fastCashBonus;
    }
    
     
     struct PoolUserStruct {
        bool isExist;
        uint id;
        uint256 payment_received; 
        uint reEntry;
        bool paid_entry;
    }
    

    

    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
     
  
      mapping (uint=>mapping(address => PoolUserStruct)) public poolusers;
     mapping(uint =>mapping(uint => address)) public pooluserList;
     
   
    mapping(uint => uint256) public Pool_Entry_fee;

    mapping(uint256 => uint256) public Payment_Received_List_Pool;
    uint256[] ref_earnings = [10,5,5,3,1,1];
   
   
    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForPoolLevelEvent(address indexed _user, address indexed _referral, uint256 _level, uint256 _time,uint256 poolid,uint256 poolno,uint8 treeLevel,uint256 amount);
     event getMoneyForPoolLevelEventReinvest(address indexed _user, address indexed _referral, uint256 _level, uint256 _time,uint poolid,uint poolno);
     event regPoolEntry(address indexed _user,uint _level,   uint _time,uint poolid,uint userid,bool paid_entry);
   
     
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level);
    event fastcashbonusevent(address indexed _user, uint _level);
   
  
     
      constructor(address _ownerWallet,address _devWallet)  {
          ownerWallet = _ownerWallet;
          devWallet = _devWallet;

        Pool_Entry_fee[1] = 10 ether;
        for(uint i = 2 ;i <= 10 ; i ++)
        {
            Pool_Entry_fee[i] = Pool_Entry_fee[i-1] * 2; 
        }

        UserStruct memory userStruct;
       
        currUserID++;
        
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0,
            referralEarning :0,
            autopoolInvestEarning:0,
            incomeOnIncome:0,
            fastCashBonus:0
           
        });
        
        users[ownerWallet] = userStruct;
       
       userList[currUserID] = ownerWallet;
       
       
         PoolUserStruct memory pooluserStruct;
        
       
       /* Pool All */
       
       for(uint i = 1 ; i<= 10; i++)
       {
        poolcurrRegisterUserID[i]++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:poolcurrRegisterUserID[i],
            payment_received:0,
            reEntry : 0,
            paid_entry:true
        });
        poolactiveUserID[i]=poolcurrRegisterUserID[i];
       poolusers[i][msg.sender] = pooluserStruct;
       pooluserList[i][poolcurrRegisterUserID[i]]=msg.sender;
       }
       
      }
     
       function regUser(uint _referrerID) public payable {
            require(!users[msg.sender].isExist, "User Exist");
          require(userList[_referrerID]!=address(0),"Invalid referrer id");
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0,
            referralEarning :0,
            autopoolInvestEarning:0,
            incomeOnIncome:0,
            fastCashBonus:0
            
        });
       users[msg.sender] = userStruct;
       
       userList[currUserID]=msg.sender;
    
        emit regLevelEvent(msg.sender, userList[_referrerID], block.timestamp);
           buyPool(1);
    }
   
   
   
   
   
   function payPoolReferral(uint _level, address _user,uint _poolno) internal {
        address referer;
        for(uint8 i=0;i<ref_earnings.length;i++)
        {
            referer = userList[users[_user].referrerID];
            if(referer==address(0))
            {
                break;
            }
            uint256 amount = percentage(Pool_Entry_fee[_poolno],ref_earnings[i]);
            payable((referer)).transfer(amount);
            users[referer].referralEarning +=  amount;
            emit getMoneyForPoolLevelEvent(referer, _user, _level, block.timestamp,users[_user].referrerID,_poolno,i+1,amount);
            _user = referer;
        }
     
     }
     
     function payPoolPaymentReferral(uint _level, address _user,uint _poolno) internal {
         if(users[_user].referrerID>0){
            address referer;
            referer = userList[users[_user].referrerID];
             payable((referer)).transfer(Pool_Entry_fee[_poolno] * 5 /100);
              users[referer].incomeOnIncome +=  Pool_Entry_fee[_poolno] * 5 /100;
                    emit getMoneyForPoolLevelEventReinvest(referer, _user, _level, block.timestamp,users[_user].referrerID,_poolno);
             
        }
     }
   
   
       function buyPool(uint poolId) public payable {
       require(users[msg.sender].isExist, "User Not Registered");
       require(!poolusers[poolId][msg.sender].isExist, "Already in AutoPool");
        require(msg.value == Pool_Entry_fee[poolId], "Incorrect Value");
        
        PoolUserStruct memory userStruct;
        poolcurrRegisterUserID[poolId]++;
        
        userStruct = PoolUserStruct({
            isExist:true,
            id:poolcurrRegisterUserID[poolId],
            payment_received:0,
            reEntry : 0,
            paid_entry:true
        });
        poolusers[poolId][msg.sender] = userStruct;
        pooluserList[poolId][poolcurrRegisterUserID[poolId]]=msg.sender;
       
       payPoolReferral(1,msg.sender,poolId);
       emit regPoolEntry(msg.sender, poolId, block.timestamp,poolcurrRegisterUserID[poolId],users[msg.sender].id,true);
    
        if(poolusers[poolId][pooluserList[poolId][poolcurrRegisterUserID[poolId]-1]].paid_entry)
        {
            payable((pooluserList[poolId][poolcurrRegisterUserID[poolId]-1])).transfer(percentage(Pool_Entry_fee[poolId],10));
                users[pooluserList[poolId][poolcurrRegisterUserID[poolId]-1]].fastCashBonus +=  percentage(Pool_Entry_fee[poolId],10);
                emit fastcashbonusevent(pooluserList[poolId][poolcurrRegisterUserID[poolId]-1],poolId);
        }
        else
        {
            payable((pooluserList[poolId][poolcurrRegisterUserID[poolId]-2])).transfer(percentage(Pool_Entry_fee[poolId],10));
                users[pooluserList[poolId][poolcurrRegisterUserID[poolId]-2]].fastCashBonus +=  percentage(Pool_Entry_fee[poolId],10);
                emit fastcashbonusevent(pooluserList[poolId][poolcurrRegisterUserID[poolId]-2],poolId);
        }
        payable((pooluserList[poolId][poolactiveUserID[poolId]])).transfer(percentage(Pool_Entry_fee[poolId],50));
        address currentUseraddress=pooluserList[poolId][poolactiveUserID[poolId]];
        users[currentUseraddress].autopoolInvestEarning +=  percentage(Pool_Entry_fee[poolId],50);
                emit getPoolPayment(msg.sender,pooluserList[poolId][poolactiveUserID[poolId]], poolId);
                /* Payment referral for pool payment   */
                
                payPoolPaymentReferral(1,currentUseraddress,poolId);
                
                poolusers[poolId][currentUseraddress].payment_received+=1;
               
                if(poolusers[poolId][currentUseraddress].payment_received>=3)
                {
                         poolcurrRegisterUserID[poolId]++;
                        userStruct = PoolUserStruct({
                            isExist:true,
                            id:poolcurrRegisterUserID[poolId],
                            payment_received:0,
                            reEntry: 0,
                            paid_entry:false
                        });
                       poolusers[poolId][currentUseraddress] = userStruct;
                      pooluserList[poolId][poolcurrRegisterUserID[poolId]]=currentUseraddress;
                      poolusers[poolId][currentUseraddress].reEntry+=1;
                      emit regPoolEntry(currentUseraddress, poolId, block.timestamp,poolcurrRegisterUserID[poolId],users[currentUseraddress].id,false);           
                    poolactiveUserID[poolId]+=1;
                   
                }
       payable((devWallet)).transfer(percentage(Pool_Entry_fee[poolId],5));
       sendBalance();
       
    }
    
   
   function sendBalance() private
    {
     uint256 balance = getMaticBalance();
        if(balance>0){
         payable((ownerWallet)).transfer(balance);
        }
    }

     function getMaticBalance() public view returns(uint) {
    return address(this).balance;
    }

    function percentage(uint256 price, uint256 per) internal pure returns (uint256) {
        return price * per / 100;

     }
    
    function viewUserReferral(address _user) public view returns(address) {
        return userList[users[_user].referrerID];
    }
    
    function checkUserExist(address _user) public view returns(bool) {
        return users[_user].isExist;
    }

    function getPoolUserPoolDetails(address _user) public view returns(uint256 [] memory _paymentReceived,uint256 [] memory _reEntry,bool [] memory _activePool_List) {
      //uint256[11] memory Payment_Received_List;
      uint[] memory payment_Received_List = new uint[](11);
      uint[] memory reEntry_List = new uint[](11);
      bool[] memory activePool_List = new bool[](11);

        for(uint i = 1 ;i <= 10 ; i ++)
        {
            payment_Received_List[i] = poolusers[i][_user].payment_received;
            reEntry_List[i] = poolusers[i][_user].reEntry;
            activePool_List[i] = poolusers[i][_user].isExist;
        }

        return (payment_Received_List,reEntry_List,activePool_List);
    }

    function getPoolUserPoolDetailsPoolWise(address _user,uint256 pool_id) public view returns(uint256 _paymentReceived,uint256 _reEntry,bool _activePool_List) {
        return (poolusers[pool_id][_user].payment_received,poolusers[pool_id][_user].reEntry,poolusers[pool_id][_user].isExist);
    }

    function totalUserCount() external view returns(uint256[] memory counts)
    {
        uint[] memory count = new uint[](11);
        for(uint i = 1 ;i <= 10 ; i ++)
        {
            count[i] = poolcurrRegisterUserID[i];
        }

        return count;
    }

   
}