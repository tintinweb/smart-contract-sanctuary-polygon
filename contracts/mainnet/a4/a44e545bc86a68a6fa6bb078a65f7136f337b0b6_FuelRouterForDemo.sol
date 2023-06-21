// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "forge-std/Test.sol";

import "./FuelRouterBaseDemo.sol";
import "../../../contracts/interfaces/IFuelRouterWhitelabelEvent.sol";
import "../../../contracts/interfaces/IFuelDistributor.sol";

// example router for a whitelabel event
contract FuelRouterForDemo is IFuelRouterWhitelabelEvent, FuelRouterBaseDemo {
    uint256 public whitelabelIntegratorId;
    uint256 public digitalTwinIntegratorId;
    address public dripCollectorInternational;

    constructor(
        address _registry,
        uint256 _baseRate,
        address _dripCollector,
        uint256 _whitelabelIntegratorId,
        uint256 _digitalTwinIntegratorId
    ) FuelRouterBaseDemo(_baseRate, _registry) {
        whitelabelIntegratorId = _whitelabelIntegratorId;
        digitalTwinIntegratorId = _digitalTwinIntegratorId;
        dripCollectorInternational = _dripCollector;

        IEconomicsFactory economicsFactory_ = IEconomicsFactory(registry.economicsFactory());

        // product fee (3%) from WL to International (for product)
        wlPrimarySaleRouteProduct_.fuelFrom = economicsFactory_.returnIntegratorEconomicsAddressOfConfiguredIntegrator(
            _whitelabelIntegratorId
        ); // from the economics contract of the whitelabel

        // to the dripcollector of the international integrator (so the maintainer of the whitelabel product)
        wlPrimarySaleRouteProduct_.fuelTo = _dripCollector;

        // protocol fee ($0.02) from DT to Protocol (for protocol)
        wlPrimarySaleRouteProtocol_.fuelFrom = economicsFactory_.returnIntegratorEconomicsAddressOfConfiguredIntegrator(
            _digitalTwinIntegratorId
        ); // from the economics contract of the digital twin operator servicing the whitelabel

        // to the protocol destination address as configured in the fuel distributor
        IFuelDistributor fuelDistributor_ = registry.fuelDistributor();
        (wlPrimarySaleRouteProtocol_.fuelTo, , ) = fuelDistributor_.destinationsProtocol(0);

        // secondary sale configuration
        wlSecondarySaleRouteProduct_.fuelFrom = economicsFactory_
            .returnIntegratorEconomicsAddressOfConfiguredIntegrator(_whitelabelIntegratorId); // from the economics contract of the whitelabel

        // to the dripcollector of the international integrator (so the maintainer of the whitelabel product)
        wlSecondarySaleRouteProduct_.fuelTo = _dripCollector;

        IEconomicsFactory.DynamicRates memory dynamicRates_ = economicsFactory_.returnDynamicRatesOfIntegrator(
            _whitelabelIntegratorId
        );

        // rate configuration primary market fee
        wlPrimarySaleRateProduct_.minFeeValue = dynamicRates_.minFeePrimary;
        wlPrimarySaleRateProduct_.maxFeeValue = dynamicRates_.maxFeePrimary;
        wlPrimarySaleRateProduct_.rateDynamic = dynamicRates_.primaryRate;

        wlSecondaryRateRateProduct_.minFeeValue = dynamicRates_.minFeeSecondary;
        wlSecondaryRateRateProduct_.maxFeeValue = dynamicRates_.maxFeeSecondary;
        wlSecondaryRateRateProduct_.rateDynamic = dynamicRates_.secondaryRate;

        routerType = RouterType.WHITE_LABEL_ROUTER;
    }

    // ROUTING FUNCTIONS

    /**
     * This is a 'basic' whitelabel fuel router. Routers are generally immutable or otherwise maximally trustless. They are used because 'you know what you get'. We do want to emulate these benefits.
     *
     * In AMM swapping routers play a role when a swap involves one of more temporary 'hop' assets, meaning that routers hold, intra tx. This is also the case with primarySale. If a WL sells a ticket international charges 3%.  This fuel will flow from the WL-economics address to the the product (dripcollector) contract likely.
     *
     * However in this same transaction International also pays a fee to the protocol. This fee is settled by the same router. The router acts as sort of standardized clearinghouse for agreed upon transcations. Approvals to routers should not bear any risks and therefor we need to make sure that routers are minimally configurable (or prefrably not at all).
     *
     * In the future a fuelrouter could also be confugured to spread for example the proceeds of a secondary market ticket resale to the artist, agent, protocol and so forth. The router itself merely
     *
     * Integrators should only approve routers they trust. Since by approving them they also  aproove them to touch their fuel.
     *
     */

    /**
     * @notice function called by the event implementaton contract to route a fuel demand of a primary sale
     * @param _ticketActions TicketAction struct with primary market nft sale information
     * @return _totalFuelValue total usd value of routed fuel
     * @return _totalFuelTokens total token amount of routed fuel
     */
    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external onlyEventImplementation returns (uint256 _totalFuelValue, uint256 _totalFuelTokens) {
        (_totalFuelValue, _totalFuelTokens) = _whitelabelRoutePrimarySale(_ticketActions);
    }

    /**
     * @notice function called by the event implementaton contract to route a fuel demand of a secondary sale
     * @param _ticketActions TicketAction struct with secondary market nft sale information
     * @return _totalFuelValue total usd value of routed fuel
     * @return _totalFuelTokens total token amount of routed fuel
     */
    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external onlyEventImplementation returns (uint256 _totalFuelValue, uint256 _totalFuelTokens) {
        (_totalFuelValue, _totalFuelTokens) = _whitelabelRouteFuelForSecondarySale(_ticketActions);
    }

    // VIEW FUNCTIONS

    function baseRate() external view override returns (uint256) {
        return mintBaseRate_;
    }

    function wlPrimarySaleRouteProduct() external view override returns (Route memory) {
        return wlPrimarySaleRouteProduct_;
    }

    function wlPrimarySaleRouteProduct2() external view returns (Route memory) {
        return wlPrimarySaleRouteProduct2_;
    }

    function wlPrimarySaleRouteProtocol() external view override returns (Route memory) {
        return wlPrimarySaleRouteProtocol_;
    }

    function wlSecondarySaleRouteProduct() external view override returns (Route memory) {
        return wlSecondarySaleRouteProduct_;
    }

    function wlPrimarySaleRateProduct() external view returns (DynamicRate memory) {
        return wlPrimarySaleRateProduct_;
    }

    function wlPrimarySaleRateProduct2() external view returns (DynamicRate memory) {
        return wlPrimarySaleRateProduct2_;
    }

    function wlSecondaryRateRateProduct() external view returns (DynamicRate memory) {
        return wlSecondaryRateRateProduct_;
    }

    // CONFIGURATION FUNCTIONS

    /**
     * ABOUT THE MANY CONFIGURATION FUNCTIONS BELOW
     *
     * Note: The idea of a router is that it isn't configured or changed after its deployment. In fact i would lean to make most storage immutable. I will leave the configuration/edit function in this example to show that it would be technically possible to change router settings.
     *
     * The core idea of a router (also the case in their use in DEXs) is that they are a trusted interface where actors can rely on.
     *
     * In the same manner we know that most events will have the same configuration as they are based on long running legal contracts.
     *
     * If a integrator has a special event or a special deal for a certain event, they can deploy a new router for that event. Also note that routers are used by many events.
     *
     * The final reason that routers should be considered immutable is that they contain payment settings for 2 entities (or more in the future) meaning that the entity changing the router can do so in a way that a different entity would pay/receive/collect more/less etc. Hence router configuration should not be given to one integrator in specific.
     */

    function setMintBaseRate(uint256 _baseRate) external onlyProtocolDAO {
        // todo add checks possibily
        _setMintBaseRate(_baseRate);
    }

    // Set fuel routes

    function setPrimarySaleRouteProtocol(address _from, address _to) external onlyIntegratorAdmin {
        wlPrimarySaleRouteProtocol_.fuelFrom = _from;
        wlPrimarySaleRouteProtocol_.fuelTo = _to;
        emit PrimarySaleRouteProtocolChanged(_from, _to);
    }

    /**
     *
     * @param _from address of economics contract sourcing the fuel (whitelabel)
     * @param _to address of product/international (possibly a dripcollector)
     */
    function setPrimarySaleRouteProduct2(address _from, address _to) external onlyIntegratorAdmin {
        wlPrimarySaleRouteProduct2_.fuelFrom = _from;
        wlPrimarySaleRouteProduct2_.fuelTo = _to;
        emit PrimarySaleRouteProductChanged(_from, _to);
    }

    /**
     *
     * @param _from address of economics contract sourcing the fuel (whitelabel)
     * @param _to address of product/international (possibly a dripcollector)
     */
    function setPrimarySaleRouteProduct(address _from, address _to) external onlyIntegratorAdmin {
        wlPrimarySaleRouteProduct_.fuelFrom = _from;
        wlPrimarySaleRouteProduct_.fuelTo = _to;
        emit PrimarySaleRouteProductChanged(_from, _to);
    }

    function setSecondarySaleRouteProduct(address _from, address _to) external onlyIntegratorAdmin {
        wlSecondarySaleRouteProduct_.fuelFrom = _from;
        wlSecondarySaleRouteProduct_.fuelTo = _to;
        emit SecondarySaleRouteProductChanged(_from, _to);
    }

    function setSecondarySaleRouteProductStables(address _from, address _to) external onlyIntegratorAdmin {
        wlSecondarySaleRouteProductForStables_.fuelFrom = _from;
        wlSecondarySaleRouteProductForStables_.fuelTo = _to;
        emit SecondarySaleRouteProductChanged(_from, _to);
    }

    // set fuel rates

    /**
     * @param _minFeeValue minimum amount of ticket fee
     * @param _maxFeeValue maximum amount of ticket fee
     * @param _rateDynamic percetantage fee charged over ticket value
     */
    function setWlPrimaryRateProduct(
        uint64 _minFeeValue,
        uint64 _maxFeeValue,
        uint64 _rateDynamic
    ) external onlyIntegratorAdmin {
        wlPrimarySaleRateProduct_.minFeeValue = _minFeeValue;
        wlPrimarySaleRateProduct_.maxFeeValue = _maxFeeValue;
        wlPrimarySaleRateProduct_.rateDynamic = _rateDynamic;
        emit PrimaryRateProductChanged(_minFeeValue, _maxFeeValue, _rateDynamic);
    }

    function setWlPrimaryRateProduct2(
        uint64 _minFeeValue,
        uint64 _maxFeeValue,
        uint64 _rateDynamic
    ) external onlyIntegratorAdmin {
        wlPrimarySaleRateProduct2_.minFeeValue = _minFeeValue;
        wlPrimarySaleRateProduct2_.maxFeeValue = _maxFeeValue;
        wlPrimarySaleRateProduct2_.rateDynamic = _rateDynamic;
        emit PrimaryRateProductChanged(_minFeeValue, _maxFeeValue, _rateDynamic);
    }

    function setWlSecondaryRateProduct(
        uint64 _minFeeValue,
        uint64 _maxFeeValue,
        uint64 _rateDynamic
    ) external onlyIntegratorAdmin {
        wlSecondaryRateRateProduct_.minFeeValue = _minFeeValue;
        wlSecondaryRateRateProduct_.maxFeeValue = _maxFeeValue;
        wlSecondaryRateRateProduct_.rateDynamic = _rateDynamic;
        emit SecondaryRateProductChanged(_minFeeValue, _maxFeeValue, _rateDynamic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../contracts/interfaces/IFuelRouterBase.sol";
import "../../../contracts/interfaces/IEconomicsImplementation.sol";
import "../../../contracts/interfaces/IEventImplementation.sol";
import "../../../contracts/interfaces/IEconomicsFactory.sol";
import "../../../contracts/abstract/AuthModifiersNP.sol";

contract FuelRouterBaseDemo is IFuelRouterBase, AuthModifiersNP {
    // IRegistry public registry;
    IAuth public auth;
    RouterType public routerType;

    // Route DT-PS (Digital Twin Primary sale)
    Route internal dtEventPrimarySaleRoute_; // fuel route
    uint256 internal mintBaseRate_; // pricing

    // Route WL-PS (WL Primary sale)
    Route internal wlPrimarySaleRouteProtocol_;
    // same pricing as DT-PS -> uint256 internal mintBaseRate_;

    Route internal wlPrimarySaleRouteProduct_;
    DynamicRate internal wlPrimarySaleRateProduct_;

    Route internal wlPrimarySaleRouteProduct2_;
    DynamicRate internal wlPrimarySaleRateProduct2_;

    // Route WL-SS (WL Secondary sale)
    // Route internal wlSecondarySaleRouteProtocol_;
    // DynamicRate internal wlSecondaryRateRateProtocol_;

    Route internal wlSecondarySaleRouteProduct_;
    DynamicRate internal wlSecondaryRateRateProduct_;

    Route internal wlSecondarySaleRouteProductForStables_;
    DynamicRate internal wlSecondaryRateRateProductForStables_;

    constructor(uint256 _baseRate, address _registry) AuthModifiersNP(_registry) {
        auth = IAuth(registry.auth());
        mintBaseRate_ = _baseRate;
    }

    /**
     * @dev Throws if called by any contract different from an instance of a GET protocol Event Contract
     */
    modifier onlyEventImplementation() {
        // prob add check if event is enabled
        auth.hasEventRole(msg.sender);
        _;
    }

    function isRouterWhitelabelRouter() external view returns (bool isWhitelabelRouter_) {
        if (routerType == RouterType.NONE) {
            revert("FuelRouterBase: Invalid routertype");
        } else if (routerType == RouterType.DIGITAL_TWIN_ROUTER) {
            return false;
        } else {
            return true;
        }
    }

    function _setMintBaseRate(uint256 _baseRate) internal {
        mintBaseRate_ = _baseRate;
    }

    function _digitalTwinPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuelValue, uint256 _totalFuelTokens) {
        _totalFuelValue = _calculateBaseFee(_ticketActions.length);

        Route memory _routeProtocol = dtEventPrimarySaleRoute_;

        // todo potentially call the EconomicsFactory to register a certain amount of tickets minted (as to replace activeTicketCount) - however might not be necessary because we do not do the tax rate anymore?

        // route the usd requirement for the base fee (to the protocol contract) from the economics contract of the DT
        _totalFuelTokens = _routeFuel(_routeProtocol.fuelFrom, _routeProtocol.fuelTo, _totalFuelValue);

        emit FuelRoutedDigitalTwinPrimarySale(
            msg.sender,
            _routeProtocol.fuelFrom,
            _routeProtocol.fuelTo,
            _totalFuelValue
        );

        return (_totalFuelValue, _totalFuelTokens);
    }

    /**
     * 30000 = 3% = 1e6 scaled
     * 20 =  $0.02 = 1e3 scaled
     */

    /**
     * @notice function that is called by the EventImplementation contract on primary sale
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     */
    function _whitelabelRoutePrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuelValue, uint256 _totalFuelTokens) {
        // calculate the product fee (so percentage of the ticket price)
        _totalFuelValue = _calculateProductFeePrimaryWhitelabel(_ticketActions);

        Route memory _routeProduct = wlPrimarySaleRouteProduct_;

        // route the usd requirement for the product fee from the economics contract of the WL economics to the product contract/recipient
        _totalFuelTokens = _routeFuel(_routeProduct.fuelFrom, _routeProduct.fuelTo, _totalFuelValue);

        // calculate the product fee (so percentage of the ticket price)
        _totalFuelValue = _calculateProductFeePrimaryWhitelabelSecond(_ticketActions);

        Route memory _routeProduct2 = wlPrimarySaleRouteProduct2_;

        // route the usd requirement for the product fee from the economics contract of the WL economics to the product contract/recipient
        _totalFuelTokens = _routeFuel(_routeProduct2.fuelFrom, _routeProduct2.fuelTo, _totalFuelValue);

        // calculate the fee to be paid to the protocol by the dt of the wl
        uint256 _totalValueFuelProtocol = _calculateBaseFee(_ticketActions.length);

        Route memory _routeProtocol = wlPrimarySaleRouteProtocol_;

        // route the usd requirement for the base fee (to the protocol contract) from the economics contract of the DT
        _routeFuel(_routeProtocol.fuelFrom, _routeProtocol.fuelTo, _totalValueFuelProtocol);

        emit FuelRoutedWhitelabelPrimarySale(msg.sender, _routeProduct.fuelFrom, _routeProduct.fuelTo, _totalFuelValue);

        // note we could emit an event for the amount and value of tokens routed/paid by the dt of the wl - however technically that could be considered double counting as the wl fee 'includes' the dt fee

        // this is the total amount of fuel tokens that were routed (and the value of them)
        return (_totalFuelValue, _totalFuelTokens);
    }

    /**
     * @notice function that is called by the EventImplementation contract on secondary sale
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     */
    function _whitelabelRouteFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal returns (uint256 _totalFuelValue, uint256 _totalFuelTokens) {
        // route the protocol fee in GET tokens
        _totalFuelValue = _calculateProductFeeSecondaryWhitelabel(_ticketActions);

        Route memory _routeProduct = wlSecondarySaleRouteProduct_;

        _totalFuelTokens = _routeFuel(_routeProduct.fuelFrom, _routeProduct.fuelTo, _totalFuelValue);

        // route the stable coin royalty settlement in USDC instead
        _totalFuelValue = _calculateProductFeeSecondaryWhitelabel(_ticketActions);

        Route memory _routeProductStables = wlSecondarySaleRouteProductForStables_;

        _totalFuelTokens = _routeFuel(_routeProductStables.fuelFrom, _routeProductStables.fuelTo, _totalFuelValue);

        emit FuelRoutedWhitelabelSecondarySale(
            msg.sender,
            _routeProduct.fuelFrom,
            _routeProduct.fuelTo,
            _totalFuelValue
        );

        return (_totalFuelValue, _totalFuelTokens);
    }

    function _calculateBaseFee(uint256 _amountActions) internal view returns (uint256 _totalFuelProtocolValue) {
        // amount of tickets minted multiplied by the price in cents per ticket mint (generally $0.02 per ticket/mint) -> 20 = 2 cents
        _totalFuelProtocolValue = _amountActions * mintBaseRate_ * 1e15;
    }

    /**
     * @notice function that calculates the fuel cost for a secondary sale for the product
     * @dev note this function charges dynamic fees based on the ticket price (and the configured min and max prices)
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     * @return _totalFuelProductValue the total fuel cost for the product portion of the secondary sale (in tokens, not usd)
     */
    function _calculateProductFeeSecondaryWhitelabel(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal view returns (uint256 _totalFuelProductValue) {
        DynamicRate memory _secondaryRateProduct = wlSecondaryRateRateProduct_;

        uint256 minFeeValue_ = uint256(_secondaryRateProduct.minFeeValue) * 1e15;
        uint256 maxFeeValue_ = uint256(_secondaryRateProduct.maxFeeValue) * 1e15;
        uint256 rate_ = uint256(_secondaryRateProduct.rateDynamic);

        _totalFuelProductValue = 0;

        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _feeUsdValue;

            unchecked {
                _feeUsdValue = uint256(_ticketActions[i].basePrice) * rate_ * 1e9;
                if (_feeUsdValue <= minFeeValue_) {
                    _totalFuelProductValue += minFeeValue_;
                } else if (maxFeeValue_ == 0 || _feeUsdValue < maxFeeValue_) {
                    _totalFuelProductValue += _feeUsdValue;
                } else {
                    _totalFuelProductValue += maxFeeValue_;
                }
            }
        }
        return _totalFuelProductValue;
    }

    /**
     * @notice function that calculates the fuel cost for a primary sale for the product
     * @dev note this function charges dynamic fees based on the ticket price (and the configured min and max prices)
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     * @param _totalFuelProductValue total fuel tokens used for the product fee of the primary sale
     */
    function _calculateProductFeePrimaryWhitelabel(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal view returns (uint256 _totalFuelProductValue) {
        DynamicRate memory _primaryRateProduct = wlPrimarySaleRateProduct_;

        uint256 minFeeValue_ = uint256(_primaryRateProduct.minFeeValue) * 1e15;
        uint256 maxFeeValue_ = uint256(_primaryRateProduct.maxFeeValue) * 1e15;
        uint256 rate_ = uint256(_primaryRateProduct.rateDynamic);

        _totalFuelProductValue = 0;

        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _feeUsdValue;

            unchecked {
                _feeUsdValue = uint256(_ticketActions[i].basePrice) * rate_ * 1e9;
                if (_feeUsdValue <= minFeeValue_) {
                    _totalFuelProductValue += minFeeValue_;
                } else if (maxFeeValue_ == 0 || _feeUsdValue < maxFeeValue_) {
                    _totalFuelProductValue += _feeUsdValue;
                } else {
                    _totalFuelProductValue += maxFeeValue_;
                }
            }
        }
        return _totalFuelProductValue;
    }

    /**
     * @notice function that calculates the fuel cost for a primary sale for the product
     * @dev note this function charges dynamic fees based on the ticket price (and the configured min and max prices)
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     * @param _totalFuelProductValue total fuel tokens used for the product fee of the primary sale
     */
    function _calculateProductFeePrimaryWhitelabelSecond(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) internal view returns (uint256 _totalFuelProductValue) {
        DynamicRate memory _primaryRateProduct = wlPrimarySaleRateProduct2_;

        uint256 minFeeValue_ = uint256(_primaryRateProduct.minFeeValue) * 1e15;
        uint256 maxFeeValue_ = uint256(_primaryRateProduct.maxFeeValue) * 1e15;
        uint256 rate_ = uint256(_primaryRateProduct.rateDynamic);

        _totalFuelProductValue = 0;

        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _feeUsdValue;

            unchecked {
                _feeUsdValue = uint256(_ticketActions[i].basePrice) * rate_ * 1e9;
                if (_feeUsdValue <= minFeeValue_) {
                    _totalFuelProductValue += minFeeValue_;
                } else if (maxFeeValue_ == 0 || _feeUsdValue < maxFeeValue_) {
                    _totalFuelProductValue += _feeUsdValue;
                } else {
                    _totalFuelProductValue += maxFeeValue_;
                }
            }
        }
        return _totalFuelProductValue;
    }

    /**
     * @param _economicsFrom address of the economics contract from which to route the fuel request
     * @param _fuelDestination address of the contract to which to route the fuel request
     * @param _fuelAmount  amount of fuel to be routed
     */
    function _routeFuel(
        address _economicsFrom,
        address _fuelDestination,
        uint256 _fuelAmount
    ) internal returns (uint256 _fuelUsedTokens) {
        if (_fuelAmount == 0) {
            // todo probably emit event
            return 0;
        } else {
            _fuelUsedTokens = IEconomicsImplementation(_economicsFrom).routeFuelRequest(_fuelAmount, _fuelDestination);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IEventImplementation.sol";
import "./IFuelRouterBase.sol";

interface IFuelRouterWhitelabelEvent {
    function setMintBaseRate(uint256 _baseRate) external;

    function baseRate() external view returns (uint256);

    function wlPrimarySaleRouteProduct() external view returns (IFuelRouterBase.Route memory);

    function wlPrimarySaleRouteProtocol() external view returns (IFuelRouterBase.Route memory);

    function wlSecondarySaleRouteProduct() external view returns (IFuelRouterBase.Route memory);

    function wlPrimarySaleRateProduct() external view returns (IFuelRouterBase.DynamicRate memory);

    function wlSecondaryRateRateProduct() external view returns (IFuelRouterBase.DynamicRate memory);

    function setPrimarySaleRouteProtocol(address _from, address _to) external;

    function setPrimarySaleRouteProduct(address _from, address _to) external;

    function setSecondarySaleRouteProduct(address _from, address _to) external;

    function setWlPrimaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic) external;

    function setWlSecondaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic) external;

    function routeFuelForPrimarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);

    function routeFuelForSecondarySale(
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external returns (uint256 _totalFuelValue, uint256 _totalFuelTokens);

    event PrimarySaleRouteProtocolChanged(address indexed _from, address indexed _to);

    event PrimarySaleRouteProductChanged(address indexed _from, address indexed _to);

    event SecondarySaleRouteProtocolChanged(address indexed _from, address indexed _to);

    event SecondarySaleRouteProductChanged(address indexed _from, address indexed _to);

    event PrimaryRateProductChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);

    event SecondaryRateProtocolChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);

    event SecondaryRateProductChanged(uint64 indexed _minPrice, uint64 indexed _maxPrice, uint64 indexed _rateDynamic);
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
pragma solidity >=0.6.0 <0.9.0;

