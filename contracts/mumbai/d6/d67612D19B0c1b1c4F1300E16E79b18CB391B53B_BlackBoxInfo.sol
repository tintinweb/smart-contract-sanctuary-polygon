//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBlackBox.sol";

contract BlackBoxInfo is Ownable {
    struct UserInfo {
        uint256[] positionIndexBought;
        uint256 feeTokenRewards;
        uint256 platformTokenRewards;
    }

    mapping(address => UserInfo) public addressToUserInfo;

    address public blackBox;
    bool public isSetBlackBox;

    event AddPositionIndexBought(
        address indexed userAddress,
        uint256 indexed roundId
    );

    event AddFeeTokenRewards(address indexed userAddress, uint256 amount);
    event AddPlatformTokenRewards(address indexed userAddress, uint256 amount);

    function addPositionIndexBought(address _userAddress, uint256 _roundId)
        external
    {
        require(msg.sender == blackBox);
        addressToUserInfo[_userAddress].positionIndexBought.push(_roundId);
        emit AddPositionIndexBought(_userAddress, _roundId);
    }

    function setBlackBoxAddress(address _blackBoxAddress) external onlyOwner {
        require(!isSetBlackBox, "Already setBlackBox");
        isSetBlackBox = true;
        blackBox = _blackBoxAddress;
    }

    function setFeeTokenRewards(address _userAddress, uint256 _amount)
        external
        returns (bool)
    {
        require(msg.sender == blackBox, "Not from blackbox contract");
        addressToUserInfo[_userAddress].feeTokenRewards = _amount;
        return true;
    }

    function setPlatformTokenRewards(address _userAddress, uint256 _amount)
        external
        returns (bool)
    {
        require(msg.sender == blackBox, "Not from blackbox contract");
        addressToUserInfo[_userAddress].platformTokenRewards = _amount;
        return true;
    }

    function addFeeTokenRewards(address _userAddress, uint256 _amount)
        external
        returns (bool)
    {
        require(msg.sender == blackBox, "Not from blackbox contract");
        addressToUserInfo[_userAddress].feeTokenRewards += _amount;
        emit AddFeeTokenRewards(_userAddress, _amount);
        return true;
    }

    function addPlatformTokenRewards(address _userAddress, uint256 _amount)
        external
        returns (bool)
    {
        require(msg.sender == blackBox, "Not from blackbox contract");
        addressToUserInfo[_userAddress].platformTokenRewards += _amount;
        emit AddPlatformTokenRewards(_userAddress, _amount);
        return true;
    }

    function getFeeTokenRewardsByAddress(address _userAddress)
        external
        view
        returns (uint256)
    {
        return addressToUserInfo[_userAddress].feeTokenRewards;
    }

    function getPlatformTokenRewardsByAddress(address _userAddress)
        external
        view
        returns (uint256)
    {
        return addressToUserInfo[_userAddress].platformTokenRewards;
    }

    function getPositionIndexesBoughtByAddress(address _userAddress)
        external
        view
        returns (uint256[] memory)
    {
        return addressToUserInfo[_userAddress].positionIndexBought;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlackBox {
    enum STATUS {
        OPEN,
        CLOSED
    }
    struct RoundDetail {
        uint256 roundId;
        uint256 deadline;
        uint256 result;
        STATUS roundStatus;
    }
    struct Position {
        address player;
        uint256 roundId;
        uint256 side;
        uint256 amount;
    }

    function addRound(uint256 _roundId, uint256 _deadline) external;

    //Buy BlackBox // USDC has 6 decimals
    function buyBlackBox(
        uint256 _amount,
        uint256 _roundIndex,
        uint256 _side
    ) external;

    function setFeeToken(address _feeTokenAddress) external;

    function setFeePercentage(uint256 _feePercentage) external;

    function setResult(uint256 _roundId, uint256 _result) external;

    function manualUpdateRewardByRoundId(uint256 _roundId) external;

    function setPlatformTokenRewardsPerRound(uint256 _rate) external;

    function withdrawAllRewards() external;

    function withdrawGas() external;

    function depositGas() external payable;

    // Get functions

    function getPositionIndexesByRoundId(uint256 _roundId)
        external
        view
        returns (uint256[] memory);

    function getLeftPositionIndexesByRoundId(uint256 _roundId)
        external
        view
        returns (uint256[] memory);

    function getRightPositionIndexesByRoundId(uint256 _roundId)
        external
        view
        returns (uint256[] memory);

    function getTotalAmountByRoundId(uint256 _roundId)
        external
        view
        returns (uint256);

    function getLeftAmountByRoundId(uint256 _roundId)
        external
        view
        returns (uint256);

    function getRightAmountByRoundId(uint256 _roundId)
        external
        view
        returns (uint256);

    // get notupdatedmatch // return lastUpdateRoundIndex, bool on isThereNotUpdate
    function getNotUpdatedRewardsRoundIndexes()
        external
        view
        returns (uint256[] memory);

    function getActiveRoundIndex()
        external
        view
        returns (uint256[] memory roundIndex);

    function getActiveRoundId()
        external
        view
        returns (uint256[] memory roundIndex);

    function getRoundDetailsByRoundIndex(uint256 _index)
        external
        view
        returns (RoundDetail memory);

    function getPositionsByPositionIndex(uint256 _index)
        external
        view
        returns (Position memory);

    function getFeePercentage() external view returns (uint256);

    function getPlatformTokenRewardsPerRound() external view returns (uint256);

    function getFirstActiveRoundIndex() external view returns (uint256);

    function getAccuFee() external view returns (uint256);
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