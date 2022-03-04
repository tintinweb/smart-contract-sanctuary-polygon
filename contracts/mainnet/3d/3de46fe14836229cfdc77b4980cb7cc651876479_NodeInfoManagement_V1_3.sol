/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INodeInfoStorage_V1_3 {

    enum NODE_INDEX {
        TYPE,
        NAME,
        CREATE_TIME,
        LAST_CLAIM_TIME,
        EXPIRE_TIME,
        REWARDED_AMOUNT
    }


    // Common Function
    function addNode(address _address, uint256 _nodeType, string memory _nodeName, uint256 _createTime, uint256 _lastClaimTime, uint256 _expireTime, uint256 _rewardedAmount) external;

    function updateNode(address _address, uint256 _nodeType, uint256 _nodeIndex, NODE_INDEX _index, uint256 _updateValue) external;


    // Admin Helper
    function updateTiers(uint256 _newValue) external;

    function removeUser(address _address) external;

    function removeNode(address _address, uint256 _nodeType, uint256 _nodeIndex) external;


    // User Helper
    function getTotalCounts() external view returns (uint256);

    function getTiersCount() external view returns (uint256);

    function isNodeOwnder(address _address) external view returns (bool);

    function isOmegaNodeOwner(address _address) external view returns (bool);

    function getTotalCountOfUser(address _address) external view returns (uint256);

    function getCountsOfUser(address _address) external view returns (uint256[] memory);
    
    function getCountOfUser(address _address, uint256 _nodeType) external view returns (uint256);

    function getNodeInfoByIndex(address _address, uint256 _nodeType, uint256 _nodeIndex) external view returns (string memory, uint256, uint256, uint256, uint256);

}

interface INodeInfoManagement_V1_3 {

    enum MODE {
        FUSION_MODE
    }

    enum UPDATE_MODE {
        REWARD_PERIOD,
        LIMIT_FOR_USER,
        FUSION_TIER
    }

    enum UPDATE_PARAMETER {
        COST_OF_NODE,
        REWARD_PER_MINUTE,
        NODE_COUNT_FOR_FUSION,
        TAX_FOR_FUSION
    }

    enum NODE_INDEX {
        TYPE,
        NAME,
        CREATE_TIME,
        LAST_CLAIM_TIME,
        EXPIRE_TIME,
        REWARDED_AMOUNT
    }



    // Admin Helper
    function updateNodeStorage(address _nodeStorage) external;

    function toggleMode(MODE _mode) external;

    function updateValue(UPDATE_MODE _mode, uint256 _newValue) external;

    function updateParameter(UPDATE_PARAMETER _updateMode, uint256[] memory newArray) external;



    // for user
    function createNode(address _address, string memory _nodeName, uint256 _nodeType) external;

    function rentNode(address _address, string memory _nodeName, uint256 _nodeType, uint256 _rentDays) external;

    function fusionNode(address _address, string memory _nodeName, uint256 _nodeType, uint256[] memory _removeIndexes) external;

    function withdraw(address _address, uint256 _nodeType, uint256 _nodeIndex) external returns (uint256);

    function cashout(address _address, uint256 _nodeType, uint256 _nodeIndex) external returns (uint256);

    function cashoutAll(address _address) external returns (uint256);

    function compound(address _address, uint256 _amount) external returns(uint256);

    function compoundForFusion(address _address, uint256 _nodeType, uint256[] memory _indexForFusion, uint256 _amount) external returns(uint256);

    function getTiersCount() external view returns (uint256);

    function getNodesInfo(address _address, NODE_INDEX _index) external view returns (string memory);

    function getCostOfNode(uint256 _nodeType) external view returns (uint256);

    function getTotalCountOfUser(address _address) external view returns (uint256);

    function getNodesForFusion(uint256 _nodeType) external view returns (uint256);

    function getTaxForFusion(uint256 _nodeType) external view returns (uint256);

    function getNodeCountsForFusion(uint256 _nodeType) external view returns (uint256);

