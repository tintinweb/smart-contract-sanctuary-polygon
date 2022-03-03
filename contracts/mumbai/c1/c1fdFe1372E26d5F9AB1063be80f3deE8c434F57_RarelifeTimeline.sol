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


// File contracts/RarelifeTimeline.sol

// 
pragma solidity ^0.8.4;


//import "hardhat/console.sol";

contract RarelifeTimeline is IRarelifeTimeline, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint public constant ACTOR_DESIGNER = 0; //god authority
    uint public override immutable ACTOR_ADMIN; //timeline administrator authority

    mapping(uint => uint) public override ages; //current ages
    mapping(uint => bool) public override character_born;
    mapping(uint => bool) public override character_birthday; //have atleast one birthday

    //uint constant ONE_AGE_VSECOND = 86400; //1 day in real means 1 age in rarelife
    uint constant ONE_AGE_VSECOND = 60; //for test net, 60 senconds in real means 1 age in rarelife
    mapping(uint => uint) public born_time_stamps;


    //map actor to age to event
    mapping(uint => mapping(uint => uint[])) private actor_events;
    //map actor to event to count
    mapping(uint => mapping(uint => uint)) private actor_events_history;
    //map age to event pool ids
    mapping(uint => uint[]) private event_ids; //age to id list
    mapping(uint => uint[]) private event_probs; //age to prob list

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeTimeline: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    /* *****************
     * Private Functions
     * *****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
        IRarelife rl = rlRoute.rl();
        ACTOR_ADMIN = rl.next_actor();
        rl.mint_actor();
    }

    function _expected_age(uint _actor) internal view returns (uint) {
        require(character_born[_actor], "have not born!");
        uint _dt = block.timestamp - born_time_stamps[_actor];
        return _dt / ONE_AGE_VSECOND;
    }

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

    function _process_talents(uint _actor, uint _age) internal
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeTalents talents = rlRoute.talents();
        IRarelifeAttributes attributes = rlRoute.attributes();

        uint[] memory tlts = talents.actor_talents(_actor);
        for(uint i=0; i<tlts.length; i++) {
            if(talents.can_occurred(_actor, tlts[i], _age)) {
                bool attributesModified = false;
                RarelifeStructs.SAbilityScore memory attrib;
                RarelifeStructs.SAbilityModifiers memory attr_modifier = talents.talent_attribute_modifiers(tlts[i]);
                (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
                if(attr_modifier._age != 0) {
                    ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
                    attributesModified = true;
                }
                if(attributesModified) {
                    //this will trigger attribute uptate event
                    attributes.set_attributes(_actor, attrib);
                }
            }
        }
    }

    function _run_event_processor(uint _actor, uint _age, address _processorAddress) private {
        //approve event processor the authority of timeline
        rlRoute.rl().approve(_processorAddress, ACTOR_ADMIN);
        IRarelifeEventProcessor(_processorAddress).process(_actor, _age); 
    }

    function _process_event(uint _actor, uint _age, uint eventId, uint _depth) private returns (uint branchEvtId) {

        IRarelifeEvents evts = rlRoute.evts();
        IRarelifeAttributes attributes = rlRoute.attributes();

        actor_events[_actor][_age].push(eventId);
        actor_events_history[_actor][eventId] += 1;

        RarelifeStructs.SAbilityModifiers memory attr_modifier = evts.event_attribute_modifiers(eventId, _actor);
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib;
        (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
        if(attr_modifier._age != 0) { //change age
            ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
            attributesModified = true;
        }

        if(attributesModified) {
            //this will trigger attribute uptate event
            attributes.set_attributes(_actor, attrib);
        }

        //process event if any processor
        address evtProcessorAddress = evts.event_processors(eventId);
        if(evtProcessorAddress != address(0))
            _run_event_processor(_actor, _age, evtProcessorAddress);

        if(_depth == 0)
            emit AgeEvent(_actor, _age, eventId);
        else
            emit BranchEvent(_actor, _age, eventId);

        //check branch
        return evts.check_branch(_actor, eventId, _age);
    }

    function _process_events(uint _actor, uint _age) internal 
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeEvents evts = rlRoute.evts();

        //filter events for occurrence
        uint[] memory events_filtered = new uint[](event_ids[_age].length);
        uint events_filtered_num = 0;
        for(uint i=0; i<event_ids[_age].length; i++) {
            if(evts.can_occurred(_actor, event_ids[_age][i], _age)) {
                events_filtered[events_filtered_num] = i;
                events_filtered_num++;
            }
        }

        uint pCt = 0;
        for(uint i=0; i<events_filtered_num; i++) {
            pCt += event_probs[_age][events_filtered[i]];
        }
        uint prob = 0;
        if(pCt > 0)
            prob = rlRoute.random().dn(_actor, pCt);
        
        pCt = 0;
        for(uint i=0; i<events_filtered_num; i++) {
            pCt += event_probs[_age][events_filtered[i]];
            if(pCt >= prob) {
                uint eventId = event_ids[_age][events_filtered[i]];
                uint branchEvtId = _process_event(_actor, _age, eventId, 0);

                //only support two level branchs
                if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                    branchEvtId = _process_event(_actor, _age, branchEvtId, 1);
                    if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                        branchEvtId = _process_event(_actor, _age, branchEvtId, 2);
                        require(branchEvtId == 0, "RarelifeTimeline: only support two level branchs");
                    }
                }

                break;
            }
        }
    }

    function _process(uint _actor, uint _age) internal
        onlyApprovedOrOwner(_actor)
    {
        require(character_born[_actor], "RarelifeTimeline: actor have not born!");
        //require(actor_events[_actor][_age] == 0, "RarelifeTimeline: actor already have event!");
        require(event_ids[_age].length > 0, "RarelifeTimeline: not exist any event in this age!");

        _process_talents(_actor, _age);
        _process_events(_actor, _age);
    }

    function _run_active_event_processor(uint _actor, uint /*_age*/, address _processorAddress, uint[] memory _uintParams) private {
        //approve event processor the authority of timeline
        rlRoute.rl().approve(_processorAddress, ACTOR_ADMIN);
        IRarelifeEventProcessor(_processorAddress).active_trigger(_actor, _uintParams);
    }

    function _process_active_event(uint _actor, uint _age, uint eventId, uint[] memory _uintParams, uint _depth) private returns (uint branchEvtId) {

        IRarelifeEvents evts = rlRoute.evts();
        IRarelifeAttributes attributes = rlRoute.attributes();

        actor_events[_actor][_age].push(eventId);
        actor_events_history[_actor][eventId] += 1;

        RarelifeStructs.SAbilityModifiers memory attr_modifier = evts.event_attribute_modifiers(eventId, _actor);
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib;
        (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
        if(attr_modifier._age != 0) { //change age
            ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
            attributesModified = true;
        }

        if(attributesModified) {
            //this will trigger attribute uptate event
            attributes.set_attributes(_actor, attrib);
        }

        //process active event if any processor
        address evtProcessorAddress = evts.event_processors(eventId);
        if(evtProcessorAddress != address(0))
            _run_active_event_processor(_actor, _age, evtProcessorAddress, _uintParams);

        if(_depth == 0)
            emit ActiveEvent(_actor, _age, eventId);
        else
            emit BranchEvent(_actor, _age, eventId);

        //check branch
        return evts.check_branch(_actor, eventId, _age);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function born_character(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {
        require(!character_born[_actor], "RarelifeTimeline: already born!");
        character_born[_actor] = true;
        born_time_stamps[_actor] = block.timestamp;

        emit Born(msg.sender, _actor);
    }

    function grow(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {
        require(character_born[_actor], "RarelifeTimeline: actor have not born");
        require(character_birthday[_actor] == false || ages[_actor] < _expected_age(_actor), "RarelifeTimeline: actor grow time have not come");
        require(rlRoute.attributes().ability_scores(_actor)._lif > 0, "RarelifeTimeline: actor dead!");

        if(character_birthday[_actor]) {
            //grow one year
            ages[_actor] += 1;
        }
        else {
            //need first birthday
            ages[_actor] = 0;
            character_birthday[_actor] = true;
        }

        //do new year age events
        _process(_actor, ages[_actor]);
    }

    function add_age_event(uint _age, uint _eventId, uint _eventProb) external 
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(_eventId > 0, "RarelifeTimeline: event id must not zero");
        require(event_ids[_age].length == event_probs[_age].length, "RarelifeTimeline: internal ids not match probs");
        event_ids[_age].push(_eventId);
        event_probs[_age].push(_eventProb);
    }

    function set_age_event_prob(uint _age, uint _eventId, uint _eventProb) external 
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(_eventId > 0, "RarelifeTimeline: event id must not zero");
        require(event_ids[_age].length == event_probs[_age].length, "RarelifeTimeline: internal ids not match probs");
        for(uint i=0; i<event_ids[_age].length; i++) {
            if(event_ids[_age][i] == _eventId) {
                event_probs[_age][i] = _eventProb;
                return;
            }
        }
        require(false, "RarelifeTimeline: can not find eventId");
    }

    function active_trigger(uint _eventId, uint _actor, uint[] memory _uintParams) external override
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeEvents evts = rlRoute.evts();

        address evtProcessorAddress = evts.event_processors(_eventId);
        require(evtProcessorAddress != address(0), "RarelifeTimeline: can not find event processor.");

        uint _age = ages[_actor];
        require(evts.can_occurred(_actor, _eventId, _age), "RarelifeTimeline: event check occurrence failed.");
        uint branchEvtId = _process_active_event(_actor, _age, _eventId, _uintParams, 0);

        //only support two level branchs
        if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
            branchEvtId = _process_active_event(_actor, _age, branchEvtId, _uintParams, 1);
            if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                branchEvtId = _process_active_event(_actor, _age, branchEvtId, _uintParams, 2);
                require(branchEvtId == 0, "RarelifeTimeline: only support two level branchs");
            }
        }
    }

    /* **************
     * View Functions
     * **************
     */

    function expected_age(uint _actor) external override view returns (uint) {
        return _expected_age(_actor);
    }

    function actor_event(uint _actor, uint _age) external override view returns (uint[] memory) {
        return actor_events[_actor][_age];
    }

    function actor_event_count(uint _actor, uint _eventId) external override view returns (uint) {
        return actor_events_history[_actor][_eventId];
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        IRarelifeEvents evts = rlRoute.evts();

        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Age: ', Strings.toString(ages[_actor]), '</text>'));
        parts[2] = '';
        string memory evtJson = '';
        for(uint i=0; i<actor_events[_actor][ages[_actor]].length; i++) {
            uint eventId = actor_events[_actor][ages[_actor]][i];
            uint y = 20*i;
            parts[2] = string(abi.encodePacked(parts[2],
                string(abi.encodePacked('<text x="10" y="', Strings.toString(40+y), '" class="base">', evts.event_info(eventId, _actor), '</text>'))));
            evtJson = string(abi.encodePacked(evtJson, Strings.toString(eventId), ','));
        }
        //end svg
        parts[3] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), '"'));
        parts[1] = ', "description": "This is not a game"';
        parts[2] = string(abi.encodePacked(', "data": {', '"age": ', Strings.toString(ages[_actor])));
        parts[3] = string(abi.encodePacked(', "events": [', evtJson, ']}'));
        //end json with svg
        parts[4] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURIByAge(uint256 _actor, uint _age) public view returns (string memory) {
        IRarelifeEvents evts = rlRoute.evts();

        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Age: ', Strings.toString(_age), '</text>'));
        parts[2] = '';
        string memory evtJson = '';
        for(uint i=0; i<actor_events[_actor][_age].length; i++) {
            uint eventId = actor_events[_actor][_age][i];
            uint y = 20*i;
            parts[2] = string(abi.encodePacked(parts[2],
                string(abi.encodePacked('<text x="10" y="', Strings.toString(40+y), '" class="base">', evts.event_info(eventId, _actor), '</text>'))));
            evtJson = string(abi.encodePacked(evtJson, Strings.toString(eventId), ','));
        }
        //end svg
        parts[3] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), '"'));
        parts[1] = ', "description": "This is not a game"';
        parts[2] = string(abi.encodePacked(', "data": {', '"age": ', Strings.toString(_age)));
        parts[3] = string(abi.encodePacked(', "events": [', evtJson, ']}'));
        //end json with svg
        parts[4] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}