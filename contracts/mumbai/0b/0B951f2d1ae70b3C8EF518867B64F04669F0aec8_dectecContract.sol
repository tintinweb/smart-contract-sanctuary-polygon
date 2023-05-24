// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract dectecContract{

    address public owner;    
    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner(){
        require(owner == msg.sender, "You are not the contract's owner.");
        _;
    }
    struct ActivityData {
        address userAddress;
        string activityId;
        uint256 points;
        string cid;
        uint256 timestamp;
    }
    mapping(address => ActivityData[]) private  earnRewardRecords;
    mapping (address => uint256) private  userPoints;

    event earnRewardHistory(address indexed userAddress, string  activityId, uint256 points, string   cid, uint256 timestamp);
    function changeOwner(address _newOwnerAddress) onlyowner private {
        owner = _newOwnerAddress;
    }

    function earnReward(address _userAddress ,string memory _activityId, uint256 _points, string memory _cid) public onlyowner{
        require(bytes(_activityId).length > 0, "Activity ID is required");
        require(_points > 0, "Points must be greater than 0");
        require( bytes(_cid).length >= 0, "CID is required");
        require(bytes(_activityId).length == bytes(string(abi.encodePacked(_activityId))).length, "Activity ID cannot have special characters");
        require(bytes(_cid).length == bytes(string(abi.encodePacked(_cid))).length, "CID ID cannot have special characters");
        require(bytes(_activityId).length == 24, "Activity ID exceeds the maximum length of 24 characters");
        require(bytes(_cid).length >= 46 && bytes(_cid).length <= 64 , "CID is not in range between 46 to 64 characters");
        earnRewardRecords[_userAddress].push(ActivityData(_userAddress,_activityId, _points, _cid, block.timestamp));
        userPoints[_userAddress] += _points;
        emit earnRewardHistory(_userAddress, _activityId, _points, _cid, block.timestamp);
    }

    function getUserPoints() public view returns (uint256) {
        uint256 points = userPoints[msg.sender];
        return points;
    }
    function getTransactionCounts() public view returns(uint256) {
        ActivityData[] storage data = earnRewardRecords[msg.sender];
        return data.length;
    }
}