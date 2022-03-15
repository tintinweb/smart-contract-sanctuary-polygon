/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/Context.sol


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

// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/Ownable.sol


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

// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/Address.sol


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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
pragma solidity ^0.8.0;


interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.0;


interface IERC1155 is IERC165 {
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

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)
pragma solidity ^0.8.0;


interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
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
// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/MetaCasperzMain.sol


// MetaCasperzMain.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]

pragma solidity 0.8.12;



contract MetaCasperzMain is ERC1155, Ownable {

    string public name = "Metacasperz";
    string public symbol = "oOOo";
    uint256 public constant NFT_Winner_Max = 50;
    uint256 internal constant NFT_MaxIndex = 3333;
    uint256 internal constant NFT_MaxAmount = 1;
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;
    uint256 public VAULT_balance_major;
    uint256 public VAULT_balance_minor;
    uint256 internal VAULT_share_percentage;
    uint256 internal NFT_PriceSpinner;
    uint256 public NFT_CurrentPrice;
    uint256 public NFT_WinnerCount;
    uint256 public WhiteListIndex;
    uint256 public NFT_IndexedTotal;
    uint256 internal NFT_IndexCounter;
    address internal VAULT_keeper_major;
    address internal VAULT_keeper_minor;
    address internal superadministrator;

    mapping(uint256 => uint256) public NFT_TotalByIndex;
    mapping(address => uint256) public NFT_Winner;
    mapping(uint256 => uint256) internal WhiteListIdCapacity;
    mapping(address => mapping(uint256 => uint)) public WhiteListedStatus;

    event EventVaultWithdrawal(address indexed reciever, uint256 amount);
    event EventVaultDeposit(address indexed sender, uint256 amount);
    event EventVaultReceive(address indexed sender, uint256 amount);
    event EventVaultKeeperTransfer(address from, address to);
    event EventAddedNFTWinner(address indexed theWinner, uint isOrNot);
    event EventVaultShare(uint256 value, uint256 minimumValue, uint256 valutSharePercentage, uint256 VAULT_balance_major, uint256 VAULT_balance_minor );

    constructor () ERC1155("https://metacasperz.com/test/{id}.json"){
        _status = _NOT_ENTERED;
        VAULT_share_percentage = 10;
        VAULT_keeper_major = payable(msg.sender);
        VAULT_keeper_minor = payable(msg.sender);
        superadministrator = payable(msg.sender);
        NFT_PriceSpinner = 2;
        NFT_priceModifier();
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_major);
        emit EventVaultKeeperTransfer(address(0), VAULT_keeper_minor);
    }

    receive() external payable { vault_share(msg.value); emit EventVaultReceive(msg.sender, msg.value); }

    function admin_showAdministrators() external view returns (address) {return superadministrator;}
    function admin_set_uri(string memory newuri) external onlysuperadministrator {require( contractAddressLength(msg.sender) == false , "Not living"); _setURI(newuri);}

    function admin_setAdministrator(address newsuperadministrator) external onlysuperadministrator {
        require( contractAddressLength(msg.sender) == false , "Not living");
        superadministrator = payable(newsuperadministrator);
        _owner = payable(superadministrator);
    }

    function whitelist_statusCheck(address _address) internal view returns (uint) {
        return WhiteListedStatus[_address][WhiteListIndex];
    }

    function whitelist_capacity(uint256 _whitelistIndex) external view returns (uint256) {
        return WhiteListIdCapacity[_whitelistIndex];
    }

    function vault_deposit() external payable {
        require(msg.value > 0);
        vault_share(msg.value);
        emit EventVaultDeposit(msg.sender, msg.value);
    }

    function vault_share(uint256 _value) internal {
        require(_value +  address(this).balance < (2 ** 256) -1, "Vault is full");
        uint256 minimumValue = (100 / VAULT_share_percentage) - 1; 
        uint256 valutSharePercentage = (_value * VAULT_share_percentage) / 100;
        if (_value > minimumValue ){ VAULT_balance_minor += valutSharePercentage; }
        VAULT_balance_major = (address(this).balance - VAULT_balance_minor);
        emit EventVaultShare(_value, minimumValue, valutSharePercentage, VAULT_balance_major, VAULT_balance_minor );
    }

    function vault_quake() external onlymajorVaultKeeper portalLock{
        require(address(this).balance != ( VAULT_balance_minor + VAULT_balance_major), "All Good");
        uint256 scrapeTheBarrel = address(this).balance - (VAULT_balance_minor + VAULT_balance_major);
        vault_share(scrapeTheBarrel);
    }

    function vault_check_balance() external view returns (uint256){return address(this).balance;}
    function NFT_maximumTotal() internal pure returns (uint256) {return NFT_MaxIndex * NFT_MaxAmount;}
    function NFT_remainingTotal() internal view returns (uint256) {return (NFT_MaxIndex * NFT_MaxAmount) - NFT_IndexedTotal;}
    function NFT_MaximumTotal() external pure returns (uint256) {return NFT_maximumTotal();}
    function NFT_RemainingTotal() external view returns (uint256) {return NFT_remainingTotal();}

    function NFT_priceMultiplier(uint256 _powerIncrement) external onlysuperadministrator {
        require(_powerIncrement > 0 && _powerIncrement < 21);
        require(NFT_CurrentPrice * (10 ** _powerIncrement) < (2 ** 256) -1);
        NFT_PriceSpinner = _powerIncrement;
        NFT_priceModifier();
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
    function NFT_justMinted(uint256 _indexCounter, uint256 _mintedAmount) internal {
        require(_indexCounter == NFT_IndexCounter, "Index out");
        NFT_IndexedTotal ++;
        NFT_TotalByIndex[NFT_IndexCounter] = _mintedAmount;
    }

    modifier onlymajorVaultKeeper() {require(msg.sender == VAULT_keeper_major, "Not keeper_major");_;}
    modifier onlyminorVaultKeeper() {require(msg.sender == VAULT_keeper_minor, "Not keeper_minor");_;}

    modifier onlyWhitelisted() {
        require(WhiteListIndex > 0, "No events started" );
        require(whitelist_statusCheck(msg.sender) != 0, "Not whitelisted");
        require(whitelist_statusCheck(msg.sender) == 1, "Already collected NFT");
        _;
    }
    modifier alreadyWhitelisted() {
        require(WhiteListIndex > 0, "No events started" );
        require(WhiteListIdCapacity[WhiteListIndex] > 0, "Reached capacity");
        require(whitelist_statusCheck(msg.sender) != 1, "Already Signedup");
        _;
    }
    modifier onlysuperadministrator() {require(msg.sender == superadministrator, "Not administrator"); _; }

    modifier portalLock() {
        require(_status != _ENTERED, "Teleport Disabled");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
function contractAddressLength(address contractAddress) view returns (bool) {
    uint256 size;
    assembly {
        size := extcodesize(contractAddress)
    }
    return size > 0;
}
    

// File: BlackBoxMint/blackboxmint/metaCasperz/production/v.1.3/MetaCasperzMatic.sol


// metaCasperzMain.sol ERC1155 v1.0
// by Dr.Barns @metaCasperz
// [email protected]
pragma solidity 0.8.12;


contract MetaCasperzMatic is MetaCasperzMain {

    function winner_signup(address _theWinner) external onlysuperadministrator {
        require(NFT_WinnerCount < NFT_Winner_Max);
        require(NFT_Winner[_theWinner] != 1, "Alread signedup");
        NFT_Winner[_theWinner] = 1; NFT_WinnerCount ++;
    }
    function winner_mint() external {
        require(NFT_Winner[msg.sender] == 1, "Not a winner");
        require(NFT_IndexedTotal < NFT_maximumTotal(), "None Left");
        NFT_IndexCounter ++; _mint (msg.sender, NFT_IndexCounter, 1, "");
        NFT_Winner[msg.sender] = 2; NFT_justMinted(NFT_IndexCounter, 1);
    }
    function whitelist_setup(uint256 _whitelistCapactity) external onlysuperadministrator {
        require(_whitelistCapactity > 0);
        require(_whitelistCapactity < NFT_remainingTotal(), "No Capacity");
        WhiteListIndex ++;
        WhiteListIdCapacity[WhiteListIndex] = _whitelistCapactity;
    }
    function whitelist_signUp() external portalLock alreadyWhitelisted {
        require(WhiteListIndex > 0, "No events started" );
        require(WhiteListIdCapacity[WhiteListIndex] > 0, "All seats taken" );
        WhiteListedStatus[msg.sender][WhiteListIndex] = 1;
        WhiteListIdCapacity[WhiteListIndex] -= 1; 
    }
    function whitelist_mint() external payable onlyWhitelisted portalLock {
        require(NFT_IndexedTotal < NFT_maximumTotal(), "None Left");
        require( contractAddressLength(msg.sender) == false , "Not living");
        NFT_priceModifier(); require(NFT_CurrentPrice > 0, "PRICE");
        require(msg.value >= NFT_CurrentPrice, "Not enough");
        vault_share(msg.value); NFT_IndexCounter++;
        _mint (msg.sender, NFT_IndexCounter, 1, "");
        WhiteListedStatus[msg.sender][WhiteListIndex] = 2;
        NFT_justMinted(NFT_IndexCounter, 1);
    }
    
    function vault_withdraw_major() external onlymajorVaultKeeper portalLock {
        VAULT_balance_major = (address(this).balance - VAULT_balance_minor);
        require(VAULT_balance_major > 0, "Empty");
        (bool success, ) = VAULT_keeper_major.call{value: VAULT_balance_major}("");
        require(success, "Locked");
        VAULT_balance_major -= VAULT_balance_major;
    }
    function vault_withdraw_minor() external onlyminorVaultKeeper portalLock {
        require(VAULT_balance_minor > 0, "Empty");
        (bool success, ) = VAULT_keeper_minor.call{value: VAULT_balance_minor}("");
        require(success, "Locked");
        VAULT_balance_minor -= VAULT_balance_minor;
    }
    function vault_set_majorKeeper(address _newmajorKeeper) external onlymajorVaultKeeper portalLock {
        VAULT_keeper_major = payable(_newmajorKeeper);
    }
    function vault_set_minorKeeper(address _newminorKeeper) external onlyminorVaultKeeper portalLock{
        VAULT_keeper_minor = payable(_newminorKeeper);
    }
}