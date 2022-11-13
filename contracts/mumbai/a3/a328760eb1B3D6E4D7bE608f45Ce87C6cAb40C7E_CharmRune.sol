// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "../../tokens/RUNE/IRune.sol";
import "../../tokens/RUNE/IRuneStruct.sol";

import "../../common/FundsManagementOwnable/FundsManagementOwnable.sol";
import "../../common/RuneContractCallerOwnable/RuneContractCallerOwnable.sol";
import "../../common/ChainlinkPriceFeedCallerOwnable/ChainlinkPriceFeedCallerOwnable.sol";

contract CharmRune is
    FundsManagementOwnable,
    RuneContractCallerOwnable,
    ChainlinkPriceFeedCallerOwnable
{
    /// @dev - 18 decimals USD amount
    uint256 private _batchedCharmPrice;
    uint256 private _batchedSuperCharmPrice;

    event BatchedCharmPriceUpdate(
        uint256 previousBatchedCharmPrice,
        uint256 batchedCharmPrice
    );
    event BatchedSuperCharmPriceUpdated(
        uint256 previousBatchedSuperCharmPrice,
        uint256 batchedSuperCharmPrice
    );

    event CharmedTwice(
        address indexed buyer,
        uint256 indexed runeServerId,
        uint256 price
    );
    event CharmedThreeTimes(
        address indexed buyer,
        uint256 indexed runeServerId,
        uint256 price
    );

    constructor(
        address _runeContractAddress,
        address _chainlinkMaticUsdPriceFeedAddress,
        uint256 _initialBatchedCharmPrice,
        uint256 _initialBatchedSuperCharmPrice
    )
        RuneContractCallerOwnable(_runeContractAddress)
        ChainlinkPriceFeedCallerOwnable(_chainlinkMaticUsdPriceFeedAddress)
    {
        setBatchedCharmPrice(_initialBatchedCharmPrice);
        setBatchedSuperCharmPrice(_initialBatchedSuperCharmPrice);
    }

    function setBatchedCharmPrice(uint256 _newBatchedCharmPrice)
        public
        onlyOwner
    {
        emit BatchedCharmPriceUpdate(_batchedCharmPrice, _newBatchedCharmPrice);
        _batchedCharmPrice = _newBatchedCharmPrice;
    }

    function setBatchedSuperCharmPrice(uint256 _newBatchedSuperCharmPrice)
        public
        onlyOwner
    {
        emit BatchedSuperCharmPriceUpdated(
            _batchedSuperCharmPrice,
            _newBatchedSuperCharmPrice
        );
        _batchedSuperCharmPrice = _newBatchedSuperCharmPrice;
    }

    function batchedCharmPrice() public view returns (uint256) {
        return (_batchedCharmPrice * 10**18) / _getLatestPrice(18);
    }

    function batchedSuperCharmPrice() public view returns (uint256) {
        return (_batchedSuperCharmPrice * 10**18) / _getLatestPrice(18);
    }

    function charm(uint256 _runeServerId) external {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                rune.runesCountToCharm,
            "NOT_ENOUGH_RUNES"
        );

        runeContract.burn(_msgSender(), _runeServerId, rune.runesCountToCharm);

        runeContract.mint(_msgSender(), rune.charmedRuneServerId, 1, "");
    }

    function charmTwice(uint256 _runeServerId) external payable {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        Rune memory charmedRune = runeContract.getRune(
            rune.charmedRuneServerId
        );

        require(
            charmedRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_TWICE"
        );

        Rune memory charmedTwiceRune = runeContract.getRune(
            charmedRune.charmedRuneServerId
        );

        uint256 price = charmedTwiceRune.charmedRuneServerId > 0
            ? batchedCharmPrice()
            : batchedSuperCharmPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        uint256 requiredRunes = charmedRune.runesCountToCharm *
            rune.runesCountToCharm;

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                requiredRunes,
            "NOT_ENOUGH_RUNES"
        );

        emit CharmedTwice(_msgSender(), _runeServerId, price);

        runeContract.burn(_msgSender(), _runeServerId, requiredRunes);

        runeContract.mint(_msgSender(), charmedRune.charmedRuneServerId, 1, "");
    }

    function charmThreeTimes(uint256 _runeServerId) external payable {
        Rune memory rune = runeContract.getRune(_runeServerId);

        require(rune.charmedRuneServerId > 0, "RUNE_CANNOT_BE_CHARMED");

        Rune memory charmedRune = runeContract.getRune(
            rune.charmedRuneServerId
        );

        require(
            charmedRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_TWICE"
        );

        Rune memory charmedTwiceRune = runeContract.getRune(
            charmedRune.charmedRuneServerId
        );

        require(
            charmedTwiceRune.charmedRuneServerId > 0,
            "RUNE_CANNOT_BE_CHARMED_THREE_TIMES"
        );

        uint256 price = batchedSuperCharmPrice();

        require(msg.value >= price, "VALUE_TOO_LOW");

        uint256 leftovers = msg.value - price;

        if (leftovers > 0) {
            (bool success, ) = _msgSender().call{value: leftovers}("");
            require(success, "LEFTOVERS_REFUND_FAILED");
        }

        uint256 requiredRunes = charmedTwiceRune.runesCountToCharm *
            charmedRune.runesCountToCharm *
            rune.runesCountToCharm;

        require(
            runeContract.balanceOf(_msgSender(), _runeServerId) >=
                requiredRunes,
            "NOT_ENOUGH_RUNES"
        );

        emit CharmedThreeTimes(_msgSender(), _runeServerId, price);

        runeContract.burn(_msgSender(), _runeServerId, requiredRunes);

        runeContract.mint(
            _msgSender(),
            charmedTwiceRune.charmedRuneServerId,
            1,
            ""
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IRuneStruct.sol";

interface IRune is IERC1155 {
    function IS_RUNE_CONTRACT() external pure returns (bool);

    function getRune(uint256 _serverId) external view returns (Rune memory);

    function mint(
        address to,
        uint256 serverId,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata serverIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 serverId,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

struct Rune {
    uint16 serverId;
    uint16 setId;
    uint8 typeId;
    uint16 charmedRuneServerId;
    uint8 runesCountToCharm;
    string name;
}

struct RunesMint {
    uint256[] ids;
    uint256[] amounts;
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../tokens/RUNE/IRune.sol";

contract RuneContractCallerOwnable is Ownable {
    IRune public runeContract;

    constructor(address _runeContractAddress) {
        setRuneContract(_runeContractAddress);
    }

    function setRuneContract(address _address) public onlyOwner {
        IRune candidateContract = IRune(_address);

        // Verify the contract is the one we expect
        require(
            candidateContract.IS_RUNE_CONTRACT(),
            "CONTRACT_ADDRES_IS_NOT_A_RUNE_CONTRACT_INSTANCE"
        );

        // Set the new contract address
        runeContract = candidateContract;
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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