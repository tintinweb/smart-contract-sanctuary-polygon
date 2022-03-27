/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract reward {
    struct User {
        uint cursor; 
        uint amountBefore;
        uint amount;
        uint[] indexIn;
        mapping(uint => uint) amountIn;
        uint reward;
    }

    uint public index;
    address public admin;

    mapping(address => User) public stackers;
    mapping(uint => uint) public stackedByIndex;
    mapping(uint => uint) public dividendByIndex;

    IERC20 public ObToken;

    event AddLiquidity(address indexed admin, uint tokens);
    event GetReward(address indexed stacker, uint tokens);
    event Stack(address indexed stacker, uint256 tokens);
    event Unstack(address indexed stacker, uint256 tokens);
    
    constructor() {
        admin = msg.sender;
        ObToken = IERC20(0x77127bEC1015d13B03CB6364E49c050C0FE1f22a);
    }

    function addLiquidity() external payable{
        uint amount = msg.value;
        require(amount > 0, 'usage : dividend > 0.');
        require(msg.sender == admin, 'Admin only.');
        
        dividendByIndex[index] += amount;
        uint tmp = stackedByIndex[index];
        index += 1;
        stackedByIndex[index] += tmp;

        emit AddLiquidity(msg.sender, amount);
    }

    function getReward() public {
        User storage user = stackers[msg.sender];
        require(user.amount > 0, 'You are not stacking');
        require(user.cursor < index, 'You have to wait the next round');

        uint tmpAmount = user.amountBefore;
        uint reward;

        for(uint i = user.cursor; i < index; i++){
            tmpAmount += user.amountIn[i];
            reward += (tmpAmount * dividendByIndex[i]) / stackedByIndex[i];
        }

        user.cursor = index;
        user.amountBefore = tmpAmount;
        user.reward += reward;

        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send.");

        emit GetReward(msg.sender, reward);
    }

    function stack() external {
        uint256 allowance = ObToken.allowance(msg.sender, address(this));
        require(allowance > 0, 'You have to allow an amount.');

        User storage user = stackers[msg.sender];
        if(user.amount == 0)    user.cursor = index;
        user.amount += allowance;
        user.indexIn.push(index);
        user.amountIn[index] += allowance;

        stackedByIndex[index] += allowance;

        require(ObToken.transferFrom(msg.sender, address(this), allowance), 'Failed to send.');

        emit Stack(msg.sender, allowance);
    }

    function unstack(uint amount) public {
        User storage user = stackers[msg.sender];

        require(amount > 0, 'Your stacking balance should be greater than 0.');
        require(user.amount > 0, 'You are not stacking');
        require(user.amount >= amount, 'amount > Your current balance.');

        if(user.cursor != index){
            getReward();
        }
        stackedByIndex[index] -= amount;
        user.amount -= amount;
        if(amount > user.amountBefore)  user.amountBefore = 0;
        else    user.amountBefore -= amount;

        ObToken.transfer(msg.sender, amount);

        emit Unstack(msg.sender, amount);
    }

    function unstackAll() external {
        unstack(stackers[msg.sender].amount);
    }
}