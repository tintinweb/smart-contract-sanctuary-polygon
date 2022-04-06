/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

pragma solidity 0.5.4;

contract Test{
    
    struct User {
        uint id;
        address payable referrer;
        uint partnersCount;   
        mapping(uint8 => bool) MT3Levels;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
        uint256 withdrawable;
        mapping(uint8 => uint256) holdAmount;
    }
    
    
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
    }
    
    struct X6 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint reinvestCount;
        uint256 RefvID;
    }

    uint256[] public REFERRAL_PERCENTS = [500,140,70,50,50,50,40];
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;

    mapping(address => uint256)  addressToUid;
    mapping(uint256 => address)  idToAddress2;

    uint256 public lastUserId = 2;

    uint256  maticRate =120*1e18;
    
    mapping(uint8 => mapping(uint256 => address)) public x3vId_number;
    mapping(uint8 => uint256) public x3CurrentvId;
    mapping(uint8 => uint256) public x3Index;
    
    address payable public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    mapping(uint8 => uint) public blevelPrice;
    mapping(uint8 => uint) public sponsorBonus;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event EntryBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event LevelBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event SponsorBonus(address indexed receiver, address indexed _from, uint _amount, uint8 level);
    event ReEntry(address indexed _user);
    event Withdraw(address indexed _user,uint256 amount);
    
   
  
    
    constructor() public {
        levelPrice[1]  = 2000*1e6;
        levelPrice[2]  = 3000*1e6;
        levelPrice[3]  = 5000*1e6;
        levelPrice[4]  = 7000*1e6;
        levelPrice[5]  = 8000*1e6;
        levelPrice[6]  = 10000*1e6;
        
        blevelPrice[1]  = 5000*1e6;
        blevelPrice[2]  = 6000*1e6;
        blevelPrice[3]  = 7000*1e6;
        blevelPrice[4]  = 8000*1e6;
        blevelPrice[5]  = 9000*1e6;
        blevelPrice[6]  = 10000*1e6;    
        
        owner = msg.sender;
        
        User memory user = User({
            id: 123456,
            referrer: address(0),
            partnersCount: uint(0),
            withdrawable: uint(0)
        });
        
        users[owner] = user;
        
       users[owner].MT3Levels[1] = true;

        idToAddress[123456] = owner;

        idToAddress2[1] = owner;
        addressToUid[owner] = 1;

        for (uint8 i = 1; i <= 6; i++) 
        {
            x3vId_number[i][1]=owner;
            x3Index[i]=1;
            x3CurrentvId[i]=1;
            users[owner].activeX3Levels[i] = true;
            users[owner].activeX6Levels[i] = true;
        } 
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender,owner,0);
    }

     function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(_amt);
    }

    function registrationExt(address payable referrerAddress,uint id) external payable {
        registration(msg.sender, referrerAddress, id);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (matrix == 1) 
        {
            require(msg.value == levelPrice[level] , "invalid price");
            require(level==1, "invalid level");
            
            require(!users[msg.sender].activeX3Levels[level], "level already activated");
        
            users[msg.sender].activeX3Levels[level] = true;
            address payable ref=users[msg.sender].referrer;
            uint ded=(msg.value*10)/100;
            owner.transfer(ded);
            uint rest=msg.value-ded;
            for(uint8 i=0;i<6;i++)
            {
                if(ref!=address(0)) 
                {
                    if(users[ref].activeX3Levels[level])
                    {
                    ref.transfer((rest*REFERRAL_PERCENTS[i])/100);
                    emit LevelBonus(ref, msg.sender, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    }
                    ref=users[ref].referrer;
                }
                else
                {
                    i=6;
                }
                
            }
            
            emit Upgrade(msg.sender, users[msg.sender].referrer, 1, level);
        }
        else 
        {
            
            require(msg.value == blevelPrice[level] , "invalid price");
            require(level==1, "invalid level");
           
            require(users[msg.sender].activeX3Levels[level], "buy working level first");
         
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            address freeX6Referrer = findFreeX6Referrer(level);
            
            users[msg.sender].activeX6Levels[level] = true;
            users[msg.sender].x6Matrix[level].currentReferrer = freeX6Referrer;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address payable referrerAddress, uint256 id) private{
        require(!isUserExists(userAddress), "user exists");
        require(idToAddress[id]==address(0) && id>=100000, "Invalid ID");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        require((msg.value*(maticRate/1e18)) == 120*1e18, "Minimum 120 USD!");
        
        User memory user = User({
            id: id,
            referrer: referrerAddress,
            partnersCount: 0,
            withdrawable:0
        });
        
        users[userAddress] = user;
        idToAddress[id] = userAddress;

        idToAddress2[lastUserId] = userAddress;
        addressToUid[userAddress] = lastUserId;
                   
        users[userAddress].referrer = referrerAddress;

        //=========== for mt3 matrix ==========
        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateMT3(userAddress, freeX3Referrer, 1);
        //=========== end mt3 matrix ==========

        lastUserId++;
        users[referrerAddress].partnersCount++;
         uint256 levelUSD=50*1e18;
        owner.transfer((msg.value*10)/100);
  
        for(uint8 i=0;i<7;i++)
        {
            if(referrerAddress!=address(0)) 
            {
                users[referrerAddress].withdrawable+=(((levelUSD*REFERRAL_PERCENTS[i])/1000)*1e18)/maticRate;                
                emit LevelBonus(referrerAddress, msg.sender, (((levelUSD*REFERRAL_PERCENTS[i])/1000)*1e18)/maticRate, i+1);
                referrerAddress=users[referrerAddress].referrer;
            }
            else
            break;
        }
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }   

    function updateMT3(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return address(uint160(referrerAddress)).transfer((20e18*1e18)/maticRate);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
       
               //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            updateMT3(referrerAddress, freeReferrerAddress, level);
        } else {
            users[owner].x3Matrix[level].reinvestCount++;
            return address(uint160(referrerAddress)).transfer((20e18/maticRate)*1e18);           
        }
    }

    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private{
        uint256 newIndex=x3Index[level]+1;
        x3vId_number[level][newIndex]=userAddress;
        x3Index[level]=newIndex;
        if(users[referrerAddress].holdAmount[level]<blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]) && level<6
        )
        {
          address(uint160(owner)).transfer((blevelPrice[level]*5)/100); 
          users[referrerAddress].holdAmount[level]=users[referrerAddress].holdAmount[level]+((blevelPrice[level]*95)/100);
          users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
          emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
          
          if(!(users[referrerAddress].activeX3Levels[level+1]) && users[referrerAddress].holdAmount[level]>=levelPrice[level+1])
          {
            autoUpgradeLevel(referrerAddress, (level+1));  
          }
          else
          {
              if(users[referrerAddress].holdAmount[level]>=blevelPrice[level+1] && !(users[referrerAddress].activeX6Levels[level+1]))
              {
                autoUpgrade(referrerAddress, (level+1));  
              }  
          }
        }
        else
        {
            if(level==6 && users[referrerAddress].x6Matrix[level].referrals.length==0)
            {
                users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
                emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
                emit ReEntry(referrerAddress);
                address(uint160(owner)).transfer((blevelPrice[level]*5)/100);
                uint256 ded=(blevelPrice[level]*5)/100+(blevelPrice[1]);
                address(uint160(referrerAddress)).transfer(blevelPrice[level]-ded);
                address freeX6Referrer = findFreeX6Referrer(1);
                users[referrerAddress].activeX6Levels[1] = true;
                updateX6Referrer(referrerAddress, freeX6Referrer, 1);
                emit Upgrade(referrerAddress, freeX6Referrer, 2, 1);
                return;
            }
            if(users[referrerAddress].x6Matrix[level].referrals.length < level+3) 
            {
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
            address(uint160(owner)).transfer((blevelPrice[level]*5)/100); 
            return address(uint160(referrerAddress)).transfer((blevelPrice[level]*95)/100);
            }
            users[referrerAddress].x6Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].referrals.length));
             if(level<6)
             {
                address(uint160(owner)).transfer((blevelPrice[level]*5)/100);            
           
                address(uint160(referrerAddress)).transfer((((blevelPrice[level]*95)/100)-sponsorBonus[level]));
             }
            
            if(users[referrerAddress].referrer!=address(0))
            {
            address(uint160(users[referrerAddress].referrer)).transfer(sponsorBonus[level]);
            emit SponsorBonus(users[referrerAddress].referrer,referrerAddress,sponsorBonus[level],1);
            }
            else
            address(uint160(owner)).transfer(sponsorBonus[level]);
            
            users[referrerAddress].x6Matrix[level].referrals = new address[](0);
            users[referrerAddress].activeX6Levels[level]=false;
            x3CurrentvId[level]=x3CurrentvId[level]+1;  //  After completion of two members
        }
        
    }

    function autoUpgradeLevel(address _user, uint8 level) private{
        if(!users[_user].activeX3Levels[level])
        {
            users[_user].activeX3Levels[level] = true;
            address payable ref=users[_user].referrer;
            uint ded=(levelPrice[level]*10)/100;
            owner.transfer(ded);
            uint rest=levelPrice[level]-ded;
            for(uint8 i=0;i<6;i++)
            {
                if(ref!=address(0)) 
                {
                     if(users[ref].activeX3Levels[level])
                    {
                    ref.transfer((rest*REFERRAL_PERCENTS[i])/100);
                    emit LevelBonus(ref, _user, (rest*REFERRAL_PERCENTS[i])/100, i+1);
                    }
                    ref=users[ref].referrer;
                }
                else
                {
                    i=6;
                }
            }
           users[_user].holdAmount[level-1]=users[_user].holdAmount[level-1]-levelPrice[level];
           emit Upgrade(_user, users[_user].referrer, 1, level);
        }
    }
    
    function autoUpgrade(address _user, uint8 level) private{
            if((users[_user].holdAmount[level-1]-blevelPrice[level])>0)
            {
             address(uint160(_user)).transfer(users[_user].holdAmount[level-1]-blevelPrice[level]);
            }
            users[_user].holdAmount[level-1]=0;
            address freeX6Referrer = findFreeX6Referrer(level);
            users[_user].activeX6Levels[level] = true;
            updateX6Referrer(_user, freeX6Referrer, level);
            emit Upgrade(_user, freeX6Referrer, 2, level);
    }


    function withdrawLevelIncome() public{
        require(users[msg.sender].withdrawable>0,"Insufficient Amount...!");
        uint8 i;
        uint256 payAble=(users[msg.sender].withdrawable*80)/100;
        uint256 rest=users[msg.sender].withdrawable-payAble;
        msg.sender.transfer(payAble);
   //     uint256 upline=users[msg.sender].;
        // for upline
        for(i=0;i<9;i++)
        {

        }
        // for downline
        for(i=0;i<9;i++)
        {

        }
        emit Withdraw(msg.sender,users[msg.sender].withdrawable);
    }

    
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].MT3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(uint8 level) public view returns(address){
            uint256 id=x3CurrentvId[level];
            return x3vId_number[level][id];
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }


    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount
                );
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool,uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].referrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

  
    function getUserHoldAmount(address userAddress) public view returns(uint256[] memory) {
		uint256[] memory levelHold = new uint256[](12);
		for(uint8 j=0; j<12; j++)
		{
		  levelHold[j]  =users[userAddress].holdAmount[j+1];
		}
		return (levelHold);
	}
    
    function transferOwnership(uint256 _place,uint8 level) public 
    {
     require(msg.sender==owner,"Only Owner");
     x3CurrentvId[level]=_place;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}