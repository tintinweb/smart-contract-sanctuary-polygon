/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
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
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
interface IAccessControl {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
interface IMagics {
    function itemDetails(uint256 id) external returns (ItemDetails memory);

    function getProfitAddress() external view returns (address);
}
interface ILottery {
    function purchaseTickets(
        address userAddress,
        TokenType tokenType,
        uint256 count
    ) external payable;

    function noteCollection(
        TokenType tokenType,
        uint256 takenLotteryFee
    ) external;

    function withdrawFixedReward(
        uint256 week,
        address userAddress,
        uint8 rank,
        TokenType tokenType
    ) external;

    function claimLotteryAdminRewards(
        uint256 week,
        TokenType tokenType
    ) external;
}
interface IDistributedRewardsPot {
    function storePurchaseStatistics(
        address user,
        TokenType tokenType,
        uint256 purchaseValue,
        uint256 rewardAmount
    ) external;

    function addMintCollection(
        TokenType tokenType,
        uint256 takenFeeAmount
    ) external;

    function withdrawUnclaimedRewards(
        uint256 month,
        address admin,
        TokenType tokenType
    ) external;

    function noteUserMintParticipation(
        address userAddress,
        TokenType tokenType
    ) external;

    function getUserInfoForCurrentMonth(
        address userAddress,
        TokenType tokenType
    ) external view returns (UserInfoDistributed memory);
}

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
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
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
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
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
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
enum TokenType {
    Native,
    AYRA,
    ITHD
}
enum Network {
    Polygon,
    Binance
}
struct ItemDetails {
    address creator;
    uint256 royalty;
    TokenType mintTokenType;
}
struct UserInfoDistributed {
    bool hasParticipated;
    bool hasParticipatedUsingMint;
    bool hasBurned;
    uint256 volumeWeightage;
    uint256 allWeightages;
    uint256 volume;
    uint256 volumeInEther;
    bool hasWithdrawn;
}
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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
contract ERC1155Holder is ERC1155Receiver {
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
contract Literals {
    address internal constant _ZERO_ADDRESS = address(0);
    address internal constant _DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 internal constant _ONE_HUNDRED = 100;
    uint8 internal constant _TWENTY = 20;
    uint8 internal constant _ONE = 1;
    uint8 internal constant _TWO = 2;
    uint8 internal constant _THREE = 3;
    uint8 internal constant _FIVE = 5;
    uint8 internal constant _TEN = 10;
    uint8 internal constant _ZERO = 0;

    uint256 internal constant _PERCENTAGE_PRECISION = 1 ether;

    uint256 internal constant _MAX_UINT_256 = type(uint256).max;

    string internal constant _INSUFFICIENT_VALUE =
        'Insufficient value sent with transaction';
}
contract Recoverable {
    using SafeERC20 for IERC20;

    address private _ZERO_ADDRESS = address(0);
    function _recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        if (_token == _ZERO_ADDRESS) {
            payable(_to).transfer(_amount);
            return true;
        }

        IERC20(_token).safeTransfer(_to, _amount);

        emit TokenRecovered(_token, _to, _amount);

        return true;
    }

    event TokenRecovered(address token, address to, uint256 amount);
}
contract MarketplaceBase is
    ERC1155Holder,
    Recoverable,
    Ownable,
    AccessControl,
    Literals
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct AffiliateStatistics {
        uint256 totalDistributed;
        uint256 maxDistribution;
        uint256 affiliateRatio;
    }

    struct ReferralStatistics {
        uint256 beneficiaries;
        uint256 ayraAmountEarned;
        uint256 ithdAmountEarned;
    }

    struct DistributedRewards {
        uint256 totalClaimable;
        uint256 usersLast60Days;
        uint256 time;
    }

    struct MarketItem {
        address nftaddress;
        uint256 listId;
        uint256 nftId;
        uint256 totalAmount;
        uint256 availableAmount;
        uint256 price;
        uint256 royalty;
        TokenType tokenType;
        address creator;
        address seller;
    }

    struct LastPurchase {
        uint256 price;
        TokenType tokenType;
    }

    Counters.Counter private _listIds;

    Network internal _network;

