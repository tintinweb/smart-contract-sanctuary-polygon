pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./TimeLock.sol";

contract Auctionv9 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event NewAuctionCreated(
        uint256[] tokenIds,
        address imxNftAddress,
        uint256 endTime,
        IERC20Upgradeable paymentToken,
        uint256 price,
        bytes32 merkleRoot
    );

    event onBuyOrBid(
        uint256 indexed auctionId,
        address imxNftAddress,
        uint256 price,
        uint256 buyDate,
        uint256 endSaleDate,
        uint256 tokenId,
        AuctionType auctionType
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256[] tokenIds,
        address[] winnerAddresses
    );

    enum AuctionType {
        BID,
        BUYNOW,
        STAKE
    }

    struct Bid {
        uint256 amt;
        address userAddress;
    }

    /*
        Auction Details.
        tokenBid[tokenId] = indicate all Bid Placed for a particular tokenId if imxNftAddress collection.
                            also,
                                 for i = 0..len-1
                                    this condition hold (tokenBid[tokenId][i] < tokenBid[tokenId][i+1].
        createdAt = Auction Creation time.
        imxNftAddress = collection address of imx.
        endTime: Auction end timestamp.
    */
    struct Auctions {
        mapping(uint256 => Bid[]) tokenBid;
        uint256[] tokenIds;
        string name;
        uint256 createdAt;
        address imxNftAddress;
        uint256 startTime;
        uint256 endTime;
        bool isEnded;
        uint256 price;
        AuctionType auctionType;
        IERC20Upgradeable paymentToken;
        bytes32 merkleRoot;
        uint256 largestBidLength;
    }

    // List of Auctions, auctionId is index of auctionDetails[] array.
    Auctions[] public auctionsDetails;

    //Winner bid amount goes to withdrawalAddress when auction is ended/
    address public withdrawAddress;

    uint256 public constant fifteenMinute = 15 * 60;

    modifier onlyIfAuctionExist(uint256 auctionId) {
        require(auctionId < auctionsDetails.length);
        _;
    }

    modifier checkForBuyAuction(Auctions storage _auc, uint256 tokenId) {
        require(
            _auc.startTime < block.timestamp &&
                _auc.endTime > block.timestamp &&
                checkTokenIdExist(_auc, tokenId)
        );
        _;
    }

    modifier checkForBidAuction(uint256 auctionId, uint256 _tokenId) {
        require(
            auctionsDetails[auctionId].startTime < block.timestamp &&
                auctionsDetails[auctionId].endTime +
                    tokenToTotalBid[auctionId][_tokenId] *
                    TimeExtendOnBid >
                block.timestamp &&
                checkTokenIdExist(auctionsDetails[auctionId], _tokenId)
        );
        _;
    }

    function initialize(address _withdrawAddress) external initializer {
        __Ownable_init();
        withdrawAddress = _withdrawAddress;
    }

    function startNewAuctions(
        string memory name,
        uint256[] memory tokenIds,
        address imxNftAddress,
        uint256 startTime,
        uint256 endTime,
        IERC20Upgradeable paymentToken,
        uint256 price,
        AuctionType auctionType,
        bytes32 merkleRoot
    ) external onlyOwner {
        require(endTime > block.timestamp);
        Auctions storage _auc = auctionsDetails.push();
        _auc.createdAt = block.timestamp;
        _auc.name = name;
        _auc.tokenIds = tokenIds;
        _auc.imxNftAddress = imxNftAddress;
        _auc.startTime = startTime;
        _auc.endTime = endTime;
        _auc.paymentToken = paymentToken;
        _auc.price = price;
        _auc.auctionType = auctionType;
        _auc.merkleRoot = merkleRoot;
        _auc.isEnded = false;

        emit NewAuctionCreated(
            tokenIds,
            imxNftAddress,
            endTime,
            paymentToken,
            price,
            merkleRoot
        );
    }

    function findUserBidIndex(
        Bid[] memory bids,
        address user
    ) internal pure returns (int256) {
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].userAddress == user) {
                return int256(i);
            }
        }
        return -1;
    }

    // Before calling this function approve rumToken amt to this address.
    function placeBid(
        uint256 auctionId,
        uint256 tokenId,
        uint256 amt,
        bytes32[] memory proof
    )
        external
        onlyIfAuctionExist(auctionId)
        checkForBidAuction(auctionId, tokenId)
    {
        Auctions storage _auc = auctionsDetails[auctionId];
        require(
            _auc.auctionType == AuctionType.BID ||
                _auc.auctionType == AuctionType.STAKE,
            "Can't place bid."
        );
        if (_auc.merkleRoot != bytes32(0)) {
            require(
                MerkleProofUpgradeable.verify(
                    proof,
                    _auc.merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "You're not allowed."
            );
        }
        Bid[] storage bids = _auc.tokenBid[tokenId];
        uint256 size = bids.length;
        _auc.paymentToken.safeTransferFrom(msg.sender, address(this), amt);
        if (size == 0) {
            require(amt >= _auc.price, "Amount should be greater than price");
            bids.push(Bid({amt: amt, userAddress: msg.sender}));
        } else {
            uint256 highestBidAmount = bids[size - 1].amt;
            int256 index = findUserBidIndex(bids, msg.sender);
            if (index != -1) {
                require(
                    highestBidAmount < bids[uint256(index)].amt + amt,
                    "Bid amount should be greater than hightest bid"
                );
                require(
                    bids[size - 1].userAddress != msg.sender,
                    "You already made a bid"
                );
                // swap highest bid to the last index for quickly query highest bid for further bid.
                Bid memory temp = bids[size - 1];
                bids[size - 1] = bids[uint256(index)];
                bids[uint256(index)] = temp;
                bids[size - 1].amt += amt;
            } else {
                require(
                    highestBidAmount < amt,
                    "Bid amount should be greater than hightest bid"
                );
                bids.push(Bid({amt: amt, userAddress: msg.sender}));
            }
        }
        tokenToTotalBid[auctionId][tokenId]++;
        uint256 totalBidLength = tokenToTotalBid[auctionId][tokenId];
        _auc.largestBidLength = _auc.largestBidLength < totalBidLength
            ? totalBidLength
            : _auc.largestBidLength;

        emit onBuyOrBid(
            auctionId,
            _auc.imxNftAddress,
            amt,
            block.timestamp,
            _auc.endTime + totalBidLength * TimeExtendOnBid,
            tokenId,
            _auc.auctionType
        );
        emit onBuyOrBid2(
            auctionId,
            _auc.imxNftAddress,
            amt,
            block.timestamp,
            _auc.endTime + totalBidLength * TimeExtendOnBid,
            tokenId,
            _auc.auctionType,
            msg.sender
        );
    }

    function buyNow(
        uint256 auctionId,
        uint256 tokenId,
        bytes32[] memory proof
    )
        external
        onlyIfAuctionExist(auctionId)
        checkForBuyAuction(auctionsDetails[auctionId], tokenId)
    {
        Auctions storage _auc = auctionsDetails[auctionId];
        require(_auc.auctionType == AuctionType.BUYNOW);
        if (_auc.merkleRoot != bytes32(0)) {
            require(
                MerkleProofUpgradeable.verify(
                    proof,
                    _auc.merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "You're not allowed."
            );
        }
        Bid[] storage bids = _auc.tokenBid[tokenId];
        uint256 size = bids.length;
        require(size == 0, "Already bought");
        _auc.paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            _auc.price
        );
        bids.push(Bid({amt: _auc.price, userAddress: msg.sender}));
        emit onBuyOrBid(
            auctionId,
            _auc.imxNftAddress,
            _auc.price,
            block.timestamp,
            block.timestamp,
            tokenId,
            _auc.auctionType
        );
        emit onBuyOrBid2(
            auctionId,
            _auc.imxNftAddress,
            _auc.price,
            block.timestamp,
            block.timestamp,
            tokenId,
            _auc.auctionType,
            msg.sender
        );
    }

    function endAuction(uint256 auctionId) public onlyOwner {
        Auctions storage _auc = auctionsDetails[auctionId];
        require(
            !_auc.isEnded &&
                _auc.endTime + _auc.largestBidLength * TimeExtendOnBid <
                block.timestamp,
            "Auction can't be ended"
        );
        uint256[] memory tokenIds = _auc.tokenIds;
        address[] memory winnerAddresses = new address[](_auc.tokenIds.length);

        uint256 totalTokenToSend = 0;
        _auc.isEnded = true;
        for (uint256 i = 0; i < _auc.tokenIds.length; i++) {
            uint256 tokenId = _auc.tokenIds[i];
            Bid[] storage bids = _auc.tokenBid[tokenId];
            uint256 size = bids.length;
            if (size > 1) {
                for (uint256 j = 0; j < size - 1; j++) {
                    _auc.paymentToken.safeTransfer(
                        bids[j].userAddress,
                        bids[j].amt
                    );
                }
            }
            if (size > 0) {
                winnerAddresses[i] = bids[size - 1].userAddress;
                totalTokenToSend += bids[size - 1].amt;
            }
        }

        if (_auc.auctionType != AuctionType.STAKE) {
            if (totalTokenToSend > 0) {
                _auc.paymentToken.safeTransfer(
                    withdrawAddress,
                    totalTokenToSend
                );
            }
        } else {
            _auc.paymentToken.approve(address(timeLock), totalTokenToSend);
            for (uint256 i = 0; i < _auc.tokenIds.length; i++) {
                uint256 tokenId = _auc.tokenIds[i];
                Bid[] storage bids = _auc.tokenBid[tokenId];
                uint256 size = bids.length;
                if (size > 0) {
                    TimeLock(timeLock).deposit(
                        address(_auc.paymentToken),
                        bids[size - 1].amt,
                        winnerAddresses[i]
                    );
                }
            }
        }
        emit AuctionEnded(auctionId, tokenIds, winnerAddresses);
    }

    function endMultipleAuctions(
        uint256[] memory auctionIds
    ) external onlyOwner {
        for (uint256 i = 0; i < auctionIds.length; i++)
            endAuction(auctionIds[i]);
    }

    function getTokenBid(
        uint256 auctionId,
        uint256 tokenId
    ) external view returns (Bid[] memory bids) {
        bids = auctionsDetails[auctionId].tokenBid[tokenId];
    }

    function getTokenIds(
        uint256 auctionId
    ) external view returns (uint256[] memory tokenIds) {
        return auctionsDetails[auctionId].tokenIds;
    }

    function getTokenLastBid(
        uint256 auctionId,
        uint256 tokenId
    ) external view returns (Bid memory bid, uint256 numOfOffer) {
        Bid[] memory bids = auctionsDetails[auctionId].tokenBid[tokenId];
        if (bids.length == 0) return (bid, 0);
        bid = bids[bids.length - 1];
        numOfOffer = bids.length;
    }

    function currentAuctionId() external view returns (uint256) {
        return auctionsDetails.length;
    }

    function getAuctionInfo(
        uint256 auctionId
    )
        external
        view
        returns (
            uint256[] memory numOfOffer,
            Bid[] memory lastBidder,
            uint256 createdAt,
            address imxNftAddress,
            uint256 endTime,
            bool isEnded,
            uint256[] memory tokenIds
        )
    {
        Auctions storage _auc = auctionsDetails[auctionId];
        createdAt = _auc.createdAt;
        imxNftAddress = _auc.imxNftAddress;
        endTime = _auc.endTime;
        isEnded = _auc.isEnded;
        tokenIds = _auc.tokenIds;

        uint256[] memory _numOfOffer = new uint256[](_auc.tokenIds.length);
        Bid[] memory _lastBidder = new Bid[](_auc.tokenIds.length);
        for (uint256 i = 0; i < _auc.tokenIds.length; i++) {
            uint256 tokenId = _auc.tokenIds[i];
            Bid[] memory bids = _auc.tokenBid[tokenId];
            _numOfOffer[i] = bids.length;
            if (bids.length != 0) _lastBidder[i] = bids[bids.length - 1];
        }
        numOfOffer = _numOfOffer;
        lastBidder = _lastBidder;
    }

    function notEndedAuctionIds() external view returns (uint256[] memory) {
        uint256 size = 0;
        for (uint256 i = 0; i < auctionsDetails.length; i++) {
            if (
                auctionsDetails[i].endTime +
                    auctionsDetails[i].largestBidLength *
                    TimeExtendOnBid <=
                block.timestamp &&
                !auctionsDetails[i].isEnded
            ) {
                size++;
            }
        }
        uint256[] memory auctionIds = new uint256[](size);
        uint256 index = 0;
        for (uint256 i = 0; i < auctionsDetails.length; i++) {
            if (
                auctionsDetails[i].endTime +
                    auctionsDetails[i].largestBidLength *
                    TimeExtendOnBid <=
                block.timestamp &&
                !auctionsDetails[i].isEnded
            ) {
                auctionIds[index++] = i;
            }
        }
        return auctionIds;
    }

    function getAuctions(
        uint256 offset,
        uint256 limit,
        bool forPastAuction
    )
        external
        view
        returns (
            uint256[] memory,
            string[] memory,
            uint256[] memory,
            address[] memory
        )
    {
        uint256 size = 0;
        uint256 skip = offset;
        for (uint256 i = 0; i < auctionsDetails.length; i++) {
            if (!forPastAuction) {
                if (auctionsDetails[i].endTime <= block.timestamp) continue;
            } else {
                if (auctionsDetails[i].endTime >= block.timestamp) continue;
            }
            if (skip > 0) {
                skip--;
                continue;
            }
            size++;
            if (size == limit) break;
        }
        uint256[] memory auctionIds = new uint256[](size);
        string[] memory auctionName = new string[](size);
        uint256[] memory endTime = new uint256[](size);
        address[] memory imxNftAddress = new address[](size);
        uint256 index = 0;
        skip = offset;
        size = 0;
        for (uint256 i = 0; i < auctionsDetails.length; i++) {
            if (!forPastAuction) {
                if (auctionsDetails[i].endTime <= block.timestamp) continue;
            } else {
                if (auctionsDetails[i].endTime >= block.timestamp) continue;
            }
            if (skip > 0) {
                skip--;
                continue;
            }
            auctionIds[index] = i;
            auctionName[index] = auctionsDetails[i].name;
            endTime[index] = auctionsDetails[i].endTime;
            imxNftAddress[index++] = auctionsDetails[i].imxNftAddress;
            size++;
            if (size == limit) break;
        }
        return (auctionIds, auctionName, endTime, imxNftAddress);
    }

    function checkTokenIdExist(
        Auctions storage _auc,
        uint256 tokenId
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _auc.tokenIds.length; i++) {
            if (_auc.tokenIds[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function withdrawAnonymousToken(
        IERC20Upgradeable token,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(withdrawAddress, amount);
    }

    uint256 public TimeExtendOnBid;

    function setTimeExtendOnBid(uint256 _TimeExtendOnBid) public onlyOwner {
        TimeExtendOnBid = _TimeExtendOnBid;
    }

    function setTimeLockAddress(address _timeLock) public onlyOwner {
        timeLock = _timeLock;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public tokenToTotalBid;

    address public timeLock;

    event onBuyOrBid2(
        uint256 indexed auctionId,
        address imxNftAddress,
        uint256 price,
        uint256 buyDate,
        uint256 endSaleDate,
        uint256 tokenId,
        AuctionType auctionType,
        address bidderAddress
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TimeLock is Ownable {
    uint256 public lockPeriod;
    uint256 public constant SECONDS_IN_A_YEAR = 31536000;
    address public auctionContract;

    struct LockedToken {
        IERC20 token;
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => LockedToken[]) public lockedTokens;

    event TokenDeposited(address indexed user, IERC20 indexed token, uint256 amount, uint256 unlockTime);
    event TokenWithdrawn(address indexed user, IERC20 indexed token, uint256 amount);

    constructor(uint256 _lockPeriod, address _auctionContract) {
        lockPeriod = _lockPeriod == 0 ? SECONDS_IN_A_YEAR : _lockPeriod;
        auctionContract = _auctionContract;
    }

    modifier onlyAuctionContract() {
        require(msg.sender == auctionContract, "Only auction contract can call this function.");
        _;
    }

    function setAuctionContractAddress(address _auctionContract) public onlyOwner {
        auctionContract = _auctionContract;
    }

    function deposit(address _token, uint256 _amount, address _user) external onlyAuctionContract { 
        require(_amount > 0, "Amount must be greater than 0.");
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Token transfer failed.");

        lockedTokens[_user].push(LockedToken({
            token: IERC20(_token),
            amount: _amount,
            unlockTime: block.timestamp + lockPeriod
        }));

        emit TokenDeposited(_user, IERC20(_token), _amount, block.timestamp + lockPeriod);
    }

    function withdraw(uint256 _index) external {
        LockedToken storage lockedToken = lockedTokens[msg.sender][_index]; 
        require(block.timestamp >= lockedToken.unlockTime, "Tokens are still locked.");
        require(lockedToken.amount > 0, "Token amount already withdrawn.");

        uint256 amount = lockedToken.amount;
        lockedToken.amount = 0;
        require(lockedToken.token.transfer(msg.sender, amount), "Token withdrawal failed.");

        emit TokenWithdrawn(msg.sender, lockedToken.token, amount);
    }

    function getUserLocks(address _user) external view returns (LockedToken[] memory) {
        return lockedTokens[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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