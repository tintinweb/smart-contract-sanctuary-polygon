// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EventImplementation Contract
 * @author GET Protocol
 * @notice Contract responsible for NFT mints and transfers
 * @dev One EventImplementation contract is deployed per real world event.
 *
 * @dev This contract Extends the ERC721 specification
 */

// import "./abstract/EventERC721Upgradeable.sol";
// import "./abstract/AuthModifiers.sol";
import "../../../contracts/interfaces/IEventImplementation.sol";
import "../../../contracts/interfaces/IRouterRegistry.sol";
import "../../../contracts/interfaces/IBaseRouter.sol";
import "../../../contracts//interfaces/IRegistry.sol";

contract EventImplementationMock is IEventImplementation {
    // using StringsUpgradeable for uint256;

    IRegistry private registry;
    IRouterRegistry public routerRegistry;
    FuelerType public fuelerType;
    EventData public eventData;
    EventFinancing public eventFinancing;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    // solhint-disable-next-line func-name-mixedcase
    // function __EventImplementationV2_init(
    //     string calldata _name,
    //     string calldata _symbol,
    //     address _registry
    // ) external initializer {
    //     __ERC721_init(_name, _symbol);
    //     __AuthModifiers_init(_registry);
    //     __EventImplementation_init_unchained(_registry);
    // }

    // solhint-disable-next-line func-name-mixedcase
    // function __EventImplementation_init_unchained(address _registry) internal initializer {
    //     registry = IRegistry(_registry);

    //     routerRegistry = IRouterRegistry(registry.routerRegistry());
    // }

    /**
     * @notice Performs all ticket interractions via an integrator's relayer
     * @dev Performs ticket actions based on the array of action counts
     *
     * @dev Each value in the actionCounts array corresponds to the number of a specific ticket action to be performed
     *
     * @dev Can only be called by an integrator's relayer
     * @param _ticketActions array of TicketAction structs for which a ticket action is performed
     * @param _actionCounts integer array corresponding to specific ticket action to be performed on the ticketActions
     * @param _balanceUpdates array of BalanceUpdates struct used to update an owner's balance upon ticket mint
     */
    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates
    ) external {
        uint256 _start = 0;

        for (uint256 _actionType = 0; _actionType < _actionCounts.length; ++_actionType) {
            uint256 _end = _start + _actionCounts[_actionType];

            if (_actionType == 0 && _actionCounts[_actionType] != 0) {
                require(!eventFinancing.primaryBlocked, "EventFinancing: Inventory Restricted");
                _primarySale(_ticketActions[_start:_end], _balanceUpdates);
                _start = _end;
                continue;
            }
            if (_actionType == 1 && _actionCounts[_actionType] != 0) {
                _secondarySale(_ticketActions[_start:_end]);
                _start = _end;
                continue;
            }
            if (_actionType == 2 && _actionCounts[_actionType] != 0) {
                require(!eventFinancing.scanBlocked, "EventFinancing: Inventory Restricted");
                _scan(_ticketActions[_start:_end]);
                _start = _end;
                continue;
            }
            if (_actionType == 3 && _actionCounts[_actionType] != 0) {
                _checkIn(_ticketActions[_start:_end]);
                _start = _end;
                continue;
            }
            if (_actionType == 4 && _actionCounts[_actionType] != 0) {
                _invalidate(_ticketActions[_start:_end]);
                _start = _end;
                continue;
            }
            if (_actionType == 5 && _actionCounts[_actionType] != 0) {
                _claim(_ticketActions[_start:_end]);
                _start = _end;
                continue;
            }
        }
    }

    /**
     * @notice Returns a boolean from a bit-field
     * @param _packedBools integer used as bit field
     * @param _boolNumber bit position
     */
    function _getBoolean(uint8 _packedBools, uint8 _boolNumber) internal pure returns (bool) {
        uint8 _flag = (_packedBools >> _boolNumber) & uint8(1);
        return (_flag == 1 ? true : false);
    }

    // chatgpt says this funciton is more efficient
    // function _getBoolean(uint8 _packedBools, uint8 _boolNumber) internal pure returns (bool) {
    //     return ((_packedBools & (uint8(1) << _boolNumber)) != 0);
    // }

    /**
     * @notice Sets a bit in a bit-field
     * @param _packedBools integer used as bit field
     * @param _boolNumber bit position
     * @param _value boolean value to set in bit position
     */
    function _setBoolean(uint8 _packedBools, uint8 _boolNumber, bool _value) internal pure returns (uint8 _flags) {
        if (_value) return _packedBools | (uint8(1) << _boolNumber);
        else return _packedBools & ~(uint8(1) << _boolNumber);
    }

    // todo note chat gpt says this version is slightly more efficient? Probably should test iout?
    // function _setBoolean(
    //     bytes1 _packedBools,
    //     uint256 _boolNumber,
    //     bool _value
    // ) internal pure returns (bytes1 _flags) {
    //     if (_value) return _packedBools | (bytes1(1) << _boolNumber);
    //     else return _packedBools & ~(bytes1(1) << _boolNumber);
    // }

    /**
     * @notice Returns a ticket's scanned status
     * @dev A ticket can be scanned multiple times as long as it's not invalidated
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status scan status
     */
    function isScanned(uint256 _tokenId) public view returns (bool _status) {
        // return _isScanned(_tokenId);
    }

    function _isScanned(uint256 _tokenId) internal view returns (bool _status) {
        // return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.SCANNED));
    }

    /**
     * @notice Returns a ticket's checked-in status
     * @dev A ticket can only be checked in once
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status check-in status
     */
    function isCheckedIn(uint256 _tokenId) public view returns (bool _status) {
        return _isCheckedIn(_tokenId);
    }

    function _isCheckedIn(uint256 _tokenId) internal view returns (bool _status) {
        // return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.CHECKED_IN));
    }

    /**
     * @notice Returns a ticket's invalidation status
     * @dev After invalidation further ticket interraction becomes impossible
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status invalidation status
     */
    function isInvalidated(uint256 _tokenId) public view returns (bool _status) {
        return _isInvalidated(_tokenId);
    }

    function _isInvalidated(uint256 _tokenId) internal view returns (bool _status) {
        // return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.INVALIDATED));
    }

    /**
     * @notice Returns a ticket's status of unlocked
     * @dev Unlocking happens after check-in, at which point the ticket is available for transfer
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status unlock status
     */
    function isUnlocked(uint256 _tokenId) public view returns (bool _status) {
        bool isPastEndTime = (eventData.endTime + 24 hours) <= block.timestamp;
        bool isZeroEndTime = eventData.endTime == 0;
        // return
        //     _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.UNLOCKED)) ||
        //     (isPastEndTime && !isZeroEndTime);
    }

    /**
     * @notice Returns status of whether ticket is custodially managed
     * @dev Custodial tickets are held within the contract for later claiming or transfer
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status custodial status
     */
    function isCustodial(uint256 _tokenId) public view returns (bool _status) {
        // return ownerOf(_tokenId) == address(this);
    }

    /**
     * @notice Sets `isScanned` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status scan status
     */
    function _setScannedFlag(uint256 _tokenId, bool _status) internal {
        // tokenData[_tokenId].booleanFlags = _setBoolean(
        //     tokenData[_tokenId].booleanFlags,
        //     uint8(TicketFlags.SCANNED),
        //     _status
        // );
    }

    /**
     * @notice Sets `isCheckedIn` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status check-in status
     */
    function _setCheckedInFlag(uint256 _tokenId, bool _status) internal {
        // tokenData[_tokenId].booleanFlags = _setBoolean(
        //     tokenData[_tokenId].booleanFlags,
        //     uint8(TicketFlags.CHECKED_IN),
        //     _status
        // );
    }

    /**
     * @notice Sets `isInvalidated` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status invalidation status
     */
    function _setInvalidatedFlag(uint256 _tokenId, bool _status) internal {
        // tokenData[_tokenId].booleanFlags = _setBoolean(
        //     tokenData[_tokenId].booleanFlags,
        //     uint8(TicketFlags.INVALIDATED),
        //     _status
        // );
    }

    /**
     * @notice Sets `isUnlocked` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status unlocked status
     */
    function _setUnlockedFlag(uint256 _tokenId, bool _status) internal {
        // tokenData[_tokenId].booleanFlags = _setBoolean(
        //     tokenData[_tokenId].booleanFlags,
        //     uint8(TicketFlags.UNLOCKED),
        //     _status
        // );
    }

    // note this is a testing state variable
    bool private fuelWasRouted_;

    function returnWasFuelRouted() external view returns (bool) {
        return fuelWasRouted_;
    }

    /// @dev Ticket Lifecycle Methods
    /**
     * @notice Performs a primary ticket sale from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which a primary sale occurs
     * @param _balanceUpdates array of BalanceUpdates struct used to update an owner's balance
     */
    function _primarySale(TicketAction[] calldata _ticketActions, BalanceUpdates[] calldata _balanceUpdates) internal {
        // for (uint256 i = 0; i < _balanceUpdates.length; ++i) {
        //     unchecked {
        //         _addressData[_balanceUpdates[i].owner].balance += _balanceUpdates[i].quantity;
        //     }
        // }

        // for (uint256 i = 0; i < _ticketActions.length; ++i) {
        //     // _mint(_ticketActions[i]);
        // }

        // consider storing the router address in the events state/storage (not immutable) to save gas
        IBaseRouter _router = IBaseRouter(routerRegistry.returnEventToRouter(address(this)));

        // amount of GET used that will go towards the product/international
        uint256 _productFuel;
        // amount of GET used that will go towards the protocol/dao
        uint256 _fuelProtocol;

        if (fuelerType == FuelerType.DIGITAL_TWIN) {
            (, _fuelProtocol) = _router.routeFuelForPrimarySale(_ticketActions);
            fuelWasRouted_ = true;
        } else if (fuelerType == FuelerType.ON_CHAIN_TICKET) {
            (_productFuel, _fuelProtocol) = _router.routeFuelForPrimarySale(_ticketActions);
            fuelWasRouted_ = true;
        } else {
            revert("EventImplementation: Invalid fueler type");
        }

        emit PrimarySale(_ticketActions, _productFuel, _fuelProtocol);
    }

    /**
     * @notice Performs a secondary ticket sale from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which a secondary sale occurs
     */
    function _secondarySale(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            // require(!isInvalidated(_tokenId) && !isUnlocked(_tokenId), "EventImplementation: Error on resale");
            require(!isInvalidated(_tokenId), "EventImplementation: Error on resale");
            require(!isUnlocked(_tokenId), "EventImplementation: Error on resale");
            // _transfer(ownerOf(_tokenId), _ticketActions[i].to, _tokenId);
        }

        uint256 _productFuel;
        uint256 _fuelProtocol;
        if (fuelerType == FuelerType.ON_CHAIN_TICKET) {
            IBaseRouter _router = IBaseRouter(routerRegistry.returnEventToRouter(address(this)));
            (_productFuel, _fuelProtocol) = _router.routeFuelForSecondarySale(_ticketActions);
        } else {
            _productFuel = 0;
            _fuelProtocol = 0;
        }
        // note: it would be possible to also eit the USD value of the deducted fuel (denominated in the value of the fuel in the economics FIFO valuation)
        emit SecondarySale(_ticketActions, _productFuel, _fuelProtocol);
    }

    // /**
    //  * @notice Performs scans on tickets from ticketActions
    //  * @dev Internal method called by `batchActions`
    //  * @param _ticketActions array of TicketAction structs for which scans occur
    //  */
    // function _scan(TicketAction[] calldata _ticketActions) internal {
    //     for (uint256 i = 0; i < _ticketActions.length; ++i) {
    //         uint256 _tokenId = _ticketActions[i].tokenId;
    //         require(!isInvalidated(_tokenId), "EventImplementation: Error on ticket scan");
    //         _setScannedFlag(_tokenId, true);
    //     }

    //     emit Scanned(_ticketActions, 0, 0);
    // }

    /**
     * @notice Performs scans on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which scans occur
     */
    function _scan(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!_isInvalidated(_tokenId), "EventImplementation: Error on ticket scan");
            _setScannedFlag(_tokenId, true);
        }

        emit Scanned(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs check-ins on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which check-ins occur
     */
    function _checkIn(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            // require(!isInvalidated(_tokenId) && !isCheckedIn(_tokenId), "EventImplementation: Error on check-in");
            // single require is most gas efficient in gas usage
            require(!isInvalidated(_tokenId), "EventImplementation: Error on check-in");
            require(!isCheckedIn(_tokenId), "EventImplementation: Error on check-in");
            _setCheckedInFlag(_tokenId, true);
            _setUnlockedFlag(_tokenId, true);
        }

        emit CheckedIn(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs invalidations on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which invalidadtions occur
     */
    function _invalidate(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on ticket invalidation");
            _setInvalidatedFlag(_tokenId, true);
            // _burn(_tokenId);
        }

        emit Invalidated(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs claims on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for whihc claims occur
     */
    function _claim(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            // require(isCustodial(_tokenId) && !isInvalidated(_tokenId), "EventImplementation: Error on NFT claim");
            require(isCustodial(_tokenId), "EventImplementation: Error on NFT claim");
            require(!isInvalidated(_tokenId), "EventImplementation: Error on NFT claim");
            // _transfer(ownerOf(_tokenId), _ticketActions[i].to, _tokenId);
        }
        emit Claimed(_ticketActions, 0, 0);
    }

    /// @dev Event Lifecycle Methods
    /**
     * @notice Sets the event data for an EventImplementation contract
     * @dev can only be called by the EventFactory contract typically at contract creation
     * @param _eventData EventData struct
     */
    function setEventData(EventData calldata _eventData) external {
        eventData = _eventData;
        emit EventDataSet(_eventData);
    }

    /**
     * @notice Updates the event data for an EventImplementation contract
     * @dev can only be called by an integrator's relayer
     * @param _eventData EventData struct
     */
    function updateEventData(EventData calldata _eventData) external {
        eventData = _eventData;
        emit EventDataUpdated(_eventData);
    }

    /**
     * @notice Updates the EventFinancing struct
     * @dev can only be called by the EventFactory contract
     * @param _financing EventFinancing struct
     */
    function setFinancing(EventFinancing calldata _financing) external {
        eventFinancing = _financing;
        emit UpdateFinancing(_financing);
    }

    /**
     */
    function setFuelerType(bool _isWhitelabel) external {
        if (_isWhitelabel) {
            fuelerType = FuelerType.ON_CHAIN_TICKET;
        } else {
            fuelerType = FuelerType.DIGITAL_TWIN;
        }
    }

    /// @dev ERC-721 Overrides

    /**
     * @notice Returns the token URI
     * @dev The token URI is resolved from the _baseURI, event index and tokenId
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _tokenURI token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        // require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _uri = _baseURI();
        // return
        // bytes(_uri).length > 0
        // ? string(abi.encodePacked(_uri, uint256(eventData.index).toString(), "/", _tokenId.toString()))
        // : "";
    }

    /**
     * @notice Returns base URI
     * @dev The baseURI at any time is universal across all EventImplementation contracts
     * @return _baseURI token URI
     */
    function _baseURI() internal view virtual returns (string memory) {
        return registry.baseURI();
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
        // require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        // return super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual {
        // require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        // return super.safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual {
        // require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        // return super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @notice Returns contract owner
     * @dev Not a full Ownable implementation, used to return a static owner for marketplace config only
     * @return _owner owner address
     */
    function owner() public view virtual returns (address) {
        return address(0x3aFdff6fCDD01E7DA59c615D3958C5fEc0e889Fd);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IEventImplementation {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        UNLOCKED // 3
    }

    enum FuelerType {
        NONE,
        DIGITAL_TWIN,
        ON_CHAIN_TICKET
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    event PrimarySale(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event SecondarySale(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Scanned(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event CheckedIn(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Invalidated(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Claimed(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event EventDataSet(EventData eventData);

    event EventDataUpdated(EventData eventData);

    event UpdateFinancing(EventFinancing financing);

    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates
    ) external;

    function isScanned(uint256 _tokenId) external returns (bool _status);

    function isCheckedIn(uint256 _tokenId) external returns (bool _status);

    function isInvalidated(uint256 _tokenId) external returns (bool _status);

    function isUnlocked(uint256 _tokenId) external returns (bool _status);

    function isCustodial(uint256 _tokenId) external returns (bool _status);

    function setEventData(EventData memory _eventData) external;

    function updateEventData(EventData memory _eventData) external;

    function setFinancing(EventFinancing memory _financing) external;

    function owner() external view returns (address);

    function setFuelerType(bool _fuelerType) external;

    function returnWasFuelRouted() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IRouterRegistry.sol";

interface IRouterRegistry {
    struct RouterInfo {
        uint128 routerIndex;
        uint64 initializationBlockTime;
        uint64 expirationBlockTime;
        uint64 totalUsages;
        bool isValidRouter; // if the router is valid for usage
        // if true, only digital twin events can be routed to this router
        bool isDigitalTwinOnlyRouter;
    }

    function registerEventToRelayerDefault(
        address _eventAddress,
        address _relayerAddress
    ) external returns (address routerAddress_);

    function registerEventToRelayerException(
        address _eventAddress,
        address _relayerAddress,
        uint256 _routerIndex
    ) external returns (address routerAddress_);

    function returnEventToRouter(address _eventAddress) external view returns (address);

    event EventRegisteredToRelayer(address indexed _eventAddress, address indexed _relayerAddress);
    event DefaultRouterSet(uint256 integratorIndex, address routerAddress);
    event RegisterEventToRouterException(address indexed _eventAddress, address indexed _routerAddress);
    event RouterAddedToAllowedRouters(uint256 indexed integratorIndex_, address indexed routerAddress_);
    event RouterRemovedFromAllowedRouters(uint256 indexed integratorIndex_, address indexed routerAddress_);
    event RouterRegistered(address indexed routerAddress, IRouterRegistry.RouterInfo routerInfo);
    error NoRouterRegistered(address eventAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IEventImplementation.sol";

interface IBaseRouter {
    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);

    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IAuth.sol";
import "./IEventFactory.sol";
import "./IPriceOracle.sol";
import "./IRegistry.sol";
import "./IEconomicsFactory.sol";
import "./IRouterRegistry.sol";
import "./ITopUp.sol";
import "./IFuelDistributor.sol";

interface IRegistry {
    event UpdateAuth(address old, address updated);
    event UpdateEconomics(address old, address updated);
    event UpdateEventFactory(address old, address updated);
    event UpdatePriceOracle(address old, address updated);
    event UpdateFuelDistributor(address old, address updated);
    event UpdateTopUp(address old, address updated);
    event UpdateBaseURI(string old, string updated);
    event UpdateRouterRegistry(address old, address updated);
    event UpdateEconomicsFactory(address oldEconomicsFactory, address economicsFactory);
    event UpdateEventFactoryV2(address oldEventFactoryV2, address newEventFactoryV2);

    function auth() external view returns (IAuth);

    function eventFactory() external view returns (IEventFactory);

    function economics() external view returns (IEconomicsFactory);

    function economicsFactory() external view returns (IEconomicsFactory);

    function fuelDistributor() external view returns (IFuelDistributor);

    function routerRegistry() external view returns (IRouterRegistry);

    function priceOracle() external view returns (IPriceOracle);

    function topUp() external view returns (ITopUp);

    function baseURI() external view returns (string memory);

    function setAuth(address _auth) external;

    function setEventFactory(address _eventFactory) external;

    function setPriceOracle(address _priceOracle) external;

    function setFuelDistributor(address _fuelDistributor) external;

    function setTopUp(address _topUp) external;

    function setBaseURI(string memory _baseURI) external;

    function setRouterRegistry(address _routerRegistry) external;

    function setEconomicsFactory(address _economicsFactory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IAuth is IAccessControlUpgradeable {
    function addIntegratorAdminToIndex(address, uint256) external;

    function removeIntegratorAdmin(address) external;

    function hasProtocolDAORole(address) external view;

    function hasEconomicsConfigurationRole(address, uint256) external view;

    function hasEventFinancingConfigurationRole(address, uint256) external view;

    function hasIntegratorAdminRole(address) external view;

    function hasEventFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasFuelDistributorRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function grantEventRole(address) external;

    function hasRouterRegistryRole(address) external view;

    function hasFuelRouterRole(address) external view;

    function hasEconomicsFactoryRole(address _sender) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IEventImplementation.sol";

interface IEventFactory {
    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);

    event RouterInUse(address indexed eventAddress, address indexed routerAddress);

    function eventAddressByIndex(uint256 _eventIndex) external view returns (address);

    function eventCount() external view returns (uint256);

    // function createEvent(
    //     string memory _name,
    //     string memory _symbol,
    //     IEventImplementation.EventData memory _eventData,
    //     bool _digitalTwin,
    //     uint256 _routerIndex
    // ) external returns (address _eventAddress);

    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData
    ) external returns (address _eventAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IPriceOracle {
    event UpdatePrice(uint256 old, uint256 updated);

    function price() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint32);

    function setPrice(uint256 _price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEconomicsFactory {
    // Data structure containing all the different rates for a particular relayer.
    //   100% (1) 1_000_000,
    //   10% (0.1) = 100_000,
    //   1% (0.01) = 10_000,
    //   0.1% (0.001) = 1_000,
    //   0.01% (0.0001) = 100,
    //   0.001% (0,00001) = 10,
    //   0.0001% = (0.000001) = 1
    // All scaled by 1_000_000.
    //
    // USD values (e.g. minFee, maxFee) are scaled by 1_000 (tenth of a cent).
    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }

    // Largely unnecesary to define separately but helps avoid stack too deep errors within reserved fuel calculations.
    struct Rate {
        uint24 minFee;
        uint24 maxFee;
        uint24 rate;
    }

    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
        bool onCredit;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct SpentFuel {
        uint256 total;
        uint256 protocol;
        uint32 ticketCount;
    }

    event UpdateIntegratorOnCredit(uint32 integratorIndex, bool onCredit);

    event UpdateSalesTaxFuelDestination(address salesTaxFuelDestination);

    event UpdateFuelToken(address old, address updated);

    event EnableIntegratorBilling(uint32 integratorIndex);

    event UpdateDynamicRates(uint32 indexed integratorIndex_, DynamicRates dynamicRates_);

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        address economicsContract,
        uint256 indexed total,
        uint256 topUpPrice
        // uint256 indexed newAveragePrice
        // uint256 salesTax
    );

    event EconomicsContractDeployed(uint32 indexed integratorIndex, address indexed economicsContract);

    event UpdateProtocolRates(DynamicRates protocolRates_);

    event IntegratorActivated(uint32 indexed integratorIndex_);

    event ConfigurationStatusUpdated(uint32 indexed integratorIndex_, bool status_);

    event BillingStatusUpdated(uint32 indexed integratorIndex_, bool status_);
    event IntegratorConfigured(
        uint256 indexed integratorIndex,
        string name,
        address relayerAddress,
        DynamicRates dynamicRates
    );
    event IntegratorDisabled(uint32 indexed integratorIndex_);

    event RelayerRemoved(address indexed relayerAddress_, uint256 indexed integratorIndex_);

    event RelayerRegistered(address relayer, uint256 integratorIndex);

    event EconomicsCreated(address economicsAddress, uint256 integratorIndex);

    event RelayerAdded(address indexed relayerAddress_, uint256 indexed integratorIndex_);

    event DisableIntegratorBilling(uint32 integratorIndex);

    function relayerToIndex(address _relayerAddress) external returns (uint32 integratorIndex_);

    // function returnBillingType(address _relayerAddress) external view returns (bool whitelabelBilling_);

    function isIntegratorDigitalTwin(address _relayerAddress) external view returns (bool isDigitalTwin_);

    function fuelToken() external view returns (IERC20);

    function economicsContracts(uint256 _integratorIndex) external view returns (address);

    function returnDynamicRatesOfIntegrator(
        uint256 _integratorIndex
    ) external view returns (DynamicRates memory dynamicRates_);

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates
    ) external returns (address economicsAddress_);

    function setupIntegratorDT(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates
    ) external returns (address economicsAddress_);

    function topUpIntegrator(
        uint256 _integratorIndex,
        address _sender,
        uint256 _total,
        uint256 _price
    ) external returns (uint256);

    function isIntegratorConfigured(uint256 _integratorIndex) external view returns (bool isConfigured_);

    function isIntegratorEnabled(uint256 _integratorIndex) external view returns (bool isEnabled_);

    function returnIntegratorIndexOfConfiguredIntegrator(
        address _relayerAddress
    ) external view returns (uint256 integratorIndex_);

    function returnIntegratorEconomicsAddressOfConfiguredIntegrator(
        uint256 _integratorIndex
    ) external view returns (address economicsAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ITopUp {
    event ToppedUpCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpCustodial0x(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpNonCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price
    );
    event UpdateBaseToken(address old, address updated);
    event UpdateWeth(address old, address updated);
    event UpdateRouter(address old, address updated);
    event UpdateOracle(address old, address updated);

    function baseToken() external returns (IERC20Metadata);

    function weth() external returns (IERC20);

    function router() external returns (IUniswapV2Router02);

    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external;

    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external;

    function pause() external;

    function unpause() external;

    function setBaseToken(address _baseToken) external;

    function setWeth(address _weth) external;

    function setRouter(address _router) external;

    function setApprovals() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IFuelDistributor {
    // The destinations array exists to define the 'splits' of the revenue of the protocol. As a simple example, lets
    // say that the foundation takes 80% and the DAO takes 20%, then the percentages within this array *must* sum to
    // 1 million in any order. The DAO address would have a percentage value of 200k and the foundation 800k.
    //
    // The precision of the percentage variable matches that of the rates above:
    //   100% (1) 1_000_000,
    //   ...
    //   0.0001% = (0.000001) = 1
    struct Destination {
        address payable destination;
        uint24 percentage;
        string label;
    }

    event Distribute(uint256 amount, uint256 total, address destination);
    event UpdateDestinationsProtocol(Destination[] old, Destination[] updated);
    event UpdateDestinationsRemainder(Destination[] old, Destination[] updated);
    event UpdateDestinationsCredit(Destination[] old, Destination[] updated);

    function collect() external;

    function destinationsProtocol(uint256 _index) external returns (address payable, uint24, string memory);

    function destinationsRemainder(uint256 _index) external returns (address payable, uint24, string memory);

    function destinationsCredit(uint256 _index) external returns (address payable, uint24, string memory);

    function setDestinationsProtocol(Destination[] calldata _destinationsProtocol) external;

    function setDestinationsRemainder(Destination[] calldata _destinationsRemainder) external;

    function setDestinationsCredit(Destination[] calldata _destinationsCredit) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}