    uint256 private _feeDenominator = 1000;

    uint256 private _platformFee = 9; // 0.9 %
    uint256 private _platformFeeToken = 5; // 0.5 %

    uint256 private _distributedRewardsFee = 31; // 3.1 %
    uint256 private _distributedRewardsFeeToken = 15; // 1.5 %

    uint256 private _swapLimitBNB = 3 ether;

    uint256 public bridgeFees = 0.05 ether;

    uint256 public maxSaleAmountForRewardsEther = 250 ether;

    bytes32 public constant BRIDGE_ADMIN = keccak256('BRIDGE_ADMIN');

    bool public affilateRewardsStarted = true;
    bool public affilateRewardsStartedPolygon = true;

    IERC20 internal _ayraToken;
    IERC20 internal _ithdToken;

    bool public swapEnabled = true;

    address public profit;
    address public distributed;
    address public bridgeAdmin;

    address internal _lottery;
    address internal _priceFeed;

    string private constant _UNSUPPORTED_TOKEN_TYPE =
        'Token type unsupported for this method';

    mapping(TokenType => AffiliateStatistics) public affiliateStatistics;

    mapping(address => ReferralStatistics) public referralStatistics;

    mapping(address => mapping(address => bool))
        private _hasPurchasedWithReferral;

    mapping(TokenType => uint256) public tokenPriceUSD;

    mapping(address => mapping(TokenType => uint256))
        public userSwappedAmountBNB;

    mapping(uint256 => MarketItem) private _marketItem;

    mapping(address => mapping(uint256 => LastPurchase)) private _lastPurchase;

    mapping(address => bool) public bridgeFeesPaid;

    event Listed(uint256 listId);

    modifier onlyNonNativeToken(TokenType tokenType) {
        require(tokenType != TokenType.Native, _UNSUPPORTED_TOKEN_TYPE);
        _;
    }

    // Receive native tokens for the cases of deficit funds in lottery
    receive() external payable {}

    function changeDistributedAddress(
        address newDistributedAddress
    ) external onlyOwner {
        distributed = newDistributedAddress;
    }

    function listItem(
        address nft,
        uint256 nftId,
        uint256 amount,
        uint256 price,
        TokenType tokenType
    ) external returns (uint256) {
        require(amount > _ZERO, 'Please deposit at least one item!');
        require(price > _ZERO, 'Price should not be zero!');

        _listIds.increment();
        uint256 listId = _listIds.current();

        ItemDetails memory itemDetails = IMagics(nft).itemDetails(nftId);

        IERC1155(nft).safeTransferFrom(
            _msgSender(),
            address(this),
            nftId,
            amount,
            ''
        );

        _marketItem[listId] = MarketItem({
            nftaddress: nft,
            listId: listId,
            nftId: nftId,
            totalAmount: amount,
            availableAmount: amount,
            price: price,
            royalty: itemDetails.royalty,
            tokenType: tokenType,
            creator: itemDetails.creator,
            seller: _msgSender()
        });

        emit Listed(listId);

        return listId;
    }

    function paybridgeFees() external payable {
        require(msg.value >= bridgeFees, _INSUFFICIENT_VALUE);

        bridgeFeesPaid[_msgSender()] = true;

        payable(bridgeAdmin).transfer(msg.value);
    }

    function setBridgeFees(uint256 newBridgeFees) external onlyOwner {
        bridgeFees = newBridgeFees;
    }

    /**
     * @dev Please use one decimal to denote fee. A value of 1 means 0.1%
     */
    function setPlatformFees(
        uint256 newFee,
        uint256 newFeeToken
    ) external onlyOwner {
        _platformFee = newFee;
        _platformFeeToken = newFeeToken;
    }

    /**
     * @dev Please use one decimal to denote fee. A value of 1 means 0.1%
     */
    function setDistributedFees(
        uint256 newFee,
        uint256 newFeeToken
    ) external onlyOwner {
        _distributedRewardsFee = newFee;
        _distributedRewardsFeeToken = newFeeToken;
    }

