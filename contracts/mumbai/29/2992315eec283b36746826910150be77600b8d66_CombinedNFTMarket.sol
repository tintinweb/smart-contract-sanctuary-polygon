/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
        counter._value = value - 1;
    }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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


pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


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


pragma solidity ^0.8.0;

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

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


pragma solidity ^0.8.0;

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
        _balances[id][from] = fromBalance - amount;
    }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
        _balances[id][from] = fromBalance - amount;
    }

        emit TransferSingle(operator, from, address(0), id, amount);
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


pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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


pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.8.3;

contract CharityContract is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => bool) public _managers;

    constructor() {
        _managers[msg.sender] = true;
    }


    //address nft address token id charity
    //associate owner nft address and charity
    struct CharityEntry {
        address owner;
        address nftAddress;
        uint256 nftTokenId;

        address[] charityAddresses;
        uint256[] charityPercentages;

        uint256 totalPercentage;
        uint256 tokensAmount;
    }

    mapping(string => CharityEntry) public creatorNftToCharityItemArray;
    mapping(address => CharityEntry[]) public ownerCharities;


    function addCreatorNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_, address[] memory charityAddresses_, uint256[] memory charityPercentages_, uint256 totalPercentage_, uint256 tokensAmount_) public {
        require(_managers[msg.sender], "!manager");
        require(charityAddresses_.length > 0, "No Charities");
        require(charityAddresses_.length == charityPercentages_.length, "% no match");
        require(totalPercentage_ > 0 && totalPercentage_ <= 100, "% bounds");
        uint256 sumCharityPercentages = 0;
        for (uint i = 0; i < charityPercentages_.length; i++) {
            if (charityPercentages_[i] <= 0) {
                revert("% > 0");
            }
            sumCharityPercentages.add(charityPercentages_[i]);
        }
        require(sumCharityPercentages == 100, "% must be 100");
        require(tokensAmount_ > 0, "Tokens > 0");
        string memory itemId = string(abi.encodePacked(owner_, nftAddress_, Strings.toString(nftTokenId_)));
        creatorNftToCharityItemArray[itemId] = CharityEntry(
            owner_,
            nftAddress_,
            nftTokenId_,
            charityAddresses_,
            charityPercentages_,
            totalPercentage_,
            tokensAmount_
        );
        removeOwnerCharity(owner_, nftAddress_, nftTokenId_);
        ownerCharities[owner_].push(creatorNftToCharityItemArray[itemId]);
    }

    function removeOwnerCharity(address owner_, address nftAddress_, uint256 nftTokenId_) internal {
        uint ownerAddressCharityIndex;
        for (uint i = 0; i < ownerCharities[owner_].length; i++) {
            CharityEntry memory ownerCharity = ownerCharities[owner_][i];
            if (ownerCharity.owner == owner_ && ownerCharity.nftAddress == nftAddress_ && ownerCharity.nftTokenId == nftTokenId_) {
                ownerAddressCharityIndex = i;
                break;
            }
        }

        if (ownerAddressCharityIndex >= 0) {
            ownerCharities[owner_][ownerAddressCharityIndex] = ownerCharities[owner_][ownerCharities[owner_].length - 1];
            // Remove the last element
            ownerCharities[owner_].pop();
        }
    }

    function removeCreatorNftCharitiesInternal(address owner_, address nftAddress_, uint256 nftTokenId_) internal {
        string memory itemId = string(abi.encodePacked(owner_, nftAddress_, Strings.toString(nftTokenId_)));
        CharityEntry memory item = creatorNftToCharityItemArray[itemId];
        require(item.owner == owner_, "Not same owner");
        require(item.owner != address(0), "Not existing");
        removeOwnerCharity(owner_, nftAddress_, nftTokenId_);
        delete creatorNftToCharityItemArray[itemId];
    }

    function removeCreatorNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_) public {
        require(_managers[msg.sender], "!manager");
        removeCreatorNftCharitiesInternal(owner_, nftAddress_, nftTokenId_);
    }

    function getCreatorNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_) public view returns (CharityEntry memory){
        return creatorNftToCharityItemArray[string(abi.encodePacked(owner_, nftAddress_, Strings.toString(nftTokenId_)))];
    }

    function hasNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_) public view returns (bool){
        CharityEntry memory item = creatorNftToCharityItemArray[string(abi.encodePacked(owner_, nftAddress_, Strings.toString(nftTokenId_)))];
        return item.owner != address(0) && item.tokensAmount > 0 && item.charityAddresses.length > 0;
    }

    function getAllCreatorNftCharities(address owner_) public view returns (CharityEntry[] memory){
        return ownerCharities[owner_];
    }


    struct OwnerCharityDonations {
        address charityAddress;
        address erc20Address;
        uint256 amount;
    }

    struct TotalDonationsSent {
        address erc20Address;
        uint256 amount;
    }

    struct TotalDonationsReceived {
        address erc20Address;
        uint256 amount;
    }

    struct NFTTokenCharityDonations {
        address erc20Address;
        uint256 amount;
    }

    mapping(address => OwnerCharityDonations[]) public ownerCharityDonations;
    mapping(address => TotalDonationsSent[]) public donationsSent;
    mapping(address => TotalDonationsReceived[]) public donationsReceived;
    mapping(string => NFTTokenCharityDonations[]) public nftTokenCharityDonations;


    function getAllCreatorNftDonations(address owner_) public view returns (OwnerCharityDonations[] memory){
        return ownerCharityDonations[owner_];
    }

    function getTotalDonationsSent(address address_) public view returns (TotalDonationsSent[] memory){
        return donationsSent[address_];
    }

    function getTotalDonationsReceived(address address_) public view returns (TotalDonationsReceived[] memory){
        return donationsReceived[address_];
    }

    function getNftTokenDonations(address nftAddress_, uint256 nftTokenId_) public view returns (NFTTokenCharityDonations[] memory){
        return nftTokenCharityDonations[string(abi.encodePacked(nftAddress_, Strings.toString(nftTokenId_)))];
    }

    struct AddDonationToCharityStruct {
        address owner_;
        address charityAddress_;
        address nftAddress_;
        uint256 nftTokenId_;
        address erc20Address_;
        uint256 amount_;
    }

    function addDonationToCharityStats(AddDonationToCharityStruct memory addDonationToCharityStruct_) public {
        require(_managers[msg.sender], "!manager");
        if (hasNftCharities(addDonationToCharityStruct_.owner_, addDonationToCharityStruct_.nftAddress_, addDonationToCharityStruct_.nftTokenId_)) {
            //add in ownerCharityDonations
            uint ownerCharityDonationsIndex;
            for (uint i = 0; i < ownerCharityDonations[addDonationToCharityStruct_.owner_].length; i++) {
                OwnerCharityDonations memory ownerCharityDonation = ownerCharityDonations[addDonationToCharityStruct_.owner_][i];
                if (ownerCharityDonation.charityAddress == addDonationToCharityStruct_.charityAddress_ && ownerCharityDonation.erc20Address == addDonationToCharityStruct_.erc20Address_) {
                    ownerCharityDonationsIndex = i;
                    break;
                }
            }

            if (ownerCharityDonationsIndex >= 0) {
                ownerCharityDonations[addDonationToCharityStruct_.owner_][ownerCharityDonationsIndex].amount = ownerCharityDonations[addDonationToCharityStruct_.owner_][ownerCharityDonationsIndex].amount.add(addDonationToCharityStruct_.amount_);
            } else {
                ownerCharityDonations[addDonationToCharityStruct_.owner_].push(OwnerCharityDonations(addDonationToCharityStruct_.charityAddress_, addDonationToCharityStruct_.erc20Address_, addDonationToCharityStruct_.amount_));
            }

            //add in donationsSent for owner given
            uint donationsSentIndex;
            for (uint i = 0; i < donationsSent[addDonationToCharityStruct_.owner_].length; i++) {
                TotalDonationsSent memory donationSent = donationsSent[addDonationToCharityStruct_.owner_][i];
                if (donationSent.erc20Address == addDonationToCharityStruct_.erc20Address_) {
                    donationsSentIndex = i;
                    break;
                }
            }

            if (donationsSentIndex >= 0) {
                donationsSent[addDonationToCharityStruct_.owner_][donationsSentIndex].amount = donationsSent[addDonationToCharityStruct_.owner_][donationsSentIndex].amount.add(addDonationToCharityStruct_.amount_);
            } else {
                donationsSent[addDonationToCharityStruct_.owner_].push(TotalDonationsSent(addDonationToCharityStruct_.erc20Address_, addDonationToCharityStruct_.amount_));
            }


            //add in donationsReceived for charity received
            uint donationsReceivedIndex;
            for (uint i = 0; i < donationsReceived[addDonationToCharityStruct_.charityAddress_].length; i++) {
                TotalDonationsReceived memory donationReceived = donationsReceived[addDonationToCharityStruct_.charityAddress_][i];
                if (donationReceived.erc20Address == addDonationToCharityStruct_.erc20Address_) {
                    donationsReceivedIndex = i;
                    break;
                }
            }

            if (donationsReceivedIndex >= 0) {
                donationsReceived[addDonationToCharityStruct_.charityAddress_][donationsReceivedIndex].amount = donationsReceived[addDonationToCharityStruct_.charityAddress_][donationsReceivedIndex].amount.add(addDonationToCharityStruct_.amount_);
            } else {
                donationsReceived[addDonationToCharityStruct_.charityAddress_].push(TotalDonationsReceived(addDonationToCharityStruct_.erc20Address_, addDonationToCharityStruct_.amount_));
            }

            //for nftTokenCharityDonations
            string memory nftTokenCharityId = string(abi.encodePacked(addDonationToCharityStruct_.nftAddress_, Strings.toString(addDonationToCharityStruct_.nftTokenId_)));
            uint nftTokenCharityDonationsIndex;
            for (uint i = 0; i < nftTokenCharityDonations[nftTokenCharityId].length; i++) {
                NFTTokenCharityDonations memory nftTokenCharityDonation = nftTokenCharityDonations[nftTokenCharityId][i];
                if (nftTokenCharityDonation.erc20Address == addDonationToCharityStruct_.erc20Address_) {
                    nftTokenCharityDonationsIndex = i;
                    break;
                }
            }
            if (nftTokenCharityDonationsIndex >= 0) {
                nftTokenCharityDonations[nftTokenCharityId][nftTokenCharityDonationsIndex].amount = nftTokenCharityDonations[nftTokenCharityId][nftTokenCharityDonationsIndex].amount.add(addDonationToCharityStruct_.amount_);
            } else {
                nftTokenCharityDonations[nftTokenCharityId].push(NFTTokenCharityDonations(addDonationToCharityStruct_.erc20Address_, addDonationToCharityStruct_.amount_));
            }
        }
    }

    function subtractTokenAmountFromDonation(address owner_, address nftAddress_, uint256 nftTokenId_, uint256 tokensAmount_) public {
        require(_managers[msg.sender], "!manager");
        if (hasNftCharities(owner_, nftAddress_, nftTokenId_)) {
            string memory itemId = string(abi.encodePacked(owner_, nftAddress_, Strings.toString(nftTokenId_)));
            CharityEntry memory item = creatorNftToCharityItemArray[itemId];
            uint256 remainTokensAmount = item.tokensAmount.sub(tokensAmount_);
            if (remainTokensAmount <= 0) {
                removeCreatorNftCharitiesInternal(owner_, nftAddress_, nftTokenId_);
            } else {
                item.tokensAmount = remainTokensAmount;
                creatorNftToCharityItemArray[itemId] = item;
            }

        }
    }


    function transferStuckFunds() public payable nonReentrant {
        require(_managers[msg.sender], "!manager");
        payable(msg.sender).transfer(address(this).balance);
    }


    function addManager(address manager) public {
        require(_managers[msg.sender], "!manager");
        _managers[manager] = true;
    }

    function removeManager(address manager) public {
        require(_managers[msg.sender], "!manager");
        _managers[manager] = false;
    }

}


// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

contract CombinedNFTMarket is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    using Address for address;
    uint256 public _itemIds = 2000;
    uint256 public _bidItemIds = 2000;


    uint256 private _marketplaceFee;
    address payable _marketplaceFeeRecipient;
    bool public paused = false;
    bool public bidsPaused = false;
    address charityContractAddress;

    mapping(address => bool) public _managers;

    enum State {
        INITIATED,
        SOLD,
        CANCELLED
    }

    enum BidState {
        INITIATED,
        ACCEPTED,
        CANCELLED
    }

    constructor(uint256 fee, address feeRecipient, address charityContractAddress_) {
        _marketplaceFee = fee;
        _marketplaceFeeRecipient = payable(feeRecipient);
        charityContractAddress = charityContractAddress_;
    }



    function hasNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_) public view returns (bool){
        return CharityContract(charityContractAddress).hasNftCharities(owner_, nftAddress_, nftTokenId_);

    }

    function addDonationToCharityStats(CharityContract.AddDonationToCharityStruct memory addDonationToCharityStruct_) internal {
        CharityContract(charityContractAddress).addDonationToCharityStats(addDonationToCharityStruct_);
    }

    function subtractTokenAmountFromDonation(address owner_, address nftAddress_, uint256 nftTokenId_, uint256 tokensAmount_) internal {
        CharityContract(charityContractAddress).subtractTokenAmountFromDonation(owner_, nftAddress_, nftTokenId_, tokensAmount_);
    }

    function getCreatorNftCharities(address owner_, address nftAddress_, uint256 nftTokenId_) public view returns (CharityContract.CharityEntry memory){
        return CharityContract(charityContractAddress).getCreatorNftCharities(owner_, nftAddress_, nftTokenId_);
    }



    struct MarketItem {
        uint itemId;
        bool isErc721;
        State state;
        address nftContract;
        address erc20Address;
        uint256 tokenId;
        uint256 amount;
        uint256 price;// price for each item
        address payable seller;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCancelled(uint256 itemId);
    event MarketItemSold(address indexed buyer, uint256 indexed itemId, uint256 amount, State state);

    event MarketItemCreated (
        uint indexed itemId,
        bool isErc721,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address seller,
        address erc20Address
    );

    event MarketItemEdited (
        uint indexed itemId,
        bool isErc721,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address seller,
        address erc20Address
    );

    struct MarketBidItem {
        uint itemId;
        bool isErc721;
        BidState state;
        address nftContract;
        address erc20Address;
        uint256 tokenId;
        uint256 amount;
        uint256 price;// price for each item
        address payable bidder;
    }

    mapping(uint256 => MarketBidItem) private idToMarketBidItem;

    event MarketBidItemCancelled(uint256 itemId);
    event MarketBidItemAccepted(address indexed acceptor, uint256 indexed itemId, uint256 amount, BidState state);

    event MarketBidItemCreated (
        uint indexed itemId,
        bool isErc721,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address bidder,
        address erc20Address
    );

    event MarketBidItemEdited (
        uint indexed itemId,
        bool isErc721,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address bidder,
        address erc20Address
    );

    function setMarketplaceFeePercent(uint256 marketplaceFee) external onlyOwner {
        _marketplaceFee = marketplaceFee;
    }

    function setMarketplaceFeeRecipient(address marketplaceFeeRecipient) external onlyOwner {
        _marketplaceFeeRecipient = payable(marketplaceFeeRecipient);
    }


    function getMarketplaceFee() public view returns (uint256) {
        return _marketplaceFee;
    }

    function getMarketplaceFeeRecipient() public view virtual returns (address) {
        return _marketplaceFeeRecipient;
    }

    function transferStuckFunds() public payable nonReentrant onlyOwner {
        _marketplaceFeeRecipient.transfer(address(this).balance);
    }

    function pause(bool paused_, bool bidsPaused_) public onlyOwner {
        paused = paused_;
        bidsPaused = bidsPaused_;
    }


    function setCurrentItemIds(uint256 itemId_, uint256 bidItemId_) public onlyOwner {
        require(itemId_ >= _itemIds, "invalid itemid");
        require(bidItemId_ >= _bidItemIds, "invalid biditemid");
        _bidItemIds = bidItemId_;
        _itemIds = itemId_;
    }


    function addManager(address manager) public onlyOwner {
        _managers[manager] = true;
    }

    function removeManager(address manager) public onlyOwner {
        _managers[manager] = false;
    }

    function migrateMarketItem(address itemOwner, uint256 itemId, bool isErc721, address nftContract, uint256 tokenId, uint256 price, uint256 amount, address erc20Address) public payable nonReentrant {
        require(_managers[msg.sender], "!manager");
        MarketItem memory item = idToMarketItem[itemId];
        require(item.itemId <= 0, "itemId already taken");
        require(price > 0, "invalid price");

        if (isErc721) {
            amount = 1;
            require(IERC721(nftContract).ownerOf(tokenId) == itemOwner, "not owner");
            if (!IERC721(nftContract).isApprovedForAll(address(itemOwner), address(this))) {
                revert("Missing approval.");
            }
        } else {
            require(amount > 0, "invalid amount");
            require(IERC1155(nftContract).balanceOf(itemOwner, tokenId) >= amount, "invalid balance");
            if (!IERC1155(nftContract).isApprovedForAll(address(itemOwner), address(this))) {
                revert("Missing approval.");
            }
        }

        idToMarketItem[itemId] = MarketItem(
            itemId,
            isErc721,
            State.INITIATED,
            nftContract,
            erc20Address,
            tokenId,
            amount,
            price,
            payable(itemOwner)
        );

    }

    function createMarketItem(bool isErc721, address nftContract, uint256 tokenId, uint256 price, uint256 amount, address erc20Address) public payable nonReentrant {
        require(!paused, "paused");
        require(price > 0, "invalid price");
        if (isErc721) {
            amount = 1;
            require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "invalid owner");
        } else {
            require(amount > 0, "invalid amount");
            require(IERC1155(nftContract).balanceOf(msg.sender, tokenId) >= amount, "invalid balance");
        }

        _itemIds = _itemIds.add(1);
        uint256 itemId = _itemIds;

        idToMarketItem[itemId] = MarketItem(
            itemId,
            isErc721,
            State.INITIATED,
            nftContract,
            erc20Address,
            tokenId,
            amount,
            price,
            payable(msg.sender)
        );
        emit MarketItemCreated(
            itemId,
            isErc721,
            nftContract,
            tokenId,
            amount,
            price,
            msg.sender,
            erc20Address
        );
    }

    function updateMarketItem(uint256 itemId, uint256 price) public payable nonReentrant {
        require(!paused, "paused");
        MarketItem memory item = idToMarketItem[itemId];
        require(item.state == State.INITIATED, "invalid state");
        require(item.seller == msg.sender || msg.sender == owner(), "invalid owner");
        require(item.price > price, "invalid price");

        if (item.isErc721) {
            require(IERC721(item.nftContract).ownerOf(item.tokenId) == msg.sender, "invalid owner");
        } else {
            require(IERC1155(item.nftContract).balanceOf(msg.sender, item.tokenId) >= item.amount, "invalid balance");
        }

        item.price = price;
        idToMarketItem[item.itemId] = item;

        emit MarketItemEdited(
            itemId,
            item.isErc721,
            item.nftContract,
            item.tokenId,
            item.amount,
            price,
            item.seller,
            item.erc20Address
        );
    }

    function cancelMarketItem(uint256 itemId) public virtual {
        MarketItem memory item = idToMarketItem[itemId];
        require(item.state == State.INITIATED, "invalid state");
        require(item.seller == msg.sender || msg.sender == owner(), "invalid owner");
        item.state = State.CANCELLED;
        idToMarketItem[item.itemId] = item;
        emit MarketItemCancelled(itemId);
    }

    function createMarketSale(uint256 itemId, address erc20Address, uint256 amount) public payable nonReentrant {
        require(!paused, "paused");
        MarketItem memory item = idToMarketItem[itemId];
        require(item.state == State.INITIATED, "invalid state");
        require(item.seller != msg.sender, "invalid owner");
        require(amount > 0, "invalid amount");
        require(amount <= item.amount, "invalid amount");
        require(item.erc20Address == erc20Address, "invalid buy token");

        if (item.isErc721) {
            require(amount == 1, "invalid amount");
            if (!IERC721(item.nftContract).isApprovedForAll(address(item.seller), address(this))) {
                revert("Missing approval");
            }
            if (IERC721(item.nftContract).ownerOf(item.tokenId) != item.seller) {
                revert("invalid token balance");
            }
        } else {
            if (!IERC1155(item.nftContract).isApprovedForAll(address(item.seller), address(this))) {
                revert("Missing approval");
            }
            if (IERC1155(item.nftContract).balanceOf(address(item.seller), item.tokenId) < amount) {
                revert("invalid token balance");
            }
        }

        uint256 priceTotal = item.price.mul(amount);
        uint256 fee = priceTotal.mul(_marketplaceFee).div(10000);
        uint256 remainAmount = item.amount.sub(amount);
        uint256 donationAmount = 0;
        uint256 tokensAmountToCharity = 0;
        CharityContract.CharityEntry memory charityEntry;
        if (hasNftCharities(address(item.seller), item.nftContract, item.tokenId)) {
            charityEntry = getCreatorNftCharities(item.seller, item.nftContract, item.tokenId);
            if (charityEntry.tokensAmount >= amount) {
                tokensAmountToCharity = amount;
            } else {
                tokensAmountToCharity = charityEntry.tokensAmount;
            }
            donationAmount = item.price.mul(tokensAmountToCharity).mul(charityEntry.totalPercentage).mul(100).div(10000);
            priceTotal = priceTotal.sub(donationAmount);
        }
        if (remainAmount == 0) {
            item.state = State.SOLD;
        }
        item.amount = remainAmount;
        idToMarketItem[item.itemId] = item;

        if (item.erc20Address == address(0)) {
            require(msg.sender.balance >= priceTotal.add(donationAmount).add(fee), "Insufficient balance");
            if (msg.value < priceTotal.add(donationAmount).add(fee)) {
                revert("Insufficient input price");
            }
            Address.sendValue(_marketplaceFeeRecipient, fee);
            if (priceTotal > 0) {
                Address.sendValue(item.seller, priceTotal);
            }

            if (donationAmount > 0) {
                //process charity send
                for (uint i = 0; i < charityEntry.charityAddresses.length; i++) {
                    address charityAddress = charityEntry.charityAddresses[i];
                    uint256 charityPercentage = charityEntry.charityPercentages[i];
                    uint256 charityDonationAmount = donationAmount.mul(charityPercentage).mul(100).div(10000);
                    Address.sendValue(payable(charityAddress), charityDonationAmount);
                    addDonationToCharityStats(CharityContract.AddDonationToCharityStruct(charityEntry.owner, charityAddress, charityEntry.nftAddress, item.tokenId, item.erc20Address, charityDonationAmount));
                }
            }

            if (msg.value.sub(priceTotal).sub(donationAmount).sub(fee) > 0) {
                Address.sendValue(payable(msg.sender), msg.value.sub(priceTotal).sub(donationAmount).sub(fee));
            }

        } else {
            IERC20 token = IERC20(item.erc20Address);
            require(token.balanceOf(msg.sender) >= priceTotal.add(donationAmount).add(fee), "Insufficient balance");
            if (priceTotal.add(donationAmount).add(fee) > token.allowance(msg.sender, address(this))) {
                revert("invalid allowance");
            }
            token.transferFrom(msg.sender, address(_marketplaceFeeRecipient), fee);
            if (priceTotal > 0) {
                token.transferFrom(msg.sender, address(item.seller), priceTotal);

            }
            if (donationAmount > 0) {
                //process charity send
                for (uint i = 0; i < charityEntry.charityAddresses.length; i++) {
                    address charityAddress = charityEntry.charityAddresses[i];
                    uint256 charityPercentage = charityEntry.charityPercentages[i];
                    uint256 charityDonationAmount = donationAmount.mul(charityPercentage).mul(100).div(10000);
                    token.transferFrom(msg.sender, charityAddress, charityDonationAmount);
                    addDonationToCharityStats(CharityContract.AddDonationToCharityStruct(charityEntry.owner, charityAddress, charityEntry.nftAddress, item.tokenId, item.erc20Address, charityDonationAmount));
                }
            }


            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
        }
        if (tokensAmountToCharity > 0) {
            subtractTokenAmountFromDonation(item.seller, item.nftContract, item.tokenId, tokensAmountToCharity);
        }

        if (item.isErc721) {
            IERC721(item.nftContract).safeTransferFrom(address(item.seller), msg.sender, item.tokenId);
        } else {
            IERC1155(item.nftContract).safeTransferFrom(address(item.seller), msg.sender, item.tokenId, amount, "");
        }
        emit MarketItemSold(msg.sender, itemId, amount, item.state);

    }

    function fetchMarketItem(uint itemId) public view returns (MarketItem memory) {
        MarketItem memory item = idToMarketItem[itemId];
        return item;
    }


    function migrateMarketBidItem(address itemOwner, uint256 itemId, bool isErc721, address nftContract, uint256 tokenId, uint256 price, uint256 amount, address erc20Address) public payable nonReentrant {
        require(_managers[msg.sender], "!manager");
        require(erc20Address != address(0), "not supported");
        MarketBidItem memory item = idToMarketBidItem[itemId];
        require(item.itemId <= 0, "itemId already taken");

        //check that bidder has the funds
        require(price > 0, "invalid price");
        if (isErc721) {
            require(amount == 1, "invalid amount");
        } else {
            require(amount > 0, "invalid amount");
        }
        uint256 priceTotal = price.mul(amount);
        IERC20 token = IERC20(erc20Address);
        require(token.balanceOf(itemOwner) >= priceTotal, "Insufficient balance");
        if (priceTotal > token.allowance(itemOwner, address(this))) {
            revert("invalid allowance");
        }
        idToMarketBidItem[itemId] = MarketBidItem(
            itemId,
            isErc721,
            BidState.INITIATED,
            nftContract,
            erc20Address,
            tokenId,
            amount,
            price,
            payable(itemOwner)
        );

    }

    function createMarketBidItem(bool isErc721, address nftContract, uint256 tokenId, uint256 price, uint256 amount, address erc20Address) public payable nonReentrant {
        require(!bidsPaused, "paused");
        require(erc20Address != address(0), "not supported");
        //check that bidder has the funds
        require(price > 0, "invalid price");
        if (isErc721) {
            require(amount == 1, "invalid amount");
        } else {
            require(amount > 0, "invalid amount");
        }

        uint256 priceTotal = price.mul(amount);

        IERC20 token = IERC20(erc20Address);
        require(token.balanceOf(msg.sender) >= priceTotal, "Insufficient balance");
        if (priceTotal > token.allowance(msg.sender, address(this))) {
            revert("invalid allowance");
        }
        _bidItemIds = _bidItemIds.add(1);
        uint256 itemId = _bidItemIds;

        idToMarketBidItem[itemId] = MarketBidItem(
            itemId,
            isErc721,
            BidState.INITIATED,
            nftContract,
            erc20Address,
            tokenId,
            amount,
            price,
            payable(msg.sender)
        );

        emit MarketBidItemCreated(
            itemId,
            isErc721,
            nftContract,
            tokenId,
            amount,
            price,
            msg.sender,
            erc20Address
        );
    }

    function updateMarketBidItem(uint256 itemId, uint256 price) public payable nonReentrant {
        require(!bidsPaused, "paused");
        require(price > 0, "invalid price");
        MarketBidItem memory item = idToMarketBidItem[itemId];
        require(item.state == BidState.INITIATED, "invalid state");
        require(item.bidder == msg.sender || msg.sender == owner(), "invalid owner");
        require(item.price < price, "invalid price");
        uint256 priceTotal = price.mul(item.amount);
        IERC20 token = IERC20(item.erc20Address);
        require(token.balanceOf(msg.sender) >= priceTotal, "Insufficient balance");
        if (priceTotal > token.allowance(msg.sender, address(this))) {
            revert("invalid allowance");
        }
        item.price = price;
        idToMarketBidItem[item.itemId] = item;
        emit MarketBidItemEdited(
            itemId,
            item.isErc721,
            item.nftContract,
            item.tokenId,
            item.amount,
            price,
            item.bidder,
            item.erc20Address
        );
    }

    function cancelMarketBidItem(uint256 itemId) public virtual {
        MarketBidItem memory item = idToMarketBidItem[itemId];
        require(item.state == BidState.INITIATED, "invalid state");
        require(item.bidder == msg.sender || msg.sender == owner(), "invalid owner");
        item.state = BidState.CANCELLED;
        idToMarketBidItem[item.itemId] = item;
        emit MarketBidItemCancelled(itemId);
    }

    function createMarketAccept(uint256 itemId, address erc20Address, uint256 amount) public payable nonReentrant {
        require(!bidsPaused, "paused");
        require(erc20Address != address(0), "not supported");

        MarketBidItem memory item = idToMarketBidItem[itemId];
        require(item.state == BidState.INITIATED, "invalid state");
        require(item.bidder != msg.sender, "invalid owner");
        require(amount > 0, "invalid amount");
        require(amount <= item.amount, "invalid amount");
        require(item.erc20Address == erc20Address, "invalid buy token");


        //check token approval and balance from msg.sender

        if (item.isErc721) {
            require(amount == 1, "invalid amount");
            if (!IERC721(item.nftContract).isApprovedForAll(address(msg.sender), address(this))) {
                revert("Missing approval");
            }
            if (IERC721(item.nftContract).ownerOf(item.tokenId) != msg.sender) {
                revert("Insufficient token balance");
            }
        } else {
            if (!IERC1155(item.nftContract).isApprovedForAll(address(msg.sender), address(this))) {
                revert("Missing approval");
            }
            if (IERC1155(item.nftContract).balanceOf(address(msg.sender), item.tokenId) < amount) {
                revert("Insufficient token balance");
            }
        }
        uint256 priceTotal = item.price.mul(amount);
        uint256 fee = priceTotal.mul(_marketplaceFee).div(10000);
        uint256 remainAmount = item.amount.sub(amount);
        uint256 donationAmount = 0;
        uint256 tokensAmountToCharity = 0;
        CharityContract.CharityEntry memory charityEntry;
        if (hasNftCharities(address(msg.sender), item.nftContract, item.tokenId)) {
            charityEntry = getCreatorNftCharities(msg.sender, item.nftContract, item.tokenId);
            if (charityEntry.tokensAmount >= amount) {
                tokensAmountToCharity = amount;
            } else {
                tokensAmountToCharity = charityEntry.tokensAmount;
            }
            donationAmount = item.price.mul(tokensAmountToCharity).mul(charityEntry.totalPercentage).mul(100).div(10000);
            priceTotal = priceTotal.sub(donationAmount);
        }

        if (remainAmount == 0) {
            item.state = BidState.ACCEPTED;
        }
        item.amount = remainAmount;
        idToMarketBidItem[item.itemId] = item;

        IERC20 token = IERC20(item.erc20Address);
        require(token.balanceOf(item.bidder) >= priceTotal.add(donationAmount).add(fee), "Insufficient balance");
        if (priceTotal.add(donationAmount).add(fee) > token.allowance(item.bidder, address(this))) {
            revert("invalid allowance");
        }
        token.transferFrom(item.bidder, address(_marketplaceFeeRecipient), fee);
        if (priceTotal > 0) {
            token.transferFrom(item.bidder, msg.sender, priceTotal);
        }

        if (donationAmount > 0){
            //process charity send
            for (uint i = 0; i < charityEntry.charityAddresses.length; i++) {
                address charityAddress = charityEntry.charityAddresses[i];
                uint256 charityPercentage = charityEntry.charityPercentages[i];
                uint256 charityDonationAmount = donationAmount.mul(charityPercentage).mul(100).div(10000);
                token.transferFrom(item.bidder, charityAddress, charityDonationAmount);
                addDonationToCharityStats(CharityContract.AddDonationToCharityStruct(charityEntry.owner, charityAddress, charityEntry.nftAddress, item.tokenId, item.erc20Address, charityDonationAmount));
            }
        }

        if (msg.value > 0) {
            Address.sendValue(payable(msg.sender), msg.value);
        }

        if (tokensAmountToCharity > 0){
            subtractTokenAmountFromDonation(msg.sender, item.nftContract, item.tokenId, tokensAmountToCharity);

        }

        if (item.isErc721) {
            IERC721(item.nftContract).safeTransferFrom(msg.sender, address(item.bidder), item.tokenId);
        } else {
            IERC1155(item.nftContract).safeTransferFrom(msg.sender, address(item.bidder), item.tokenId, amount, "");
        }
        emit MarketBidItemAccepted(msg.sender, itemId, amount, item.state);
    }

    function fetchMarketBidItem(uint itemId) public view returns (MarketBidItem memory) {
        return idToMarketBidItem[itemId];
    }
}