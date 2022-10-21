///SPDX-License-Identifier:MIT
/**
    @title CharacterMinter
    @author Eman Garciano
    @notice: This contract serves as the router/minter for the Character NFT. It communicates with the VRF contract,
    performs the necessary calculations to determine the character's properties and stats and ultimately calls the mint 
    function of the NFT contract with the calculated results as arguments. Only this contract can call the NFT's mint function
    and only one router at a time can be set in the NFT contract as well.
    Originally created for CHAINLINK HACKATHON FALL 2022
*/
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../utils/BreakdownUint256.sol";
import "../libraries/StructLibrary.sol";

interface _RandomizationContract {
    function requestRandomWords(address user, bool experimental) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns(bool fulfilled, uint256[] memory randomWords);
}

interface _Characters {
    function _mintCharacter(address user, character_properties memory character_props, string memory _character_name) external;
}

contract CharacterMinter is Ownable, Pausable{
    ///The randomization contract for generating random numbers for mint
    _RandomizationContract randomizer;
    address private vrfContract;

    ///The core: Characters NFT contract deployment.
    _Characters charactersNft;

    ///The beneficiary of the msg.value being sent to the contract for every mint request.
    address vrf_refunder;

    ///The msg.value required to mint to prevent spam and deplete VRF funds
    ///Currently unset (0) for judging purposes as stated in the hackathon rules.
    uint256 mint_fee;

    ///Map out a user's address to its character request (if any) {request_id, character_class}. If none, the request_id == 0.
    mapping (address => character_request) public request;
    
    event CharacterRequested(address indexed user, character_request request);
    constructor(address charactersNftAddress){
        charactersNft = _Characters(charactersNftAddress);
        vrf_refunder = msg.sender;
    }

    ///@notice This function requests n random number/s from the VRF contract to be consumed with the mint.
    function requestCharacter(uint32 _character_class, string memory _character_name) public payable whenNotPaused{
        ///We can only allow one request per address at a time. A request shall be completed (minted the equipment) to be 
        ///able request another one.
        character_request memory _request = request[msg.sender];
        require(_request.request_id == 0, "cMNTR: There is a request pending mint.");

        ///Characters can only be a viking, woodcutter, troll, mechanic, amphibian, graverobber
        require(_character_class < 6, "cMNTR: Incorrect number for a character class.");
        
        ///The MATIC being received is not payment for the NFT but rather to simply replenish the VRF subscribtion's funds 
        ///and also serves as an effective anti-spam measure as well.
        require(msg.value >= mint_fee, "cMNTR: Incorrect amount for character minting. Send exactly 0.01 MATIC per item requested.");
        
        ///EXTCALL to VRF contract. Set the caller's current character_request to the returned request_id by the VRF contract.
        ///The bool argument here notifies the vrf contract that the request being sent is NOT experimental.
        request[msg.sender] = character_request({
            request_id: randomizer.requestRandomWords(msg.sender, false),
            character_class: _character_class,
            _name: _character_name,
            time_requested: block.timestamp
        });
        
        emit CharacterRequested(msg.sender, request[msg.sender]);
    }

    /**
        @notice This function is flagged as EXPERIMENTAL. This invokes a request to the VRF of random numbers which are when
        fulfilled, the VRF (automatically) mints the NFT within the same transaction as the fulfillment.
        This function requests n random number/s from the VRF contract to be consumed with the mint.
    */
    function requestCharacterExperimental(uint32 _character_class, string memory _character_name) public payable whenNotPaused{
        ///We can only allow one request per address at a time. A request shall be completed (minted the equipment) to be able request another one.
        character_request memory _request = request[msg.sender];
        require(_request.request_id == 0, "cMNTR: There is a request pending mint.");

        ///Characters can only be a viking, woodcutter, troll, mechanic, amphibian, graverobber
        require(_character_class < 6, "cMNTR: Incorrect number for a character class.");
        
        ///The MATIC being received is not payment for the NFT but rather to simply replenish the VRF subscribtion's funds 
        ///and also serves as an effective anti-spam measure as well.
        require(msg.value >= mint_fee, "cMNTR: Incorrect amount for character minting. Send exactly 0.01 MATIC per item requested.");
        
        ///@notice EXTCALL to VRF contract. Set the caller's current character_request to the returned request_id by the VRF contract.
        ///The bool argument here notifies the vrf contract that the request being sent is experimental.
        request[msg.sender] = character_request({
            request_id: randomizer.requestRandomWords(msg.sender, true),
            character_class: _character_class,
            _name: _character_name,
            time_requested: block.timestamp
        });
        
        emit CharacterRequested(msg.sender, request[msg.sender]);
    }

    ///@notice This function will reset the senders request. In case requests dont get fulfilled by the VRF within an hour.
    function cancelRequestExperimental() public {
        character_request memory _request = request[msg.sender];
        require(_request.request_id > 0, "cMNTR: Cannot cancel non-existing requests.");
        require((block.timestamp - _request.time_requested) > 3600, "cMNTR: Cannot cancel requests that havent lapsed 1 hour from time requested.");

        (bool fulfilled,) = randomizer.getRequestStatus(_request.request_id);
        require(!fulfilled, "cMNTR: Cannot cancel requests that have already been fulfilled.");

        request[msg.sender] = character_request({
            request_id: 0,
            character_class: 0,
            _name: "",
            time_requested: block.timestamp
        });
    }

    ///Once the random numbers requested has been fulfilled in the VRF contract, this function shall be called by the user
    ///to complete the mint process.
    function mintCharacter() public{
        character_request memory _request = request[msg.sender];

        ///Check if there is a pending/fulfilled request previously made by the caller using requestEquipment().
        require(_request.request_id > 0, "cMNTRS: No request to mint.");

        ///Fetch the request status from the VRF contract
        (bool fulfilled, uint256[] memory randomNumberRequested) = randomizer.getRequestStatus(_request.request_id);

        ///Verify if the random number request has been indeed fulfilled, revert if not.
        require(fulfilled, "cMNTRS: Request is not yet fulfilled or invalid request id.");

        ///Compute for the character props and mint the character NFT
        mint(msg.sender, randomNumberRequested[0], _request.character_class, _request._name);
        
        ///Reset the sender's request property values to 0
        request[msg.sender] = character_request({
            request_id: 0,
            character_class: 0,
            _name: "",
            time_requested: block.timestamp
        });
    }

    ///@notice This function is flagged as EXPERIMENTAL. There is a risk for a loss of material tokens if the call to this
    ///function by the VRF reverts.
    ///Once the random numbers requested has been fulfilled in the VRF contract, this function is called by the VRF contract
    ///to complete the mint process.
    function mintCharacterExperimental(address user, uint256[] memory randomNumberRequested) public onlyVRF{
        character_request memory _request = request[user];
        ///@notice Removing the immediate following external SLOAD since the VRF already knows the randomNumberRequested, 
        ///we simply pass it from the VRF's external call to this function
            // (/** bool fulfilled */, uint256[] memory randomNumberRequested) = randomizer.getRequestStatus(_request.request_id);

        ///@notice We are removing the immediate following requirements since we have shifted the minting responsibility to the VRF.
        ///When the fulfillRandomWords() is executed, there is no more need to check if the request has been fulfilled.
            ///Check if there is a pending/fulfilled request previously made by the caller using requestEquipment().
            // require(_request.request_id > 0, "cMNTRS: No request to mint.");

            ///Verify if the random number request has been indeed fulfilled, revert if not.
            // require(fulfilled, "cMNTRS: Request is not yet fulfilled or invalid request id.");

        ///Compute for the character props and mint the character NFT
        mint(user, randomNumberRequested[0], _request.character_class, _request._name);

        ///Reset the sender's request property values to 0
        request[user] = character_request({
            request_id: 0,
            character_class: 0,
            _name: "",
            time_requested: block.timestamp
        });
    }

    ///@notice This includes external call to the Character NFT Contract to actually mint the tokens.
    function mint(address user, uint256 randomNumberRequested, uint32 character_class, string memory _name) internal {
        (character_properties memory character_props) = getResult(randomNumberRequested, character_class);
        charactersNft._mintCharacter(user, character_props, _name);
    }

    function getResult(uint256 randomNumber, uint32 character_class) internal pure returns (character_properties memory character_props){
        ///To save on LINK tokens for our VRF contract, we are breaking a single random word into 8 uint32s.
        ///The reason for this is we will need a lot(6) of random numbers for a single equipment mint.
        ///It is given that the chainlink VRF generates verifiable, truly random numbers that it is safe to assume that breaking this
        ///truly random number poses no exploitable risk as far as the mint is concerned.
        ///However, there is a theoretical risk that the VRF generates a number with an extremely low number so that the first few uint32s would
        ///have their value at 0. In that case, it can be argued that it simply is not a blessing from the RNG Gods for the user.
        ///Still, our workaround if such thing occurs anyway is to start using the last numbers in the uint32s array which probably contains
        ///values greater than 0.
        uint32[] memory randomNumbers = BreakdownUint256.break256BitsIntegerIntoBytesArrayOf32Bits(randomNumber);

        ///Compute for the character's properties
        uint32 _element = getCharacterElement(randomNumbers[0]);
        (uint32 _str, uint32 _vit, uint32 _dex) = getCharacterAttributes(randomNumbers[1], randomNumbers[2], randomNumbers[3]);
        uint32 _talent = getCharacterTalent(randomNumbers[4]);
        uint32 _mood = getCharacterMood(randomNumbers[5]);

        character_props = character_properties({
            character_class: character_class,
            element: _element,
            str: _str,
            vit: _vit,
            dex: _dex,
            talent: _talent,
            mood: _mood,
            exp: 0
        });
    }

    ///For this design, elements can only have values 0-3
    function getCharacterElement(uint32 number) internal pure returns (uint32 character_element){
        character_element = number % 4;
    }

    ///The initial attribute points a character will have is 1000. This will be allocated in the following manner: 
    ///     First, allocate equally to each attribute 150 points each for a total of 450 points.
    ///     Second, consuming the 3 random numbers, we calculate for how the remaining 550 points will be distributed to each attribute.
    function getCharacterAttributes(uint32 number1, uint32 number2, uint32 number3) internal pure returns (uint32 _str, uint32 _int, uint32 _agi){
        uint32 str_points = number1 % 1000;
        uint32 int_points = number2 % 1000;
        uint32 agi_points = number3 % 1000;
        uint32 total_points = str_points + int_points + agi_points;
        _str = ((str_points * 550) / total_points) + 150;
        _int = ((int_points * 550) / total_points) + 150;
        _agi = ((agi_points * 550) / total_points) + 150;
    }

    ///Characters have can have values 0-2
    function getCharacterTalent(uint32 number) internal pure returns (uint32 character_talent){
        character_talent = number % 3;
    }

    ///For fun purposes, we set the character's mood initially and then subsequently in some select actions.
    function getCharacterMood(uint32 number) internal pure returns (uint32 character_mood){
        character_mood = number % 12;
    }

    ///@notice Admin Functions
    function setRandomizationContract(address _vrfContract) public onlyOwner {
        vrfContract = _vrfContract;
        randomizer = _RandomizationContract(_vrfContract);
    }

    function setMintFee(uint256 amount) public onlyOwner {
        mint_fee = amount * 1 gwei;
    }

    modifier onlyVRF(){
        require(msg.sender == vrfContract, "cMNTR: Can only be called by the VRF Contract for equipment crafting.");
        _;
    }

    function withdraw() public onlyOwner{
        (bool succeed, ) = vrf_refunder.call{value: address(this).balance}("");
        require(succeed, "Failed to withdraw matics.");
    }
}

