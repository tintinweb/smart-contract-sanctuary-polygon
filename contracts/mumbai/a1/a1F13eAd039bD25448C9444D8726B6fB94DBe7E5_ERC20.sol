// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);
}

contract ERC20 {
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event ReturnInvestment(uint id, address indexed caller, uint amount);


    struct Campaign {        
        address creator;    
        uint goal;        
        uint pledged;       
        uint32 startAt; 
        uint32 endAt;
        bool claimed;
    }

    IERC20 public immutable token;

    uint public counter;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(
        uint32 _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "Campaign hasnt start yet");
        require(_endAt >= _startAt, "Campaign must start before it ends");
        require(_endAt <= block.timestamp + 45 days, "Campaign ends 45 days from now");

       counter = 1;
       campaigns[counter] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(counter, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Only creator can cancel campaign");
        delete campaigns[_id];
        emit Cancel(_id);        
    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require (block.timestamp >= campaign.startAt, "Campaign hasnt started yet");
        require (block.timestamp <= campaign.endAt, "Campaign has already ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Only creator can claim tokens");
        require (block.timestamp > campaign.endAt, "Campaign hasnt ended yet");
        require(campaign.pledged >= campaign.goal, "The amount pledged is lower than the total goal");
        require(!campaign.claimed, "Have been claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function returnInvestment(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Only creator can claim tokens");
        require (block.timestamp > campaign.endAt, "Campaign hasnt ended yet");
        require(campaign.pledged >= campaign.goal, "The amount pledged is higher than the total goal");

        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;        
        token.transfer(msg.sender, balance);

        emit ReturnInvestment(_id, msg.sender, balance);
    }
}