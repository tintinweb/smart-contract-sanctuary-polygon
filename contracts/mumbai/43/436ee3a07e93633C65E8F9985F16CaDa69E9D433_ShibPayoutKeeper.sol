// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPharoCover {
    function payoutActivePoliciesForCurrentPharo() external;
    // function mintObelisk(address treasury, bytes memory data) external;
}

interface ITokenPriceFeed {
    function latestRoundData() external 
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function requestValue() external;
}


contract ShibPayoutKeeper is KeeperCompatibleInterface, Ownable {
    IPharoCover private _pharoCoverInterface;
    ITokenPriceFeed private _tokenPriceFeed;

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public interval = 60;
    uint public lastTimeStamp;

    mapping(uint256 => uint256) public answers;

    event PayoutTriggered(uint256 atRoundId, uint256 atPrice);
    event Debug();

    constructor(address pharoCoverAddress, address priceFeedAddress) public {
        lastTimeStamp = block.timestamp;
        _pharoCoverInterface = IPharoCover(pharoCoverAddress);
        _tokenPriceFeed = ITokenPriceFeed(priceFeedAddress);
    }

    function updateInterval(uint newInterval) public onlyOwner {
        interval = newInterval;
    }

    function checkUpkeep
    (
        bytes calldata checkData
    ) 
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;       
        //uint256 percentage = 500;
        // answers[uint256(roundId)] = uint256(answer);
        // uint256(answer);
        // uint256 prevPrice = answers[roundId] - 1;
        // 5% swing in 1 hour/3600000 ms will trigger a payout on all policies 
        // covering this event.
        //uint256 lowLimit = prevPrice - (prevPrice / percentage) * 100;
        // check if we need to perform upkeep
        // if(uint256(answer) < lowLimit) {
        //     upkeepNeeded = true;
        // }
        
        // if(upkeepNeeded) { 
        //     // set up the performData to send to performUpkeep
        //     performData = abi.encodePacked(uint256(answer), uint256(roundId), updatedAt);
        //     // return (upkeepNeeded, performData);
        // }

        // force upkeep for test/debug
        //upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata performData) external override {
        // get the latest round data
        //(uint80 roundId, int256 answer,,, ) = _tokenPriceFeed.latestRoundData();

        _pharoCoverInterface.payoutActivePoliciesForCurrentPharo();

        // emit PayoutTriggered(roundId, uint256(answer));
        emit Debug();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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