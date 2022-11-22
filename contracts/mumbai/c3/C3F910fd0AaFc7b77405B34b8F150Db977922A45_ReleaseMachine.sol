// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBall.sol";
import "../../tokens/BALL/IBallStruct.sol";
import "../../tokens/TICKET/ITicket.sol";

import "../../state/Editions/IEditions.sol";

import "../../common/BallContractCallerOwnable/BallContractCallerOwnable.sol";
import "../../common/TicketContractCallerOwnable/TicketContractCallerOwnable.sol";
import "../../common/EditionsContractCallerOwnable/EditionsContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

import "../../oracles/BallBuyOracle/BallBuyOracleCaller.sol";

contract ReleaseMachine is
    BallContractCallerOwnable,
    TicketContractCallerOwnable,
    EditionsContractCallerOwnable,
    BallBuyOracleCaller,
    ChainlinkPriceFeedCallerOwnable
{
    bool public constant IS_RELEASE_MACHINE_CONTRACT = true;

    uint16 public machineServerId;

    bool public isOpen;

    /// @dev - 18 decimals USD amount
    uint256 private _releasePackItemPrice;

    event MachineServerIdUpdated(
        uint16 previousMachineServerId,
        uint16 machineServerId
    );
    event IsOpenUpdated(bool previousIsOpen, bool isOpen);
    event ReleasePackItemPriceUpdated(
        uint256 previousReleasePackItemPrice,
        uint256 releasePackItemPrice
    );
    event ReleasePackItemBought(address indexed buyer, uint256 price);

    constructor(
        uint16 _machineServerId,
        bool _isOpen,
        uint256 _initialReleasePackItemPrice,
        address _ballContractAddress,
        address _ticketContractAddress,
        address _editionsContractAddress,
        address _ballBuyOracleContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress
    )
        BallContractCallerOwnable(_ballContractAddress)
        TicketContractCallerOwnable(_ticketContractAddress)
        EditionsContractCallerOwnable(_editionsContractAddress)
        BallBuyOracleCaller(_ballBuyOracleContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setMachineServerId(_machineServerId);
        setIsOpen(_isOpen);
        setReleasePackItemPrice(_initialReleasePackItemPrice);
    }

    /* Parameters management */
    function setMachineServerId(uint16 _newMachineServerId) public onlyOwner {
        emit MachineServerIdUpdated(machineServerId, _newMachineServerId);
        machineServerId = _newMachineServerId;
    }

    function setIsOpen(bool _newIsOpen) public onlyOwner {
        emit IsOpenUpdated(isOpen, _newIsOpen);
        isOpen = _newIsOpen;
    }

    function setReleasePackItemPrice(uint256 _newPackReleaseItemPrice)
        public
        onlyOwner
    {
        emit ReleasePackItemPriceUpdated(
            _releasePackItemPrice,
            _newPackReleaseItemPrice
        );
        _releasePackItemPrice = _newPackReleaseItemPrice;
    }

    /* Getters */
    function releasePackItemPrice() public view returns (uint256) {
        return (_releasePackItemPrice * 10**18) / _getLatestPrice(18);
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

        editionsContract.increaseCurrentSetIdEditionItemsCount(ballData.setId);

        uint256 ballTokenId = ballContract.mint(
            _to,
            _ballTokenURIPrefix,
            ballData
        );

        return ballTokenId;
    }

    function _buyReleasePack(address _to) private {
        require(isOpen, "MACHINE_IS_NOT_OPEN");

        _callBallBuyOracle(_to, machineServerId, 100, 0, false);
    }

    /* Entry points */
    function buyReleasePack() external payable {
        uint256 price = releasePackItemPrice();

        require(price > 0, "PRICE_IS_ZERO");

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        emit ReleasePackItemBought(_msgSender(), price);

        _buyReleasePack(_msgSender());
    }

    // Oracle callback
    function callback(
        uint256 _requestId,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external override nonReentrant {
        _isGoldBuy; // not used

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
        }

        // Mint Balls
        for (uint256 i = 0; i < _ballsMintData.length; i++) {
            _mintBall(_to, _ballTokenURIPrefix, _ballsMintData[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITicketStruct.sol";

interface ITicket is IERC721 {
    function IS_TICKET_CONTRACT() external pure returns (bool);

    function getTicket(uint256 _tokenId) external view returns (Ticket memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function mint(
        address _to,
        string calldata _tokenURIPrefix,
        Ticket calldata _ticketData
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/BALL/IBall.sol";

contract BallContractCallerOwnable is Ownable {
    IBall public ballContract;

    constructor(address _ballContractAddress) {
        setBallContract(_ballContractAddress);
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/TICKET/ITicket.sol";

contract TicketContractCallerOwnable is Ownable {
    ITicket public ticketContract;

    constructor(address _ticketContractAddress) {
        setTicketContract(_ticketContractAddress);
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../state/Editions/IEditions.sol";

contract EditionsContractCallerOwnable is Ownable {
    IEditions public editionsContract;

    constructor(address _editionsContractAddress) {
        setEditionsContract(_editionsContractAddress);
    }

    function setEditionsContract(address _address) public onlyOwner {
        IEditions candidateContract = IEditions(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_EDITIONS_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_AN_EDITIONS_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        editionsContract = candidateContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkPriceFeedCallerOwnable is Ownable {
    AggregatorV3Interface internal _priceFeed;

    constructor(address _priceFeedAddress) {
        setPriceFeed(_priceFeedAddress);
    }

    function setPriceFeed(address _priceFeedAddress) public onlyOwner {
        _priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function _getLatestPrice(uint8 _decimals) internal view returns (uint256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();

        if (price <= 0) {
            return 0;
        }

        return _scalePrice(uint256(price), _priceFeed.decimals(), _decimals);
    }

    function _scalePrice(
        uint256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) private pure returns (uint256) {
        if (_priceDecimals < _decimals) {
            return _price * (10**(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / (10**(_priceDecimals - _decimals));
        }
        return _price;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";

import "../../tokens/BALL/IBallStruct.sol";

import "./IBallBuyOracle.sol";

abstract contract BallBuyOracleCaller is
    Ownable,
    ReentrancyGuard,
    FundsManagementOwnable
{
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
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) internal nonReentrant returns (uint256) {
        uint256 requestId = ballBuyOracleContract.requestBallBuy(
            _to,
            _machineServerId,
            _amount,
            _ticketTokenId,
            _isGoldBuy
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
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external virtual;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Ticket {
    uint16 serverId;
    address redeemContractAddress;
    uint256 expirationDate; // 0 = never expires
    string name;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/BALL/IBallStruct.sol";

interface IBallBuyOracle {
    function IS_BALL_BUY_ORACLE() external returns (bool);

    function requestBallBuy(
        address _to,
        uint16 _machineServerId,
        uint16 _amount,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external returns (uint256);

    function reportBallBuy(
        uint256 _requestId,
        address _callerAddress,
        address _to,
        string calldata _ballTokenURIPrefix,
        BallMintData[] calldata _ballsMintData,
        uint256 _ticketTokenId,
        bool _isGoldBuy
    ) external;
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