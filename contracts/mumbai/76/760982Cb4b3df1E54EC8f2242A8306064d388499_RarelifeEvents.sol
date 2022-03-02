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


// File contracts/RarelifeEvents.sol

// 
pragma solidity ^0.8.4;


contract RarelifeEvents is IRarelifeEvents, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint public constant ACTOR_DESIGNER = 0; //God authority

    mapping(uint => address) public override event_processors;
    
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeEvents: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
    }

    /* *****************
     * Private Functions
     * *****************
     */

    /* ****************
     * External Functions
     * ****************
     */

    function set_event_processor(uint _id, address _address) external override
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        event_processors[_id] = _address;        
    }

    /* **************
     * View Functions
     * **************
     */

    function event_info(uint _id, uint _actor) external view override returns (string memory) {
        string memory info;
        if(event_processors[_id] != address(0))
            info = IRarelifeEventProcessor(event_processors[_id]).event_info(_actor);
        return info;
    }

    function event_attribute_modifiers(uint _id, uint _actor) external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        RarelifeStructs.SAbilityModifiers memory attr;
        if(event_processors[_id] != address(0))
            attr = IRarelifeEventProcessor(event_processors[_id]).event_attribute_modifiers(_actor);
        return attr;
    }

    function can_occurred(uint _actor, uint _id, uint _age) external view override returns (bool) {
        if(event_processors[_id] == address(0))
            return true;
        return IRarelifeEventProcessor(event_processors[_id]).check_occurrence(_actor, _age);
    }

    function check_branch(uint _actor, uint _id, uint _age) external view override returns (uint) {
        if(event_processors[_id] == address(0))
            return 0;
        return IRarelifeEventProcessor(event_processors[_id]).check_branch(_actor, _age); 
    }

}