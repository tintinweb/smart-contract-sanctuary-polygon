// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Airbnb.sol";
/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract Counter is AutomationCompatibleInterface {
    AirBNB private airbnb;
    uint public counter;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(address _airbnb,uint updateInterval) {
        interval = updateInterval;
        airbnb = AirBNB(_airbnb);

        counter = 0;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint length = airbnb.checkAndreturn();
        upkeepNeeded = length>0;
        
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        
        airbnb.transfer_money_To_propertyOwner();
      
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
pragma solidity ^0.8.0;

contract AirBNB is Ownable{
    using Counters for Counters.Counter; 
    Counters.Counter public _tokenIdCounter;
    Counters.Counter public IdtoBooking;

    struct PropertyDetails {
        address propertyOwner;
        string details;
        bool isBooked;
        uint PricePerDay;
    }

    struct BookingDetails{
        uint propertyId;
        address customerAddress;
        uint duration;
        uint startTimeStamp;
        uint endTimeStamp;
        uint bookingAmount;
        mapping(address => uint) Balance;
    }
    address counterAddress;
    

    /// only owner can call this function
    error onlyowner();

    ///property is booked 
    error checkStatus();

    ///not having enough ether
    error insufficientBalance();

    ///failed to send balance
    error failedToTrnasfer();

    ///only customer can call this function
    error onlyCustomer();

    event addProperty(address propertyOwner,string details,
    bool isBooked,uint PricePerDay);

    event bookProperty(
        uint propertyId,address customerAddress,
        uint duration,uint startTimeStamp,uint endTimeStamp,
        uint amount,uint Balance);
    

    modifier isBooked(uint propertyId){
        PropertyDetails memory property = PropertyDetailsId[propertyId];
        if( property.isBooked){
            revert checkStatus();
        }
        _;
    }

    modifier OnlyOwner(uint propertyId){
        PropertyDetails memory property = PropertyDetailsId[propertyId];
        if(property.propertyOwner != msg.sender){
              revert onlyowner();
        }
        _;
    }

    modifier onlycustomerOwner(address customerAddress){
        BookingDetails storage _bookingdetails = bookingdetails[customerAddress];
        if(_bookingdetails.customerAddress!=customerAddress){
            revert onlyCustomer();
        }
        _; 
    }

    mapping (address => BookingDetails) public bookingdetails;
    mapping (uint =>PropertyDetails) public PropertyDetailsId;
    mapping (uint => address) idToBookingAddress;
    

   
    function addPropety(string memory propertDetails,
    uint _peicePerDay) public {
        _tokenIdCounter.increment();
        uint count = _tokenIdCounter.current();
        PropertyDetails storage addnewProPerty = PropertyDetailsId[count];
        addnewProPerty.propertyOwner = msg.sender;
        addnewProPerty.details= propertDetails;
        addnewProPerty.isBooked= false;
        addnewProPerty.PricePerDay = _peicePerDay;
        
        emit addProperty(addnewProPerty.propertyOwner,addnewProPerty.details
        ,addnewProPerty.isBooked,addnewProPerty.PricePerDay);
        

    }

    function BookyourProperty(uint propertyId,uint duration) public payable isBooked(propertyId){
        IdtoBooking.increment();
        uint count = IdtoBooking.current();
       PropertyDetails storage property = PropertyDetailsId[propertyId];
       if(msg.value<property.PricePerDay * duration){
           revert insufficientBalance();
       }
       property.isBooked = true;
      

    
       BookingDetails storage _bookingdetails = bookingdetails[msg.sender];
      
       _bookingdetails.propertyId = propertyId;
       _bookingdetails.customerAddress = msg.sender;
       _bookingdetails.duration = duration;
       _bookingdetails.startTimeStamp = block.timestamp;
       _bookingdetails.endTimeStamp = block.timestamp + duration;
       idToBookingAddress[count] = msg.sender;
       
       uint amount  = (msg.value * 5)/100;
       (bool success,) = owner().call{value:amount}("");
       if(!success){
          revert failedToTrnasfer();
       }
       _bookingdetails.bookingAmount = (msg.value * 95)/100;
       _bookingdetails.Balance[PropertyDetailsId[propertyId].propertyOwner] = _bookingdetails.bookingAmount;
       uint Balance =_bookingdetails.Balance[PropertyDetailsId[propertyId].propertyOwner]; 

       emit bookProperty(_bookingdetails.propertyId,
       _bookingdetails.customerAddress,
       _bookingdetails.duration,
       _bookingdetails.startTimeStamp,
       _bookingdetails.endTimeStamp,
       _bookingdetails.bookingAmount,
       Balance);
    }

    function updatePropertyDetailes (
        uint propertyId,string memory
        _propertyDetails,uint _pricePerDay) public OnlyOwner( propertyId) isBooked(propertyId){
        PropertyDetails storage updateproperty = PropertyDetailsId[propertyId];
      
        updateproperty.details = _propertyDetails;
      
        updateproperty.PricePerDay = _pricePerDay;
    }

    function cancelBooking(address bookingId) public onlycustomerOwner(bookingId){
         BookingDetails storage _bookingdetails = bookingdetails[bookingId];
         PropertyDetails memory _propertyDetails = PropertyDetailsId[_bookingdetails.propertyId];
         uint dutationleft = _bookingdetails.endTimeStamp - _bookingdetails.startTimeStamp;
         uint amountRemain =  _bookingdetails.bookingAmount - dutationleft * _propertyDetails.PricePerDay;
         (bool success,) = _bookingdetails.customerAddress.call{value:amountRemain}("");
         if(!success){
             revert failedToTrnasfer();
         }
         delete bookingdetails[bookingId];
    }

    function transfer_money_To_propertyOwner() external {
        if(msg.sender != counterAddress){
            revert();
        }
        uint count = IdtoBooking.current();
        uint currentIndex=0;
      
        for(uint i = 0;i<count;i++){
            currentIndex = 1+i;
           address bookingAddress = idToBookingAddress[currentIndex];
           BookingDetails storage _bookingDetails = bookingdetails[bookingAddress];
           if(block.timestamp > _bookingDetails.endTimeStamp){
            //    _bookingDetails.isBooked = false;
               
               PropertyDetails memory _Propertydetails = PropertyDetailsId[_bookingDetails.propertyId];
               _Propertydetails.isBooked = false;
               address propertyOwner = _Propertydetails.propertyOwner;
               uint amount= _bookingDetails.Balance[propertyOwner];
               (bool success,) = propertyOwner.call{value:amount}("");
               if(!success){
                   revert failedToTrnasfer();
               } 
               _bookingDetails.Balance[propertyOwner] = 0;

           }

        }
       
    }

    

    function delistProperty(uint propertyId) public OnlyOwner(propertyId){
           delete PropertyDetailsId[propertyId];
    }


    function checkAndreturn() public view returns(uint){
        uint count = IdtoBooking.current();
        uint currentIndex=0;
        uint currentId = 0;
        for(uint i = 0;i<count;i++){
            currentIndex = 1+i;
           address bookingAddress = idToBookingAddress[currentIndex];
           BookingDetails storage bookingDetails = bookingdetails[bookingAddress];
           if(block.timestamp > bookingDetails.endTimeStamp){
               currentId++;
           }

        }
        return currentId;

        
        

    }

    function get_List_of_all_Property() external view returns(PropertyDetails[] memory,uint){
        uint count  = _tokenIdCounter.current();
        uint currentIndex = 0;
        uint currentId = 0;
        PropertyDetails[] memory property = new PropertyDetails[](count);  
        for(uint i=0;i<property.length;i++){
            currentIndex =i+1;
            PropertyDetails storage propertyList = PropertyDetailsId[currentIndex];
            property[currentId] = propertyList;
            currentId+=1;
        }
        return (property,property.length);
    }

    function get_list_of_rented_property() external view returns(PropertyDetails[] memory,uint){
        uint count = _tokenIdCounter.current();
        uint currentIndex = 0;
        uint currentId = 0;
        for(uint i = 0;i<count;i++){
            currentIndex = i+1;
            if(PropertyDetailsId[currentIndex].isBooked){
                currentId++;
            }

        }
        PropertyDetails[] memory property = new PropertyDetails[](currentId);
        currentIndex = 0;
        currentId = 0;
        for(uint i=0;i<count;i++){
            currentIndex= i+1;
            PropertyDetails storage propertyList = PropertyDetailsId[currentIndex];
            if(propertyList.isBooked){
            property[currentId] = propertyList;
            currentId++;
            }
        }
        return (property,property.length);
    }

    function property_available_for_rent() external view returns(PropertyDetails[] memory,uint){
        uint count = _tokenIdCounter.current();
        uint currentIndex = 0;
        uint currentId = 0;
        for(uint i = 0;i<count;i++){
            currentIndex = i+1;
            if(!PropertyDetailsId[currentIndex].isBooked){
                currentId++;
            }

        }
        PropertyDetails[] memory property = new PropertyDetails[](currentId);
        currentIndex = 0;
        currentId = 0;
        for(uint i=0;i<count;i++){
            currentIndex= i+1;
            PropertyDetails storage propertyList = PropertyDetailsId[currentIndex];
            if(!propertyList.isBooked){
            property[currentId] = propertyList;
            currentId++;
            }
        }
        return (property,property.length);
    }

    function setCounterAddress(address _counter) external onlyOwner{
        counterAddress = _counter;
    }

    

    
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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