/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

// File: src/PCV_editable_strategy/libraries/Errors.sol


pragma solidity ^0.8.0;

// SG = strategy

library Errors{

string public constant SG_INVALID_PROTOCOL_METHOD_NUM = "1"; //The protocol number or action number does not exist
string public constant SG_TOKEN_NOT_SUPPROT = "2"; // There are unsupported tokens
string public constant SG_INVALID_METHOD_LENGTH = "3"; // The number of protocols and the number of actions are not equal
string public constant SG_OPERATIONS_OUT_OF_RANGE = "4"; // The number of operations is out of range
string public constant SG_PROTOCOL_NOT_SUPPORT = "5"; // Protocol actions are not supported
string public constant SG_PERCENTAGE_OUT_OF_LIMIT = "6"; // Protocol actions are not supported
string public constant IV_NO_STRATEGY = "7"; // has no strategy
string public constant SWAP_NOT_ENOUGH_LP = "8" ;// not enough LP TOKEN to remove

string public constant PARAM_OUT_OF_LIMIT = "9" ;// not enough LP TOKEN to remove

string public constant SG_ALREADY_EXIST = "10" ;// not enough LP TOKEN to remove

string public constant PCV_NOT_EXIST = "11";
string public constant PCV_IS_NOT_OWNER = "12"; // Is not owner of PCV 

string public constant NO_REWARD_TO_CLAIM = "13"; // There are no rewards to claim


}
// File: src/PCV_editable_strategy/PcvRewardPool.sol


pragma solidity ^0.8.0;


interface IPcvStorage{
    function pcvIsExsit(address pcv) external view returns(bool);
}

interface IPCV{
    function rewardsAccount() external view returns(address);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function incrReward() external view returns(uint256);
    function updateReward() external;

}

contract PcvRewardPool{

    IPcvStorage public pcvStorage ;

    struct Reward{
        uint rewardSnapshot;
        uint received;
    }

    mapping(address => Reward) public pcvReward;

     constructor(address _pcvStorage){
        pcvStorage = IPcvStorage(_pcvStorage); 
    }

    event claimedReward(address indexed pcvStorage,address pcv,uint receivedAmount);
    
    function claimReward(address PCV) external {
        require(_isPcvRewardAccount(PCV,msg.sender),Errors.PCV_IS_NOT_OWNER);
        IPCV(PCV).updateReward();
        Reward storage reward = pcvReward[PCV];
        require(reward.rewardSnapshot > reward.received,Errors.NO_REWARD_TO_CLAIM);
        uint receiveAmount = reward.rewardSnapshot - reward.received;
        reward.received += receiveAmount;
        IPCV(PCV).transfer(msg.sender,receiveAmount);
        emit claimedReward(address(pcvStorage),PCV,receiveAmount);
    }

    function updateReward(address PCV,uint amount) external isPcv{
            Reward storage reward = pcvReward[PCV];
            reward.rewardSnapshot += amount; 
    }

    modifier isPcv(){
        require(pcvStorage.pcvIsExsit(msg.sender),Errors.PCV_NOT_EXIST);
        _;
    }

    function _isPcvRewardAccount(address PCV,address account) internal view returns(bool){
        return account == IPCV(PCV).rewardsAccount();
    }

    function currentReward(address PCV) public view returns(uint totalReward,uint received,uint notYetReceived){
        uint incrReward = IPCV(PCV).incrReward();
        totalReward = pcvReward[PCV].rewardSnapshot + incrReward;
        received = pcvReward[PCV].received;
        notYetReceived = totalReward - received;
    }

}