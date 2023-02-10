// SPDX-License-Identifier: MIT
import "./JPEGXPool.sol";
import "./IJPEGXPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.13;

contract JPEGXController is Ownable {
    address public erc20;
    mapping(address => address) public pools;
    address[] public erc721;
    event PoolDeployed(address erc721, address erc20, address pool);
    address auctionManager;

    constructor(address _erc20) {
        erc20 = _erc20;
    }

    function deployPool(
        address _erc721
    ) public onlyOwner returns (address pool) {
        require(pools[_erc721] == address(0));
        JPEGXPool jpegxPool = new JPEGXPool(_erc721, erc20, auctionManager);
        pools[_erc721] = address(jpegxPool);
        erc721.push(_erc721);
        jpegxPool.transferOwnership(owner());
        emit PoolDeployed(_erc721, erc20, address(jpegxPool));
        return address(jpegxPool);
    }

    function erasePool(address _erc721) public onlyOwner {
        pools[_erc721] = address(0);
    }

    function getPoolFromTokenAddress(
        address _tokenAddress
    ) public view returns (address) {
        return pools[_tokenAddress];
    }

    function setAuctionManager(address _auctionManager) public onlyOwner {
        auctionManager = _auctionManager;
    }

    function getAuctionManager() public view returns (address) {
        return auctionManager;
    }

    /*** Call PoolContract - setters functions  ***/
    function setPoolAuctionManager(
        address _pool,
        address _auctionManager
    ) public onlyOwner {
        IJPEGXPool(_pool).setAuctionManager(_auctionManager);
    }

    /*** Call PoolContract - getters functions  ***/

    function getfloorprice(
        address _pool,
        uint256 _epoch
    ) public view returns (uint256) {
        return IJPEGXPool(_pool).getfloorprice(_epoch);
    }

    function getEpoch_2e(address _pool) public view returns (uint256) {
        return IJPEGXPool(_pool).getEpoch_2e();
    }

    function getSharesAtOf(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice,
        address _add
    ) public view returns (uint256) {
        IJPEGXPool(_pool).getSharesAtOf(_epoch, _strikePrice, _add);
    }

    function getAmountLockedAt(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return IJPEGXPool(_pool).getAmountLockedAt(_epoch, _strikePrice);
    }

    function getOptionAvailableAt(
        address _pool,
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return IJPEGXPool(_pool).getOptionAvailableAt(_epoch, _strikePrice);
    }

    function getEpochDuration(
        address _pool
    ) public view returns (uint256 epochduration) {
        return IJPEGXPool(_pool).getEpochDuration();
    }

    function getInterval(address _pool) public view returns (uint256 interval) {
        return IJPEGXPool(_pool).getInterval();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAuctionERCManager.sol";

/// @notice JPEGX Staking contract - NFT Option Protocol
/// @author Rems0

contract JPEGXPool is Ownable, ERC721Holder {
    /*** Constants ***/
    address public erc721;
    address public erc20;
    address public jPEGXController;
    address public auctionManager;
    bool public liquidationInterrupted = false;
    uint256 immutable epochduration = 1 days / 24;
    uint256 immutable interval = 10 * 1 days /(24*60);
    uint256 immutable firstBidRatio = 800;
    uint256 public hatching;
    /*** Owner variables ***/
    mapping(uint256 => mapping(uint256 => bool)) strikePriceAt;
    mapping(uint256 => mapping(uint256 => uint256)) premiumAt;
    mapping(uint256 => uint256) floorPriceAt;
    /*** Option relatives variables ***/
    mapping(uint256 => mapping(uint256 => uint256[])) NFTsAt;
    mapping(uint256 => mapping(uint256 => uint256)) NFTtradedAt;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) shareAtOf;
    mapping(uint256 => Option) optionAt;
    /*** Events ***/
    event Stake(
        uint256 indexed _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address indexed _writer
    );
    event ReStake(
        uint256 indexed _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address indexed _writer
    );
    event BuyOption(
        uint256 indexed _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address _writer,
        address indexed _buyer
    );
    event CoverPosition(
        uint256 indexed _epoch,
        uint256 _tokenId,
        uint256 _debt,
        address indexed _writer,
        address _buyer
    );
    event WithdrawNFT(uint256 _tokenId, address _owner);
    event ClaimPremiums(
        uint256 indexed _epoch,
        uint256 _shares,
        uint256 _premiums,
        address indexed _owner
    );
    event LiquidateNFT(
        uint256 indexed _tokenId,
        uint256 _firstPrice,
        address _writer,
        address _buyer,
        uint256 _debt
    );
    event SetFloorPrice(uint256 indexed _epoch, uint256 _floorPrice);
    event SetStrikePrice(uint256 indexed _epoch,uint256[] _strikePrices, uint256[] _floorPrices);

    struct Option {
        address writer;
        address buyer;
        uint256 sPrice;
        uint256 premium;
        uint256 epoch;
        bool covered;
        bool liquidated;
    }

    constructor(address _erc721, address _erc20, address _auctionManager) {
        hatching = block.timestamp;
        erc721 = _erc721;
        erc20 = _erc20;
        jPEGXController = msg.sender;
        auctionManager = _auctionManager;
        IERC721(erc721).setApprovalForAll(_auctionManager, true);
    }

    /*** Stakers functions ***/

    function stake(uint256 _tokenId, uint256 _strikePrice) public {
        uint256 epoch = getEpoch_2e() + 1;
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        // Transfer the NFT to the pool and write the option
        IERC721(erc721).safeTransferFrom(msg.sender, address(this), _tokenId);
        optionAt[_tokenId].sPrice = _strikePrice;
        optionAt[_tokenId].writer = msg.sender;
        optionAt[_tokenId].premium = premiumAt[epoch][_strikePrice];
        optionAt[_tokenId].epoch = epoch;
        optionAt[_tokenId].buyer = address(0);
        // Push the tokenId into a list for the epoch and increment shares of writer for the epoch
        NFTsAt[epoch][_strikePrice].push(_tokenId);
        ++shareAtOf[epoch][_strikePrice][msg.sender];
        emit Stake(
            epoch,
            _tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            msg.sender
        );
    }

    function restake(uint256 _tokenId, uint256 _strikePrice) public {
        Option memory option = optionAt[_tokenId];
        uint256 epoch = getEpoch_2e() + 1;
        require(
            block.timestamp - hatching >
                option.epoch * epochduration - 2 * interval,
            "Option has not expired"
        );
        require(option.writer == msg.sender, "You are not the owner");
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[option.epoch] <= option.sPrice ||
                option.covered ||
                option.buyer == address(0),
            "Cover your position"
        );
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        // Claim premiums if user has some to request
        if (
            shareAtOf[option.epoch][option.sPrice][msg.sender] > 0 &&
            premiumAt[option.epoch][option.sPrice] > 0
        ) {
            _claimPremiums(option.epoch, option.sPrice, msg.sender);
        }
        // Re-write the option
        optionAt[_tokenId].sPrice = _strikePrice;
        optionAt[_tokenId].premium = premiumAt[epoch][_strikePrice];
        optionAt[_tokenId].epoch = epoch;
        optionAt[_tokenId].buyer = address(0);
        NFTsAt[epoch][_strikePrice].push(_tokenId);
        ++shareAtOf[epoch][_strikePrice][msg.sender];
        emit ReStake(
            epoch,
            _tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            msg.sender
        );
    }

    function claimPremiums(uint256 _epoch, uint256 _strikePrice) public {
        require(floorPriceAt[_epoch] != 0, "Option didn't expired yet");
        uint256 shares = shareAtOf[_epoch][_strikePrice][msg.sender];
        uint256 totalPremiums = premiumAt[_epoch][_strikePrice] *
            NFTtradedAt[_epoch][_strikePrice];
        uint256 userPremiums = (totalPremiums * shares) /
            NFTsAt[_epoch][_strikePrice].length;
        shareAtOf[_epoch][_strikePrice][msg.sender] = 0;
        IERC20(erc20).transfer(msg.sender, userPremiums);
    }

    function _claimPremiums(
        uint256 _epoch,
        uint256 _strikePrice,
        address _user
    ) internal {
        require(floorPriceAt[_epoch] != 0, "Option didn't expired yet");
        uint256 shares = shareAtOf[_epoch][_strikePrice][_user];
        uint256 totalPremiums = premiumAt[_epoch][_strikePrice] *
            NFTtradedAt[_epoch][_strikePrice];
        uint256 userPremiums = (totalPremiums * shares) /
            NFTsAt[_epoch][_strikePrice].length;
        shareAtOf[_epoch][_strikePrice][_user] = 0;
        IERC20(erc20).transfer(_user, userPremiums);
    }

    function coverPosition(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            block.timestamp - hatching >
                (option.epoch + 1) * epochduration - 2 * interval,
            "Option has not expired"
        );
        require(
            floorPriceAt[option.epoch] > option.sPrice,
            "Option expired worthless"
        );
        require(option.liquidated != true, "Option already liquidated");
        require(option.buyer != address(0), "Option have not been bought");
        require(!option.covered, "Option already covered");
        // Transfer debt to option writer and set the position covered
        uint256 debt = floorPriceAt[option.epoch] - option.sPrice;
        require(IERC20(erc20).transferFrom(msg.sender, option.buyer, debt));
        optionAt[_tokenId].covered = true;
        emit CoverPosition(
            option.epoch,
            _tokenId,
            debt,
            msg.sender,
            option.buyer
        );
    }

    function withdrawNFT(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(getEpoch_2e() > option.epoch, "Epoch not finished");
        require(option.writer == msg.sender, "You are not the owner");
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[option.epoch] <= option.sPrice ||
                option.covered ||
                option.buyer == address(0),
            "Cover your position"
        );
        // Claim premiums if user has some to request
        if (
            shareAtOf[option.epoch][option.sPrice][msg.sender] > 0 &&
            premiumAt[option.epoch][option.sPrice] > 0
        ) {
            _claimPremiums(option.epoch, option.sPrice, msg.sender);
        }
        // Transfer back NFT to owner
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /*** Buyers functions ***/

    function buyOption(uint256 _strikePrice) public {
        uint256 epoch = getEpoch_2e();
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        require(
            NFTtradedAt[epoch][_strikePrice] <
                NFTsAt[epoch][_strikePrice].length,
            "All options have been bought"
        );
        require(floorPriceAt[epoch] == 0, "Option expired");
        require(
            IERC20(erc20).transferFrom(
                msg.sender,
                address(this),
                premiumAt[epoch][_strikePrice]
            )
        );
        uint256 tokenIterator = NFTsAt[epoch][_strikePrice].length -
            NFTtradedAt[epoch][_strikePrice] -
            1;
        ++NFTtradedAt[epoch][_strikePrice];
        uint256 tokenId = NFTsAt[epoch][_strikePrice][tokenIterator];
        require(
            optionAt[tokenId].buyer == address(0),
            "This option has already been bought"
        );
        optionAt[tokenId].buyer = msg.sender;
        emit BuyOption(
            epoch,
            tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            optionAt[tokenId].writer,
            msg.sender
        );
    }

    function buyAtStrike(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(option.buyer == msg.sender, "You don't own this option");
        require(getEpoch_2e() > option.epoch, "Epoch not finished");
        require(!option.covered, "Position covered");
        require(
            IERC20(erc20).transferFrom(
                msg.sender,
                option.writer,
                option.sPrice
            ),
            "Please set allowance"
        );
        require(!option.liquidated, "option already liquidated");
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function liquidateNFT(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        uint256 epoch = option.epoch;
        require(!liquidationInterrupted);
        require(
            block.timestamp - hatching >
                (option.epoch + 1) * epochduration + interval,
            "Liquidation period isn't reached"
        );
        require(
            floorPriceAt[epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[epoch] > option.sPrice,
            "Option expired worthless"
        );
        require(!option.covered, "Position covered");
        require(option.liquidated != true, "Option already liquidated");
        // Set the option to liquidated and start an auction on the NFT
        optionAt[_tokenId].liquidated = true;
        optionAt[_tokenId].writer = address(0);
        uint256 debt = floorPriceAt[epoch] - option.sPrice;
        uint256 firstBid = (floorPriceAt[epoch] * firstBidRatio) / 1000;
        IAuctionERCManager(auctionManager).start(
            erc721,
            _tokenId,
            firstBid,
            option.writer,
            option.buyer,
            debt
        );
        emit LiquidateNFT(
            _tokenId,
            firstBid,
            option.writer,
            option.buyer,
            debt
        );
    }

    /*** Auction contract ***/

    function bidAuction(uint256 _tokenId, uint256 _amount) public {
        IAuctionERCManager(auctionManager).bid(
            erc721,
            _tokenId,
            _amount,
            msg.sender
        );
    }

    function endAuction(uint256 _tokenId) public {
        require(
            IAuctionERCManager(auctionManager).end(
                erc721,
                address(this),
                _tokenId
            )
        );
        optionAt[_tokenId].liquidated = false;
        optionAt[_tokenId].covered = true;
        optionAt[_tokenId].writer = address(0);
    }

    /*** Admin functions ***/

    function setStrikePriceAt(
        uint256 _epoch,
        uint256[] memory _strikePrices,
        uint256[] memory _premiums
    ) public onlyOwner {
        require(
            _strikePrices.length == _premiums.length,
            "_strikePrices.length != _premiums.length"
        );
        for (uint256 i = 0; i != _strikePrices.length; ++i) {
            strikePriceAt[_epoch][_strikePrices[i]] = true;
            premiumAt[_epoch][_strikePrices[i]] = _premiums[i];
        }
        emit SetStrikePrice(_epoch, _strikePrices, _premiums);
    }

    function setfloorpriceAt(
        uint256 _epoch,
        uint256 _floorPrice
    ) public onlyOwner {
        require(_floorPrice > 0, "Floor price < 0");
        floorPriceAt[_epoch] = _floorPrice;
        emit SetFloorPrice(_epoch, _floorPrice);
    }

    function setAuctionManager(address _auctionManager) public onlyOwner {
        auctionManager = _auctionManager;
    }

    function setLiquidationInterrupted(
        bool _liquidationInterrupted
    ) public onlyOwner {
        liquidationInterrupted = _liquidationInterrupted;
    }

    /*** Getters ***/
    function getfloorprice(uint256 _epoch) public view returns (uint256) {
        return floorPriceAt[_epoch];
    }

    function getEpoch_2e() public view returns (uint256) {
        return (block.timestamp - hatching) / epochduration;
    }

    function getEpochDuration() public pure returns (uint256) {
        return epochduration;
    }

    function getInterval() public pure returns (uint256) {
        return interval;
    }

    function getSharesAtOf(
        uint256 _epoch,
        uint256 _strikePrice,
        address _add
    ) public view returns (uint256) {
        return shareAtOf[_epoch][_strikePrice][_add];
    }

    function getAmountLockedAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return NFTsAt[_epoch][_strikePrice].length;
    }

    function getOption(
        uint256 _tokenId
    ) public view returns (Option memory option) {
        return optionAt[_tokenId];
    }

    function getOptionAvailableAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return
            NFTsAt[_epoch][_strikePrice].length -
            NFTtradedAt[_epoch][_strikePrice];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IJPEGXPool {
    struct Option {
        address writer;
        address buyer;
        uint256 sPrice;
        uint256 premium;
        uint256 epoch;
        bool covered;
        bool liquidated;
    }

    function stake(uint256 _tokenId, uint256 _strikePrice) external;

    function restake(uint256 _tokenId, uint256 _strikePrice) external;

    function buyOption(uint256 _strikePrice) external;

    function liquidateNFT(uint256 _tokenId) external;

    function coverPosition(uint256 _tokenId) external;

    function withdrawNFT(uint256 _tokenId) external;

    function claimPremiums(uint256 _epoch, uint256 _strikePrice) external;

    function buyAtStrike(uint256 _tokenId) external;

    function bidAuction(uint256 _tokenId, uint256 _amount) external;

    function endAuction(uint256 _tokenId) external;

    /*** Admin functions ***/
    function setStrikePriceAt(
        uint256 _epoch,
        uint256[] memory _strikePrices,
        uint256[] memory _premiums
    ) external;

    function setfloorpriceAt(uint256 _epoch, uint256 _floorPrice) external;

    function setAuctionManager(address _auctionManager) external;

    /*** Getters ***/
    function getfloorprice(uint256 _epoch) external view returns (uint256);

    function getEpoch_2e() external view returns (uint256);

    function getSharesAtOf(
        uint256 _epoch,
        uint256 _strikePrice,
        address _add
    ) external view returns (uint256);

    function getOption(
        uint256 _tokenId
    ) external view returns (Option memory option);

    function getAmountLockedAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) external view returns (uint256);

    function getOptionAvailableAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) external view returns (uint256);

    function getEpochDuration() external view returns (uint256 epochduration);

    function getInterval() external view returns (uint256 interval);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAuctionERCManager {
    event Start(uint256 _nftId, uint256 startingBid);
    event End(address actualBidder, uint256 highestBid);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);

    function start(
        address _tokenAddress,
        uint256 _nftId,
        uint256 _startingBid,
        address _optionWriter,
        address _optionOwner,
        uint256 _debt
    ) external;

    function bid(
        address _tokenAddress,
        uint256 _nftId,
        uint256 _bidAmount,
        address _user
    ) external;

    //  Users can retract at any times if they aren't the actual bidder
    function withdraw(address _user) external;

    // End auction
    function end(
        address _tokenAddress,
        address _pool,
        uint256 _nftId
    ) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}