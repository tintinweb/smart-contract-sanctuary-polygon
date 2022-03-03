/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// 

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/interfaces/RarelifeStructs.sol

// 
pragma solidity ^0.8.4;

library RarelifeStructs {

    struct SAbilityScore {
        uint32 _chr; // charm CHR
        uint32 _int; // intelligence INT
        uint32 _str; // strength STR
        uint32 _mny; // money MNY

        uint32 _spr; // happy SPR
        uint32 _lif; // health LIF
        //uint32 _age; // age AGE
    }

    struct SAbilityModifiers {
        int32 _chr;
        int32 _int;
        int32 _str;
        int32 _mny;

        int32 _spr;
        int32 _lif;
        int32 _age;
    }
}


// File contracts/interfaces/RarelifeInterfaces.sol

// 
pragma solidity ^0.8.4;




interface IRarelifeRandom {
    function dn(uint _actor, uint _number) external view returns (uint);
    function d20(uint _actor) external view returns (uint);
}

interface IRarelife is IERC721 {

    event actorMinted(address indexed _owner, uint indexed _actor, uint indexed _time);

    function actor(uint _actor) external view returns (uint _mintTime, uint _status);
    function next_actor() external view returns (uint);
    function mint_actor() external;
}

interface IRarelifeTimeline {

    event Born(address indexed creator, uint indexed actor);
    event AgeEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);
    event BranchEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);
    event ActiveEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);

    function ACTOR_ADMIN() external view returns (uint);
    function ages(uint _actor) external view returns (uint); //current age
    function expected_age(uint _actor) external view returns (uint); //age should be
    function character_born(uint _actor) external view returns (bool);
    function character_birthday(uint _actor) external view returns (bool);
    function actor_event(uint _actor, uint _age) external view returns (uint[] memory);
    function actor_event_count(uint _actor, uint _eventId) external view returns (uint);

    function active_trigger(uint _eventId, uint _actor, uint[] memory _uintParams) external;
}

interface IRarelifeNames is IERC721Enumerable {

    event NameClaimed(address indexed owner, uint indexed actor, uint indexed name_id, string name, string first_name, string last_name);
    event NameUpdated(uint indexed name_id, string old_name, string new_name);
    event NameAssigned(uint indexed name_id, uint indexed previous_actor, uint indexed new_actor);

    function next_name() external view returns (uint);
    function actor_name(uint _actor) external view returns (string memory name, string memory firstName, string memory lastName);
}

interface IRarelifeAttributes {

    event Created(address indexed creator, uint indexed actor, uint32 CHR, uint32 INT, uint32 STR, uint32 MNY, uint32 SPR, uint32 LIF);
    event Updated(address indexed executor, uint indexed actor, uint32 CHR, uint32 INT, uint32 STR, uint32 MNY, uint32 SPR, uint32 LIF);

    function set_attributes(uint _actor, RarelifeStructs.SAbilityScore memory _attr) external;
    function ability_scores(uint _actor) external view returns (RarelifeStructs.SAbilityScore memory);
    function character_points_initiated(uint _actor) external view returns (bool);
    function apply_modified(uint _actor, RarelifeStructs.SAbilityModifiers memory attr_modifier) external view returns (RarelifeStructs.SAbilityScore memory, bool);
}

interface IRarelifeTalents {

    event Created(address indexed creator, uint indexed actor, uint[] ids);

    function talents(uint _id) external view returns (string memory _name, string memory _description);
    function talent_attribute_modifiers(uint _id) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function talent_attr_points_modifiers(uint _id) external view returns (int);
    function set_talent(uint _id, string memory _name, string memory _description, RarelifeStructs.SAbilityModifiers memory _attribute_modifiers, int _attr_point_modifier) external;
    function set_talent_exclusive(uint _id, uint[] memory _exclusive) external;
    function set_talent_condition(uint _id, address _conditionAddress) external;
    function talent_exclusivity(uint _id) external view returns (uint[] memory);

    function actor_attribute_point_buy(uint _actor) external view returns (uint);
    function actor_talents(uint _actor) external view returns (uint[] memory);
    function actor_talents_initiated(uint _actor) external view returns (bool);
    function actor_talents_exist(uint _actor, uint[] memory _talents) external view returns (bool[] memory);
    function can_occurred(uint _actor, uint _id, uint _age) external view returns (bool);
}

