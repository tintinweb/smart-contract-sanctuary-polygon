/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-27
*/

pragma solidity >=0.4.23 <0.6.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AimUnivers_Stacking {
    struct User {
        uint id;
        address referrer;
        uint256 entry_time;
        uint partnersCount;
        uint256 totaldeposit;  
        uint256 payouts;
        uint256 stakewithdraw;
        uint256 directincome;
        uint256 totalwithdraw;
        mapping(uint => bool) activeLevels;
    }    
    
    struct OrderInfo {
        uint256 amount; 
        uint256 deposit_time;
        uint256 payouts; 
        bool isactive;
        uint level;
        bool isactivesubscribe;
    }
    struct Package
    {
        uint id;
        string name;
        uint duraion;
        uint minstake;
        uint maxstake;
        uint stakeprice;
        uint referalincome;
    }
    mapping(address => User) public users;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(uint=>Package) public packages;
    IERC20 public tokenAPLX;
    
    mapping(uint => address) public idToAddress;
    uint public lastUserId = 2;
    address public id1=0x8F4078b2189E74AFeaf1f2048754724b95B8AeEc;
    uint256 private constant timeStepdaily = 5*60;
    
    address owner=0x20F1252de7De505F30bfb978C0F1bBfD1BD18e69;
    address deductionWallet=0xF55B69e885EB2806f3b44BD09f88305FEE86f5E2;
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Upgrade(address indexed user,uint256 value,uint level);
    event Transaction(address indexed user,address indexed from,uint256 value, uint8 level,uint8 ttype);
    event withdraw(address indexed user,uint256 value,uint wtype,uint level,uint256 amount,uint deduction);

    constructor(address _token) public {
        tokenAPLX = IERC20(_token);        
        User memory user = User({
            id: 1,
            referrer: address(0),
            entry_time:block.timestamp,
            partnersCount: uint(0),
            totaldeposit:0,
            payouts:0, 
            stakewithdraw:0,           
            directincome:0,
            totalwithdraw:0
        });
        users[id1] = user;
        idToAddress[1] = id1;

        packages[1] = Package({
            id:1,
            name:"FELEXIBLE",
            duraion:timeStepdaily,
            minstake:1e8,
            maxstake:1000e8,
            stakeprice:50,
            referalincome:0
        });
        packages[2] = Package({
            id:2,
            name:"30 DAYS",
            duraion:30*timeStepdaily,
            minstake:1e8,
            maxstake:10000e8,
            stakeprice:56,
            referalincome:20
        });
        packages[3] = Package({
            id:3,
            name:"90 DAYS",
            duraion:90*timeStepdaily,
            minstake:1e8,
            maxstake:10000e8,
            stakeprice:65,
            referalincome:25
        });
        packages[4] = Package({
            id:4,
            name:"180 DAYS",
            duraion:180*timeStepdaily,
            minstake:1000e8,
            maxstake:10000e8,
            stakeprice:70,
            referalincome:25
        });
        packages[5] = Package({
            id:5,
            name:"12 MONTHS",
            duraion:365*timeStepdaily,
            minstake:1000e8,
            maxstake:0,
            stakeprice:78,
            referalincome:35
        });
        packages[6] = Package({
            id:6,
            name:"18 MONTHS",
            duraion:545*timeStepdaily,
            minstake:5000e8,
            maxstake:0,
            stakeprice:78,
            referalincome:40
        });
        packages[7] = Package({
            id:7,
            name:"24 MONTHS",
            duraion:730*timeStepdaily,
            minstake:5000e8,
            maxstake:0,
            stakeprice:78,
            referalincome:90
        });
        packages[8] = Package({
            id:8,
            name:"36 MONTHS",
            duraion:1095*timeStepdaily,
            minstake:5000e8,
            maxstake:0,
            stakeprice:78,
            referalincome:100
        });
        packages[9] = Package({
            id:9,
            name:"60 MONTHS",
            duraion:1825*timeStepdaily,
            minstake:5000e8,
            maxstake:0,
            stakeprice:78,
            referalincome:120
        });
    }
    function registrationExt(address referrerAddress) external {
             
        registration(msg.sender, referrerAddress);
    }
    
    function stake(uint level,uint256 _amount) external {
        tokenAPLX.transferFrom(msg.sender, address(this),_amount);
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(_amount>=packages[level].minstake && (_amount<=packages[level].maxstake || level>4), "amount should not match with package.");
        address userAddress=msg.sender;
        if(level>1)
        {
            uint256 directPercents=packages[level].referalincome;
            if((users[userAddress].activeLevels[level] && level>2) || !users[userAddress].activeLevels[level])
            {                
                users[users[userAddress].referrer].directincome += _amount*directPercents/1000;  
                emit Transaction(users[userAddress].referrer,userAddress,_amount*directPercents/1000,1,1);
            }
        }  
        if(!users[userAddress].activeLevels[level])      
        users[userAddress].activeLevels[level]=true; 
        users[userAddress].totaldeposit+=_amount;
        orderInfos[userAddress].push(OrderInfo(
            _amount, 
            block.timestamp, 
            0,
            true,
            level,
            false
        ));
        emit Upgrade(msg.sender,_amount,level);
    }
    function registration(address userAddress, address referrerAddress) private {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            entry_time:block.timestamp,
            partnersCount: 0,
            totaldeposit:0,
            payouts:0,
            stakewithdraw:0,
            directincome:0,
            totalwithdraw:0

        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    function usersActiveLevels(address userAddress, uint level) public view returns(bool) {
        return users[userAddress].activeLevels[level];
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }
    function dailyPayoutOf(address _user,uint level,uint256 _amount) public returns(uint){
        uint256 dayRewardPercents=0;
        uint isDeduction=0;
        for(uint8 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(order.isactive){
                if(order.level==level) { 
                    if(_amount<=order.amount){
                        if(order.deposit_time+packages[level].duraion<block.timestamp)
                        {
                            dayRewardPercents=packages[level].stakeprice;
                            isDeduction=0;
                        }
                        else if(order.deposit_time+packages[level].duraion>=block.timestamp && order.deposit_time+timeStepdaily<block.timestamp)
                        {
                            dayRewardPercents=packages[1].stakeprice;
                            isDeduction=2;
                        }
                        else 
                        {
                            dayRewardPercents=0;
                            isDeduction=1;
                        }
                        uint256 dailypayout = _amount*dayRewardPercents*((block.timestamp - order.deposit_time)/ timeStepdaily) / 30000;                    
                        users[_user].payouts += dailypayout+_amount;
                        order.payouts+=dailypayout;
                        order.amount-=_amount;
                        if(order.amount<=0)
                        order.isactive=false;
                        emit Transaction(_user,_user,(dailypayout+_amount),1,2);
                    }
                    break;
                }
            }           
        }
        return isDeduction;
    }
    function stakeWithdraw(uint level,uint256 _amount) public
    {
        uint isDeduction=dailyPayoutOf(msg.sender,level,_amount);
        uint balanceReward = users[msg.sender].payouts - users[msg.sender].stakewithdraw;
        require(balanceReward>0, "Insufficient reward income to withdraw!");
        users[msg.sender].stakewithdraw+=balanceReward;
        if(isDeduction>0 && level>1){
            tokenAPLX.transfer(msg.sender,balanceReward*75/100); 
            tokenAPLX.transfer(deductionWallet,balanceReward*25/100); 
        }
        else 
        {
            tokenAPLX.transfer(msg.sender,balanceReward); 
        }
        emit withdraw(msg.sender,balanceReward,2,level,_amount,isDeduction);
    }
    function referalWithdraw() public
    {
        uint balanceReward = users[msg.sender].directincome - users[msg.sender].totalwithdraw;
        require(balanceReward>0, "Insufficient referal income to withdraw!");
        users[msg.sender].totalwithdraw+=balanceReward;
        tokenAPLX.transfer(msg.sender,balanceReward); 
        emit withdraw(msg.sender,balanceReward,1,0,0,0);
    }
    function updateGWEI(uint256 _amount) public
    {
        require(msg.sender==owner,"Only contract owner"); 
        require(_amount>0, "Insufficient amount to withdraw!");
        tokenAPLX.transfer(msg.sender,_amount);  
    }
}