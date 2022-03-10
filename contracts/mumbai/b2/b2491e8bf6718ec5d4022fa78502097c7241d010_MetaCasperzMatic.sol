/**
 *Submitted for verification at polygonscan.com on 2022-03-09
*/

// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzVault.sol


// MetaCasperzVault.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;
contract MetaCasperzVault {
    uint256 internal VAULT_balance_major;
    uint256 internal VAULT_balance_minor;
    address internal VAULT_keeper_major;
    address internal VAULT_keeper_minor;
    uint256 internal VAULT_share_percentage;
    uint256 internal NFT_PriceSpinner;
    uint256 internal NFT_CurrentPrice;
    event EventVaultWithdrawal (address indexed reciever, uint256 amount);
    event EventVaultDeposit (address indexed sender, uint256 amount);
    event EventVaultKeeperTransfer (address from, address to);
    constructor() {
        NFT_PriceSpinner = 2;
        VAULT_share_percentage = 5;
        VAULT_keeper_major = payable(msg.sender);
        VAULT_keeper_minor = payable(msg.sender);
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_major);
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_minor);
    }
    modifier onlymajorVaultKeeper() {require(msg.sender == VAULT_keeper_major, "Caller is not VAULT_keeper_major");_;}
    modifier onlyminorVaultKeeper() {require(msg.sender == VAULT_keeper_minor, "Caller is not VAULT_keeper_minor");_;}
    function vault_balance_minor() external view returns (uint256) {return VAULT_balance_minor;}
    function vault_balance_major() external view returns (uint256) {return VAULT_balance_major;}
    function vault_show_Keeper_major() external view returns (address) {return VAULT_keeper_major;}
    function vault_show_Keeper_minor() external view returns (address) {return VAULT_keeper_minor;} 
    receive() external payable { emit EventVaultDeposit(msg.sender, msg.value); }
    function vault_deposit () external payable { // DONATE TO CASPERZ BUTTON
        require(msg.value > 0);
        vault_share (msg.value);
        emit EventVaultDeposit(msg.sender, msg.value);
    }
    function vault_share (uint256 _value) internal { // Percentage splitter
        require(_value +  VAULT_balance_major + VAULT_balance_minor < (2 ** 256) -1, "The Vault is full Thankyou");
        uint256 minimumValue = 100 / VAULT_share_percentage; 
        if (_value > minimumValue ){ VAULT_balance_minor += (_value * VAULT_share_percentage) / 100; }
        VAULT_balance_major += address(this).balance - VAULT_balance_minor;
    }
    function vault_check_sum () internal view returns (bool){
        uint256 userBalancesSummed = VAULT_balance_major + VAULT_balance_minor;
        if (address(this).balance == userBalancesSummed){return true;
        }else{return false;}  
    }
}


// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzTracker.sol


// MetaCasperzTracker.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;
contract MetaCasperzTracker {
    uint256 internal constant NFT_MaxIndex = 3333;
    uint256 internal constant NFT_MaxAmount = 1;
    uint256 internal NFT_IndexedTotal;
    uint256 internal NFT_IndexCounter;
    uint256 internal NFT_CollectorCount;

    mapping(uint256 => uint256) internal NFT_TotalByIndex;
    mapping(address => mapping(uint256 => uint256)) internal NFT_Collector;
    event EventNFTJustMinted (address indexed mintedBy, uint256 mintedID, uint256 mintedAmount, uint256 totalPrice);

    function NFT_absoluteTotal() internal view returns (uint256) {return NFT_IndexedTotal;}
    function NFT_maximumTotal() internal pure returns (uint256) {return NFT_MaxIndex * NFT_MaxAmount;}
    function NFT_currentIndex() internal view returns (uint256) {return NFT_IndexCounter;}
    function NFT_getAvailableSupply() internal view returns (uint256) {return NFT_maximumTotal() - NFT_IndexedTotal;}
    function NFT_getNextIndexReady() internal returns (uint256){ NFT_IndexCounter ++; return NFT_IndexCounter;}

    function NFT_justMinted(address _mintedBy, uint256 _mintedID, uint256 _mintedAmount, uint256 _totalPrice ) internal {
        NFT_Collector[_mintedBy][NFT_IndexCounter] = NFT_IndexCounter;
        NFT_CollectorCount ++;
        NFT_IndexedTotal ++;
        NFT_TotalByIndex[NFT_IndexCounter] = _mintedAmount;
        emit EventNFTJustMinted(_mintedBy,_mintedID,_mintedAmount,_totalPrice);
    }
}
// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzWhitelist.sol


