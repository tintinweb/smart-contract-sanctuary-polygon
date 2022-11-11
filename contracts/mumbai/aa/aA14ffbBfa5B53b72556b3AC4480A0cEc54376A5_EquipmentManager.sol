//SPDX-License-Identifier: MIT
/**
    @title Equipment Manager
    @author Eman @SgtChiliPapi
    @notice: Contract to map equipment items to characters and vice-versa.
    Originally created for CHAINLINK HACKATHON FALL 2022
*/
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/structs/CharacterStructs.sol";
import "../libraries/structs/EquipmentStructs.sol";

interface ICharacters {
    function isOwner(address _owner, uint256 _character) external view returns (bool);
    function character(uint256 _character_id) external view returns (character_properties memory);
}

interface IEquipment {
    function isOwner(address _owner, uint256 _equipment) external view returns (bool);
    function equipment(uint256 _equipment_id) external view returns (equipment_properties memory);
}

contract EquipmentManager {

    ///Instantiate contract links for ownership checks and properties references.
    ICharacters character_contract;
    IEquipment equipment_contract;
    address private character_contract_address;
    address private equipment_contract_address;

    mapping(uint256 => uint256) public equippedTo;//POV Equipment Item: Specify the character currently the item is equipped to.
    mapping (uint256 => character_equipments) public equippedWith; //POV Character: Specify the items currently equipped to the character.

    event ItemEquipped(uint256 indexed character_id,  uint256 indexed equipment_id, uint256 equipment_type);
    event ItemUnequipped(uint256 indexed character_id, uint256 indexed equipment_id, uint256 equipment_type);

    constructor(address character_address, address equipment_address){
        character_contract_address = character_address;
        equipment_contract_address = equipment_address;
        character_contract = ICharacters(character_address);
        equipment_contract = IEquipment(equipment_address);
    }

    ///@notice This function equips an equipment to a character.
    function equip(uint256 _character_id, uint256 _equipment_id) public{
        //Ownership checks for character and equipment.
        require(character_contract.isOwner(msg.sender, _character_id), "EQPD: Cannot equip to a character not owned.");
        require(equipment_contract.isOwner(msg.sender, _equipment_id), "EQPD: Cannot equip with equipment not owned.");

        ///Fetch equipment properties from their respective contracts.
        equipment_properties memory equipment =  equipment_contract.equipment(_equipment_id);

        ///Check if the items is equippable
        require(equipment.equipment_type < 4, "EQPD: Item not equippable.");

        //Reference the equipment's _type prop to update the appropriate equipment slot (helm, armor, weapon, accessory) of the character.
        if(equipment.equipment_type == 0){equipWeapon(_character_id, _equipment_id);}
        if(equipment.equipment_type == 1){equipHelm(_character_id, _equipment_id);}
        if(equipment.equipment_type == 2){equipArmor(_character_id, _equipment_id);}
        if(equipment.equipment_type == 3){equipAccessory(_character_id, _equipment_id);}
    }

    ///@notice For multiple equipments to be equipped to a character in one transaction, simply loop through the equipments specified.
    function equipMany(uint256 _character_id, uint256[] memory _equipment_ids) public{
        require(_equipment_ids.length < 5, "EQPD: Cannot equip more than 4 items."); //Safety check to save users gas.
        for(uint256 i = 0; i < _equipment_ids.length; i++){
            equip(_character_id, _equipment_ids[i]);
        }
    }

    ///@notice This function effectively unequips the 'helm to be equipped' from the character it is currently equipped to.
    ///Also, the current helm (if any) of the 'character to be equipped to' will be unequipped as well. 
    function equipHelm(uint256 _character_id, uint256 _equipment_id) internal {
        //1st Unequip from the character it is currently equipped to
        uint256 currentlyEquippedTo = equippedTo[_equipment_id]; //Check for the current character
        if(currentlyEquippedTo != 0) { unequipHelm(currentlyEquippedTo);}

        //2nd Unequip the character's current equipment
        unequipHelm(_character_id);
        
        //Lastly, equip the item to the character
        equippedTo[_equipment_id] = _character_id;
        equippedWith[_character_id].headgear = uint64(_equipment_id);
        emit ItemEquipped(_character_id, _equipment_id, 1); //1 => headgear
    }

    ///@notice Same effect with equipHelm but for Armors.
    function equipArmor(uint256 _character_id, uint256 _equipment_id) internal{
        //1st Unequip from the character it is currently equipped to
        uint256 currentlyEquippedTo = equippedTo[_equipment_id]; //Check for the current character
        if(currentlyEquippedTo != 0) { unequipArmor(currentlyEquippedTo);}

        //2nd Unequip the character's current equipment
        unequipArmor(_character_id);
        
        //Lastly, equip the item to the character
        equippedTo[_equipment_id] = _character_id;
        equippedWith[_character_id].armor = uint64(_equipment_id);
        emit ItemEquipped(_character_id, _equipment_id, 2); //2 => armor
    }

    ///@notice Same effect with equipHelm but for Weapons.
    function equipWeapon(uint256 _character_id, uint256 _equipment_id) internal{
        //1st Unequip from the character it is currently equipped to
        uint256 currentlyEquippedTo = equippedTo[_equipment_id]; //Check for the current character
        if(currentlyEquippedTo != 0) { unequipWeapon(currentlyEquippedTo);}

        //2nd Unequip the character's current equipment
        unequipWeapon(_character_id);
        
        //Lastly, equip the item to the character
        equippedTo[_equipment_id] = _character_id;
        equippedWith[_character_id].weapon = uint64(_equipment_id);
        emit ItemEquipped(_character_id, _equipment_id, 0); //0 => weapon
    }

    ///@notice Same effect with equipHelm but for Accessories.
    function equipAccessory(uint256 _character_id, uint256 _equipment_id) internal{
        //1st Unequip from the character it is currently equipped to
        uint256 currentlyEquippedTo = equippedTo[_equipment_id]; //Check for the current character
        if(currentlyEquippedTo != 0) { unequipAccessory(currentlyEquippedTo);}

        //2nd Unequip the character's current equipment
        unequipAccessory(_character_id);
        
        //Lastly, equip the item to the character
        equippedTo[_equipment_id] = _character_id;
        equippedWith[_character_id].accessory = uint64(_equipment_id);
        emit ItemEquipped(_character_id, _equipment_id, 3); //3 => headgear
    }

    ///@notice The owner of the character can unequip items by type (headgear, armor, weapon, accessory)
    function unequipType(uint256 _character_id, uint256 equipment_type) public{
        require(character_contract.isOwner(msg.sender, _character_id), "EQPD: Cannot unequip from character not owned.");
        if(equipment_type == 0){unequipWeapon(_character_id);}
        if(equipment_type == 1){unequipHelm(_character_id);}
        if(equipment_type == 2){unequipArmor(_character_id);}
        if(equipment_type == 3){unequipAccessory(_character_id);}
    }

    ///@notice The owner can unequip everything from his character
    function unequipAll(uint256 _character_id) public{
        require(character_contract.isOwner(msg.sender, _character_id), "EQPD: Cannot unequip from character not owned.");
        unequipHelm(_character_id);
        unequipArmor(_character_id);
        unequipWeapon(_character_id);
        unequipAccessory(_character_id);
    }

    ///@notice This function is triggered everytime an equipment item is transferred
    function unequipItemFromTransfer(uint256 _equipment_id) external onlyEquipmentContract returns (bool success){
        if(equippedTo[_equipment_id] != 0){
            equipment_properties memory equipment =  equipment_contract.equipment(_equipment_id);
            if(equipment.equipment_type == 0){unequipWeapon(equippedTo[_equipment_id]);}
            if(equipment.equipment_type == 1){unequipHelm(equippedTo[_equipment_id]);}
            if(equipment.equipment_type == 2){unequipArmor(equippedTo[_equipment_id]);}
            if(equipment.equipment_type == 3){unequipAccessory(equippedTo[_equipment_id]);}
        }
        success = true;
    }

    ///@notice This is triggered everytime a character is transferred
    function unequipAllFromTransfer(uint256 _character_id) external onlyCharacterContract returns (bool success){
        unequipHelm(_character_id);
        unequipArmor(_character_id);
        unequipWeapon(_character_id);
        unequipAccessory(_character_id);
        success = true;
    }

    function unequipHelm(uint256 _character_id) internal {
        uint256 _equipment_id = equippedWith[_character_id].headgear;
        equippedTo[_equipment_id] = 0;
        equippedWith[_character_id].headgear = 0;
        emit ItemUnequipped(_character_id, _equipment_id, 1);
        
    }

    function unequipArmor(uint256 _character_id) internal {
        uint256 _equipment_id = equippedWith[_character_id].armor;
        equippedTo[_equipment_id] = 0;
        equippedWith[_character_id].armor = 0;
        emit ItemUnequipped(_character_id, _equipment_id, 2);
    }

    function unequipWeapon(uint256 _character_id) internal {
        uint256 _equipment_id = equippedWith[_character_id].weapon;
        equippedTo[_equipment_id] = 0;
        equippedWith[_character_id].weapon = 0;
        emit ItemUnequipped(_character_id, _equipment_id, 0);
    }

    function unequipAccessory(uint256 _character_id) internal {
        uint256 _equipment_id = equippedWith[_character_id].accessory;
        equippedTo[_equipment_id] = 0;
        equippedWith[_character_id].accessory = 0;
        emit ItemUnequipped(_character_id, _equipment_id, 3);
    }

    modifier onlyCharacterContract() {
        require(msg.sender == character_contract_address);
        _;
    }

    modifier onlyEquipmentContract(){
        require(msg.sender == equipment_contract_address);
        _;
    }

}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

struct character_uri_details {
    string name;
    string image;
    string mood;
    string bonus;
    string bonus_value;
    string talent_value;
}

struct character_request { //SSTORED
    uint256 request_id;
    uint32 character_class;
    string _name;
    uint256 time_requested;
}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

struct item_recipe {
    uint256 main_material;
    uint256 indirect_material;
    uint256 catalyst;
    uint256 main_material_amount;
    uint256 indirect_material_amount;
    uint256 catalyst_amount;
}

struct equipment_request { //SSTORED
    uint256 request_id;
    uint64 equipment_type;
    uint32 number_of_items;
    uint256 time_requested;
    bool free;
}

struct character_equipments {
    uint64 headgear;
    uint64 armor;
    uint64 weapon;
    uint64 accessory;
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