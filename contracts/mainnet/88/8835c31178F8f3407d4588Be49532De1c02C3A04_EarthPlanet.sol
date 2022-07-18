/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-18
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

contract EarthPlanet{
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
        address[] secondReferrals;
        uint8 reinvestCount;
        bool isBoardActive;
    }

    uint256 public  maticRate =10e18;

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
    uint256 public INTEREST_CYCLE = 1 days; 
    
    uint256 public  total_withdraw;
    uint256 public  total_liquidity;

    ERC20 earthToken;

    address public owner; 
    address payable public devAddress; 
    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel, uint256 currentRate);
    event CommunityReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel, uint256 currentRate);
    event BoardReward(address  _user,  uint256 reward, uint8 level, uint8 sublevel, uint8 autoBuy, uint256 currentRate);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
    event onWithdraw(address  _user, uint256 amount);

    constructor(address ownerAddress, address payable _devAddress, ERC20 earthToken_) public 
    {
        owner = ownerAddress;
        devAddress=_devAddress; 
        earthToken=earthToken_;

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

        for(uint8 i=1; i<13; i++) {
            currentGlobalCount[i]=1;
            globalCount[i]=1;
            globalIndex[i][1]=ownerAddress;
            communityGlobalCount[i]=1;
            communityGlobalIndex[i][1]=ownerAddress;
            users[ownerAddress].levelActive[i]=true;
            users[ownerAddress].boardMatrix[i].isBoardActive=true;
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
            uint256 reward=(msg.value.mul(REFERRAL_PERCENTS[i])).div(1000);
            address(uint160(upline)).transfer(reward);
            emit ReferralReward(upline, msg.sender, reward, 1, i+1, maticRate);
            upline=users[upline].referrer;
            leftPer=leftPer-REFERRAL_PERCENTS[i];
            if(upline==address(0))
            {
                devAddress.transfer((msg.value.mul(leftPer)).div(1000));
                break;
            }
        }

        uint256 leftCom=100;
        uint256 globalId=lastUserId-1;
        for(uint8 j=1; j<=10; j++)
        {
            uint256 reward=(msg.value.mul(communityPercent)).div(1000);
            address(uint160(idToAddress[globalId])).transfer(reward);
            emit CommunityReward(idToAddress[globalId], msg.sender, reward, 1, j, maticRate);        
            globalId--;
            leftCom=leftCom-communityPercent;
            if(globalId==0)
            {
                devAddress.transfer((msg.value.mul(leftCom)).div(1000));
                break;
            }           
        }
        lastUserId++;
        total_liquidity+=(msg.value.mul(liquidityFee)).div(100);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
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
                uint256 reward=(msg.value.mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, msg.sender, reward, level, i+1, maticRate);            
                leftPer=leftPer-REFERRAL_PERCENTS[i];
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                devAddress.transfer((msg.value.mul(leftPer)).div(1000));
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
                uint256 reward=(msg.value.mul(communityPercent)).div(1000);   
                address(uint160(communityGlobalIndex[level][globalId])).transfer(reward);            
                emit CommunityReward(communityGlobalIndex[level][globalId], msg.sender, reward, level, j, maticRate);
                leftCom=leftCom-communityPercent;
                j++;         
            }
            globalId--;
            if(globalId==0)
            {
                devAddress.transfer((msg.value.mul(leftCom)).div(1000));
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
        uint256 mintedToken=getMintedToken(user);
        users[user].genReward+=mintedToken;
        users[user].currentLevel=level;
        users[user].lastTokenWithdraw=block.timestamp;

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

        uint256 slotValue=(levelPrice[level].mul(1e18)).div(maticRate);        

        address upline=users[user].referrer;
        uint256 leftPer=150;
        for(uint8 i=0; i<2;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(slotValue.mul(REFERRAL_PERCENTS[i])).div(1000);
                address(uint160(upline)).transfer(reward);
                emit ReferralReward(upline, user, reward, level, i+1, maticRate);            
                leftPer=leftPer-REFERRAL_PERCENTS[i];
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                devAddress.transfer((slotValue.mul(leftPer)).div(1000));
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
                uint256 reward=(slotValue.mul(communityPercent)).div(1000);   
                address(uint160(communityGlobalIndex[level][globalId])).transfer(reward);            
                emit CommunityReward(communityGlobalIndex[level][globalId], user, reward, level, j, maticRate);
                leftCom=leftCom-communityPercent;
                j++;         
            }
            globalId--;
            if(globalId==0)
            {
                devAddress.transfer((slotValue.mul(leftCom)).div(1000));
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
            uint256 reward=(levelPrice[level].mul(1e18)).div(maticRate);
            address(uint160(user)).transfer(reward);
            emit BoardReward(user, reward, level, 1, 0, maticRate);
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
            users[newBoardUser2].boardMatrix[level].firstReferrals.push(allBoardUser[4]);
            users[allBoardUser[4]].boardMatrix[level].boardReferrer=newBoardUser2;
            users[newBoardUser2].boardMatrix[level].firstReferrals.push(allBoardUser[5]);
            users[allBoardUser[5]].boardMatrix[level].boardReferrer=newBoardUser2;
            
            //===== increasing reinvest
            users[user].boardMatrix[level].reinvestCount+=1;
            if(level==10 || users[user].levelActive[level+1])
            {
                uint256 reward=(levelPrice[level].mul(1e18)).div(maticRate);                
                address(uint160(user)).transfer(reward*2);
                emit BoardReward(user, reward*2, level, 2, 0, maticRate);
            }
            else
            {
                uint256 reward=(levelPrice[level].mul(1e18)).div(maticRate);
                autoUpgrade(user,(level+1));
                emit BoardReward(user, reward*2, level, 2, 1, maticRate);
            }
            
            currentGlobalCount[level]=currentGlobalCount[level]+1;
        }
    }

    function withdrawMintedToken() public {
        require(isUserExists(msg.sender),"User not exist!");
        uint256 mintedToken=getMintedToken(msg.sender);
        uint256 totalReward=users[msg.sender].genReward+mintedToken;
        require(totalReward>0,"Zero rewards!");
        users[msg.sender].genReward=0;
        users[msg.sender].lastTokenWithdraw=block.timestamp;
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
        uint256 level=users[user].currentLevel;
        uint256 perSecondToken=(level.mul(1e18)).div(INTEREST_CYCLE);
        uint256 reward= perSecondToken*(block.timestamp-users[user].lastTokenWithdraw);
        return(reward);
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