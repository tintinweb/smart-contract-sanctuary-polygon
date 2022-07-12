/**
 *Submitted for verification at polygonscan.com on 2022-07-11
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

    uint256[] public REFERRAL_PERCENTS = [400, 50, 50, 50, 50];
    uint256 public communityPercent=50;
    uint256 public lastUserId = 2; 
    uint256 public lastBoardId = 1; 
    
    uint256 public  total_withdraw;

    IBEP20 BUSD;

    address public owner; 
    address public devAddress; 
    
    event Registration(address indexed investor, address indexed referrer, uint256 indexed investorId, uint256 referrerId);
    event Withdraw(address user, uint256 amount,uint8 level);
    event ReferralReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event CommunityReward(address  _user, address _from, uint256 reward, uint8 level, uint8 sublevel);
    event BuyNewLevel(address  _user, uint256 userId, uint8 _level, address referrer, uint256 referrerId);
        

    constructor(address ownerAddress, address _devAddress) public 
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
        }

        levelPrice[1]=10e18;
        levelPrice[2]=20e18;
        levelPrice[3]=40e18;
        levelPrice[4]=80e18;
        levelPrice[5]=150e18;
        levelPrice[6]=300e18;
        levelPrice[7]=600e18;
        levelPrice[8]=1200e18;
        levelPrice[9]=2500e18;
        levelPrice[10]=5000e18;
        levelPrice[11]=10000e18;
        levelPrice[12]=20000e18;
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
        
        users[userAddress].referrer = referrerAddress;
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

        // address upline=referrerAddress;
        // uint256 leftPer=600;
        // for(uint8 i=0; i<5; i++)
        // {
        //     uint256 reward=(levelPrice[1].mul(REFERRAL_PERCENTS[i])).div(1000);
            
        //     emit ReferralReward(upline, msg.sender, reward, 1, i+1);
        //     upline=users[upline].referrer;
        //     leftPer=leftPer-REFERRAL_PERCENTS[i];
        //     if(upline==address(0))
        //     {
        //         BUSD.transfer(devAddress,(levelPrice[1].mul(leftPer)).div(1000));
        //         break;
        //     }
        // }

        // uint256 leftCom=400;
        // uint256 globalId=lastUserId-1;
        // for(uint8 j=1; j<=8; j++)
        // {
        //     uint256 reward=(levelPrice[1].mul(communityPercent)).div(1000);
            
        //     emit CommunityReward(idToAddress[globalId], msg.sender, reward, 1, j);        
        //     globalId--;
        //     leftCom=leftCom-communityPercent;
        //     if(globalId==0)
        //     {
        //         BUSD.transfer(devAddress,(levelPrice[1].mul(leftCom)).div(1000));
        //         break;
        //     }
           
        // }

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


    function updateBoard(address user, uint8 level) public view {
        address newBoardUser1;
        address newBoardUser2;

        if(users[user].boardMatrix[level].reinvestCount<1) {
            newBoardUser1=user;
            address[] memory allBoardUser=findNewBoardUser(user, level);
            newBoardUser2=allBoardUser[0]; 
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
                if(users[users[user].boardMatrix[level].firstReferrals[i]].partnersCount>=1){
                    allBoardUser[k]= users[user].boardMatrix[level].firstReferrals[i];     
                    k++;         
                }
            }
            else{
                    if(users[users[user].boardMatrix[level].secondReferrals[i-2]].partnersCount>=1){
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

    
    

    //  function autoWithdraw(address _user,uint8 level) private{
    //     uint256 payableAmount = users[_user].withdrawable[level]/2;
    //     BUSD.transfer(_user,payableAmount);
    //     if(_user!=owner)
    //     reInvest(_user, payableAmount, level);
    //     emit Withdraw(_user, users[_user].withdrawable[level], level);
    //     users[_user].withdrawable[level]=0;
    // }    

    

    // function getWithdrawAmt(address _user) public view returns(uint256[] memory){
    //     uint256[] memory amt = new  uint256[](12);
    //     uint8 i=0;
    //     while(i<12){
    //         amt[i]=users[_user].withdrawable[i+1];
    //         i++;
    //     }
    //     return amt;
    // }
   
   
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