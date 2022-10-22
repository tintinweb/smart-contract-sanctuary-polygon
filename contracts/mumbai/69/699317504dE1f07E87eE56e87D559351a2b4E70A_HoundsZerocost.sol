//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IHound.sol';
import '../../payments/params/MicroPayment.sol';
import '../params/Constructor.sol';


contract HoundsZerocost is Ownable {

    Constructor.Struct public control;

    constructor(Constructor.Struct memory input) {
        control = input;
    }

    function setGlobalParameters(Constructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
    }

    function getBreedCosts(uint256 hound) external view returns(
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory
    ) {
        Hound.Struct memory houndStruct = IHound(control.boilerplate.hounds).hound(hound);

        return (

            // Breed cost fee
            MicroPayment.Struct(
                control.fees.breedCostCurrency,
                control.fees.breedCost
            ),

            // Breed fee for alpha dune
            MicroPayment.Struct(
                control.fees.breedFeeCurrency,
                control.fees.breedFee
            ),

            // Hound breeding fee ( in case of external breeding )
            MicroPayment.Struct(
                houndStruct.breeding.breedingFeeCurrency,
                houndStruct.breeding.breedingFee
            )

        );

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Hound.sol';


interface IHound {

    function hound(uint256 theId) external view returns(Hound.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library MicroPayment {
    
    struct Struct {
        address currency;
        uint256 amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Boilerplate.sol';
import './Fees.sol';
import './Hound.sol';

library Constructor {
    struct Struct {
        string name;
        string symbol;
        Hound.Struct defaultHound;
        address[] allowedCallers;
        ConstructorBoilerplate.Struct boilerplate;
        ConstructorFees.Struct fees;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Specie.sol';


library Hound {

    struct Profile {
        string name;
        string token_uri;
        uint256 runningOn;
        bool custom;
    }

    struct Breeding {
        address breedingFeeCurrency;
        address breedingCooldownCurrency;
        uint256 lastBreed;
        uint256 breedingCooldown;
        uint256 breedingFee;
        uint256 breedingCooldownTimeUnit;
        uint256 refillBreedingCooldownCost;
        bool availableToBreed;
    }

    struct Stamina {
        address staminaRefillCurrency;
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint32 staminaValue;
        uint32 staminaPerTimeUnit;
        uint32 staminaCap;
    }

    struct Identity {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint32[54] geneticSequence;
        string extensionTraits;
        Specie.Enum specie;
    }

    struct Struct {
        Stamina stamina;
        Breeding breeding;
        Identity identity;
        Profile profile;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Specie {

    enum Enum {
        FREE_HOUND,
        NORMAL,
        CHAD,
        RACER,
        COMMUNITY,
        SPEC_OPS,
        PRIME,
        THIRT_PARTY
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ConstructorBoilerplate {
    struct Struct {

        // Contract modules 
        address restricted;
        address minter;
        address houndsModifier;
        address zerocost;
        address hounds;

        // External dependencies
        address payments;
        address shop;
        address races;
        address genetics;

        // Payout checkpoint
        address alphadune;
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ConstructorFees {
    struct Struct {
        address currency;
        address breedCostCurrency;
        address breedFeeCurrency;
        uint256 breedCost;
        uint256 breedFee;
    }
}