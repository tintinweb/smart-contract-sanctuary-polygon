/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

pragma solidity 0.5.4;

interface IBEP20 {
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

contract Test {
     using SafeMath for uint256;
  
     
    struct User {
        uint256 id;
        address referrer; 
        uint256 partnersCount;     
        uint256 genReward;
        uint256 lastTokenWithdraw; 
        uint8   currentLevel; 
        mapping(uint8 => bool) levelActive;
        mapping(uint8 => Board) boardMatrix;        
    }

     struct Board {
        address boardReferrer;
        address[] firstReferrals;
        address[] secondReferrals;
        uint8 reinvestCount;
        bool isBoardActive;
    }

    mapping(uint8 => uint256) public currentGlobalCount;
    mapping(uint8 => uint256) public globalCount;
    mapping(uint8 => mapping(uint256 => address)) public globalIndex;

    mapping(uint8 => uint256) public communityGlobalCount;
    mapping(uint8 => mapping(uint256 => address)) public communityGlobalIndex;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    mapping(uint8 => uint256) public levelPrice;

    uint256[] public REFERRAL_PERCENTS = [100,50];
    uint256 public communityPercent=10;
    uint256 public lastUserId = 2; 
    uint256 public INTEREST_CYCLE = 1 hours; 
    
    uint256 public  total_withdraw;

    IBEP20 BUSD;

    address public owner; 
    address payable public devAddress; 
    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event CommunityReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event BoardReward(address  _user,  uint256 reward, uint8 level, uint8 sublevel);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
        

    constructor(address ownerAddress, address payable _devAddress) public 
    {
        owner = ownerAddress;
        devAddress=_devAddress; 

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 0,
            genReward:0,
            lastTokenWithdraw:block.timestamp,
            currentLevel:1   
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for(uint8 i=1; i<13; i++) {
            currentGlobalCount[i]=1;
            globalCount[i]=1;
            globalIndex[i][1]=ownerAddress;
            communityGlobalCount[i]=1;
            communityGlobalIndex[i][1]=ownerAddress;
            users[ownerAddress].levelActive[i]=true;
            users[ownerAddress].boardMatrix[i].isBoardActive=true;
        }

        levelPrice[1]=1e18;
        levelPrice[2]=2e18;
        levelPrice[3]=4e18;
        levelPrice[4]=8e18;
        levelPrice[5]=16e18;
        levelPrice[6]=32e18;
        levelPrice[7]=64e18;
        levelPrice[8]=128e18;
        levelPrice[9]=256e18;
        levelPrice[10]=512e18;
    } 
    

    function withdrawBalance(uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner!");
        msg.sender.transfer(amt);
    }  

     function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists!");
        require(isUserExists(referrerAddress), "referrer not exists!");
        require(msg.value==levelPrice[1],"Insufficient Amount!");
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

        communityGlobalCount[1]+=1;
        communityGlobalIndex[1][communityGlobalCount[1]]=userAddress;
        
        users[userAddress].levelActive[1]=true;
        users[referrerAddress].partnersCount+=1;
        

        address boardRef=globalIndex[1][currentGlobalCount[1]];

        if(users[boardRef].boardMatrix[1].firstReferrals.length<2) {
           users[userAddress].boardMatrix[1].boardReferrer=boardRef;
           users[boardRef].boardMatrix[1].firstReferrals.push(userAddress); 
        }
           
        else {
            users[userAddress].boardMatrix[1].boardReferrer=boardRef;
            users[boardRef].boardMatrix[1].secondReferrals.push(userAddress);  
            if(users[boardRef].boardMatrix[1].secondReferrals.length==4) {
            updateBoard(boardRef,1);
           }
        }

        address upline=referrerAddress;
        uint256 leftPer=150;
        for(uint8 i=0; i<2; i++)
        {
            uint256 reward=(levelPrice[1].mul(REFERRAL_PERCENTS[i])).div(1000);
            address(uint160(upline)).transfer(reward);
            emit ReferralReward(upline, msg.sender, reward, 1, i+1);
            upline=users[upline].referrer;
            leftPer=leftPer-REFERRAL_PERCENTS[i];
            if(upline==address(0))
            {
                devAddress.transfer((levelPrice[1].mul(leftPer)).div(1000));
                break;
            }
        }

        uint256 leftCom=100;
        uint256 globalId=lastUserId-1;
        for(uint8 j=1; j<=10; j++)
        {
            uint256 reward=(levelPrice[1].mul(communityPercent)).div(1000);
            address(uint160(idToAddress[globalId])).transfer(reward);
            emit CommunityReward(idToAddress[globalId], msg.sender, reward, 1, j);        
            globalId--;
            leftCom=leftCom-communityPercent;
            if(globalId==0)
            {
                devAddress.transfer((levelPrice[1].mul(leftCom)).div(1000));
                break;
            }           
        }
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function buyLevel(uint8 level) public payable
    {
        require(isUserExists(msg.sender), "user not exists!");
        require(level<11, "Max 10 Level!");  
        require(users[msg.sender].levelActive[level-1],"Buy Previous Level First!");
        require(!users[msg.sender].levelActive[level],"Level Already Activated!");
        require(msg.value==levelPrice[level],"Insufficient Amount!");
        users[msg.sender].levelActive[level]=true;

        uint256 mintedToken=getMintedToken(msg.sender);
        users[msg.sender].genReward+=mintedToken;
        users[msg.sender].currentLevel=level;
        users[msg.sender].lastTokenWithdraw=block.timestamp;

        communityGlobalCount[level]+=1;
        communityGlobalIndex[level][communityGlobalCount[level]]=msg.sender;
    
        address boardRef=globalIndex[level][currentGlobalCount[level]];

        if(users[boardRef].boardMatrix[level].firstReferrals.length<2) {
            users[msg.sender].boardMatrix[level].boardReferrer=boardRef;            
            users[boardRef].boardMatrix[level].firstReferrals.push(msg.sender); 
        }
                
        else {
           users[boardRef].boardMatrix[level].secondReferrals.push(msg.sender);  
           users[msg.sender].boardMatrix[level].boardReferrer=boardRef;
           if(users[boardRef].boardMatrix[level].secondReferrals.length==4) {
            updateBoard(boardRef,level);
           }
        }
        

        address upline=users[msg.sender].referrer;
        uint256 leftPer=150;
        for(uint8 i=0; i<2;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(levelPrice[level].mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, msg.sender, reward, level, i+1);            
                leftPer=leftPer-REFERRAL_PERCENTS[i];
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                devAddress.transfer((levelPrice[level].mul(leftPer)).div(1000));
                break;
            }
        }

        uint256 globalId=communityGlobalCount[level]-1;
        uint8 j=1;
        uint256 leftCom=100;
        while(j<11)
        {
            if(users[communityGlobalIndex[level][globalId]].levelActive[level])
            {
                uint256 reward=(levelPrice[level].mul(communityPercent)).div(1000);   
                address(uint160(communityGlobalIndex[level][globalId])).transfer(reward);            
                emit CommunityReward(communityGlobalIndex[level][globalId], msg.sender, reward, level, j);
                leftCom=leftCom-communityPercent;
                j++;         
            }
            globalId--;
            if(globalId==0)
            {
                devAddress.transfer((levelPrice[level].mul(leftCom)).div(1000));
                break;
            }
        }
        address refer= communityGlobalIndex[level][communityGlobalCount[level]-1];
        emit BuyNewLevel(msg.sender, users[msg.sender].id, level, refer, users[refer].id);
    }  