    function editListing(
        uint256 listId,
        uint256 price,
        TokenType tokenType
    ) external {
        MarketItem storage item = _marketItem[listId];

        require(
            _msgSender() == item.seller,
            'You are not the seller of this item!'
        );

        item.tokenType = tokenType;
        item.price = price;
    }

    function unlistItem(uint256 listId) external {
        MarketItem storage item = _marketItem[listId];

        require(
            _msgSender() == item.seller,
            'You are not the seller of this item!'
        );

        require(item.availableAmount != _ZERO, 'No quantity available');

        item.availableAmount = _ZERO;

        onERC1155Received(
            address(this),
            _msgSender(),
            item.nftId,
            item.availableAmount,
            ''
        );

        IERC1155(item.nftaddress).safeTransferFrom(
            address(this),
            _msgSender(),
            item.nftId,
            item.availableAmount,
            ''
        );
    }

    function buyItem(
        uint256 listId,
        uint256 count,
        address referrer
    ) external payable {
        MarketItem storage item = _marketItem[listId];
        ItemDetails memory itemDetails = IMagics(item.nftaddress).itemDetails(
            item.nftId
        );

        IERC1155 nftContract = IERC1155(item.nftaddress);
        address userAddress = _msgSender();

        require(count > _ZERO, 'Should buy atleast one');
        require(count <= item.availableAmount, 'Quantity unavilable');

        uint256 totalSaleAmount = item.price.mul(count);
        uint256 amountToCreator = totalSaleAmount.mul(item.royalty).div(
            _ONE_HUNDRED
        );
        uint256 amountToProfit = totalSaleAmount
            .mul(
                item.tokenType == TokenType.Native
                    ? _platformFee
                    : _platformFeeToken
            )
            .div(_feeDenominator);
        uint256 amountToDistributed = totalSaleAmount
            .mul(
                itemDetails.mintTokenType == TokenType.Native
                    ? _distributedRewardsFee
                    : _distributedRewardsFeeToken
            )
            .div(_feeDenominator);
        uint256 amountToSeller = totalSaleAmount
            .sub(amountToCreator)
            .sub(amountToProfit)
            .sub(amountToDistributed);

        item.availableAmount = item.availableAmount.sub(count);

        if (item.tokenType == TokenType.Native) {
            // BNB or MATIC
            require(msg.value >= totalSaleAmount, _INSUFFICIENT_VALUE);

            payable(item.creator).transfer(amountToCreator);
            payable(item.seller).transfer(amountToSeller);
            payable(profit).transfer(amountToProfit);
            payable(distributed).transfer(amountToDistributed);
        } else if (item.tokenType == TokenType.AYRA) {
            _ayraToken.safeTransferFrom(
                userAddress,
                item.creator,
                amountToCreator
            );
            _ayraToken.safeTransferFrom(userAddress, profit, amountToProfit);
            _ayraToken.safeTransferFrom(
                userAddress,
                distributed,
                amountToDistributed
            );
            _ayraToken.safeTransferFrom(
                userAddress,
                item.seller,
                amountToSeller
            );
        } else if (item.tokenType == TokenType.ITHD) {
            _ithdToken.safeTransferFrom(
                userAddress,
                address(this),
                totalSaleAmount
            );

            _ithdToken.safeTransfer(item.creator, amountToCreator);
            _ithdToken.safeTransfer(profit, amountToProfit);
            _ithdToken.safeTransfer(distributed, amountToDistributed);
            _ithdToken.safeTransfer(item.seller, amountToSeller);
        }

        onERC1155Received(address(this), userAddress, item.nftId, count, '');
        nftContract.safeTransferFrom(
            address(this),
            userAddress,
            item.nftId,
            count,
            ''
        );

        // solhint-disable-next-line reentrancy
        _lastPurchase[userAddress][item.nftId] = LastPurchase({
            price: totalSaleAmount,
            tokenType: item.tokenType
        });

        if (_shouldNoteAffiliateRewards(referrer))
            _noteAffiliateRewards(listId, referrer, count);

        IDistributedRewardsPot(distributed).storePurchaseStatistics(
            userAddress,
            item.tokenType,
            totalSaleAmount,
            amountToDistributed
        );
    }

