/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

pragma solidity 0.5.11;

contract AutoPoly {
     address public ownerWallet;
     address payable internal creator1;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
      uint public pool4currUserID = 0;
      uint public pool5currUserID = 0;
      uint public pool6currUserID = 0;
      uint public pool7currUserID = 0;
      uint public pool8currUserID = 0;
      uint public pool9currUserID = 0;
      uint public pool10currUserID = 0;
      uint public pool11currUserID = 0;
      uint public pool12currUserID = 0;
      
      
    uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0;
      uint public pool7activeUserID = 0;
      uint public pool8activeUserID = 0;
      uint public pool9activeUserID = 0;
      uint public pool10activeUserID = 0;
      uint public pool11activeUserID = 0;
      uint public pool12activeUserID = 0;
      
            
      uint public unlimited_level_price=0;
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
        mapping(uint => uint) levelExpired;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received; 
    }
    
    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
       mapping (address => PoolUserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
          mapping (address => PoolUserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
          mapping (address => PoolUserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
          mapping (address => PoolUserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
          mapping (address => PoolUserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
          mapping (address => PoolUserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
          mapping (address => PoolUserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
          mapping (address => PoolUserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
          mapping (address => PoolUserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
          mapping (address => PoolUserStruct) public pool10users;
     mapping (uint => address) public pool10userList;
          mapping (address => PoolUserStruct) public pool11users;
     mapping (uint => address) public pool11userList;
         mapping (address => PoolUserStruct) public pool12users;
     mapping (uint => address) public pool12userList;
     mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=2 ether;
   uint pool1_price=2 ether;
   uint pool2_price=4 ether ;
   uint pool3_price=8 ether;
   uint pool4_price=16 ether;
   uint pool5_price=32 ether;
   uint pool6_price=64 ether;
   uint pool7_price=128 ether ;
   uint pool8_price=256 ether;
   uint pool9_price=512 ether;
   uint pool10_price=1024 ether;
   uint pool11_price=2048 ether;
   uint pool12_price=4096 ether;

   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
      event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time);
      
     event regPoolEntry(address indexed _user,uint _level,   uint _time);
        
    event getPoolPayment(address indexed _user,address indexed _receiver, uint _level, uint _time);
   
    UserStruct[] public requests;
     
      constructor(address payable _creator1) public {
          ownerWallet = msg.sender;
          creator1 = _creator1;

        LEVEL_PRICE[1] = 1.5 ether;
        LEVEL_PRICE[2] = 0.2 ether;
        LEVEL_PRICE[3] = 0.2 ether;
        unlimited_level_price=0.1 ether;

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
        
        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });

    pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pooluserStruct;
       pool1userList[pool1currUserID]=msg.sender;
      
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pooluserStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pooluserStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
        pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pooluserStruct;
       pool4userList[pool4currUserID]=msg.sender;

        pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pooluserStruct;
       pool5userList[pool5currUserID]=msg.sender;
              
         pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pooluserStruct;
       pool6userList[pool6currUserID]=msg.sender;
       
         pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0
        });
    pool7activeUserID=pool7currUserID;
       pool7users[msg.sender] = pooluserStruct;
       pool7userList[pool7currUserID]=msg.sender;
       
       pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0
        });
    pool8activeUserID=pool8currUserID;
       pool8users[msg.sender] = pooluserStruct;
       pool8userList[pool8currUserID]=msg.sender;
       
        pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0
        });
    pool9activeUserID=pool9currUserID;
       pool9users[msg.sender] = pooluserStruct;
       pool9userList[pool9currUserID]=msg.sender;
       
       
        pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
    pool10activeUserID=pool10currUserID;
       pool10users[msg.sender] = pooluserStruct;
       pool10userList[pool10currUserID]=msg.sender;
       
        pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
        
    pool11activeUserID=pool11currUserID;
       pool11users[msg.sender] = pooluserStruct;
       pool11userList[pool11currUserID]=msg.sender;
       
        pool11currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool11currUserID,
            payment_received:0
        });
  
