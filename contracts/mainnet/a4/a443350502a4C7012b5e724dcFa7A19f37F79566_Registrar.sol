/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/did/interfaces/IHashDB.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPushItemSingle {
    function pushElement(bytes32 itemKey, bytes memory itemValue) external;
}

interface IRemoveElement {
    function removeElement(bytes32 itemKey) external;
}

interface IItemArray {
    function itemArrayLength(bytes32 itemKey) external view returns (uint256);

    function itemArraySlice(bytes32 itemKey, uint256 start, uint256 end) external view returns (bytes[] memory);
}

interface IGetElement {
    function getElement(bytes32 itemKey, uint256 idx) external view returns (bytes memory);
}

interface IGetFirstElement {
    function getFirstElement(bytes32 itemKey) external view returns (bytes memory);
}

interface IRemoveItemArray {
    function removeItemArray(bytes32 itemKey) external;
}

interface IReplaceItemArray {
    function replaceItemArray(bytes32 itemKey, bytes[] memory itemArray) external;
}

interface IReplaceItemArrayWithElement {
    function replaceItemArray(bytes32 itemKey, bytes memory itemValue) external;
}


// File contracts/did/interfaces/IDB.sol

// 

pragma solidity ^0.8.9;

interface ISetReverse {
    function setReverse(address owner, bytes32 node) external;
}

interface INodeStatus {
    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);
}

interface IActivate {
    function activate(bytes32 parent, address owner, uint64 expire, string memory name, bytes memory _data)
        external
        returns (bytes32);
}

interface IDeactivate {
    function deactivate(bytes32 node) external;
}

interface NodeStruct {
    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 transfer;
        string name;
    }
}

interface INodeRecord is NodeStruct {
    function getNodeRecord(bytes32 node) external view returns (Node memory);
}

interface IIsNodeActive {
    function isNodeActive(bytes32 node) external view returns (bool);
}

interface IOwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/did/lib/KeyEnumBase.sol

// 

pragma solidity ^0.8.9;

abstract contract KeyEnumBase {
    bytes32 public constant ROOT = bytes32(0);
    uint256 internal constant INDEX_NULL = 0;
    address internal constant ADDRESS_NULL = address(0);
    bytes32 internal constant KEY_NULL = bytes32(0);
    // encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)

    bytes32 internal constant KEY_BRAND = keccak256("KEY_BRAND");
    // contract address for a domain to set customized tokenURI function for subdomain

    bytes32 internal constant KEY_LIKE = keccak256("KEY_LIKE");
    // maxLength == 100
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(0)) => [liker1, liker2, liker3...]
    // maxLength == Type(uint256).max
    // encodeToKey(node, address(0), KEY_LIKE, bytes32(1)) => [(likee1, timestamp1), (likee2, timestamp2)...]

    bytes32 internal constant KEY_ORDER = keccak256("KEY_ORDER");
    // => [(market address, taker address, expire time, fixed price)]

    bytes32 internal constant KEY_TTL = keccak256("KEY_TTL"); // => [time to live]

    // !!! order and ttl should be cleared before transfer !!!

    // bytes32 internal constant KEY_RESERVE = keccak256("KEY_RESERVE"); // => [marker]
}


// File contracts/did/interfaces/IBeacon.sol

// 

pragma solidity ^0.8.9;

interface IDAOBeacon {
    function DAO() external view returns (address);
}

interface IDBBeacon {
    function DB() external view returns (address);
}

interface IEditorBeacon {
    function editor() external view returns (address);
}

interface IBufferBeacon {
    function buffer() external view returns (address);
}

interface IVaultBeacon {
    function vault() external view returns (address);
}

interface IBrandBeacon {
    function brand() external view returns (address);
}

interface IHookBeacon {
    function hook() external view returns (address);
}

interface IMarketBeacon {
    function market() external view returns (address);
}

interface IResolverBeacon {
    function resolver() external view returns (address);
}

interface IFilterBeacon {
    function filter() external view returns (address);
}

interface IValueMiningBeacon {
    function valueMining() external view returns (address);
}


// File contracts/did/platform/AccessControl.sol

// 

pragma solidity ^0.8.9;

