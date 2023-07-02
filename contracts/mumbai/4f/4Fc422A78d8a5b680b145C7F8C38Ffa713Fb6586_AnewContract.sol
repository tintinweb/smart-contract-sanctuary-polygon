/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AnewContract{
    using SafeMath for uint256;
    BEP20 public depositToken;

    address payable owner;
    uint256 actvePkg = 75e18;
    uint256 basicPkg = 50e18;
    uint256 roiPer = 15000;
    uint256 baseDiv = 100000;
    uint256 public totalUsers;
    struct User {
        uint id;
        address referrer; 
        uint40 directs;        
        uint40 pkg_id;        
        uint40 teamNum;
        uint256 totalDeposit;
        uint256 maxDeposit;
        uint32 timestamp;       
        uint32 maxLevel;       
               
        uint32 basicCount;       
        
    }
    
    struct Basic {
        uint256 amount;        
        uint256 claimedTotal;
        uint256 claimP;
        uint256 afterP;
        uint32 lastClaim;       
        uint32 nextClaim;       
        uint32 timestamp;
        bool isClosed;
    }
    struct Order {
        uint256 amount;        
        uint256 claimedTotal;
        uint256 claimP;
        uint256 afterP;             
        uint32 timestamp;
        bool isClosed;
        uint256 cycle;
    }

    mapping(address => User) public users;
    mapping(address => mapping(uint256=> Basic)) public basicInvest;
    mapping(address => mapping(uint256 => Order)) public Investments;
    mapping(address => mapping(uint256 => uint256)) public LevelIncome;
    mapping(address => mapping(uint256 => uint256)) public MatrixLevelUsers;
    mapping(address => mapping(uint256 => bool)) public MatrixLevelStatus;

    mapping(address =>mapping(uint32=>uint256))public myTeam;
    modifier onlyContractOwner() { 
        require(msg.sender == owner); 
        _; 
    }

    constructor() public {       
        owner = msg.sender;
    }
    uint256[] public levelincome;
    uint256[] public levelincome2;
    
    function init(address tkn)public onlyContractOwner(){
        depositToken=BEP20(tkn);
        totalUsers++;
        users[msg.sender].id=totalUsers;
        users[msg.sender].referrer=address(this);
        users[msg.sender].timestamp=uint32(block.timestamp);
        users[msg.sender].totalDeposit=10000e18;
        levelincome = [25,25,25,25,25,50,50,50,50,50,75,75,75,75,75,100,100,100,100,100];
        levelincome2 = [3000,2000,1000,500,500,500,1000,2000,3000,3000,3000,3000,3000,3000,3000,3000,5000,5000,5000,5000];

    }

    uint256 public day1 = 1 days;
    uint256 public day30 = 30 days;
    
    function register(address sponsor,uint256 amount) public {
        require(users[sponsor].totalDeposit>0,"Sponsor not active.");
        require(users[msg.sender].id==0,"Account Already exists.");
        require(amount>=actvePkg,"Account Already exists.");
        
        depositToken.transferFrom(msg.sender,address(this),amount);
        totalUsers++;
        users[msg.sender].id=totalUsers;
        users[msg.sender].referrer=sponsor;
        users[msg.sender].timestamp=uint32(block.timestamp);
        users[msg.sender].directs++;
        users[msg.sender].maxLevel=1;
        MatrixLevelStatus[msg.sender][1] = true;
        
        _addBasic(msg.sender,basicPkg);
        updateTeam(msg.sender);
    }
    

    function _addBasic(address addr,uint256 amnt) internal {
        users[addr].basicCount++;
        uint256 cnt = users[addr].basicCount;
        basicInvest[addr][cnt].amount=amnt;
        basicInvest[addr][cnt].nextClaim=uint32(uint256(block.timestamp).add(day30));
        basicInvest[addr][cnt].timestamp=uint32(block.timestamp);        
    }

    function claimBasic(uint256 cnt)public{
        require(basicInvest[msg.sender][cnt].nextClaim<= uint32(block.timestamp),"You can claim after time period over.");
        uint256 incm = basicInvest[msg.sender][cnt].amount.mul(roiPer).div(baseDiv);
        orderIncome(msg.sender,0);
        if(basicInvest[msg.sender][cnt].claimP.add(incm)<=basicInvest[msg.sender][cnt].amount.mul(2)){
            basicInvest[msg.sender][cnt].claimP += incm;
            basicInvest[msg.sender][cnt].claimedTotal += incm;
        }else{
            if(basicInvest[msg.sender][cnt].claimP<basicInvest[msg.sender][cnt].amount.mul(2)){

                basicInvest[msg.sender][cnt].claimP = basicInvest[msg.sender][cnt].amount.mul(2);
                basicInvest[msg.sender][cnt].claimedTotal += incm;
                basicInvest[msg.sender][cnt].afterP = basicInvest[msg.sender][cnt].claimedTotal.sub(basicInvest[msg.sender][cnt].claimP);
            }else{
                basicInvest[msg.sender][cnt].afterP += incm;
                basicInvest[msg.sender][cnt].claimedTotal += incm;
            }
        }        

        if(basicInvest[msg.sender][cnt].claimedTotal.mul(3)>= basicInvest[msg.sender][cnt].amount){
              basicInvest[msg.sender][cnt].isClosed = true;  
              _addBasic(msg.sender,basicInvest[msg.sender][cnt].amount);
        } 

        basicInvest[msg.sender][cnt].nextClaim = uint32(uint256(block.timestamp).add(day30));
        basicInvest[msg.sender][cnt].lastClaim = uint32(block.timestamp);
    }

    function upgrade(uint40 pkgid)public{
        require(users[msg.sender].id>0,"User Not Registered.");
        require(users[msg.sender].pkg_id == (pkgid-1),"User Not Registered.");

        users[msg.sender].pkg_id = pkgid;
        _addOrder(msg.sender,(pkgid*basicPkg),pkgid);
    }

    function _addOrder(address addr,uint256 amnt,uint256 pkgid) internal {
        
        Investments[addr][pkgid].cycle++;
        Investments[addr][pkgid].amount +=amnt;
            
        Investments[addr][pkgid].timestamp=uint32(block.timestamp);

        orderIncome(addr,pkgid);
    }

    

    function claimLevel(address usr,uint256 cnt,uint256 incm)public{
       
       if(Investments[usr][cnt].claimedTotal<Investments[usr][cnt].amount.mul(2)){ 

           LevelIncome[usr][cnt] += incm;
       
            if(Investments[usr][cnt].claimP.add(incm)<=Investments[usr][cnt].amount){
                Investments[usr][cnt].claimP += incm;
                Investments[usr][cnt].claimedTotal += incm;
            }else{
                if(Investments[usr][cnt].claimP<Investments[usr][cnt].amount){

                    Investments[usr][cnt].claimP = Investments[usr][cnt].amount;
                    Investments[usr][cnt].claimedTotal += incm;
                    Investments[usr][cnt].afterP = Investments[usr][cnt].claimedTotal.sub(Investments[usr][cnt].claimP);
                }else{
                    Investments[usr][cnt].afterP += incm;
                    Investments[usr][cnt].claimedTotal += incm;
                }
            }        
        }  

         
    }

    function orderIncome(address usdrid,uint256 pkgid)internal {
        x = users[usdrid].referrer;        
        for(uint32 i = 0 ; i < 20 ; i++ ){
            if(x != address(0)){
                if(users[x].pkg_id>pkgid){
                    if(pkgid==0){

                         claimLevel(x,pkgid+1,levelincome[i]);                                
                    }else{
                        uint256 amnt = ((50e18*pkgid)*levelincome2[i])/baseDiv;
                         claimLevel(x,pkgid+1,amnt);                                
                    }
                }                   
                    x = users[x].referrer;
            }else{
                break;
            }            
        }
    }


    address private x;
    function updateTeam(address usdrid)internal {

        x = users[usdrid].referrer; 
        for(uint32 i = 0 ; i < 20 ; i++ ){
            if(x != address(0)){

                    users[x].teamNum ++; 
                    myTeam[x][i]++; 
                    if(i==0){
                        MatrixLevelUsers[x][1]++;
                    }
                    if(MatrixLevelUsers[x][1]==5 && MatrixLevelStatus[x][1+1]==false && i==0){
                        MatrixLevelStatus[x][1+1]=true;
                        users[x].maxLevel=2;
                        updatemartix(x,2);
                    }                                     
                    x = users[x].referrer;
            }else{
                break;
            }            
        }
    }

    function updatemartix(address usdrid,uint256 cnt)internal {
        address sp = users[usdrid].referrer;

        if(users[sp].maxLevel>=cnt){
            MatrixLevelUsers[sp][cnt]++;
            if(MatrixLevelUsers[sp][cnt]==5 && MatrixLevelStatus[sp][cnt+1]==false ){
                        MatrixLevelStatus[x][cnt+1]=true;
                        users[sp].maxLevel++;
                        updatemartix(sp,uint256(cnt+1));
                    }  

        }else{
            updatemartix(sp,cnt);
        }
    }

 }
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}