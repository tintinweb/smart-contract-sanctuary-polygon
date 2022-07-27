/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/KeeperCompatibleInterface.sol";

//import "../libraries/v08/access/Ownable.sol";

import "../core/interfaces/IPositionManager.sol";
import "../core/interfaces/IOrderBook.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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




contract OrderBookUpkeep is Ownable, KeeperCompatibleInterface {
    IPositionManager public positionManager;
    IOrderBook public orderBook;
    address payable public _executionFeeReceiver;
    uint256 public interval;
    uint256 public lastTimeStamp;

    constructor(uint256 _updateInterval) {
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
    }

    function initialize(address _positionManager,address _orderBook) external onlyOwner {
        require(_positionManager != address(0), "Address not valid.");
        require(_orderBook != address(0), "Address not valid.");
        positionManager = IPositionManager(_positionManager);
        orderBook = IOrderBook(_orderBook);
    }

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
        lastTimeStamp = block.timestamp;
    }

    function setExecutionFeeReceiver(address payable _receiver) public onlyOwner {
        require(_receiver != address(0), "Receiver not valid.");
        _executionFeeReceiver = _receiver;
    }

    function setPositionManager(address _positionManager) public onlyOwner {
        require(_positionManager != address(0), "Address not valid.");
        positionManager = IPositionManager(_positionManager);
    }

    function setOrderBook(address _orderBook) public onlyOwner {
        require(_orderBook != address(0), "Address not valid.");
        orderBook = IOrderBook(_orderBook);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded =  ensureCheckUpdate();
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        lastTimeStamp = block.timestamp;
        executeInternal();
    }

    function ensureCheckUpdate() internal view returns (bool) {
        bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

        if ((block.timestamp - lastTimeStamp) > interval) {
            (upkeepNeeded,) = orderBook.getShouldExecuteOrderList(true);
        }
        return upkeepNeeded ;
    }

    function executeInternal() internal {
        bool shouldExecute;
        uint160[] memory orderList;
        (shouldExecute,orderList) = orderBook.getShouldExecuteOrderList(false);

        if(shouldExecute){
            uint256 orderLength = orderList.length/3;

            uint256 curIndex = 0;

            while (curIndex < orderLength) {
                address account = address(orderList[curIndex*3]);
                uint256 orderIndex = uint256(orderList[curIndex*3+1]);
                uint256 orderType = uint256(orderList[curIndex*3+2]);

                if(orderType== 0 ) {//SWAP
                    positionManager.executeSwapOrder(account,orderIndex, _executionFeeReceiver);
                }else if(orderType== 1 ) {//INCREASE
                    positionManager.executeIncreaseOrder(account,orderIndex, _executionFeeReceiver);
                }else if(orderType== 2 ) {//DECREASE
                    positionManager.executeDecreaseOrder(account,orderIndex, _executionFeeReceiver);
                }
                curIndex++;
            }

        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.9.0;

interface IPositionManager {
    function executeSwapOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeDecreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external;

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external;

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.9.0;

interface IOrderBook {
    function getSwapOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeDecreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeIncreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function getShouldExecuteOrderList(
        bool _returnFirst
    ) external view returns (
            bool ,
            uint160[] memory); 


}