// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Epos {
    event Distribution(
        address receiver,
        address refferedBy,
        uint256 levelIncome,
        uint256 incomeReceived
    );
    event Registeration(
        address userAddress,
        address referredBy,
        uint256 amountPaid,
        uint256 joingDate
    );
    struct userData {
        uint256 id;
        address userAddress;
        address referredBy;
        uint256 amountPaid;
        uint256 joingDate;
        bool activeAllLevel;
        bool isExist;
    }
    uint256 public _currentId = 1;
    mapping(address => userData) public users;
    address firstId;
    uint256 _minInvestment = 10;
    uint256 _amountForAccessAllLevel = 100;
    uint256[] levelDistribution = [3, 2, 1, 1];

    constructor(address userAddress) {
        users[userAddress] = userData(
            _currentId,
            userAddress,
            address(0),
            100,
            block.timestamp,
            true,
            true
        );
        firstId = userAddress;
        _currentId++;
    }

    function register(address referredBy) external payable {
        require(checkUserExists(referredBy) == true, "Invalid refer address");
        require(msg.sender != address(0));
        require(msg.value >= _minInvestment, "Can't be less than Min Amount");
        bool _activeAllLevel = false;
        if (msg.value >= _amountForAccessAllLevel) {
            _activeAllLevel = true;
        }

        //Now we will distribute income

        payable(referredBy).transfer((msg.value * 5) / 100);
        address uplineUserAddress = getUplineAddress(referredBy);
        uint256 currentLevelDistribute = 0;
        for (uint256 i = 1; i <= _currentId; i++) {
            if (uplineUserAddress == firstId) {
                break;
            } else {
                if (currentLevelDistribute < 4) {
                    if (users[uplineUserAddress].activeAllLevel == true) {
                        payable(uplineUserAddress).transfer(
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );
                        emit Distribution(
                            uplineUserAddress,
                            referredBy,
                            currentLevelDistribute,
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );

                        currentLevelDistribute++;
                    } else {
                        uplineUserAddress = getUplineAddress(uplineUserAddress);
                    }
                } else {
                    break;
                }
            }
        }
        users[msg.sender] = userData(
            _currentId,
            msg.sender,
            referredBy,
            msg.value,
            block.timestamp,
            _activeAllLevel,
            true
        );
        _currentId++;
        emit Registeration(msg.sender, referredBy, msg.value, block.timestamp);
    }

    function getUplineAddress(address _userAddress)
        internal
        view
        returns (address)
    {
        return users[_userAddress].referredBy;
    }

    function checkUserExists(address _userAddress) internal returns (bool) {
        return users[_userAddress].isExist;
    }
}