    function buyToken(TokenType tokenType) external payable {
        if (!swapEnabled) revert('Sale not enabled!');

        uint256 previouslySwappedAmount = userSwappedAmountBNB[_msgSender()][
            tokenType
        ];
        if (previouslySwappedAmount.add(msg.value) > _swapLimitBNB) {
            revert('Swap limits reached');
        }

        userSwappedAmountBNB[_msgSender()][tokenType] = previouslySwappedAmount
            .add(msg.value);

        payable(profit).transfer(msg.value);

        if (tokenType == TokenType.AYRA) {
            uint256 _ayraValue = _etherToToken(msg.value, TokenType.AYRA);

            _ayraToken.safeTransfer(_msgSender(), _ayraValue);
        } else if (tokenType == TokenType.ITHD) {
            uint256 _ithdValue = _etherToToken(msg.value, TokenType.ITHD);

            _ithdToken.safeTransfer(_msgSender(), _ithdValue);
        } else {
            revert(_UNSUPPORTED_TOKEN_TYPE);
        }
    }

    function changeTokenPrice(
        uint256 newPrice,
        TokenType tokenType
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        tokenPriceUSD[tokenType] = newPrice;
    }

    function changeMaxRewardableSaleAmount(
        uint256 newAmount
    ) external onlyOwner {
        maxSaleAmountForRewardsEther = newAmount;
    }

    function changeBridgeAdmin(address newBridgeAdmin) external onlyOwner {
        _revokeRole(BRIDGE_ADMIN, bridgeAdmin);

        bridgeAdmin = newBridgeAdmin;

        _grantRole(BRIDGE_ADMIN, newBridgeAdmin);
    }

    function changePriceFeedAddress(address _newPriceFeed) external onlyOwner {
        _priceFeed = _newPriceFeed;
    }

    function changeProfitAddress(address newProfitAddress) external onlyOwner {
        profit = newProfitAddress;
    }

    function changeMaxDistribution(
        TokenType tokenType,
        uint256 _newValue
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        affiliateStatistics[tokenType].maxDistribution = _newValue;
    }

    function changeAffiliateRatio(
        TokenType tokenType,
        uint256 _newValue
    ) external onlyOwner onlyNonNativeToken(tokenType) {
        affiliateStatistics[tokenType].affiliateRatio = _newValue;
    }

    function setSwapStatus(bool newStatus) external onlyOwner {
        swapEnabled = newStatus;
    }

    function changeSwapLimitBNB(uint256 newLimit) external onlyOwner {
        _swapLimitBNB = newLimit;
    }

    function setAffiliateRewardsStatus(
        bool newStatus,
        Network network
    ) external onlyOwner {
        if (network == Network.Binance) {
            affilateRewardsStarted = newStatus;
        } else if (network == Network.Polygon) {
            affilateRewardsStartedPolygon = newStatus;
        }
    }

    function recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        bool flag = _recoverFunds(_token, _to, _amount);

