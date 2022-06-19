/**
 *Submitted for verification at polygonscan.com on 2022-06-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/
// SPDX-License-Identifier: MIT
// File: GGDAO/contracts/Character NFT/ownable.sol


pragma solidity ^0.8.0;

contract Ownable 
{

  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor()
  {
    owner = msg.sender;
  }
  
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// File: GGDAO/contracts/Character NFT/IERC165.sol


pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: GGDAO/contracts/Character NFT/IERC1155Receiver.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
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

// File: GGDAO/contracts/Character NFT/ERC165.sol



pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: GGDAO/contracts/Character NFT/IERC1155.sol



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

// File: GGDAO/contracts/Character NFT/IERC1155MetadataURI.sol

pragma solidity ^0.8.0;


interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

// File: GGDAO/contracts/Character NFT/ERC1155.sol

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

// File: GGDAO/contracts/Character NFT/ERC1155Supply.sol

pragma solidity ^0.8.0;

abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
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

// File: GGDAO/contracts/Character NFT/main.sol


pragma solidity ^0.8.0;

interface POTIONS {
    function newCharacter() external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
     function burnPotion(address user, uint256 _id) external;
}

interface GENESIS {
    function createNewCharacter(uint256 _id, string memory folderHash) external;
    function mintGenesis(address _to, uint256 _id) external;
}

interface ERC20 {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface DISTRIBUTE {
    function addClaimableWETHFounders(uint256 amount) external;
    function addClaimableGGFounders(uint256 amount) external;
    function addClaimableWETHGenesis(uint256 amount) external;
    function addClaimableGGGenesis(uint256 amount) external;
}


contract CharacterNFT is ERC1155Supply, Ownable{
    address potionContract;
    address genContract;
    using SafeMath for uint;
    uint256 characterCount = 0;
    mapping(uint256 => string) public characterToFolderHash;
    mapping(uint256 => uint256) public characterToCoinGenesisSupply;
    mapping(uint256 => uint256) public characterToCoinNonGenesisSupply;
    mapping(uint256 => uint256) public characterToCount;
    mapping(uint256 => uint256) public characterToNonCount;
    mapping(string => uint256) public bundleToPrice;
    mapping(string => uint256[]) public bundleToItems;
    mapping(uint256 => uint256) public characterToGenPriceWETH;
    mapping(uint256 => uint256) public characterToNonGenPriceWETH;
    mapping(uint256 => uint256) public characterToGenPriceGG;
    mapping(uint256 => uint256) public characterToNonGenPriceGG;
    mapping(uint256 => bool) public characterToPublicEnabled;
    mapping(uint256 => mapping(address => bool)) public characterToWhitelist;
    mapping(address => bool) public newM;

    constructor() public ERC1155("") {

    }

    function setPotionContract(address _potContract) public onlyOwner {
        potionContract = _potContract;
    }

    function setGenContract(address _genContract) public onlyOwner {
        genContract = _genContract;
    }

    address GGContract;
    address WETHContract;
    address distributeContract;
    function setWETHContract(address _addy) public onlyOwner {
        WETHContract = _addy;
    }

    function setDistContract(address _addy) public onlyOwner {
        uint256 approve_amount = 115792089237316195423570985008687907853269984665640564039457584007913129639935; //(2^256 - 1 )
        distributeContract = _addy;
        ERC20(WETHContract).approve(_addy, approve_amount);
        ERC20(GGContract).approve(_addy,approve_amount);
    }

    function setGGContract(address _contract) public onlyOwner {
        GGContract = _contract;
    }

    address[] public teamAddresses;

    function createBundle(string memory bundleName, uint256 priceWei, uint[] memory itemIDs) public {
        require(isTeam(msg.sender));
        bundleToPrice[bundleName] = priceWei;
        bundleToItems[bundleName] = itemIDs;
    }

    uint256[] internal amounts;
    function mintBundle(string memory _bundleName) public  {
        delete amounts;
        ERC20(WETHContract).transferFrom(msg.sender, address(this),bundleToPrice[_bundleName]);
        for (uint i=0;i<bundleToItems[_bundleName].length; i++) {
            require(characterToCoinGenesisSupply[bundleToItems[_bundleName][i]]>0 || characterToCoinNonGenesisSupply[bundleToItems[_bundleName][i]]>0, "Max Supply Reached");
        }
        for (uint i=0;i<bundleToItems[_bundleName].length; i++) {
            amounts.push(1);
        }

        _mintBatch(msg.sender, bundleToItems[_bundleName], amounts, "");
        for (uint i=0;i<bundleToItems[_bundleName].length; i++) {
            if (characterToCoinGenesisSupply[bundleToItems[_bundleName][i]] > 0) {
                characterToCoinGenesisSupply[bundleToItems[_bundleName][i]] -= 1;
                GENESIS(genContract).mintGenesis(msg.sender, bundleToItems[_bundleName][i]);
            } else {
                characterToCoinNonGenesisSupply[bundleToItems[_bundleName][i]] -= 1;
            }
        }
    }

    function createNewCharacter(string memory folderHash, uint256 genPriceInWei, uint256 nonGenPriceInWei, uint256 genPriceInGG, uint256 nonGenPriceInGG) public {
        require(isTeam(msg.sender));
        uint256 _id = (characterCount*100) + 100;
        for (uint i = 0; i < 100; i++) {
            characterToFolderHash[_id+i] = folderHash;
        }
        characterToCoinGenesisSupply[_id] = 2500;
        characterToCoinNonGenesisSupply[_id] = 0;
        characterToGenPriceWETH[_id] = genPriceInWei;
        characterToNonGenPriceWETH[_id] = nonGenPriceInWei;
        characterToGenPriceGG[_id] = genPriceInGG;
        characterToNonGenPriceGG[_id] = nonGenPriceInGG;
        characterToCount[_id] = 0;
        characterToNonCount[_id] = 0;
        characterToPublicEnabled[_id] = false;
        POTIONS(potionContract).newCharacter();
        GENESIS(genContract).createNewCharacter(_id, folderHash);
        characterCount+=1;
    }

    function addNonGenesis(uint256 _id, uint256 addSupply) public {
        require(isTeam(msg.sender));
        characterToCoinNonGenesisSupply[_id] += addSupply;
    }

    function enablePublicMint(uint256 _id) public {
        require(isTeam(msg.sender));
        characterToPublicEnabled[_id] = true;
    }

    function disablePublicMint(uint256 _id) public {
        require(isTeam(msg.sender));
        characterToPublicEnabled[_id] = false;
        //characterToWhitelist[_id] = newM;
    }

    function setWhiteList(uint256 _id, address[] memory _addresses) public {
        require(isTeam(msg.sender));
        for (uint i=0; i < _addresses.length; i++) {
            characterToWhitelist[_id][_addresses[i]] = true;
        }
    }

    function mintGenesisWETH(uint256 _id) public {
        if (!characterToPublicEnabled[_id]) {
            require(characterToWhitelist[_id][msg.sender]);
        }
        ERC20(WETHContract).transferFrom(msg.sender, address(this), characterToGenPriceWETH[_id]);
        DISTRIBUTE(distributeContract).addClaimableWETHFounders((characterToGenPriceWETH[_id]*2)/100);
        require(characterToCount[_id] < characterToCoinGenesisSupply[_id]);
        _mint(msg.sender, _id, 1, "");
        GENESIS(genContract).mintGenesis(msg.sender, _id);
        characterToCount[_id] += 1;
    }

    function mintGenesisGG(uint256 _id) public {
        if (!characterToPublicEnabled[_id]) {
            require(characterToWhitelist[_id][msg.sender]);
        }
        ERC20(GGContract).transferFrom(msg.sender, address(this), characterToGenPriceGG[_id]);
        DISTRIBUTE(distributeContract).addClaimableGGFounders((characterToGenPriceGG[_id]*2)/100);
        require(characterToCount[_id] < characterToCoinGenesisSupply[_id]);
        _mint(msg.sender, _id, 1, "");
        GENESIS(genContract).mintGenesis(msg.sender, _id);
        characterToCount[_id] += 1;
    }

    function initialAirdropGenesis(uint256 _id, address[] memory holders) public {
        require(isTeam(msg.sender));
        for (uint i=0; i < holders.length; i++) {
            _mint(holders[i], _id, 1, "");
            characterToCount[100] += 1;
        }
    }

    function applyPotion(uint256 _potionId, uint256 _tokenID) public {
        require(POTIONS(potionContract).balanceOf(msg.sender, _potionId)>0);
        require(balanceOf(msg.sender, _tokenID) > 0);
        uint256 _charId = _tokenID.sub(_tokenID.mod(100));
        POTIONS(potionContract).burnPotion(msg.sender,_potionId);
        _burn(msg.sender,_tokenID,1);
        if (_tokenID - _charId < 50) {
            _mint(msg.sender, (_charId+1+_potionId), 1, "");
        } else {
            _mint(msg.sender, (_charId+51+_potionId), 1, "");
        }
    }

    function mintNonGenesisWETH(uint256 _id) public {
        if (!characterToPublicEnabled[_id]) {
            require(characterToWhitelist[_id][msg.sender]);
        }
        ERC20(WETHContract).transferFrom(msg.sender, address(this), characterToNonGenPriceWETH[_id]);
        DISTRIBUTE(distributeContract).addClaimableWETHGenesis((characterToGenPriceWETH[_id]*2)/100);
        require(characterToNonCount[_id] < characterToCoinNonGenesisSupply[_id]);
        _mint(msg.sender, _id+50, 1, "");
        characterToNonCount[_id] += 1;
    }

    function mintNonGenesisGG(uint256 _id) public {
        if (!characterToPublicEnabled[_id]) {
            require(characterToWhitelist[_id][msg.sender]);
        }
        ERC20(GGContract).transferFrom(msg.sender, address(this), characterToNonGenPriceGG[_id]);
        DISTRIBUTE(distributeContract).addClaimableGGGenesis((characterToGenPriceGG[_id]*2)/100);
        require(characterToNonCount[_id] < characterToCoinNonGenesisSupply[_id]);
        _mint(msg.sender, _id+50, 1, "");
        characterToNonCount[_id] += 1;
    }

    function setPriceWETH(uint256 _id, bool _genesis, uint256 _newPrice) public {
        require(isTeam(msg.sender));
        if (_genesis) {
            characterToGenPriceWETH[_id] = _newPrice;
        } else {
            characterToNonGenPriceWETH[_id] = _newPrice;
        }
    }

    function setPriceGG(uint256 _id, bool _genesis, uint256 _newPrice) public {
        require(isTeam(msg.sender));
        if (_genesis) {
            characterToGenPriceGG[_id] = _newPrice;
        } else {
            characterToNonGenPriceGG[_id] = _newPrice;
        }
    }

    function name()
    external
    view
    returns (string memory) {
        return "Character NFTs";
    }

    function symbol()
    external
    view
    returns (string memory) {
        return "Symbol";
    }
    
    function isTeam(address[] calldata _users) public onlyOwner {
      delete teamAddresses;
      teamAddresses = _users;
    }

    function isTeam(address _user) public view returns (bool) {
      for (uint i = 0; i < teamAddresses.length; i++) {
        if (teamAddresses[i] == _user) {
            return true;
        }
      }
      return false;
    }

    function uri(uint256 _id) override public view returns (string memory) {
        return string(abi.encodePacked( "ipfs://",
            characterToFolderHash[_id], "/",
            Strings.toString(_id),
            ".json")
        );
    }

    function extractWETH() external onlyOwner {
      ERC20(WETHContract).transfer(msg.sender, ERC20(WETHContract).balanceOf(address(this)));
    }

    function extractGG() external onlyOwner {
      ERC20(GGContract).transfer(msg.sender, ERC20(WETHContract).balanceOf(address(this)));
    }

}