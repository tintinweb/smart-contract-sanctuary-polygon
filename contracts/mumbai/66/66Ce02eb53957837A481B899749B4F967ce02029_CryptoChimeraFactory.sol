// SPDX-License-Identifier: MIT
// contracts/CryptoChimeraFactory.sol
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CryptoChimeraInterface.sol";
import "./CryptoChimeraFactoryInterface.sol";

contract CryptoChimeraFactory is CryptoChimeraFactoryInterface, Pausable, Ownable {
    /*
     * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
     * now has built in overflow checking.
     */

    address private _cryptoChimeraContractAddress;
    CryptoChimeraInterface private _cryptoChimeraContract;
    event CryptoChimeraAddressChanged(address oldAddress, address newAddress);

    uint8 public maxMissedTasks = 3;
    uint256 public priceUnblockMaxMissedTasks = 200 gwei;

    struct CurrencyCoinType {
        uint8 currencyType;
        /*
         * Supported types:
         * 0 - price in the native currency (taskTypes[].nativeCrPrice).
         * 1 - default ERC20. Supported coins (as example):
         *  https://etherscan.io/address/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 - USD Coin (USDC)
         *  https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f - Dai Stablecoin (DAI)
         *  and others
         *
         * TODO: Add the EIP-1363 type for supporting calls 'addTask()' without calling contractERC20.approve() before.
         *  - https://eips.ethereum.org/EIPS/eip-1363 - EIP-1363: Payable Token.
         *    transferAndCall and transferFromAndCall will call an onTransferReceived on a ERC1363Receiver contract.
         *    approveAndCall will call an onApprovalReceived on a ERC1363Spender contract.
         *  - https://forum.openzeppelin.com/t/erc1363-payable-token/956 - Example ERC1363 Implementation and "payable"
         *    contract implementation.
         * TODO: Add the ERC677 type ...:
         *    Call the 'transferAndCall()', that call to the 'ERC677Receiver(receiver).onTokenTransfer()'. Example:
         *    https://github.com/ethereum/EIPs/issues/677 - ERC-677 - 'transferAndCall()' Token Standard for
         *      calling the 'onTokenTransfer(address,uint256,bytes)' after coins transfered.
         *    https://etherscan.io/address/0x514910771af9ca656af840dff83e8264ecf986ca - ChainLink Token (LINK) (supports ERC677)
         *  Articles:
         *  - https://medium.com/immunefi/how-erc-standards-work-part-1-c9795803f459 - explain ERC-20, ERC-677, ERC-1363
         *  - https://ethereum.org/ru/developers/tutorials/transfers-and-approval-of-erc-20-tokens-from-a-solidity-smart-contract/
         *    Example using ERC-20.
         *  Other old solutions:
         *  - https://github.com/ethereum/EIPs/issues/223 - ERC-223 transfer() call the callback 'tokenReceived()' function
         *    on the receiver contract (old 'tokenFallback()')
         *  - https://medium.com/@jgm.orinoco/ethereum-smart-service-payment-with-tokens-60894a79f75c - very old article
         *    with approveAndCall() -> receiveApproval(), and transferAndCall() -> tokenFallback() (old ERC-677)
         */
        mapping(uint8 => uint256) taskPrices;  // taskType => price
    }
    mapping(address => CurrencyCoinType) public taskPricesForCurrencies;

    struct TaskType {
        uint8 numberArguments;
        uint256 nativeCrPrice;  // Price from the 'msg.value'. Not supported in the zkSync2.
    }
    mapping(uint8 => TaskType) public taskTypes;

    // Emits event instead of using blockchain storage for reduce your smart contract gas fees
    //    https://cryptomarketpool.com/gas-in-solidity-smart-contracts/
    //    https://ethereum.stackexchange.com/questions/28813/how-to-write-an-optimized-gas-cost-smart-contract
    /*
    struct TaskInQueue {
        uint8 taskTypeId;
        uint8 addedTasksBefore;
        //uint256 nativeCrPrice;
        uint256[] arguments;
    }
    mapping(address => TaskInQueue) private _taskQueueForAddress;
    */
    mapping(address => uint8) private _addedTasksBefore;

    constructor() Ownable() {
    }

    function setCryptoChimeraContract(address cryptoChimeraContractAddress) external onlyOwner {
        require(cryptoChimeraContractAddress != address(0), "setCryptoChimeraContract: new factory is the zero address");
        address oldAddress = _cryptoChimeraContractAddress;
        _cryptoChimeraContractAddress = cryptoChimeraContractAddress;
        _cryptoChimeraContract = CryptoChimeraInterface(cryptoChimeraContractAddress);
        emit CryptoChimeraAddressChanged(oldAddress, cryptoChimeraContractAddress);
    }

    function getCryptoChimeraAddress() external view onlyOwner returns (address) {
        return _cryptoChimeraContractAddress;
    }

    function setTaskType(uint8 taskTypeId, uint8 numberArguments, uint256 nativeCrPrice) external onlyOwner {
        TaskType storage taskType = taskTypes[taskTypeId];
        taskType.numberArguments = numberArguments;
        taskType.nativeCrPrice = nativeCrPrice;
    }

    function setCurrencyCoinType(address currencyAddress, uint8 currencyType) external onlyOwner {
        require(currencyAddress != address(0), "CryptoChimeraFactory: zero currencyAddress");
        CurrencyCoinType storage choosedCurrency = taskPricesForCurrencies[currencyAddress];
        choosedCurrency.currencyType = currencyType;
    }

    function deleteCurrencyCoinType(address currencyAddress) external onlyOwner {
        delete(taskPricesForCurrencies[currencyAddress]);
    }

    function setPriceForTaskType(uint8 taskTypeId, address currencyAddress, uint256 currencyTokensPrice) external onlyOwner {
        require(taskTypes[taskTypeId].numberArguments != 0, "CryptoChimeraFactory: unknown taskTypeId");
        CurrencyCoinType storage choosedCurrency = taskPricesForCurrencies[currencyAddress];
        require(choosedCurrency.currencyType != 0, "CryptoChimeraFactory: unknown currency");
        choosedCurrency.taskPrices[taskTypeId] = currencyTokensPrice;
    }

    function getTaskPricesForCurrencyCoin(address currencyAddress, uint8 taskId) external view returns (uint256) {
        return taskPricesForCurrencies[currencyAddress].taskPrices[taskId];
    }

    // The msg.value does not work in the zkSync2: https://v2-docs.zksync.io/dev/zksync-v2/temp-limits.html
    // Can be paying with ERC20 tokens.
    function addTask(uint8 taskTypeId, address currencyAddress, uint256 arg2, uint256 arg3) external whenNotPaused payable {
        TaskType storage taskType = taskTypes[taskTypeId];
        require(taskType.numberArguments != 0, "CryptoChimeraFactory: unknown taskTypeId");
        require(taskType.numberArguments == 1 || arg2 != 0, "CryptoChimeraFactory: error - the zero arg2");
        require(taskType.numberArguments < 3 || arg3 != 0, "CryptoChimeraFactory: error - the zero arg3");

        uint8 addedTasksBefore = _addedTasksBefore[_msgSender()];
        require(addedTasksBefore <= maxMissedTasks, "CryptoChimeraFactory addTask: the maximum number of tasks has been reached");

        uint8 currencyTypePayed;
        if (currencyAddress == address(0)) {
            currencyTypePayed = 0;
            require(taskType.nativeCrPrice == 0 || taskType.nativeCrPrice == msg.value,
                "CryptoChimeraFactory: you need to pay the correct price for adding selected task");
        } else {
            CurrencyCoinType storage choosedCurrency = taskPricesForCurrencies[currencyAddress];
            currencyTypePayed = choosedCurrency.currencyType;
            require(currencyTypePayed != 0, "CryptoChimeraFactory: unknown choosed currency");
            if (currencyTypePayed == 1) {
                // Needs to call the 'contractERC20.approve(THIS_FACTORY_CONTRACT_ADDR, amount)' by user before call the 'addTask()'.
                //IERC20 contractERC20 = IERC20(currencyAddress);
                IERC20(currencyAddress).transferFrom(_msgSender(), address(this), choosedCurrency.taskPrices[taskTypeId]);
            } else {
                revert("CryptoChimeraFactory: unsupported currencyType");
            }
        }

        _addedTasksBefore[_msgSender()] += 1;

        emit TaskInQueueAdded(taskTypeId, addedTasksBefore, currencyTypePayed, _msgSender(), arg2, arg3);
    }

    function unblockMissedTasks() external payable {
        // TODO: not workes in zkSync2, need repair (do pay in the other currency)
        require(msg.value == priceUnblockMaxMissedTasks, "CryptoChimeraFactory unblockMissedTasks: you need to pay the correct price");
        _addedTasksBefore[_msgSender()] = 0;
    }

    function resetMissedTasks(address recipient) external {
        require(
            _msgSender() == _cryptoChimeraContractAddress || _msgSender() == owner(),
            "resetMissedTasks: caller is not the cryptoChimeraContractAddress"
        );
        delete _addedTasksBefore[recipient];
    }

    function getMissedTasks() external view returns (uint8) {
        return _addedTasksBefore[_msgSender()];
    }

    function setPriceUnblockMaxMissedTasks(uint256 price) external onlyOwner {
        priceUnblockMaxMissedTasks = price;
    }

    function setMaxMissedTasks(uint8 maxTasks) external onlyOwner {
        maxMissedTasks = maxTasks;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawBalanceWeis(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Cannot withdraw more than current balance");
        payable(_msgSender()).transfer(amount);
    }

    function withdrawAllBalanceWeis() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "contract has no balance");
        payable(_msgSender()).transfer(balance);
    }

    function withdrawBalanceCurrencyCoin(address currencyAddress, uint256 amount) external onlyOwner {
        //IERC20 contractERC20 = IERC20(currencyAddress);
        IERC20(currencyAddress).transfer(owner(), amount);  // owner() == _msgSender()
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
// contracts/CryptoChimeraInterface.sol
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface CryptoChimeraInterface is IERC721 {
    // TODO: adds descriptions ?

    event TokenIsWaitingAtFactoryDelivery(address indexed recipient, uint256 indexed tokenId, uint256 nativeCrPrice, uint256 oldTokenId);
    event TokenWasDeliveredFromFactory(address indexed recipient, uint256 indexed tokenId, uint256 nativeCrPrice);
    event PermanentURI(string _value, uint256 indexed _id);

    function viewTokenAtFactoryDelivery() external view returns (uint256 tokenId, uint256 nativeCrPrice);
    function receiveFromCCHFactory() external payable;

    /*
     * Functions for Factory backend or for Owner only (onlyOwnerOrFactory):
     */
    function mintNFT(address recipient, uint256 newItemId) external;
    function burnForFactory(uint256 tokenId) external;
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;
    function resetTokenRoyalty(uint256 tokenId) external;
    function addTokenToFactoryDelivery(address recipient, uint256 tokenId, uint256 nativeCrPrice) external;
    function viewTokenAtFactoryDelivery(address recipient) external view returns (uint256 tokenId, uint256 nativeCrPrice);
    function receiveFromCCHFactory(address recipient) external;
    function emitTokenWasDeliveredFromFactory(address recipient, uint256 tokenId, uint256 nativeCrPrice) external;
    function freezeTokenForever(uint256 tokenId, string memory _value) external;
}

// SPDX-License-Identifier: MIT
// contracts/CryptoChimeraInterface.sol
pragma solidity ^0.8.9;

interface CryptoChimeraFactoryInterface {
    event TaskInQueueAdded(uint8 taskTypeId, uint8 missedTasksBefore, uint8 currencyTypePayed, address indexed recipient, uint256 arg2, uint256 arg3);

    function addTask(uint8 taskTypeId, address currencyAddress, uint256 arg2, uint256 arg3) external payable;
    function unblockMissedTasks() external payable;
    function getMissedTasks() external view returns (uint8 addedTasksBefore);

    /*
     * Functions for CryptoChimera contracts called only (or owner).
     */
    function resetMissedTasks(address recipient) external;
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