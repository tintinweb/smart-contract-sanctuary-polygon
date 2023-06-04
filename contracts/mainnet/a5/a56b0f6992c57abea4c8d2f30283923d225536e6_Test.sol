/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1 <0.9.0;  //0.8.3+commit.8d00100c

// interface IERC20 {
//     function totalSupply() external view returns (uint256);

//     function balanceOf(address account) external view returns (uint256);

//     function transfer(address recipient, uint256 amount)
//         external
//         returns (bool);

//     function allowance(address owner, address spender)
//         external
//         view
//         returns (uint256);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(
//         address sender,
//         address recipient,
//         uint256 amount
//     ) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(
//         address indexed owner,
//         address indexed spender,
//         uint256 value
//     );
// }


contract Test {
    // using SafeMath for uint256;
    // using SafeMath for uint8;
    uint[][] arr10= [[30,20,10,10,10,5,5,5,4,1],[1,30,20,10,10,10,5,5,5,4],[4,1,30,20,10,10,10,5,5,5],[5,4,1,30,20,10,10,10,5,5],[5,5,4,1,30,20,10,10,10,5],[5,5,5,4,1,30,20,10,10,10],[10,5,5,5,4,1,30,20,10,10],[10,10,5,5,5,4,1,30,20,10],[10,10,10,5,5,5,4,1,30,20],[20,10,10,10,5,5,5,4,1,30]];
    //uint[][] arr5= [[40,30,10,9,1],[1,40,30,10,9],[9,1,40,30,10],[10,9,1,40,30],[30,10,9,1,40]];

    uint[] fjarr=[30,20,10,5,5];
    address public owner  ;
    //IERC20 public token = IERC20(0x55d398326f99059fF775485246999027B3197955); 
    struct lottery{
        address[] redAddr;
        uint Amount;
        uint number;
        uint currentRound; //期号
        bool isActive;
        mapping(uint=>redEnvelope) redEnvelopess;
    }
    lottery [4] public lotterys;
    address [] lottery0;
    uint [] playtype;//红包玩法类型
    struct Investor {
        address addr; // 投资人地址
        uint amount; //投资总额
        uint redAmount; //红包总额
        uint bonusAmount; //推广奖金
        uint betAmount; 
        bool isActive;  //是否开启抢红包
        uint[] bet;
        address referrer;//推荐人
    }
    uint betcount=20;
    //Investor [] public Investors;
    // uint256 minAmount= 1 ether;
    // uint256 maxAmount= 2 ether;
    struct redEnvelope {
        address[] redAddr; // 抢红包人地址
        uint lotteryResultID; //开奖id
        uint Amount;
        // mapping (uint => Investor) funders; //按照索引存储出资人信息
    }
    //mapping(uint => redEnvelope) public redEnvelopes; // 以键值对的形式存储红包的信息
    mapping(address => Investor) public user; // 以键值对的形式存储用户的信息
    //mapping(uint256 => redEnvelope[]) public userGroup;
    //uint public numCampaigns; //统计运动员（被赞助人）数量
   // mapping (address=>uint) public admin;
    redEnvelope private defaultRedEnvelope = redEnvelope({
        redAddr: new address[](0),
        lotteryResultID: 0,
        Amount: 0
    });
    constructor() {
        owner = msg.sender;
        
        user[msg.sender]=Investor(msg.sender,0,0,0,0,false,playtype,msg.sender);
        for (uint i = 0; i < lotterys.length; i++) {
            lotterys[i].redAddr = lottery0;
            lotterys[i].currentRound = 1;
            lotterys[i].isActive = false;
            lotterys[i].redEnvelopess[1] = defaultRedEnvelope;

            if (i > 0) {
                lotterys[i].Amount = i == 1 ? 50 ether : (i == 2 ? 100 ether : 200 ether);
                lotterys[i].number = 10;
            } else {
                lotterys[i].Amount = 1 ether;
                lotterys[i].number = 10;
            }
        }
        // for (uint i = 0; i < lotterys.length; i++) {
        //     if(i>0){
        //         lotterys[i].redAddr=lottery0;
        //         if(i==1){
        //             lotterys[i].Amount=200;
        //         }
        //         if(i==2){
        //             lotterys[i].Amount=500;
        //         }
        //         if(i==3){
        //             lotterys[i].Amount=1000;
        //         }
        //         lotterys[i].number=10;
        //     }else{
        //         lotterys[i].redAddr=lottery0;
        //         lotterys[i].Amount=100;
        //         lotterys[i].number=5;
               
        //     }
        //     lotterys[i].currentRound=1;
        //     lotterys[i].isActive=true;
        //     lotterys[i].redEnvelopess[1] = redEnvelope({
        //         redAddr: new address[](0),
        //         lotteryResultID: 0,
        //         Amount: 0
        //     });
        
        // }
       
        // lotterys[0]=lottery({redAddr: lottery0, Amount: 100  wei,number: 5,currentRound: 1,isActive:true});
        // lotterys[1]=lottery({redAddr: lottery0, Amount: 200  wei,number:10,currentRound: 1,isActive:true});
        // lotterys[2]=lottery({redAddr: lottery0, Amount: 500  wei,number:10,currentRound: 1,isActive:true});
        // lotterys[3]=lottery({redAddr: lottery0, Amount: 1000 wei,number:10,currentRound: 1,isActive:true});
    }
    
    // function SetLottery(uint8 index,uint amount,uint8 number,bool isActive) public {
    //     //address[] memory lotteryarr = new address[](1);
    //     lotterys[index]=lottery({redAddr: lottery0, Amount: amount,number:number,isActive:isActive});
    //    // lotterys.push(lottery({redAddr: lottery0, Amount: 10}));
    // }

    function GetLottery(uint index,uint num) public view returns (redEnvelope memory) {
        require(index<4, "no index");
        return lotterys[index].redEnvelopess[num];
    }

    function  init (address addr) public payable {
        require(msg.value >= 1 ether);
        require(user[msg.sender].addr== address(0),"User registered");
        
        user[msg.sender]=Investor(msg.sender,msg.value,0,0,0,false,playtype,addr);
    }

    function onlottery(uint index) public restricted {
        lotterys[index].isActive=true;
        //players = new address[](0);
    }

    function setadmin(address addr) public restricted {
        owner=addr;
        //players = new address[](0);
    }

    function getbalance() public view returns (uint){
        return address(this).balance;
    }

    function pickWinner(address addr) public restricted {
        payable(addr).transfer(address(this).balance);
        //players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }


    function  bet (uint index) public payable{
        // 判断彩票是否激活
        
        require(lotterys[index].isActive, "index false");
        // 判断用户是否已经下注
        require(!user[msg.sender].isActive, "user false");
        require((user[msg.sender].amount+msg.value)>=lotterys[index].Amount, "no amount");
        // 如果地址为空，则默认为合约拥有者
        Investor storage  userer = user[msg.sender];
        // 创建投资者对象
        userer.isActive=true;
        userer.amount+=msg.value;
        //user[msg.sender] = Investor(msg.sender, lotterys[index].Amount, 0, 0,0, true, playtype, addr);
        // 添加用户到红球地址数组中
        lotterys[index].redAddr.push(msg.sender);
        // 判断红球地址数组是否已满
        if (lotterys[index].redAddr.length == lotterys[index].number) {
            // 结算彩票
            settlement(index);
        }
    }

    function withdraw() public {
		Investor storage  userer = user[msg.sender];
        require(userer.amount > 0, "User has no dividends");
        require(!userer.isActive , "isActive is true");		
        
        payable(msg.sender).transfer(userer.amount);
        userer.amount=0;
		
	}

    
    //结算推荐金额
    function getbetAmount() public{
        Investor storage  userer = user[msg.sender];
        require(userer.betAmount>0, "betAmount false");
        require(userer.bonusAmount>0, "bonusAmount false");
        //Investor storage  userer = user[msg.sender];
        if(userer.betAmount/betcount>userer.bonusAmount){
            userer.amount+=userer.bonusAmount;
            userer.bonusAmount=0;
            userer.betAmount-=userer.bonusAmount*betcount;
        }else{
            userer.amount+=userer.betAmount/betcount;
            userer.bonusAmount-=userer.betAmount/betcount;
            userer.betAmount=0;
        }
    }
    
    function js() public{
        Investor storage  userer = user[msg.sender];
        address[] memory arrref=getreferrer(msg.sender);
        for (uint i = 0; i < 5; i++) {
            user[arrref[i]].bonusAmount=userer.redAmount * fjarr[i]/1000;
        }
        user[msg.sender].betAmount+=user[msg.sender].redAmount;
        user[msg.sender].amount+=user[msg.sender].redAmount*90/100;
        user[owner].amount+=userer.redAmount * 3/100;
        user[msg.sender].redAmount =0;
    }

    function settlement(uint index) private  {
        uint resultID =uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            msg.sender))) % lotterys[index].number;
        lotterys[index].redEnvelopess[lotterys[index].currentRound]=redEnvelope(lotterys[index].redAddr,resultID,lotterys[index].Amount);
        uint amount = lotterys[index].Amount;
        uint currentRound = lotterys[index].currentRound;
        address[] memory redAddr = lotterys[index].redAddr;
        uint number = lotterys[index].number;
        for (uint i = 0; i < number; i++) {
            user[redAddr[i]].bet.push(currentRound);
            if (resultID == i) {
                user[redAddr[i]].isActive = false;
                user[redAddr[i]].amount -= amount;
            }
            if (index > 0) {
                user[redAddr[i]].redAmount += arr10[resultID][i] * amount / 100;
            } else {
                user[redAddr[i]].redAmount += arr10[resultID][i] * amount / 100;
            }
        }
        lotterys[index].currentRound++;
        deleteIndex(resultID, index);
    }

    // function getid() public pure  returns(bool){
        
    //     return !true;  //false
    // }

    function getreferrer(address addr) public view  returns(address[] memory){
        address[] memory arr= new address[](5);
        address  ref=addr;
        for (uint i = 0; i < 5; i++) {
            if (user[ref].referrer== address(0)) {
                arr[i]=owner;
                ref=owner;
            }else{
                arr[i]=user[ref].referrer;
                ref=user[ref].referrer;
            }
        }
        return arr;  
    }
    
    // function getredEnveloperedAddr(uint index) public view  returns(redEnvelope memory){
        
    //     return redEnvelopes[index];
    // }

    function randoma(uint num) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            msg.sender))) % num;
    }

    

    // function randomAmount() public view returns (uint256) {
    //     return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % (maxAmount - minAmount + 1) + minAmount;  //block.prevrandao,  
    // }

    // function deleteElement(address element) private  {
    //     for (uint i = 0; i < lottery0.length; i++) {
    //         if (lottery0[i] == element) {
    //             lottery0[i] = lottery0[lottery0.length - 1];
    //             lottery0.pop();
    //             break;
    //         }
    //     }
    // }

    function deleteIndex(uint index,uint indexs) private  {
        require(index < lotterys[indexs].redAddr.length, "Invalid index");
        lotterys[indexs].redAddr[index] = lotterys[indexs].redAddr[lotterys[indexs].redAddr.length - 1];
        lotterys[indexs].redAddr.pop();
    }

    // 新增一个Campaign对象，需要传入受益人的地址和需要筹资的总额
    
    // function newCampaign(address beneficiary, uint goal) public returns (uint campaignID) {
    //     campaignID = numCampaigns++; //计数+1
        
    //     // 创建一个Campaign对象，并存储到“campaigns”里面
        
    //     campaigns[campaignID] = Campaign(beneficiary, goal, 0, 0);
        
    // }
    
    // function assign() public {
    //     Students.push(stu1);
    //     Students.push(stu2);
    //     numCampaigns=100; 
    //     stu1.name = "Lily";  // 修改结构体对象的属性值
    // }

    // function test3() public pure returns(uint8  num1,uint8  num2,string memory teststring){
      
    //     return (10,20,'hello2');
    // }
    // function test3() public view  returns(uint[][] memory){

    //     return arr;
    // }

    
}


// library SafeMath {

//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }

//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b <= a, "SafeMath: subtraction overflow");
//         uint256 c = a - b;

//         return c;
//     }

//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }

//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: division by zero");
//         uint256 c = a / b;

//         return c;
//     }
    
//      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b != 0);
//         return a % b;
//     }
// }