//SPDX-License-Identifier: MIT
///@author https://ethereum.stackexchange.com/users/102976/jeremy-then
///@notice This is a modified code snippet from his stack overflow answer here: https://ethereum.stackexchange.com/a/133983

pragma solidity ^0.8.7;

library BreakdownUint256 {
    function break256BitsIntegerIntoBytesArrayOf8Bits(uint256 n) internal pure returns(uint8[] memory) {

        uint8[] memory _8BitNumbers = new uint8[](32);

        uint256 mask = 0x00000000000000000000000000000000000000000000000000000000000000ff;
        uint256 shiftBy = 0;

        for(int256 i = 31; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 8;
            v >>= shiftBy;
            _8BitNumbers[uint(i)] = uint8(v);
            shiftBy += 8;
        }
        return _8BitNumbers;
    }

    function break256BitsIntegerIntoBytesArrayOf16Bits(uint256 n) internal pure returns(uint16[] memory) {

        uint16[] memory _16BitNumbers = new uint16[](16);

        uint256 mask = 0x000000000000000000000000000000000000000000000000000000000000ffff;
        uint256 shiftBy = 0;

        for(int256 i = 15; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 16;
            v >>= shiftBy;
            _16BitNumbers[uint(i)] = uint16(v);
            shiftBy += 16;
        }
        return _16BitNumbers;
    }

    function break256BitsIntegerIntoBytesArrayOf32Bits(uint256 n) internal pure returns(uint32[] memory) {

        uint32[] memory _32BitNumbers = new uint32[](8);

        uint256 mask = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
        uint256 shiftBy = 0;

        for(int256 i = 7; i >= 0; i--) { 
            uint256 v = n & mask;
            mask <<= 32;
            v >>= shiftBy;
            _32BitNumbers[uint(i)] = uint32(v);
            shiftBy += 32;
        }
        return _32BitNumbers;
    }
}