abstract contract AccessControl {
    mapping(address => bool) public operators;

    address public beacon;

    event OperatorGranted(address operator, bool granted);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    modifier onlyDAO() {
        require(msg.sender == _DAO(), "Caller is not the DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    function _DAO() internal view virtual returns (address) {
        return IDAOBeacon(beacon).DAO();
    }

    function setOperator(address addr, bool granted) external onlyDAO {
        _setOperator(addr, granted);
    }

    function setOperators(address[] calldata addrs, bool granted) external onlyDAO {
        for (uint256 i = 0; i < addrs.length; i++) {
            _setOperator(addrs[i], granted);
        }
    }

    function _setOperator(address addr, bool granted) internal {
        operators[addr] = granted;
        emit OperatorGranted(addr, granted);
    }
}


// File @openzeppelin/contracts/security/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/did/lib/Parser.sol

// 

pragma solidity ^0.8.9;

library Parser {
    function encodeNameToNode(bytes32 parent, string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // !!! keyHash must be a hash value, but keySub might be converted from a unit256 number directly !!!
    function encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, owner, keyHash, keySub));
    }

    function abiBytesToAddressTime(bytes memory bys) internal pure returns (address addr, uint64 time) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
        time = uint64(num & type(uint96).max);
    }

    //
    //    function abiBytesToAddress(bytes memory bys) internal pure returns (address ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (address));
    //        }
    //        return ret;
    //    }
    //
    //    function abiBytesToUint64(bytes memory bys) internal pure returns (uint64 ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (uint64));
    //        }
    //        return ret;
    //    }
    //
    function abiBytesToUint256(bytes memory bys) internal pure returns (uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }
    //
    //    function abiBytesToString(bytes memory bys) internal pure returns (string memory ret) {
    //        if (bys.length > 0) {
    //            ret = abi.decode(bys, (string));
    //        }
    //        return ret;
    //    }
    //

    function abiBytesCutToAddress(bytes memory bys) internal pure returns (address addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
    }
}


// File contracts/did/lib/Releasable.sol

// 

pragma solidity ^0.8.9;

contract Releasable {
    uint256 public startTime;
    uint256 public dailyAmount;
    uint256 public preConsumable;
    uint256 public consumedAmount;

    event SpeedChanged(uint256 preStartTime, uint256 preSpeed, uint256 currentSpeed);

    constructor(uint256 _startTime, uint256 _dailyAmount) {
        if (_startTime == 0) {
            _startTime = block.timestamp - (1 days);
        }
        startTime = _startTime;
        dailyAmount = _dailyAmount;
    }

    function _consume(uint256 amount) internal {
        require(_consumable() >= amount, "Not enough yet");
        consumedAmount += amount;
    }

    function _updateSpeed(uint256 _dailyAmount) internal {
        preConsumable = _consumable(); // flush pre speed

        emit SpeedChanged(startTime, dailyAmount, _dailyAmount);
        dailyAmount = _dailyAmount;
        startTime = block.timestamp;
    }

    function _consumable() internal view returns (uint256 amount) {
        if (block.timestamp >= startTime) {
            amount = (block.timestamp - startTime) * dailyAmount / (24 hours) + preConsumable - consumedAmount;
        }
    }

    function consumable() external view returns (uint256 amount) {
        return _consumable();
    }
}


// File contracts/lib/TransferHelper.sol

// 

pragma solidity ^0.8.9;

library TransferHelper {
    function sendValue(address recipient, uint256 amount) internal {
        address payable payableRecipient = payable(recipient);

        require(address(this).balance >= amount, "Insufficient balance");

        (bool success,) = payableRecipient.call{value: amount}("");
        require(success, "Unable to send value");
    }
}


// File contracts/did/Registrar.sol

// 

pragma solidity ^0.8.9;







interface IFilter {
    function validName(string memory name) external view returns (bool);
}