interface IRarelifeTalentChecker {
    function check(uint _actor, uint _age) external view returns (bool);
}

interface IRarelifeEvents {
    function event_info(uint _id, uint _actor) external view returns (string memory);
    function event_attribute_modifiers(uint _id, uint _actor) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function event_processors(uint _id) external view returns(address);
    function set_event_processor(uint _id, address _address) external;
    function can_occurred(uint _actor, uint _id, uint _age) external view returns (bool);
    function check_branch(uint _actor, uint _id, uint _age) external view returns (uint);
}

interface IRarelifeEventProcessor {
    function event_info(uint _actor) external view returns (string memory);
    function event_attribute_modifiers(uint _actor) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function check_occurrence(uint _actor, uint _age) external view returns (bool);
    function process(uint _actor, uint _age) external;
    function active_trigger(uint _actor, uint[] memory _uintParams) external;
    function check_branch(uint _actor, uint _age) external view returns (uint);
}

abstract contract DefaultRarelifeEventProcessor is IRarelifeEventProcessor {
    function event_attribute_modifiers(uint /*_actor*/) virtual external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        return RarelifeStructs.SAbilityModifiers(0,0,0,0,0,0,0);
    }
    function check_occurrence(uint /*_actor*/, uint /*_age*/) virtual external view override returns (bool) { return true; }
    function process(uint _actor, uint _age) virtual external override {}
    function check_branch(uint /*_actor*/, uint /*_age*/) virtual external view override returns (uint) { return 0; }
    function active_trigger(uint /*_actor*/, uint[] memory /*_uintParams*/) virtual external override { }
} 

interface IRarelifeFungible {
    event Transfer(uint indexed from, uint indexed to, uint amount);
    event Approval(uint indexed from, uint indexed to, uint amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(uint owner) external view returns (uint);
    function allowance(uint owner, uint spender) external view returns (uint);

    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface IRarelifeGold is IRarelifeFungible {
    function claim(uint _actor, uint _amount) external;
}


// File contracts/interfaces/RarelifeLibrary.sol

// 
pragma solidity ^0.8.4;


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
//-----------------------------------------------------------------------------
/**
 * @dev String operations.
 */
library RarelifeStrings {
    
    function toString(int value) internal pure returns (string memory) {
        string memory _string = '';
        if (value < 0) {
            _string = '-';
            value = value * -1;
        }
        return string(abi.encodePacked(_string, Strings.toString(uint(value))));
    }
}
//-----------------------------------------------------------------------------
library RarelifeConstants {

    //time constants
    uint public constant DAY = 1 days;
    uint public constant HOUR = 1 hours;
    uint public constant MINUTE = 1 minutes;
    uint public constant SECOND = 1 seconds;
}
//-----------------------------------------------------------------------------
contract RarelifeContractRoute {
    // Deployment Address
    address internal _owner;    
 
    address                 public randomAddress;
    IRarelifeRandom         public random;
 
    address                 public rlAddress;
    IRarelife               public rl;
 
    address                 public evtsAddress;
    IRarelifeEvents         public evts;

    address                 public timelineAddress;
    IRarelifeTimeline       public timeline;

    address                 public namesAddress;
    IRarelifeNames          public names;

    address                 public attributesAddress;
    IRarelifeAttributes     public attributes;

    address                 public talentsAddress;
    IRarelifeTalents        public talents;

    address                 public goldAddress;
    IRarelifeGold           public gold;

    constructor() {
        _owner = msg.sender;
    }

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyContractOwner() {
        require(msg.sender == _owner, "RarelifeContractRoute: Only contract owner");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "RarelifeContractRoute: cannot set contract as zero address");
        _;
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerRandom(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(randomAddress == address(0), "RarelifeContractRoute: address already registered.");
        randomAddress = _address;
        random = IRarelifeRandom(_address);
    }

    function registerRLM(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(rlAddress == address(0), "RarelifeContractRoute: address already registered.");
        rlAddress = _address;
        rl = IRarelife(_address);
    }

    function registerEvents(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(evtsAddress == address(0), "RarelifeContractRoute: address already registered.");
        evtsAddress = _address;
        evts = IRarelifeEvents(_address);
    }

    function registerTimeline(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(timelineAddress == address(0), "RarelifeContractRoute: address already registered.");
        timelineAddress = _address;
        timeline = IRarelifeTimeline(_address);
    }

    function registerNames(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(namesAddress == address(0), "RarelifeContractRoute: address already registered.");
        namesAddress = _address;
        names = IRarelifeNames(_address);
    }

    function registerAttributes(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(attributesAddress == address(0), "RarelifeContractRoute: address already registered.");
        attributesAddress = _address;
        attributes = IRarelifeAttributes(_address);
    }

    function registerTalents(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(talentsAddress == address(0), "RarelifeContractRoute: address already registered.");
        talentsAddress = _address;
        talents = IRarelifeTalents(_address);
    }

    function registerGold(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(goldAddress == address(0), "RarelifeContractRoute: address already registered.");
        goldAddress = _address;
        gold = IRarelifeGold(_address);
    }
}
//-----------------------------------------------------------------------------
contract RarelifeConfigurable {
    // Deployment Address
    address internal _owner;    

    // Address of the Reallife Contract Route
    address public rlRouteContract;
    RarelifeContractRoute internal rlRoute;

    constructor(address rlRouteAddress) {
        _owner = msg.sender;
        require(rlRouteAddress != address(0), "RarelifeConfigurable: cannot set contract as zero address");
        rlRouteContract = rlRouteAddress;
        rlRoute = RarelifeContractRoute(rlRouteAddress);
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IRarelife rl = rlRoute.rl();
        return (rl.getApproved(_actor) == msg.sender || rl.ownerOf(_actor) == msg.sender) || rl.isApprovedForAll(rl.ownerOf(_actor), msg.sender);
    }
}


// File contracts/RarelifeAttributes.sol

// 
pragma solidity ^0.8.4;


contract RarelifeAttributes is IRarelifeAttributes, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint constant LABEL_CHR = 0; // charm CHR
    uint constant LABEL_INT = 1; // intelligence INT
    uint constant LABEL_STR = 2; // strength STR
    uint constant LABEL_MNY = 3; // money MNY

    uint constant LABEL_HPY = 4; // happy SPR
    uint constant LABEL_HLH = 5; // health LIF
    uint constant LABEL_AGE = 6; // age AGE

    string[] private ability_labels = [
        "Charm",
        "Intelligence",
        "Strength",
        "Money",
        "Happy",
        "Health",
        "Age"
    ];

    mapping(uint => RarelifeStructs.SAbilityScore) public _ability_scores;
    mapping(uint => bool) public override character_points_initiated;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeAttributes: not approved or owner");
        _;
    }