    function getCountOfUser(address _address, uint256 _nodeType) external view returns (uint256);

    function isNodeOwnder(address _address) external view returns (bool);

    function getRewardPerMinute(uint256 _nodeType) external view returns (uint256);

    function getTotalRewardableAmount(address _address) external view returns (uint256);

    function getTotalCounts() external view returns (uint256);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract NodeInfoManagement_V1_3 is INodeInfoManagement_V1_3 {
    using SafeMath for uint256;

    address public admin;
    mapping(address => bool) managers;

    INodeInfoStorage_V1_3 private nodeStorage;

    uint256 public rewardPeriod = 60;
    uint256 public limitForUser = 100;

    mapping(uint256 => uint256) costOfNode;
    mapping(uint256 => uint256) rewardPerMinute;

    bool public enableFusionMode = true;
    mapping(uint256 => uint256) nodesForFusion;
    mapping(uint256 => uint256) taxForFusion;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MANAGEMENT: NOT ADMIN");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender] == true, "MANAGEMENT: NOT MANAGER");
        _;
    }

    constructor (address _nodeStorage) {
        admin = msg.sender;
        managers[msg.sender] = true;

        require(_nodeStorage != address(0), "MANAGEMENT: CONST ERROR");
        nodeStorage = INodeInfoStorage_V1_3(_nodeStorage);
    }

