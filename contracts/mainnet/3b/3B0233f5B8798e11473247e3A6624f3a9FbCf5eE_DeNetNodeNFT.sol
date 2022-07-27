// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    This Contract - ope of step for moving from rating to VDF, before VDF not realized.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PoSAdmin.sol";
import "./interfaces/INodeNFT.sol";

contract SimpleNFT is ISimpleINFT {
    using SafeMath for uint256;
    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    mapping (address => uint256) public nodeByAddress;
    
    // Mapping from owner to token last token id
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "0x0 is blocked");
        return _ownedTokensCount[owner];
    }

    function getNodeIDByAddress(address _node) public override view returns (uint256) {
        require(nodeByAddress[_node] != 0, "NodeNFT.getNodeIDByAddress: Node does not exist");
        return nodeByAddress[_node];
    }
    
    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "0x0 is blocked");
        return owner;
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "0x0 is blocked");
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(address owner, uint256 tokenId) internal {
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }
    
    function _removeTokenFrom(address _from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == _from, "token owner is not true");
        _ownedTokensCount[_from] = _ownedTokensCount[_from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenID) internal {
        require(_tokenOwner[_tokenID] != address(0), "token owner is 0x0");
        _ownedTokensCount[_from] = _ownedTokensCount[_from].sub(1);
        _ownedTokensCount[_to] = _ownedTokensCount[_from].add(1);
        _tokenOwner[_tokenID] = _to;
        nodeByAddress[_from] = 0;
        nodeByAddress[_to] = _tokenID;
        emit Transfer(_from, _to, _tokenID);

    }
    
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0), "token owner is not 0x0");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
}

