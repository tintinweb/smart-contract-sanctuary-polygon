// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IPrimarySale.sol";

/**
 *  @title   Primary Sale
 *  @notice  Thirdweb's `PrimarySale` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about
 *           primary sales, if desired.
 */

abstract contract PrimarySale is IPrimarySale {
    /// @dev The address that receives all primary sales value.
    address private recipient;

    /// @dev Returns primary sale recipient address.
    function primarySaleRecipient() public view override returns (address) {
        return recipient;
    }

    /**
     *  @notice         Updates primary sale recipient.
     *  @dev            Caller should be authorized to set primary sales info.
     *                  See {_canSetPrimarySaleRecipient}.
     *                  Emits {PrimarySaleRecipientUpdated Event}; See {_setupPrimarySaleRecipient}.
     *
     *  @param _saleRecipient   Address to be set as new recipient of primary sales.
     */
    function setPrimarySaleRecipient(address _saleRecipient) external override {
        if (!_canSetPrimarySaleRecipient()) {
            revert("Not authorized");
        }
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function _setupPrimarySaleRecipient(address _saleRecipient) internal {
        recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Primary` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about
 *  primary sales, if desired.
 */

interface IPrimarySale {
    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";

contract SFTM_alpha_v2 is Ownable, PrimarySale {

    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev The tokenId of the next tournament
    uint256 public tournamentCount;


    /*//////////////////////////////////////////////////////////////
                        Structures
    //////////////////////////////////////////////////////////////*/
    
    struct Tournament {
        string slug;
        uint256 entryFee;
        
        address[] allowList;
        mapping(address => bool) userJoined;
    }


    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Tournament) public tournaments;


    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _primarySaleRecipient
    ) {
        _setupOwner(msg.sender);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }


    /*//////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    event TournamentCreated(string message, string slug);
    event TournamentJoined(uint256 tournamentId, address participant);


    /*//////////////////////////////////////////////////////////////
                        Internal (overridable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Owner can set new owner of the contract
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Owner can set primary sale recipient
    function _canSetPrimarySaleRecipient() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }


    /*//////////////////////////////////////////////////////////////
                        Create A Tournament
    //////////////////////////////////////////////////////////////*/

    function createTournament(
        string memory _slug,
        uint256 _entryFee
    ) external returns (uint256) {

        Tournament storage tournament = tournaments[tournamentCount];

        tournament.slug = _slug;
        tournament.entryFee = _entryFee;
        tournament.allowList = new address[](0);

        tournamentCount++;

        emit TournamentCreated("A new tournament has been created.", _slug);
        return tournamentCount - 1;
    }


    /*//////////////////////////////////////////////////////////////
                        Join A Tournament
    //////////////////////////////////////////////////////////////*/

    function joinTournament(uint256 _tournamentId) external payable {

        Tournament storage tournament = tournaments[_tournamentId];

        require(tournament.userJoined[msg.sender] == false, "Player already joined!");

        if (tournament.userJoined[msg.sender] == false) {

            uint256 amount = tournament.entryFee;

            require(msg.value == amount, "Invalid entry fee");

            tournament.allowList.push(payable(msg.sender));

            tournament.userJoined[msg.sender] = true;

            (bool success,) = payable(primarySaleRecipient()).call{value: amount}("");

            if(success) {  }

        }

    }


    /*//////////////////////////////////////////////////////////////
                        Tests
    //////////////////////////////////////////////////////////////*/

    /// @dev Test payable to sale recipient
    function testPay() external payable {

        uint256 amount = 0.001 ether;
        require(msg.value == amount, "Invalid entry fee");

        (bool success,) = payable(primarySaleRecipient()).call{value: amount}("");
            
        if(success) { }
    }





}