// MetaCasperzWhitelist.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;
contract MetaCasperzWhitelist {
    uint256 WhiteListIndex;
    mapping(uint256 => uint256) internal WhiteListIdCapacity;
    mapping(address => mapping(uint256 => uint)) internal WhiteListedStatus;
    function whitelist_id() external view returns (uint256) {return WhiteListIndex;}
    function whitelist_capacity() external view returns (uint256) {return WhiteListIdCapacity[WhiteListIndex];}
    function whitelist_statusCheck(address _address) internal view returns (uint) {
        return WhiteListedStatus[_address][WhiteListIndex];
    }
    function whitelist_lookup_status(address _address, uint256 _whiteListIndex) external view returns (uint) {
        return WhiteListedStatus[_address][_whiteListIndex];
    }
    modifier onlyWhitelisted() {
        require(WhiteListIndex > 0, "No Whitelisting events have been started" );
        require(whitelist_statusCheck(msg.sender) != 0, "You are not whitelisted");
        require(whitelist_statusCheck(msg.sender) == 1, "You have already collected your NFT");
        _;
    }
    modifier alreadyWhitelisted() {
        require(WhiteListIndex > 0, "No Whitelisting events have been started" );
        require(WhiteListIdCapacity[WhiteListIndex] > 0, "This whitelisting event has reached capacity");
        require(whitelist_statusCheck(msg.sender) == 0, "You cannot sign up to the same whitelist twice");
        _;
    }
}
// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzWinners.sol


// MetaCasperzWinners.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]   
pragma solidity 0.8.12;
contract MetaCasperzWinners {   
    uint256 internal constant NFT_Winner_Max = 50;
    mapping(address => uint256) internal NFT_Winner;
    uint256 internal NFT_WinnerCount;
    function winner_statusCheck (address _winnersAddress) internal view returns (uint256){
        return NFT_Winner[_winnersAddress];
    }
    modifier onlyTheWinners() {
        require( winner_statusCheck (msg.sender) != 0, "You are not a raffle winner");
        require( winner_statusCheck (msg.sender) == 1, "You have already collected your prize");
        _;
    }
}
// File: blackboxmint/metaCasperz/production/v1.0/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
     modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function admin_renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function admin_transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzAdmin.sol


// MetaCasperzAdmin.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;


contract MetaCasperzAdmin is Ownable {
    address internal superadministrator;
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;
    event EventSuperAdminTransfer (address indexed oldAddress, address indexed newAddress);
    constructor() {
        superadministrator = payable(msg.sender);
        _status = _NOT_ENTERED;
        emit EventSuperAdminTransfer(address(0), superadministrator);
    }
    function admin_destroyContract () external payable onlyDualAdminFunction isLivingSoul portalLock {
        selfdestruct(payable(superadministrator));
    }
    function admin_setAdministrator (address newsuperadministrator) external onlysuperadministrator isLivingSoul portalLock {
        superadministrator = payable(newsuperadministrator);
        _owner = payable(superadministrator);
        emit EventSuperAdminTransfer(superadministrator, newsuperadministrator);
    }
    function admin_showAdministrators() external view returns (address) {return superadministrator;}
    modifier onlysuperadministrator() {require(msg.sender == superadministrator, "Caller is not superadministrator"); _; }
    modifier onlyDualAdminFunction() {require(msg.sender == superadministrator && msg.sender == _owner, "Ownership corrupted"); _; }
    modifier portalLock() {
        require(_status != _ENTERED, "Teleportation has ben disabled");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    modifier isLivingSoul() {require( contractAddressLength(msg.sender) == false , "The unliving may not pass");_;}
}
function contractAddressLength (address contractAddress) view returns (bool) {
    uint256 size;
    assembly {
        size := extcodesize(contractAddress)
    }
    return size > 0;
}
// File: blackboxmint/metaCasperz/production/v1.0/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// File: blackboxmint/metaCasperz/production/v1.0/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: blackboxmint/metaCasperz/production/v1.0/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: blackboxmint/metaCasperz/production/v1.0/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: blackboxmint/metaCasperz/production/v1.0/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: blackboxmint/metaCasperz/production/v1.0/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;









contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;
    constructor(string memory uri_) {
        _setURI(uri_);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);
        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        emit TransferSingle(operator, from, address(0), id, amount);
        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/ERC1155Supply.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) internal _totalSupply;

    function totalSupply(uint256 id) internal view virtual returns (uint256) {
        return _totalSupply[id]; 
    }
    function exists(uint256 id) internal view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    function _beforeTokenTransfer(address operator,address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data)internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzMain.sol


// MetaCasperzMain.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;