    function addManager(address _newManager) external onlyAdmin {
        require(_newManager != address(0), "MANAGEMENT: ADD MANAGER ERROR");

        managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyAdmin {
        require(_manager != address(0), "MANAGEMENT: REMOVE MANAGER ERROR");

        managers[_manager] = false;
    }



    // Admin Helper
    function updateNodeStorage(address _nodeStorage) external override onlyManager {
        require(_nodeStorage != address(0), "MANAGEMENT: CONST ERROR");
        nodeStorage = INodeInfoStorage_V1_3(_nodeStorage);
    }

    function toggleMode(MODE _mode) external override onlyManager {
        if (_mode == MODE.FUSION_MODE) {
            enableFusionMode = !enableFusionMode;
        }
    }

    function updateValue(UPDATE_MODE _mode, uint256 _newValue) external override onlyManager {
        if (_mode == UPDATE_MODE.REWARD_PERIOD) {
            rewardPeriod = _newValue;
        } else if (_mode == UPDATE_MODE.LIMIT_FOR_USER) {
            limitForUser = _newValue;
        }
    }

    function updateParameter(UPDATE_PARAMETER _updateMode, uint256[] memory newArray) external override onlyManager {
        if (_updateMode == UPDATE_PARAMETER.COST_OF_NODE || _updateMode == UPDATE_PARAMETER.REWARD_PER_MINUTE) {
            require(nodeStorage.getTiersCount() + 1 == newArray.length, "MANAGEMENT: UPDATE PARAMETER LENGTH ERROR");
        } else if (_updateMode == UPDATE_PARAMETER.NODE_COUNT_FOR_FUSION || _updateMode == UPDATE_PARAMETER.TAX_FOR_FUSION) {
            require(3 == newArray.length, "MANAGEMENT: UPDATE PARAMETER LENGTH ERROR");
        }

        if (_updateMode == UPDATE_PARAMETER.COST_OF_NODE) {
            for (uint256 i = 0; i < newArray.length; i ++) {
                costOfNode[i] = newArray[i];
            }
        } else if (_updateMode == UPDATE_PARAMETER.REWARD_PER_MINUTE) {
            for (uint256 i = 0; i < newArray.length; i ++) {
                rewardPerMinute[i] = newArray[i];
            }
        } else if (_updateMode == UPDATE_PARAMETER.NODE_COUNT_FOR_FUSION) {
            for (uint256 i = 0; i < newArray.length; i ++) {
                nodesForFusion[i] = newArray[i];
            }
        } else if (_updateMode == UPDATE_PARAMETER.TAX_FOR_FUSION) {
            for (uint256 i = 0; i < newArray.length; i ++) {
                taxForFusion[i] = newArray[i];
            }
        }
    }



    // User Helper
    function isNodeOwnder(address _address) external override view onlyManager returns (bool) {
        return nodeStorage.isNodeOwnder(_address);
    }

    function createNode(address _address, string memory _nodeName, uint256 _nodeType) external override onlyManager {
        address sender = _address;

        require(nodeStorage.getTotalCountOfUser(sender) < limitForUser, "MANAGEMENT: CREATE LIMIT ERROR");

        nodeStorage.addNode(sender, _nodeType, _nodeName, block.timestamp, block.timestamp, 0, 0);
    }

    function rentNode(address _address, string memory _nodeName, uint256 _nodeType, uint256 _rentDays) external override onlyManager {
        address sender = _address;

        require(nodeStorage.getTotalCountOfUser(sender) < limitForUser, "MANAGEMENT: RENT LIMIT ERROR");

        require(_rentDays >= 1 && _rentDays <= 30, "MANAGEMENT: RENT TIME ERROR");

        uint256 expireTime = block.timestamp + _rentDays * 1 days;

        nodeStorage.addNode(sender, _nodeType, _nodeName, block.timestamp, block.timestamp, expireTime, 0);
    }

    function fusionNode(address _address, string memory _nodeName, uint256 _nodeType, uint256[] memory _removeIndexes) external override onlyManager {
        address sender = _address;

        require(nodeStorage.getTotalCountOfUser(sender) < limitForUser, "MANAGEMENT: FUSION LIMIT ERROR");

        require(enableFusionMode == true, "MANAGEMENT: FUSION MODE DISABLED");

        if (nodeStorage.isOmegaNodeOwner(sender) == true) {
            require(_nodeType + 1 != 3, "MANAGEMENT: FUSION OMEGA ERROR");
        }

        nodeStorage.addNode(sender, _nodeType + 1, _nodeName, block.timestamp, block.timestamp, 0, 0);

        require(nodeStorage.getCountOfUser(sender, _nodeType) >= _removeIndexes.length, "MANAGEMENT: FUSION BALANCE INSUFFICIENT");

        for (uint256 i = 0; i < _removeIndexes.length; i ++) {
            nodeStorage.removeNode(sender, _nodeType, _removeIndexes[i]);
        }
    }

    function withdraw(address _address, uint256 _nodeType, uint256 _nodeIndex) external override onlyManager returns (uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256 expireTime;

        (, , , expireTime, ) = nodeStorage.getNodeInfoByIndex(sender, _nodeType, _nodeIndex);

        require(expireTime >= block.timestamp, "MANAGEMENT: WITHDRAW NOT EXPIRED");

        nodeStorage.removeNode(sender, _nodeType, _nodeIndex);

        return costOfNode[_nodeIndex];
    }

    function cashout(address _address, uint256 _nodeType, uint256 _nodeIndex) external override onlyManager returns (uint256) {
        require(nodeStorage.isNodeOwnder(_address), "MANAGEMENT: NOT NODE OWNER");

        return _cashout(_address, _nodeType, _nodeIndex);
    }

    function cashoutAll(address _address) external override onlyManager returns (uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256[] memory counts = nodeStorage.getCountsOfUser(sender);

        uint256 rewardableAmount = 0;
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < counts.length; i ++) {
            for (uint256 j = 0; j < counts[i]; j ++) {
                rewardableAmount = _cashout(_address, i, j);

                totalRewardAmount += rewardableAmount;
            }
        }

        return totalRewardAmount;
    }

