/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IRewardPool {
    function rewardTo(address _account, uint256 _rewardAmount) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

contract UserHelper_V1_3 {
    using SafeMath for uint256;

    address public admin;
    mapping(address => bool) managers;
    mapping(address => bool) blacklist;

    IERC20 public token;
    IRewardPool public rewardPool;
    INodeInfoManagement_V1_3 private nodeManagement;
    IPentSpliter_V1_3 public distributor;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public cashoutFee = 10;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MANAGEMENT: NOT ADMIN");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender] == true, "MANAGEMENT: NOT MANAGER");
        _;
    }

    modifier isBlacklist() {
        require(blacklist[msg.sender] != true, "USER HELPER: SENDER BLACKLIST");
        _;
    }

    constructor (address _token, address _nodeManagement, address _rewardPool, address _distributor) {
        admin = msg.sender;
        managers[msg.sender] = true;

        require(_token != address(0) && _nodeManagement != address(0) && _rewardPool != address(0) && _distributor != address(0), "USER HELPER: CONST ADDRESS ERROR");
        token = IERC20(_token);
        nodeManagement = INodeInfoManagement_V1_3(_nodeManagement);
        rewardPool = IRewardPool(_rewardPool);
        distributor = IPentSpliter_V1_3(_distributor);
    }

    function addManager(address _newManager) external onlyAdmin {
        require(_newManager != address(0), "USER HELPER: ADD MANAGER ERROR");

        managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyAdmin {
        require(_manager != address(0), "USER HELPER: REMOVE MANAGER ERROR");

        managers[_manager] = false;
    }

    function addBlacklist(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "USER HELPER: ADD MANAGER ERROR");

        blacklist[_newAddress] = true;
    }

    function removeBlacklist(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "USER HELPER: REMOVE MANAGER ERROR");

        blacklist[_newAddress] = false;
    }


    // Admin Helper
    function updateManagement(address _newAddress) external onlyManager {
        require(_newAddress != address(0), "USER HELPER: UPDATE MANAGEMENT ERROR");
        nodeManagement = INodeInfoManagement_V1_3(_newAddress);
    }

    function updateDistributor(address _distributor) external onlyManager {
        distributor = IPentSpliter_V1_3(_distributor);
    }


    // User Interfaces
    function createNode(string memory _nodeName, uint256 _nodeType) public isBlacklist {
        require(bytes(_nodeName).length > 3 && bytes(_nodeName).length < 20, "USER HELPER: CREATE NAME SIZE INVALID");

        require(_nodeType >=0 && _nodeType <= 2, "USER HELPER: CREATE NODE TYPE ERROR");

        address sender = msg.sender;

        uint256 nodeCost = nodeManagement.getCostOfNode(_nodeType);

        uint256 compoundableAmount = 0;
        uint256 payAmountForUser = 0;
        if (nodeManagement.isNodeOwnder(sender)) {
            compoundableAmount = nodeManagement.compound(sender, nodeCost);
        }

        payAmountForUser = nodeCost.sub(compoundableAmount);

        if (compoundableAmount > 0) {
            rewardPool.rewardTo(address(distributor), compoundableAmount);
        }

        if (payAmountForUser > 0) {
            token.transferFrom(sender, address(distributor), payAmountForUser);
        }

        distributor.addBalance(IPentSpliter_V1_3.DISTRIBUTION_METHOD.CREATE, nodeCost);

        nodeManagement.createNode(sender, _nodeName, _nodeType);
    }

    function rentNode(string memory _nodeName, uint256 _nodeType, uint256 _rentDays) public isBlacklist {
        require(bytes(_nodeName).length > 3 && bytes(_nodeName).length < 20, "USER HELPER: RENT NAME SIZE INVALID");
        require(_rentDays > 0 && _rentDays < 31, "USER HELPER: RENT NAME SIZE INVALID");
        require(_nodeType >= 4 && _nodeType <= 6, "USER HELPER: RENT NODE TYPE ERROR");

        address sender = msg.sender;

        uint256 nodeCost = nodeManagement.getCostOfNode(_nodeType);

        uint256 compoundableAmount = 0;
        uint256 payAmountForUser = 0;

        if (nodeManagement.isNodeOwnder(sender)) {
            compoundableAmount = nodeManagement.compound(sender, nodeCost);
        }

        payAmountForUser = nodeCost.sub(compoundableAmount);

        if (compoundableAmount > 0) {
            rewardPool.rewardTo(address(distributor), compoundableAmount);
        }

        if (payAmountForUser > 0) {
            token.transferFrom(sender, address(distributor), payAmountForUser);
        }

        distributor.addBalance(IPentSpliter_V1_3.DISTRIBUTION_METHOD.RENT, nodeCost);

        nodeManagement.rentNode(sender, _nodeName, _nodeType, _rentDays);
    }

    function fusionNode(string memory _nodeName, uint256 _nodeType, uint256[] memory _removeIndexes) public isBlacklist {
        require(bytes(_nodeName).length > 3 && bytes(_nodeName).length < 20, "USER HELPER: RENT NAME SIZE INVALID");
        require(_removeIndexes.length == nodeManagement.getNodesForFusion(_nodeType), "USER HELPER: INVALIDE INDEXED");
        require(_nodeType >=0 && _nodeType <= 2, "USER HELPER: FUSION NODE TYPE ERROR");

        address sender = msg.sender;

        uint256 cost = nodeManagement.getTaxForFusion(_nodeType);

        uint256 compoundableAmount = 0;
        uint256 extraAmount = 0;
        if (nodeManagement.isNodeOwnder(sender)) {
            compoundableAmount = nodeManagement.compoundForFusion(sender, _nodeType, _removeIndexes, cost);
        }

        if (compoundableAmount > 0 && compoundableAmount < cost) {
            rewardPool.rewardTo(address(distributor), compoundableAmount);
            token.transferFrom(sender, address(distributor), cost.sub(compoundableAmount));
        } else if (compoundableAmount == cost) {
            rewardPool.rewardTo(address(distributor), compoundableAmount);
        } else if (compoundableAmount > cost) {
            rewardPool.rewardTo(address(distributor), cost);

            extraAmount = compoundableAmount - cost;

            rewardPool.rewardTo(address(distributor), extraAmount * cashoutFee / 100);
            rewardPool.rewardTo(sender, extraAmount * (100 - cashoutFee) / 100);
        }

        distributor.addBalance(IPentSpliter_V1_3.DISTRIBUTION_METHOD.FUSION, cost + extraAmount * cashoutFee / 100);

        nodeManagement.fusionNode(sender, _nodeName, _nodeType, _removeIndexes);
    }

    function cashoutReward(uint256 _nodeType, uint256 _nodeIndex) public isBlacklist {
        address sender = msg.sender;

        uint256 rewardAmount = nodeManagement.cashout(sender, _nodeType, _nodeIndex);

        rewardPool.rewardTo(sender, rewardAmount);
    }

    function cashoutAllReward() public isBlacklist {
        address sender = msg.sender;

        uint256 rewardAmount = nodeManagement.cashoutAll(sender);

        rewardPool.rewardTo(sender, rewardAmount);
    }

    function withdraw(uint256 _nodeType, uint256 _nodeIndex) public isBlacklist {
        address sender = msg.sender;

        uint256 refundAmount = nodeManagement.withdraw(sender, _nodeType, _nodeIndex);

        rewardPool.rewardTo(sender, refundAmount);
    }

    function getTotalCounts() public view returns (uint256) {
        return nodeManagement.getTotalCounts();
    }

    function getCostsOfNode() public view returns (uint256[] memory) {
        uint256[] memory returnValue;

        returnValue[0] = nodeManagement.getCostOfNode(0);
        returnValue[1] = nodeManagement.getCostOfNode(1);
        returnValue[2] = nodeManagement.getCostOfNode(2);
        returnValue[3] = nodeManagement.getCostOfNode(4);
        returnValue[4] = nodeManagement.getCostOfNode(5);
        returnValue[5] = nodeManagement.getCostOfNode(6);

        return returnValue;
    }

    function getRewardsPerMinute() public view returns (uint256[] memory) {
        uint256[] memory returnValue;

        returnValue[0] = nodeManagement.getRewardPerMinute(0);
        returnValue[1] = nodeManagement.getRewardPerMinute(1);
        returnValue[2] = nodeManagement.getRewardPerMinute(2);
        returnValue[3] = nodeManagement.getRewardPerMinute(3);
        returnValue[4] = nodeManagement.getRewardPerMinute(4);
        returnValue[5] = nodeManagement.getRewardPerMinute(5);
        returnValue[6] = nodeManagement.getRewardPerMinute(6);

        return returnValue;
    }

    function getTotalRewardableAmount() public view returns (uint256) {
        address sender = msg.sender;
        if (nodeManagement.isNodeOwnder(sender) == true) {
            return nodeManagement.getTotalRewardableAmount(sender);
        } else {
            return 0;
        }
    }

    function getNodeCountsForFusion() public view returns (uint256[] memory) {
        uint256[] memory returnValue;

        returnValue[0] = nodeManagement.getNodeCountsForFusion(0);
        returnValue[1] = nodeManagement.getNodeCountsForFusion(1);
        returnValue[2] = nodeManagement.getNodeCountsForFusion(2);

        return returnValue;
    }

    function getTaxesForFusion() public view returns (uint256[] memory) {
        uint256[] memory returnValue;

        returnValue[0] = nodeManagement.getTaxForFusion(0);
        returnValue[1] = nodeManagement.getTaxForFusion(1);
        returnValue[2] = nodeManagement.getTaxForFusion(2);

        return returnValue;
    }

    function getNodeBalanceOfUser() public view returns (uint256[] memory) {
        address sender = msg.sender;

        uint256[] memory returnValues;

        uint256 totalCount = nodeManagement.getTotalCountOfUser(sender);

        uint256 tiers = nodeManagement.getTiersCount();

        returnValues[0] = totalCount;

        for (uint256 i = 0; i < tiers; i ++) {
            returnValues[i + 1] = nodeManagement.getCountOfUser(sender, i);
        }

        return returnValues;
    }

    function getTypesOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.TYPE);
    }

    function getNamesOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.NAME);
    }

    function getCreateTimesOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.CREATE_TIME);
    }

    function getLastClaimTimesOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.LAST_CLAIM_TIME);
    }

    function getExpireTimesOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.EXPIRE_TIME);
    }

    function getRewardAmountsOfNodes() public view returns (string memory) {
        address sender = msg.sender;

        return nodeManagement.getNodesInfo(sender, INodeInfoManagement_V1_3.NODE_INDEX.REWARDED_AMOUNT);
    }
}