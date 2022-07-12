/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

/*
0x038cA0F3be6B3C4150aB06E6Dc52C9A86c987A07 --2    1  ref by 1
0xa97407A70c1B22378D0F006aC28d54b5c3695620 --3    2  ref by 2
0x80F2962698435F57C5342c20f0842183BAf1D194 --4    0  ref by 3
0x5750DD0be0b5F1aE1F3A4B189B5415e37C4A1C2C --5    2  ref by 2
0x5750DD0be0b5F1aE1F3A4B189B5415e37C4A1C2C --6    0  ref by 5
0x5750DD0be0b5F1aE1F3A4B189B5415e37C4A1C2C --7    0  ref by 5
*/

// 0x6dA4867268c80BFcc1Fe4515A841eCa6299557Fb  // owner
// 0x90a80a33eB2B8770b4f9659F222b6B39A21D2ECa  // busd contract
// https://bscscan.com/address/0x1ce7d580209408ec4068c4ea1c0af78a1dd9b80c
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

contract EarthPlanet {
     using SafeMath for uint256;
  
     
    struct User {
        uint256 id;
        address referrer; 
        uint256 partnersCount;       
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

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    mapping(uint8 => uint256) public levelPrice;

    uint256[] public REFERRAL_PERCENTS = [100,50];
    uint256 public communityPercent=10;
    uint256 public lastUserId = 2; 
    uint256 public lastBoardId = 1; 
    
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
            partnersCount: 0        
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for(uint8 i=1; i<13; i++) {
            currentGlobalCount[i]=1;
            globalCount[i]=1;
            globalIndex[i][1]=ownerAddress;
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
            partnersCount: 0 
        });
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].levelActive[1]=true;
        users[referrerAddress].partnersCount+=1;
        
        globalCount[1]=globalCount[1]+1;
        globalIndex[1][globalCount[1]]=userAddress;

        address boardRef=globalIndex[1][currentGlobalCount[1]];

        if(users[boardRef].boardMatrix[1].firstReferrals.length<2)
           users[boardRef].boardMatrix[1].firstReferrals.push(userAddress); 
        else {
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
        for(uint8 j=1; j<=8; j++)
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

    function buyLevel(uint8 level) public 
    {
        require(isUserExists(msg.sender), "user exists!");
        require(level<13, "Max 12 Level!");  
        require(users[msg.sender].levelActive[level-1],"Buy Previous Level First!");
        require(!users[msg.sender].levelActive[level],"Level Already Activated!");
        BUSD.transferFrom(msg.sender,address(this),levelPrice[level]);
        users[msg.sender].levelActive[level]=true;
        globalCount[level]=globalCount[level]+1;
        //globalAddresstoId[level][msg.sender]=globalCount[level];
        globalIndex[level][globalCount[level]]=msg.sender;
        address upline=users[msg.sender].referrer;
        uint256 leftPer=600;
        for(uint8 i=0; i<5;)
        {
            if(users[upline].levelActive[level])
            {
                uint256 reward=(levelPrice[level].mul(REFERRAL_PERCENTS[i])).div(1000);
                
                emit ReferralReward(upline, msg.sender, reward, level, i+1);
                leftPer=leftPer-REFERRAL_PERCENTS[i];
                i++;
            }
            upline=users[upline].referrer;
            if(upline==address(0))
            {
                BUSD.transfer(devAddress,(levelPrice[level].mul(leftPer)).div(1000));
                break;
            }
        }

        uint256 globalId=globalCount[level]-1;
        uint8 j=1;
        uint256 leftCom=400;
        while(j<9)
        {
            if(users[globalIndex[level][globalId]].levelActive[level])
            {
                uint256 reward=(levelPrice[level].mul(communityPercent)).div(1000);
               
                emit CommunityReward(globalIndex[level][globalId], msg.sender, reward, level, j);
                leftCom=leftCom-communityPercent;
                j++;         
            }
            globalId--;
            if(globalId==0)
            {
                BUSD.transfer(devAddress,(levelPrice[level].mul(leftCom)).div(1000));
                break;
            }
        }
        address refer= globalIndex[level][globalCount[level]-1];
        emit BuyNewLevel(msg.sender, users[msg.sender].id, level, refer, users[refer].id);
    }  


    function updateBoard(address user, uint8 level) private {
       
        if(users[user].boardMatrix[level].reinvestCount<1) { // when user's board breaking first time
            address newBoardUser;
            address[] memory allBoardUser=findNewBoardUser(user, level);
            newBoardUser=allBoardUser[0]; 
            users[newBoardUser].boardMatrix[level].isBoardActive=true;
            users[user].boardMatrix[level].firstReferrals=new address[](0);
            users[user].boardMatrix[level].secondReferrals=new address[](0);

            // for first level of reinvested user
            users[user].boardMatrix[level].firstReferrals.push(allBoardUser[1]);
            users[allBoardUser[1]].boardMatrix[level].boardReferrer=user;
            users[user].boardMatrix[level].firstReferrals.push(allBoardUser[2]);
            users[allBoardUser[2]].boardMatrix[level].boardReferrer=user;

            // for first level of new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[3]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[4]);
            users[allBoardUser[4]].boardMatrix[level].boardReferrer=newBoardUser;

            // for second level of reinvested user
            users[user].boardMatrix[level].secondReferrals.push(allBoardUser[5]);
            users[allBoardUser[5]].boardMatrix[level].boardReferrer=user;

            // increasing reinvest
            users[user].boardMatrix[level].reinvestCount+=1;
        }
        else {  // when user's board breaking second time
            address newBoardUser;
            address newBoardUser2;
            address[] memory allBoardUser=findNewBoardUser(user, level);
            newBoardUser=allBoardUser[0]; 
            newBoardUser2=allBoardUser[1]; 
            users[newBoardUser].boardMatrix[level].isBoardActive=true;
            users[newBoardUser2].boardMatrix[level].isBoardActive=true;

            users[user].boardMatrix[level].firstReferrals=new address[](0);
            users[user].boardMatrix[level].secondReferrals=new address[](0);

            // for first level of first new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[2]);
            users[allBoardUser[2]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[3]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;

            // for first level of second new user
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[4]);
            users[allBoardUser[3]].boardMatrix[level].boardReferrer=newBoardUser;
            users[newBoardUser].boardMatrix[level].firstReferrals.push(allBoardUser[5]);
            users[allBoardUser[4]].boardMatrix[level].boardReferrer=newBoardUser;

            // for second level of reinvested user
            users[user].boardMatrix[level].secondReferrals.push(allBoardUser[5]);
            users[allBoardUser[5]].boardMatrix[level].boardReferrer=user;
            
            // increasing reinvest
            users[user].boardMatrix[level].reinvestCount+=1;
        }
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
    

    function getUserBoard(address user, uint8 level) public view returns(address[] memory, address[] memory) {
        if(users[user].levelActive[level])
        {
            while(true) {
                if(users[user].boardMatrix[level].isBoardActive)
                break;
                user=users[user].boardMatrix[level].boardReferrer;
            }
        }
       return(users[user].boardMatrix[level].firstReferrals, users[user].boardMatrix[level].secondReferrals);
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