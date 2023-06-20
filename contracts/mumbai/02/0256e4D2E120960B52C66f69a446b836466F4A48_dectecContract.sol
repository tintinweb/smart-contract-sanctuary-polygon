// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dectecContract {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyowner() {
        require(owner == msg.sender, "You are not the contract's owner.");
        _;
    }
    struct ActivityData {
        address userAddress;
        string activityName;
        uint256 points;
        string cid;
        uint256 timestamp;
    }

    mapping(address => ActivityData[]) private earnRewardRecords;
    mapping(address => uint256) private userPoints;

    event earnRewardHistory(
        address indexed userAddress,
        string activityName,
        uint256 points,
        string cid,
        uint256 timestamp
    );

    function changeOwner(address _newOwnerAddress) private onlyowner {
        owner = _newOwnerAddress;
    }

    function earnReward(
        address _userAddress,
        string memory _activityName,
        uint256 _points,
        string memory _cid
    ) public onlyowner {
        require(bytes(_activityName).length > 0, "Activity ID is required");
        require(_points > 0, "Points must be greater than 0");
        require(bytes(_cid).length >= 0, "CID is required");
        require(
            bytes(_activityName).length ==
                bytes(string(abi.encodePacked(_activityName))).length,
            "Activity ID cannot have special characters"
        );

        earnRewardRecords[_userAddress].push(
            ActivityData(
                _userAddress,
                _activityName,
                _points,
                _cid,
                block.timestamp
            )
        );

        userPoints[_userAddress] += _points;
        emit earnRewardHistory(
            _userAddress,
            _activityName,
            _points,
            _cid,
            block.timestamp
        );
    }

    function getTransactionCounts() public view returns (uint256) {
        ActivityData[] storage data = earnRewardRecords[msg.sender];
        return data.length;
    }
}