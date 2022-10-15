// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Economics Contract
 * @author GET Protocol
 * @notice Contract responsible for on-chain fuel accounting per integrator
 * @dev Fuel strictly refers to $GET
 *
 * @dev Fuel is denominated in 18 decimals
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./abstract/AuthModifiers.sol";
import "./interfaces/IEconomics.sol";
import "./interfaces/IEventImplementation.sol";

contract Economics is IEconomics, AuthModifiers, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    mapping(address => RelayerData) public relayerData;
    mapping(uint32 => IntegratorData) public integratorData;
    mapping(uint32 => DynamicRates) public integratorRates;
    DynamicRates public protocolRates;
    SpentFuel public spentFuel;
    IERC20 public fuelToken;
    uint24 public basicTaxRate;
    uint32 public integratorCount;
    uint256 public salesTaxFuel;
    address public salesTaxFuelDestination;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     * @param _registry the Registry contract address
     * @param _fuelToken $GET token contract address
     * @param _salesTaxFuelDestination address sales tax is collected to
     * @param _basicTaxRate tax rate per basic action e.g scan
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Economics_init(
        address _registry,
        address _fuelToken,
        address _salesTaxFuelDestination,
        uint24 _basicTaxRate,
        DynamicRates calldata _protocolRates
    ) public initializer {
        __Ownable_init();
        __AuthModifiers_init(_registry);
        __Economics_init_unchained(_fuelToken, _salesTaxFuelDestination, _basicTaxRate, _protocolRates);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Economics_init_unchained(
        address _fuelToken,
        address _salesTaxFuelDestination,
        uint24 _basicTaxRate,
        DynamicRates calldata _protocolRates
    ) internal initializer {
        fuelToken = IERC20(_fuelToken);
        setBasicTaxRate(_basicTaxRate);
        setProtocolRates(_protocolRates);
        setSalesTaxFuelDestination(_salesTaxFuelDestination);
    }

    // MODIFIERS //
    ///  @dev filters out unconfigured integrators
    modifier onlyConfigured(address _relayerAddress) {
        require(
            integratorData[relayerData[_relayerAddress].integratorIndex].isConfigured,
            "Economics: integrator not configured"
        );
        _;
    }

    /// OPERATIONAL FUNCTIONS

    /**
     * @notice Tops up an integrator
     * @dev It's called by the TopUp contract and transfers $GET to this contract
     *
     * @dev It increases integrator available fuel
     *
     * @dev It updates integrator average $GET price at top up
     * @param _integratorIndex index of the integrator to top up
     * @param _sender account that $GET should be transferred from
     * @param _total amount of $GET that will be topped up, inclusive of sales tax
     * @param _price USD price per GET that is paid and will be locked
     */
    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _total,
        uint256 _price
    ) external onlyTopUp returns (uint256) {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        DynamicRates storage _integratorRates = integratorRates[_integratorIndex];

        require(integrator.isConfigured, "Economics: integrator not configured");
        require(_total > 0, "Economics: zero amount");
        require(_price > 0, "Economics: incorrect price");
        require(fuelToken.allowance(_sender, address(this)) >= _total, "Economics: sender lacks allowance");

        bool _topUpFuel = fuelToken.transferFrom(_sender, address(this), _total);
        require(_topUpFuel, "Economics: transfer failed! Perhaps balance might be too low");

        uint256 _salesTaxAmount = (_total * _integratorRates.salesTaxRate) / 1_000_000;
        uint256 _remainingTopUpAmount = _total - _salesTaxAmount;
        uint256 _newAveragePrice = _calculateAveragePrice(
            _remainingTopUpAmount,
            _price,
            integrator.availableFuel,
            integrator.price
        );

        salesTaxFuel += _salesTaxAmount;
        integrator.availableFuel += _remainingTopUpAmount;
        integrator.price = _newAveragePrice;

        emit IntegratorToppedUp(_integratorIndex, _total, _price, _newAveragePrice, _salesTaxAmount);
        return integrator.availableFuel;
    }

    /**
     * @notice Internal function that calculates and reserves fuel upon primary or secondary sale
     * @dev It receives a minimum and maximum fee and returns a value within the range
     *
     * @dev It reduces integrator available fuel and increases reserved fuel
     * @param integrator integrator struct
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which fuel is to be reserved
     * @param _product Rate struct containing fee info for the product
     * @param _protocol Rate struct containing fee info for the protocol
     * @return _fuel total fuel reserved
     * @return _fuelProtocol portion of _fuel for the protocol
     */

    function _reserveFuelForRate(
        IntegratorData storage integrator,
        IEventImplementation.TicketAction[] calldata _ticketActions,
        Rate memory _product,
        Rate memory _protocol
    ) internal returns (uint256, uint256) {
        if (!integrator.isBillingEnabled) return (0, 0);

        // Both the integrator's average price (price) and the fuel are normalized to 1e18, here we do the same for the
        // minFee and maxFee for use in comparisons later in the function.
        uint256 _min = uint256(_product.minFee) * 1e15;
        uint256 _max = uint256(_product.maxFee) * 1e15;

        // Deductions represent the fees that the Protocol charges for tickets as a baseline fee for usage. This forms
        // a part of the total fee, where the Protocol 'eats first'. E.g. if the Protocol has a $0.02 fixed fee for
        // minting tickets, and the SaaS has $0.10, then the deduction represents the Protocol fee portion and will be
        // allocated prior to the $0.10. The total fee in this example will still be $0.10 only that the Protocol takes
        // the first slice.
        uint256 _protocolMin = uint256(_protocol.minFee) * 1e15;
        uint256 _protocolMax = uint256(_protocol.maxFee) * 1e15;

        // We store a minimum and maximum fee (in USD) for each integrator which denotes the maximum and minimum fuel
        // we can collect for each ticket sale. We first calculate the amount of fuel required per-ticket in USD to
        // 1e18 precision and then compare against the min/max to determine whether it's in range. 0 denotes no fee
        // limit.
        //
        // When the minFee is 0 we can take that as-is because _fuelUsd would be greater and fall into another
        // condition, however when the maxFee is 0 we need to treat this as a special case so that we don't use 0 as
        // the fee. Hence this is checked for first.
        //
        // Full workings:
        //
        // _fuelUsd[1e18] = (basePrice[1e3] * 1e15) * (rate[1e6] / 1e6);
        //   => _fuelUsd[1e18] = (basePrice[1e3] * 1e9) / rate[1e6];
        //
        // _fuel[1e18] = (_fuelUsd[1e18] * 1e18) / price[1e18];
        uint256 _fuel = 0;
        uint256 _protocolFuel = 0;
        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _fuelUsd = uint256(_ticketActions[i].basePrice) * _product.rate * 1e9;
            uint256 _protocolFuelUsd = uint256(_ticketActions[i].basePrice) * _protocol.rate * 1e9;

            if (_protocolFuelUsd < _protocolMin) {
                _protocolFuel += (_protocolMin * 1e18) / integrator.price;
            } else if (_protocolFuelUsd > _protocolMax && _protocolMax != 0) {
                _protocolFuel += (_protocolMax * 1e18) / integrator.price;
            } else {
                _protocolFuel += (_protocolFuelUsd * 1e18) / integrator.price;
            }

            if (_fuelUsd < _min) {
                _fuel += (_min * 1e18) / integrator.price;
            } else if (_fuelUsd > _max && _max != 0) {
                _fuel += (_max * 1e18) / integrator.price;
            } else {
                _fuel += (_fuelUsd * 1e18) / integrator.price;
            }
        }

        require(_fuel < integrator.availableFuel, "Economics: insufficient available fuel");

        integrator.availableFuel -= _fuel;
        integrator.reservedFuel += _fuel;

        if (_protocolFuel >= _fuel) _protocolFuel = _fuel;
        integrator.reservedFuelProtocol += _protocolFuel;

        return (_fuel, _protocolFuel);
    }

    /**
     * @notice Reserves fuel on a primary sale
     * @dev It can only be called by an Event contract for a configured integrator
     *
     * @dev It increases an integrator's active ticket count
     * @param _relayerAddress integrator relayer address
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which sale happens
     * @return _fuel total fuel reserved
     * @return _fuelProtocol portion of _fuel for the protocol
     */

    function reserveFuelPrimarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external onlyEvent onlyConfigured(_relayerAddress) returns (uint256, uint256) {
        uint32 _integratorIndex = relayerData[_relayerAddress].integratorIndex;
        DynamicRates storage _integratorRates = integratorRates[_integratorIndex];
        IntegratorData storage integrator = integratorData[_integratorIndex];

        (uint256 _fuel, uint256 _fuelProtocol) = _reserveFuelForRate(
            integrator,
            _ticketActions,
            Rate(_integratorRates.minFeePrimary, _integratorRates.maxFeePrimary, _integratorRates.primaryRate),
            Rate(protocolRates.minFeePrimary, protocolRates.maxFeePrimary, protocolRates.primaryRate)
        );

        integrator.activeTicketCount += uint32(_ticketActions.length);
        emit FuelReservedPrimary(_integratorIndex, uint32(_ticketActions.length), _fuel, _fuelProtocol);
        return (_fuel, _fuelProtocol);
    }

    /**
     * @notice Reserves fuel on a resale
     * @dev can only be called by an Event contract for a configured integrator
     *
     * @dev It does NOT increases an integrator's active ticket count
     * @param _relayerAddress integrator relayer address
     * @param _ticketActions array of IEventImplementation.TicketAction structs for which resale happens
     * @return _fuel total fuel reserved
     * @return _fuelProtocol portion of _fuel for the protocol
     */

    function reserveFuelSecondarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] calldata _ticketActions
    ) external onlyEvent onlyConfigured(_relayerAddress) returns (uint256, uint256) {
        uint32 _integratorIndex = relayerData[_relayerAddress].integratorIndex;
        DynamicRates storage _integratorRates = integratorRates[_integratorIndex];
        IntegratorData storage integrator = integratorData[_integratorIndex];

        (uint256 _fuel, uint256 _fuelProtocol) = _reserveFuelForRate(
            integrator,
            _ticketActions,
            Rate(_integratorRates.minFeeSecondary, _integratorRates.maxFeeSecondary, _integratorRates.secondaryRate),
            Rate(protocolRates.minFeeSecondary, protocolRates.maxFeeSecondary, protocolRates.secondaryRate)
        );

        emit FuelReservedSecondary(_integratorIndex, uint32(_ticketActions.length), _fuel, _fuelProtocol);
        return (_fuel, _fuelProtocol);
    }

    /**
     * @notice Taxes an integrator for a basic action, i.e scan
     * @dev It can only be called by an Event contract
     *
     * @dev It deducts the calculated fuel from the integrator's reserved fuel
     *
     * @dev It adds the deducted fuel to the total spent fuel
     * @param _relayerAddress - relayer address of an integrator
     * @param _ticketCount - number of tickets for which fuel is to be deducted
     * @return _fuelToSpend - amount of fuel for all tickets spent
     * @return _fuelToSpentProtocol - portion of _fuelToSpend for to the protocol
     */
    function spendBasicAction(address _relayerAddress, uint32 _ticketCount)
        external
        onlyEvent
        returns (uint256, uint256)
    {
        IntegratorData storage integrator = integratorData[relayerData[_relayerAddress].integratorIndex];
        if (!integrator.isBillingEnabled) return (0, 0);

        (uint256 _reservedFuel, uint256 _reservedFuelProtocol) = _reservedFuelPerTicket(integrator.index);
        uint256 _fuelToSpend = (basicTaxRate * _reservedFuel * _ticketCount) / 1e6;
        uint256 _fuelToSpendProtocol = (basicTaxRate * _reservedFuelProtocol * _ticketCount) / 1e6;

        integrator.reservedFuel -= _fuelToSpend;
        spentFuel.total += _fuelToSpend;

        integrator.reservedFuelProtocol -= _fuelToSpendProtocol;
        spentFuel.protocol += _fuelToSpendProtocol;

        emit BasicTaxCharged(integrator.index, _ticketCount, _fuelToSpend, _fuelToSpendProtocol);
        return (_fuelToSpend, _fuelToSpendProtocol);
    }

    /**
     * @notice Spends the reserved fuel of an integrator
     * @dev It can only be called by an Event contract
     *
     * @dev It adds the deducted fuel to the total spent fuel
     *
     * @dev It deducts the ticketCount from the integrator's ticket count
     * @param _relayerAddress - relayer address of an integrator
     * @param _ticketCount - number of tickets for which fuel is to be deducted
     * @return _fuelToSpend - amount of fuel for all tickets spent
     * @return _fuelToSpendProtocol - portion of _fuelToSpend for to the protocol
     */
    function spendTicketReserved(address _relayerAddress, uint32 _ticketCount)
        external
        onlyEvent
        returns (uint256, uint256)
    {
        IntegratorData storage integrator = integratorData[relayerData[_relayerAddress].integratorIndex];
        if (!integrator.isBillingEnabled) return (0, 0);

        (uint256 _reservedFuel, uint256 _reservedFuelProtocol) = _reservedFuelPerTicket(integrator.index);
        uint256 _fuelToSpend = _reservedFuel * _ticketCount;
        uint256 _fuelToSpendProtocol = _reservedFuelProtocol * _ticketCount;

        if (_reservedFuel == 0) return (0, 0);

        require(integrator.reservedFuel >= _fuelToSpend, "Economics: spending more fuel than reserved");
        require(
            integrator.reservedFuelProtocol >= _fuelToSpendProtocol,
            "Economics: spending more protocol fuel than reserved"
        );
        require(integrator.activeTicketCount >= _ticketCount, "Economics: processing more tickets than active");

        integrator.reservedFuel -= _fuelToSpend;
        spentFuel.total += _fuelToSpend;

        integrator.reservedFuelProtocol -= _fuelToSpendProtocol;
        spentFuel.protocol += _fuelToSpendProtocol;

        integrator.activeTicketCount -= _ticketCount;
        spentFuel.ticketCount += _ticketCount;

        emit TicketFuelEmptied(integrator.index, _ticketCount, _fuelToSpend, _fuelToSpendProtocol);
        return (_fuelToSpend, _fuelToSpendProtocol);
    }

    /**
     * @dev Moves the spentFuel total balance to the FuelDistributor contract
     *
     * @dev It can only be called by the FuelDistributor contract
     * @return total - total spent fuel accrued
     * @return protocol - portion of spent fuel reserved for the protocol
     */
    function collectSpentFuel() public nonReentrant onlyFuelDistributor returns (uint256, uint256) {
        if (spentFuel.total == 0) return (0, 0);
        require(fuelToken.balanceOf(address(this)) >= spentFuel.total, "Economics: insufficient token balance");

        // State-change before transfer to cover reentrancy.
        SpentFuel memory _spentFuel = spentFuel;
        spentFuel.total = 0;
        spentFuel.protocol = 0;
        spentFuel.ticketCount = 0;

        require(fuelToken.transfer(msg.sender, _spentFuel.total), "Economics: fuel token transfer failed");
        emit SpentFuelCollected(_spentFuel);
        return (_spentFuel.total, _spentFuel.protocol);
    }

    /**
     * @dev Moves the salesTaxFuel balance to the caller
     *
     * @dev It can only be called by an integrator admin account
     */
    function collectSalesTaxFuel() public nonReentrant onlyIntegratorAdmin {
        require(salesTaxFuel > 0, "Economics: nothing to collect");
        require(fuelToken.balanceOf(address(this)) >= salesTaxFuel, "Economics: insufficient token balance");
        uint256 _salesTaxFuel = salesTaxFuel;
        salesTaxFuel = 0;
        require(fuelToken.transfer(salesTaxFuelDestination, _salesTaxFuel), "Economics: fuel token transfer failed");
        emit SalesTaxFuelCollected(salesTaxFuelDestination, _salesTaxFuel);
    }

    /**
     * @notice An internal function to process balance difference when correcting an integrator's account balances
     */
    function _processCorrection(uint256 _new, uint256 _old) internal {
        uint256 _difference;
        if (_new != 0 && _new != _old) {
            if (_new > _old) {
                _difference = _new - _old;
                require(
                    fuelToken.transferFrom(msg.sender, address(this), _difference),
                    "Economics: available fuel transfer in failed"
                );
            } else {
                _difference = _old - _new;
                require(fuelToken.transfer(msg.sender, _difference), "Economics: available fuel balance refund failed");
            }
        }
    }

    /**
     * @notice Corrects an integrator's available and reserved fuel balance
     * @dev The available fuel delta is either removed or added to the spentFuel balance
     * @param _integratorIndex index of the integrator in question
     * @param _newAvailableFuel the correct/intended balance of the integrator's available balance
     * @param _newReservedFuel the correct/intended balance of the integrator's reserved balance
     */
    function correctAccountBalance(
        uint32 _integratorIndex,
        uint256 _newAvailableFuel,
        uint256 _newReservedFuel
    ) external nonReentrant onlyIntegratorAdmin {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        uint256 _oldAvailableFuel = integrator.availableFuel;
        uint256 _oldReservedFuel = integrator.reservedFuel;
        uint256 _oldReservedFuelProtocol = integrator.reservedFuelProtocol;

        _processCorrection(_newAvailableFuel, _oldAvailableFuel);
        _processCorrection(_newReservedFuel, _oldReservedFuel);

        integrator.availableFuel = _newAvailableFuel;
        integrator.reservedFuel = _newReservedFuel;
        integrator.reservedFuelProtocol = (integrator.reservedFuelProtocol * _newReservedFuel) / _oldReservedFuel;

        emit AccountBalanceCorrected(
            integrator.index,
            _oldAvailableFuel,
            integrator.availableFuel,
            _oldReservedFuel,
            integrator.reservedFuel,
            _oldReservedFuelProtocol,
            integrator.reservedFuelProtocol
        );
    }

    /**
     * @notice Calculates weighted average $GET price for an integrator during a top up.
     * @dev All params are 18 decimals in precision
     * @param _incomingFuelAmount amount of $GET that is to be topped x10^18
     * @param _incomingPrice USD price per $GET that is being topped up x10^4
     * @param _currentFuelBalance amount of reservedFuel for a relayer x10^18
     * @param _currentPrice current USD price per $GET for a relayer x10^18
     * @return _newPrice new $GET price for the integrator
     */
    function _calculateAveragePrice(
        uint256 _incomingFuelAmount,
        uint256 _incomingPrice,
        uint256 _currentFuelBalance,
        uint256 _currentPrice
    ) internal pure returns (uint256) {
        uint256 _currentUsdValue = _currentFuelBalance * _currentPrice;
        uint256 _incomingUsdValue = _incomingFuelAmount * _incomingPrice;
        uint256 _totalUSDValue = _currentUsdValue + _incomingUsdValue;
        uint256 _totalFuelBalance = _currentFuelBalance + _incomingFuelAmount;
        uint256 _newPrice = _totalUSDValue / _totalFuelBalance;

        return _newPrice;
    }

    /**
     * @notice Creates and configures an integrator
     * @dev It sets the the dynamic rates and relayer for an integrator
     *
     * @dev It can only be called by an integrator admin
     *
     * @dev Dynamic rates are used to determine fuel spent by an integrator per specific ticket interraction
     * @param _name Integrator name
     * @param _relayerAddress an integrator relayer address
     * @param _dynamicRates integrator dynamic rates
     */
    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates,
        uint256 _price
    ) external onlyIntegratorAdmin {
        IntegratorData storage integrator = integratorData[integratorCount];
        integratorRates[integratorCount] = _dynamicRates;
        integrator.index = integratorCount;
        integrator.name = _name;

        activateIntegrator(integrator.index);
        setIntegratorPrice(integrator.index, _price);

        relayerData[_relayerAddress] = RelayerData(integrator.index);

        emit IntegratorConfigured(integratorCount, _name, _relayerAddress, _dynamicRates);
        integratorCount++;
    }

    /**
     * @notice Acitvates an already existing integrator
     * @dev It's called within setupIntegrator
     *
     * @dev It can only be called by an integrator admin
     *
     * @dev It sets both configuration status and billing status to true
     * @param _integratorIndex index of the integrator in question
     */
    function activateIntegrator(uint32 _integratorIndex) public onlyIntegratorAdmin {
        setConfigurationStatus(_integratorIndex, true);
        setBillingStatus(_integratorIndex, true);
        emit IntegratorActivated(_integratorIndex);
    }

    /**
     * @notice Disables an integrator
     * @dev It can only be called by an integrator admin
     *
     * @dev It sets both configuration status and billing status to false
     * @param _integratorIndex index of the integrator in question
     */
    function disableIntegrator(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setConfigurationStatus(_integratorIndex, false);
        setBillingStatus(_integratorIndex, false);
        emit IntegratorDisabled(_integratorIndex);
    }

    /**
     * @notice Adds a relayer to an integrator
     * @dev It can only be called by an integrator admin
     * @param _relayerAddress address to be added as a relayer
     * @param _integratorIndex index of the integrator in question
     */
    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external onlyIntegratorAdmin {
        relayerData[_relayerAddress] = RelayerData(_integratorIndex);
        emit RelayerAdded(_relayerAddress, _integratorIndex);
    }

    /**
     * @notice Detaches a relayer from an integrator
     * @dev It can only be called by an integrator admin
     * @param _relayerAddress address to be detached from an integrator
     */
    function removeRelayer(address _relayerAddress) external onlyIntegratorAdmin {
        emit RelayerRemoved(_relayerAddress, relayerData[_relayerAddress].integratorIndex);
        delete relayerData[_relayerAddress];
    }

    /**
     * @notice Updates an integrator's dynamic rates
     * @param  _integratorIndex the index of the integrator to update
     * @param  _dynamicRates array containing all the dyanmic rates
     */
    function setDynamicRates(uint32 _integratorIndex, DynamicRates calldata _dynamicRates)
        external
        onlyIntegratorAdmin
    {
        integratorRates[_integratorIndex] = _dynamicRates;
        emit UpdateDynamicRates(_integratorIndex, _dynamicRates);
    }

    /**
     * @notice Updates the protocol rates
     * @param  _protocolRates array containing all the dyanmic rates
     */
    function setProtocolRates(DynamicRates calldata _protocolRates) public onlyOwner {
        protocolRates = _protocolRates;
        emit UpdateProtocolRates(_protocolRates);
    }

    /**
     * @notice Updates the destination address for the sales tax fuel collection
     * @param  _salesTaxFuelDestination destination address
     */
    function setSalesTaxFuelDestination(address _salesTaxFuelDestination) public onlyOwner {
        salesTaxFuelDestination = _salesTaxFuelDestination;
        emit UpdateSalesTaxFuelDestination(_salesTaxFuelDestination);
    }

    /**
     * @notice Enables billing on an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of the integrator in question
     */
    function enableIntegratorBilling(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setBillingStatus(_integratorIndex, true);
        emit EnableIntegratorBilling(_integratorIndex);
    }

    /**
     * @notice Disables billing on an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of the integrator in question
     */
    function disableIntegratorBilling(uint32 _integratorIndex) external onlyIntegratorAdmin {
        setBillingStatus(_integratorIndex, false);
        emit DisableIntegratorBilling(_integratorIndex);
    }

    /**
     * @notice Sets the basic tax rate
     * @dev The basic tax rate is a global variable used to calculate fuel to be taxed on basic actions
     *
     * @dev It can only be called by the contract owner
     * @param _basicTaxRate basic tax rate x10^6
     */
    function setBasicTaxRate(uint24 _basicTaxRate) public onlyOwner {
        require(_basicTaxRate >= 0, "Economics: invalid tax rate");
        emit UpdateBasicTaxRate(basicTaxRate, _basicTaxRate);
        basicTaxRate = _basicTaxRate;
    }

    /**
     * @notice Sets the address for the fuel token; typically $GET
     * @dev It can only be called by the contract owner
     * @param _fuelToken contract address of fuel token
     */
    function setFuelToken(address _fuelToken) external onlyOwner {
        emit UpdateFuelToken(address(fuelToken), _fuelToken);
        fuelToken = IERC20(_fuelToken);
    }

    /**
     * @notice Resets the spentFuel balance.
     * @dev The function is useful for resetting the balance if it doesn't reflect what has been truely collected
     *
     * @dev It can only be called by the contract owner
     * @param _spentFuel spent fuel value
     */
    function setSpentFuel(SpentFuel calldata _spentFuel) external onlyOwner {
        require(_spentFuel.total > 0, "Economics: new balance invalid");
        require(_spentFuel.protocol > 0, "Economics: new balance invalid");
        emit UpdateSpentFuel(_spentFuel);
        spentFuel = _spentFuel;
    }

    /**
     * @notice Withdraws an asset on this contract to a given address
     * @dev This becomes usefull when migrating an Economics contract to another
     *
     * @dev It can only be called by the contract owner
     * @param _asset contract address of a particular asset
     * @param _to address the asset is sent to
     * @param _amount amount of the asset to be sent
     */
    function emergencyWithdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_asset).transfer(_to, _amount);
    }

    /**
     * @notice Sets the billing status of an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of integrator in question
     * @param _status billing status; boolean
     */
    function setBillingStatus(uint32 _integratorIndex, bool _status) public onlyIntegratorAdmin {
        integratorData[_integratorIndex].isBillingEnabled = _status;
        emit BillingStatusUpdated(_integratorIndex, _status);
    }

    /**
     * @notice Sets the configuration status of an integrator
     * @dev It can only be called by an integrator admin
     * @param _integratorIndex index of integrator in question
     * @param _status configuration status; boolean
     */
    function setConfigurationStatus(uint32 _integratorIndex, bool _status) public onlyIntegratorAdmin {
        integratorData[_integratorIndex].isConfigured = _status;
        emit ConfigurationStatusUpdated(_integratorIndex, _status);
    }

    /**
     * @notice Sets the active ticket count for an integrator
     * @dev It can only be called by an integrator admin
     *
     * @dev usefull in porting contract states between Economics contracts
     * @param _integratorIndex index of integrator in question
     * @param _activeTicketCount number of active tickets for an integrator
     */
    function setIntegratorTicketCount(uint32 _integratorIndex, uint32 _activeTicketCount) external onlyIntegratorAdmin {
        integratorData[_integratorIndex].activeTicketCount = _activeTicketCount;
        emit UpdateIntegratorTicketCount(_integratorIndex, _activeTicketCount);
    }

    /**
     * @notice Sets the average top up price for an integrator
     * @dev It can only be called by an integrator admin
     *
     * @dev usefull in porting contract states between Economics contracts
     * @param _integratorIndex index of integrator in question
     * @param _price integrator average top up price
     */
    function setIntegratorPrice(uint32 _integratorIndex, uint256 _price) public onlyIntegratorAdmin {
        require(_price > 0, "Economics: price must be greater than 0");
        integratorData[_integratorIndex].price = _price;
        emit UpdateIntegratorPrice(_integratorIndex, _price);
    }

    /**
     * @notice Sets an Integrator's name
     * @dev It can only be called by an integrator admin
     *
     * @dev usefull in porting contract states between Economics contracts
     * @param _integratorIndex index of integrator in question
     * @param _name integrator name
     */
    function setIntegratorName(uint32 _integratorIndex, string calldata _name) external onlyIntegratorAdmin {
        integratorData[_integratorIndex].name = _name;
        emit UpdateIntegratorName(_integratorIndex, _name);
    }

    //// VIEW FUNCTIONS ////

    /**
     * @notice Internal view function to calculate the fuel per active ticket of an integrator
     * @param _integratorIndex index of integrator in question
     * @return _reservedPerTicket amount of fuel per ticket
     * @return _reservedProtocolPerTicket protocol fuel reserved per ticket
     */
    function _reservedFuelPerTicket(uint32 _integratorIndex) internal view returns (uint256, uint256) {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        uint256 _reservedPerTicket = integrator.reservedFuel / integrator.activeTicketCount;
        uint256 _reservedProtocolPerTicket = integrator.reservedFuelProtocol / integrator.activeTicketCount;
        return (_reservedPerTicket, _reservedProtocolPerTicket);
    }

    /**
     * @notice  View integrator USD balance
     * @param _integratorIndex index of integrator in question
     * @return usdBalance integrator USD balance
     */
    function viewIntegratorUSDBalance(uint32 _integratorIndex) external view returns (uint256) {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        return (integrator.availableFuel * integrator.price) / 1e18;
    }

    /**
     * @notice Internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IRegistry.sol";

/**
 * @title AuthModifiers Contract
 * @author GET Protocol
 * @notice This contract provides access control modifiers to the Auth contract
 * @dev It's implemented as an abstract contract
 */