pool12currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool12currUserID,
            payment_received:0
        });
    pool12activeUserID=pool12currUserID;
       pool12users[msg.sender] = pooluserStruct;
       pool12userList[pool12currUserID]=msg.sender;

      
      //// for creator1

  UserStruct memory userStruct1;
        currUserID++;

        userStruct1 = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 1,
            referredUsers:0
           
        });
        
        users[creator1] = userStruct1;
       userList[currUserID] =creator1;
       
       PoolUserStruct memory pooluserStruct1;
        
        pool1currUserID++;

        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
       pool1users[creator1] = pooluserStruct1;
       pool1userList[pool1currUserID]=creator1;
         
        pool2currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
       pool2users[creator1] = pooluserStruct1;
       pool2userList[pool2currUserID]=creator1;
            
        pool3currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
       pool3users[creator1] = pooluserStruct1;
       pool3userList[pool3currUserID]=creator1;

        pool4currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
       pool4users[creator1] = pooluserStruct1;
       pool4userList[pool4currUserID]=creator1;
        
        pool5currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
       pool5users[creator1] = pooluserStruct1;
       pool5userList[pool5currUserID]=creator1;
       
        pool6currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
       pool6users[creator1] = pooluserStruct1;
       pool6userList[pool6currUserID]=creator1;

        pool7currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0
        });
       pool7users[creator1] = pooluserStruct1;
       pool7userList[pool7currUserID]=creator1;

       pool8currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0
        });
       pool8users[creator1] = pooluserStruct1;
       pool8userList[pool8currUserID]=creator1;

        pool9currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0
        });
       pool9users[creator1] = pooluserStruct1;
       pool9userList[pool9currUserID]=creator1;
       
        pool10currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
       pool10users[creator1] = pooluserStruct1;
       pool10userList[pool10currUserID]=creator1;
       
       pool11currUserID++;
       pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool11currUserID,
            payment_received:0
       });
       pool11users[creator1] = pooluserStruct1;
       pool11userList[pool11currUserID]=creator1;

       pool12currUserID++;
        pooluserStruct1 = PoolUserStruct({
            isExist:true,
            id:pool12currUserID,
            payment_received:0
        });
       pool12users[creator1] = pooluserStruct1;
       pool12userList[pool12currUserID]=creator1;
      
      }
     
       function regUser(uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
        require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
       
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
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        
       payReferral(1,msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
   
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
         bool sent = false;
       
            uint level_price_local=0;
            if(_level>3){
            level_price_local=unlimited_level_price;
            }
            else{
            level_price_local=LEVEL_PRICE[_level];
            }
            sent = address(uint160(referer)).send(level_price_local);

            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                if(_level < 5 && users[referer].referrerID >= 1){
                    payReferral(_level+1,referer);
                }
                else
                {
                    sendBalance();
                }
               
            }
       
        if(!sent) {
          //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);

            payReferral(_level, referer);
        }
     }
   
       function buyPool1() public payable {
       require(users[msg.sender].isExist, "User Not Registered");
      require(!pool1users[msg.sender].isExist, "Already in AutoPool");
      
        require(msg.value == pool1_price, 'Incorrect Value');
        
        PoolUserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];
        
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool1Currentuser)).send(pool1_price);

            if (sent) {
                pool1users[pool1Currentuser].payment_received+=1;
                if(pool1users[pool1Currentuser].payment_received>=2)
                {
                    pool1activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool1Currentuser, 1, now);
            }
       emit regPoolEntry(msg.sender, 1, now);
    }
    
      function buyPool2() public payable {
          require(users[msg.sender].isExist, "User Not Registered");
      require(!pool2users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool2_price, 'Incorrect Value');
                 
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0
        });
       pool2users[msg.sender] = userStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       bool sent = false;
       sent = address(uint160(pool2Currentuser)).send(pool2_price);

            if (sent) {
                pool2users[pool2Currentuser].payment_received+=1;
                if(pool2users[pool2Currentuser].payment_received>=3)
                {
                    pool2activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool2Currentuser, 2, now);
            }
            emit regPoolEntry(msg.sender,2,  now);
    }
    
    
     function buyPool3() public payable {
         require(users[msg.sender].isExist, "User Not Registered");
      require(!pool3users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool3_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0
        });
       pool3users[msg.sender] = userStruct;
       pool3userList[pool3currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool3Currentuser)).send(pool3_price);

            if (sent) {
                pool3users[pool3Currentuser].payment_received+=1;
                if(pool3users[pool3Currentuser].payment_received>=3)
                {
                    pool3activeUserID+=1;
                }
                emit getPoolPayment(msg.sender,pool3Currentuser, 3, now);
            }
