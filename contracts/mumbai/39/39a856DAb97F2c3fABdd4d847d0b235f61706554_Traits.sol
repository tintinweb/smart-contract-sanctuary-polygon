// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StructLib.sol";

/**  
    * @title ForeverPudgyPenguin soulbound traits contract
    * @author PudgyPenguins
    * @notice Ownable contract to store all the traits for the ForeverPudgyPenguin.sol contract
    * @dev The owner of this contract uses the uploadTraitType & uploadTraitVariations functions to save the traits to the blockchain. 
    * The compileAttributes method is called in the main ForeverPudgyPenguin.sol via interface
    * @dev We use Trait Types to define traits like: Type, Hat, Backround
    * And Trait Variations to define sub-traits like Type:{Big Pudgy, Lil Pudgy}
*/
contract Traits is Ownable {

    error MismatchedInput();

    // storage of trait type index to its name
    string[] internal traitTypes;

    // storage of trait variation index to its name
    mapping(uint8 => mapping(uint8 => StructLib.Trait)) public traitVariations;

    /**
        * @notice Uploades the names associated with each trait type
        * @param _traitTypeIds the id of the trait type
        * @param _namesOfTraitTypes the name of the trait type
        * @dev this deletes the old data and assign new ones
        * @dev we should use bytes instead of string to save gas
    */
    function uploadTraitTypes(uint8[] calldata _traitTypeIds, string[] calldata _namesOfTraitTypes) external onlyOwner {
        if (_traitTypeIds.length != _namesOfTraitTypes.length) revert MismatchedInput();
        delete traitTypes;
        for (uint i; i < _namesOfTraitTypes.length;) {
            traitTypes.push(_namesOfTraitTypes[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
        * @notice Uploades the names & allowed types associated with each trait variation
        * @param _traitType the trait type to upload the traits variations for (see traitTypes for a mapping)
        * @param _traitVariationIds the id of each trait variation
        * @param _traitVariations the StructLib.Trait struct containing names & allowed types for each trait variation
        * @dev we should use bytes instead of string to save gas
    */
    function uploadTraitVariations(uint8 _traitType, uint8[] calldata _traitVariationIds, StructLib.Trait[] calldata _traitVariations) external onlyOwner {
        if (_traitVariationIds.length != _traitVariations.length) revert MismatchedInput();
        for (uint i; i < _traitVariations.length;) {
            traitVariations[_traitType][_traitVariationIds[i]] = _traitVariations[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
         * @notice Generates an array composed of all the individual traits and values
         * @param _tokenTraits the struct of the token traits to compose the metadata for
         * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint8[] calldata _tokenTraits) external view returns (string memory) {
        string memory traits;

        //generates attribute for every trade but the last one
        for (uint256 i; i < _tokenTraits.length-1; ) {
            traits = string(abi.encodePacked(
                traits,
                attributeForTypeAndValue(traitTypes[i], traitVariations[uint8(i)][_tokenTraits[i]].name),','
            ));

            unchecked {
                ++i;
            }
        }

        // generates attributes for the last trait
        traits = string(abi.encodePacked(
            traits,
            attributeForTypeAndValue(traitTypes[_tokenTraits.length-1], traitVariations[uint8(_tokenTraits.length-1)][_tokenTraits[_tokenTraits.length-1]].name),''
        ));

        return string(abi.encodePacked(
            '[',
                traits,
            ']'
        ));
    }

    /**
         * @notice Generates an attribute for the attributes array in the ERC721A metadata standard
         * @param _traitType the trait type to reference as the metadata key
         * @param _value the token's trait associated with the key
         * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
                _traitType,
                   '","value":"',
                _value,
            '"}'
        ));
    }

    /**
        * @notice Returns the name associated with each trait type
        * @param _traitId the id of trait type
    */
    function getTraitTypesByUint(uint8 _traitId) external view returns (string memory) {
        return traitTypes[_traitId];
    }

    /**
        * @notice Returns the name associated with each trait variation
        * @param _traitType the trait type (see traitTypes for a mapping)
        * @param _traitId the id of trait variation
    */
    function getTraitVariationsByUint(uint8 _traitType, uint8 _traitId) external view returns (StructLib.Trait memory) {
        return traitVariations[_traitType][_traitId];
    }

    /**
        * @notice Returns the data in trait types array
    */
    function getTraitTypesArrayData() external view returns(string[] memory) {
        return traitTypes;
    }
      
    /**
        * @notice Returns length of trait types array
    */
    function getTraitTypesArrayLength() external view returns (uint) {
            return traitTypes.length;
    }

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

pragma solidity ^0.8.4;

 library StructLib {
    // struct to store trait variations
    struct Trait {
        string name;
        uint8[] allowedTypes;
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