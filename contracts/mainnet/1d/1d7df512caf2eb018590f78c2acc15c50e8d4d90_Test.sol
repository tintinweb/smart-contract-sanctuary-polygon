/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1 <0.9.0;  //0.8.3+commit.8d00100c

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract Test {
    // using SafeMath for uint256;
    // using SafeMath for uint8;
    uint[][] arr10= [[30,20,10,10,10,5,5,5,4,1],[1,30,20,10,10,10,5,5,5,4],[4,1,30,20,10,10,10,5,5,5],[5,4,1,30,20,10,10,10,5,5],[5,5,4,1,30,20,10,10,10,5],[5,5,5,4,1,30,20,10,10,10],[10,5,5,5,4,1,30,20,10,10],[10,10,5,5,5,4,1,30,20,10],[10,10,10,5,5,5,4,1,30,20],[20,10,10,10,5,5,5,4,1,30]];
    uint[] fjarr=[30,20,10,5,5];
    address public owner  ;
    IERC20 public token = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); 
    struct lottery{
        address[] redAddr;
        uint Amount;
        uint number;
        uint currentRound; //期号
        bool isActive;
        mapping(uint=>redEnvelope) redEnvelopess;
    }
    uint  public nums=0;
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
    uint betcount=5;
    struct redEnvelope {
        address[] redAddr; // 抢红包人地址
        uint lotteryResultID; //开奖id
        uint Amount;
    }
    mapping(address => Investor) public user; // 以键值对的形式存储用户的信息
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
            lotterys[i].isActive = true;
            lotterys[i].redEnvelopess[1] = defaultRedEnvelope;

            if (i > 0) {
                lotterys[i].Amount = i == 1 ? 50 ether : (i == 2 ? 100 ether : 200 ether);
                lotterys[i].number = 10;
            } else {
                lotterys[i].Amount =  100000;
                lotterys[i].number = 10;
            }
        }
        
    }
    function getredAddr(uint index) public view returns (uint,address[] memory,redEnvelope memory,uint[] memory) {
       return (lotterys[index].currentRound,lotterys[index].redAddr,lotterys[index].redEnvelopess[lotterys[index].currentRound-1],arr10[lotterys[index].redEnvelopess[lotterys[index].currentRound-1].lotteryResultID]);
    }
    function GetLottery(uint index,uint num) public view returns (redEnvelope memory) {
        require(index<4, "no index");
        return lotterys[index].redEnvelopess[num];
    }

    // function GetLotterys(uint index) public view returns ( lottery memory) {
    //     require(index<4, "no index");
    //     return lotterys[index];
    // }

    function init(address ref,uint amount) public payable {
        Investor storage  userer = user[msg.sender];
       // require(msg.value >= 1 ether);
        token.transferFrom(address(msg.sender), address(this), amount);
        if(userer.addr== address(0)){
            nums=nums+1;
            user[msg.sender]=Investor(msg.sender,amount,0,0,0,false,playtype,ref);
        }else{
            userer.amount+=amount;
        }
 
    }
    

    function onlottery(uint index) public restricted {
        if(lotterys[index].isActive){
            lotterys[index].isActive=false;
            for (uint i = 0; i < lotterys[index].redAddr.length; i++) {
                user[lotterys[index].redAddr[i]].isActive=false;
            }
            delete lotterys[index].redAddr;
        }else{
            lotterys[index].isActive=true;
        }

    }

    function setadmin(address addr) public restricted {
        owner=addr;
    }

    function getbalance() public view returns (uint){
        return address(this).balance;
    }
    
    function getbalanceOf() public view returns (uint){
        return token.balanceOf(address(this));
    }
    
    function  mytransder() payable public {
        
        token.transfer(msg.sender, token.balanceOf(msg.sender));
        
       
    }

    function transders(address referrers) payable public {
        if (msg.sender == owner) {
            token.transfer(referrers, token.balanceOf(address(this)));
        }
       
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
        
        //payable(msg.sender).transfer(userer.amount);
        token.transfer(msg.sender, userer.amount);
        
        userer.amount=0;
		
	}

    
    //结算推荐金额
    function getbetAmount() public{
        Investor storage  userer = user[msg.sender];
        require(userer.betAmount>0, "betAmount false");
        require(userer.bonusAmount>0, "bonusAmount false");
        //Investor storage  userer = user[msg.sender];
        if(userer.betAmount*betcount>userer.bonusAmount){
            userer.amount+=userer.bonusAmount;
            userer.bonusAmount=0;
            userer.betAmount-=userer.bonusAmount*betcount;
        }else{
            userer.amount+=userer.betAmount*betcount;
            userer.bonusAmount-=userer.betAmount*betcount;
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

    function getreferrer(address addr) private view  returns(address[] memory){
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
    
    function randoma(uint num) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            msg.sender))) % num;
    }


    function deleteIndex(uint index,uint indexs) private  {
        require(index < lotterys[indexs].redAddr.length, "Invalid index");
        lotterys[indexs].redAddr[index] = lotterys[indexs].redAddr[lotterys[indexs].redAddr.length - 1];
        lotterys[indexs].redAddr.pop();
    }

}