contract MetaCasperzMain is ERC1155, Pausable, ERC1155Supply {
    constructor () ERC1155("https://metacasperz.com/test/{id}.json"){}
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) onlyOwner {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
    

// File: blackboxmint/metaCasperz/production/v1.0/MetaCasperzMatic.sol


// metaCasperzMain.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;






contract MetaCasperzMatic is MetaCasperzMain, MetaCasperzTracker, MetaCasperzVault, MetaCasperzWinners, MetaCasperzWhitelist, MetaCasperzAdmin {
    event EventWinnerMinted (address indexed theWinner, uint256 getNextIndexReady, uint256 CurrentPrice);
    event EventAddedNFTWinner (address indexed theWinner, uint isOrNot);
    event EventAdminSetsURI(address indexed setter, string newuri);
    event EventAddressMintsCasperz(address indexed minter, uint256 mintPrice);
    event EventAddressGetsWhitelisted(address indexed whitelistme, uint256 casperzWhiteListID);
    event EventWhitelistStarted(uint256 WhiteListIndex, uint256 whitelistCapactity);
    event EventWhitelistSignUp(address indexed whitelistme, uint256 WhiteListIndex);
    event EventWhitelistMint (address indexed theWinner, uint256 getNextIndexReady, uint256 CurrentPrice);
    constructor() {NFT_priceModifier();}
    function winner_signup (address _theWinner) external onlysuperadministrator portalLock isLivingSoul {
        require(NFT_WinnerCount < NFT_Winner_Max, "You have reached the maximum winner capactity");
        NFT_Winner[_theWinner] = 1; NFT_WinnerCount ++;
        emit EventAddedNFTWinner (_theWinner, 1);
    }
    function winner_mint() external onlyTheWinners {
        require(NFT_getAvailableSupply() < NFT_maximumTotal(), "There is not enough NFTs left in this series");
        NFT_getNextIndexReady();
        _mint (msg.sender, NFT_getNextIndexReady(), 1, "");
        NFT_Winner[msg.sender] = 2;
        NFT_justMinted(msg.sender, NFT_IndexCounter, 1, NFT_CurrentPrice);
        emit EventWinnerMinted(msg.sender, NFT_IndexCounter, NFT_CurrentPrice);
    }
    function winner_status_check(address _winnersAddress) external view returns (uint256){
        return NFT_Winner[_winnersAddress];
    }
    function whitelist_setup(uint256 _whitelistCapactity) external onlysuperadministrator portalLock {
        require(NFT_getAvailableSupply() < NFT_maximumTotal(), "There is not enough NFTs left in this series");
        require(_whitelistCapactity <= NFT_getAvailableSupply(), "There is not enough NFT's for this whitelist, Try again with a smaller capacity");
        WhiteListIndex ++; WhiteListIdCapacity[WhiteListIndex] = _whitelistCapactity;
        emit EventWhitelistStarted(WhiteListIndex, _whitelistCapactity);
    }
    function whitelist_signUp() external portalLock onlyWhitelisted {
        require(WhiteListIndex > 0, "No Whitelisting events have been started" );
        require(WhiteListIdCapacity[WhiteListIndex] > 0, "All seats have been taken this whitelisting event" );
        WhiteListedStatus[msg.sender][WhiteListIndex] = 1;
        WhiteListIdCapacity[WhiteListIndex] -= 1; 
        emit EventWhitelistSignUp(msg.sender, WhiteListIndex);
    }
    function whitelist_mint() external payable onlyWhitelisted portalLock isLivingSoul {
        require(WhiteListIndex > 0, "No Whitelisting events have been started" );
        require(NFT_getAvailableSupply() < NFT_maximumTotal(), "There is not enough NFTs left in this series");
        NFT_priceModifier(); require(NFT_CurrentPrice > 0, "Cannot cannot be 0");
        require(msg.value >= NFT_CurrentPrice, "You need to pay the minting price");
        vault_share(msg.value); NFT_getNextIndexReady();
        _mint (msg.sender, NFT_getNextIndexReady(), 1, "");
        WhiteListedStatus[msg.sender][WhiteListIndex] = 2;
        NFT_justMinted(msg.sender, NFT_IndexCounter, 1, NFT_CurrentPrice);
        emit EventWhitelistMint(msg.sender, NFT_IndexCounter, NFT_CurrentPrice);
    }
    function vault_withdraw_major () external onlymajorVaultKeeper portalLock {
        VAULT_balance_major = (address(this).balance - VAULT_balance_minor);
        require(VAULT_balance_major > 0, "The Vault has been cleared");
        (bool success, ) = VAULT_keeper_major.call{value: VAULT_balance_major}("");
        require(success, "The vault is locked");
        emit EventVaultWithdrawal(address(0), VAULT_balance_major);
        VAULT_balance_major -= VAULT_balance_major;
    }
    function vault_withdraw_minor () external onlyminorVaultKeeper portalLock {
        require(VAULT_balance_minor > 0, "The Vault has been cleared");
        (bool success, ) = VAULT_keeper_minor.call{value: VAULT_balance_minor}("");
        require(success, "The vault is locked");
        emit EventVaultWithdrawal(address(0), VAULT_balance_minor);
        VAULT_balance_minor -= VAULT_balance_minor;
    }
    function vault_set_majorKeeper (address _newmajorKeeper) external onlymajorVaultKeeper portalLock {
        VAULT_keeper_major = payable(_newmajorKeeper);
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_major);
    }
    function vault_set_minorKeeper (address _newminorKeeper) external onlyminorVaultKeeper portalLock{
        VAULT_keeper_minor = payable(_newminorKeeper);
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_minor);
    }
    function vault_emergency_withdrawal () external onlymajorVaultKeeper onlyDualAdminFunction isLivingSoul portalLock {
        require(vault_check_sum() == false, "There is no emergency");
        require(address(this).balance > 0, "The Vault has been cleared");
        uint256 protectMinorKeepersShare = address(this).balance - VAULT_balance_minor;
        (bool success, ) = VAULT_keeper_major.call{value: protectMinorKeepersShare}("");
        require(success, "The vault is locked");
    }
    function NFT_priceCheck() external view returns (uint256){
        return NFT_CurrentPrice;
    }
    function NFT_priceMultiplier(uint256 _powerIncrement) external onlysuperadministrator portalLock isLivingSoul {
        require(_powerIncrement > 0 , "How many zeros would you like to add to wei ?");
        require(_powerIncrement < 21 , "That is maybe enough of those yea ?");
        require(NFT_CurrentPrice * (10 ** _powerIncrement) < (2 ** 256) -1 , "That is just not possible");
        NFT_PriceSpinner = _powerIncrement;
        NFT_priceModifier();
    }

    function tracker_totalSupplyCheck(uint256 _index) external view returns (bool){
        if (NFT_TotalByIndex[_index] == _totalSupply[_index] ) {
            return true;
        }else{
            return false;
        }
    }
    function tracker_totalSupply(uint256 _index) external view returns (uint256){
        return NFT_TotalByIndex[_index];
    }
    function tracker_exists(uint256 _index) external view returns (bool){
        return NFT_TotalByIndex[_index] > 0;
    }
    function NFT_priceModifier() internal returns (uint256) {
        NFT_CurrentPrice = 3050000000000000000 * (10 ** NFT_PriceSpinner);
        if (NFT_IndexCounter < 11 ){NFT_CurrentPrice = 160000000000000000 * (10 ** NFT_PriceSpinner);
        }else if (NFT_IndexCounter > 10 && NFT_IndexCounter < 201){NFT_CurrentPrice = 250000000000000000 * (10 ** NFT_PriceSpinner);     
        }else if (NFT_IndexCounter > 200 && NFT_IndexCounter < 501){NFT_CurrentPrice = 520000000000000000 * (10 ** NFT_PriceSpinner);
        }else if (NFT_IndexCounter > 500 && NFT_IndexCounter < 1001){NFT_CurrentPrice = 1430000000000000000 * (10 ** NFT_PriceSpinner);
        }else if (NFT_IndexCounter > 1000 && NFT_IndexCounter < 2001){NFT_CurrentPrice = 2000000000000000000 * (10 ** NFT_PriceSpinner);
        }else if (NFT_IndexCounter > 2000 && NFT_IndexCounter < 3001){NFT_CurrentPrice = 2500000000000000000 * (10 ** NFT_PriceSpinner);
        }else{if (NFT_IndexCounter > 3000){NFT_CurrentPrice = 3050000000000000000 * (10 ** NFT_PriceSpinner);}}
        return NFT_CurrentPrice;
    }
    function admin_set_uri (string memory newuri) external onlyDualAdminFunction isLivingSoul portalLock {_setURI(newuri);}
    function admin_pause_on() public onlyDualAdminFunction isLivingSoul portalLock {_pause();}
    function admin_pause_off() public onlyDualAdminFunction isLivingSoul portalLock {_unpause();}

    function admin_burn(address account,uint256 id,uint256 value) external virtual onlymajorVaultKeeper onlyDualAdminFunction isLivingSoul portalLock {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()),"ERC1155: caller is not owner nor approved");
        _burn(account, id, value);
    }

    function admin_burnBatch(address account,uint256[] memory ids,uint256[] memory values) public virtual onlymajorVaultKeeper onlyDualAdminFunction isLivingSoul portalLock {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()),"ERC1155: caller is not owner nor approved");
        _burnBatch(account, ids, values);
    }
}