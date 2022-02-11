// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/SafeMath.sol";

import "./types/Ownable.sol";

contract NewNODERewardManagement is Ownable {
    using SafeMath for uint256;

    struct NodeEntity {
        uint256 creationTime;
        uint256 lastClaimTime;
		uint256 expireTime;
        uint256 rewardsPerMinute;
        string name;
        uint256 nodeType;
        uint256 created;
        uint256 isStake;
        uint256 rewardedAmount;
    }

    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => uint256) private _nodesCount;
	mapping(address => bool) public _managers;

    uint256 public nodePriceLesser = 1000000000000000000;
    uint256 public nodePriceCommon = 5000000000000000000;
    uint256 public nodePriceLegendary = 10000000000000000000;

	uint256 public rewardPerMinuteLesser = 8680550000000;
	uint256 public rewardPerMinuteCommon = 49861110000000;
	uint256 public rewardPerMinuteLegendary = 114652770000000;
    uint256 public rewardsPerMinuteOMEGA = 1318472220000000;

	uint256 public rewardPerMinuteLesserStake = 8680550000000;
	uint256 public rewardPerMinuteCommonStake = 49861110000000;
	uint256 public rewardPerMinuteLegendaryStake = 114652770000000;

    uint256 public totalNodesCreated = 0;

	uint256 public claimInterval = 60;

	event NodeCreated(address indexed from, string name, uint256 index, uint256 totalNodesCreated, uint256 _type);

    // Fusion
    mapping(address => uint256) public lesserNodes;
    mapping(address => uint256) public commonNodes;
    mapping(address => uint256) public legendaryNodes;
    mapping(address => bool) public omegaOwner;

    mapping(address => uint256) public lesserNodesStake;
    mapping(address => uint256) public commonNodesStake;
    mapping(address => uint256) public legendaryNodesStake;

    uint256 public nodeCountForLesser = 5;
    uint256 public nodeCountForCommon = 2;
    uint256 public nodeCountForLegendary = 10;

    uint256 public taxForLesser = 12500000000000000;
    uint256 public taxForCommon = 165100000000000000;
    uint256 public taxForLegendary = 1898000000000000000;

    bool public allowFusion = true;
    bool public allowMigrate = true;

    uint256 public nodeLimit = 100;

    constructor(
    ) {
		_managers[msg.sender] = true;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    // external

    function _getNodeNumberOf(address account) external view returns (uint256) {
        return _nodesCount[account];
    }

    function _getFusionCost() external view returns (uint256, uint256, uint256) {
        return (
            nodeCountForLesser,
            nodeCountForCommon,
            nodeCountForLegendary
        );
    }

    function _getNodePrices() external view returns (uint256, uint256, uint256) {
        return (
            nodePriceLesser,
            nodePriceCommon,
            nodePriceLegendary
        );
    }

    function getNodePrice(uint256 _type, bool isFusion) external view returns (uint256 returnValue) {
        if (isFusion) {
            if (_type == 2) {
                returnValue = taxForLesser;
            } else if (_type == 3) {
                returnValue = taxForCommon;
            } else if (_type == 4) {
                returnValue = taxForLegendary;
            }
        } else {
            if (_type == 1) {
                returnValue = nodePriceLesser;
            } else if (_type == 2) {
                returnValue = nodePriceCommon;
            } else if (_type == 3) {
                returnValue = nodePriceLegendary;
            }
        }
    }

    function _getTaxForFusion() external view returns (uint256, uint256, uint256) {
        return (
            taxForLesser,
            taxForCommon,
            taxForLegendary
        );
    }

    function _getNodeCounts(address account) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        return (
            lesserNodes[account],
            commonNodes[account],
            legendaryNodes[account],
            omegaOwner[account]? 1: 0,
            lesserNodesStake[account],
            commonNodesStake[account],
            legendaryNodesStake[account]
        );
    }

    function _getNodesInfo(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _info = uint2str(nodes[0].isStake);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _info = string(
                abi.encodePacked(
                    _info,
                    separator,
                    uint2str(_node.isStake)
                )
            );
        }
        return _info;
    }

    function _getNodesType(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _types = uint2str(nodes[0].nodeType);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _types = string(
                abi.encodePacked(
                    _types,
                    separator,
                    uint2str(_node.nodeType)
                )
            );
        }
        return _types;
    }

    function _getNodesName(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _names = nodes[0].name;
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _names = string(
                abi.encodePacked(
                    _names,
                    separator,
                    _node.name
                )
            );
        }
        return _names;
    }

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodesExpireTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _expireTimes = uint2str(nodes[0].expireTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            _expireTimes = string(
                abi.encodePacked(
                    _expireTimes,
                    separator,
                    uint2str(_node.expireTime)
                )
            );
        }
        return _expireTimes;
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(dividendsOwing(nodes[0]));
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(dividendsOwing(_node))
                )
            );
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function _getRewardAmountOf(address account, uint256 index)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "NO NODE OWNER");
        NodeEntity[] storage nodes = _nodesOfUser[account];

        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        return rewardNode;
    }

    // only manager

	function addManager(address manager) external onlyOwner {
		_managers[manager] = true;
	}

	function removeManager(address manager) external onlyOwner {
		_managers[manager] = false;
	}

    function _getRewardAmountOf(address account)
        external
        view
        onlyManager
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = _nodesCount[account];

		NodeEntity storage _node;
        for (uint256 i = 0; i < nodesCount; i++) {
			_node = nodes[i];
            rewardCount += dividendsOwing(_node);
        }

        return rewardCount;
    }

    function withdrawAmount(address account, uint256 index) external onlyManager returns(uint256) {
        require(isNodeOwner(account), "WITHDRAWO AMOUNT: NO NODE OWNER");

        NodeEntity[] memory nodes = _nodesOfUser[account];

        require(nodes[index].isStake == 1, "Invalid Node Index");
        require(nodes[index].expireTime <= block.timestamp, "Not Expired Yet");

        if (index != _nodesCount[account] - 1) {
            _nodesOfUser[account][index] = _nodesOfUser[account][_nodesCount[account] - 1];
        }
        delete _nodesOfUser[account][_nodesCount[account] - 1];
        _nodesCount[account]--;
        totalNodesCreated--;

        uint256 returnValue;

        if (nodes[index].nodeType == 1) {
            returnValue = nodePriceLesser;
        } else if (nodes[index].nodeType == 2) {
            returnValue = nodePriceCommon;
        } else if (nodes[index].nodeType == 3) {
            returnValue = nodePriceLegendary;
        }

        return returnValue;
    }

    function _cashoutNodeReward(address account, uint256 index)
        external
		onlyManager
        returns (uint256)
    {
        require(isNodeOwner(account), "CASHOURT NODE: NO NODE OWNER");
        NodeEntity[] storage nodes = _nodesOfUser[account];

        NodeEntity storage node = _getNodeByIndex(nodes, index);
        uint256 rewardNode = dividendsOwing(node);
        node.rewardedAmount = node.rewardedAmount + rewardNode;
        node.lastClaimTime = block.timestamp;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
        external
		onlyManager
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        require(nodesCount > 0, "NODE: NO NODE OWNER");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
			uint256 rewardNode = dividendsOwing(_node);
            _node.rewardedAmount = _node.rewardedAmount + rewardNode;
            rewardsTotal += rewardNode;
            _node.lastClaimTime = block.timestamp;
        }
        return rewardsTotal;
    }

    function fusionNode(uint256 _method, address account) external onlyManager {
        require(isNodeOwner(account), "Fusion: NO NODE OWNER");
        require(allowFusion, "Fusion: Not Allowed to Fuse");

        uint256 nodeCountForFusion;

        if (_method == 1) {
            require(lesserNodes[account] >= nodeCountForLesser, "Fusion: Not enough Lesser Nodes");
            nodeCountForFusion = nodeCountForLesser;
            lesserNodes[account] -= nodeCountForFusion;
        } else if (_method == 2) {
            require(commonNodes[account] >= nodeCountForCommon, "Fusion: Not enough Common Nodes");
            nodeCountForFusion = nodeCountForCommon;
            commonNodes[account] -= nodeCountForFusion;
        } else if (_method == 3) {
            require(legendaryNodes[account] >= nodeCountForLegendary, "Fusion: Not enough Legendary Nodes");
            require(!omegaOwner[account], "Fusion: Already has OMEGA Node");
            nodeCountForFusion = nodeCountForLegendary;
            legendaryNodes[account] -= nodeCountForFusion;
        }

        NodeEntity memory _node;

        uint256 count = 0;

        uint256 i = 0;

        while(i < _nodesCount[account]) {

            if (count == nodeCountForFusion) {
                break;
            }

            NodeEntity[] memory nodes = _nodesOfUser[account];

            _node = nodes[i];

            if (_node.nodeType == _method && _node.isStake == 0) {
                if (i != _nodesCount[account] - 1) {
                    _nodesOfUser[account][i] = _nodesOfUser[account][_nodesCount[account] - 1];
                }
                delete _nodesOfUser[account][_nodesCount[account] - 1];
                count++;
                _nodesCount[account]--;
                totalNodesCreated--;
            } else {
                i++;
                continue;
            }
        }
    }

    function _changeNodePrice(uint256 newnodePriceLesser, uint256 newnodePriceCommon, uint256 newnodePriceLegendary) external onlyManager {
        nodePriceLesser = newnodePriceLesser;
        nodePriceCommon = newnodePriceCommon;
        nodePriceLegendary = newnodePriceLegendary;
    }

	function _changeClaimInterval(uint256 newInterval) external onlyManager {
        claimInterval = newInterval;
    }

    function _changeRewardsPerMinute(uint256 newPriceLesser, uint256 newPriceCommon, uint256 newPriceLegendary, uint256 newPriceOMEGA, uint256 newPriceLesserStake, uint256 newPriceCommonStake, uint256 newPriceLegendaryStake) external onlyManager {
        rewardPerMinuteLesser = newPriceLesser;
        rewardPerMinuteCommon = newPriceCommon;
        rewardPerMinuteLegendary = newPriceLegendary;
        rewardsPerMinuteOMEGA = newPriceOMEGA;

        rewardPerMinuteLesserStake = newPriceLesserStake;
        rewardPerMinuteCommonStake = newPriceCommonStake;
        rewardPerMinuteLegendaryStake = newPriceLegendaryStake;
    }

    function toggleFusionMode() external onlyManager {
        allowFusion = !allowFusion;
    }

    function setNodeCountForFusion(uint256 _nodeCountForLesser, uint256 _nodeCountForCommon, uint256 _nodeCountForLegendary) external onlyManager {
        nodeCountForLesser = _nodeCountForLesser;
        nodeCountForCommon = _nodeCountForCommon;
        nodeCountForLegendary = _nodeCountForLegendary;
    }

    function setTaxForFusion(uint256 _taxForLesser, uint256 _taxForCommon, uint256 _taxForLegendary) external onlyManager {
        taxForLesser = _taxForLesser;
        taxForCommon = _taxForCommon;
        taxForLegendary = _taxForLegendary;
    }

    function updateNodeLimit(uint256 newValue) external onlyManager {
        nodeLimit = newValue;
    }

    function migrateNode(address _account, string memory _name, uint256 _creationTime, uint256 _lastClaimTime, uint256 _expireTime, uint256 _type, uint256 _isStake, uint256 _rewardedAmount) external onlyManager {
        require(_nodesCount[_account] < nodeLimit, "Can't create nodes over 100");
        require(allowMigrate, "Now Allowed to Migrate");
        uint256 rewardsPerMinute;
        if (_isStake == 0) {
            if (_type == uint256(1)) {
                rewardsPerMinute = rewardPerMinuteLesser;
                lesserNodes[_account] = lesserNodes[_account].add(1);
            } else if (_type == uint256(2)) {
                rewardsPerMinute = rewardPerMinuteCommon;
                commonNodes[_account] = commonNodes[_account].add(1);
            } else if (_type == uint256(3)) {
                rewardsPerMinute = rewardPerMinuteLegendary;
                legendaryNodes[_account] = legendaryNodes[_account].add(1);
            } else if (_type == uint256(4)) {
                rewardsPerMinute = rewardsPerMinuteOMEGA;
                omegaOwner[_account] = true;
            }
        } else if (_isStake == 1) {
            if (_type == uint256(1)) {
                rewardsPerMinute = rewardPerMinuteLesserStake;
                lesserNodesStake[_account] = lesserNodesStake[_account].add(1);
            } else if (_type == uint256(2)) {
                rewardsPerMinute = rewardPerMinuteCommonStake;
                commonNodesStake[_account] = commonNodesStake[_account].add(1);
            } else if (_type == uint256(3)) {
                rewardsPerMinute = rewardPerMinuteLegendaryStake;
                legendaryNodesStake[_account] = legendaryNodesStake[_account].add(1);
            }
        }
        _nodesOfUser[_account].push(
            NodeEntity({
                creationTime: _creationTime,
                lastClaimTime:_lastClaimTime,
				expireTime: _expireTime,
                rewardsPerMinute: rewardsPerMinute,
                name: _name,
                nodeType: _type,
                created: 1,
                isStake: _isStake,
                rewardedAmount: _rewardedAmount
            })
        );
        totalNodesCreated++;
        _nodesCount[_account] ++;
        refreshNodes(_account);
		emit NodeCreated(_account, _name, _nodesOfUser[_account].length, totalNodesCreated, _type);
    }

    function createNode(address account, string memory name, uint256 expireTime, uint256 _type, uint256 _isStake) external onlyManager {
        require(_nodesCount[account] < nodeLimit, "Can't create nodes over 100");
		uint256 realExpireTime = 0;
		if (expireTime > 0) {
			realExpireTime = block.timestamp + expireTime;
		}
        uint256 rewardsPerMinute;
        if (_isStake == 0) {
            if (_type == uint256(1)) {
                rewardsPerMinute = rewardPerMinuteLesser;
                lesserNodes[account] = lesserNodes[account].add(1);
            } else if (_type == uint256(2)) {
                rewardsPerMinute = rewardPerMinuteCommon;
                commonNodes[account] = commonNodes[account].add(1);
            } else if (_type == uint256(3)) {
                rewardsPerMinute = rewardPerMinuteLegendary;
                legendaryNodes[account] = legendaryNodes[account].add(1);
            } else if (_type == uint256(4)) {
                rewardsPerMinute = rewardsPerMinuteOMEGA;
                omegaOwner[account] = true;
            }
        } else if (_isStake == 1) {
            if (_type == uint256(1)) {
                rewardsPerMinute = rewardPerMinuteLesserStake;
                lesserNodesStake[account] = lesserNodesStake[account].add(1);
            } else if (_type == uint256(2)) {
                rewardsPerMinute = rewardPerMinuteCommonStake;
                commonNodesStake[account] = commonNodesStake[account].add(1);
            } else if (_type == uint256(3)) {
                rewardsPerMinute = rewardPerMinuteLegendaryStake;
                legendaryNodesStake[account] = legendaryNodesStake[account].add(1);
            }
        }
        _nodesOfUser[account].push(
            NodeEntity({
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
				expireTime: realExpireTime,
                rewardsPerMinute: rewardsPerMinute,
                name: name,
                nodeType: _type,
                created: 1,
                isStake: _isStake,
                rewardedAmount: 0
            })
        );
        totalNodesCreated++;
        _nodesCount[account] ++;
        refreshNodes(account);
		emit NodeCreated(account, name, _nodesOfUser[account].length, totalNodesCreated, _type);
    }

    function _compoundForNode(address account, uint256 amount, uint256 _type, bool isFusion) external onlyManager returns(uint256) {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = _nodesCount[account];
        require(nodesCount > 0, "NODE: NO NODE OWNER");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        if (isFusion) {
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (_node.nodeType != _type) {
                    continue;
                }
                uint256 rewardNode = dividendsOwing(_node);

                if (rewardsTotal + rewardNode <= amount) {
                    _node.rewardedAmount = _node.rewardedAmount + rewardNode;
                    _node.lastClaimTime = block.timestamp;
                    rewardsTotal += rewardNode;
                } else {
                    _node.rewardedAmount = _node.rewardedAmount + amount - rewardsTotal;
                    _node.lastClaimTime = block.timestamp;
                    rewardsTotal += amount - rewardsTotal;
                    break;
                }
            }
        }

        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            uint256 rewardNode = dividendsOwing(_node);

            if (rewardsTotal + rewardNode <= amount) {
                _node.rewardedAmount = _node.rewardedAmount + rewardNode;
                _node.lastClaimTime = block.timestamp;
                rewardsTotal += rewardNode;
            } else {
                _node.rewardedAmount = _node.rewardedAmount + amount - rewardsTotal;
                _node.lastClaimTime = block.timestamp;
                rewardsTotal += amount - rewardsTotal;
                break;
            }
        }

        return rewardsTotal;
    }

    function toggleMigrateMode() external onlyManager {
        allowMigrate = !allowMigrate;
    }

    function giftNode(address account, string memory name, uint256 _type) external onlyManager {
        require(_nodesCount[account] < nodeLimit, "Can't create nodes over 100");
        require(_type > 0 &&  _type < 5, "NOT ALLOWED");

        uint256 rewardsPerMinute;

        if (_type == uint256(1)) {
            rewardsPerMinute = rewardPerMinuteLesser;
            lesserNodes[account] = lesserNodes[account].add(1);
        } else if (_type == uint256(2)) {
            rewardsPerMinute = rewardPerMinuteCommon;
            commonNodes[account] = commonNodes[account].add(1);
        } else if (_type == uint256(3)) {
            rewardsPerMinute = rewardPerMinuteLegendary;
            legendaryNodes[account] = legendaryNodes[account].add(1);
        } else if (_type == uint256(4)) {
            rewardsPerMinute = rewardsPerMinuteOMEGA;
            omegaOwner[account] = true;
        }

        _nodesOfUser[account].push(
            NodeEntity({
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
				expireTime: 0,
                rewardsPerMinute: rewardsPerMinute,
                name: name,
                nodeType: _type,
                created: 1,
                isStake: 0,
                rewardedAmount: 0
            })
        );
        totalNodesCreated++;
        _nodesCount[account] ++;
        refreshNodes(account);
		emit NodeCreated(account, name, _nodesOfUser[account].length, totalNodesCreated, _type);
    }

    // Private

    function refreshNodes(address account) private {
        NodeEntity[] memory nodes = _nodesOfUser[account];

        NodeEntity memory _node;

        uint256 i = 0;

        while(i < _nodesCount[account]) {

            _node = nodes[i];

            if (keccak256(abi.encodePacked(_node.name)) != keccak256(abi.encodePacked(""))) {
                i++;
                continue;
            }

            _nodesOfUser[account][i] = _nodesOfUser[account][nodes.length - 1];
            delete _nodesOfUser[account][nodes.length - 1];
            break;
        }
    }

	function dividendsOwing(NodeEntity memory node) private view returns (uint256 availableRewards) {
		uint256 currentTime = block.timestamp;
		if (currentTime > node.expireTime && node.expireTime > 0) {
			currentTime = node.expireTime;
		}
		uint256 minutesPassed = (currentTime).sub(node.creationTime).div(claimInterval);
        if (node.lastClaimTime == node.creationTime) {
		    return minutesPassed.mul(node.rewardsPerMinute);
        } else {
		    return minutesPassed.mul(node.rewardsPerMinute).sub(node.rewardedAmount);
        }
	}

	function _checkExpired(NodeEntity memory node) private view returns (bool isExpired) {
		return (node.expireTime > 0 && node.expireTime <= block.timestamp);
	}

    function _getNodeByIndex(
        NodeEntity[] storage nodes,
        uint256 index
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        require(index < numberOfNodes, "CASHOUT ERROR: Invalid node");
        return nodes[index];
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
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

    function isNodeOwner(address account) private view returns (bool) {
        return _nodesCount[account] > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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