contract Registrar is AccessControl, KeyEnumBase, ReentrancyGuard, Releasable {
    using TransferHelper for address;

    uint256 public baseCost = 10 ether; // 10 MATIC
    uint256 public likeCost = 1 ether; // 1 MATIC
    bytes32 public immutable topLevelNode;
    string public topLevelName;

    // agent will get 90/100 of base-price as reward
    uint256 public constant PRECISION = 1e9;
    uint256 public agentRatio = 9e8;

    event RatioUpdated(uint256 ratio);
    event BaseCostUpdated(uint256 cost);
    event LikeCostUpdated(uint256 cost);

    constructor(address _beacon, string memory _name, uint256 _baseCost, uint256 _startTime, uint256 _dailyAmount)
        AccessControl(_beacon)
        Releasable(_startTime, _dailyAmount)
    {
        topLevelNode = keccak256(abi.encodePacked(ROOT, keccak256(abi.encodePacked(_name))));
        topLevelName = _name;
        if (_baseCost > 0) {
            baseCost = _baseCost;
        }
    }

    function setBaseCost(uint256 cost) external onlyOperator {
        baseCost = cost;
        emit BaseCostUpdated(cost);
    }

    function setLikeCost(uint256 cost) external onlyOperator {
        likeCost = cost;
        emit LikeCostUpdated(cost);
    }

    function setAgentRatio(uint256 ratio) external onlyDAO {
        require(agentRatio != ratio, "Nothing changes");
        agentRatio = ratio;
        emit RatioUpdated(ratio);
    }

    function getBasePrice(string memory name) external view returns (uint256) {
        return _getBasePrice(name);
    }

    function _getBasePrice(string memory name) internal view returns (uint256) {
        uint256 nameLength = bytes(name).length;
        uint256 basePrice = baseCost;
        if (nameLength < 6) {
            basePrice = (3 ** (6 - nameLength)) * basePrice;
        }
        return basePrice;
    }

    // 1L ~ 3L are reserved, <4L 10Matic> <5L, 30Matic> <6L 90Matic>...
    function getCost(address db, string memory name)
        public
        view
        returns (
            bytes32 node,
            address owner,
            address reserver,
            uint256 basePrice,
            uint256 reserveReward,
            uint256 likeReward,
            uint256 totalCost,
            bytes[] memory fansArray
        )
    {
        require(IFilter(IFilterBeacon(beacon).filter()).validName(name), "Invalid name");
        node = Parser.encodeNameToNode(topLevelNode, name);
        if (db == address(0)) {
            db = IDBBeacon(beacon).DB();
        }

        IItemArray ha = IItemArray(db);
        bytes32 itemKey = Parser.encodeToKey(node, ADDRESS_NULL, KEY_LIKE, KEY_NULL);
        uint256 fansNum = ha.itemArrayLength(itemKey);
        if (fansNum > 0) {
            fansArray = ha.itemArraySlice(itemKey, 0, fansNum - 1);
        }

        owner = INodeRecord(db).getNodeRecord(node).owner;
        if (owner == address(0)) {
            basePrice = _getBasePrice(name);

            reserver = INodeRecord(IBufferBeacon(beacon).buffer()).getNodeRecord(node).owner;
            if (reserver != address(0)) {
                reserveReward = basePrice;
            }

            likeReward = fansNum * likeCost;
        }

        totalCost = basePrice + reserveReward + likeReward;
    }

    function updateSpeed(uint256 _dailyAmount) external onlyDAO {
        _updateSpeed(_dailyAmount);
    }

    function batchRegister(bytes32 agentNode, address to, string[] calldata names) external payable nonReentrant {
        _consume(names.length);

        // msg.sender.code.length == 0 // contract-caller is not allowed
        // require(tx.origin == msg.sender || operators[msg.sender]); // it is like [nonReentrant]
        require(to != address(0), "Zero address");
        address db = IDBBeacon(beacon).DB();
        NodeStruct.Node memory n = INodeRecord(db).getNodeRecord(agentNode);
        require(n.parent == topLevelNode, "Wrong agent node");
        address agent = n.owner;

        uint256 payAmount = msg.value;
        for (uint256 i = 0; i < names.length; i++) {
            payAmount -= _distribute(db, payAmount, agent, names[i]);
            IActivate(db).activate(topLevelNode, to, 0, names[i], "");
        }

        if (payAmount > 0) {
            msg.sender.sendValue(payAmount);
        }
    }

    function _distribute(address db, uint256 payAmount, address agent, string memory name) private returns (uint256) {
        (
            bytes32 node,
            address owner,
            address reserver,
            uint256 basePrice,
            uint256 reserveReward,
            uint256 likeReward,
            uint256 totalCost,
            bytes[] memory fansArray
        ) = getCost(db, name);

        require(owner == address(0), "Node is existed");
        require(payAmount >= totalCost, "Value is not enough");

        if (reserveReward > 0) {
            reserver.sendValue(reserveReward);
            IDeactivate(IBufferBeacon(beacon).buffer()).deactivate(node);
        }

        if (likeReward > 0) {
            // !!! payAmount is used as reward to avoid compiler error (stack-too-deep) !!!
            payAmount = likeReward / fansArray.length;
            // uint256 reward = likeReward / fansArray.length;
            for (uint256 i = 0; i < fansArray.length; i++) {
                INodeRecord(db).getNodeRecord(abi.decode(fansArray[i], (bytes32))).owner.sendValue(payAmount);
            }
            // _processLike(db, likeReward, fansArray);
        }

        _processAgent(basePrice, agent);

        return totalCost;
    }

    function _processAgent(uint256 basePrice, address agent) internal {
        require(agent != address(0), "No agent");
        uint256 agentFee = basePrice * agentRatio / PRECISION;
        agent.sendValue(agentFee);
        IVaultBeacon(beacon).vault().sendValue(basePrice - agentFee);
    }

    /*
    function _processLike(address db, uint256 likeReward, bytes[] memory fansArray) internal {
        uint256 fansNum = fansArray.length;
        uint256 reward = likeReward / fansNum;
        for (uint256 i = 0; i < fansNum; i++) {
            bytes32 fansNode = abi.decode(fansArray[i], (bytes32));
            INodeRecord(db).getNodeRecord(fansNode).owner.sendValue(reward);
        }
    }
    */
}