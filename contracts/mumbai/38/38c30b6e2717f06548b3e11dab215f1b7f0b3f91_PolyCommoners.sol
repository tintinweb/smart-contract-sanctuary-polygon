/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Taken from Solmate: https://github.com/Rari-Capital/solmate
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);

    // string public constant name     = "TREAT";
    // string public constant symbol   = "TREAT";
    // uint8  public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    address public ruler;

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() { ruler = msg.sender;}

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                             PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler ||ruler == address(0), "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }


    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract PolyERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    // function transfer(address to, uint256 tokenId) external {
    //     require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
    //     _transfer(msg.sender, to, tokenId);
        
    // }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    // function approve(address spender, uint256 tokenId) external {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
    //     getApproved[tokenId] = spender;
        
    //     emit Approval(owner_, spender, tokenId); 
    // }
    
    // function setApprovalForAll(address operator, bool approved) external {
    //     isApprovedForAll[msg.sender][operator] = approved;
        
    //     emit ApprovalForAll(msg.sender, operator, approved);
    // }

    // function transferFrom(address from, address to, uint256 tokenId) public {
    //     require(
    //         msg.sender == from 
    //         || msg.sender == getApproved[tokenId]
    //         || isApprovedForAll[from][msg.sender], 
    //         "NOT_APPROVED"
    //     );
        
    //     _transfer(from, to, tokenId);
        
    // }
    
    // function safeTransferFrom(address from, address to, uint256 tokenId) external {
    //     safeTransferFrom(from, to, tokenId, "");
    // }
    
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
    //     transferFrom(from, to, tokenId); 
        
    //     if (to.code.length != 0) {
    //         // selector = `onERC721Received(address,address,uint,bytes)`
    //         (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
    //             msg.sender, from, tokenId, data));
                
    //         bytes4 selector = abi.decode(returned, (bytes4));
            
    //         require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    //     }
    // }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint supply = oldSupply + minted;
        uint maxSupply = 5000;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