import "./IEventImplementation.sol";
import "./IRegistry.sol";
import "./IAuth.sol";

interface IFuelRouterBase {
    event FuelRoutedDigitalTwinPrimarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        address indexed fuelDestinationTo,
        uint256 fuelValue
    );
    event FuelRoutedWhitelabelPrimarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        address indexed fuelDestinationTo,
        uint256 fuelValue
    );
    event FuelRoutedWhitelabelSecondarySale(
        address indexed eventAddress,
        address indexed economicsAddressFrom,
        address indexed fuelDestinationTo,
        uint256 fuelValue
    );
    event FuelRouted(address indexed _from, address indexed _to, uint256 _value);

    enum RouterType {
        NONE,
        DIGITAL_TWIN_ROUTER,
        WHITE_LABEL_ROUTER
    }

    function isRouterWhitelabelRouter() external view returns (bool isWhitelabelRouter_);

    // function registry() external view returns (IRegistry);

    /**
        FuelRoute Struct
        @param fuelFrom address of the economics contract that will be sending the fuel 
        @param fuelTo address of the address that will be receiving the fuel
     */
    struct Route {
        address fuelFrom; // this is always an economics contract
        address fuelTo; // this could be an economics contract or a protocol contract (dripcollector)
    }

    struct DynamicRate {
        uint64 minFeeValue;
        uint64 maxFeeValue;
        uint64 rateDynamic;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IPricingFIFO.sol";

interface IEconomicsImplementation is IPricingFIFO {
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

    event OverdraftConfigSet(bool overdraftEnabled_);

    function routeFuelRequest(
        uint256 _usdAmount,
        address _fuelDestination
    ) external returns (uint256 totalFuelSpendTokens_);

    function topUpEconomics(uint256 _price, uint256 _amount) external returns (uint256 totalFuel_);

    function returnTokenBalanceOfFuelHolder() external view returns (uint256 fuelBalance_);

    // EVENTS

    // event IntegratorToppedUp(
    //     uint32 indexed integratorIndex,
    //     uint256 indexed total,
    //     uint256 price,
    //     uint256 indexed newAveragePrice,
    //     uint256 salesTax // .
    // );

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        uint256 indexed total,
        uint256 price,
        uint256 indexed newAveragePrice,
        uint256 salesTax // .
    );

    event NewFuelHolder(address fuelHolder);

    event ToppedUp(
        uint256 price,
        uint256 amount
        // add ticket ID?
    );

    event FuelRouted(address router, uint256 usdAmount, address fuelDestination);

    event EventRegisterd(address eventAddress, address fuelHolderAddress);
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

    function setTokenRoyaltyException(uint256 _tokenId, address _receiver, uint96 _feeNominator) external;

    function setTokenRoyaltyDefault(address _royaltyReceiver, uint96 _feeDenominator) external;

    function deleteRoyaltyInfoDefault() external;

    function deleteRoyaltyException(uint256 _tokenId) external;
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
pragma solidity ^0.8.4;

import "../interfaces/IRegistry.sol";

/**
 * @title AuthModifiers Contract (NON PROXY VARIANT)
 * @author GET Protocol
 * @notice This contract provides access control modifiers to the Auth contract
 * @dev It's implemented as an abstract contract
 */

abstract contract AuthModifiersNP {
    IRegistry public immutable registry;

    constructor(address _registry) {
        registry = IRegistry(_registry);
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer admin account.
     */
    modifier onlyIntegratorAdmin() {
        registry.auth().hasIntegratorAdminRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer account.
     */
    modifier onlyRelayer() {
        registry.auth().hasRelayerRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than a GET Protocol Factory contract.
     */
    modifier onlyEventFactory() {
        registry.auth().hasEventFactoryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract different from an instance of a GET protocol Event Contract
     */
    modifier onlyEvent() {
        registry.auth().hasEventRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the GET Protocol FuelDistributor Contract.
     */
    modifier onlyFuelDistributor() {
        registry.auth().hasFuelDistributorRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the GET Protocol TopUp Contract.
     */
    modifier onlyTopUp() {
        registry.auth().hasTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol EOA(S) designated for TopUps.
     */
    modifier onlyCustodialTopUp() {
        registry.auth().hasCustodialTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the PriceOracle update EOA.
     */
    modifier onlyPriceOracle() {
        registry.auth().hasPriceOracleRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the router registry contract
     */
    modifier onlyRouterRegistry() {
        registry.auth().hasRouterRegistryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the fuel router contract
     */
    modifier onlyFuelRouter() {
        registry.auth().hasFuelRouterRole(msg.sender);
        _;
    }

    modifier onlyProtocolDAO() {
        registry.auth().hasProtocolDAORole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the economics factory contract
     */
    modifier onlyEconomicsFactory() {
        registry.auth().hasEconomicsFactoryRole(msg.sender);
        _;
    }

    modifier onlyIntegratorEconomicsConfiguration(uint256 _integratorIndex) {
        registry.auth().hasEconomicsConfigurationRole(msg.sender, _integratorIndex);
        _;
    }

    modifier onlyIntegratorEventFinancingConfiguration(uint256 _integratorIndex) {
        registry.auth().hasEventFinancingConfigurationRole(msg.sender, _integratorIndex);
        _;
    }
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

interface IPricingFIFO {
    // topup info, every topup comes a topup 'tick' (like uniswap v3 lp)
    struct TopUpTickInfo {
        // todo probaby we can use smaller uint256 types here
        uint256 price; // price of the GET in the tick
        uint256 amount; // amount of GET in topup (note this is NOT what is left in top up tick!!!)
        uint256 start; // start of the tick (in GET units)
        uint256 stop; // end of the ticket (in GET units)
        uint256 timestamp;
        // todo consider adding total value
    }

    // function topUpTicks(uint256 _index) external view returns (TopUpTickInfo memory);

    function aggregatedTokensToppedUpAllTime() external view returns (uint256 totalTokens_);

    function aggregatedUSDToppedUpAllTime() external view returns (uint256 totalUsd_);

    function fuelAmountUnits() external view returns (uint256 amountUnits_);

    function fuelBalanceUSD() external view returns (uint256 amountUnits_);

    function valueUsdOfAllTicks() external view returns (uint256 amountUnits_);

    function totalFuel() external view returns (uint256 totalFuelUsd_, uint256 totalFuelGET_);

    function topUpCounter() external view returns (uint256);

    function overdraftEnabled() external view returns (bool);

    function inOverdraft() external view returns (bool);

    function aggregatedUSDValueUsedAllTime() external view returns (uint256);

    function usdValueOfOverdraftedFuelUsd() external view returns (uint256);

    function timeOfLastOverdraftUpdate() external view returns (uint256);

    function activeTopupTick() external view returns (uint256 activeTick_);

    function usdLeftInActiveTick() external view returns (uint256 usdValueleftInTick_);

    function nextTicketActivation() external;

    event OverdraftTopUp();
    event CurrentActiveTick(uint256 tickIndex);
    event TickActivated(uint256 tickIndex);
    event TickAppended(uint256 tickIndex);
    event FuelOnCredit(uint256 amountUsdToOverdraft);
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