    function compound(address _address, uint256 _amount) external override onlyManager returns(uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256[] memory counts = nodeStorage.getCountsOfUser(sender);

        uint256 createTime;
        uint256 expireTime;
        uint256 rewardedAmount;

        uint256 currentTime;
        uint256 rewardableAmount = 0;
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < counts.length; i ++) {
            for (uint256 j = 0; j < counts[i]; j ++) {
                (, createTime, , expireTime, rewardedAmount) = nodeStorage.getNodeInfoByIndex(sender, i, j);

                currentTime = block.timestamp;

                if (expireTime > 0 && currentTime > expireTime) {
                    currentTime = expireTime;
                }
                rewardableAmount = (currentTime - createTime).div(rewardPeriod).mul(rewardPerMinute[i]).sub(rewardedAmount);

                if (totalRewardAmount + rewardableAmount <= _amount) {
                    nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.REWARDED_AMOUNT, rewardableAmount + rewardedAmount);
                    nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.LAST_CLAIM_TIME, currentTime);
                    
                    totalRewardAmount += rewardableAmount;
                } else {
                    uint256 requireAmount = _amount - totalRewardAmount;
                    nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.REWARDED_AMOUNT, rewardedAmount + requireAmount);
                    nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.LAST_CLAIM_TIME, currentTime);

                    totalRewardAmount = _amount;
                }
            }
        }

        return totalRewardAmount;
    }

    function compoundForFusion(address _address, uint256 _nodeType, uint256[] memory _indexForFusion, uint256 _amount) external override onlyManager returns(uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256[] memory counts = nodeStorage.getCountsOfUser(sender);

        uint256 createTime;
        uint256 lastClaimTime;
        uint256 expireTime;
        uint256 rewardedAmount;

        uint256 currentTime;
        uint256 rewardableAmount = 0;
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < _indexForFusion.length; i ++ ) {
            totalRewardAmount += _cashout(sender, _nodeType, _indexForFusion[i]);
        }

        if (totalRewardAmount < _amount) {
            for (uint256 i = 0; i < counts.length; i ++) {
                for (uint256 j = 0; j < counts[i]; j ++) {
                    (, createTime, lastClaimTime, expireTime, rewardedAmount) = nodeStorage.getNodeInfoByIndex(sender, i, j);

                    currentTime = block.timestamp;

                    if (expireTime > 0 && currentTime > expireTime) {
                        currentTime = expireTime;
                    }
                    rewardableAmount = (currentTime - createTime).div(rewardPeriod).mul(rewardPerMinute[i]).sub(rewardedAmount);

                    if (totalRewardAmount + rewardableAmount <= _amount) {
                        nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.REWARDED_AMOUNT, rewardableAmount + rewardedAmount);
                        nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.LAST_CLAIM_TIME, currentTime);
                        
                        totalRewardAmount += rewardableAmount;
                    } else {
                        uint256 requireAmount = _amount - totalRewardAmount;
                        nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.REWARDED_AMOUNT, rewardedAmount + requireAmount);
                        nodeStorage.updateNode(sender, i, j, INodeInfoStorage_V1_3.NODE_INDEX.LAST_CLAIM_TIME, currentTime);

                        totalRewardAmount = _amount;
                    }
                }
            }
        }

        return totalRewardAmount;
    }

    function getTiersCount() external override view returns (uint256) {
        return nodeStorage.getTiersCount();
    }

    function getNodesInfo(address _address, NODE_INDEX _index) external override view returns (string memory) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256[] memory counts = nodeStorage.getCountsOfUser(sender);

        string memory name;
        uint256 createTime;
        uint256 lastClaimTime;
        uint256 expireTime;
        uint256 rewardedAmount;
        
        string memory returnValue = "";
        string memory separator = "#";

        for (uint256 i = 0; i < counts.length; i ++) {
            for (uint256 j = 0; j < counts[i]; j ++) {
                (name, createTime, lastClaimTime, expireTime, rewardedAmount) = nodeStorage.getNodeInfoByIndex(sender, i, j);

                if (_index == NODE_INDEX.TYPE) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            uint2str(i)
                        )
                    );
                } else if (_index == NODE_INDEX.NAME) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            name
                        )
                    );
                } else if (_index == NODE_INDEX.CREATE_TIME) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            uint2str(createTime)
                        )
                    );
                } else if (_index == NODE_INDEX.LAST_CLAIM_TIME) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            uint2str(lastClaimTime)
                        )
                    );
                } else if (_index == NODE_INDEX.EXPIRE_TIME) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            uint2str(expireTime)
                        )
                    );
                } else if (_index == NODE_INDEX.REWARDED_AMOUNT) {
                    returnValue = string(
                        abi.encodePacked(
                            returnValue,
                            separator,
                            uint2str(rewardedAmount)
                        )
                    );
                }
            }
        }

        return returnValue;
    }

    function getTotalCountOfUser(address _address) external override view returns (uint256) {
        return nodeStorage.getTotalCountOfUser(_address);
    }

    function getCostOfNode(uint256 _nodeType) external override view returns (uint256) {
        return costOfNode[_nodeType];
    }

    function getNodesForFusion(uint256 _nodeType) external override view returns (uint256) {
        return nodesForFusion[_nodeType];
    }

    function getTaxForFusion(uint256 _nodeType) external override view returns (uint256) {
        return taxForFusion[_nodeType];
    }

    function getNodeCountsForFusion(uint256 _nodeType) external override view returns (uint256) {
        return taxForFusion[_nodeType];
    }

    function getCountOfUser(address _address, uint256 _nodeType) external override view returns (uint256) {
        return nodeStorage.getCountOfUser(_address, _nodeType);
    }

    function getTotalRewardableAmount(address _address) external override view onlyManager returns (uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256[] memory counts = nodeStorage.getCountsOfUser(sender);

        uint256 createTime;
        uint256 expireTime;
        uint256 rewardedAmount;

        uint256 rewardableAmount = 0;
        uint256 totalRewardAmount = 0;

        for (uint256 i = 0; i < counts.length; i ++) {
            for (uint256 j = 0; j < counts[i]; j ++) {

                (, createTime, , expireTime, rewardedAmount) = nodeStorage.getNodeInfoByIndex(sender, i, j);

                rewardableAmount = calcRewardAmount(i, createTime, expireTime, rewardedAmount); 

                totalRewardAmount += rewardableAmount;
            }
        }

        return totalRewardAmount;
    }

    function getRewardPerMinute(uint256 _nodeType) external override view onlyManager returns (uint256) {
        return rewardPerMinute[_nodeType];
    }

    function getTotalCounts() external override view onlyManager returns (uint256) {
        return nodeStorage.getTotalCounts();
    }



    // Interval Function
    function _cashout(address _address, uint256 _nodeType, uint256 _nodeIndex) internal returns (uint256) {
        address sender = _address;

        require(nodeStorage.isNodeOwnder(sender), "MANAGEMENT: NOT NODE OWNER");

        uint256 createTime;
        uint256 expireTime;
        uint256 rewardedAmount;

        (, createTime, , expireTime, rewardedAmount) = nodeStorage.getNodeInfoByIndex(sender, _nodeType, _nodeIndex);

        uint256 rewardableAmount = calcRewardAmount(_nodeType, createTime, expireTime, rewardedAmount); 

        nodeStorage.updateNode(sender, _nodeType, _nodeIndex, INodeInfoStorage_V1_3.NODE_INDEX.REWARDED_AMOUNT, rewardableAmount + rewardedAmount);
        nodeStorage.updateNode(sender, _nodeType, _nodeIndex, INodeInfoStorage_V1_3.NODE_INDEX.LAST_CLAIM_TIME, block.timestamp);

        return rewardableAmount;
    }

    function calcRewardAmount(uint256 _nodeType, uint256 _createTime, uint256 _expireTime, uint256 _rewardedAmount) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;

        if (_expireTime > 0 && currentTime > _expireTime) {
            currentTime = _expireTime;
        }

        uint256 rewardableAmount = (currentTime - _createTime).div(rewardPeriod).mul(rewardPerMinute[_nodeType]).sub(_rewardedAmount);

        return rewardableAmount;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}