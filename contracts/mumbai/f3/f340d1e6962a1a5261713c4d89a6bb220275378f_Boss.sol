// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBase } from "src/dependencies/chainlink/VRFV2WrapperConsumerBase.sol";
import { Babylonian } from "src/dependencies/Babylonian.sol";
import { IItem } from "./interfaces/IItem.sol";
import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IBoss } from "./interfaces/IBoss.sol";

contract Boss is IBoss, VRFV2WrapperConsumerBase {
    uint256 public immutable ROUND_DURATION;
    uint256 public constant MAX_ITEM_ID = 4999;
    uint256 public immutable MAX_NUMBER_SQRT;

    mapping(uint256 => mapping(uint256 => Round)) public charInfo;
    mapping(uint256 => uint256) public roundSeed;
    uint256 public lastRoundTimestamp = block.timestamp;
    uint256 public roundId;
    IItem public _item;
    IChar public _char;

    constructor(IItem item_, IChar char_, address link_, address vrfV2Wrapper_, uint256 roundDuration_)
        VRFV2WrapperConsumerBase(link_, vrfV2Wrapper_)
    {
        _item = item_;
        _char = char_;
        MAX_NUMBER_SQRT = Babylonian.sqrt(type(uint256).max);
        ROUND_DURATION = roundDuration_;
    }

    function attackBoss(uint256 charId_) external override {
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        if (charInfo[roundId][charId_].attacked) revert AlreadyAttackedError(charId_, roundId);
        charInfo[roundId][charId_].attacked = true;
        emit BossAttacked(roundId, charId_);
    }

    function claimRewards(uint256 charId_, uint256 roundId_) external override returns (uint256 itemId_) {
        uint256 seed_ = roundSeed[roundId_];
        if (seed_ == 0) revert RoundNotOverError(roundId_);
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        if (!charInfo[roundId_][charId_].attacked) revert AlreadyAttackedError(charId_, roundId_);
        if (charInfo[roundId_][charId_].claimed) revert AlreadyClaimedError(charId_, roundId_);

        itemId_ = MAX_ITEM_ID
            - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(seed_, charId_)))) / MAX_NUMBER_SQRT;
        _item.mint(msg.sender, itemId_);
        charInfo[roundId_][charId_].claimed = true;
        _char.levelUp(charId_);
        emit RewardClaimed(roundId_, charId_, itemId_);
    }

    function previewRewards(uint256 charId_, uint256 roundId_) external view override returns (uint256 itemId_) {
        itemId_ = MAX_ITEM_ID
            - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(roundSeed[roundId_], charId_))))
                / MAX_NUMBER_SQRT;
    }

    function nextRound() public override {
        if (block.timestamp - lastRoundTimestamp < ROUND_DURATION) return;
        ++roundId;
        lastRoundTimestamp = block.timestamp;
        requestRandomness(100_000, 1, 1);
        emit RoundStarted(roundId, block.timestamp);
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords) internal override {
        roundSeed[roundId - 1] = _randomWords[0];
        emit RandomWordsFulfilled(roundId, _randomWords[0]);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";
import "./interfaces/VRFV2WrapperConsumerBaseInterface.sol";

/**
 *
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase is VRFV2WrapperConsumerBaseInterface {
    LinkTokenInterface internal immutable LINK;
    VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

    /**
     * @param _link is the address of LinkToken
     * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
     */
    constructor(address _link, address _vrfV2Wrapper) {
        LINK = LinkTokenInterface(_link);
        VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
    }

    /**
     * @dev Requests randomness from the VRF V2 wrapper.
     *
     * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
     *        fulfillRandomWords function.
     * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
     *        request. A higher number of confirmations increases security by reducing the likelihood
     *        that a chain re-org changes a published randomness outcome.
     * @param _numWords is the number of random words to request.
     *
     * @return requestId is the VRF V2 request ID of the newly created randomness request.
     */
    function requestRandomness(uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords)
        internal
        returns (uint256 requestId)
    {
        LINK.transferAndCall(
            address(VRF_V2_WRAPPER),
            VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
            abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
        );
        return VRF_V2_WRAPPER.lastRequestId();
    }

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
     * @notice implement it.
     *
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external override {
        require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
        fulfillRandomWords(_requestId, _randomWords);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperConsumerBaseInterface {
    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
    /**
     * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
     * be relied option within the same transaction that the request was made.
     */
    function lastRequestId() external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
     * @notice block.
     *
     * @dev This function relies on the transaction gas price which is not automatically set during
     * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     */
    function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

    /**
     * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
     *
     * @dev This is a convenience function that can be called in simulation to better understand
     * @dev pricing.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     * @param _requestGasPriceWei is the gas price in wei used for the estimation.
     */
    function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IONFT1155Core.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT1155 is IONFT1155Core, IERC1155 { }

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT1155Core is IERC165 {
    event SendToChain(
        uint16 indexed _dstChainId, address indexed _from, bytes indexed _toAddress, uint256 _tokenId, uint256 _amount
    );
    event SendBatchToChain(
        uint16 indexed _dstChainId,
        address indexed _from,
        bytes indexed _toAddress,
        uint256[] _tokenIds,
        uint256[] _amounts
    );
    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint256 _tokenId,
        uint256 _amount
    );
    event ReceiveBatchFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint256[] _tokenIds,
        uint256[] _amounts
    );

    // _from - address where tokens should be deducted from on behalf of
    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenId - token Id to transfer
    // _amount - amount of the tokens to transfer
    // _refundAddress - address on src that will receive refund for any overpayment of L0 fees
    // _zroPaymentAddress - if paying in zro, pass the address to use. using 0x0 indicates not paying fees in zro
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // _from - address where tokens should be deducted from on behalf of
    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenIds - token Ids to transfer
    // _amounts - amounts of the tokens to transfer
    // _refundAddress - address on src that will receive refund for any overpayment of L0 fees
    // _zroPaymentAddress - if paying in zro, pass the address to use. using 0x0 indicates not paying fees in zro
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenId - token Id to transfer
    // _amount - amount of the tokens to transfer
    // _useZro - indicates to use zro to pay L0 fees
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // _dstChainId - L0 defined chain id to send tokens too
    // _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
    // _tokenIds - tokens Id to transfer
    // _amounts - amounts of the tokens to transfer
    // _useZro - indicates to use zro to pay L0 fees
    // _adapterParams - flexible bytes array to indicate messaging adapter services in L0
    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBaseInterface } from
    "src/dependencies/chainlink/interfaces/VRFV2WrapperConsumerBaseInterface.sol";

import { ICharacter as IChar } from "./ICharacter.sol";

interface IBoss is VRFV2WrapperConsumerBaseInterface {
    error RoundNotOverError(uint256 roundId_);
    error AlreadyAttackedError(uint256 charId_, uint256 roundId_);
    error AlreadyClaimedError(uint256 charId_, uint256 roundId_);

    struct Round {
        bool attacked;
        bool claimed;
    }

    event RoundStarted(uint256 indexed roundId, uint256 timestamp);
    event BossAttacked(uint256 indexed roundId, uint256 indexed charId);
    event RewardClaimed(uint256 indexed roundId, uint256 indexed charId, uint256 itemId);
    event RandomWordsFulfilled(uint256 indexed roundId, uint256 seed);

    error NotCharOwnerError(uint256 charId_, address sender_);

    function attackBoss(uint256 charId_) external;

    function claimRewards(uint256 charId_, uint256 roundId_) external returns (uint256 itemId_);

    function previewRewards(uint256 charId_, uint256 roundId_) external view returns (uint256 itemId_);

    function nextRound() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";

interface ICharacter is IERC721, IVotes {
    struct CharInfo {
        uint32 charId;
        uint32 level;
        uint32 power;
        uint160 equippedGold;
    }

    event ItemsEquipped(uint256 indexed charId, uint256[] itemIds);
    event GoldCarried(uint256 indexed charId, uint256 goldAmount);
    event GoldDropped(uint256 indexed charId, uint256 goldAmount);
    event CharacterSent(CharInfo indexed charInfo, uint16 dstChainId, address toAddress);
    event CharacterReceived(CharInfo indexed charInfo, address fromAddress);
    event CharacterLevelUp(uint256 indexed charId, uint32 level);

    error InvalidCharInfoError(CharInfo charInfo);
    error NotOwnerError(address owner);
    error OnlyPortalError(address portal);
    error OnlyBossError(address boss);

    function equipItems(uint256 charId_, uint256[] calldata itemIds_) external;

    function carryGold(uint256 charId_, uint256 goldAmount_) external;

    function dropGold(uint256 charId_, uint256 goldAmount_) external;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, uint256 charId_) external payable;

    /**
     * @dev send tokens `_tokenIds[]` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendBatchFrom(address _from, uint16 _dstChainId, address _toAddress, uint256[] calldata charIds_)
        external
        payable;

    function creditTo(address toAddress_, uint256 tokenId_, bytes memory data_) external;

    function levelUp(uint256 charId_) external;

    function getCharInfo(uint256 charId_) external view returns (CharInfo memory, address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IONFT1155 } from "src/dependencies/layerZero/interfaces/onft1155/IONFT1155.sol";

interface IItem is IONFT1155 {
    event ItemBurned(address indexed from, uint256 id);
    event ItemMinted(address indexed to, uint256 id);
    event ItemBatchBurned(address indexed from, uint256[] ids, uint256[] amounts);
    event ItemBatchMinted(address indexed to, uint256[] ids, uint256[] amounts);
    event ItemPrivilegedTransfer(address indexed from, address indexed to, uint256 id);

    function burn(address from, uint256 id) external;
    function mint(address to, uint256 id) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function privilegedSafeTransferFrom(address from_, address to_, uint256 id_) external;
}