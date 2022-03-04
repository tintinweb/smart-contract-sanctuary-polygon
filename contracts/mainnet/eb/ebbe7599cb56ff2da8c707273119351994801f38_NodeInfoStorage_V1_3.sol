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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NodeInfoStorage_V1_3 is Ownable, INodeInfoStorage_V1_3 {

    struct NodeEntity {
        string name;
        uint256 createTime;
        uint256 lastClaimTime;
		uint256 expireTime;
        uint256 rewardedAmount;
    }

    mapping(address => bool) managers;

    // NODE TYPES: 0: lesser, 1: common, 2: legendary, 3: omega, 4: rented lesser, 5: rented common, 6: rented legendary
    uint256 public tiers = 6;

    // Stats
    uint256 totalNodes;
    mapping(uint256 => uint256) countsOfTiers;

    // Users' Nodes
    mapping(address => uint256) public countsOfUser;
    mapping(address => mapping(uint256 => uint256)) public balanceOfNodes;
    mapping(address => mapping(uint256 => NodeEntity[])) public nodesOfUser;

    modifier onlyManager() {
        require(managers[msg.sender] == true, "STORAGE: NOT MANAGER");
        _;
    }

    constructor () {
        managers[msg.sender] = true;    
    }

    function addManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "STORAGE: ADD MANAGER ERROR");

        managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        require(_manager != address(0), "STORAGE: REMOVE MANAGER ERROR");

        managers[_manager] = false;
    }


    // Common Function
    function addNode(address _address, uint256 _nodeType, string memory _nodeName, uint256 _createTime, uint256 _lastClaimTime, uint256 _expireTime, uint256 _rewardedAmount) external override onlyManager {
        address sender = _address;

        totalNodes += 1;
        countsOfTiers[_nodeType] += 1;

        countsOfUser[sender] += 1;
        balanceOfNodes[sender][_nodeType] += 1;
        nodesOfUser[sender][_nodeType].push(
            NodeEntity({
                name: _nodeName,
                createTime: _createTime,
                lastClaimTime: _lastClaimTime,
				expireTime: _expireTime,
                rewardedAmount: _rewardedAmount
            })
        );

        if (balanceOfNodes[sender][_nodeType] < nodesOfUser[sender][_nodeType].length) {
            nodesOfUser[sender][_nodeType][balanceOfNodes[sender][_nodeType] - 1] = nodesOfUser[sender][_nodeType][nodesOfUser[sender][_nodeType].length - 1];
        }
        delete nodesOfUser[sender][_nodeType][nodesOfUser[sender][_nodeType].length - 1];
    }

    function updateNode(address _address, uint256 _nodeType, uint256 _nodeIndex, NODE_INDEX _index, uint256 _updateValue) external override onlyManager {
        address sender = _address;

        require(_nodeIndex >= 0 && _nodeIndex < balanceOfNodes[sender][_nodeType], "STORAGE: UPDATE INDEX ERROR");

        NodeEntity[] storage nodes = nodesOfUser[sender][_nodeType];
        NodeEntity storage node = nodes[_nodeIndex];

        if (_index == NODE_INDEX.CREATE_TIME) {
            node.createTime = _updateValue;
        } else if (_index == NODE_INDEX.LAST_CLAIM_TIME) {
            node.lastClaimTime = _updateValue;
        } else if (_index == NODE_INDEX.EXPIRE_TIME) {
            node.expireTime = _updateValue;
        } else if (_index == NODE_INDEX.REWARDED_AMOUNT) {
            node.rewardedAmount = _updateValue;
        }
    }


    // Admin Helper
    function updateTiers(uint256 _newValue) external override onlyManager {
        tiers = _newValue;
    }

    function removeUser(address _address) external override onlyManager {
        address sender = _address;

        totalNodes = totalNodes - countsOfUser[sender];

        countsOfUser[sender] = 0;

        for (uint256 i = 0; i < tiers; i ++) {
            countsOfTiers[i] = countsOfTiers[i] - balanceOfNodes[sender][i];

            balanceOfNodes[sender][i] = 0;
        }
    }

    function removeNode(address _address, uint256 _nodeType, uint256 _nodeIndex) external override onlyManager {
        address sender = _address;

        require(_nodeIndex <= balanceOfNodes[sender][_nodeType], "STORAGE: REMOVE INVALID INDEX ERROR");

        NodeEntity[] storage nodes = nodesOfUser[sender][_nodeType];
        NodeEntity storage node = nodes[_nodeIndex];

        if (_nodeIndex < balanceOfNodes[sender][_nodeType]) {
            node = nodes[balanceOfNodes[sender][_nodeType] - 1];
        }
        delete nodes[balanceOfNodes[sender][_nodeType] - 1];

        balanceOfNodes[sender][_nodeType] -= 1;

        countsOfUser[sender] -= 1;

        totalNodes -= 1;
        countsOfTiers[_nodeType] -= 1;
    }


    // User Helper
    function getTotalCounts() external override view onlyManager returns (uint256) {
        return totalNodes;
    }

    function getTiersCount() external override view onlyManager returns (uint256) {
        return tiers;
    }

    function isNodeOwnder(address _address) external override view onlyManager returns (bool) {
        address sender = _address;

        if (countsOfUser[sender] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function isOmegaNodeOwner(address _address) external override view onlyManager returns (bool) {
        if (balanceOfNodes[_address][4] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getTotalCountOfUser(address _address) external override view onlyManager returns (uint256) {
        address sender = _address;

        return countsOfUser[sender];
    }

    function getCountsOfUser(address _address) external override view onlyManager returns (uint256[] memory) {
        address sender = _address;
        uint256[] memory counts;
        for (uint256 i = 0; i < tiers; i ++) {
            counts[i] = balanceOfNodes[sender][i];
        }

        return counts;
    }

    function getCountOfUser(address _address, uint256 _nodeType) external override view onlyManager returns (uint256) {
        return balanceOfNodes[_address][_nodeType];
    }

    function getNodeInfoByIndex(address _address, uint256 _nodeType, uint256 _nodeIndex) external override view onlyManager returns (string memory, uint256, uint256, uint256, uint256) {
        address sender = _address;

        require(_nodeIndex >= 0 && _nodeIndex < balanceOfNodes[sender][_nodeType], "STORAGE: GET INFO INDEX ERROR");

        NodeEntity[] storage nodes = nodesOfUser[sender][_nodeType];
        NodeEntity storage node = nodes[_nodeIndex];

        return (node.name, node.createTime, node.lastClaimTime, node.expireTime, node.rewardedAmount);
    }
}