emit regPoolEntry(msg.sender,3,  now);
    }
    
    
    function buyPool4() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool4users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool4_price, 'Incorrect Value');
              
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0
        });
       pool4users[msg.sender] = userStruct;
       pool4userList[pool4currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool4Currentuser)).send(pool4_price);

            if (sent) {
                pool4users[pool4Currentuser].payment_received+=1;
                if(pool4users[pool4Currentuser].payment_received>=3)
                {
                    pool4activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool4Currentuser, 4, now);
            }
        emit regPoolEntry(msg.sender,4, now);
    }
    
    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool5users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool5_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0
        });
       pool5users[msg.sender] = userStruct;
       pool5userList[pool5currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool5Currentuser)).send(pool5_price);

            if (sent) {
                pool5users[pool5Currentuser].payment_received+=1;
                if(pool5users[pool5Currentuser].payment_received>=3)
                {
                    pool5activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool5Currentuser, 5, now);
            }
        emit regPoolEntry(msg.sender,5,  now);
    }
    
    function buyPool6() public payable {
      require(!pool6users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool6_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0
        });
       pool6users[msg.sender] = userStruct;
       pool6userList[pool6currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool6Currentuser)).send(pool6_price);

            if (sent) {
                pool6users[pool6Currentuser].payment_received+=1;
                if(pool6users[pool6Currentuser].payment_received>=3)
                {
                    pool6activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool6Currentuser, 6, now);
            }
        emit regPoolEntry(msg.sender,6,  now);
    }
    
    function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool7users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool7_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];
        
        pool7currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0
        });
       pool7users[msg.sender] = userStruct;
       pool7userList[pool7currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool7Currentuser)).send(pool7_price);

            if (sent) {
                pool7users[pool7Currentuser].payment_received+=1;
                if(pool7users[pool7Currentuser].payment_received>=3)
                {
                    pool7activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool7Currentuser, 7, now);
            }
        emit regPoolEntry(msg.sender,7,  now);
    }
    
    
    function buyPool8() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool8users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool8_price, 'Incorrect Value');
              
        PoolUserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];
        
        pool8currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0
        });
       pool8users[msg.sender] = userStruct;
       pool8userList[pool8currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool8Currentuser)).send(pool8_price);

            if (sent) {
                pool8users[pool8Currentuser].payment_received+=1;
                if(pool8users[pool8Currentuser].payment_received>=3)
                {
                    pool8activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool8Currentuser, 8, now);
            }
        emit regPoolEntry(msg.sender,8,  now);
    }
    
    function buyPool9() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool9users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool9_price, 'Incorrect Value');
              
        PoolUserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];
        
        pool9currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0
        });
       pool9users[msg.sender] = userStruct;
       pool9userList[pool9currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool9Currentuser)).send(pool9_price);

            if (sent) {
                pool9users[pool9Currentuser].payment_received+=1;
                if(pool9users[pool9Currentuser].payment_received>=3)
                {
                    pool9activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool9Currentuser, 9, now);
            }
        emit regPoolEntry(msg.sender,9,  now);
    }
    
    function buyPool10() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool10users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool10_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];
        
        pool10currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0
        });
       pool10users[msg.sender] = userStruct;
       pool10userList[pool10currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool10Currentuser)).send(pool10_price);

            if (sent) {
                pool10users[pool10Currentuser].payment_received+=1;
                if(pool10users[pool10Currentuser].payment_received>=3)
                {
                    pool10activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool10Currentuser, 10, now);
            }
        emit regPoolEntry(msg.sender, 10, now);
    }
    
    function buyPool11() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool11users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool11_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool11Currentuser=pool11userList[pool11activeUserID];
        
        pool11currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool11currUserID,
            payment_received:0
        });
       pool11users[msg.sender] = userStruct;
       pool11userList[pool11currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool11Currentuser)).send(pool11_price);

            if (sent) {
                pool11users[pool11Currentuser].payment_received+=1;
                if(pool11users[pool11Currentuser].payment_received>=3)
                {
                    pool11activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool11Currentuser, 11, now);
            }
        emit regPoolEntry(msg.sender, 11, now);
    }
    
    function buyPool12() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
      require(!pool12users[msg.sender].isExist, "Already in AutoPool");
        require(msg.value == pool12_price, 'Incorrect Value');
                
        PoolUserStruct memory userStruct;
        address pool12Currentuser=pool12userList[pool12activeUserID];
        
        pool12currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool12currUserID,
            payment_received:0
        });
       pool12users[msg.sender] = userStruct;
       pool12userList[pool12currUserID]=msg.sender;
       bool sent = false;
       sent = address(uint160(pool12Currentuser)).send(pool12_price);

            if (sent) {
                pool12users[pool12Currentuser].payment_received+=1;
                if(pool12users[pool12Currentuser].payment_received>=3)
                {
                    pool12activeUserID+=1;
                }
                 emit getPoolPayment(msg.sender,pool12Currentuser, 12, now);
            }
        emit regPoolEntry(msg.sender,12 , now);
    }
    
    
    
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
         if (!address(uint160(ownerWallet)).send(getEthBalance()))
         {
             
         }
    }
     
}