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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IAuctionBonus {
    function onBidMinting(address _user) external;

    function mint(address _user, uint256 _amount, bool _alsoBurn) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct Tokens {
    address feeToken;
    address credit;
    address bonus;
}

interface IAuctionFactory {
    function feeToken() external view returns (address);

    function creditToken() external view returns (address);

    function bonusToken() external view returns (address);

    function stakingTreasury() external view returns (address);

    function bidRouter() external view returns (address);

    function pools(uint256 id) external view returns (address);

    function isOperator(address _operator) external view returns (bool);

    function addUserVolume(address _user, uint256 _amount) external;

    function getTokens() external view returns (Tokens memory);

    function isPool(address _pool) external view returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IAuctionFactory.sol";

enum stat {
    Untouch,
    Valid,
    Invalid,
    Revoked
}

struct BidInfoSlim {
    address bidder;
    bytes32 bidHash;
    stat status;
}

interface IAuctionPoolSlim {
    function bid(address _bidder, uint256 _roundId, string[] calldata _ciphers, bytes32[] calldata _hash, bool _isBonus) external;

    function bidFee() external view returns (uint256);

    function factory() external view returns (IAuctionFactory);

    function alive() external view returns (bool);

    function getRoundStatus(uint256 _roundId) external view returns (uint8 _status);

    function settlementTime(uint256 _roundId) external view returns (uint256);

    function roundIdToBidListId(uint256 _roundId) external view returns (uint256);

    function highestValidBid(uint256 _roundId) external view returns (uint256);

    function roundStartTime(uint256 roundId) external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function valuedBidsLength(uint256 _bidListId) external view returns (uint256);

    function coolOffPeriodStartTime() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);

    function totalBidListCount() external view returns (uint256);

    function whichRoundInitedMyBids(uint256 bidListId) external view returns (uint256);

    function whichRoundFinalizedMyBids(uint256 bidList) external view returns (uint256);

    function pid() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function bidListLength(uint256 bidListId) external view returns (uint256);

    function faceValue() external view returns (uint256);

    function bidListSlotsDataReindexer(uint256 bidListId) external view returns (uint256);

    function SlotsData(uint256 reindexerId, uint256 slotIndex) external view returns (uint256);

    function periodOfExtension() external view returns (uint256);

    function bidsForExtension() external view returns (uint256);

    function roundExtensionChunk() external view returns (uint256);

    function extenderBids(uint256 roundId) external view returns (uint256);

    function roundExtension(uint256 roundId) external view returns (uint256);

    function extensionsHad(uint256 roundId) external view returns (uint256);

    function extensionStep() external view returns (uint256);

    function minBids()  external view returns (uint256);
}

abstract contract ISlimPool is IAuctionPoolSlim {
    mapping(uint256 => mapping(uint256 => BidInfoSlim)) public bidsList;
    mapping(uint256 => mapping(uint256 => uint256)) public bidAmounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../interfaces/IAuctionBonus.sol";

import "../../interfaces/IAuctionPoolSlim.sol";

contract BonusRewarderSlim is Ownable {
    event RewardDistributed(address user, address pool, uint256 roundId, uint256 bidId, uint256 amount);

    event AddedOperator(address _op);

    event RemovedOperator(address _op);

    bool public mode;

    IAuctionBonus public bonus;

    //pool => bidListId => bidId => is
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public isBidRewarded;

    //address => is_operator
    mapping(address => bool) public isOperator;

    constructor(address _bonus) {
        bonus = IAuctionBonus(_bonus);
        mode = true;
    }

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }

    function rewardBid(uint256 _bidId, IAuctionPoolSlim _pool, uint256 _roundId) external onlyOperator {
        uint256 _amount = _pool.bidFee();
        uint256 _bidListId = _pool.roundIdToBidListId(_roundId);
        (address _bidder, , ) = ISlimPool(address(_pool)).bidsList(_bidListId, _bidId);

        require(_bidListId != 0, "Round never initialized");

        require(!isBidRewarded[address(_pool)][_bidListId][_bidId], "Already rewarded this bid");

        isBidRewarded[address(_pool)][_bidListId][_bidId] = true;

        bonus.mint(_bidder, _amount, mode);

        emit RewardDistributed(_bidder, address(_pool), _roundId, _bidId, _amount);
    }

    /// @notice like rewardBid only bulk, will revert if 1 bid is bad
    function rewardBids(uint256[] calldata _bidIds, address _pool, uint256[] calldata _roundIds) external onlyOperator {
        ISlimPool _ipm = ISlimPool(address(_pool));
        uint256 _amount = _ipm.bidFee();
        uint256 _bidListId;
        address _bidder;
        for (uint256 i; i < _bidIds.length; ++i) {
            _bidListId = _ipm.roundIdToBidListId(_roundIds[i]);
            (_bidder, ,) = _ipm.bidsList(_bidListId, _bidIds[i]);
            require(_bidListId != 0, "Round never initialized");
            require(!isBidRewarded[_pool][_bidListId][_bidIds[i]], "Already rewarded this bid");
            isBidRewarded[_pool][_bidListId][_bidIds[i]] = true;
            bonus.mint(_bidder, _amount, mode);
            emit RewardDistributed(_bidder, _pool, _roundIds[i], _bidIds[i], _amount);
        }
    }

    /// @notice returns array of bids ids and round ids of bids that were already rewarded
    function areBidsRewarded(
        uint256[] calldata _bidIds,
        IAuctionPoolSlim _pool,
        uint256[] calldata _roundIds
    ) public view returns (uint256[] memory _rewardedBidIds, uint256[] memory _rewardedRoundIds) {
        uint256 _bidListId;
        uint256[] memory tempIndexArray = new uint256[](_bidIds.length);
        uint j;
        uint256 i;
        for (; i < _bidIds.length; ++i) {
            _bidListId = _pool.roundIdToBidListId(_roundIds[i]);
            if (isBidRewarded[address(_pool)][_bidListId][_bidIds[i]]) {
                tempIndexArray[j] = i;
                j++;
            }
        }
        i = 0;
        _rewardedBidIds = new uint256[](j);
        _rewardedRoundIds = new uint256[](j);
        while (j > 0) {
            _rewardedBidIds[i] = _bidIds[tempIndexArray[j - 1]];
            _rewardedRoundIds[i] = _roundIds[tempIndexArray[j - 1]];
            ++i;
            --j;
        }
    }

    /**
     * @notice Add operator
     *
     * @param _operator The address of the operator to add
     */
    function addOperator(address _operator) external onlyOwner {
        isOperator[_operator] = true;

        emit AddedOperator(_operator);
    }

    /**
     * @notice Remove operator
     *
     * @param _operator The address of the operator to remove
     */
    function removeOperator(address _operator) external onlyOwner {
        isOperator[_operator] = false;

        emit RemovedOperator(_operator);
    }

    /// @notice mode will decide if to burn expired user bonus tokens or not when minting him new tokens
    function setMode(bool _mode) external onlyOperator {
        mode = _mode;
    }

    /// @notice bonus
    function setBonus(IAuctionBonus _bonus) external onlyOwner {
        bonus = _bonus;
    }
}