abstract contract AuthModifiers is Initializable {
    IRegistry private registry;

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    /**
     * @dev initialization function for proxy contract
     * @param _registry the Registry contract address
     */

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init(address _registry) public initializer {
        __AuthModifiers_init_unchained(_registry);
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
    modifier onlyFactory() {
        registry.auth().hasFactoryRole(msg.sender);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEventImplementation.sol";

interface IEconomics {
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
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct SpentFuel {
        uint256 total;
        uint256 protocol;
        uint32 ticketCount;
    }

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        uint256 indexed total,
        uint256 price,
        uint256 indexed newAveragePrice,
        uint256 salesTax
    );
    event FuelReservedPrimary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event FuelReservedSecondary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event BasicTaxCharged(uint32 integratorIndex, uint32 actionCount, uint256 fuel, uint256 fuelProtocol);
    event TicketFuelEmptied(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event SpentFuelCollected(SpentFuel spentFuel);
    event SalesTaxFuelCollected(address salesTaxFuelDesintation, uint256 salesTaxFuel);
    event AccountBalanceCorrected(
        uint32 integratorIndex,
        uint256 oldAvailableFuel,
        uint256 newAvailableFuel,
        uint256 oldReservedBalance,
        uint256 newReservedBalance,
        uint256 oldReservedBalanceProtocol,
        uint256 newReservedBalanceProtocol
    );
    event UpdateBasicTaxRate(uint24 old, uint24 updated);
    event UpdateFuelToken(address old, address updated);
    event UpdateSpentFuel(SpentFuel spentFuel);
    event UpdateDynamicRates(uint32 integratorIndex, DynamicRates dynamicRates);
    event UpdateProtocolRates(DynamicRates protocolRates);
    event UpdateSalesTaxFuelDestination(address salesTaxFuelDestination);
    event IntegratorConfigured(uint32 integratorIndex, string name, address relayerAddress, DynamicRates dynamicRates);
    event IntegratorActivated(uint32 integratorIndex);
    event IntegratorDisabled(uint32 integratorIndex);
    event RelayerAdded(address relayerAddress, uint32 integratorIndex);
    event RelayerRemoved(address relayerAddress, uint32 integratorIndex);
    event BillingStatusUpdated(uint32 integeratorIndex, bool status);
    event ConfigurationStatusUpdated(uint32 integratorIndex, bool status);
    event EnableIntegratorBilling(uint32 integratorIndex);
    event DisableIntegratorBilling(uint32 integratorIndex);
    event UpdateIntegratorTicketCount(uint32 integratorIndex, uint256 activeTicketCount);
    event UpdateIntegratorPrice(uint32 integratorIndex, uint256 price);
    event UpdateIntegratorName(uint32 integratorIndex, string name);

    function fuelToken() external returns (IERC20);

    function basicTaxRate() external returns (uint24);

    function spentFuel()
        external
        returns (
            uint256,
            uint256,
            uint32
        );

    function integratorCount() external returns (uint32);

    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external returns (uint256);

    function reserveFuelPrimarySale(address _relayerAddress, IEventImplementation.TicketAction[] memory _ticketActions)
        external
        returns (uint256, uint256);

    function reserveFuelSecondarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external returns (uint256, uint256);

    function spendBasicAction(address _relayerAddress, uint32 _actionCount) external returns (uint256, uint256);

    function spendTicketReserved(address _relayerAddress, uint32 _ticketCount) external returns (uint256, uint256);

    function collectSpentFuel() external returns (uint256, uint256);

    function collectSalesTaxFuel() external;

    function correctAccountBalance(
        uint32 _integratorIndex,
        uint256 _newAvailableFuel,
        uint256 _newReservedFuel
    ) external;

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates,
        uint256 _price
    ) external;

    function activateIntegrator(uint32 _integratorIndex) external;

    function disableIntegrator(uint32 _integratorIndex) external;

    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external;

    function removeRelayer(address _relayerAddress) external;

    function setDynamicRates(uint32 _integratorIndex, DynamicRates memory dynamicRates) external;

    function setProtocolRates(DynamicRates memory dynamicRates) external;

    function setSalesTaxFuelDestination(address _salesTaxFuelDestination) external;

    function enableIntegratorBilling(uint32 _integratorIndex) external;

    function disableIntegratorBilling(uint32 _integratorIndex) external;

    function setBasicTaxRate(uint24 _basicTaxRate) external;

    function setFuelToken(address _fuelToken) external;

    function setSpentFuel(SpentFuel calldata _spentFuel) external;

    function emergencyWithdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) external;

    function setBillingStatus(uint32 _integratorIndex, bool status) external;

    function setConfigurationStatus(uint32 _integratorIndex, bool status) external;

    function setIntegratorTicketCount(uint32 _integratorIndex, uint32 _activeTicketCount) external;

    function setIntegratorPrice(uint32 _integratorIndex, uint256 _price) external;

    function setIntegratorName(uint32 _integratorIndex, string calldata _name) external;

    function viewIntegratorUSDBalance(uint32 _integratorIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventImplementation {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        UNLOCKED // 3
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
        uint8[] memory _actionCounts,
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAuth.sol";
import "./IEconomics.sol";
import "./IEventFactory.sol";
import "./IPriceOracle.sol";
import "./ITopUp.sol";

interface IRegistry {
    event UpdateAuth(address old, address updated);
    event UpdateEconomics(address old, address updated);
    event UpdateEventFactory(address old, address updated);
    event UpdatePriceOracle(address old, address updated);
    event UpdateFuelDistributor(address old, address updated);
    event UpdateTopUp(address old, address updated);
    event UpdateBaseURI(string old, string updated);

    function auth() external view returns (IAuth);

    function economics() external view returns (IEconomics);

    function eventFactory() external view returns (IEventFactory);

    function priceOracle() external view returns (IPriceOracle);

    function topUp() external view returns (ITopUp);

    function baseURI() external view returns (string memory);

    function setAuth(address _auth) external;

    function setEconomics(address _economics) external;

    function setEventFactory(address _eventFactory) external;

    function setPriceOracle(address _priceOracle) external;

    function setFuelDistributor(address _fuelDistributor) external;

    function setTopUp(address _topUp) external;

    function setBaseURI(string memory _baseURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IAuth is IAccessControlUpgradeable {
    function hasIntegratorAdminRole(address) external view;

    function hasFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasFuelDistributorRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function grantEventRole(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventFactory {
    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    event UpdatePrice(uint256 old, uint256 updated);

    function price() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint32);

    function setPrice(uint256 _price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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