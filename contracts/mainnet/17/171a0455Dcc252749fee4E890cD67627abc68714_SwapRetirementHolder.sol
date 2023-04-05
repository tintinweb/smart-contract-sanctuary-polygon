/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

// File: contracts/helpers/Ownable.sol



pragma solidity ^0.8.4;

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}
// File: contracts/kamixklima/keepers/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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
// File: contracts/kamixklima/keepers/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
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
// File: contracts/kamixklima/keepers/KeeperCompatible.sol



pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
// File: contracts/kamixklima/SwapRetirementHolder.sol



pragma solidity ^0.8.10;



interface IKlimaRetirementAggregator {

    function retireCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage
    ) external;
}

interface IWrappedAsset {

    function deposit() external payable;
    function balanceOf(address user) external;
    function approve(address guy, uint wad) external returns (bool);

}


contract SwapRetirementHolder is KeeperCompatibleInterface, Ownable {

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint public interval;
    uint public lastTimeStamp;
    uint public numPendingRetirementAddresses;
    bool private continueUpKeeping;

    address public WrappedNativeAssetAddress;
    address public sourceCarbonToken;
    
    IKlimaRetirementAggregator public KlimaAggregator;

    mapping (address => uint256) public pendingRetirementAmounts;
    mapping (uint256 => address) public pendingRetirees;
    mapping (address => uint256) public pendingAddressQueuePosition;

    event intervalUpdated(uint newInterval);
    event aggregatorAddressUpdated(address newAddress);
    event newPendingRetirement(address retiree, uint256 amount);
    event newCarbonTokenUpdated(address newCarbonTokenUpdate);

    constructor(address _KlimaAggregator, uint _interval, address _wrappedNativeAsset, address _carbonToken) {
        KlimaAggregator = IKlimaRetirementAggregator(_KlimaAggregator);

        // set first upkeep check at the interval from now
        lastTimeStamp = block.timestamp + _interval;

        interval = _interval;

        // set native wrapped asset address
        WrappedNativeAssetAddress = _wrappedNativeAsset;

        // set carbon token to use
        // TODO: make this dynamic on upkeep

        sourceCarbonToken = _carbonToken;
    }

    // Change Klima Aggregator address, though its upgradeable so doubtful this will change
    function setKlimaAggregator(address newAggregator) public onlyManager {
        KlimaAggregator = IKlimaRetirementAggregator(newAggregator);
    }

    // Change retirement interval, uint256 in seconds
    function setRetirementInterval(uint newInterval) public onlyManager {
        interval = newInterval;
        emit intervalUpdated(interval);
    }

    // Change source carbon token, address of erc20
    function setSourceCarbonToken(address newCarbonToken) public onlyManager {
        sourceCarbonToken = newCarbonToken;
        emit newCarbonTokenUpdated(sourceCarbonToken);
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStamp) > interval && numPendingRetirementAddresses != 0 ) {
            //lastTimeStamp = block.timestamp;

            //Start from the ending of the array until you get to 0 in case users continue to swap during the upkeep period
            address retiree = pendingRetirees[numPendingRetirementAddresses-1];
            uint amountToRetire = pendingRetirementAmounts[retiree];

            // Deposit the ETH/MATIC to WETH/WMATIC using fallback function of WETH/WMATIC
            IWrappedAsset(WrappedNativeAssetAddress).deposit{value: amountToRetire}();

            //Approve for use by aggregator
            IWrappedAsset(WrappedNativeAssetAddress).approve(address(KlimaAggregator), amountToRetire);

            // Retire tonnage using wrapped token asset; fire and forget no checks on amount

            KlimaAggregator.retireCarbon(WrappedNativeAssetAddress,sourceCarbonToken, amountToRetire, false, retiree, "Kamiswap Green Txn", "Retired using KlimaDAO x Kami Integration");

            // Reset this user's retirement pending to 0
            pendingRetirees[numPendingRetirementAddresses-1] = address(0);
            pendingRetirementAmounts[retiree] = 0;

            // Reduce counter by 1
            numPendingRetirementAddresses -= 1;



        }
        else if (((block.timestamp - lastTimeStamp) > interval && numPendingRetirementAddresses == 0)) {
            // All users have been retired, reset interval
            lastTimeStamp = block.timestamp;

        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
    // Admin override in case of odd behavior.

    function storePendingRetirement(uint256 amountToStore, address addressToStore) public onlyManager {
        if (pendingRetirementAmounts[addressToStore] == 0){
            pendingRetirees[numPendingRetirementAddresses] = addressToStore;
            pendingRetirementAmounts[addressToStore] += amountToStore;
            numPendingRetirementAddresses += 1;
        }
        else {
            pendingRetirementAmounts[addressToStore] += amountToStore;
        }
        require(pendingRetirementAmounts[addressToStore] != 0, "Pending Retirement Record Failed: Pending amount is 0");
        

    }

    // Replace a pending address with a new address, this is handy because the retirement side of Toucan refuses to send
    // ERC721s to non receiving addresses (aka most smart contracts) and may end up breaking from time to time as a result

    function replaceAddressInPendingRetirement(address oldAddress, address replacementAddress) public onlyManager {

        require(pendingRetirementAmounts[oldAddress] != 0, "No pending retirement found");
        pendingRetirees[pendingAddressQueuePosition[oldAddress]] = replacementAddress;



    }


    // This nifty contract makes use of the fallback function to detect when native ETH/Matic or any native asset is deposited. It automatically sequesters it for retirement use.

    receive() external payable {

        if (pendingRetirementAmounts[tx.origin] == 0){
            pendingRetirees[numPendingRetirementAddresses] = tx.origin;
            pendingRetirementAmounts[tx.origin] += msg.value;
            pendingAddressQueuePosition[tx.origin] = numPendingRetirementAddresses;
            numPendingRetirementAddresses += 1;
        }
        else {
            pendingRetirementAmounts[tx.origin] += msg.value;
        }
        require(pendingRetirementAmounts[tx.origin] != 0, "Pending Retirement Record Failed: Pending amount is 0");

    }

     fallback() external payable {

        if (pendingRetirementAmounts[tx.origin] == 0){
            pendingRetirees[numPendingRetirementAddresses] = tx.origin;
            pendingRetirementAmounts[tx.origin] += msg.value;
            pendingAddressQueuePosition[tx.origin] = numPendingRetirementAddresses;
            numPendingRetirementAddresses += 1;
        }
        else {
            pendingRetirementAmounts[tx.origin] += msg.value;
        }
        require(pendingRetirementAmounts[tx.origin] != 0, "Pending Retirement Record Failed: Pending amount is 0");


    }



}