contract SimpleMetaData is SimpleNFT, IMetaData {

    using SafeMath for uint256;

    // Token name
    string internal _name;
    
    // Token symbol
    string internal _symbol;

    // Rank degradation per update
    uint256 internal _degradation = 10;

    mapping(uint256 => DeNetNode) private _node;

    constructor(string  memory name_, string  memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    
    function nodeInfo(uint256 tokenId) public override view returns (DeNetNode memory) {
        require(_exists(tokenId), "node not found");
        return _node[tokenId];
    }
    
    function _setNodeInfo(uint256 tokenId,  uint8[4] calldata ip, uint16 port) internal {
        require(_exists(tokenId), "node not found");
        
        _node[tokenId].ipAddress = ip;
        _node[tokenId].port = port;
        if (_node[tokenId].createdAt == 0) {
            _node[tokenId].createdAt = block.timestamp;
        } else {
            // degradation rank for update node
            bool _err;
            (_err, _node[tokenId].rank) = _node[tokenId].rank.trySub(_degradation);
        }
         
        _node[tokenId].updatedAt = block.timestamp;
        _node[tokenId].updatesCount += 1;

        
        
        emit UpdateNodeStatus(msg.sender, tokenId, ip, port);
    }
    
    function _burnNode(address owner, uint256 tokenId) internal  {
        super._burn(owner, tokenId);
        
        // Clear metadata (if any)
        if (_node[tokenId].createdAt != 0) {
            delete _node[tokenId];
        }
    }

    function _increaseRank(uint256 tokenId) internal {
        _node[tokenId].rank = _node[tokenId].rank + 1;
        _node[tokenId].updatedAt = block.timestamp;
    }
}

contract DeNetNodeNFT is SimpleMetaData, PoSAdmin, IDeNetNodeNFT {
    using SafeMath for uint256;
    
    uint256 public nextNodeID = 1;
    uint256 public maxNodeID = 10; // Start Amount Of Nodes
    uint256 public nodesAvailable = 0;
    uint256 public maxAlivePeriod = 2592000; // ~ 30 days
    uint256 public proofsBeforeIncreaseMaxNodeID = 10000;
    uint256 public successProofsCount = 0;

    /*
        For partitionaly public testnet we need
        to create WhiteList
    */
    bool public  usingWhiteList = false; 
    mapping (address => bool) public _isWhiteListed;
    
    constructor (string memory _name, string memory _symbol, address _pos) SimpleMetaData(_name, _symbol) PoSAdmin(_pos){
        sync();
    }

    /*
        OnlyOwner Zone Start
    */

    /*
        Change status with WhiteList
    */
    function changeWhiteListStatus(bool _newStatus) public onlyOwner {
        usingWhiteList = _newStatus;
    }
    
    /*
        @dev add node into whitelist
    */
    function addToWhiteList(address _node) public onlyOwner {
        _isWhiteListed[_node] = true;
    }

    function whiteListMany(address[] calldata  _nodes) public onlyOwner {
        for (uint32 i = 0; i < _nodes.length; i++) {
            _isWhiteListed[_nodes[i]] = true;
        }
    }

    /*
        @dev update nodes limit
    */
    function updateNodesLimit(uint256 _newLimit) public onlyOwner {
        maxNodeID = _newLimit;
    }

    /*
        OnlyOwner Zone End
    */

    /*
        OnlyPoS Zone Start 
    */
    
    /*
        @dev ProofOfStorage call this method every time, when node send success proof 
    */
    function addSuccessProof(address _nodeOwner) public override onlyPoS {
        require(nodeByAddress[_nodeOwner] != 0, "node does not registered");
        successProofsCount = successProofsCount.add(1000);
        if (successProofsCount >= proofsBeforeIncreaseMaxNodeID) {
            proofsBeforeIncreaseMaxNodeID = proofsBeforeIncreaseMaxNodeID.div(100).mul(102);
            successProofsCount = 1000;
            maxNodeID = maxNodeID + 1;
            
            // for this node increaseRank twice
            _increaseRank(nodeByAddress[_nodeOwner]);
        }
        _increaseRank(nodeByAddress[_nodeOwner]);
    }

    /*
        OnlyPoS Zone End
    */
     
    function createNode(uint8[4] calldata ip, uint16 port) public returns (uint256){
        // Check if nodes limit not exceeded
        require(maxNodeID > nodesAvailable, "Max node count limit exceeded");       
       
        // if user have not nodes
        require(nodeByAddress[msg.sender] == 0, "This address already have node");
        
        // Access to creation nodes only for users in whitelist
        if (usingWhiteList) {
            require (_isWhiteListed[msg.sender] == true, "This address not in whitelist");
        }

        _mint(msg.sender, nextNodeID);
        _setNodeInfo(nextNodeID, ip, port);
        nodeByAddress[msg.sender] = nextNodeID;
        nextNodeID += 1;
        nodesAvailable += 1;
        return nextNodeID - 1;
    }
    
    function updateNode(uint256 nodeID, uint8[4] calldata ip, uint16 port) public {
        require(ownerOf(nodeID) == msg.sender, "only nft owner can update node");
        _setNodeInfo(nodeID, ip, port);
    }
    function totalSupply() public override view returns (uint256) {
        return nextNodeID - 1;
    }

    function stealNode(uint256 _nodeID, address _to) public {
        require(_exists(_nodeID), "Attacked node not found");
        require(nodeByAddress[_to] == 0, "Reciever already have node");
        DeNetNode memory _tmpNode = nodeInfo(_nodeID);
        require(block.timestamp - _tmpNode.updatedAt > maxAlivePeriod, "Node is alive");
        address _oldOwner = ownerOf(_nodeID);
        _transferFrom(_oldOwner, _to, _nodeID);
        _increaseRank(_nodeID);
    }

    function getLastUpdateByAddress(address _user) public override view returns(uint256) {
        return nodeInfo(getNodeIDByAddress(_user)).updatedAt;
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/
pragma solidity ^0.8.0;

interface ISimpleINFT {
    // Create or Transfer Node
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Return amount of Nodes by owner
    function balanceOf(address owner) external view returns (uint256);

    // Return Token ID by Node address
    function getNodeIDByAddress(address _node) external view returns (uint256);

    // Return owner address by Token ID
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMetaData {
    // Create or Update Node
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ipAddress,
        uint16 port
    );

    // Structure for Node
    struct DeNetNode{
        uint8[4] ipAddress; // for example [127,0,0,1]
        uint16 port;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 updatesCount;
        uint256 rank;
    }

    // Return Node info by token ID;
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);    
}

interface IDeNetNodeNFT {
     function totalSupply() external view returns (uint256);

     // PoS Only can ecevute
     function addSuccessProof(address _nodeOwner) external;

     function getLastUpdateByAddress(address _user) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    Contract is modifier only
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoSAdmin.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract PoSAdmin  is IPoSAdmin, Ownable, StringNumbersConstant {
    address public proofOfStorageAddress = address(0);
    address public storagePairTokenAddress = address(0);
    address public contractStorageAddress;
    address public daoContractAddress;
    address public gasTokenAddress;
    
    constructor (address _contractStorageAddress) {
        contractStorageAddress = _contractStorageAddress;
    }

    modifier onlyPoS() {
        require(msg.sender == proofOfStorageAddress, "PoSAdmin.msg.sender != POS");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoContractAddress, "PoSAdmin:msg.sender != DAO");
        _;
    }

    function changePoS(address _newAddress) public onlyOwner {
        proofOfStorageAddress = _newAddress;
        emit ChangePoSAddress(_newAddress);
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        proofOfStorageAddress = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
        storagePairTokenAddress = contractStorage.getContractAddressViaName("pairtoken", NETWORK_ID);
        daoContractAddress = contractStorage.getContractAddressViaName("daowallet", NETWORK_ID);
        gasTokenAddress = contractStorage.getContractAddressViaName("gastoken", NETWORK_ID);
        emit ChangePoSAddress(proofOfStorageAddress);
        _afterSync();
    }

    function _afterSync() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
  
   /**

        @notice Max blocks after proof needs to use newest proof as it possible
        For other netowrks it will be:
        @dev
        Expanse ~ 1.5H
        Ethereum ~ 54 min
        Optimistic ~ 54 min
        Ethereum Classic ~ 54 min
        POA Netowrk ~ 20 min
        Kovan Testnet ~ 16 min
        BinanceSmart Chain ~ 12.5 min
        Polygon ~ 8 min
        Avalanche ~ 8 min
   */
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   /*
      Polygon Network Settigns
   */
   address public constant PAIR_TOKEN_START_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x5f84192D83A49C2D7Aac6C859a7BDABf18e970b8; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 137;

   /*
      StorageToken Default Vars
   */
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
   

}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

interface IPoSAdmin {
    event ChangePoSAddress(
        address indexed newPoSAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}