//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './params/Index.sol';


contract Gamification is Params {

    constructor(
        GamificationConstructor.Struct memory input
    ) 
        Params(input) 
    {

    }

    function initializeHoundGamingStats(
        uint256 id, 
        uint32[54] memory genetics
    ) 
        external 
    {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success);
    }

    function setStamina(
        uint256 id, 
        HoundStamina.Struct memory stamina
    ) 
        external 
    {
        (bool success, ) = control.restricted.delegatecall(msg.data);
        require(success);
    }

    function setBreeding(
        uint256 id, 
        HoundBreeding.Struct memory breeding
    ) 
        external 
    {
        (bool success, ) = control.restricted.delegatecall(msg.data);
        require(success);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../firewall/interfaces/IsAllowed.sol';
import './Constructor.sol';
import './HoundBreeding.sol';
import './HoundStamina.sol';


contract Params {

    GamificationConstructor.Struct public control;
    mapping(uint256 => HoundStamina.Struct) public houndsStamina;
    mapping(uint256 => HoundBreeding.Struct) public houndsBreeding;

    constructor(
        GamificationConstructor.Struct memory input
    ) 
    {
        control = input;
    }

    function setGlobalParameters(
        GamificationConstructor.Struct memory globalParameters
    ) 
        external  
    {
        require(IsAllowed(control.firewall).isAllowed(msg.sender,msg.sig));
        control = globalParameters;
    }

    function getStamina(
        uint256 id
    ) 
        external 
        view 
        returns(HoundStamina.Struct memory) 
    {
        return houndsStamina[id];
    }

    function getBreeding(
        uint256 id
    ) 
        external 
        view 
        returns(HoundBreeding.Struct memory) 
    {
        return houndsBreeding[id];
    }

    function getStaminaBreeding(
        uint256 id
    ) 
        external 
        view 
        returns(HoundStamina.Struct memory, HoundBreeding.Struct memory) 
    {
        return (houndsStamina[id],houndsBreeding[id]);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IsAllowed {

    function isAllowed(
        address user, 
        bytes4 method
    ) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './HoundBreeding.sol';
import './HoundStamina.sol';


library GamificationConstructor {
    struct Struct {
        HoundBreeding.Struct defaultBreeding;
        HoundStamina.Struct defaultStamina;
        address firewall;
        address restricted;
        address methods;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundBreeding {

    struct Struct {
        address breedingFeeCurrency;
        address breedingCooldownCurrency;
        uint256 lastBreed;
        uint256 breedingCooldown;
        uint256 breedingFee;
        uint256 breedingCooldownTimeUnit;
        uint256 refillBreedingCooldownCost;
        bool availableToBreed;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundStamina {

    struct Struct {
        address staminaRefillCurrency;
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint32 staminaValue;
        uint32 staminaPerTimeUnit;
        uint32 staminaCap;
    }

}