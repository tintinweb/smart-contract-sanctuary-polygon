// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@routerprotocol/router-sdk/contracts/nonupgradeable/RouterCrossTalk.sol";

import "./library/IXERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract XERC20 is Context, IERC20Metadata, RouterCrossTalk, IXERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address _genericHandler
    ) RouterCrossTalk(_genericHandler) {
        _name = name_;
        _symbol = symbol_;
        setLink(msg.sender);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    //outgoing
    function xTransfer(
        uint8 chainId,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external override returns (bool) {
        _xTransfer(to, amount);
        bytes memory data = abi.encode(to, amount);
        bytes4 _selector = bytes4(keccak256("xReceive(address,uint256)"));
        bool success = routerSend(chainId, _selector, data, gasLimit);

        emit XTransfer(chainId, to, amount);

        return success;
    }

    function _xTransfer(address to, uint256 amount) internal {
        require(amount > 0, "Cannot transfer zero");
        _burn(to, amount);
    }

    function _xReceive(address to, uint256 amount) external isSelf {
        _mint(to, amount);
        emit XReceive(to, amount);
    }

    //incoming
    function _routerSyncHandler(bytes4 _interface, bytes memory _data)
        internal
        virtual
        override
        returns (bool, bytes memory)
    {
        // _interface;
        (address to, uint256 amount) = abi.decode(_data, (address, uint256));
        // _xReceive(to, amount);
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeWithSelector(_interface, to, amount)
        );
        return (success, returnData);
        // return (true, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/iGenericHandler.sol";
import "./iRouterCrossTalk.sol";

abstract contract RouterCrossTalk is Context , iRouterCrossTalk, ERC165 {

    iGenericHandler handler;

    address private linkSetter;

    address private feeToken;

    mapping ( uint8 => address ) private Chain2Addr; // CHain ID to Address

    modifier isHandler(){
        require(_msgSender() == address(handler) , "RouterCrossTalk : Only GenericHandler can call this function" );
        _;
    }

    modifier isLinkSet(uint8 _chainID){
        require(Chain2Addr[_chainID] == address(0) , "RouterCrossTalk : Cross Chain Contract to Chain ID set" );
        _;
    }

    modifier isLinkUnSet(uint8 _chainID){
        require(Chain2Addr[_chainID] != address(0) , "RouterCrossTalk : Cross Chain Contract to Chain ID is not set" );
        _;
    }

    modifier isLinkSync( uint8 _srcChainID, address _srcAddress ){
        require(Chain2Addr[_srcChainID] == _srcAddress , "RouterCrossTalk : Source Address Not linked" );
        _;
    }

    modifier isSelf(){
        require(_msgSender() == address(this) , "RouterCrossTalk : Can only be called by Current Contract" );
        _;
    }

    constructor( address _handler ) {
        handler = iGenericHandler(_handler);
    }

    /*
    * @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
    * @param _addr Address of linker.
    */
    function setLink( address _addr ) internal {
        linkSetter = _addr;
    }

    /*
    * @notice Used to set fee Token address, this function is internal and can only be set by contract owner or admins
    * @param _addr Address of linker.
    */
    function setFeeToken( address _addr ) internal {
        feeToken = _addr;
    }

    function fetchHandler( ) external override view returns ( address ) {
        return address(handler);
    }

    function fetchLinkSetter( ) external override view returns( address) {
        return linkSetter;
    }

    function fetchLink( uint8 _chainID ) external override view returns( address) {
        return Chain2Addr[_chainID];
    }

    function fetchFeetToken(  ) external override view returns( address) {
        return feeToken;
    }


    /*
    * @notice routerSend This is internal function to generate a cross chain communication request.
    * @param _destChainId Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to be sent on Destination side.
    */
    function routerSend( uint8 destChainId , bytes4 _selector , bytes memory _data , uint256 _gas) internal isLinkUnSet( destChainId ) returns (bool success) {
        uint8 cid = handler.fetch_chainID();
        bytes32 hash = _hash(address(this),Chain2Addr[destChainId],destChainId, _selector, _data);
        handler.genericDeposit(destChainId , _selector , _data, hash , _gas , feeToken );
        emit CrossTalkSend( cid , destChainId , address(this), Chain2Addr[destChainId] ,_selector, _data , hash );
        return true;
    }

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes memory _data , bytes32 hash ) external override isLinkSync( srcChainID , srcAddress ) isHandler returns ( bool , bytes memory ) {
        uint8 cid = handler.fetch_chainID();
        bytes32 Dhash = _hash(Chain2Addr[srcChainID],address(this),cid, _selector, _data);
        require( Dhash == hash , "RouterSync : Valid Hash" );
        ( bool success , bytes memory _returnData ) = _routerSyncHandler( _selector , _data );
        emit CrossTalkReceive( srcChainID , cid , srcAddress , address(this), _selector, _data , hash );
        return ( success , _returnData );
    }

    /*
    * @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
    * @param _srcAddres Source Address.
    * @param _destAddress Destination Address.
    * @param _destChainId Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    */
    function _hash(address _srcAddres , address _destAddress , uint8 _destChainId , bytes4 _selector , bytes memory _data) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            _srcAddres,
            _destAddress,
            _destChainId,
            _selector,
            keccak256(_data)
        ));
    }

    function Link(uint8 _chainID , address _linkedContract) external override isHandler isLinkSet(_chainID) {
        Chain2Addr[_chainID] = _linkedContract;
        emit Linkevent( _chainID , _linkedContract );
    }

    function Unlink(uint8 _chainID ) external override isHandler {
        emit Unlinkevent( _chainID , Chain2Addr[_chainID] );
        Chain2Addr[_chainID] = address(0);
    }

    function approveFees(address _feeToken , uint256 _value) external {
        IERC20 token = IERC20(_feeToken);
        token.approve( address(handler) , _value );
    }

    /*
    * @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
    * @param _selector Selector to interface.
    * @param _data Data to be handled.
    */
    function _routerSyncHandler( bytes4 _selector , bytes memory _data ) internal virtual returns ( bool ,bytes memory );
    uint256[100] private __gap;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXERC20 is IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `to` in `chainId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a  event.
     */
    function xTransfer(
        uint8 chainId,
        address to,
        uint256 amount,
        uint256 gasLimit
    ) external returns (bool);

    event XTransfer(uint8 chainId, address to, uint256 amount);
    event XReceive(address to, uint256 amount);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.0;

interface iGenericHandler {

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
        uint8 linkerType;
    }

    /*
    * @notic UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    * @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
    * @param _sign Signature of Linker data object signed by linkerSetter address.
    */
    function MapContract( RouterLinker calldata linker , bytes memory _sign ) external;

    /*
    * @notic UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    * @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
    * @param _sign Signature of Linker data object signed by linkerSetter address.
    */
    function UnMapContract(RouterLinker calldata linker , bytes memory _sign ) external;

    /*
    * @notic generic deposit on generic handler contract
    * @param _chainid Chain id to be transacted
    * @param _selector Selector for the crosschain interface
    * @param _data Data to be transferred
    * @param _hash Hash of the data sent to the contract
    * @param _gas Gas Specified for the contract function
    * @param _feeToken Fee Token Specified for the contract function
    */
    function genericDeposit( uint8 _destChainID, bytes4 _selector, bytes memory _data, bytes32 _hash, uint256 _gas, address _feeToken) external;

    /*
    * @notic fetches ChainID for the native chain
    */
    function fetch_chainID( ) external view returns ( uint8 );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface iRouterCrossTalk is IERC165 {

    /*
    * @notice Link event is emitted when a new link is created.
    * @param _chainid Chain id the contract is linked to.
    * @param linkedContract Contract address linked to.
    */
    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    /*
    * @notice UnLink event is emitted when a link is removed.
    * @param _chainid Chain id the contract is unlinked to.
    * @param linkedContract Contract address unlinked to.
    */
    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    /*
    * @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
    * @param sourceChain Source ChainID.
    * @param destChain Destination ChainID.
    * @param sourceAddress Source Address.
    * @param destinationAddress Destination Address.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /*
    * @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
    * @param sourceChain Source ChainID.
    * @param destChain Destination ChainID.
    * @param sourceAddress Source Address.
    * @param destinationAddress Destination Address.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /*
    * @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
    * @param srcChainID Source ChainID.
    * @param srcAddress Destination ChainID.
    * @param _selector Selector to interface on destination side.
    * @param _data Data to interface on Destination side.
    * @param _hash Hash of the data sent.
    */
    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    /*
    * @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
    * @notice This function links contract on other chain ID's.
    * @notice This is an administrative function and can only be initiated by linkSetter address.
    * @param _chainID network Chain ID linked Contract linked to.
    * @param _linkedContract Linked Contract address.
    */
    function Link(uint8 _chainID , address _linkedContract) external;

    /*
    * @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
    * @notice This function unLinks contract on other chain ID's.
    * @notice This is an administrative function and can only be initiated by linkSetter address.
    * @param _chainID network Chain ID linked Contract linked to.
    */
    function Unlink(uint8 _chainID ) external;

    /*
    * @notice fetchLinkSetter This is a public function and fetches the linksetter address.
    */
    function fetchLinkSetter( ) external view returns( address);

    /*
    * @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
    * @param _chainID Chain ID information.
    */
    function fetchLink( uint8 _chainID ) external view returns( address);

    /*
    * @notice fetchLinkSetter This is a public function and fetches the generic handler address.
    */
    function fetchHandler( ) external view returns ( address );


    /*
    * @notice fetchFeetToken This is a public function and fetches the fee token set by admin.
    */
    function fetchFeetToken(  ) external view returns( address);

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