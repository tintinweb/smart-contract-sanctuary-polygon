/**
 *Submitted for verification at polygonscan.com on 2022-10-30
*/

pragma solidity 0.5.4;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract OCN {
     using SafeMath for uint256;
  
     
    struct User {
        uint256 id;
        address referrer; 
        uint256 partnersCount;     
        uint256 genReward;
        uint256 lastTokenWithdraw; 
        uint256   currentLevel; 
        mapping(uint8 => bool) levelActive;
        mapping(uint8 => Board) boardMatrix;        
    }

     struct Board {
        address boardReferrer;
        address[] firstReferrals;
        uint8 reinvestCount;
    }

    uint256 public  maticRate =10e18;

    mapping(uint8 => uint256) public currentGlobalCount;
    mapping(uint8 => uint256) public globalCount;
    mapping(uint8 => mapping(uint256 => address)) public globalIndex;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    mapping(uint8 => uint256) public levelPrice;
    mapping(uint8 => uint256) public boardReward;

    uint256[] public REFERRAL_PERCENTS = [250];
    uint256 public adminPercent=10;
    uint256 public lastUserId = 2;
    uint256 public liquidityFee = 5; 
    uint256 public INTEREST_CYCLE = 1 days; 
    
    uint256 public  total_withdraw;
    uint256 public  total_liquidity;

    ERC20 OceanCyberNetics;

    address public owner; 
    address payable public devAddress; 
    address payable public commissionAddress; 
    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel, uint256 currentRate);
    
    event BoardReward(address  _user,  uint256 reward, uint8 level, uint8 sublevel, uint8 autoBuy, uint256 currentRate);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
    event onWithdraw(address  _user, uint256 amount);
    event BuyGameSlot(address  _user, uint256 game);

    constructor(address ownerAddress, address payable _devAddress, address payable commissionAddress_, ERC20 OceanCyberNetics_) public 
    {
        owner = ownerAddress;
        devAddress=_devAddress; 
        OceanCyberNetics=OceanCyberNetics_;
        commissionAddress=commissionAddress_;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 0,
            genReward:0,
            lastTokenWithdraw:block.timestamp,
            currentLevel:10  
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for(uint8 i=1; i<11; i++) {
            currentGlobalCount[i]=1;
            globalCount[i]=1;
            globalIndex[i][1]=ownerAddress;
            users[ownerAddress].levelActive[i]=true;
        }

        levelPrice[1]=10e18;
        levelPrice[2]=20e18;
        levelPrice[3]=40e18;
        levelPrice[4]=80e18;
        levelPrice[5]=160e18;
        levelPrice[6]=320e18;
        levelPrice[7]=640e18;
        levelPrice[8]=1280e18;
        levelPrice[9]=2560e18;
        levelPrice[10]=5120e18;

        boardReward[1]=3e18;
        boardReward[2]=6e18;
        boardReward[3]=12e18;
        boardReward[4]=24e18;
        boardReward[5]=48e18;
        boardReward[6]=96e18;
        boardReward[7]=192e18;
        boardReward[8]=384e18;
        boardReward[9]=768e18;
        boardReward[10]=1436e18;
    } 
    

    function withdrawBalance(uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner!");
        msg.sender.transfer(amt);
    }  

    function withdrawToken(ERC20 token,uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner");
        token.transfer(msg.sender,amt);       
    } 

    function setPrice(uint256 price) public {
        require((msg.sender == owner || msg.sender == devAddress), "only Owner");
        maticRate=price;
    }

    function changeDevAddress(address payable _dev) public {
        require((msg.sender == owner || msg.sender == devAddress), "only Owner");
        devAddress=_dev;
    }

     function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists!");
        require(isUserExists(referrerAddress), "referrer not exists!");        
        require(((msg.value*maticRate)/1e18)>=levelPrice[1], "Minimum 10 USD!");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract!");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            genReward:0,
            lastTokenWithdraw:block.timestamp,
            currentLevel:1   
        });
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].levelActive[1]=true;
        users[referrerAddress].partnersCount+=1;

        if(users[referrerAddress].partnersCount==2 && referrerAddress!=owner)
        {
            for(uint8 i=1; i<11; i++){
                if(users[referrerAddress].levelActive[i]){                            
                    globalCount[i]=globalCount[i]+1;
                    globalIndex[i][globalCount[i]]=referrerAddress;
                }
                else
                break;
            }
        }
                
        address boardRef=globalIndex[1][currentGlobalCount[1]];

        if(users[boardRef].boardMatrix[1].firstReferrals.length<1) {
           users[boardRef].boardMatrix[1].firstReferrals.push(userAddress); 
        }           
        else {
            users[boardRef].boardMatrix[1].reinvestCount+=1;
            uint256 reward=(boardReward[1].mul(1e18)).div(maticRate);
            address(uint160(boardRef)).transfer(reward);
            emit BoardReward(boardRef, reward, 1, users[boardRef].boardMatrix[1].reinvestCount, 0, maticRate);
            if(users[boardRef].boardMatrix[1].reinvestCount<3 || boardRef==owner)
            {
                users[boardRef].boardMatrix[1].firstReferrals=new address[](0);
                currentGlobalCount[1]=currentGlobalCount[1]+1;
                globalCount[1]=globalCount[1]+1;
                globalIndex[1][globalCount[1]]=boardRef;
            }
            else{
                users[boardRef].boardMatrix[1].firstReferrals=new address[](0);
                currentGlobalCount[1]=currentGlobalCount[1]+1;
                if(users[boardRef].levelActive[2])
                {
                    uint256 breward=(levelPrice[2].mul(1e18)).div(maticRate);
                    address(uint160(boardRef)).transfer(breward);
                    emit BoardReward(boardRef, breward, 1, 4, 0, maticRate);    
                }
                else
                updateBoard(boardRef, 2);
            } 
        }

        address upline=referrerAddress;
       
        for(uint8 i=0; i<1; i++)
        {
            uint256 reward=(msg.value.mul(REFERRAL_PERCENTS[i])).div(1000);
            address(uint160(upline)).transfer(reward);
            emit ReferralReward(upline, msg.sender, reward, 1, i+1, maticRate);
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                break;
            }
        }

        uint256 reward=(msg.value.mul(adminPercent)).div(100);
        commissionAddress.transfer(reward);

        lastUserId++;
        total_liquidity+=(msg.value.mul(liquidityFee)).div(100);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function adminRegistration(address userAddress, address referrerAddress, uint256 _jamt) public 
    {
        require((msg.sender == owner || msg.sender == devAddress), "only Owner");
        require(!isUserExists(userAddress), "user exists!");
        require(isUserExists(referrerAddress), "referrer not exists!");       
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract!");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            genReward:0,
            lastTokenWithdraw:block.timestamp,
            currentLevel:1   
        });
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].levelActive[1]=true;
        users[referrerAddress].partnersCount+=1;

        if(users[referrerAddress].partnersCount==2 && referrerAddress!=owner)
        {
            for(uint8 i=1; i<11; i++){
                if(users[referrerAddress].levelActive[i]){                            
                    globalCount[i]=globalCount[i]+1;
                    globalIndex[i][globalCount[i]]=referrerAddress;
                }
                else
                break;
            }
        }
                
        address boardRef=globalIndex[1][currentGlobalCount[1]];

        if(users[boardRef].boardMatrix[1].firstReferrals.length<1) {
           users[boardRef].boardMatrix[1].firstReferrals.push(userAddress); 
        }           
        else {
            users[boardRef].boardMatrix[1].reinvestCount+=1;
            uint256 reward=(boardReward[1].mul(1e18)).div(maticRate);            
            emit BoardReward(boardRef, reward, 1, users[boardRef].boardMatrix[1].reinvestCount, 0, maticRate);
            if(users[boardRef].boardMatrix[1].reinvestCount<3 || boardRef==owner)
            {
                users[boardRef].boardMatrix[1].firstReferrals=new address[](0);
                currentGlobalCount[1]=currentGlobalCount[1]+1;
                globalCount[1]=globalCount[1]+1;
                globalIndex[1][globalCount[1]]=boardRef;
            }
            else{
                users[boardRef].boardMatrix[1].firstReferrals=new address[](0);
                currentGlobalCount[1]=currentGlobalCount[1]+1;
               
                if(users[boardRef].levelActive[2])
                {
                    uint256 breward=(levelPrice[2].mul(1e18)).div(maticRate);
                    emit BoardReward(boardRef, breward, 1, 4, 0, maticRate);    
                }
                else
                adminUpdateBoard(boardRef, 2);
            } 
        }

        address upline=referrerAddress;
     
        for(uint8 i=0; i<1; i++)
        {
            uint256 reward=(_jamt.mul(REFERRAL_PERCENTS[i])).div(1000);
            emit ReferralReward(upline, userAddress, reward, 1, i+1, maticRate);
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                break;
            }
        }

        lastUserId++;
        total_liquidity+=(_jamt.mul(liquidityFee)).div(100);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyGameSlot(address userAddress, uint256 amount) payable public 
    {
        require(isUserExists(userAddress), "User not exists!");  
        require(amount>1e18, "Insufficient Amount!"); 
        uint256 game=amount/1e18;            
        OceanCyberNetics.transferFrom(msg.sender,address(this),game);
        emit BuyGameSlot(userAddress, game);
    }


     function buyLevel(uint8 level) public payable
    {
        require(isUserExists(msg.sender), "user not exists!");
        require(level<11, "Max 10 Level!");  
        require(users[msg.sender].levelActive[level-1],"Buy Previous Level First!");
        require(!users[msg.sender].levelActive[level],"Level Already Activated!");
        require(((msg.value*maticRate)/1e18)>=levelPrice[level], "Insufficient Amount!");
        users[msg.sender].levelActive[level]=true;
        total_liquidity+=(levelPrice[level].mul(liquidityFee)).div(100);


        uint256 mintedToken=getMintedToken(msg.sender);

        users[msg.sender].genReward+=mintedToken;
        users[msg.sender].currentLevel=level;
        users[msg.sender].lastTokenWithdraw=block.timestamp;


        if(users[msg.sender].partnersCount>=2){
            globalCount[level]=globalCount[level]+1;
            globalIndex[level][globalCount[level]]=msg.sender;
        }

        address boardRef=globalIndex[level][currentGlobalCount[level]];
        if(users[boardRef].boardMatrix[level].firstReferrals.length<1) {
           users[boardRef].boardMatrix[level].firstReferrals.push(msg.sender); 
        }           
        else {
            users[boardRef].boardMatrix[level].reinvestCount+=1;
            uint256 reward=(boardReward[level].mul(1e18)).div(maticRate);
            address(uint160(boardRef)).transfer(reward);
            emit BoardReward(boardRef, reward, level, users[boardRef].boardMatrix[level].reinvestCount, 0, maticRate);
            if(users[boardRef].boardMatrix[level].reinvestCount<3 || boardRef==owner)
            {
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);                
                globalCount[level]=globalCount[level]+1;
                globalIndex[level][globalCount[level]]=boardRef;
                currentGlobalCount[level]=currentGlobalCount[level]+1;
            }
            else if(level<10){
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1;
                if(users[boardRef].levelActive[level+1])
                {
                    uint256 breward=(levelPrice[level+1].mul(1e18)).div(maticRate);
                    address(uint160(boardRef)).transfer(breward);
                    emit BoardReward(boardRef, breward, level, 4, 0, maticRate);    
                }
                else
                updateBoard(boardRef, level+1);
            }  
            else{
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1; 
            } 
        }
        

        address upline=users[msg.sender].referrer;
        
        for(uint8 i=0; i<1;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(msg.value.mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, msg.sender, reward, level, i+1, maticRate);            
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                break;
            }
        }

         uint256 reward=(msg.value.mul(adminPercent)).div(100);
        commissionAddress.transfer(reward);

       
        emit BuyNewLevel(msg.sender, users[msg.sender].id, level, boardRef, users[boardRef].id);
    }  

 
    function updateBoard(address user, uint8 level) private {
        users[user].levelActive[level]=true;
        total_liquidity+=(levelPrice[level].mul(liquidityFee)).div(100);

        uint256 mintedToken=getMintedToken(user);
        users[user].genReward+=mintedToken;
        users[user].currentLevel=level;
        users[user].lastTokenWithdraw=block.timestamp;
           
        if(users[user].partnersCount>=2){
        globalCount[level]=globalCount[level]+1;
        globalIndex[level][globalCount[level]]=user;
        }
        address boardRef=globalIndex[level][currentGlobalCount[level]];
       if(users[boardRef].boardMatrix[level].firstReferrals.length<1) {
           users[boardRef].boardMatrix[level].firstReferrals.push(user); 
        }           
        else {
            users[boardRef].boardMatrix[level].reinvestCount+=1;
            uint256 reward=(boardReward[level].mul(1e18)).div(maticRate);
            address(uint160(boardRef)).transfer(reward);
            emit BoardReward(boardRef, reward, level, users[boardRef].boardMatrix[level].reinvestCount, 0, maticRate);
            if(users[boardRef].boardMatrix[level].reinvestCount<3 || boardRef==owner)
            {
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1;
                globalCount[level]=globalCount[level]+1;
                globalIndex[level][globalCount[level]]=boardRef;
            }
            else if(level<10){
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1; 
                updateBoard(boardRef, level+1);
            }  
            else{
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1; 
            }        
        }

        
        address upline=users[user].referrer;
        uint256 slotValue=(levelPrice[level].mul(1e18)).div(maticRate);  
      
        for(uint8 i=0; i<1;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(slotValue.mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, user, reward, level, i+1, maticRate);
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                break;
            }
        }

        uint256 reward=(slotValue.mul(adminPercent)).div(100);
        commissionAddress.transfer(reward);
       
        emit BuyNewLevel(user, users[user].id, level, boardRef, users[boardRef].id);
    }

    function adminUpdateBoard(address user, uint8 level) private {
        users[user].levelActive[level]=true;
        total_liquidity+=(levelPrice[level].mul(liquidityFee)).div(100);

        uint256 mintedToken=getMintedToken(user);
        users[user].genReward+=mintedToken;
        users[user].currentLevel=level;
        users[user].lastTokenWithdraw=block.timestamp;

   
        if(users[user].partnersCount>=2){
        globalCount[level]=globalCount[level]+1;
        globalIndex[level][globalCount[level]]=user;
        }
        address boardRef=globalIndex[level][currentGlobalCount[level]];
       if(users[boardRef].boardMatrix[level].firstReferrals.length<1) {
           users[boardRef].boardMatrix[level].firstReferrals.push(user); 
        }           
        else {
            users[boardRef].boardMatrix[level].reinvestCount+=1;
            uint256 reward=(boardReward[level].mul(1e18)).div(maticRate);
            emit BoardReward(boardRef, reward, level, users[boardRef].boardMatrix[level].reinvestCount, 0, maticRate);
            if(users[boardRef].boardMatrix[level].reinvestCount<3 || boardRef==owner)
            {
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1;
                globalCount[level]=globalCount[level]+1;
                globalIndex[level][globalCount[level]]=boardRef;
            }
            else if(level<10){
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1; 
                updateBoard(boardRef, level+1);
            }  
            else{
                users[boardRef].boardMatrix[level].firstReferrals=new address[](0);
                currentGlobalCount[level]=currentGlobalCount[level]+1; 
            }        
        }

        
        address upline=users[user].referrer;
        uint256 slotValue=(levelPrice[level].mul(1e18)).div(maticRate);  
   
        for(uint8 i=0; i<1;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(slotValue.mul(REFERRAL_PERCENTS[i])).div(1000);
                emit ReferralReward(upline, user, reward, level, i+1, maticRate);            
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                break;
            }
        }

        emit BuyNewLevel(user, users[user].id, level, boardRef, users[boardRef].id);
    }

    function withdrawMintedToken() public {
        require(isUserExists(msg.sender),"User not exist!");
        uint256 mintedToken=getMintedToken(msg.sender);
        uint256 totalReward=users[msg.sender].genReward+mintedToken;
        require(totalReward>0,"Zero rewards!");
        users[msg.sender].genReward=0;
        users[msg.sender].lastTokenWithdraw=block.timestamp;
        OceanCyberNetics.transfer(msg.sender,totalReward);
        emit onWithdraw(msg.sender, totalReward);
    }  

    function getMintedToken(address user) public view returns(uint256){
        uint256 level=users[user].currentLevel;
        uint256 perSecondToken=(level.mul(1e18)).div(INTEREST_CYCLE);
        uint256 reward= perSecondToken*(block.timestamp-users[user].lastTokenWithdraw);
        return(reward);
    }
    

    function getUserBoard(uint8 level) public view returns(uint256, uint256) {
                uint256 boardMember;
                address boardUser=globalIndex[level][currentGlobalCount[level]];
                uint256 boardUserId=users[globalIndex[level][currentGlobalCount[level]]].id;
                if(users[boardUser].boardMatrix[level].firstReferrals.length>0)
                boardMember=users[users[boardUser].boardMatrix[level].firstReferrals[0]].id;
                return(boardUserId, boardMember);
       }
   
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
 
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}