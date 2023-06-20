// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import "../../../contracts/interfaces/IEconomicsFactory.sol";

contract EconomicsFactoryMock {
    constructor() {}

    function returnIntegratorEconomicsAddressOfConfiguredIntegrator(
        uint256 _integratorIndex
    ) public pure returns (address integratorEconomicsAddress_) {
        integratorEconomicsAddress_ = address(0x1);
    }

    function returnDynamicRatesOfIntegrator(
        uint256 _integratorIndex
    ) public pure returns (IEconomicsFactory.DynamicRates memory rates_) {
        rates_ = IEconomicsFactory.DynamicRates(1, 2, 3, 4, 5, 6, 7);
    }
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