    modifier onlyPointsInitiated(uint _actor) {
        require(character_points_initiated[_actor], "RarelifeAttributes: points have not been initiated yet");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
    }

    function calculate_point_buy(uint _chr, uint _int, uint _str, uint _mny) public pure returns (uint) {
        return _chr + _int + _str + _mny;
    }

    /* *****************
     * Private Functions
     * *****************
     */

    function _attribute_modify(uint32 _attr, int32 _modifier) internal pure returns (uint32) {
        if(_modifier > 0)
            _attr += uint32(_modifier); 
        else {
            if(_attr < uint32(-_modifier))
                _attr = 0;
            else
                _attr -= uint32(-_modifier); 
        }
        return _attr;
    }

    /* ****************
     * External Functions
     * ****************
     */

    function point_character(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {        
        IRarelifeTalents talents = rlRoute.talents();
        require(talents.actor_talents_initiated(_actor), "RarelifeAttributes: talents have not initiated");
        require(!character_points_initiated[_actor], "RarelifeAttributes: already init points");

        IRarelifeRandom rand = rlRoute.random();
        uint max_point_buy = talents.actor_attribute_point_buy(_actor);
        uint _str = 0;
        if(max_point_buy > 0)
            _str = rand.dn(_actor, max_point_buy);
        uint _chr = 0;
        if((max_point_buy-_str) > 0)
            _chr = rand.dn(_actor+1, max_point_buy-_str);
        uint _int = 0;
        if((max_point_buy-_str-_chr) > 0)
            _int = rand.dn(_actor+2, max_point_buy-_str-_chr);
        uint _mny = max_point_buy-_str-_chr-_int;

        character_points_initiated[_actor] = true;
        _ability_scores[_actor] = RarelifeStructs.SAbilityScore(uint32(_chr), uint32(_int), uint32(_str), uint32(_mny), 100, 100);

        emit Created(msg.sender, _actor, uint32(_chr), uint32(_int), uint32(_str), uint32(_mny), 100, 100);
    }

    function set_attributes(uint _actor, RarelifeStructs.SAbilityScore memory _attr) external override
        onlyPointsInitiated(_actor)
    {
        IRarelifeTimeline timeline = rlRoute.timeline();
        require(_isActorApprovedOrOwner(timeline.ACTOR_ADMIN()), "RarelifeAttributes: not approved or owner of timeline");

        _ability_scores[_actor] = _attr;

        emit Updated(msg.sender, _actor, _attr._chr, _attr._int, _attr._str, _attr._mny, _attr._spr, _attr._lif);
    }

    /* **************
     * View Functions
     * **************
     */

    function ability_scores(uint _actor) external view override returns (RarelifeStructs.SAbilityScore memory) {
        return _ability_scores[_actor];
    }

    function apply_modified(uint _actor, RarelifeStructs.SAbilityModifiers memory attr_modifier) external view override returns (RarelifeStructs.SAbilityScore memory, bool) {
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib = _ability_scores[_actor];
        if(attr_modifier._chr != 0) {
            attrib._chr = _attribute_modify(attrib._chr, attr_modifier._chr);
            attributesModified = true;
        }
        if(attr_modifier._int != 0) {
            attrib._int = _attribute_modify(attrib._int, attr_modifier._int);
            attributesModified = true;
        }
        if(attr_modifier._str != 0) {
            attrib._str = _attribute_modify(attrib._str, attr_modifier._str);
            attributesModified = true;
        }
        if(attr_modifier._mny != 0) {
            attrib._mny = _attribute_modify(attrib._mny, attr_modifier._mny);
            attributesModified = true;
        }
        if(attr_modifier._spr != 0) {
            attrib._spr = _attribute_modify(attrib._spr, attr_modifier._spr);
            attributesModified = true;
        }
        if(attr_modifier._lif != 0) {
            attrib._lif = _attribute_modify(attrib._lif, attr_modifier._lif);
            attributesModified = true;
        }

        return (attrib, attributesModified);
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        string[7] memory parts;
        //start svg
        RarelifeStructs.SAbilityScore memory _attr = _ability_scores[_actor];
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">', ability_labels[LABEL_CHR], "=", Strings.toString(_attr._chr), '</text>'));
        parts[2] = string(abi.encodePacked('<text x="10" y="40" class="base">', ability_labels[LABEL_INT], "=", Strings.toString(_attr._int), '</text>'));
        parts[3] = string(abi.encodePacked('<text x="10" y="60" class="base">', ability_labels[LABEL_STR], "=", Strings.toString(_attr._str), '</text>'));
        parts[4] = string(abi.encodePacked('<text x="10" y="80" class="base">', ability_labels[LABEL_MNY], "=", Strings.toString(_attr._mny), '</text>'));
        parts[5] = string(abi.encodePacked('<text x="10" y="100" class="base">', ability_labels[LABEL_HPY], "=", Strings.toString(_attr._spr), '</text>'));
        parts[6] = string(abi.encodePacked('<text x="10" y="120" class="base">', ability_labels[LABEL_HLH], "=", Strings.toString(_attr._lif), '</text>'));
        parts[0] = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        //end svg
        parts[1] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), ' attributes"'));
        parts[1] = ', "description": "This is not a game."';
        parts[2] = string(abi.encodePacked(', "data": {', '"CHR": ', Strings.toString(_attr._chr)));
        parts[3] = string(abi.encodePacked(', "INT": ', Strings.toString(_attr._int)));
        parts[4] = string(abi.encodePacked(', "STR": ', Strings.toString(_attr._str)));
        parts[5] = string(abi.encodePacked(', "MNY": ', Strings.toString(_attr._mny)));
        parts[6] = string(abi.encodePacked(', "SPR": ', Strings.toString(_attr._spr)));
        parts[0] = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        parts[1] = string(abi.encodePacked(', "LIF": ', Strings.toString(_attr._lif), '}'));
        //end json with svg
        parts[2] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}