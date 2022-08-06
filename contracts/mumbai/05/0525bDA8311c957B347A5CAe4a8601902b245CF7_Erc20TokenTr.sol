/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

pragma solidity 0.5.11;

contract Erc20TokenTr {
     address public ownerWallet;
      uint public currUserID = 0;

       uint[11] pool1currRegisterUserID;
       uint[11] pool1activeUserID;
      
     
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
    }
    
     
     struct PoolUserStruct {
        bool isExist;
        uint id;
        uint payment_received; 
        bool paid_entry;
    }
    

    

    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
     
  
      mapping (uint=>mapping(address => PoolUserStruct)) public poolusers;
     mapping (uint => address) public pooluserList;
     
   
    mapping(uint => uint256) public Pool_Entry_fee;
   
   
   //  event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
     event getMoneyForPoolLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time,uint poolid,uint poolno);
     event getMoneyForPoolLevelEventReinvest(address indexed _user, address indexed _referral, uint _level, uint _time,uint poolid,uint poolno);
     event regPoolEntry(address indexed _user,uint _level,   uint _time,uint poolid,uint userid,bool paid_entry);
   
     
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level);
    event fastcashbonusevent(address indexed _user, uint _level);
   
  
     
      constructor() public {
          ownerWallet = msg.sender;

        Pool_Entry_fee[1] = 0.01 ether;
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
            referredUsers:0
           
        });
        
        users[ownerWallet] = userStruct;
       
       userList[currUserID] = ownerWallet;
       
       
         PoolUserStruct memory pooluserStruct;
        
       
       /* Pool All */
       
       for(uint i = 1 ; i<= 10; i++)
       {
        pool1currRegisterUserID[i]++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currRegisterUserID[i],
            payment_received:0,
            paid_entry:true
        });
    pool1activeUserID[i]=pool1currRegisterUserID[i];
       poolusers[i][msg.sender] = pooluserStruct;
       pooluserList[pool1currRegisterUserID[i]]=msg.sender;
       }
       
      }
     
       function regUser(uint _referrerID) public payable {
            require(!users[msg.sender].isExist, "User Exist");
          
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0
            
        });
       users[msg.sender] = userStruct;
       
       userList[currUserID]=msg.sender;
    //   payReferral(1,msg.sender);
    //    emit regLevelEvent(msg.sender, userList[_referrerID], now);
           buyPool(1);
    }
   
   
   
   
   
   function payPoolReferral(uint _level, address _user,uint _poolno) internal {
        address referer;
        referer = userList[users[_user].referrerID];
         bool sent = false;
       
            sent = address(uint160(referer)).send(percentage(Pool_Entry_fee[_poolno],10));

            if (sent) {
                emit getMoneyForPoolLevelEvent(referer, msg.sender, _level, now,users[_user].referrerID,_poolno);
            }
       
        if(!sent) {
         //   emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            
        }
     
     }
     
     function payPoolPaymentReferral(uint _level, address _user,uint _poolno) internal {
         if(users[_user].referrerID>0){
            address referer;
            referer = userList[users[_user].referrerID];
             bool sent = false;
                sent = address(uint160(referer)).send(Pool_Entry_fee[_poolno] * 5 /100);
    
                if (sent) {
                    emit getMoneyForPoolLevelEventReinvest(referer, msg.sender, _level, now,users[_user].referrerID,_poolno);
                }
           
            if(!sent) {
             //   emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
                
            }
        }
     }
   
   
       function buyPool(uint poolId) public payable {
       require(users[msg.sender].isExist, "User Not Registered");
       require(!poolusers[poolId][msg.sender].isExist, "Already in AutoPool");
        require(msg.value == Pool_Entry_fee[poolId], "Incorrect Value");
        
        PoolUserStruct memory userStruct;
        pool1currRegisterUserID[poolId]++;
        
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currRegisterUserID[poolId],
            payment_received:0,
            paid_entry:true
        });
        poolusers[poolId][msg.sender] = userStruct;
        pooluserList[pool1currRegisterUserID[poolId]]=msg.sender;
       
       payPoolReferral(1,msg.sender,poolId);
       emit regPoolEntry(msg.sender, poolId, now,pool1currRegisterUserID[poolId],users[msg.sender].id,true);
    
        if(poolusers[poolId][pooluserList[pool1currRegisterUserID[poolId]-1]].paid_entry)
        {
            if(address(uint160(pooluserList[pool1currRegisterUserID[poolId]-1])).send(percentage(Pool_Entry_fee[poolId],20)))
            {
                emit fastcashbonusevent(pooluserList[pool1currRegisterUserID[poolId]-1],poolId);
            }
        }
        else
        {
            if(address(uint160(pooluserList[pool1currRegisterUserID[poolId]-2])).send(percentage(Pool_Entry_fee[poolId],20)))
            {
                emit fastcashbonusevent(pooluserList[pool1currRegisterUserID[poolId]-2],poolId);
            }
        }
     
       bool sent = false;
       sent = address(uint160(pooluserList[pool1activeUserID[poolId]])).send(percentage(Pool_Entry_fee[poolId],50));
    
            if (sent) {
                emit getPoolPayment(msg.sender,pooluserList[pool1activeUserID[poolId]], poolId);
                /* Payment referral for pool payment   */
                address currentUseraddress=pooluserList[pool1activeUserID[poolId]];
                payPoolPaymentReferral(1,currentUseraddress,poolId);
                
                poolusers[poolId][currentUseraddress].payment_received+=1;
               
                if(poolusers[poolId][currentUseraddress].payment_received>=3)
                {
                         pool1currRegisterUserID[poolId]++;
                        userStruct = PoolUserStruct({
                            isExist:true,
                            id:pool1currRegisterUserID[poolId],
                            payment_received:0,
                            paid_entry:false
                        });
                       poolusers[poolId][currentUseraddress] = userStruct;
                      pooluserList[pool1currRegisterUserID[poolId]]=currentUseraddress;
                      emit regPoolEntry(currentUseraddress, poolId, now,pool1currRegisterUserID[poolId],users[currentUseraddress].id,false);           
                    pool1activeUserID[poolId]+=1;
                   
                }
       }
       sendBalance();
       
    }
    
   
   function sendBalance() private
    {
     
        if(getMaticBalance()>0){
         if (!address(uint160(ownerWallet)).send(getMaticBalance()))
         {
             
         }
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
   
}