    function updateBoard(address user, uint8 level) private {
       
        if(users[user].boardMatrix[level].reinvestCount<1) { // when user's board breaking first time
            address newBoardUser;
            address[] memory allBoardUser=findNewBoardUser(user, level);
            newBoardUser=allBoardUser[0]; 

            //===== adding new member in board 
            globalCount[level]=globalCount[level]+1;
            globalIndex[level][globalCount[level]]=newBoardUser;

            users[newBoardUser].boardMatrix[level].isBoardActive=true;
            users[user].boardMatrix[level].firstReferrals=new address[](0);
            users[user].boardMatrix[level].secondReferrals=new address[](0);

            //===== for first level of reinvested user
            users[user].boardMatrix[level].firstReferrals.push(allBoardUser[1]);
            users[allBoardUser[1]].boardMatrix[level].boardReferrer=user;
            users[user].boardMatrix[level].firstReferrals.push(allBoardUser[2]);
            users[allBoardUser[2]].boardMatrix[level].boardReferrer=user;

            //===== for first level of new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[3]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[4]);
            users[allBoardUser[4]].boardMatrix[level].boardReferrer=newBoardUser;

            //===== for second level of reinvested user
            users[user].boardMatrix[level].secondReferrals.push(allBoardUser[5]);
            users[allBoardUser[5]].boardMatrix[level].boardReferrer=user;

            //===== increasing reinvest
            users[user].boardMatrix[level].reinvestCount+=1;
            address(uint160(user)).transfer(levelPrice[level]);
            emit BoardReward(user, levelPrice[level], level, 1);
        }
        else {  // when user's board breaking second time
            address newBoardUser;
            address newBoardUser2;
            address[] memory allBoardUser=findNewBoardUser(user, level);

            newBoardUser=allBoardUser[0]; 
            newBoardUser2=allBoardUser[1]; 

            //===== adding new member in board 
            globalCount[level]=globalCount[level]+1;
            globalIndex[level][globalCount[level]]=newBoardUser;
            globalCount[level]=globalCount[level]+1;
            globalIndex[level][globalCount[level]]=newBoardUser2;

            users[newBoardUser].boardMatrix[level].isBoardActive=true;
            users[newBoardUser2].boardMatrix[level].isBoardActive=true;
            
            //===== removing user from board after completing 2 reinvest
            users[user].boardMatrix[level].isBoardActive=false;
            users[user].boardMatrix[level].firstReferrals=new address[](0);
            users[user].boardMatrix[level].secondReferrals=new address[](0);

            //===== for first level of first new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[2]);
            users[allBoardUser[2]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[3]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;

            //===== for first level of second new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[4]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[5]);
            users[allBoardUser[4]].boardMatrix[level].boardReferrer=newBoardUser;
            
            //===== increasing reinvest
            users[user].boardMatrix[level].reinvestCount+=1;
            address(uint160(user)).transfer(levelPrice[level]*2);
            emit BoardReward(user, levelPrice[level], level, 2);
            currentGlobalCount[level]=currentGlobalCount[level]+1;
        }
    }

    function withdrawMintedToken() public{
        require(isUserExists(msg.sender),"User not exist!");
        uint256 mintedToken=getMintedToken(msg.sender);
        uint256 totalReward=users[msg.sender].genReward+mintedToken;
        users[msg.sender].genReward=0;
        users[msg.sender].lastTokenWithdraw=block.timestamp;
    }

    function findNewBoardUser(address user, uint8 level) public view returns(address[] memory){
        address[] memory allBoardUser = new  address[](6);
        uint8 k=0;
        for(uint8 i=0; i<6;i++){
            if(i<2){
                if(users[users[user].boardMatrix[level].firstReferrals[i]].partnersCount>=2){
                    allBoardUser[k]= users[user].boardMatrix[level].firstReferrals[i]; 
                    k++;             
                }
            }
            else{
                    if(users[users[user].boardMatrix[level].secondReferrals[i-2]].partnersCount>=2){
                    allBoardUser[k]= users[user].boardMatrix[level].secondReferrals[i-2];    
                    k++;          
                }
            }
        }

        for(uint8 i=0; i<6;i++){
            if(i<2){
                if(users[users[user].boardMatrix[level].firstReferrals[i]].partnersCount==1){
                    allBoardUser[k]= users[user].boardMatrix[level].firstReferrals[i];     
                    k++;         
                }
            }
            else{
                    if(users[users[user].boardMatrix[level].secondReferrals[i-2]].partnersCount==1){
                    allBoardUser[k]= users[user].boardMatrix[level].secondReferrals[i-2];   
                    k++;           
                }
            }
        }

        for(uint8 i=0; i<6;i++){
            if(i<2){
                if(users[users[user].boardMatrix[level].firstReferrals[i]].partnersCount==0){
                    allBoardUser[k]= users[user].boardMatrix[level].firstReferrals[i]; 
                    k++;             
                }
            }
            else{
                    if(users[users[user].boardMatrix[level].secondReferrals[i-2]].partnersCount==0){
                    allBoardUser[k]= users[user].boardMatrix[level].secondReferrals[i-2];
                    k++;              
                }
            }
        }
        
        return allBoardUser;
    }

    function getMintedToken(address user) public view returns(uint256){
        uint8 level=users[user].currentLevel;
        uint256 perSecondToken=level/INTEREST_CYCLE;
        return perSecondToken*(users[user].lastTokenWithdraw-block.timestamp);
    }
    

    function getUserBoard(address user, uint8 level) public view returns(uint256[] memory, address[] memory, uint8 reinvestCount , uint256 bUser) {
        address[] memory allBoardUser = new  address[](6);
        uint256[] memory allBoardUserId = new  uint256[](6);
        uint8 k=0;
        if(users[user].levelActive[level])
        {
            while(true) {
                if(users[user].boardMatrix[level].isBoardActive)
                break;
                user=users[user].boardMatrix[level].boardReferrer;
            }
            for(uint8 i=0; i<users[user].boardMatrix[level].firstReferrals.length; i++){       
                    allBoardUser[k]= users[user].boardMatrix[level].firstReferrals[i];
                    allBoardUserId[k]= users[users[user].boardMatrix[level].firstReferrals[i]].id; 
                    k++;             
            }
            for(uint8 i=0; i<users[user].boardMatrix[level].secondReferrals.length; i++) {                  
                    allBoardUser[k]= users[user].boardMatrix[level].secondReferrals[i];
                    allBoardUserId[k]= users[users[user].boardMatrix[level].secondReferrals[i]].id; 
                    k++;
            }
      
        }
       return(allBoardUserId, allBoardUser, users[user].boardMatrix[level].reinvestCount, users[user].id);
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