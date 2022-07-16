/**
 *Submitted for verification at polygonscan.com on 2022-07-15
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
        uint256 currentLevel; 
        uint256 genReward;     
        mapping(uint8 => bool) levelActive;
        mapping(uint8 => Board) boardMatrix;        
        mapping(uint8 => Mint) minting;
    }

     struct Board {
        address boardReferrer;
        address[] firstReferrals;
        address[] secondReferrals;
        uint8 reinvestCount;
        bool isBoardActive;
    }

    struct Mint {
        uint256 lastTokenWithdraw;         
        bool isExpired;
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
    uint256 public liquidityFee = 5; 
    uint256 public INTEREST_CYCLE = 1 hours; 
    
    uint256 public  total_withdraw;
    uint256 public  total_liquidity;

    IBEP20 earthToken;

    address public owner; 
    address payable public devAddress; 
    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event CommunityReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event BoardReward(address  _user,  uint256 reward, uint8 level, uint8 sublevel);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
    event onWithdraw(address  _user, uint256 amount);

    constructor(address ownerAddress, address payable _devAddress, IBEP20 earthToken_) public 
    {
        owner = ownerAddress;
        devAddress=_devAddress; 
        earthToken=earthToken_;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: 0,
            currentLevel:12 , 
            genReward:0
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
            currentLevel:1 ,
            genReward:0  
        });
        users[userAddress] = user;

        
        users[userAddress].minting[1].lastTokenWithdraw=block.timestamp;

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
        total_liquidity+=(levelPrice[1].mul(liquidityFee)).div(100);
        
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
        total_liquidity+=(levelPrice[level].mul(liquidityFee)).div(100);

        users[msg.sender].genReward+=getMintedToken(msg.sender);  
        updateMintedToken(msg.sender);  
        users[msg.sender].currentLevel=level;
        users[msg.sender].minting[level].lastTokenWithdraw=block.timestamp;        

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

    function autoUpgrade(address user, uint8 level) private
    {
        users[user].levelActive[level]=true;
        total_liquidity+=(levelPrice[level].mul(liquidityFee)).div(100);  
        users[user].genReward+=getMintedToken(user);  
        updateMintedToken(user);   
        users[user].currentLevel=level;
        users[user].minting[level].lastTokenWithdraw=block.timestamp;
        

        communityGlobalCount[level]+=1;
        communityGlobalIndex[level][communityGlobalCount[level]]=user;
    
        address boardRef=globalIndex[level][currentGlobalCount[level]];

        if(users[boardRef].boardMatrix[level].firstReferrals.length<2) {
            users[user].boardMatrix[level].boardReferrer=boardRef;            
            users[boardRef].boardMatrix[level].firstReferrals.push(user); 
        }
                
        else {
           users[boardRef].boardMatrix[level].secondReferrals.push(user);  
           users[user].boardMatrix[level].boardReferrer=boardRef;
           if(users[boardRef].boardMatrix[level].secondReferrals.length==4) {
            updateBoard(boardRef,level);
           }
        }
        

        address upline=users[user].referrer;
        uint256 leftPer=150;
        for(uint8 i=0; i<2;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(levelPrice[level].mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, user, reward, level, i+1);            
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
                emit CommunityReward(communityGlobalIndex[level][globalId], user, reward, level, j);
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
        emit BuyNewLevel(user, users[user].id, level, refer, users[refer].id);
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
            if(users[user].partnersCount>=2)
            {
                if(level==10 || users[user].levelActive[level+1])
                {
                    address(uint160(user)).transfer(levelPrice[level]*2);
                    emit BoardReward(user, levelPrice[level]*2, level, 2);
                }
                else
                autoUpgrade(user,(level+1));
            }
            users[user].minting[level].isExpired=true;
            currentGlobalCount[level]=currentGlobalCount[level]+1;
        }
    }

    function withdrawMintedToken() public {
        require(isUserExists(msg.sender),"User not exist!");
        uint256 mintedToken=getMintedToken(msg.sender);
        uint256 totalReward=users[msg.sender].genReward+mintedToken;
        require(totalReward>0,"Zero rewards!");
        users[msg.sender].genReward=0;
        updateMintedToken(msg.sender);
        earthToken.transfer(msg.sender,totalReward);
        emit onWithdraw(msg.sender, totalReward);
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
        uint256 reward;
        uint256 level=1;
        for(uint8 i=1;i<=users[user].currentLevel;i++)
        {
            if(!users[user].minting[i].isExpired){
            uint256 perSecondToken=(level.mul(1e18)).div(INTEREST_CYCLE);
            reward+= perSecondToken*(block.timestamp-users[user].minting[i].lastTokenWithdraw);
            }
            level++;
        }
        return(reward);
    }

    function updateMintedToken(address user) private{
       
        for(uint8 i=1;i<=users[user].currentLevel;i++)
        {
          users[user].minting[i].lastTokenWithdraw=block.timestamp;
        }
       
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