// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './params/Index.sol';


contract Races is Params {
    
    constructor(RacesConstructor.Struct memory input) Params(input) {}

    function uploadRace(
        uint256 theId, 
        uint256 queueId,
        Race.Struct memory race
    ) external {
        (bool success, ) = control.restricted.delegatecall(msg.data);
        require(success);
    }

    function raceStart(
        uint256 queueId,
        Queue.Struct memory queue
    ) external {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success);
    }

    function handleRaceLoot(
        Payment.Struct memory payment
    ) public payable {
        (bool success, ) = control.methods.delegatecall(msg.data);
        require(success);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Race.sol';
import './Constructor.sol';
import '../../arenas/interfaces/IHandleArenaUsage.sol';
import '../../arenas/params/Arena.sol';
import '../../payments/params/Payment.sol';
import '../interfaces/IHandleRaceLoot.sol';
import '../../hounds/interfaces/IUpdateHoundRunning.sol';
import '../../hounds/interfaces/IUpdateHoundStamina.sol';
import '../../queues/params/Queue.sol';
import '../../payments/interfaces/IPay.sol';
import '../../queues/interfaces/IStaminaCostOf.sol';


contract Params is Ownable {
    
    event NewRace(
        uint256 indexed id, 
        uint256 indexed queueId, 
        Race.Struct race
    );
    event NewFinishedRace(
        uint256 indexed id, 
        uint256 indexed queueId, 
        Race.Struct race
    );
    event UploadRace(
        uint256 indexed id, 
        uint256 indexed queueId, 
        Race.Struct race
    );

    uint256 public id = 1;
    RacesConstructor.Struct public control;
    mapping(uint256 => Race.Struct) public races;
    mapping(address => bool) public allowed;

    constructor(RacesConstructor.Struct memory input) {
        control = input;
        for ( uint256 i = 0 ; i < input.allowedCallers.length ; ++i ) {
            allowed[input.allowedCallers[i]] = !allowed[input.allowedCallers[i]];
        }
    }

    function setGlobalParameters(RacesConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
        for ( uint256 i = 0 ; i < globalParameters.allowedCallers.length ; ++i ) {
            allowed[globalParameters.allowedCallers[i]] = !allowed[globalParameters.allowedCallers[i]];
        }
    }

    function race(uint256 theId) external view returns(Race.Struct memory) {
        return races[theId];
    }

    function participantsOf(uint256 theId) external view returns(uint256[] memory) {
        return races[theId].core.participants;
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
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import '../../queues/params/Core.sol';

library Race {
    
    struct Struct {

        Core.Struct core;

        uint256 queueId;

        bytes seed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library RacesConstructor {
    struct Struct {
        address arenas;
        address hounds;
        address methods;
        address payments;
        address restricted;
        address queues;
        address races;
        address[] allowedCallers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IHandleArenaUsage { 

    function handleArenaUsage(uint256 theId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;

        address currency;
        uint256 fee;
        
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Payment {

    enum PaymentTypes {
        ERC721,
        ERC1155,
        ERC20,
        DEFAULT
    }
    
    struct Struct {
        address[] from;
        address[] to;
        address[] currency;
        uint256[][] ids;
        uint256[][] amounts;
        PaymentTypes[] paymentType;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';


interface IHandleRaceLoot {

    function handleRaceLoot(
        Payment.Struct memory payment
    ) external payable;

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IUpdateHoundRunning {

    function updateHoundRunning(uint256 theId, uint256 runningOn) external returns(uint256 ranOn);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IUpdateHoundStamina {

    function updateHoundStamina(uint256 theId, uint32 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import './Core.sol';
import '../../hounds/params/Specie.sol';

library Queue {
    
    struct Struct {

        Core.Struct core;

        uint256 startDate;

        uint256 endDate;

        uint256 lastCompletion;

        uint32 totalParticipants;

        uint32 cooldown;

        uint32 staminaCost;

        Specie.Enum[] speciesAllowed;

        bool closed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Payment.sol';

interface IPay {

	function pay(
		address from,
        address to,
        address currency,
        uint256[] memory ids, // for batch transfers
        uint256[] memory amounts, // for batch transfers
        Payment.PaymentTypes paymentType
	) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IStaminaCostOf { 

    function staminaCostOf(uint256 theId) external view returns(uint32);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';

library Core {
    
    struct Struct {

        string name;

        address feeCurrency;

        address entryFeeCurrency;

        uint256[] participants;

        uint256[] enqueueDates;

        uint256 arena;

        uint256 entryFee;

        uint256 fee;

        Payment.Struct payments;

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