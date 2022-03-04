/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPentSpliter_V1_3 {

    enum DISTRIBUTION_METHOD {
        CREATE,
        RENT,
        FUSION,
        CASHOUT
    }

    enum DISTRIBUTION {
        REWARD_POOL,
        TREASURY,
        VAULT,
        LIQUIDITY,
        BURN_ADDRESS
    }


    // for admin
    function updateProtocolAddresses(DISTRIBUTION _target, address _newAddress) external;

    function updateProtocolFees(DISTRIBUTION_METHOD _method, DISTRIBUTION _feeIndex, uint256 _newValue) external;

    function updateSwapAmount(uint256 _newValue) external;

    function updateTokenAddress(address _newToken) external;

    function updateUniswapV2Router(address newAddress) external;


    // for user
    function addBalance(DISTRIBUTION_METHOD _method, uint256 _value) external;
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

interface IUserHelper_V1_3 {

    // Admin Helper
    function updateManagement(address _newAddress) external;

    function updateDistributor(address _distributor) external;
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

contract AdminHelper_V1_3 {
    using SafeMath for uint256;

    address public admin;
    mapping(address => bool) managers;

    IPentSpliter_V1_3 public distributor;
    INodeInfoStorage_V1_3 public nodeStorage;
    INodeInfoManagement_V1_3 public management;
    IUserHelper_V1_3 public userHelper;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MANAGEMENT: NOT ADMIN");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender] == true, "MANAGEMENT: NOT MANAGER");
        _;
    }

    constructor (address _distributor, address _nodeStorage, address _management, address _userHelper) {
        admin = msg.sender;
        managers[msg.sender] = true;

        require(_distributor != address(0) && _management != address(0) && _nodeStorage != address(0) && _userHelper != address(0), "ADMIN HELPER: CONST ADDRESS ERROR");
        distributor = IPentSpliter_V1_3(_distributor);
        nodeStorage = INodeInfoStorage_V1_3(_nodeStorage);
        management = INodeInfoManagement_V1_3(_management);
        userHelper = IUserHelper_V1_3(_userHelper);
    }

    function addManager(address _newManager) public onlyAdmin {
        require(_newManager != address(0), "ADMIN HELPER: ADD MANAGER ERROR");

        managers[_newManager] = true;
    }

    function removeManager(address _manager) public onlyAdmin {
        require(_manager != address(0), "ADMIN HELPER: REMOVE MANAGER ERROR");

        managers[_manager] = false;
    }



    // Distribution
    function updateProtocolAddresses(IPentSpliter_V1_3.DISTRIBUTION _target, address _newAddress) public onlyManager {
        distributor.updateProtocolAddresses(_target, _newAddress);
    }

    function updateProtocolFees(IPentSpliter_V1_3.DISTRIBUTION_METHOD _method, IPentSpliter_V1_3.DISTRIBUTION _feeIndex, uint256 _newValue) public onlyManager {
        distributor.updateProtocolFees(_method, _feeIndex, _newValue);
    }

    function updateSwapAmount(uint256 _newValue) public onlyManager {
        distributor.updateSwapAmount(_newValue);
    }

    function updateTokenAddress(address _newToken) public onlyManager {
        distributor.updateTokenAddress(_newToken);
    }

    function updateUniswapV2Router(address newAddress) public onlyManager {
        distributor.updateUniswapV2Router(newAddress);
    }



    // Storage
    function addNode(address _address, uint256 _nodeType, string memory _nodeName, uint256 _createTime, uint256 _lastClaimTime, uint256 _expireTime, uint256 _rewardedAmount) public onlyManager {
        nodeStorage.addNode(_address, _nodeType, _nodeName, _createTime, _lastClaimTime, _expireTime, _rewardedAmount);
    }

    function updateNode(address _address, uint256 _nodeType, uint256 _nodeIndex, INodeInfoStorage_V1_3.NODE_INDEX _index, uint256 _updateValue) public onlyManager {
        nodeStorage.updateNode(_address, _nodeType, _nodeIndex, _index, _updateValue);
    }

    function updateTiers(uint256 _newValue) public onlyManager {
        nodeStorage.updateTiers(_newValue);
    }

    function removeUser(address _address) public onlyManager {
        nodeStorage.removeUser(_address);
    }

    function removeNode(address _address, uint256 _nodeType, uint256 _nodeIndex) public onlyManager {
        nodeStorage.removeNode(_address, _nodeType, _nodeIndex);
    }


    // Management
    function updateNodeStorage(address _nodeStorage) public onlyManager {
        management.updateNodeStorage(_nodeStorage);
    }

    function toggleMode(INodeInfoManagement_V1_3.MODE _mode) public onlyManager {
        management.toggleMode(_mode);
    }

    function updateValue(INodeInfoManagement_V1_3.UPDATE_MODE _mode, uint256 _newValue) public onlyManager {
        management.updateValue(_mode, _newValue);
    }

    function updateParameter(INodeInfoManagement_V1_3.UPDATE_PARAMETER _updateMode, uint256[] memory newArray) public onlyManager {
        management.updateParameter(_updateMode, newArray);
    }


    // User Helper
    function updateManagement(address _newAddress) public onlyManager {
        userHelper.updateManagement(_newAddress);
    }

    function updateDistributor(address _newAddress) external onlyManager {
        userHelper.updateDistributor(_newAddress);
    }


    // Gift Node
    function giftNode(address _address, uint256 _nodeType, string memory _nodeName) public onlyManager {
        nodeStorage.addNode(_address, _nodeType, _nodeName, block.timestamp, block.timestamp, 0, 0);
    }
}