        return flag;
    }

    function withdrawUnclaimedDistributedRewards(
        uint256 month,
        TokenType tokenType
    ) external onlyOwner {
        IDistributedRewardsPot(distributed).withdrawUnclaimedRewards(
            month,
            owner(),
            tokenType
        );
    }

    function changeLotteryAddress(address newAddress) external onlyOwner {
        _lottery = newAddress;
    }

    function withdrawFixedLotteryReward(
        uint256 week,
        address userAddress,
        uint8 rank,
        TokenType tokenType
    ) external onlyRole(BRIDGE_ADMIN) {
        _consumeBridgeFeesOf(userAddress);

        ILottery(_lottery).withdrawFixedReward(
            week,
            userAddress,
            rank,
            tokenType
        );
    }

    function getLotteryAddress() external view returns (address) {
        return _lottery;
    }

    function getLastPurchaseDetails(
        address buyer,
        uint256 nftId
    ) external view returns (LastPurchase memory) {
        return _lastPurchase[buyer][nftId];
    }

    function tokenToEther(
        uint256 value,
        TokenType tokenType
    ) external view returns (uint256) {
        return _tokenToEther(value, tokenType);
    }

    function withdrawReferralBenefitsOf(address _userAddress) public {
        require(
            affilateRewardsStarted,
            'Affilate rewards distribution paused!'
        );

        if (_network == Network.Polygon) {
            require(hasRole(BRIDGE_ADMIN, _msgSender()), 'Unauthorized!');

            _consumeBridgeFeesOf(_userAddress);
        } else {
            require(
                _msgSender() == _userAddress,
                'Cannot withdraw rewards of someone else'
            );
        }

        ReferralStatistics storage _referrerStatistics = referralStatistics[
            _userAddress
        ];

        require(
            _referrerStatistics.ayraAmountEarned > _ZERO ||
                _referrerStatistics.ithdAmountEarned > _ZERO,
            'No benefits to claim'
        );

        if (_network == Network.Binance) {
            if (_referrerStatistics.ayraAmountEarned > _ZERO) {
                _ayraToken.safeTransfer(
                    _userAddress,
                    _referrerStatistics.ayraAmountEarned
                );
            }

            if (_referrerStatistics.ithdAmountEarned > _ZERO) {
                _ithdToken.safeTransfer(
                    _userAddress,
                    _referrerStatistics.ithdAmountEarned
                );
            }
        }

        _referrerStatistics.ayraAmountEarned = _ZERO;
        _referrerStatistics.ithdAmountEarned = _ZERO;
    }

    function sendAffilateBenefits(
        uint256 ayraAmountEarned,
        uint256 ithdAmountEarned,
        address userAddress
    ) public onlyRole(BRIDGE_ADMIN) {
        require(affilateRewardsStartedPolygon, 'Withdrawals not enabled.');

        _consumeBridgeFeesOf(userAddress);

        AffiliateStatistics
            storage affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];
        AffiliateStatistics
            storage affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        if (
            ayraAmountEarned.add(affiliateStatisticsAYRA.totalDistributed) >
            affiliateStatisticsAYRA.maxDistribution
        ) {
            ayraAmountEarned = _ZERO;
        }

        if (
            ithdAmountEarned.add(affiliateStatisticsITHD.totalDistributed) >
            affiliateStatisticsITHD.maxDistribution
        ) {
            ithdAmountEarned = _ZERO;
        }

        affiliateStatisticsAYRA.totalDistributed = affiliateStatisticsAYRA
            .totalDistributed
            .add(ayraAmountEarned);
        affiliateStatisticsITHD.totalDistributed = affiliateStatisticsITHD
            .totalDistributed
            .add(ithdAmountEarned);

        if (ayraAmountEarned > _ZERO) {
            _ayraToken.safeTransfer(userAddress, ayraAmountEarned);
        }

        if (ithdAmountEarned > _ZERO) {
            _ithdToken.safeTransfer(userAddress, ithdAmountEarned);
        }
    }

    function fetchSingleItem(
        uint256 id
    ) public view returns (MarketItem memory) {
        return _marketItem[id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _consumeBridgeFeesOf(address userAddress) private {
        require(
            bridgeFeesPaid[userAddress],
            _network == Network.Binance
                ? 'Please pay BSC bridge fee first'
                : 'Please pay MATIC bridge fee first'
        );

        bridgeFeesPaid[userAddress] = false;
    }

    function _noteAffiliateRewards(
        uint256 listId,
        address referrer,
        uint256 count
    ) private {
        MarketItem storage item = _marketItem[listId];

        ReferralStatistics storage _referrerStatistics = referralStatistics[
            referrer
        ];

        AffiliateStatistics
            storage affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];

        AffiliateStatistics
            storage affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        _hasPurchasedWithReferral[referrer][_msgSender()] = true;

        uint256 totalSaleAmount = item.price.mul(count);
        uint256 saleAmountEther = _tokenToEther(
            totalSaleAmount,
            item.tokenType
        );

        saleAmountEther = saleAmountEther > maxSaleAmountForRewardsEther
            ? maxSaleAmountForRewardsEther
            : saleAmountEther;

        uint256 rewardInAYRA = saleAmountEther.mul(_TEN).mul(1 ether).div(
            uint256(_ONE_HUNDRED).mul(affiliateStatisticsAYRA.affiliateRatio)
        );

        uint256 rewardInITHD = saleAmountEther.mul(_TEN).mul(1 ether).div(
            uint256(_ONE_HUNDRED).mul(affiliateStatisticsITHD.affiliateRatio)
        );

        if (
            rewardInAYRA.add(affiliateStatisticsAYRA.totalDistributed) >
            affiliateStatisticsAYRA.maxDistribution
        ) {
            rewardInAYRA = _ZERO;
        }

        if (
            rewardInITHD.add(affiliateStatisticsITHD.totalDistributed) >
            affiliateStatisticsITHD.maxDistribution
        ) {
            rewardInITHD = _ZERO;
        }

        if (rewardInAYRA > _ZERO) {
            _referrerStatistics.ayraAmountEarned = _referrerStatistics
                .ayraAmountEarned
                .add(rewardInAYRA);
            affiliateStatisticsAYRA.totalDistributed = affiliateStatisticsAYRA
                .totalDistributed
                .add(rewardInAYRA);
        }

        if (rewardInITHD > _ZERO) {
            _referrerStatistics.ithdAmountEarned = _referrerStatistics
                .ithdAmountEarned
                .add(rewardInITHD);
            affiliateStatisticsITHD.totalDistributed = affiliateStatisticsITHD
                .totalDistributed
                .add(rewardInITHD);
        }

        if (rewardInAYRA > _ZERO || rewardInITHD > _ZERO) {
            _referrerStatistics.beneficiaries = _referrerStatistics
                .beneficiaries
                .add(_ONE);
        }
    }

    function _etherToToken(
        uint256 value,
        TokenType _toTokenType
    ) private view returns (uint256) {
        uint256 usdPerEther = _getLatestPriceEther();
        uint256 usdValue = value.mul(usdPerEther);

        if (_toTokenType == TokenType.Native) {
            revert(_UNSUPPORTED_TOKEN_TYPE);
        }

        return usdValue.div(tokenPriceUSD[_toTokenType]);
    }

    function _tokenToEther(
        uint256 value,
        TokenType tokenType
    ) private view returns (uint256) {
        if (tokenType == TokenType.Native) {
            return value;
        } else {
            uint256 usdPerEther = _getLatestPriceEther();

            return value.mul(tokenPriceUSD[tokenType]).div(usdPerEther);
        }
    }

    function _shouldNoteAffiliateRewards(
        address referrer
    ) private view returns (bool) {
        return
            referrer != _ZERO_ADDRESS &&
            _msgSender() != referrer &&
            !_hasPurchasedWithReferral[referrer][_msgSender()];
    }

    function _getLatestPriceEther() private view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_priceFeed)
            .latestRoundData();

        return uint256(price).mul(1e10);
    }
}

