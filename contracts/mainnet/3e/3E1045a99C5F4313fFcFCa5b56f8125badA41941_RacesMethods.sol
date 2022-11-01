// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract RacesMethods is Params {

    constructor(RacesConstructor.Struct memory input) Params(input) {}

    function raceStart(
        uint256 queueId,
        Queue.Struct memory queue
    ) 
        external 
        whitelisted 
    {

        emit NewRace(id, queueId, Race.Struct(
            Core.Struct(
                queue.core.name,
                queue.core.feeCurrency,
                queue.core.entryFeeCurrency,
                queue.core.participants,
                queue.core.enqueueDates,
                queue.core.arena,
                queue.core.entryFee,
                queue.core.fee,
                queue.core.payments
            ),
            queueId,
            0,
            '0x00'
        ));

        ++id;

    }

    function handleRaceLoot(
        Payment.Struct memory payment
    ) 
        public 
        payable 
        whitelisted 
    {

        for ( uint256 i = 0 ; i < payment.from.length ; ++i ) {
            IPay(control.payments).pay(
                payment.from[i],
                payment.to[i],
                payment.currency[i],
                payment.ids[i],
                payment.amounts[i],
                payment.paymentType[i]
            );
        }

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
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
import '../../whitelist/Index.sol';
import '../../queues/interfaces/IStaminaCostOf.sol';


contract Params is Whitelist {
    
    event NewRace(
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

    constructor(
        RacesConstructor.Struct memory input
    ) 
        Whitelist(input.operators, input.targets) 
    {
        control = input;
    }

    function setGlobalParameters(
        RacesConstructor.Struct memory globalParameters
    ) 
        external 
        onlyOwner 
    {
        control = globalParameters;
        updateWhitelist(globalParameters.operators, globalParameters.targets);
    }

    function race(uint256 theId) external view returns(Race.Struct memory) {
        return races[theId];
    }

    function participantsOf(uint256 theId) external view returns(uint256[] memory) {
        return races[theId].core.participants;
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

        uint256 randomness;

        bytes seed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library RacesConstructor {
    struct Struct {
        address[] operators;
        address arenas;
        address hounds;
        address methods;
        address payments;
        address restricted;
        address queues;
        address races;
        bytes4[][] targets;
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


library Queue {
    
    struct Struct {

        Core.Struct core;

        uint256[] speciesAllowed;

        uint256 startDate;

        uint256 endDate;

        uint256 lastCompletion;

        uint32 totalParticipants;

        uint32 cooldown;

        uint32 staminaCost;

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
import '@openzeppelin/contracts/access/Ownable.sol';


contract Whitelist is Ownable {

    mapping(address => bytes4[]) public whitelists;

    constructor(address[] memory operators, bytes4[][] memory targets) {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                whitelists[operators[i]].push(targets[i][j]);
            }
        }
    }

    function updateWhitelist(address[] memory operators, bytes4[][] memory targets) internal {
        require(operators.length == targets.length);
        for (uint256 i = 0; i < operators.length ; ++i ) {
            for (uint256 j = 0; j < targets[i].length; ++j) {
                if ( j >= whitelists[operators[i]].length ) {
                    whitelists[operators[i]].push(targets[i][j]);
                } else {
                    whitelists[operators[i]][j] = targets[i][j];
                }
            }
        }
    }

    modifier whitelisted() {
        bool found = false;
        for (uint256 i = 0; i < whitelists[msg.sender].length; ++i) {
            if ( whitelists[msg.sender][i] == msg.sig ) {
                found = true;
            }
        }
        require(found);
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IStaminaCostOf { 

    function staminaCostOf(uint256 theId) external view returns(uint32);

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