// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/INFTLendingV1.sol";
import "./utils/Transfers.sol";
import "./NFTLendingV1Gov.sol";

/**
 * @title NFTLending implements NFT collateralized lending.
 */
contract NFTLendingV1 is
    INFTLendingV1,
    NFTLendingV1Gov,
    Transfers,
    ReentrancyGuard
{
    /**
     * @notice Initiate a loan with the specified NFT.
     */
    function createLoan(address nftAddress, uint256 nftId)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 loanId)
    {
        require(
            _acceptedNFTs[nftAddress],
            "NFTLendingV1: NFT collection not accepted"
        );
        require(
            nftCollections[nftAddress].enabled,
            "NFTLendingV1: NFT collection not enabled"
        );

        uint256 loanAmount = calcLoanAmount(nftAddress);
        require(loanAmount > 0, "NFTLendingV1: loan amount can not be zero");
        require(
            loanAmount <= lendableFunds,
            "NFTLendingV1: loan amount can not exceed lendable funds"
        );

        loanId = ++numLoans;

        loans[loanId].borrower = msg.sender;
        loans[loanId].loanAmount = loanAmount;
        loans[loanId].interestRate = nftCollections[nftAddress].interestRate;
        loans[loanId].nftValue = nftCollections[nftAddress].value;

        loans[loanId].nftId = nftId;
        loans[loanId].nftAddress = nftAddress;
        loans[loanId].nftType = nftCollections[nftAddress].nftType;

        loans[loanId].startTime = block.timestamp;
        loans[loanId].dueTime = block.timestamp + LOAN_PERIOD;
        loans[loanId].status = Status.CREATED;

        // transfer NFT from borrower to lending contract
        transferNFT(
            msg.sender,
            address(this),
            nftAddress,
            nftId,
            loans[loanId].nftType
        );

        // transfer token from lending contract to borrower
        transferToken(
            address(this),
            payable(msg.sender),
            address(0),
            loanAmount
        );

        accountLoans[msg.sender].push(loanId);
        lendableFunds -= loanAmount;

        // trigger event
        emit LoanCreated(
            msg.sender,
            loanId,
            loanAmount,
            nftAddress,
            nftId,
            loans[loanId].nftType
        );
    }

    /**
     * @notice Repay the given loan.
     */
    function repayLoan(uint256 loanId) external payable {
        require(
            loans[loanId].borrower == msg.sender,
            "NFTLendingV1: sender must be the loan borrower"
        );
        require(
            loans[loanId].status == Status.CREATED,
            "NFTLendingV1: invalid loan status"
        );
        require(
            loans[loanId].dueTime >= block.timestamp,
            "NFTLendingV1: loan is already overdue"
        );

        (, uint256 interest) = calcLoanInterest(loanId);
        require(
            msg.value >= loans[loanId].loanAmount + interest,
            "NFTLendingV1: insufficient repayment amount"
        );

        loans[loanId].status = Status.REPAYED;
        lendableFunds += msg.value;

        // transfer NFT from lending contract to borrower
        transferNFT(
            address(this),
            msg.sender,
            loans[loanId].nftAddress,
            loans[loanId].nftId,
            loans[loanId].nftType
        );

        emit LoanRepayed(msg.sender, loanId, interest);
    }

    /**
     * @notice Liquidate loan when the loan is defaulted
     */
    function liquidateLoan(uint256 loanId, address to) external onlyOwner {
        require(
            loans[loanId].status == Status.CREATED,
            "NFTLendingV1: invalid loan status"
        );
        require(
            block.timestamp > loans[loanId].dueTime,
            "NFTLendingV1: loan is not overdue"
        );

        loans[loanId].status = Status.LIQUIDATED;

        transferNFT(
            address(this),
            to,
            loans[loanId].nftAddress,
            loans[loanId].nftId,
            loans[loanId].nftType
        );

        emit LoanLiquidated(msg.sender, loanId, to);
    }

    /**
     * @notice Retrieve the loan by the given loan id.
     */
    function getLoan(uint256 loanId) external view returns (Loan memory loan) {
        return loans[loanId];
    }

    /**
     * @notice Retrieve the loan list of the given account.
     */
    function getLoans(address account)
        external
        view
        returns (uint256[] memory loanIds)
    {
        return accountLoans[account];
    }

    /**
     * @notice Retrieve the specified NFT collection.
     */
    function getNFTCollection(address nftAddress)
        external
        view
        returns (NFTCollection memory nftCollection)
    {
        return nftCollections[nftAddress];
    }

    /**
     * @notice Check if the given NFT collection is accepted.
     */
    function isNFTAccepted(address nftAddress) external view returns (bool) {
        return _acceptedNFTs[nftAddress];
    }

    /**
     * @notice Retrieve the accepted NFT address list.
     */
    function getAcceptedNFTs() external view returns (address[] memory) {
        return _acceptedNFTSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

/**
 * @title Intended to transfer tokens(native token or ERC20 tokens) or NFTs(ERC721 or ERC1155).
 */
contract Transfers is ERC721Holder, ERC1155Holder {
    /**
     * @notice Transfer native or ERC20 token.
     */
    function transferToken(
        address from,
        address payable to,
        address token,
        uint256 amount
    ) public {
        if (token != address(0)) {
            require(
                IERC20(token).transferFrom(from, to, amount),
                "Transfers: token transfer failed"
            );
        } else {
            require(to.send(amount), "Transfers: native token transfer failed");
        }
    }

    /**
     * @notice Transfer NFT.
     */
    function transferNFT(
        address from,
        address to,
        address nftAddress,
        uint256 nftId,
        uint8 nftType
    ) public {
        if (nftType == 0) {
            IERC721(nftAddress).safeTransferFrom(from, to, nftId);
        } else {
            IERC1155(nftAddress).safeTransferFrom(from, to, nftId, 1, "0x00");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @dev Implementation of the {IERC1155Receiver} interface.
 */
contract ERC1155Holder is ERC165Storage, IERC1155Receiver {
    constructor() {
        _registerInterface(
            IERC1155Receiver.onERC1155Received.selector ^
                IERC1155Receiver.onERC1155BatchReceived.selector
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interfaces for NFT collateralized lending.
 */
interface INFTLendingV1 {
    /**
     * @notice Initiate a loan with the specified NFT.
     * @param nftAddress The NFT address
     * @param nftId The token id of the NFT
     * @return loanId The loan id
     */
    function createLoan(address nftAddress, uint256 nftId)
        external
        returns (uint256 loanId);

    /**
     * @notice Repay the given loan.
     * @param loanId The loan id
     */
    function repayLoan(uint256 loanId) external payable;

    /**
     * @notice Liquidate loan when the loan is defaulted.
     * @param loanId The loan id
     * @param to The NFT recipient address
     */
    function liquidateLoan(uint256 loanId, address to) external;

    /**
     * @notice Retrieve the loan list of the given account.
     * @param account The destination account address
     * @return loanIds The loan id list
     */
    function getLoans(address account)
        external
        view
        returns (uint256[] memory loanIds);

    /**
     * @notice Check if the given NFT collection is accepted.
     * @param nftAddress The destination NFT address
     * @return bool True if the given NFT collection is accepted, false otherwise
     */
    function isNFTAccepted(address nftAddress) external view returns (bool);

    /**
     * @notice Retrieve the accepted NFT address list.
     * @return nftAddresses The accepted NFT address list
     */
    function getAcceptedNFTs()
        external
        view
        returns (address[] memory nftAddresses);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./NFTLendingV1Core.sol";

/**
 * @title NFTLendingGov implements NFT lending management including NFT evaluation,
 * funding, upgrading, etc.
 */
contract NFTLendingV1Gov is Ownable, Pausable, NFTLendingV1Core {
    /**
     * @notice Triggered when funds deposited.
     */
    event FundDeposited(address sender, uint256 amount);

    /**
     * @notice Triggered when funds withdrawn.
     */
    event FundWithdrawn(address sender, uint256 amount, address to);

    /**
     * @notice Triggered when upgraded to the new address.
     */
    event Upgraded(address newAddress);

    /**
     * @notice Add the NFT collection by the NFT address.
     */
    function addNFTCollection(
        address nftAddress,
        uint8 nftType,
        uint256 value,
        uint256 ltv,
        uint256 interestRate
    ) external onlyOwner {
        require(
            nftAddress != address(0),
            "NFTLendingV1Gov: NFT address can not be 0"
        );
        require(
            !_acceptedNFTs[nftAddress],
            "NFTLendingV1Gov: NFT collection already exists"
        );
        require(
            nftType == 0 || nftType == 1,
            "NFTLendingV1Gov: NFT type must be 0 or 1"
        );

        nftCollections[nftAddress] = NFTCollection(
            nftType,
            value,
            ltv,
            interestRate,
            true
        );

        _acceptedNFTSet.push(nftAddress);
        _acceptedNFTs[nftAddress] = true;

        emit NFTCollectionAdded(nftAddress, nftType, value, ltv, interestRate);
    }

    /**
     * @notice Edit the given NFT collection.
     */
    function editNFTCollection(
        address nftAddress,
        uint256 value,
        uint256 ltv,
        uint256 interestRate
    ) external onlyOwner {
        require(
            _acceptedNFTs[nftAddress],
            "NFTLendingV1Gov: NFT address does not exist"
        );

        nftCollections[nftAddress].value = value;
        nftCollections[nftAddress].ltv = ltv;
        nftCollections[nftAddress].interestRate = interestRate;

        emit NFTCollectionEdited(nftAddress, value, ltv, interestRate);
    }

    /**
     * @notice Enable the specified NFT collection for loans.
     */
    function enableNFTCollection(address nftAddress) external onlyOwner {
        require(
            _acceptedNFTs[nftAddress],
            "NFTLendingV1Gov: NFT collection does not exist"
        );
        require(
            !nftCollections[nftAddress].enabled,
            "NFTLendingV1Gov: NFT collection already enabled"
        );

        nftCollections[nftAddress].enabled = true;

        emit NFTCollectionEnabled(nftAddress);
    }

    /**
     * @notice Disable the specified NFT collection for loans.
     */
    function disableNFTCollection(address nftAddress) external onlyOwner {
        require(
            _acceptedNFTs[nftAddress],
            "NFTLendingV1Gov: NFT collection does not exist"
        );
        require(
            nftCollections[nftAddress].enabled,
            "NFTLendingV1Gov: NFT collection already disabled"
        );

        nftCollections[nftAddress].enabled = false;

        emit NFTCollectionDisabled(nftAddress);
    }

    /**
     * @notice Modify the due time of the specified loan.
     ************Only For Testing Purpose***************
     ************Will Be Deleted In Producion***********
     */
    function setLoanDueTimeForTest(uint256 loanId, uint256 dueTime)
        external
        onlyOwner
    {
        loans[loanId].dueTime = dueTime;
    }

    /**
     * @notice Deposit funds for issuing loans.
     */
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "NFTLendingV1Gov: deposit amount can not be 0");

        lendableFunds += msg.value;

        emit FundDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw funds from lending contract.
     */
    function withdrawFunds(uint256 amount, address payable to)
        external
        onlyOwner
    {
        require(
            to != address(0),
            "NFTLendingV1Gov: the recipient address can not be 0"
        );
        require(
            address(this).balance >= amount,
            "NFTLendingV1Gov: insufficient balance"
        );

        lendableFunds -= amount;

        to.transfer(amount);

        emit FundWithdrawn(msg.sender, amount, to);
    }

    /**
     * @notice Pause NFT collateralized lending.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Resume NFT collateralized lending.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Notify of upgrading to the new implementation address.
     */
    function upgrade(address newAddress) external onlyOwner {
        emit Upgraded(newAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title NFTLendingCore defines NFT lending related state variables, types and events.
 */
contract NFTLendingV1Core {
    using Math for uint256;

    uint256 public constant LOAN_PERIOD = 180 * 1 days; // 180 days; loan period

    uint256 public numLoans; // total number of issued loans

    mapping(uint256 => Loan) public loans; // mapping from ids to loans

    mapping(address => uint256[]) public accountLoans; // mapping from accounts to loanIds

    mapping(address => NFTCollection) public nftCollections; // mapping from NFT addresses to NFTCollections

    address[] internal _acceptedNFTSet; // accepted NFT address set

    mapping(address => bool) internal _acceptedNFTs; // accepted NFT address mapping

    uint256 public lendableFunds; // total lendable funds

    // loan status
    enum Status {
        CREATED,
        REPAYED,
        LIQUIDATED
    }

    // loan struct
    struct Loan {
        address borrower; // the loan initiator
        uint256 loanAmount; // the loan amount in native token
        uint256 interestRate; // the loan interest rate
        uint256 nftValue; // the value of the collateralized NFT
        address nftAddress; // the address of the NFT
        uint256 nftId; // the token id of the NFT
        uint8 nftType; // the NFT type; 0 for ERC721, 1 for ERC1155
        uint256 startTime; // loan starting time
        uint256 dueTime; // loan due time
        Status status; // the loan status
    }

    // NFT Collection
    struct NFTCollection {
        uint8 nftType; // NFT type; 0 for ERC721 and 1 for ERC1155
        uint256 value; // NFT value in native token
        uint256 ltv; // loan to value ratio, e.g. 80, which represents 80%
        uint256 interestRate; // annual interest rate, e.g. 500, which represents 5%
        bool enabled; // indicates if the NFT is enabled for collateralized loans
    }

    /**
     * @notice Triggered when the loan is created.
     */
    event LoanCreated(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 loanAmount,
        address nftAddress,
        uint256 nftId,
        uint8 nftType
    );

    /**
     * @notice Triggered when the loan is repayed.
     */
    event LoanRepayed(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 interest
    );

    /**
     * @notice Triggered when the loan is liquidated.
     */
    event LoanLiquidated(address sender, uint256 indexed loanId, address to);

    /**
     * @notice Triggered when the NFT collection is added.
     */
    event NFTCollectionAdded(
        address nftAddress,
        uint8 nftType,
        uint256 value,
        uint256 ltv,
        uint256 intererstRate
    );

    /**
     * @notice Triggered when the NFT collection is edited.
     */
    event NFTCollectionEdited(
        address nftAddress,
        uint256 value,
        uint256 ltv,
        uint256 intererstRate
    );

    /**
     * @notice Triggered when the specified NFT collection is enabled for loans.
     */
    event NFTCollectionEnabled(address nftAddress);

    /**
     * @notice Triggered when the specified NFT collection is disabled for loans.
     */
    event NFTCollectionDisabled(address nftAddress);

    /**
     * @notice Calculate the loan amount by the given NFT address.
     */
    function calcLoanAmount(address nftAddress) public view returns (uint256) {
        return
            (nftCollections[nftAddress].value *
                nftCollections[nftAddress].ltv) / 100;
    }

    /**
     * @notice Calculate the loan interest by the given loan id.
     * Less than one day is counted as one day.
     */
    function calcLoanInterest(uint256 loanId)
        public
        view
        returns (uint256 timestamp, uint256 interest)
    {
        timestamp = block.timestamp;

        uint256 dailyInterest = (loans[loanId].loanAmount *
            loans[loanId].interestRate).ceilDiv(10000 * 365);

        uint256 loanTime = timestamp - loans[loanId].startTime;
        uint256 loanDays = loanTime > 0 ? loanTime.ceilDiv(1 days) : 1;

        interest = dailyInterest * loanDays;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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