contract Marketplace is MarketplaceBase {
    constructor(
        IERC20 ayraToken,
        IERC20 ithdToken,
        address _profit,
        address priceFeed,
        address _owner,
        address _bridgeAdmin
    ) {
        _network = Network.Binance;
        _ayraToken = ayraToken;
        _ithdToken = ithdToken;
        profit = _profit;

        _transferOwnership(_owner);

        _priceFeed = priceFeed;
        
        bridgeAdmin = _bridgeAdmin;
        
        _grantRole(BRIDGE_ADMIN, bridgeAdmin);

        AffiliateStatistics
            storage _affiliateStatisticsAYRA = affiliateStatistics[
                TokenType.AYRA
            ];
        AffiliateStatistics
            storage _affiliateStatisticsITHD = affiliateStatistics[
                TokenType.ITHD
            ];

        _affiliateStatisticsAYRA.maxDistribution = 50_000_000_000_000 ether;
        _affiliateStatisticsITHD.maxDistribution = 10_000_000 ether;

        _affiliateStatisticsAYRA.affiliateRatio = 0.000_000_44 ether;
        _affiliateStatisticsITHD.affiliateRatio = 0.001_25 ether;

        tokenPriceUSD[TokenType.AYRA] = 0.000_000_007 ether;
        tokenPriceUSD[TokenType.ITHD] = 0.01 ether;

        maxSaleAmountForRewardsEther = 250 ether;
    }
}