/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
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
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];
        
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner_, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            msg.sender == from 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[from][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(from, to, tokenId);
        
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, from, tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
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
  function tokenURINotRevealed(uint256 tokenId) external view returns (string memory);
  function tokenURITopTalents(uint8 topTalentNo, uint256 tokenId) external view returns (string memory);
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

interface IDogewoodForCommonerSale {
    function validateDogeOwnerForClaim(uint256 id, address who_) external view returns (bool);
}

interface ICastleForCommonerSale {
    function dogeOwner(uint256 id) external view returns (address);
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
    function transferFrom(address from, address to, uint256 value) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external view returns (address owner);
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

// import "./ERC721Poly.sol";
/**
 * treat.setMinter(commonerPolyV2, true)
 * vrf.setAuth(commonerPolyV2, true)
 * items.setAuth(commonerPolyV2, true)
 */
contract CommonersPolyV2 is ERC721 {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/
    bool public initialized;
    mapping(address => bool) public auth;
    mapping(uint256 => ICommoner.Commoner) internal commoners; // traits: tokenId => blockNumber
    mapping(uint256 => Action)    public activities;

    ERC20Like public treat;
    ERC1155Like public items;

    ITraits public traits;
    IVRF public vrf; // random generator

    mapping(uint256 => uint256) public coolBlocks; // cool blocks to lock metadata: tokenId => blockNumber
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant ARMOR_ID = 6; 
    uint256 public constant POTION_ID = 7; 
    uint256 public constant STEW_ID  = 8; 

    // list of probabilities for each trait type
    // 0 - 7 are associated with head, breed, palette, bodyType, clothes, accessory, background, smithing, alchemy, cooking
    uint8[][10] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 7 are associated with head, breed, palette, bodyType, clothes, accessory, background, smithing, alchemy, cooking
    uint8[][10] public aliases;

    bool public revealed;
    mapping(uint256 => uint8) public topTalents; // commonerId => topTalentNo (1~4)
    ERC20Like public paymentsToken;
    uint8 public saleStatus; // 0 : not in sale, 1: claim & WL & public, 2: public sale

    address public castle;

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    // Action: 0 - Unstaked | 1 - Farming
    // jobType: 1 - Smithing | 2 - Alchemy | 3 - Cooking
    struct Action  { address owner; uint88 timestamp; uint8 action; uint8 jobType; }

    /*///////////////////////////////////////////////////////////////
                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AirdropTopTalent(uint8 talentId, uint256 commonerId);
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

    function initialize(address treat_, address vrf_, address items_, address _paymentsToken) public {
        require(msg.sender == admin, "not admin");
        require(initialized == false, "already initialized");
        initialized = true;

        auth[msg.sender] = true;
        treat = ERC20Like(treat_);
        vrf = IVRF(vrf_);
        items = ERC1155Like(items_);
        paymentsToken = ERC20Like(_paymentsToken);
        
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // head
        rarities[0] = [173, 155, 255, 206, 206, 206, 114, 114, 114];
        aliases[0] = [2, 2, 8, 0, 0, 0, 0, 1, 1];
        // breed
        rarities[1] = [255, 255, 255, 255, 255, 255, 255, 255];
        aliases[1] = [7, 7, 7, 7, 7, 7, 7, 7];
        // palette
        rarities[2] = [255, 188, 255, 229, 153, 76];
        aliases[2] = [2, 2, 5, 0, 0, 1];
        // bodyType
        rarities[3] = [255, 255];
        aliases[3] = [1, 1];
        // clothes
        rarities[4] = [209, 96, 66, 153, 219, 107, 112, 198, 198, 66, 132, 132, 254];
        aliases[4] = [4, 5, 0, 6, 6, 6, 12, 1, 1, 1, 3, 3, 12];
        // accessory
        rarities[5] = [209, 96, 66, 153, 219, 107, 112, 198, 198, 66, 132, 132, 254];
        aliases[5] = [4, 5, 0, 6, 6, 6, 12, 1, 1, 1, 3, 3, 12];
        // background
        rarities[6] = [142, 254, 244, 183, 122, 61];
        aliases[6] = [1, 5, 0, 0, 0, 0];
        // smithing
        rarities[7] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[7] = [1, 3, 0, 0];
        // alchemy
        rarities[8] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[8] = [1, 3, 0, 0];
        // cooking
        rarities[9] = [204, 255, 153, 51]; // [0.5, 0.3, 0.15, 0.05]
        aliases[9] = [1, 3, 0, 0];
    }

    function setRevealed() external {
        require(msg.sender == admin, "not admin");
        require(!revealed, "already revealed");
        revealed = true;
        _airdropTopTalents();
    }

    function setSaleStatus(uint8 status_) public {
        require(msg.sender == admin, "not admin");
        saleStatus = status_;
    }

    // function setTopTalents(uint256[] memory commonerIds, uint8[] memory topTalentNos) external {
    //     require(msg.sender == admin);
    //     require(commonerIds.length == topTalentNos.length);
    //     for (uint256 i = 0; i < commonerIds.length; i++) {
    //         topTalents[commonerIds[i]] = topTalentNos[i];
    //     }
    // }

    function setTreat(address t_) external {
        require(msg.sender == admin);
        treat = ERC20Like(t_);
    }

    function setPaymentsToken(address _paymentsToken) external onlyOwner {
        paymentsToken = ERC20Like(_paymentsToken);
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

    function withdraw() external {
        require(msg.sender == admin, "not admin");
        address w1 = 0x8c8bbDB5C8D9c35FfB4493490172D2787648cAD8;
        uint balance = paymentsToken.balanceOf(address(this));
        require(balance > 0);
        paymentsToken.transfer(w1, balance);
    }

    /*///////////////////////////////////////////////////////////////
                    MINT
    //////////////////////////////////////////////////////////////*/

    function initMint(uint256[] memory amounts_, address[] memory to_) external noCheaters {
        require(msg.sender == admin, "not admin");
        require(amounts_.length == to_.length, "invalid input");

        uint256 count_ = totalSupply;
        for (uint256 i = 0; i < amounts_.length; i++) {
            require(amounts_[i] > 0, "empty amount");
            count_ += amounts_[i];
        }
        require(count_ <= MAX_SUPPLY, "exceeds supply");

        for (uint256 i = 0; i < amounts_.length; i++) {
            for (uint256 j = 0; j < amounts_[i]; j++) {
                _mintCommoner(to_[i]);
            }
        }
    }

    function publicMint(uint256 quantity_, bool useTreat) external noCheaters {
        require(saleStatus == 1, "status is not public sale");
        require(quantity_ <= 6, "exceed max quantity");
        require(totalSupply+quantity_ <= MAX_SUPPLY, "sold out");

        if(useTreat) {
            treat.burn(msg.sender, quantity_ * 150 ether);
        } else { // weth
            paymentsToken.transferFrom(msg.sender, address(this), quantity_ * 0.035 ether);
        }
        for (uint256 i = 0; i < quantity_; i++) {
            _mintCommoner(msg.sender);
        }
    }

    function _mintCommoner(address to) internal {
        uint16 id_ = uint16(totalSupply + 1);
        uint256 seed = vrf.getRandom(id_);
        generate(id_, seed);
        coolBlocks[id_] = block.number;
        _mint(to, id_);
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
        if(topTalents[tokenId] > 0) return traits.tokenURITopTalents(topTalents[tokenId], tokenId);
        return traits.tokenURI(tokenId);
    }

    function name() external pure returns (string memory) {
        return "Commoners";
    }

    function symbol() external pure returns (string memory) {
        return "COMMONERS";
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
        require (msg.sender == castle && castle != address(0), "not castle");
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
    
    // function transfer(address to, uint256 tokenId) external {
    //     require(auth[msg.sender], "not authorized");
    //     require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
    //     _transfer(msg.sender, to, tokenId);
        
    // }

    /*///////////////////////////////////////////////////////////////
                    Internal methods
    //////////////////////////////////////////////////////////////*/

    function _airdropTopTalents() internal {
        uint256 airdropMax_ = totalSupply > MAX_SUPPLY ? MAX_SUPPLY : (totalSupply-1);
        for (uint8 i = 1; i <= 4; i++) {
            uint256 topCommoner_;
            do {
                topCommoner_ = (vrf.getRandom(i) % airdropMax_) + 1;
            } while (topTalents[topCommoner_] > 0);
            topTalents[topCommoner_] = i;

            // Set traits of top talents - commoners[topCommoner_]
            if(i == 1) {
                // Rudy Hammerpaw, Master Blacksmith
                //     uint8 head; Determined
                //     uint8 breed; Pitbull
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Rudy's Smithing Apron
                //     uint8 accessory; Rudy's Eye Patch
                //     uint8 background; The Forge
                commoners[topCommoner_].head = 0;
                commoners[topCommoner_].breed = 6;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 13;
                commoners[topCommoner_].accessory = 13;
                commoners[topCommoner_].background = 6;
                commoners[topCommoner_].smithing = 5;
                commoners[topCommoner_].alchemy = 1;
                commoners[topCommoner_].cooking = 1;
            } else if(i == 2) {
                // Catharine Von Schbeagle, Savant of Science
                //     uint8 head; Excited
                //     uint8 breed; Beagle
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Goggles of Science
                //     uint8 accessory; Von Schbeagle's Lab Coat
                //     uint8 background; Artificer's Lab
                commoners[topCommoner_].head = 9;
                commoners[topCommoner_].breed = 8;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 14;
                commoners[topCommoner_].accessory = 14;
                commoners[topCommoner_].background = 7;
                commoners[topCommoner_].smithing = 1;
                commoners[topCommoner_].alchemy = 5;
                commoners[topCommoner_].cooking = 1;
            } else if(i == 3) {
                // Charlie Chonkins, Royal Cook
                //     uint8 head; Content
                //     uint8 breed; Corgi
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Royal Chef's Apron
                //     uint8 accessory; Royal Chef's Hat
                //     uint8 background; The Mess Hall
                commoners[topCommoner_].head = 10;
                commoners[topCommoner_].breed = 2;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 15;
                commoners[topCommoner_].accessory = 15;
                commoners[topCommoner_].background = 8;
                commoners[topCommoner_].smithing = 1;
                commoners[topCommoner_].alchemy = 1;
                commoners[topCommoner_].cooking = 5;
            } else if(i == 4) {
                // Prince Pom, Prince of Dogewood Kingdom
                //     uint8 head; Proud
                //     uint8 breed; Pomeranian
                //     uint8 palette; 1
                //     uint8 bodyType; A
                //     uint8 clothes; Coat of the Strategist
                //     uint8 accessory; Dogewood Royal Scepter
                //     uint8 background; The War Room
                commoners[topCommoner_].head = 11;
                commoners[topCommoner_].breed = 9;
                commoners[topCommoner_].palette = 0;
                commoners[topCommoner_].bodyType = 0;
                commoners[topCommoner_].clothes = 16;
                commoners[topCommoner_].accessory = 16;
                commoners[topCommoner_].background = 9;
                commoners[topCommoner_].smithing = 4;
                commoners[topCommoner_].alchemy = 4;
                commoners[topCommoner_].cooking = 4;
            }
            emit AirdropTopTalent(i, topCommoner_);
        }
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (ICommoner.Commoner memory t) {
        t = selectTraits(seed);
        commoners[tokenId] = t;
        return t;

        // keep the following code for future use, current version using different seed, so no need for now
        // if (existingCombinations[structToHash(t)] == 0) {
        //     doges[tokenId] = t;
        //     existingCombinations[structToHash(t)] = tokenId;
        //     return t;
        // }
        // return generate(tokenId, random(seed));
    }

    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (ICommoner.Commoner memory t) {    
        t.head = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        t.breed = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        t.palette = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        t.bodyType = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 6);
        seed >>= 16;
        t.smithing = selectTrait(uint16(seed & 0xFFFF), 7);
        seed >>= 16;
        t.alchemy = selectTrait(uint16(seed & 0xFFFF), 8);
        seed >>= 16;
        t.cooking = selectTrait(uint16(seed & 0xFFFF), 9);
        seed >>= 16;
    }

    // /**
    // * converts a struct to a 256 bit hash to check for uniqueness
    // * @param s the struct to pack into a hash
    // * @return the 256 bit hash of the struct
    // */
    // function structToHash(ICommoner.Commoner memory s) internal pure returns (uint256) {
    //     return uint256(bytes32(
    //         abi.encodePacked(
    //             s.head,
    //             s.breed,
    //             s.palette,
    //             s.bodyType,
    //             s.clothes,
    //             s.accessory,
    //             s.background,
    //             s.smithing,
    //             s.alchemy,
    //             s.cooking
    //         )
    //     ));
    // }
    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

}