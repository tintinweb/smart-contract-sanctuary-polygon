// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Interface/IUltiBetsToken.sol";

contract TreasuryFuzzed {
    address betsFuzzedUTBETS;
    address public immutable Admin;

    IUltiBetsToken public utbetsToken;

    struct Salary {
        uint256 utbetsAmount;
        uint256 nativeTokenAmount;
        uint256 lastClaimTime;
    }

    modifier onlyUltiBets() {
        require(
            msg.sender == betsFuzzedUTBETS,
            "You are not ultibets contract."
        );
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == Admin, "Only Admin can call this function");
        _;
    }

    uint256 public withdrawInterval; /// frequency of withdrwal (monthly)
    mapping(address => Salary) public salaryList;

    constructor() {
        Admin = msg.sender;
        withdrawInterval = 30 days;
    }

    function addTeamMember(
        address _member,
        uint256 _nativeTokenAmount,
        uint256 _utbetsAmount
    ) external onlyAdmin {
        salaryList[_member] = Salary(
            _utbetsAmount,
            _nativeTokenAmount,
            block.timestamp
        );
    }

    function updateSalary(
        address _member,
        uint256 _nativeTokenAmount,
        uint256 _utbetsAmount
    ) external onlyAdmin {
        require(
            salaryList[_member].lastClaimTime > 0,
            "This is not team mate address."
        );
        salaryList[_member].utbetsAmount = _utbetsAmount;
        salaryList[_member].nativeTokenAmount = _nativeTokenAmount;
    }

    function remoeveMember(address _member) external onlyAdmin {
        delete salaryList[_member];
    }

    function withdrawSalary() external {
        require(
            salaryList[msg.sender].lastClaimTime > 0,
            "You are not a team member."
        );
        require(
            block.timestamp >=
                salaryList[msg.sender].lastClaimTime + withdrawInterval,
            "Can't withdraw for now."
        );
        salaryList[msg.sender].lastClaimTime = block.timestamp;
        if (
            utbetsToken.balanceOf(address(this)) >=
            salaryList[msg.sender].utbetsAmount
        ) utbetsToken.transfer(msg.sender, salaryList[msg.sender].utbetsAmount);
        if (address(this).balance >= salaryList[msg.sender].nativeTokenAmount)
            payable(msg.sender).transfer(
                salaryList[msg.sender].nativeTokenAmount
            );
    }

    function setUTBETSContract(IUltiBetsToken _utbets) public onlyAdmin {
        utbetsToken = _utbets;
    }

    function setUltibetsContracts(address _betsFuzzedUTBETS) public onlyAdmin {
        betsFuzzedUTBETS = _betsFuzzedUTBETS;
    }

    function setRewardInterval(uint256 _interval) external onlyAdmin {
        withdrawInterval = _interval;
    }

    function sendReferReward(
        address _referrer,
        uint256 _amount
    ) external onlyUltiBets {
        utbetsToken.transfer(_referrer, _amount);
    }

    function sendRefBetRefund(
        address _referee,
        uint256 _amount
    ) external onlyUltiBets {
        utbetsToken.transfer(_referee, _amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUltiBetsToken {
    
    function allowance(address, address) external view returns(uint256);

    function approveOrg(address, uint256) external;
    
    function burn(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
}