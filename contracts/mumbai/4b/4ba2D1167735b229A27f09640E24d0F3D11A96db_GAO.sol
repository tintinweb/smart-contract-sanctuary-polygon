// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IBall.sol";
import "../interfaces/IBallStruct.sol";
import "../interfaces/IEditions.sol";
import "../interfaces/ITicket.sol";

import "../common/FundsManagementOwnable.sol";

import "../oracles/BallBuyOracleCaller.sol";

contract GAO is FundsManagementOwnable, BallBuyOracleCaller {
    bool public constant IS_GAO_CONTRACT = true;

    uint16 machineServerId;

    bool public isOpen;

    IEditions public editionsContract;
    IBall public ballContract;
    ITicket public ticketContract;

    uint256 public singleItemPrice;
    uint256 public packItemPrice;

    event SingleItemBought(address indexed buyer, uint256 price);
    event PackItemBought(address indexed buyer, uint256 price);
    event TicketRedeemed(uint256 indexed ticketTokenId);

    constructor(
        uint16 _machineServerId,
        bool _isOpen,
        address _editionsContractAddress,
        address _ballContractAddress,
        address _ticketContractAddress,
        uint256 _singleItemPrice,
        uint256 _packItemPrice,
        address _ballBuyOracleContractAddress
    ) BallBuyOracleCaller(_ballBuyOracleContractAddress) {
        setMachineServerId(_machineServerId);
        setIsOpen(_isOpen);
        setEditionsContractAddress(_editionsContractAddress);
        setBallContract(_ballContractAddress);
        setTicketContract(_ticketContractAddress);
        setSingleItemPrice(_singleItemPrice);
        setPackItemPrice(_packItemPrice);
    }

    /* Parameters management */
    function setMachineServerId(uint16 _machineServerId) public onlyOwner {
        machineServerId = _machineServerId;
    }

    function setIsOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function setEditionsContractAddress(address _address) public onlyOwner {
        IEditions candidateContract = IEditions(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_EDITIONS_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_AN_EDITIONS_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        editionsContract = candidateContract;
    }

    function setBallContract(address _address) public onlyOwner {
        IBall candidateContract = IBall(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_BALL_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_BALL_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ballContract = candidateContract;
    }

    function setTicketContract(address _address) public onlyOwner {
        ITicket candidateContract = ITicket(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_TICKET_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_TICKET_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        ticketContract = candidateContract;
    }

    function setSingleItemPrice(uint256 _singleItemPrice) public onlyOwner {
        singleItemPrice = _singleItemPrice;
    }

    function setPackItemPrice(uint256 _packItemPrice) public onlyOwner {
        packItemPrice = _packItemPrice;
    }

    /* Helpers */
    function _mintBall(
        address _to,
        string memory _ballTokenURIPrefix,
        BallMintData memory _ballMintData
    ) private returns (uint256) {
        Ball memory ballData = Ball(
            _ballMintData.serverId,
            _ballMintData.setId,
            editionsContract.getCurrentSetIdEdition(_ballMintData.setId),
            _ballMintData.minRunes,
            _ballMintData.maxRunes,
            _ballMintData.isShiny,
            _ballMintData.name
        );

        uint256 ballTokenId = ballContract.mint(
            _to,
            _ballTokenURIPrefix,
            ballData
        );

        editionsContract.increaseCurrentSetIdEditionItemsCount(ballData.setId);

        return ballTokenId;
    }

    function _buySingle(address _to) private {
        require(isOpen, "SALE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 1, 0);

        emit SingleItemBought(_to, singleItemPrice);
    }

    function _buyPack(address _to) private {
        require(isOpen, "SALE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 5, 0);

        emit PackItemBought(_to, packItemPrice);
    }

    /* Entry points */
    function buySingle() external payable {
        require(msg.value == singleItemPrice, "VALUE_INCORRECT");

        _buySingle(_msgSender());
    }

    function buyPack() external payable {
        require(msg.value == packItemPrice, "VALUE_INCORRECT");

        _buyPack(_msgSender());
    }

    function redeemTicket(uint256 _ticketTokenId) external {
        Ticket memory ticket = ticketContract.getTicket(_ticketTokenId);

        require(
            ticket.redeemContractAddress == address(this),
            "TICKET_IS_NOT_FOR_THIS_CONTRACT"
        );

        require(ticket.expirationDate <= block.timestamp, "TICKET_IS_EXPIRED");

        require(
            ticketContract.ownerOf(_ticketTokenId) == _msgSender(),
            "ONLY_TICKET_OWNER_ALLOWED"
        );

        require(
            ticketContract.getApproved(_ticketTokenId) == address(this),
            "TICKET_NOT_APPROVED"
        );

        _callBallBuyOracle(_msgSender(), machineServerId, 1, _ticketTokenId);
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId
    ) external override {
        // Only oracle should be able to call
        require(
            _msgSender() == address(ballBuyOracleContract),
            "NOT_AUTHORIZED"
        );

        // Ensure this is a legitimate callback request
        require(
            _pendingBallBuyRequests[_requestId],
            "REQUEST_ID_IS_NOT_PENDING"
        );

        // Remove the request from pending requests
        delete _pendingBallBuyRequests[_requestId];

        // Burn ticket if any
        if (_ticketTokenId > 0) {
            ticketContract.burn(_ticketTokenId);
            emit TicketRedeemed(_ticketTokenId);
        }

        // Mint Balls
        for (uint256 i = 0; i < _ballsMintData.length; i++) {
            _mintBall(_to, _ballTokenURIPrefix, _ballsMintData[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IBallStruct.sol";

interface IBall is IERC721 {
    function IS_BALL_CONTRACT() external pure returns (bool);

    function getBall(uint256 _tokenId) external view returns (Ball memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ball calldata _ballData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Ball {
    uint16 serverId;
    uint16 setId;
    uint8 edition;
    uint16 minRunes;
    uint16 maxRunes;
    bool isShiny;
    string name;
}

struct BallMintData {
    uint16 serverId;
    uint16 setId;
    // no edition
    uint16 minRunes;
    uint16 maxRunes;
    bool isShiny;
    string name;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEditions {
    function IS_EDITIONS_CONTRACT() external pure returns (bool);

    function getCurrentSetIdEdition(uint16 _setId)
        external
        view
        returns (uint8 _currentSetIdEdition);

    function getCurrentSetIdEditionItemsCount(uint16 _setId)
        external
        view
        returns (uint256 _currentSetIdItemsCount);

    function increaseCurrentSetIdEditionItemsCount(uint16 _setId)
        external
        returns (uint8 _currentSetIdEdition);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITicketStruct.sol";

interface ITicket is IERC721 {
    function IS_TICKET_CONTRACT() external pure returns (bool);

    function getTicket(uint256 _tokenId) external view returns (Ticket memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ticket calldata _ticketData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundsManagementOwnable is Ownable {
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function withdraw(address _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "WITHDRAW_FAILED");
    }

    function recoverERC20(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            IERC20(_tokenAddress).transfer(_to, _tokenAmount),
            "RECOVERY_FAILED"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../common/FundsManagementOwnable.sol";

import "../interfaces/IBallStruct.sol";
import "../interfaces/IBallBuyOracle.sol";

abstract contract BallBuyOracleCaller is Ownable, FundsManagementOwnable {
    bool public constant IS_BALL_BUY_ORACLE_CALLER = true;

    IBallBuyOracle public ballBuyOracleContract;

    mapping(uint256 => bool) internal _pendingBallBuyRequests;

    constructor(address _initialBallBuyOracleContractAddress) {
        setBallBuyOracleContractAddress(_initialBallBuyOracleContractAddress);
    }

    /* External contracts management */
    function setBallBuyOracleContractAddress(address _address)
        public
        onlyOwner
    {
        IBallBuyOracle candidateContract = IBallBuyOracle(_address);

        // Verify the contract is the one we expect
        require(candidateContract.IS_BALL_BUY_ORACLE());

        // Set the new contract address
        ballBuyOracleContract = candidateContract;
    }

    // Entry point
    function _callBallBuyOracle(
        address _to,
        uint16 _machineServerId,
        uint16 _amount,
        uint256 _ticketTokenId
    ) internal returns (uint256) {
        uint256 requestId = ballBuyOracleContract.requestBallBuy(
            _to,
            _machineServerId,
            _amount,
            _ticketTokenId
        );
        _pendingBallBuyRequests[requestId] = true;
        return requestId;
    }

    // Exit point, to be implemented by the use case contract
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId
    ) external virtual;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Ticket {
    uint16 serverId;
    address redeemContractAddress;
    uint256 expirationDate; // 0 = never expires
    string name;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IBallStruct.sol";

interface IBallBuyOracle {
    function IS_BALL_BUY_ORACLE() external returns (bool);

    function requestBallBuy(
        address _to,
        uint16 _machineServerId,
        uint16 _amount,
        uint256 _ticketTokenId
    ) external returns (uint256);

    function reportBallBuy(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId
    ) external;
}