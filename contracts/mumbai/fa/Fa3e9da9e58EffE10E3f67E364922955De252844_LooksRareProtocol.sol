// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 * @dev error ETHTransferFail()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant ETHTransferFail_error_selector = 0x07246cf4;
uint256 constant ETHTransferFail_error_length = 0x04;
uint256 constant Error_selector_offset = 0x1c;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev ERC1271's magic value (bytes4(keccak256("isValidSignature(bytes32,bytes)"))
 */
bytes4 constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the signer is null.
 */
error NullSignerAddress();

/**
 * @notice It is emitted if the signature is invalid for an EOA (the address recovered is not the expected one).
 */
error SignatureEOAInvalid();

/**
 * @notice It is emitted if the signature is invalid for a ERC1271 contract signer.
 */
error SignatureERC1271Invalid();

/**
 * @notice It is emitted if the signature's length is neither 64 nor 65 bytes.
 */
error SignatureLengthInvalid(uint256 length);

/**
 * @notice It is emitted if the signature is invalid due to S parameter.
 */
error SignatureParameterSInvalid();

/**
 * @notice It is emitted if the signature is invalid due to V parameter.
 */
error SignatureParameterVInvalid(uint8 v);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1155} from "../interfaces/generic/IERC1155.sol";

// Errors
import {ERC1155SafeTransferFromFail, ERC1155SafeBatchTransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "../interfaces/generic/IERC20.sol";

// Errors
import {ERC20TransferFail, ERC20TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC20Transfer
 * @notice This contract contains low-level calls to transfer ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Transfer {
    /**
     * @notice Execute ERC20 transferFrom
     * @param currency Currency address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20TransferFrom(address currency, address from, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transferFrom, (from, to, amount)));

        if (!status) {
            revert ERC20TransferFromFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFromFail();
            }
        }
    }

    /**
     * @notice Execute ERC20 (direct) transfer
     * @param currency Currency address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20DirectTransfer(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transfer, (to, amount)));

        if (!status) {
            revert ERC20TransferFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC721} from "../interfaces/generic/IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Assembly constants
import {ETHTransferFail_error_selector, ETHTransferFail_error_length, Error_selector_offset} from "../constants/AssemblyConstants.sol";

/**
 * @title LowLevelETHReturnETHIfAnyExceptOneWei
 * @notice This contract contains a function to return all ETH except 1 wei held.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelETHReturnETHIfAnyExceptOneWei {
    /**
     * @notice It returns ETH to the original sender if any is left in the payable call
     *         but this leaves 1 wei of ETH in the contract.
     * @dev It does not revert if self balance is equal to 1 or 0.
     */
    function _returnETHIfAnyWithOneWeiLeft() internal {
        assembly {
            let selfBalance := selfbalance()
            if gt(selfBalance, 1) {
                let status := call(gas(), caller(), sub(selfBalance, 1), 0, 0, 0, 0)
                if iszero(status) {
                    mstore(0x00, ETHTransferFail_error_selector)
                    revert(Error_selector_offset, ETHTransferFail_error_length)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IWETH} from "../interfaces/generic/IWETH.sol";

/**
 * @title LowLevelWETH
 * @notice This contract contains a function to transfer ETH with an option to wrap to WETH.
 *         If the ETH transfer fails within a gas limit, the amount in ETH is wrapped to WETH and then transferred.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelWETH {
    /**
     * @notice It transfers ETH to a recipient with a specified gas limit.
     *         If the original transfers fails, it wraps to WETH and transfers the WETH to recipient.
     * @param _WETH WETH address
     * @param _to Recipient address
     * @param _amount Amount to transfer
     * @param _gasLimit Gas limit to perform the ETH transfer
     */
    function _transferETHAndWrapIfFailWithGasLimit(
        address _WETH,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        bool status;

        assembly {
            status := call(_gasLimit, _to, _amount, 0, 0, 0, 0)
        }

        if (!status) {
            IWETH(_WETH).deposit{value: _amount}();
            IWETH(_WETH).transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IOwnableTwoSteps} from "./interfaces/IOwnableTwoSteps.sol";

/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IReentrancyGuard} from "./interfaces/IReentrancyGuard.sol";

/**
 * @title PackableReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 *         The only difference between this contract and ReentrancyGuard
 *         is that _status is uint8 instead of uint256 so that it can be
 *         packed with other contracts' storage variables.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract PackableReentrancyGuard is IReentrancyGuard {
    uint8 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1271} from "./interfaces/generic/IERC1271.sol";

// Constants
import {ERC1271_MAGIC_VALUE} from "./constants/StandardConstants.sol";

// Errors
import {SignatureParameterSInvalid, SignatureParameterVInvalid, SignatureERC1271Invalid, SignatureEOAInvalid, NullSignerAddress, SignatureLengthInvalid} from "./errors/SignatureCheckerErrors.sol";

/**
 * @title SignatureCheckerCalldata
 * @notice This library is used to verify signatures for EOAs (with lengths of both 65 and 64 bytes)
 *         and contracts (ERC1271).
 * @author LooksRare protocol team (👀,💎)
 */
library SignatureCheckerCalldata {
    /**
     * @notice This function verifies whether the signer is valid for a hash and raw signature.
     * @param hash Data hash
     * @param signer Signer address (to confirm message validity)
     * @param signature Signature parameters encoded (v, r, s)
     * @dev For EIP-712 signatures, the hash must be the digest (computed with signature hash and domain separator)
     */
    function verify(bytes32 hash, address signer, bytes calldata signature) internal view {
        if (signer.code.length == 0) {
            if (_recoverEOASigner(hash, signature) == signer) return;
            revert SignatureEOAInvalid();
        } else {
            if (IERC1271(signer).isValidSignature(hash, signature) == ERC1271_MAGIC_VALUE) return;
            revert SignatureERC1271Invalid();
        }
    }

    /**
     * @notice This function is internal and splits a signature into r, s, v outputs.
     * @param signature A 64 or 65 bytes signature
     * @return r The r output of the signature
     * @return s The s output of the signature
     * @return v The recovery identifier, must be 27 or 28
     */
    function splitSignature(bytes calldata signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        uint256 length = signature.length;
        if (length == 65) {
            assembly {
                r := calldataload(signature.offset)
                s := calldataload(add(signature.offset, 0x20))
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }
        } else if (length == 64) {
            assembly {
                r := calldataload(signature.offset)
                let vs := calldataload(add(signature.offset, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert SignatureLengthInvalid(length);
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert SignatureParameterSInvalid();
        }

        if (v != 27 && v != 28) {
            revert SignatureParameterVInvalid(v);
        }
    }

    /**
     * @notice This function is private and recovers the signer of a signature (for EOA only).
     * @param hash Hash of the signed message
     * @param signature Bytes containing the signature (64 or 65 bytes)
     * @return signer The address that signed the signature
     */
    function _recoverEOASigner(bytes32 hash, bytes calldata signature) private pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        // If the signature is valid (and not malleable), return the signer's address
        signer = ecrecover(hash, v, r, s);

        if (signer == address(0)) {
            revert NullSignerAddress();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

// Interfaces
import {IAffiliateManager} from "./interfaces/IAffiliateManager.sol";

// Constants
import {ONE_HUNDRED_PERCENT_IN_BP} from "./constants/NumericConstants.sol";

/**
 * @title AffiliateManager
 * @notice This contract handles the management of affiliates for the LooksRare protocol.
 * @author LooksRare protocol team (👀,💎)
 */
contract AffiliateManager is IAffiliateManager, OwnableTwoSteps {
    /**
     * @notice Whether the affiliate program is active.
     */
    bool public isAffiliateProgramActive;

    /**
     * @notice Address of the affiliate controller.
     */
    address public affiliateController;

    /**
     * @notice It tracks the affiliate rate (in basis point) for a given affiliate address.
     *         The basis point represents how much of the protocol fee will be shared to the affiliate.
     */
    mapping(address => uint256) public affiliateRates;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @notice This function allows the affiliate controller to update the affiliate rate (in basis point).
     * @param affiliate Affiliate address
     * @param bp Rate (in basis point) to collect (e.g. 100 = 1%) per referred transaction
     */
    function updateAffiliateRate(address affiliate, uint256 bp) external {
        if (msg.sender != affiliateController) {
            revert NotAffiliateController();
        }

        if (bp > ONE_HUNDRED_PERCENT_IN_BP) {
            revert PercentageTooHigh();
        }

        affiliateRates[affiliate] = bp;
        emit NewAffiliateRate(affiliate, bp);
    }

    /**
     * @notice This function allows the owner to update the affiliate controller address.
     * @param newAffiliateController New affiliate controller address
     * @dev Only callable by owner.
     */
    function updateAffiliateController(address newAffiliateController) external onlyOwner {
        affiliateController = newAffiliateController;
        emit NewAffiliateController(newAffiliateController);
    }

    /**
     * @notice This function allows the owner to update the affiliate program status.
     * @param isActive Whether the affiliate program is active
     * @dev Only callable by owner.
     */
    function updateAffiliateProgramStatus(bool isActive) external onlyOwner {
        isAffiliateProgramActive = isActive;
        emit NewAffiliateProgramStatus(isActive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Shared errors
import {MerkleProofTooLarge} from "./errors/SharedErrors.sol";

/**
 * @title BatchOrderTypehashRegistry
 * @notice The contract generates the batch order hash that is used to compute the digest for signature verification.
 * @author LooksRare protocol team (👀,💎)
 */
contract BatchOrderTypehashRegistry {
    /**
     * @notice This function returns the hash of the concatenation of batch order type hash and merkle root.
     * @param root Merkle root
     * @param proofLength Merkle proof length
     * @return batchOrderHash The batch order hash
     */
    function hashBatchOrder(bytes32 root, uint256 proofLength) public pure returns (bytes32 batchOrderHash) {
        batchOrderHash = keccak256(abi.encode(_getBatchOrderTypehash(proofLength), root));
    }

    /**
     * @dev It looks like this for each height
     *      height == 1: BatchOrder(Maker[2] tree)Maker(uint8 quoteType,uint256 globalNonce,uint256 subsetNonce,uint256 orderNonce,uint256 strategyId,uint8 collectionType,address collection,address currency,address signer,uint256 startTime,uint256 endTime,uint256 price,uint256[] itemIds,uint256[] amounts,bytes additionalParameters)
     *      height == 2: BatchOrder(Maker[2][2] tree)Maker(uint8 quoteType,uint256 globalNonce,uint256 subsetNonce,uint256 orderNonce,uint256 strategyId,uint8 collectionType,address collection,address currency,address signer,uint256 startTime,uint256 endTime,uint256 price,uint256[] itemIds,uint256[] amounts,bytes additionalParameters)
     *      height == n: BatchOrder(Maker[2]...[2] tree)Maker(uint8 quoteType,uint256 globalNonce,uint256 subsetNonce,uint256 orderNonce,uint256 strategyId,uint8 collectionType,address collection,address currency,address signer,uint256 startTime,uint256 endTime,uint256 price,uint256[] itemIds,uint256[] amounts,bytes additionalParameters)
     */
    function _getBatchOrderTypehash(uint256 height) internal pure returns (bytes32 typehash) {
        if (height == 1) {
            typehash = hex"9661287f7a4aa4867db46a2453ee15bebac4e8fc25667a58718da658f15de643";
        } else if (height == 2) {
            typehash = hex"a54ab330ea9e1dfccee2b86f3666989e7fbd479704416c757c8de8e820142a08";
        } else if (height == 3) {
            typehash = hex"93390f5d45ede9dea305f16aec86b2472af4f823851637f1b7019ad0775cea49";
        } else if (height == 4) {
            typehash = hex"9dda2c8358da895e43d574bb15954ce5727b22e923a2d8f28261f297bce42f0b";
        } else if (height == 5) {
            typehash = hex"92dc717124e161262f9d10c7079e7d54dc51271893fba54aa4a0f270fecdcc98";
        } else if (height == 6) {
            typehash = hex"ce02aee5a7a35d40d974463c4c6e5534954fb07a7e7bc966fee268a15337bfd8";
        } else if (height == 7) {
            typehash = hex"f7a65efd167a18f7091b2bb929d687dd94503cf0a43620487055ed7d6b727559";
        } else if (height == 8) {
            typehash = hex"def24acacad1318b664520f7c10e8bc6d1e7f6f6f7c8b031e70624ceb42266a6";
        } else if (height == 9) {
            typehash = hex"4cb4080dc4e7bae88b4dc4307ad5117fa4f26195998a1b5f40368809d7f4c7f2";
        } else if (height == 10) {
            typehash = hex"f8b1f864164d8d6e0b45f1399bd711223117a4ab0b057a9c2d7779e86a7c88db";
        } else {
            revert MerkleProofTooLarge(height);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
 * @dev error OrderInvalid()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OrderInvalid_error_selector = 0x2e0c0f71;
uint256 constant OrderInvalid_error_length = 0x04;

/*
 *  @dev error CurrencyInvalid()
 *       Memory layout:
 *         - 0x00: Left-padded selector (data begins at 0x1c)
 *       Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CurrencyInvalid_error_selector = 0x4f795487;
uint256 constant CurrencyInvalid_error_length = 0x04;

/*
 * @dev error OutsideOfTimeRange()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OutsideOfTimeRange_error_selector = 0x7476320f;
uint256 constant OutsideOfTimeRange_error_length = 0x04;

/*
 * @dev error NoSelectorForStrategy()
 *      Memory layout:
 *        - 0x00: Left-padded selector (data begins at 0x1c)
 *      Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoSelectorForStrategy_error_selector = 0xab984846;
uint256 constant NoSelectorForStrategy_error_length = 0x04;

uint256 constant Error_selector_offset = 0x1c;

uint256 constant OneWord = 0x20;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev 100% represented in basis point is 10_000.
 */
uint256 constant ONE_HUNDRED_PERCENT_IN_BP = 10_000;

/**
 * @dev The maximum length of a proof for a batch order is 10.
 *      The maximum merkle tree that can used for signing has a height of
 *      2**10 = 1_024.
 */
uint256 constant MAX_CALLDATA_PROOF_LENGTH = 10;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";

// Dependencies
import {AffiliateManager} from "./AffiliateManager.sol";

/**
 * @title CurrencyManager
 * @notice This contract manages the list of valid fungible currencies.
 * @author LooksRare protocol team (👀,💎)
 */
contract CurrencyManager is ICurrencyManager, AffiliateManager {
    /**
     * @notice It checks whether the currency is allowed for transacting.
     */
    mapping(address => bool) public isCurrencyAllowed;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) AffiliateManager(_owner) {}

    /**
     * @notice This function allows the owner to update the status of a currency.
     * @param currency Currency address (address(0) for ETH)
     * @param isAllowed Whether the currency should be allowed for trading
     * @dev Only callable by owner.
     */
    function updateCurrencyStatus(address currency, bool isAllowed) external onlyOwner {
        isCurrencyAllowed[currency] = isAllowed;
        emit CurrencyStatusUpdated(currency, isAllowed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice CollectionType is used in OrderStructs.Maker's collectionType to determine the collection type being traded.
 */
enum CollectionType {
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice QuoteType is used in OrderStructs.Maker's quoteType to determine whether the maker order is a bid or an ask.
 */
enum QuoteType {
    Bid,
    Ask
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice It is returned if the amount is invalid.
 *         For ERC721, any number that is not 1. For ERC1155, if amount is 0.
 */
error AmountInvalid();

/**
 * @notice It is returned if the ask price is too high for the bid user.
 */
error AskTooHigh();

/**
 * @notice It is returned if the bid price is too low for the ask user.
 */
error BidTooLow();

/**
 * @notice It is returned if the function cannot be called by the sender.
 */
error CallerInvalid();

/**
 * @notice It is returned if the currency is invalid.
 */
error CurrencyInvalid();

/**
 * @notice The function selector is invalid for this strategy implementation.
 */
error FunctionSelectorInvalid();

/**
 * @notice It is returned if there is either a mismatch or an error in the length of the array(s).
 */
error LengthsInvalid();

/**
 * @notice It is returned if the merkle proof provided is invalid.
 */
error MerkleProofInvalid();

/**
 * @notice It is returned if the length of the merkle proof provided is greater than tolerated.
 * @param length Proof length
 */
error MerkleProofTooLarge(uint256 length);

/**
 * @notice It is returned if the order is permanently invalid.
 *         There may be an issue with the order formatting.
 */
error OrderInvalid();

/**
 * @notice It is returned if the maker quote type is invalid.
 */
error QuoteTypeInvalid();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Interfaces
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {ICreatorFeeManager} from "./interfaces/ICreatorFeeManager.sol";

// Direct dependencies
import {InheritedStrategy} from "./InheritedStrategy.sol";
import {NonceManager} from "./NonceManager.sol";
import {StrategyManager} from "./StrategyManager.sol";

// Assembly
import {NoSelectorForStrategy_error_selector, NoSelectorForStrategy_error_length, OutsideOfTimeRange_error_selector, OutsideOfTimeRange_error_length, Error_selector_offset} from "./constants/AssemblyConstants.sol";

// Constants
import {ONE_HUNDRED_PERCENT_IN_BP} from "./constants/NumericConstants.sol";

// Enums
import {QuoteType} from "./enums/QuoteType.sol";

/**
 * @title ExecutionManager
 * @notice This contract handles the execution and resolution of transactions. A transaction is executed on-chain
 *         when an off-chain maker order is matched by on-chain taker order of a different kind.
 *         For instance, a taker ask is executed against a maker bid (or a taker bid against a maker ask).
 * @author LooksRare protocol team (👀,💎)
 */
contract ExecutionManager is InheritedStrategy, NonceManager, StrategyManager, IExecutionManager {
    /**
     * @notice Protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice Maximum creator fee (in basis point).
     */
    uint16 public maxCreatorFeeBp = 1_000;

    /**
     * @notice Creator fee manager.
     */
    ICreatorFeeManager public creatorFeeManager;

    /**
     * @notice Constructor
     * @param _owner Owner address
     * @param _protocolFeeRecipient Protocol fee recipient address
     */
    constructor(address _owner, address _protocolFeeRecipient) StrategyManager(_owner) {
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @notice This function allows the owner to update the creator fee manager address.
     * @param newCreatorFeeManager Address of the creator fee manager
     * @dev Only callable by owner.
     */
    function updateCreatorFeeManager(address newCreatorFeeManager) external onlyOwner {
        creatorFeeManager = ICreatorFeeManager(newCreatorFeeManager);
        emit NewCreatorFeeManager(newCreatorFeeManager);
    }

    /**
     * @notice This function allows the owner to update the maximum creator fee (in basis point).
     * @param newMaxCreatorFeeBp New maximum creator fee (in basis point)
     * @dev The maximum value that can be set is 25%.
     *      Only callable by owner.
     */
    function updateMaxCreatorFeeBp(uint16 newMaxCreatorFeeBp) external onlyOwner {
        if (newMaxCreatorFeeBp > 2_500) {
            revert CreatorFeeBpTooHigh();
        }

        maxCreatorFeeBp = newMaxCreatorFeeBp;

        emit NewMaxCreatorFeeBp(newMaxCreatorFeeBp);
    }

    /**
     * @notice This function allows the owner to update the protocol fee recipient.
     * @param newProtocolFeeRecipient New protocol fee recipient address
     * @dev Only callable by owner.
     */
    function updateProtocolFeeRecipient(address newProtocolFeeRecipient) external onlyOwner {
        _updateProtocolFeeRecipient(newProtocolFeeRecipient);
    }

    /**
     * @notice This function is internal and is used to execute a transaction initiated by a taker order.
     * @param takerOrder Taker order struct (taker specific parameters for the execution)
     * @param makerOrder Maker order struct (maker specific parameter for the execution)
     * @param sender The address that sent the transaction
     * @return itemIds Array of item ids to be traded
     * @return amounts Array of amounts for each item id
     * @return recipients Array of recipient addresses
     * @return feeAmounts Array of fee amounts
     * @return isNonceInvalidated Whether the order's nonce will be invalidated after executing the order
     */
    function _executeStrategyForTakerOrder(
        OrderStructs.Taker calldata takerOrder,
        OrderStructs.Maker calldata makerOrder,
        address sender
    )
        internal
        returns (
            uint256[] memory itemIds,
            uint256[] memory amounts,
            address[2] memory recipients,
            uint256[3] memory feeAmounts,
            bool isNonceInvalidated
        )
    {
        uint256 price;

        // Verify the order validity for timestamps
        _verifyOrderTimestampValidity(makerOrder.startTime, makerOrder.endTime);

        if (makerOrder.strategyId == 0) {
            _verifyItemIdsAndAmountsEqualLengthsAndValidAmounts(makerOrder.amounts, makerOrder.itemIds);
            (price, itemIds, amounts) = (makerOrder.price, makerOrder.itemIds, makerOrder.amounts);
            isNonceInvalidated = true;
        } else {
            if (strategyInfo[makerOrder.strategyId].isActive) {
                /**
                 * @dev This is equivalent to
                 *
                 * if (makerOrder.quoteType == QuoteType.Bid) {
                 *     if (!strategyInfo[makerOrder.strategyId].isMakerBid) {
                 *         revert NoSelectorForStrategy();
                 *     }
                 * } else {
                 *     if (strategyInfo[makerOrder.strategyId].isMakerBid) {
                 *         revert NoSelectorForStrategy();
                 *     }
                 * }
                 *
                 * because one must be 0 and another must be 1 for the function
                 * to not revert.
                 *
                 * Both quoteType (an enum with 2 values) and isMakerBid (a bool)
                 * can only be 0 or 1.
                 */
                QuoteType quoteType = makerOrder.quoteType;
                bool isMakerBid = strategyInfo[makerOrder.strategyId].isMakerBid;
                assembly {
                    if eq(quoteType, isMakerBid) {
                        mstore(0x00, NoSelectorForStrategy_error_selector)
                        revert(Error_selector_offset, NoSelectorForStrategy_error_length)
                    }
                }

                (bool status, bytes memory data) = strategyInfo[makerOrder.strategyId].implementation.call(
                    abi.encodeWithSelector(strategyInfo[makerOrder.strategyId].selector, takerOrder, makerOrder)
                );

                if (!status) {
                    // @dev It forwards the revertion message from the low-level call
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                }

                (price, itemIds, amounts, isNonceInvalidated) = abi.decode(data, (uint256, uint256[], uint256[], bool));
            } else {
                revert StrategyNotAvailable(makerOrder.strategyId);
            }
        }

        // Creator fee and adjustment of protocol fee
        (recipients[1], feeAmounts[1]) = _getCreatorRecipientAndCalculateFeeAmount(
            makerOrder.collection,
            price,
            itemIds
        );
        if (makerOrder.quoteType == QuoteType.Bid) {
            _setTheRestOfFeeAmountsAndRecipients(
                makerOrder.strategyId,
                price,
                takerOrder.recipient == address(0) ? sender : takerOrder.recipient,
                feeAmounts,
                recipients
            );
        } else {
            _setTheRestOfFeeAmountsAndRecipients(
                makerOrder.strategyId,
                price,
                makerOrder.signer,
                feeAmounts,
                recipients
            );
        }
    }

    /**
     * @notice This private function updates the protocol fee recipient.
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function _updateProtocolFeeRecipient(address newProtocolFeeRecipient) private {
        if (newProtocolFeeRecipient == address(0)) {
            revert NewProtocolFeeRecipientCannotBeNullAddress();
        }

        protocolFeeRecipient = newProtocolFeeRecipient;
        emit NewProtocolFeeRecipient(newProtocolFeeRecipient);
    }

    /**
     * @notice This function is internal and is used to calculate
     *         the protocol fee amount for a set of fee amounts.
     * @param price Transaction price
     * @param strategyId Strategy id
     * @param creatorFeeAmount Creator fee amount
     * @param minTotalFeeAmount Min total fee amount
     * @return protocolFeeAmount Protocol fee amount
     */
    function _calculateProtocolFeeAmount(
        uint256 price,
        uint256 strategyId,
        uint256 creatorFeeAmount,
        uint256 minTotalFeeAmount
    ) private view returns (uint256 protocolFeeAmount) {
        protocolFeeAmount = (price * strategyInfo[strategyId].standardProtocolFeeBp) / ONE_HUNDRED_PERCENT_IN_BP;

        if (protocolFeeAmount + creatorFeeAmount < minTotalFeeAmount) {
            protocolFeeAmount = minTotalFeeAmount - creatorFeeAmount;
        }
    }

    /**
     * @notice This function is internal and is used to get the creator fee address
     *         and calculate the creator fee amount.
     * @param collection Collection address
     * @param price Transaction price
     * @param itemIds Array of item ids
     * @return creator Creator recipient
     * @return creatorFeeAmount Creator fee amount
     */
    function _getCreatorRecipientAndCalculateFeeAmount(
        address collection,
        uint256 price,
        uint256[] memory itemIds
    ) private view returns (address creator, uint256 creatorFeeAmount) {
        if (address(creatorFeeManager) != address(0)) {
            (creator, creatorFeeAmount) = creatorFeeManager.viewCreatorFeeInfo(collection, price, itemIds);

            if (creator == address(0)) {
                // If recipient is null address, creator fee is set to 0
                creatorFeeAmount = 0;
            } else if (creatorFeeAmount * ONE_HUNDRED_PERCENT_IN_BP > (price * uint256(maxCreatorFeeBp))) {
                // If creator fee is higher than tolerated, it reverts
                revert CreatorFeeBpTooHigh();
            }
        }
    }

    /**
     * @dev This function does not need to return feeAmounts and recipients as they are modified
     *      in memory.
     */
    function _setTheRestOfFeeAmountsAndRecipients(
        uint256 strategyId,
        uint256 price,
        address askRecipient,
        uint256[3] memory feeAmounts,
        address[2] memory recipients
    ) private view {
        // Compute minimum total fee amount
        uint256 minTotalFeeAmount = (price * strategyInfo[strategyId].minTotalFeeBp) / ONE_HUNDRED_PERCENT_IN_BP;

        if (feeAmounts[1] == 0) {
            // If creator fee is null, protocol fee is set as the minimum total fee amount
            feeAmounts[2] = minTotalFeeAmount;
            // Net fee amount for seller
            feeAmounts[0] = price - feeAmounts[2];
        } else {
            // If there is a creator fee information, the protocol fee amount can be calculated
            feeAmounts[2] = _calculateProtocolFeeAmount(price, strategyId, feeAmounts[1], minTotalFeeAmount);
            // Net fee amount for seller
            feeAmounts[0] = price - feeAmounts[1] - feeAmounts[2];
        }

        recipients[0] = askRecipient;
    }

    /**
     * @notice This function is internal and is used to verify the validity of an order
     *         in the context of the current block timestamps.
     * @param startTime Start timestamp
     * @param endTime End timestamp
     */
    function _verifyOrderTimestampValidity(uint256 startTime, uint256 endTime) private view {
        // if (startTime > block.timestamp || endTime < block.timestamp) revert OutsideOfTimeRange();
        assembly {
            if or(gt(startTime, timestamp()), lt(endTime, timestamp())) {
                mstore(0x00, OutsideOfTimeRange_error_selector)
                revert(Error_selector_offset, OutsideOfTimeRange_error_length)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Shared errors
import {OrderInvalid} from "./errors/SharedErrors.sol";

// Assembly
import {OrderInvalid_error_selector, OrderInvalid_error_length, Error_selector_offset, OneWord} from "./constants/AssemblyConstants.sol";

/**
 * @title InheritedStrategy
 * @notice This contract handles the verification of parameters for standard transactions.
 *         It does not verify the taker struct's itemIds and amounts array as well as
 *         minPrice (taker ask) / maxPrice (taker bid) because before the taker executes the
 *         transaction and the maker itemIds/amounts/price should have already been confirmed off-chain.
 * @dev A standard transaction (bid or ask) is mapped to strategyId = 0.
 * @author LooksRare protocol team (👀,💎)
 */
contract InheritedStrategy {
    /**
     * @notice This function is internal and is used to validate the parameters for a standard sale strategy
     *         when the standard transaction is initiated by a taker bid.
     * @param amounts Array of amounts
     * @param itemIds Array of item ids
     */
    function _verifyItemIdsAndAmountsEqualLengthsAndValidAmounts(
        uint256[] calldata amounts,
        uint256[] calldata itemIds
    ) internal pure {
        assembly {
            let end
            {
                /*
                 * @dev If A == B, then A XOR B == 0.
                 *
                 * if (amountsLength == 0 || amountsLength != itemIdsLength) {
                 *     revert OrderInvalid();
                 * }
                 */
                let amountsLength := amounts.length
                let itemIdsLength := itemIds.length

                if or(iszero(amountsLength), xor(amountsLength, itemIdsLength)) {
                    mstore(0x00, OrderInvalid_error_selector)
                    revert(Error_selector_offset, OrderInvalid_error_length)
                }

                /**
                 * @dev Shifting left 5 times is equivalent to amountsLength * 32 bytes
                 */
                end := shl(5, amountsLength)
            }

            let amountsOffset := amounts.offset

            for {

            } end {

            } {
                /**
                 * @dev Starting from the end of the array minus 32 bytes to load the last item,
                 *      ending with `end` equal to 0 to load the first item
                 *
                 * uint256 end = amountsLength;
                 *
                 * for (uint256 i = end - 1; i >= 0; i--) {
                 *   uint256 amount = amounts[i];
                 *   if (amount == 0) {
                 *      revert OrderInvalid();
                 *   }
                 * }
                 */
                end := sub(end, OneWord)

                let amount := calldataload(add(amountsOffset, end))

                if iszero(amount) {
                    mstore(0x00, OrderInvalid_error_selector)
                    revert(Error_selector_offset, OrderInvalid_error_length)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IAffiliateManager
 * @author LooksRare protocol team (👀,💎)
 */
interface IAffiliateManager {
    /**
     * @notice It is emitted when there is an update of affliate controller.
     * @param affiliateController Address of the new affiliate controller
     */
    event NewAffiliateController(address affiliateController);

    /**
     * @notice It is emitted if the affiliate program is activated or deactivated.
     * @param isActive Whether the affiliate program is active after the update
     */
    event NewAffiliateProgramStatus(bool isActive);

    /**
     * @notice It is emitted if there is a new affiliate and its associated rate (in basis point).
     * @param affiliate Address of the affiliate
     * @param rate Affiliate rate (in basis point)
     */
    event NewAffiliateRate(address affiliate, uint256 rate);

    /**
     * @notice It is returned if the function is called by another address than the affiliate controller.
     */
    error NotAffiliateController();

    /**
     * @notice It is returned if the affiliate controller is trying to set an affiliate rate higher than 10,000.
     */
    error PercentageTooHigh();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {IRoyaltyFeeRegistry} from "./IRoyaltyFeeRegistry.sol";

/**
 * @title ICreatorFeeManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ICreatorFeeManager {
    /**
     * @notice It is returned if the bundle contains multiple itemIds with different creator fee structure.
     */
    error BundleEIP2981NotAllowed(address collection);

    /**
     * @notice It returns the royalty fee registry address/interface.
     * @return royaltyFeeRegistry Interface of the royalty fee registry
     */
    function royaltyFeeRegistry() external view returns (IRoyaltyFeeRegistry royaltyFeeRegistry);

    /**
     * @notice This function returns the creator address and calculates the creator fee amount.
     * @param collection Collection address
     * @param price Transaction price
     * @param itemIds Array of item ids
     * @return creator Creator address
     * @return creatorFeeAmount Creator fee amount
     */
    function viewCreatorFeeInfo(
        address collection,
        uint256 price,
        uint256[] memory itemIds
    ) external view returns (address creator, uint256 creatorFeeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ICurrencyManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ICurrencyManager {
    /**
     * @notice It is emitted if the currency status in the allowlist is updated.
     * @param currency Currency address (address(0) = ETH)
     * @param isAllowed Whether the currency is allowed
     */
    event CurrencyStatusUpdated(address currency, bool isAllowed);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IExecutionManager
 * @author LooksRare protocol team (👀,💎)
 */
interface IExecutionManager {
    /**
     * @notice It is issued when there is a new creator fee manager.
     * @param creatorFeeManager Address of the new creator fee manager
     */
    event NewCreatorFeeManager(address creatorFeeManager);

    /**
     * @notice It is issued when there is a new maximum creator fee (in basis point).
     * @param maxCreatorFeeBp New maximum creator fee (in basis point)
     */
    event NewMaxCreatorFeeBp(uint256 maxCreatorFeeBp);

    /**
     * @notice It is issued when there is a new protocol fee recipient address.
     * @param protocolFeeRecipient Address of the new protocol fee recipient
     */
    event NewProtocolFeeRecipient(address protocolFeeRecipient);

    /**
     * @notice It is returned if the creator fee (in basis point) is too high.
     */
    error CreatorFeeBpTooHigh();

    /**
     * @notice It is returned if the new protocol fee recipient is set to address(0).
     */
    error NewProtocolFeeRecipientCannotBeNullAddress();

    /**
     * @notice It is returned if there is no selector for maker ask/bid for a given strategyId,
     *         depending on the quote type.
     */
    error NoSelectorForStrategy();

    /**
     * @notice It is returned if the current block timestamp is not between start and end times in the maker order.
     */
    error OutsideOfTimeRange();

    /**
     * @notice It is returned if the strategy id has no implementation.
     * @dev It is returned if there is no implementation address and the strategyId is strictly greater than 0.
     */
    error StrategyNotAvailable(uint256 strategyId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

/**
 * @title ILooksRareProtocol
 * @author LooksRare protocol team (👀,💎)
 */
interface ILooksRareProtocol {
    /**
     * @notice This struct contains an order nonce's invalidation status
     *         and the order hash that triggered the status change.
     * @param orderHash Maker order hash
     * @param orderNonce Order nonce
     * @param isNonceInvalidated Whether this transaction invalidated the maker user's order nonce at the protocol level
     */
    struct NonceInvalidationParameters {
        bytes32 orderHash;
        uint256 orderNonce;
        bool isNonceInvalidated;
    }

    /**
     * @notice It is emitted when there is an affiliate fee paid.
     * @param affiliate Affiliate address
     * @param currency Address of the currency
     * @param affiliateFee Affiliate fee (in the currency)
     */
    event AffiliatePayment(address affiliate, address currency, uint256 affiliateFee);

    /**
     * @notice It is emitted if there is a change in the domain separator.
     */
    event NewDomainSeparator();

    /**
     * @notice It is emitted when there is a new gas limit for a ETH transfer (before it is wrapped to WETH).
     * @param gasLimitETHTransfer Gas limit for an ETH transfer
     */
    event NewGasLimitETHTransfer(uint256 gasLimitETHTransfer);

    /**
     * @notice It is emitted when a taker ask transaction is completed.
     * @param nonceInvalidationParameters Struct about nonce invalidation parameters
     * @param askUser Address of the ask user
     * @param bidUser Address of the bid user
     * @param strategyId Id of the strategy
     * @param currency Address of the currency
     * @param collection Address of the collection
     * @param itemIds Array of item ids
     * @param amounts Array of amounts (for item ids)
     * @param feeRecipients Array of fee recipients
     *        feeRecipients[0] User who receives the proceeds of the sale (it can be the taker ask user or different)
     *        feeRecipients[1] Creator fee recipient (if none, address(0))
     * @param feeAmounts Array of fee amounts
     *        feeAmounts[0] Fee amount for the user receiving sale proceeds
     *        feeAmounts[1] Creator fee amount
     *        feeAmounts[2] Protocol fee amount prior to adjustment for a potential affiliate payment
     */
    event TakerAsk(
        NonceInvalidationParameters nonceInvalidationParameters,
        address askUser, // taker (initiates the transaction)
        address bidUser, // maker (receives the NFT)
        uint256 strategyId,
        address currency,
        address collection,
        uint256[] itemIds,
        uint256[] amounts,
        address[2] feeRecipients,
        uint256[3] feeAmounts
    );

    /**
     * @notice It is emitted when a taker bid transaction is completed.
     * @param nonceInvalidationParameters Struct about nonce invalidation parameters
     * @param bidUser Address of the bid user
     * @param bidRecipient Address of the recipient of the bid
     * @param strategyId Id of the strategy
     * @param currency Address of the currency
     * @param collection Address of the collection
     * @param itemIds Array of item ids
     * @param amounts Array of amounts (for item ids)
     * @param feeRecipients Array of fee recipients
     *        feeRecipients[0] User who receives the proceeds of the sale (it is the maker ask user)
     *        feeRecipients[1] Creator fee recipient (if none, address(0))
     * @param feeAmounts Array of fee amounts
     *        feeAmounts[0] Fee amount for the user receiving sale proceeds
     *        feeAmounts[1] Creator fee amount
     *        feeAmounts[2] Protocol fee amount prior to adjustment for a potential affiliate payment
     */
    event TakerBid(
        NonceInvalidationParameters nonceInvalidationParameters,
        address bidUser, // taker (initiates the transaction)
        address bidRecipient, // taker (receives the NFT)
        uint256 strategyId,
        address currency,
        address collection,
        uint256[] itemIds,
        uint256[] amounts,
        address[2] feeRecipients,
        uint256[3] feeAmounts
    );

    /**
     * @notice It is returned if the gas limit for a standard ETH transfer is too low.
     */
    error NewGasLimitETHTransferTooLow();

    /**
     * @notice It is returned if the domain separator cannot be updated (i.e. the chainId is the same).
     */
    error SameDomainSeparator();

    /**
     * @notice It is returned if the domain separator should change.
     */
    error ChainIdInvalid();

    /**
     * @notice It is returned if the nonces are invalid.
     */
    error NoncesInvalid();

    /**
     * @notice This function allows a user to execute a taker ask (against a maker bid).
     * @param takerAsk Taker ask struct
     * @param makerBid Maker bid struct
     * @param makerSignature Maker signature
     * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
     * @param affiliate Affiliate address
     */
    function executeTakerAsk(
        OrderStructs.Taker calldata takerAsk,
        OrderStructs.Maker calldata makerBid,
        bytes calldata makerSignature,
        OrderStructs.MerkleTree calldata merkleTree,
        address affiliate
    ) external;

    /**
     * @notice This function allows a user to execute a taker bid (against a maker ask).
     * @param takerBid Taker bid struct
     * @param makerAsk Maker ask struct
     * @param makerSignature Maker signature
     * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
     * @param affiliate Affiliate address
     */
    function executeTakerBid(
        OrderStructs.Taker calldata takerBid,
        OrderStructs.Maker calldata makerAsk,
        bytes calldata makerSignature,
        OrderStructs.MerkleTree calldata merkleTree,
        address affiliate
    ) external payable;

    /**
     * @notice This function allows a user to batch buy with an array of taker bids (against an array of maker asks).
     * @param takerBids Array of taker bid structs
     * @param makerAsks Array of maker ask structs
     * @param makerSignatures Array of maker signatures
     * @param merkleTrees Array of merkle tree structs if the signature contains multiple maker orders
     * @param affiliate Affiliate address
     * @param isAtomic Whether the execution should be atomic
     *        i.e. whether it should revert if 1 or more transactions fail
     */
    function executeMultipleTakerBids(
        OrderStructs.Taker[] calldata takerBids,
        OrderStructs.Maker[] calldata makerAsks,
        bytes[] calldata makerSignatures,
        OrderStructs.MerkleTree[] calldata merkleTrees,
        address affiliate,
        bool isAtomic
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title INonceManager
 * @author LooksRare protocol team (👀,💎)
 */
interface INonceManager {
    /**
     * @notice This struct contains the global bid and ask nonces of a user.
     * @param bidNonce Bid nonce
     * @param askNonce Ask nonce
     */
    struct UserBidAskNonces {
        uint256 bidNonce;
        uint256 askNonce;
    }

    /**
     * @notice It is emitted when there is an update of the global bid/ask nonces for a user.
     * @param user Address of the user
     * @param bidNonce New bid nonce
     * @param askNonce New ask nonce
     */
    event NewBidAskNonces(address user, uint256 bidNonce, uint256 askNonce);

    /**
     * @notice It is emitted when order nonces are cancelled for a user.
     * @param user Address of the user
     * @param orderNonces Array of order nonces cancelled
     */
    event OrderNoncesCancelled(address user, uint256[] orderNonces);

    /**
     * @notice It is emitted when subset nonces are cancelled for a user.
     * @param user Address of the user
     * @param subsetNonces Array of subset nonces cancelled
     */
    event SubsetNoncesCancelled(address user, uint256[] subsetNonces);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IRoyaltyFeeRegistry
 * @author LooksRare protocol team (👀,💎)
 */
interface IRoyaltyFeeRegistry {
    /**
     * @notice This function returns the royalty information for a collection at a given transaction price.
     * @param collection Collection address
     * @param price Transaction price
     * @return receiver Receiver address
     * @return royaltyFee Royalty fee amount
     */
    function royaltyInfo(
        address collection,
        uint256 price
    ) external view returns (address receiver, uint256 royaltyFee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

/**
 * @title IStrategy
 * @author LooksRare protocol team (👀,💎)
 */
interface IStrategy {
    /**
     * @notice Validate *only the maker* order under the context of the chosen strategy. It does not revert if
     *         the maker order is invalid. Instead it returns false and the error's 4 bytes selector.
     * @param makerOrder Maker struct (maker specific parameters for the execution)
     * @param functionSelector Function selector for the strategy
     * @return isValid Whether the maker struct is valid
     * @return errorSelector If isValid is false, it returns the error's 4 bytes selector
     */
    function isMakerOrderValid(
        OrderStructs.Maker calldata makerOrder,
        bytes4 functionSelector
    ) external view returns (bool isValid, bytes4 errorSelector);

    /**
     * @notice This function acts as a safety check for the protocol's owner when adding new execution strategies.
     * @return isStrategy Whether it is a LooksRare V2 protocol strategy
     */
    function isLooksRareV2Strategy() external pure returns (bool isStrategy);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStrategyManager
 * @author LooksRare protocol team (👀,💎)
 */
interface IStrategyManager {
    /**
     * @notice This struct contains the parameter of an execution strategy.
     * @param strategyId Id of the new strategy
     * @param standardProtocolFeeBp Standard protocol fee (in basis point)
     * @param minTotalFeeBp Minimum total fee (in basis point)
     * @param maxProtocolFeeBp Maximum protocol fee (in basis point)
     * @param selector Function selector for the transaction to be executed
     * @param isMakerBid Whether the strategyId is for maker bid
     * @param implementation Address of the implementation of the strategy
     */
    struct Strategy {
        bool isActive;
        uint16 standardProtocolFeeBp;
        uint16 minTotalFeeBp;
        uint16 maxProtocolFeeBp;
        bytes4 selector;
        bool isMakerBid;
        address implementation;
    }

    /**
     * @notice It is emitted when a new strategy is added.
     * @param strategyId Id of the new strategy
     * @param standardProtocolFeeBp Standard protocol fee (in basis point)
     * @param minTotalFeeBp Minimum total fee (in basis point)
     * @param maxProtocolFeeBp Maximum protocol fee (in basis point)
     * @param selector Function selector for the transaction to be executed
     * @param isMakerBid Whether the strategyId is for maker bid
     * @param implementation Address of the implementation of the strategy
     */
    event NewStrategy(
        uint256 strategyId,
        uint16 standardProtocolFeeBp,
        uint16 minTotalFeeBp,
        uint16 maxProtocolFeeBp,
        bytes4 selector,
        bool isMakerBid,
        address implementation
    );

    /**
     * @notice It is emitted when an existing strategy is updated.
     * @param strategyId Id of the strategy
     * @param isActive Whether the strategy is active (or not) after the update
     * @param standardProtocolFeeBp Standard protocol fee (in basis point)
     * @param minTotalFeeBp Minimum total fee (in basis point)
     */
    event StrategyUpdated(uint256 strategyId, bool isActive, uint16 standardProtocolFeeBp, uint16 minTotalFeeBp);

    /**
     * @notice If the strategy has not set properly its implementation contract.
     * @dev It can only be returned for owner operations.
     */
    error NotV2Strategy();

    /**
     * @notice It is returned if the strategy has no selector.
     * @dev It can only be returned for owner operations.
     */
    error StrategyHasNoSelector();

    /**
     * @notice It is returned if the strategyId is invalid.
     */
    error StrategyNotUsed();

    /**
     * @notice It is returned if the strategy's protocol fee is too high.
     * @dev It can only be returned for owner operations.
     */
    error StrategyProtocolFeeTooHigh();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "../enums/CollectionType.sol";

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ITransferManager {
    /**
     * @notice This struct is only used for transferBatchItemsAcrossCollections.
     * @param collection Collection address
     * @param collectionType 0 for ERC721, 1 for ERC1155
     * @param itemIds Array of item ids to transfer
     * @param amounts Array of amounts to transfer
     */
    struct BatchTransferItem {
        address collection;
        CollectionType collectionType;
        uint256[] itemIds;
        uint256[] amounts;
    }

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are granted by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsGranted(address user, address[] operators);

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are revoked by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsRemoved(address user, address[] operators);

    /**
     * @notice It is emitted if a new operator is added to the global allowlist.
     * @param operator Operator address
     */
    event OperatorAllowed(address operator);

    /**
     * @notice It is emitted if an operator is removed from the global allowlist.
     * @param operator Operator address
     */
    event OperatorRemoved(address operator);

    /**
     * @notice It is returned if the operator to approve has already been approved by the user.
     */
    error OperatorAlreadyApprovedByUser();

    /**
     * @notice It is returned if the operator to revoke has not been previously approved by the user.
     */
    error OperatorNotApprovedByUser();

    /**
     * @notice It is returned if the transfer caller is already allowed by the owner.
     * @dev This error can only be returned for owner operations.
     */
    error OperatorAlreadyAllowed();

    /**
     * @notice It is returned if the operator to approve is not in the global allowlist defined by the owner.
     * @dev This error can be returned if the user tries to grant approval to an operator address not in the
     *      allowlist or if the owner tries to remove the operator from the global allowlist.
     */
    error OperatorNotAllowed();

    /**
     * @notice It is returned if the transfer caller is invalid.
     *         For a transfer called to be valid, the operator must be in the global allowlist and
     *         approved by the 'from' user.
     */
    error TransferCallerInvalid();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Libraries
import {OrderStructs} from "../../libraries/OrderStructs.sol";

/**
 * @title MerkleProofCalldataWithNodes
 * @notice This library is adjusted from the work of OpenZeppelin.
 *         It is based on the 4.7.0 (utils/cryptography/MerkleProof.sol).
 * @author OpenZeppelin (adjusted by LooksRare)
 */
library MerkleProofCalldataWithNodes {
    /**
     * @notice This returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
     *         For this, a `proof` must be provided, containing sibling hashes on the branch from the leaf to the
     *         root of the tree. Each pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verifyCalldata(
        OrderStructs.MerkleTreeNode[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @notice This returns the rebuilt hash obtained by traversing a Merkle tree up from `leaf` using `proof`.
     *         A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
     *         When processing the proof, the pairs of leafs & pre-images are assumed to be sorted.
     */
    function processProofCalldata(
        OrderStructs.MerkleTreeNode[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        uint256 length = proof.length;

        for (uint256 i = 0; i < length; ) {
            if (proof[i].position == OrderStructs.MerkleTreeNodePosition.Left) {
                computedHash = _efficientHash(proof[i].value, computedHash);
            } else {
                computedHash = _efficientHash(computedHash, proof[i].value);
            }
            unchecked {
                ++i;
            }
        }
        return computedHash;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Enums
import {CollectionType} from "../enums/CollectionType.sol";
import {QuoteType} from "../enums/QuoteType.sol";

/**
 * @title OrderStructs
 * @notice This library contains all order struct types for the LooksRare protocol (v2).
 * @author LooksRare protocol team (👀,💎)
 */
library OrderStructs {
    /**
     * 1. Maker struct
     */

    /**
     * @notice Maker is the struct for a maker order.
     * @param quoteType Quote type (i.e. 0 = BID, 1 = ASK)
     * @param globalNonce Global user order nonce for maker orders
     * @param subsetNonce Subset nonce (shared across bid/ask maker orders)
     * @param orderNonce Order nonce (it can be shared across bid/ask maker orders)
     * @param strategyId Strategy id
     * @param collectionType Collection type (i.e. 0 = ERC721, 1 = ERC1155)
     * @param collection Collection address
     * @param currency Currency address (@dev address(0) = ETH)
     * @param signer Signer address
     * @param startTime Start timestamp
     * @param endTime End timestamp
     * @param price Minimum price for maker ask, maximum price for maker bid
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @param additionalParameters Extra data specific for the order
     */
    struct Maker {
        QuoteType quoteType;
        uint256 globalNonce;
        uint256 subsetNonce;
        uint256 orderNonce;
        uint256 strategyId;
        CollectionType collectionType;
        address collection;
        address currency;
        address signer;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256[] itemIds;
        uint256[] amounts;
        bytes additionalParameters;
    }

    /**
     * 2. Taker struct
     */

    /**
     * @notice Taker is the struct for a taker ask/bid order. It contains the parameters required for a direct purchase.
     * @dev Taker struct is matched against MakerAsk/MakerBid structs at the protocol level.
     * @param recipient Recipient address (to receive NFTs or non-fungible tokens)
     * @param additionalParameters Extra data specific for the order
     */
    struct Taker {
        address recipient;
        bytes additionalParameters;
    }

    /**
     * 3. Merkle tree struct
     */

    enum MerkleTreeNodePosition { Left, Right }

    /**
     * @notice MerkleTreeNode is a MerkleTree's node.
     * @param value It can be an order hash or a proof
     * @param position The node's position in its branch.
     *                 It can be left or right or none
     *                 (before the tree is sorted).
     */
    struct MerkleTreeNode {
        bytes32 value;
        MerkleTreeNodePosition position;
    }

    /**
     * @notice MerkleTree is the struct for a merkle tree of order hashes.
     * @dev A Merkle tree can be computed with order hashes.
     *      It can contain order hashes from both maker bid and maker ask structs.
     * @param root Merkle root
     * @param proof Array containing the merkle proof
     */
    struct MerkleTree {
        bytes32 root;
        MerkleTreeNode[] proof;
    }

    /**
     * 4. Constants
     */

    /**
     * @notice This is the type hash constant used to compute the maker order hash.
     */
    bytes32 internal constant _MAKER_TYPEHASH =
        keccak256(
            "Maker("
                "uint8 quoteType,"
                "uint256 globalNonce,"
                "uint256 subsetNonce,"
                "uint256 orderNonce,"
                "uint256 strategyId,"
                "uint8 collectionType,"
                "address collection,"
                "address currency,"
                "address signer,"
                "uint256 startTime,"
                "uint256 endTime,"
                "uint256 price,"
                "uint256[] itemIds,"
                "uint256[] amounts,"
                "bytes additionalParameters"
            ")"
        );

    /**
     * 5. Hash functions
     */

    /**
     * @notice This function is used to compute the order hash for a maker struct.
     * @param maker Maker order struct
     * @return makerHash Hash of the maker struct
     */
    function hash(Maker memory maker) internal pure returns (bytes32) {
        // Encoding is done into two parts to avoid stack too deep issues
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        _MAKER_TYPEHASH,
                        maker.quoteType,
                        maker.globalNonce,
                        maker.subsetNonce,
                        maker.orderNonce,
                        maker.strategyId,
                        maker.collectionType,
                        maker.collection,
                        maker.currency
                    ),
                    abi.encode(
                        maker.signer,
                        maker.startTime,
                        maker.endTime,
                        maker.price,
                        keccak256(abi.encodePacked(maker.itemIds)),
                        keccak256(abi.encodePacked(maker.amounts)),
                        keccak256(maker.additionalParameters)
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {SignatureCheckerCalldata} from "@looksrare/contracts-libs/contracts/SignatureCheckerCalldata.sol";
import {LowLevelETHReturnETHIfAnyExceptOneWei} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelETHReturnETHIfAnyExceptOneWei.sol";
import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";

// OpenZeppelin's library (adjusted) for verifying Merkle proofs
import {MerkleProofCalldataWithNodes} from "./libraries/OpenZeppelin/MerkleProofCalldataWithNodes.sol";

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Interfaces
import {ILooksRareProtocol} from "./interfaces/ILooksRareProtocol.sol";

// Shared errors
import {CallerInvalid, CurrencyInvalid, LengthsInvalid, MerkleProofInvalid, MerkleProofTooLarge, QuoteTypeInvalid} from "./errors/SharedErrors.sol";

// Direct dependencies
import {TransferSelectorNFT} from "./TransferSelectorNFT.sol";
import {BatchOrderTypehashRegistry} from "./BatchOrderTypehashRegistry.sol";

// Constants
import {MAX_CALLDATA_PROOF_LENGTH, ONE_HUNDRED_PERCENT_IN_BP} from "./constants/NumericConstants.sol";

// Enums
import {QuoteType} from "./enums/QuoteType.sol";

/**
 * @title LooksRareProtocol
 * @notice This contract is the core smart contract of the LooksRare protocol ("v2").
 *         It is the main entry point for users to initiate transactions with taker orders
 *         and manage the cancellation of maker orders, which exist off-chain.
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRAR'''''''''''''''''''''''''''''''''''OOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKS:.                                        .;OOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOO,.                                            .,KSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRAREL'                ..',;:LOOKS::;,'..                'RARELOOKSRARELOOKSR
LOOKSRARELOOKSRAR.              .,:LOOKSRARELOOKSRARELO:,.              .RELOOKSRARELOOKSR
LOOKSRARELOOKS:.             .;RARELOOKSRARELOOKSRARELOOKSl;.             .:OOKSRARELOOKSR
LOOKSRARELOO;.            .'OKSRARELOOKSRARELOOKSRARELOOKSRARE'.            .;KSRARELOOKSR
LOOKSRAREL,.            .,LOOKSRARELOOK:;;:"""":;;;lELOOKSRARELO,.            .,RARELOOKSR
LOOKSRAR.             .;okLOOKSRAREx:.              .;OOKSRARELOOK;.             .RELOOKSR
LOOKS:.             .:dOOOLOOKSRARE'      .''''..     .OKSRARELOOKSR:.             .LOOKSR
LOx;.             .cKSRARELOOKSRAR'     'LOOKSRAR'     .KSRARELOOKSRARc..            .OKSR
L;.             .cxOKSRARELOOKSRAR.    .LOOKS.RARE'     ;kRARELOOKSRARExc.             .;R
LO'             .;oOKSRARELOOKSRAl.    .LOOKS.RARE.     :kRARELOOKSRAREo;.             'SR
LOOK;.            .,KSRARELOOKSRAx,     .;LOOKSR;.     .oSRARELOOKSRAo,.            .;OKSR
LOOKSk:.            .'RARELOOKSRARd;.      ....       'oOOOOOOOOOOxc'.            .:LOOKSR
LOOKSRARc.             .:dLOOKSRAREko;.            .,lxOOOOOOOOOd:.             .ARELOOKSR
LOOKSRARELo'             .;oOKSRARELOOxoc;,....,;:ldkOOOOOOOOkd;.             'SRARELOOKSR
LOOKSRARELOOd,.            .,lSRARELOOKSRARELOOKSRARELOOKSRkl,.            .,OKSRARELOOKSR
LOOKSRARELOOKSx;.            ..;oxELOOKSRARELOOKSRARELOkxl:..            .:LOOKSRARELOOKSR
LOOKSRARELOOKSRARc.              .':cOKSRARELOOKSRALOc;'.              .ARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELl'                 ...'',,,,''...                 'SRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOo,.                                          .,OKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSx;.                                      .;xOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLO:.                                  .:SRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKl.                              .lOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRo'.                        .'oWENV2?LOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARd;.                    .;xRELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELO:.                .:kRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKl.            .cOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRo'        'oLOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARE,.  .,dRELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareProtocol is
    ILooksRareProtocol,
    TransferSelectorNFT,
    LowLevelETHReturnETHIfAnyExceptOneWei,
    LowLevelWETH,
    LowLevelERC20Transfer,
    BatchOrderTypehashRegistry
{
    using OrderStructs for OrderStructs.Maker;

    /**
     * @notice Wrapped ETH.
     */
    address public immutable WETH;

    /**
     * @notice Current chainId.
     */
    uint256 public chainId;

    /**
     * @notice Current domain separator.
     */
    bytes32 public domainSeparator;

    /**
     * @notice This variable is used as the gas limit for a ETH transfer.
     *         If a standard ETH transfer fails within this gas limit, ETH will get wrapped to WETH
     *         and transferred to the initial recipient.
     */
    uint256 private _gasLimitETHTransfer = 2_300;

    /**
     * @notice Constructor
     * @param _owner Owner address
     * @param _protocolFeeRecipient Protocol fee recipient address
     * @param _transferManager Transfer manager address
     * @param _weth Wrapped ETH address
     */
    constructor(
        address _owner,
        address _protocolFeeRecipient,
        address _transferManager,
        address _weth
    ) TransferSelectorNFT(_owner, _protocolFeeRecipient, _transferManager) {
        _updateDomainSeparator();
        WETH = _weth;
    }

    /**
     * @inheritdoc ILooksRareProtocol
     */
    function executeTakerAsk(
        OrderStructs.Taker calldata takerAsk,
        OrderStructs.Maker calldata makerBid,
        bytes calldata makerSignature,
        OrderStructs.MerkleTree calldata merkleTree,
        address affiliate
    ) external nonReentrant {
        address currency = makerBid.currency;

        // Verify whether the currency is allowed and is not ETH (address(0))
        if (!isCurrencyAllowed[currency] || currency == address(0)) {
            revert CurrencyInvalid();
        }

        address signer = makerBid.signer;
        bytes32 orderHash = makerBid.hash();
        _verifyMerkleProofOrOrderHash(merkleTree, orderHash, makerSignature, signer);

        // Execute the transaction and fetch protocol fee amount
        uint256 totalProtocolFeeAmount = _executeTakerAsk(takerAsk, makerBid, orderHash);

        // Pay protocol fee (and affiliate fee if any)
        _payProtocolFeeAndAffiliateFee(currency, signer, affiliate, totalProtocolFeeAmount);
    }

    /**
     * @inheritdoc ILooksRareProtocol
     */
    function executeTakerBid(
        OrderStructs.Taker calldata takerBid,
        OrderStructs.Maker calldata makerAsk,
        bytes calldata makerSignature,
        OrderStructs.MerkleTree calldata merkleTree,
        address affiliate
    ) external payable nonReentrant {
        address currency = makerAsk.currency;

        // Verify whether the currency is allowed for trading.
        if (!isCurrencyAllowed[currency]) {
            revert CurrencyInvalid();
        }

        bytes32 orderHash = makerAsk.hash();
        _verifyMerkleProofOrOrderHash(merkleTree, orderHash, makerSignature, makerAsk.signer);

        // Execute the transaction and fetch protocol fee amount
        uint256 totalProtocolFeeAmount = _executeTakerBid(takerBid, makerAsk, msg.sender, orderHash);

        // Pay protocol fee amount (and affiliate fee if any)
        _payProtocolFeeAndAffiliateFee(currency, msg.sender, affiliate, totalProtocolFeeAmount);

        // Return ETH if any
        _returnETHIfAnyWithOneWeiLeft();
    }

    /**
     * @inheritdoc ILooksRareProtocol
     */
    function executeMultipleTakerBids(
        OrderStructs.Taker[] calldata takerBids,
        OrderStructs.Maker[] calldata makerAsks,
        bytes[] calldata makerSignatures,
        OrderStructs.MerkleTree[] calldata merkleTrees,
        address affiliate,
        bool isAtomic
    ) external payable nonReentrant {
        uint256 length = takerBids.length;
        if (
            length == 0 ||
            (makerAsks.length ^ length) | (makerSignatures.length ^ length) | (merkleTrees.length ^ length) != 0
        ) {
            revert LengthsInvalid();
        }

        // Verify whether the currency at index = 0 is allowed for trading
        address currency = makerAsks[0].currency;
        if (!isCurrencyAllowed[currency]) {
            revert CurrencyInvalid();
        }

        {
            // Initialize protocol fee amount
            uint256 totalProtocolFeeAmount;

            // If atomic, it uses the executeTakerBid function.
            // If not atomic, it uses a catch/revert pattern with external function.
            if (isAtomic) {
                for (uint256 i; i < length; ) {
                    OrderStructs.Maker calldata makerAsk = makerAsks[i];

                    // Verify the currency is the same
                    if (i != 0) {
                        if (makerAsk.currency != currency) {
                            revert CurrencyInvalid();
                        }
                    }

                    OrderStructs.Taker calldata takerBid = takerBids[i];
                    bytes32 orderHash = makerAsk.hash();

                    {
                        _verifyMerkleProofOrOrderHash(merkleTrees[i], orderHash, makerSignatures[i], makerAsk.signer);

                        // Execute the transaction and add protocol fee
                        totalProtocolFeeAmount += _executeTakerBid(takerBid, makerAsk, msg.sender, orderHash);

                        unchecked {
                            ++i;
                        }
                    }
                }
            } else {
                for (uint256 i; i < length; ) {
                    OrderStructs.Maker calldata makerAsk = makerAsks[i];

                    // Verify the currency is the same
                    if (i != 0) {
                        if (makerAsk.currency != currency) {
                            revert CurrencyInvalid();
                        }
                    }

                    OrderStructs.Taker calldata takerBid = takerBids[i];
                    bytes32 orderHash = makerAsk.hash();

                    {
                        _verifyMerkleProofOrOrderHash(merkleTrees[i], orderHash, makerSignatures[i], makerAsk.signer);

                        try this.restrictedExecuteTakerBid(takerBid, makerAsk, msg.sender, orderHash) returns (
                            uint256 protocolFeeAmount
                        ) {
                            totalProtocolFeeAmount += protocolFeeAmount;
                        } catch {}

                        unchecked {
                            ++i;
                        }
                    }
                }
            }

            // Pay protocol fee (and affiliate fee if any)
            _payProtocolFeeAndAffiliateFee(currency, msg.sender, affiliate, totalProtocolFeeAmount);
        }

        // Return ETH if any
        _returnETHIfAnyWithOneWeiLeft();
    }

    /**
     * @notice This function is used to do a non-atomic matching in the context of a batch taker bid.
     * @param takerBid Taker bid struct
     * @param makerAsk Maker ask struct
     * @param sender Sender address (i.e. the initial msg sender)
     * @param orderHash Hash of the maker ask order
     * @return protocolFeeAmount Protocol fee amount
     * @dev This function is only callable by this contract. It is used for non-atomic batch order matching.
     */
    function restrictedExecuteTakerBid(
        OrderStructs.Taker calldata takerBid,
        OrderStructs.Maker calldata makerAsk,
        address sender,
        bytes32 orderHash
    ) external returns (uint256 protocolFeeAmount) {
        if (msg.sender != address(this)) {
            revert CallerInvalid();
        }

        protocolFeeAmount = _executeTakerBid(takerBid, makerAsk, sender, orderHash);
    }

    /**
     * @notice This function allows the owner to update the domain separator (if possible).
     * @dev Only callable by owner. If there is a fork of the network with a new chainId,
     *      it allows the owner to reset the domain separator for the new chain id.
     */
    function updateDomainSeparator() external onlyOwner {
        if (block.chainid != chainId) {
            _updateDomainSeparator();
            emit NewDomainSeparator();
        } else {
            revert SameDomainSeparator();
        }
    }

    /**
     * @notice This function allows the owner to update the maximum ETH gas limit for a standard transfer.
     * @param newGasLimitETHTransfer New gas limit for ETH transfer
     * @dev Only callable by owner.
     */
    function updateETHGasLimitForTransfer(uint256 newGasLimitETHTransfer) external onlyOwner {
        if (newGasLimitETHTransfer < 2_300) {
            revert NewGasLimitETHTransferTooLow();
        }

        _gasLimitETHTransfer = newGasLimitETHTransfer;

        emit NewGasLimitETHTransfer(newGasLimitETHTransfer);
    }

    /**
     * @notice This function is internal and is used to execute a taker ask (against a maker bid).
     * @param takerAsk Taker ask order struct
     * @param makerBid Maker bid order struct
     * @param orderHash Hash of the maker bid order
     * @return protocolFeeAmount Protocol fee amount
     */
    function _executeTakerAsk(
        OrderStructs.Taker calldata takerAsk,
        OrderStructs.Maker calldata makerBid,
        bytes32 orderHash
    ) internal returns (uint256) {
        if (makerBid.quoteType != QuoteType.Bid) {
            revert QuoteTypeInvalid();
        }

        address signer = makerBid.signer;
        {
            bytes32 userOrderNonceStatus = userOrderNonce[signer][makerBid.orderNonce];
            // Verify nonces
            if (
                userBidAskNonces[signer].bidNonce != makerBid.globalNonce ||
                userSubsetNonce[signer][makerBid.subsetNonce] ||
                (userOrderNonceStatus != bytes32(0) && userOrderNonceStatus != orderHash)
            ) {
                revert NoncesInvalid();
            }
        }

        (
            uint256[] memory itemIds,
            uint256[] memory amounts,
            address[2] memory recipients,
            uint256[3] memory feeAmounts,
            bool isNonceInvalidated
        ) = _executeStrategyForTakerOrder(takerAsk, makerBid, msg.sender);

        // Order nonce status is updated
        _updateUserOrderNonce(isNonceInvalidated, signer, makerBid.orderNonce, orderHash);

        // Taker action goes first
        _transferNFT(makerBid.collection, makerBid.collectionType, msg.sender, signer, itemIds, amounts);

        // Maker action goes second
        _transferToAskRecipientAndCreatorIfAny(recipients, feeAmounts, makerBid.currency, signer);

        emit TakerAsk(
            NonceInvalidationParameters({
                orderHash: orderHash,
                orderNonce: makerBid.orderNonce,
                isNonceInvalidated: isNonceInvalidated
            }),
            msg.sender,
            signer,
            makerBid.strategyId,
            makerBid.currency,
            makerBid.collection,
            itemIds,
            amounts,
            recipients,
            feeAmounts
        );

        // It returns the protocol fee amount
        return feeAmounts[2];
    }

    /**
     * @notice This function is internal and is used to execute a taker bid (against a maker ask).
     * @param takerBid Taker bid order struct
     * @param makerAsk Maker ask order struct
     * @param sender Sender of the transaction (i.e. msg.sender)
     * @param orderHash Hash of the maker ask order
     * @return protocolFeeAmount Protocol fee amount
     */
    function _executeTakerBid(
        OrderStructs.Taker calldata takerBid,
        OrderStructs.Maker calldata makerAsk,
        address sender,
        bytes32 orderHash
    ) internal returns (uint256) {
        if (makerAsk.quoteType != QuoteType.Ask) {
            revert QuoteTypeInvalid();
        }

        address signer = makerAsk.signer;
        {
            // Verify nonces
            bytes32 userOrderNonceStatus = userOrderNonce[signer][makerAsk.orderNonce];

            if (
                userBidAskNonces[signer].askNonce != makerAsk.globalNonce ||
                userSubsetNonce[signer][makerAsk.subsetNonce] ||
                (userOrderNonceStatus != bytes32(0) && userOrderNonceStatus != orderHash)
            ) {
                revert NoncesInvalid();
            }
        }

        (
            uint256[] memory itemIds,
            uint256[] memory amounts,
            address[2] memory recipients,
            uint256[3] memory feeAmounts,
            bool isNonceInvalidated
        ) = _executeStrategyForTakerOrder(takerBid, makerAsk, msg.sender);

        // Order nonce status is updated
        _updateUserOrderNonce(isNonceInvalidated, signer, makerAsk.orderNonce, orderHash);

        // Taker action goes first
        _transferToAskRecipientAndCreatorIfAny(recipients, feeAmounts, makerAsk.currency, sender);

        // Maker action goes second
        _transferNFT(
            makerAsk.collection,
            makerAsk.collectionType,
            signer,
            takerBid.recipient == address(0) ? sender : takerBid.recipient,
            itemIds,
            amounts
        );

        emit TakerBid(
            NonceInvalidationParameters({
                orderHash: orderHash,
                orderNonce: makerAsk.orderNonce,
                isNonceInvalidated: isNonceInvalidated
            }),
            sender,
            takerBid.recipient == address(0) ? sender : takerBid.recipient,
            makerAsk.strategyId,
            makerAsk.currency,
            makerAsk.collection,
            itemIds,
            amounts,
            recipients,
            feeAmounts
        );

        // It returns the protocol fee amount
        return feeAmounts[2];
    }

    /**
     * @notice This function is internal and is used to pay the protocol fee and affiliate fee (if any).
     * @param currency Currency address to transfer (address(0) is ETH)
     * @param bidUser Bid user address
     * @param affiliate Affiliate address (address(0) if none)
     * @param totalProtocolFeeAmount Total protocol fee amount (denominated in the currency)
     */
    function _payProtocolFeeAndAffiliateFee(
        address currency,
        address bidUser,
        address affiliate,
        uint256 totalProtocolFeeAmount
    ) internal {
        if (totalProtocolFeeAmount != 0) {
            if (affiliate != address(0)) {
                // Check whether affiliate program is active and whether to execute a affiliate logic
                // If so, it adjusts the protocol fee downward.
                if (isAffiliateProgramActive) {
                    uint256 totalAffiliateFeeAmount = (totalProtocolFeeAmount * affiliateRates[affiliate]) /
                        ONE_HUNDRED_PERCENT_IN_BP;

                    if (totalAffiliateFeeAmount != 0) {
                        totalProtocolFeeAmount -= totalAffiliateFeeAmount;

                        // If bid user isn't the affiliate, pay the affiliate.
                        // If currency is ETH, funds are returned to sender at the end of the execution.
                        // If currency is ERC20, funds are not transferred from bidder to bidder
                        // (since it uses transferFrom).
                        if (bidUser != affiliate) {
                            _transferFungibleTokens(currency, bidUser, affiliate, totalAffiliateFeeAmount);
                        }

                        emit AffiliatePayment(affiliate, currency, totalAffiliateFeeAmount);
                    }
                }
            }

            // Transfer remaining protocol fee to the protocol fee recipient
            _transferFungibleTokens(currency, bidUser, protocolFeeRecipient, totalProtocolFeeAmount);
        }
    }

    /**
     * @notice This function is internal and is used to transfer fungible tokens.
     * @param currency Currency address
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Amount (in fungible tokens)
     */
    function _transferFungibleTokens(address currency, address sender, address recipient, uint256 amount) internal {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, recipient, amount, _gasLimitETHTransfer);
        } else {
            _executeERC20TransferFrom(currency, sender, recipient, amount);
        }
    }

    /**
     * @notice This function is private and used to transfer funds to
     *         (1) creator recipient (if any)
     *         (2) ask recipient.
     * @param recipients Recipient addresses
     * @param feeAmounts Fees
     * @param currency Currency address
     * @param bidUser Bid user address
     * @dev It does not send to the 0-th element in the array since it is the protocol fee,
     *      which is paid later in the execution flow.
     */
    function _transferToAskRecipientAndCreatorIfAny(
        address[2] memory recipients,
        uint256[3] memory feeAmounts,
        address currency,
        address bidUser
    ) private {
        // @dev There is no check for address(0) since the ask recipient can never be address(0)
        // If ask recipient is the maker --> the signer cannot be the null address
        // If ask is the taker --> either it is the sender address or
        // if the recipient (in TakerAsk) is set to address(0), it is adjusted to the original taker address
        uint256 sellerProceed = feeAmounts[0];
        if (sellerProceed != 0) {
            _transferFungibleTokens(currency, bidUser, recipients[0], sellerProceed);
        }

        // @dev There is no check for address(0), if the creator recipient is address(0), the fee is set to 0
        uint256 creatorFeeAmount = feeAmounts[1];
        if (creatorFeeAmount != 0) {
            _transferFungibleTokens(currency, bidUser, recipients[1], creatorFeeAmount);
        }
    }

    /**
     * @notice This function is private and used to compute the domain separator and store the current chain id.
     */
    function _updateDomainSeparator() private {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("LooksRareProtocol"),
                keccak256(bytes("2")),
                block.chainid,
                address(this)
            )
        );
        chainId = block.chainid;
    }

    /**
     * @notice This function is internal and is called during the execution of a transaction to decide
     *         how to map the user's order nonce.
     * @param isNonceInvalidated Whether the nonce is being invalidated
     * @param signer Signer address
     * @param orderNonce Maker user order nonce
     * @param orderHash Hash of the order struct
     * @dev If isNonceInvalidated is true, this function invalidates the user order nonce for future execution.
     *      If it is equal to false, this function maps the order hash for this user order nonce
     *      to prevent other order structs sharing the same order nonce to be executed.
     */
    function _updateUserOrderNonce(
        bool isNonceInvalidated,
        address signer,
        uint256 orderNonce,
        bytes32 orderHash
    ) private {
        userOrderNonce[signer][orderNonce] = (isNonceInvalidated ? MAGIC_VALUE_ORDER_NONCE_EXECUTED : orderHash);
    }

    /**
     * @notice This function is private and used to verify the chain id, compute the digest, and verify the signature.
     * @dev If chainId is not equal to the cached chain id, it would revert.
     * @param computedHash Hash of order (maker bid or maker ask) or merkle root
     * @param makerSignature Signature of the maker
     * @param signer Signer address
     */
    function _computeDigestAndVerify(bytes32 computedHash, bytes calldata makerSignature, address signer) private view {
        if (chainId == block.chainid) {
            // \x19\x01 is the standard encoding prefix
            SignatureCheckerCalldata.verify(
                keccak256(abi.encodePacked("\x19\x01", domainSeparator, computedHash)),
                signer,
                makerSignature
            );
        } else {
            revert ChainIdInvalid();
        }
    }

    /**
     * @notice This function is private and called to verify whether the merkle proofs provided for the order hash
     *         are correct or verify the order hash if the order is not part of a merkle tree.
     * @param merkleTree Merkle tree
     * @param orderHash Order hash (can be maker bid hash or maker ask hash)
     * @param signature Maker order signature
     * @param signer Maker address
     * @dev It verifies (1) merkle proof (if necessary) (2) signature is from the expected signer
     */
    function _verifyMerkleProofOrOrderHash(
        OrderStructs.MerkleTree calldata merkleTree,
        bytes32 orderHash,
        bytes calldata signature,
        address signer
    ) private view {
        uint256 proofLength = merkleTree.proof.length;

        if (proofLength != 0) {
            if (proofLength > MAX_CALLDATA_PROOF_LENGTH) {
                revert MerkleProofTooLarge(proofLength);
            }

            if (!MerkleProofCalldataWithNodes.verifyCalldata(merkleTree.proof, merkleTree.root, orderHash)) {
                revert MerkleProofInvalid();
            }

            orderHash = hashBatchOrder(merkleTree.root, proofLength);
        }

        _computeDigestAndVerify(orderHash, signature, signer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces and errors
import {INonceManager} from "./interfaces/INonceManager.sol";
import {LengthsInvalid} from "./errors/SharedErrors.sol";

/**
 * @title NonceManager
 * @notice This contract handles the nonce logic that is used for invalidating maker orders that exist off-chain.
 *         The nonce logic revolves around three parts at the user level:
 *         - order nonce (orders sharing an order nonce are conditional, OCO-like)
 *         - subset (orders can be grouped under a same subset)
 *         - bid/ask (all orders can be executed only if the bid/ask nonce matches the user's one on-chain)
 *         Only the order nonce is invalidated at the time of the execution of a maker order that contains it.
 * @author LooksRare protocol team (👀,💎)
 */
contract NonceManager is INonceManager {
    /**
     * @notice Magic value nonce returned if executed (or cancelled).
     */
    bytes32 public constant MAGIC_VALUE_ORDER_NONCE_EXECUTED = keccak256("ORDER_NONCE_EXECUTED");

    /**
     * @notice This tracks the bid and ask nonces for a user address.
     */
    mapping(address => UserBidAskNonces) public userBidAskNonces;

    /**
     * @notice This checks whether the order nonce for a user was executed or cancelled.
     */
    mapping(address => mapping(uint256 => bytes32)) public userOrderNonce;

    /**
     * @notice This checks whether the subset nonce for a user was cancelled.
     */
    mapping(address => mapping(uint256 => bool)) public userSubsetNonce;

    /**
     * @notice This function allows a user to cancel an array of order nonces.
     * @param orderNonces Array of order nonces
     * @dev It does not check the status of the nonces to save gas
     *      and to prevent revertion if one of the orders is filled in the same
     *      block.
     */
    function cancelOrderNonces(uint256[] calldata orderNonces) external {
        uint256 length = orderNonces.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            userOrderNonce[msg.sender][orderNonces[i]] = MAGIC_VALUE_ORDER_NONCE_EXECUTED;
            unchecked {
                ++i;
            }
        }

        emit OrderNoncesCancelled(msg.sender, orderNonces);
    }

    /**
     * @notice This function allows a user to cancel an array of subset nonces.
     * @param subsetNonces Array of subset nonces
     * @dev It does not check the status of the nonces to save gas.
     */
    function cancelSubsetNonces(uint256[] calldata subsetNonces) external {
        uint256 length = subsetNonces.length;

        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            userSubsetNonce[msg.sender][subsetNonces[i]] = true;
            unchecked {
                ++i;
            }
        }

        emit SubsetNoncesCancelled(msg.sender, subsetNonces);
    }

    /**
     * @notice This function increments a user's bid/ask nonces.
     * @param bid Whether to increment the user bid nonce
     * @param ask Whether to increment the user ask nonce
     * @dev The logic for computing the quasi-random number is inspired by Seaport v1.2.
     *      The pseudo-randomness allows non-deterministic computation of the next ask/bid nonce.
     *      A deterministic increment would make the cancel-all process non-effective in certain cases
     *      (orders signed with a greater ask/bid nonce).
     *      The same quasi-random number is used for incrementing both the bid and ask nonces if both values
     *      are incremented in the same transaction.
     *      If this function is used twice in the same block, it will return the same quasiRandomNumber
     *      but this will not impact the overall business logic.
     */
    function incrementBidAskNonces(bool bid, bool ask) external {
        // Use second half of the previous block hash as a quasi-random number
        uint256 quasiRandomNumber = uint256(blockhash(block.number - 1) >> 128);
        uint256 newBidNonce = userBidAskNonces[msg.sender].bidNonce;
        uint256 newAskNonce = userBidAskNonces[msg.sender].askNonce;

        if (bid) {
            newBidNonce += quasiRandomNumber;
            userBidAskNonces[msg.sender].bidNonce = newBidNonce;
        }

        if (ask) {
            newAskNonce += quasiRandomNumber;
            userBidAskNonces[msg.sender].askNonce = newAskNonce;
        }

        emit NewBidAskNonces(msg.sender, newBidNonce, newAskNonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {CurrencyManager} from "./CurrencyManager.sol";

// Interfaces
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IStrategyManager} from "./interfaces/IStrategyManager.sol";

/**
 * @title StrategyManager
 * @notice This contract handles the addition and the update of execution strategies.
 * @author LooksRare protocol team (👀,💎)
 */
contract StrategyManager is IStrategyManager, CurrencyManager {
    /**
     * @notice This variable keeps the count of how many strategies exist.
     *         It includes strategies that have been removed.
     */
    uint256 private _countStrategies = 1;

    /**
     * @notice This returns the strategy information for a strategy id.
     */
    mapping(uint256 => Strategy) public strategyInfo;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) CurrencyManager(_owner) {
        strategyInfo[0] = Strategy({
            isActive: true,
            standardProtocolFeeBp: 150,
            minTotalFeeBp: 200,
            maxProtocolFeeBp: 300,
            selector: bytes4(0),
            isMakerBid: false,
            implementation: address(0)
        });

        emit NewStrategy(0, 150, 200, 300, bytes4(0), false, address(0));
    }

    /**
     * @notice This function allows the owner to add a new execution strategy to the protocol.
     * @param standardProtocolFeeBp Standard protocol fee (in basis point)
     * @param minTotalFeeBp Minimum total fee (in basis point)
     * @param maxProtocolFeeBp Maximum protocol fee (in basis point)
     * @param selector Function selector for the strategy
     * @param isMakerBid Whether the function selector is for maker bid
     * @param implementation Implementation address
     * @dev Strategies have an id that is incremental.
     *      Only callable by owner.
     */
    function addStrategy(
        uint16 standardProtocolFeeBp,
        uint16 minTotalFeeBp,
        uint16 maxProtocolFeeBp,
        bytes4 selector,
        bool isMakerBid,
        address implementation
    ) external onlyOwner {
        if (minTotalFeeBp > maxProtocolFeeBp || standardProtocolFeeBp > minTotalFeeBp || maxProtocolFeeBp > 500) {
            revert StrategyProtocolFeeTooHigh();
        }

        if (selector == bytes4(0)) {
            revert StrategyHasNoSelector();
        }

        if (!IStrategy(implementation).isLooksRareV2Strategy()) {
            revert NotV2Strategy();
        }

        strategyInfo[_countStrategies] = Strategy({
            isActive: true,
            standardProtocolFeeBp: standardProtocolFeeBp,
            minTotalFeeBp: minTotalFeeBp,
            maxProtocolFeeBp: maxProtocolFeeBp,
            selector: selector,
            isMakerBid: isMakerBid,
            implementation: implementation
        });

        emit NewStrategy(
            _countStrategies++,
            standardProtocolFeeBp,
            minTotalFeeBp,
            maxProtocolFeeBp,
            selector,
            isMakerBid,
            implementation
        );
    }

    /**
     * @notice This function allows the owner to update parameters for an existing execution strategy.
     * @param strategyId Strategy id
     * @param isActive Whether the strategy must be active
     * @param newStandardProtocolFee New standard protocol fee (in basis point)
     * @param newMinTotalFee New minimum total fee (in basis point)
     * @dev Only callable by owner.
     */
    function updateStrategy(
        uint256 strategyId,
        bool isActive,
        uint16 newStandardProtocolFee,
        uint16 newMinTotalFee
    ) external onlyOwner {
        if (strategyId >= _countStrategies) {
            revert StrategyNotUsed();
        }

        if (newMinTotalFee > strategyInfo[strategyId].maxProtocolFeeBp || newStandardProtocolFee > newMinTotalFee) {
            revert StrategyProtocolFeeTooHigh();
        }

        strategyInfo[strategyId].isActive = isActive;
        strategyInfo[strategyId].standardProtocolFeeBp = newStandardProtocolFee;
        strategyInfo[strategyId].minTotalFeeBp = newMinTotalFee;

        emit StrategyUpdated(strategyId, isActive, newStandardProtocolFee, newMinTotalFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";

// Interfaces and errors
import {ITransferManager} from "./interfaces/ITransferManager.sol";
import {AmountInvalid, LengthsInvalid} from "./errors/SharedErrors.sol";

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "./enums/CollectionType.sol";

/**
 * @title TransferManager
 * @notice This contract provides the transfer functions for ERC721/ERC1155 for contracts that require them.
 *         Collection type "0" refers to ERC721 transfer functions.
 *         Collection type "1" refers to ERC1155 transfer functions.
 * @dev "Safe" transfer functions for ERC721 are not implemented since they come with added gas costs
 *       to verify if the recipient is a contract as it requires verifying the receiver interface is valid.
 * @author LooksRare protocol team (👀,💎)
 */
contract TransferManager is ITransferManager, LowLevelERC721Transfer, LowLevelERC1155Transfer, OwnableTwoSteps {
    /**
     * @notice This returns whether the user has approved the operator address.
     * The first address is the user and the second address is the operator (e.g. LooksRareProtocol).
     */
    mapping(address => mapping(address => bool)) public hasUserApprovedOperator;

    /**
     * @notice This returns whether the operator address is allowed by this contract's owner.
     */
    mapping(address => bool) public isOperatorAllowed;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @notice This function transfers items for a single ERC721 collection.
     * @param collection Collection address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     */
    function transferItemsERC721(
        address collection,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        for (uint256 i; i < length; ) {
            if (amounts[i] != 1) {
                revert AmountInvalid();
            }
            _executeERC721TransferFrom(collection, from, to, itemIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function transfers items for a single ERC1155 collection.
     * @param collection Collection address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @dev It does not allow batch transferring if from = msg.sender since native function should be used.
     */
    function transferItemsERC1155(
        address collection,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;

        if (length == 0 || amounts.length != length) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        if (length == 1) {
            if (amounts[0] == 0) {
                revert AmountInvalid();
            }
            _executeERC1155SafeTransferFrom(collection, from, to, itemIds[0], amounts[0]);
        } else {
            for (uint256 i; i < length; ) {
                if (amounts[i] == 0) {
                    revert AmountInvalid();
                }

                unchecked {
                    ++i;
                }
            }
            _executeERC1155SafeBatchTransferFrom(collection, from, to, itemIds, amounts);
        }
    }

    /**
     * @notice This function transfers items across an array of collections that can be both ERC721 and ERC1155.
     * @param items Array of BatchTransferItem
     * @param from Sender address
     * @param to Recipient address
     */
    function transferBatchItemsAcrossCollections(
        BatchTransferItem[] calldata items,
        address from,
        address to
    ) external {
        uint256 itemsLength = items.length;

        if (itemsLength == 0) {
            revert LengthsInvalid();
        }

        if (from != msg.sender) {
            _isOperatorValidForTransfer(from, msg.sender);
        }

        for (uint256 i; i < itemsLength; ) {
            uint256[] calldata itemIds = items[i].itemIds;
            uint256 itemIdsLengthForSingleCollection = itemIds.length;
            uint256[] calldata amounts = items[i].amounts;

            if (itemIdsLengthForSingleCollection == 0 || amounts.length != itemIdsLengthForSingleCollection) {
                revert LengthsInvalid();
            }

            CollectionType collectionType = items[i].collectionType;
            if (collectionType == CollectionType.ERC721) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] != 1) {
                        revert AmountInvalid();
                    }
                    _executeERC721TransferFrom(items[i].collection, from, to, itemIds[j]);
                    unchecked {
                        ++j;
                    }
                }
            } else if (collectionType == CollectionType.ERC1155) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] == 0) {
                        revert AmountInvalid();
                    }

                    unchecked {
                        ++j;
                    }
                }
                _executeERC1155SafeBatchTransferFrom(items[i].collection, from, to, itemIds, amounts);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function allows a user to grant approvals for an array of operators.
     *         Users cannot grant approvals if the operator is not allowed by this contract's owner.
     * @param operators Array of operator addresses
     * @dev Each operator address must be globally allowed to be approved.
     */
    function grantApprovals(address[] calldata operators) external {
        uint256 length = operators.length;

        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!isOperatorAllowed[operator]) {
                revert OperatorNotAllowed();
            }

            if (hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorAlreadyApprovedByUser();
            }

            hasUserApprovedOperator[msg.sender][operator] = true;

            unchecked {
                ++i;
            }
        }

        emit ApprovalsGranted(msg.sender, operators);
    }

    /**
     * @notice This function allows a user to revoke existing approvals for an array of operators.
     * @param operators Array of operator addresses
     * @dev Each operator address must be approved at the user level to be revoked.
     */
    function revokeApprovals(address[] calldata operators) external {
        uint256 length = operators.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorNotApprovedByUser();
            }

            delete hasUserApprovedOperator[msg.sender][operator];
            unchecked {
                ++i;
            }
        }

        emit ApprovalsRemoved(msg.sender, operators);
    }

    /**
     * @notice This function allows an operator to be added for the shared transfer system.
     *         Once the operator is allowed, users can grant NFT approvals to this operator.
     * @param operator Operator address to allow
     * @dev Only callable by owner.
     */
    function allowOperator(address operator) external onlyOwner {
        if (isOperatorAllowed[operator]) {
            revert OperatorAlreadyAllowed();
        }

        isOperatorAllowed[operator] = true;

        emit OperatorAllowed(operator);
    }

    /**
     * @notice This function allows the user to remove an operator for the shared transfer system.
     * @param operator Operator address to remove
     * @dev Only callable by owner.
     */
    function removeOperator(address operator) external onlyOwner {
        if (!isOperatorAllowed[operator]) {
            revert OperatorNotAllowed();
        }

        delete isOperatorAllowed[operator];

        emit OperatorRemoved(operator);
    }

    /**
     * @notice This function is internal and verifies whether the transfer
     *         (by an operator on behalf of a user) is valid. If not, it reverts.
     * @param user User address
     * @param operator Operator address
     */
    function _isOperatorValidForTransfer(address user, address operator) private view {
        if (isOperatorAllowed[operator] && hasUserApprovedOperator[user][operator]) {
            return;
        }

        revert TransferCallerInvalid();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Direct dependencies
import {PackableReentrancyGuard} from "@looksrare/contracts-libs/contracts/PackableReentrancyGuard.sol";
import {ExecutionManager} from "./ExecutionManager.sol";
import {TransferManager} from "./TransferManager.sol";

// Libraries
import {OrderStructs} from "./libraries/OrderStructs.sol";

// Enums
import {CollectionType} from "./enums/CollectionType.sol";

/**
 * @title TransferSelectorNFT
 * @notice This contract handles the logic for transferring non-fungible items.
 * @author LooksRare protocol team (👀,💎)
 */
contract TransferSelectorNFT is ExecutionManager, PackableReentrancyGuard {
    /**
     * @notice Transfer manager for ERC721 and ERC1155.
     */
    TransferManager public immutable transferManager;

    /**
     * @notice Constructor
     * @param _owner Owner address
     * @param _protocolFeeRecipient Protocol fee recipient address
     * @param _transferManager Address of the transfer manager for ERC721/ERC1155
     */
    constructor(
        address _owner,
        address _protocolFeeRecipient,
        address _transferManager
    ) ExecutionManager(_owner, _protocolFeeRecipient) {
        transferManager = TransferManager(_transferManager);
    }

    /**
     * @notice This function is internal and used to transfer non-fungible tokens.
     * @param collection Collection address
     * @param collectionType Collection type (e.g. 0 = ERC721, 1 = ERC1155)
     * @param sender Sender address
     * @param recipient Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     */
    function _transferNFT(
        address collection,
        CollectionType collectionType,
        address sender,
        address recipient,
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) internal {
        if (collectionType == CollectionType.ERC721) {
            transferManager.transferItemsERC721(collection, sender, recipient, itemIds, amounts);
        } else if (collectionType == CollectionType.ERC1155) {
            transferManager.transferItemsERC1155(collection, sender, recipient, itemIds, amounts);
        }
    }
}