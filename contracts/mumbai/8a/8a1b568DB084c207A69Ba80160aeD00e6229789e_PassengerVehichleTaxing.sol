// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
    @title A contract for Passenger Vehicle Taxing System
    @author iamenochlee
    @notice This smart contract eradicates automates bus taxes collection
    @dev A smart contract solution to passenger vehicle taxing system.
 */

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./TaxConverter.sol";

//custom errors
error PassengerVehichleTaxing__NotPermitted(string message);
error PassengerVehichleTaxing__TransactionFailed();
error PassengerVehichleTaxing__InsufficientFunds(uint256 _bal, uint256 _tax);
error PassengerVehichleTaxing__InvalidInput(
    uint256 _minRequred,
    uint256 _maxRequired
);
error PassengerVehichleTaxing__RegistrationFailed(string message);
error PassengerVehichleTaxing__DriverNotFound(string message);

contract PassengerVehichleTaxing is AutomationCompatible {
    //library
    using TaxConverter for uint256;

    //variables
    address private immutable i_owner;
    uint256 public s_tripPrice = 5;
    uint256 private s_taxRate = 2;
    uint256 public s_minVehicleCapacity = 12;
    uint256 public s_maxVehicleCapacity = 24;
    uint256 public immutable INTERVAL;
    uint256 private lastTimeStamp;
    AggregatorV3Interface private s_priceFeed;

    //struct Array

    struct Driver {
        address addr;
        uint256 passId;
        string name;
        uint8 vehicleCapacity;
        uint256 tax;
        bool isWorking;
    }

    Driver[] public s_drivers;
    Driver[] private s_defaulters;
    //mapping
    mapping(uint256 => Driver) private s_idToDriver;

    //enums
    enum Status {
        OPEN,
        CALCULATING
    }

    Status public status;
    //events
    event Registered(
        uint256 indexed _passId,
        address indexed _address,
        uint256 _vehicleCapacity
    );

    event TaxPay(
        uint256 indexed _passId,
        address indexed _address,
        uint256 _amount
    );
    event UnRegistered(uint256 indexed _passId, address indexed _address);
    event TaxCalculated();
    event Withdrawn();

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert PassengerVehichleTaxing__NotPermitted("Not Permitted");
        }
        _;
    }
    modifier onlyDriver() {
        Driver[] memory m_drivers = s_drivers;
        for (uint256 i; i < m_drivers.length; i++) {
            if (msg.sender != m_drivers[i].addr) {
                revert PassengerVehichleTaxing__NotPermitted("Not Permitted");
            }
        }
        _;
    }

    //constructor
    /** @notice This initializes parameters needed for the contract to run
        @dev A constructor function
        @param priceFeed a uinque address usee by Chainlink AggregatorV3Interface to get ETH price in USD
        @param interval the upkeep intrval
     */

    constructor(address priceFeed, uint256 interval) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
        INTERVAL = interval;
        lastTimeStamp = block.timestamp;
    }

    //functions

    /**
    @notice registers a new driver
    @dev A register function to registera driver upon passing all requirements
    @param _passId the drivers passId, a unique number
    @param _name name of driver
    @param _vehicleCapacity the maximum capacity of the drivers vehicle
    */

    function register(
        uint256 _passId,
        string memory _name,
        uint8 _vehicleCapacity
    ) public {
        /// @notice confirming if registration is open
        if (status != Status.OPEN) {
            revert PassengerVehichleTaxing__NotPermitted(
                "Cant Register at this time"
            );
        }
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        /// @dev comfirming that driver has not been registered.
        for (uint256 i = 0; i < m_drivers.length; i++) {
            if (
                m_drivers[i].addr == msg.sender ||
                m_drivers[i].passId == _passId
            ) {
                /// @notice throwing an error if the driver has already registed
                revert PassengerVehichleTaxing__RegistrationFailed(
                    "Failed to register this account"
                );
            }
        }
        /// @dev checking if the driver vehichle capacity is in the allowed range

        if (
            _vehicleCapacity < s_minVehicleCapacity ||
            _vehicleCapacity > s_maxVehicleCapacity
        )
            /// @notice throwing an error if the driver has already registed
            revert PassengerVehichleTaxing__InvalidInput(
                12,
                s_maxVehicleCapacity
            );

        /// @dev pushing driver that meets the registration requirements
        s_drivers.push(
            Driver(msg.sender, _passId, _name, _vehicleCapacity, 0, true)
        );

        /// @notice taking note of the driver in a map
        s_idToDriver[_passId] = Driver(
            msg.sender,
            _passId,
            _name,
            _vehicleCapacity,
            0,
            true
        );

        /// @notice emitting a registration event
        emit Registered(_passId, msg.sender, _vehicleCapacity);
    }

    /** @notice handles the tax
        @dev handletax function calculates and set the tax for the driver that have a working status
    */

    function handleTax() internal {
        Driver[] memory m_drivers = s_drivers;

        for (uint256 i = 0; i < m_drivers.length; i++) {
            uint256 amountToBeTaxed = s_tripPrice *
                s_drivers[i].vehicleCapacity;
            /// @dev passing amount to be taxed,rate, s_priceFeed to _getTaxInWei from PriceConverter library
            /// @return _taxAmount amount of tax in wei value
            uint256 _taxAmount = amountToBeTaxed._getTaxInWei(
                s_taxRate,
                s_priceFeed
            );
            /// @dev making sure the driver has a working status and setting the tax amount for the driver
            if (s_drivers[i].isWorking == true) {
                s_drivers[i].tax += _taxAmount;
            } else {
                s_drivers[i].tax += 0;
            }
        }
    }

    /** 
    @notice this function take notes of defaulting drivers
    @dev handleDefaulters pushes defulting drivers to an array of defaulters
 */
    function handleDefaulters() internal {
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        for (uint256 i = 0; i < m_drivers.length; i++) {
            /// @dev checking for tax
            if (m_drivers[i].tax != 0) {
                s_defaulters.push(m_drivers[i]);
            } else if (m_drivers[i].tax == 0) {
                s_defaulters[i] = s_defaulters[s_defaulters.length - 1];
                s_defaulters.pop();
            }
        }
    }

    /**@notice pays the driver tax
        @dev drivers call this functio to pay off their tax 
    */

    function payTax() public payable onlyDriver {
        /// @dev requiring the contract staus to be open
        require(status == Status.OPEN, "Undergoing Daily Calculations");
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        /// @dev _passId is needed to emit taxpayed event
        uint256 _passId;
        for (uint256 i = 0; i < m_drivers.length; i++) {
            /// @dev a check to require that the caller is a registerd driver
            if (m_drivers[i].addr == msg.sender) {
                uint256 _tax = s_drivers[i].tax;
                _passId = s_drivers[i].passId;
                /// @dev ensuring the value sent is enough to clear the driver tax
                if (msg.value != _tax) {
                    /// @notice throwing an error on insufficient funds
                    revert PassengerVehichleTaxing__InsufficientFunds(
                        address(msg.sender).balance,
                        _tax
                    );
                }
                s_drivers[i].tax = 0;
            }
        }
        /// @dev emitting taxpayed event if all conditions are met
        emit TaxPay(_passId, msg.sender, msg.value);

        ///@dev resetting defaulters array
        handleDefaulters();
    }

    /// @notice toggles driver working status
    function turnOffWorkingStatus() public onlyDriver {
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        /// @dev ensuring that the caller is a registered driver
        for (uint256 i = 0; i < m_drivers.length; i++) {
            if (m_drivers[i].addr == msg.sender) {
                /// @dev toggling the driver working status
                s_drivers[i].isWorking = false;
            }
        }
    }

    /**@notice unregisters a driver
        @dev unregitered a driver, also ensuring that the driver has paid all defaulted tax
        @param _passId thsi is needed to confirm the drivers will to uregister
     */

    function unRegister(uint256 _passId) public virtual onlyDriver {
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        for (uint256 i = 0; i < m_drivers.length; i++) {
            if (m_drivers[i].addr == msg.sender) {
                /// @dev checking to make sure the driver has paid all tax
                if (s_drivers[i].tax != 0) {
                    revert PassengerVehichleTaxing__NotPermitted(
                        "pay out pending tax"
                    );
                }
                /// @dev moving the driver to the last index
                s_drivers[i] = s_drivers[s_drivers.length - 1];
                /// @dev removing the driver
                s_drivers.pop();
                delete s_idToDriver[_passId];
            }
        }

        /// @dev emitting an unregister event
        emit UnRegistered(_passId, msg.sender);
    }

    /// @notice withdraw function, only owner can call
    function withdraw() public payable onlyOwner {
        /// @dev owner cashout, lol
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) revert PassengerVehichleTaxing__TransactionFailed();
        emit Withdrawn();
    }

    //getter functions

    /** @notice getsDriverTax
        @dev gets and returns the driver tax
        @param _passId the passid of the driver whose tax is requested
        @return tax the taxamountinwei corresponding to the driver 
     */
    function getDriverTax(uint256 _passId) public view returns (uint256) {
        /// @dev copying drivers storage to memory so as to map through at a lower gas
        Driver[] memory m_drivers = s_drivers;
        /// @dev creating a tax variable that will be assigned to the requested drivers tax
        uint256 _tax;
        for (uint256 i = 0; i < m_drivers.length; i++) {
            /// @dev checking if the driver exist user the passId
            if (m_drivers[i].passId != _passId) {
                /// @notice throwing an error if the passId is not found
                revert PassengerVehichleTaxing__DriverNotFound("");
            }
            /// @dev assigning the driver tax to tax variable
            _tax = s_drivers[i].tax;
        }
        /// @notice returning tax
        return _tax;
    }

    //getters
    /** @notice Gets a Driver using passId
     *  @param _passId the Id of the Driver and returns
     *  @return the driver struct
     */
    function getDriverWithId(
        uint256 _passId
    ) public view onlyOwner returns (Driver memory) {
        return s_idToDriver[_passId];
    }

    /**@notice getDrivers returns all drivers in an array
     *@return all Drivers
     */

    function getDrivers() public view onlyOwner returns (Driver[] memory) {
        return s_drivers;
    }

    /**  @notice all drivers count
     *   @return drivers count,  the owner calls this function to get the drivers count
     */
    function getDriversCount() public view onlyOwner returns (uint256) {
        return s_drivers.length;
    }

    /**  @notice all defaulters
     *   @return s_defaulters ,  the detailsof all defaulting drivers
     */
    function getDefaulters() public view onlyOwner returns (Driver[] memory) {
        return s_defaulters;
    }

    function getTaxRate() public view returns (uint256) {
        return s_taxRate;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    //setters
    /** @notice sets tripPrice to new trip price
     * @dev setPrice updates trip price, can only be called by the owner
     * @param _newTripPrice the new trip Price
     */
    function setPrice(uint256 _newTripPrice) public onlyOwner {
        s_tripPrice = _newTripPrice;
    }

    /** @notice sets maxVehicleCapacity to new maxVehicleCapacity
     * @dev setmaxVehicleCapacity updates s_maxVehicleCapacity, can only be called by the owner
     * @param _maxVehicleCapacity the new maximum ehicleCapacity
     */
    function setmaxVehicleCapacity(
        uint256 _maxVehicleCapacity
    ) public onlyOwner {
        s_maxVehicleCapacity = _maxVehicleCapacity;
    }

    /**  @notice sets setTaxRate to new taxRate
     * @dev setTaxRate updates s_taxRate, can only be called by the owner
     * @param _taxrate the new tax rate
     */

    function setTaxRate(uint256 _taxrate) public onlyOwner {
        s_taxRate = _taxrate;
    }

    //for testing purpose
    function tax() public onlyOwner {
        status = Status.CALCULATING;
        handleTax();
        handleDefaulters();
        emit TaxCalculated();
        status = Status.OPEN;
        // @dev ensuring that the caller is a registered driver
        for (uint256 i = 0; i < s_drivers.length; i++) {
            /// @dev resetting the count for updating working status to 0
            s_drivers[i].isWorking = true;
        }
        lastTimeStamp = block.timestamp;
    }

    //Called by Chainlink Keepers to check if work needs to be done
    function checkUpkeep(
        bytes calldata /*checkData */
    ) external returns (bool upkeepNeeded, bytes memory upKeepData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > INTERVAL;
        return (upkeepNeeded, upKeepData);
    }

    //Called by Chainlink Keepers to handle work
    function performUpkeep(bytes calldata) external {
        if ((block.timestamp - lastTimeStamp) > INTERVAL) {
            tax();
            emit TaxCalculated();
            lastTimeStamp = block.timestamp;
        } else {
            revert("cant perform upkeep");
        }
    }

    //fallback

    /**  @notice both functions handles the situation whereby the contract  is interacted with indirectly
     *   @dev a fallback function
     */

    receive() external payable {
        payTax();
    }

    fallback() external payable {
        payTax();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title A TaxConverter library
    @notice Generate tax in wei using this library
    @dev This library functions takes in arguments and returns taxamount in wei in relation to eth price in usd.
 */

library TaxConverter {
    /**
     * @notice This gets the amount of Ethereum in Wei based on ETH/USD price
        @dev This function comes from Chainlink Aggregator, giving way to get ETH price
        @param priceFeed a uinque address usee by Chainlink AggregatorV3Interface to get ETH price in USD
        @return ETH price in WEI
     */
    function _getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price / 10 ** 8);
    }

    /**
        @notice This gets calculates tax based on parameters given
        @dev This function comes from Chainlink AggregatorV3Interface giving way to get ETH price
        @param amountToBeTaxed the total amount to be taxed in USD
        @param taxRate the rate at which the tax is calculated, the given value is uded as a percentage
        @param priceFeed a uinque address usee by Chainlink AggregatorV3Interface to get
        * ETH price in USD, this address is passed to this function as it varies basedd on network.
        @return taxInWei tax amount in wei value
 */
    function _getTaxInWei(
        uint256 amountToBeTaxed,
        uint256 taxRate,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 taxAmount = ((amountToBeTaxed * taxRate) / 100);
        uint256 ethPriceInWei = _getPrice(priceFeed);
        uint256 taxInWei = ((taxAmount * 1e18) / ethPriceInWei);
        return taxInWei;
    }
}