//SPDX-License-Identifier: MIT
/**
    @title Struct Library
    @author Eman Garciano
    @notice: Reference for structs across contracts. 
    Originally created for CHAINLINK HACKATHON FALL 2022
*/

pragma solidity =0.8.17;

/*
    Character Classes Reference:
    1. Viking
    2. Woodcutter
    3. Troll
    4. Mechanic
    5. Amphibian
    6. Graverobber
*/

struct character_request { //SSTORED
    uint256 request_id;
    uint32 character_class;
    string _name;
    uint256 time_requested;
}

struct character_properties { //SSTORED
    uint32 character_class;
    uint32 element;
    uint32 str;
    uint32 vit;
    uint32 dex;
    uint32 talent;
    uint32 mood;
    uint32 exp;
}

struct character_stats { //SLOADED ONLY (Computed using character_properties)
    uint256 atk;
    uint256 def;
    uint256 eva;
    uint256 hp;
    uint256 pen;
    uint256 crit;
    uint256 atk_min;
    uint256 atk_max;
}

struct character_equipments {
    uint64 headgear;
    uint64 armor;
    uint64 weapon;
    uint64 accessory;
}

struct character_image_and_name {
    string name;
    string image;
}

struct attack_event {
    uint256 attack_index;
    uint256 challenger_hp;
    uint256 defender_hp;
    uint256 evaded;
    uint256 critical_hit;
    uint256 penetrated;
    uint256 damage_to_challenger;
    uint256 damage_to_defender;  
}

struct equipment_request { //SSTORED
    uint256 request_id;
    uint64 equipment_type;
    uint32 number_of_items;
    uint256 time_requested;
}

struct equipment_details {
    bytes name;
    bytes image;
    bytes type_tag;
    bytes rarity_tag;
    bytes dominant_stat_tag;
    bytes extremity_tag;
}

struct equipment_properties { //SSTORED
    uint64 equipment_type; //0-3
    uint64 rarity;
    uint64 dominant_stat;
    uint64 extremity;
}

struct equipment_stats {
    uint32 atk;
    uint32 def;
    uint32 eva;
    uint32 hp;
    uint32 pen;
    uint32 crit;
    uint32 luck; //for crafting and loot
    uint32 energy_regen; //energy refund after actions
}

struct item_recipe {
    uint256 main_material;
    uint256 indirect_material;
    uint256 catalyst;
    uint256 main_material_amount;
    uint256 indirect_material_amount;
    uint256 catalyst_amount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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