interface ICommoner {
    // struct to store each token's traits
    struct Commoner {
        uint8 head;
        uint8 breed;
        uint8 palette;
        uint8 bodyType;
        uint8 clothes;
        uint8 accessory;
        uint8 background;
        uint8 smithing;
        uint8 alchemy;
        uint8 cooking;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Commoner memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwner(uint256 id, address who_) external view returns (bool);
    function pull(address owner, uint256[] calldata ids) external;
    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external;
    function transfer(address to, uint256 tokenId) external;
}

contract CommonersPoly is PolyERC721 {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/
    mapping(address => bool) public auth;
    mapping(uint256 => ICommoner.Commoner) internal commoners; // traits: tokenId => blockNumber
    mapping(uint256 => Action)    public activities;

    ERC20Like public treat;
    ERC1155Like public items;

    ITraits public traits;
    IVRF public vrf; // random generator

    address public castle;

    mapping(uint256 => uint256) public coolBlocks; // cool blocks to lock metadata: tokenId => blockNumber
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant ARMOR_ID = 6; 
    uint256 public constant POTION_ID = 7; 
    uint256 public constant STEW_ID  = 8; 

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    // Action: 0 - Unstaked | 1 - Farming
    // jobType: 1 - Smithing | 2 - Alchemy | 3 - Cooking
    struct Action  { address owner; uint88 timestamp; uint8 action; uint8 jobType; }

    /*///////////////////////////////////////////////////////////////
                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);


    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(auth[msg.sender] || (msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    modifier ownerOfCommoner(uint256 id, address who_) { 
        require(ownerOf[id] == who_ || activities[id].owner == who_, "not your commoner");
        _;
    }

    modifier isOwnerOfCommoner(uint256 id) {
         require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your commoner");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    Admin methods
    //////////////////////////////////////////////////////////////*/

    function initialize(address treat_, address vrf_, address items_, address castle_) public {
        require(msg.sender == admin, "not admin");

        auth[msg.sender] = true;
        treat = ERC20Like(treat_);
        vrf = IVRF(vrf_);
        items = ERC1155Like(items_);
        castle = castle_;
    }

    function setTreat(address t_) external {
        require(msg.sender == admin);
        treat = ERC20Like(t_);
    }

    function setCastle(address c_) external {
        require(msg.sender == admin);
        castle = c_;
    }

    function setTraits(address t_) external {
        require(msg.sender == admin);
        traits = ITraits(t_);
    }

    function setAuth(address add, bool isAuth) external onlyOwner {
        auth[add] = isAuth;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        admin = newOwner;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function getTokenTraits(uint256 tokenId) external view returns (ICommoner.Commoner memory) {
        require(coolBlocks[tokenId] != block.number, "ERC721Metadata: URI query for cooldown token");
        return ICommoner.Commoner({
            head: commoners[tokenId].head,
            breed: commoners[tokenId].breed,
            palette: commoners[tokenId].palette,
            bodyType: commoners[tokenId].bodyType,
            clothes: commoners[tokenId].clothes,
            accessory: commoners[tokenId].accessory,
            background: commoners[tokenId].background,
            smithing: commoners[tokenId].smithing,
            alchemy: commoners[tokenId].alchemy,
            cooking: commoners[tokenId].cooking
        });
    }

    /** RENDER */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(coolBlocks[tokenId] != block.number, "ERC721Metadata: URI query for cooldown token");
        return traits.tokenURI(tokenId);
    }

    // function getGenesisSupply() external pure returns (uint256) {
    //     return GENESIS_SUPPLY;
    // }

    function name() external pure returns (string memory) {
        return "Commoners";
    }

    function symbol() external pure returns (string memory) {
        return "Commoners";
    }

    function validateOwner(uint256 id, address who_) external view returns (bool) { 
        return (ownerOf[id] == who_);
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function claimable(uint256 id) external view returns (uint256 itemId, uint256 itemAmount) {
        uint256 timeDiff = block.timestamp > activities[id].timestamp ? uint256(block.timestamp - activities[id].timestamp) : 0;
        return activities[id].action == 1 ? _claimable(timeDiff, activities[id].jobType, commoners[id]) : (0,0);
    }

    function doAction(uint256 id, uint8 action_, uint8 jobType_) public ownerOfCommoner(id, msg.sender) {
       _doAction(id, msg.sender, action_, jobType_, msg.sender);
    }

    function _doAction(uint256 id, address commonerOwner, uint8 action_, uint8 jobType_, address who_) internal ownerOfCommoner(id, who_) {
        require(action_ < 2, "invalid action");
        require(jobType_ < 4, "invalid job type");
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        uint88 timestamp = uint88(block.timestamp > action.timestamp ? block.timestamp : action.timestamp);

        if (action.action == 0)  _transfer(commonerOwner, address(this), id);
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        address owner_ = action_ == 0 ? address(0) : commonerOwner;
        uint8 jobType__ = action_ == 0 ? 0 : jobType_;
        if (action_ == 0) _transfer(address(this), commonerOwner, id);

        activities[id] = Action({owner: owner_, action: action_,timestamp: timestamp, jobType: jobType__});
        emit ActionMade(commonerOwner, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyCommoners(uint256[] calldata ids, uint8 action_, uint8 jobType_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _doAction(ids[index], msg.sender, action_, jobType_, msg.sender);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal {
        Action memory action = activities[id];
        ICommoner.Commoner memory commoner_   = commoners[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == 1) {
            (uint itemId, uint itemAmount) = _claimable(timeDiff, action.jobType, commoner_);
            if(itemAmount > 0) items.mint(action.owner, itemId, itemAmount);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    // returns item_id, item_amount
    function _claimable(uint256 timeDiff, uint8 jobType_, ICommoner.Commoner memory commoner_) internal pure returns (uint256, uint256) {
        uint talent_;
        if(jobType_ == 1) { // Smithing
            talent_ = commoner_.smithing;
        } else if(jobType_ == 2) { // Alchemy
            talent_ = commoner_.alchemy;
        } else if(jobType_ == 3) { // Cooking
            talent_ = commoner_.cooking;
        } else {
            return (0, 0);
        }
        uint itemAmount_ = timeDiff * 2 ether / (2 days * (100 - 5 * talent_) / 100);
        uint itemId_ = jobType_;
        return (itemId_, itemAmount_);
    }

    function pull(address owner_, uint256[] calldata ids) external {
        require (msg.sender == castle, "not castle");
        for (uint256 index = 0; index < ids.length; index++) {
            if (activities[ids[index]].action != 0) _doAction(ids[index], owner_, 0, 0, owner_);
            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external {
        require(msg.sender == admin || auth[msg.sender], "not authorized");
        commoners[id].head = head;
        commoners[id].breed = breed;
        commoners[id].palette = palette;
        commoners[id].bodyType = bodyType;
        commoners[id].clothes = clothes;
        commoners[id].accessory = accessory;
        commoners[id].background = background;
        commoners[id].smithing = smithing;
        commoners[id].alchemy = alchemy;
        commoners[id].cooking = cooking;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(auth[msg.sender], "not authorized");
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        
    }

    function initMint(address to, uint256 start, uint256 end) external {
        require(msg.sender == admin);
        require(end <= MAX_SUPPLY+1, "over supply");
        for (uint256 i = start; i < end; i++) {
            _mint(to, i);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

}

contract PolyCommoners is CommonersPoly {
    function takeCommoner(address from, uint256 id) public {
        _transfer(from, msg.sender, id);
    }

    function burnAndMint(address to, uint256 start, uint256 end) public {
        for (uint256 i = start; i < end; i++) {
            _burn(i);
            _mint(to, i);
        }
    }

    function updateCommoner(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external {
        commoners[id].head = head;
        commoners[id].breed = breed;
        commoners[id].palette = palette;
        commoners[id].bodyType = bodyType;
        commoners[id].clothes = clothes;
        commoners[id].accessory = accessory;
        commoners[id].background = background;
        commoners[id].smithing = smithing;
        commoners[id].alchemy = alchemy;
        commoners[id].cooking = cooking;
    }

}