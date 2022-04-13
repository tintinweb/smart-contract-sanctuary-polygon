// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IVerificationTokenOracle.sol";

contract VerificationTokenOracle is IVerificationTokenOracle {
    event ChangeTokenStatus(address token, uint8 newStatus);
    event ChangeTokenReward(address token, uint256 newReward);
    address owner = msg.sender;

    uint8 constant public STATUS_NONE = 0;
    uint8 constant public STATUS_VERIFIED = 1;
    uint8 constant public STATUS_SCAM = 2;

    mapping(address => uint8) public status;
    mapping(address => uint256) public reward;
    
    modifier onlyOwner {
        require(msg.sender == owner, "only-owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setStatus(address token, uint8 newStatus) external onlyOwner {
        _setStatus(token, newStatus);
    }

    function setReward(address token, uint256 newReward) external onlyOwner {
        _setReward(token, newReward);
    }

    function setRewardWithAutoupdateStatus(address token, uint256 newReward) external onlyOwner {
        _setReward(token, newReward);
        if(newReward > 0 && status[token] == STATUS_NONE) {
            _setStatus(token, STATUS_VERIFIED);
        }
    }

    function _setStatus(address token, uint8 newStatus) internal {
        require(
            newStatus == STATUS_NONE || 
            newStatus == STATUS_VERIFIED || 
            newStatus == STATUS_SCAM,
            "invalid-status-value"
        );

        status[token] = newStatus;
        emit ChangeTokenStatus(token, newStatus);
    }

    
    function _setReward(address token, uint256 newReward) internal {
        reward[token] = newReward;
        emit ChangeTokenReward(token, newReward);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVerificationTokenOracle {
    function STATUS_NONE() external pure returns (uint8);
    function STATUS_VERIFIED() external pure returns (uint8);
    function STATUS_SCAM() external pure returns (uint8);
    function reward(address) external view returns (uint256);
    function status(address) external view returns (uint8);
}