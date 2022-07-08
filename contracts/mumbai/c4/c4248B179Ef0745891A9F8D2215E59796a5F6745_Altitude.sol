/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma abicoder v2;

/******************************************/
/*           IERC20 starts here           */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

/******************************************/
/*           Context starts here          */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*           Ownable starts here          */
/******************************************/

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/******************************************/
/*      IERC20Metadata starts here        */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

/******************************************/
/*           ERC20 starts here            */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
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

        emit Transfer(account, 0x000000000000000000000000000000000000dEaD, amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

/******************************************/
/*          LPTOKEN starts here           */
/******************************************/

contract LPTOKEN is ERC20, Ownable {

    address public minter;

    event Mint(address _to, uint256 _amount);
    event Burn(address _from, uint256 _amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) 
    {
    }

    /**
     * @dev Mint new LP tokens.
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        emit Mint(_to, _amount);
    }

    /**
     * @dev Burn LP tokens.
     */
    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }
}

/***************************************************/
/*   ILayerZeroUserApplicationConfig starts here   */
/***************************************************/

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

/******************************************/
/*     ILayerZeroEndpoint starts here     */
/******************************************/

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. ie: pay for a specified destination gasAmount, or receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

/******************************************/
/*     ILayerZeroReceiver starts here     */
/******************************************/

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

/******************************************/
/*          ALTITUDE starts here          */
/******************************************/

contract Altitude is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {

    // CONSTANTS  
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint8 internal constant TYPE_SWAP_REMOTE = 1;
    uint8 internal constant TYPE_ADD_LIQUIDITY = 2;
    uint8 internal constant TYPE_REMOVE_LIQUIDITY = 3;
    uint8 internal constant TYPE_REDEEM_LIQUIDITY = 4;

    // STRUCTS
    struct ChainPath {
        bool ready;
        address srcToken;
        uint16 dstChainId;
        address dstToken;
        uint256 remoteLiquidity;
        uint256 localLiquidity;
        uint256 rewardPoolSize;
        LPTOKEN lpToken;
    }

    // VARIABLES
    uint256 internal P = 45 * 1e14;
    uint256 internal D1 = 6000 * 1e14;
    uint256 internal D2 = 500 * 1e14;
    uint256 internal L1 = 40 * 1e14;
    uint256 internal L2 = 9960 * 1e14;

    ILayerZeroEndpoint public layerZeroEndpoint;
    ChainPath[] public chainPaths;
    address public feeTo;
    mapping(uint16 => mapping(address => uint256)) public chainPathIndexLookup; // lookup for chainPath by chainId => token => index
    mapping(uint16 => mapping(uint8 => uint256)) public gasLookup;              // lookup for gas fee by chainId => function => gas
    mapping(uint16 => bytes) public bridgeLookup;

    // EVENTS
    event Swap(uint16 _dstChainId, address _dstToken, uint256 _amount, bytes _to);
    event AddLiquidity(uint16 _dstChainId, address _dstToken, uint256 _amount);
    event RemoveLiquidityLocal(uint16 _dstChainId, address _dstToken, uint256 _amount);
    event RemoveLiquidityRemote(uint16 _dstChainId, address _dstToken, uint256 _amount, bytes _to);
    event Remote_Swap(uint16 _srcChainId, address _Token, uint256 _amount, address _to);
    event Remote_AddLiquidity(uint16 _srcChainId, address _dstToken, uint256 _amount);
    event Remote_RemoveLiquidityLocal(uint16 _srcChainId, address _dstToken, uint256 _amount);
    event Remote_RemoveLiquidityRemote(uint16 _srcChainId, address _dstToken, uint256 _amount, address _to);

    constructor(address _endpoint) {
        layerZeroEndpoint = ILayerZeroEndpoint(_endpoint);
    }

/******************************************/
/*           ADMIN starts here            */
/******************************************/

    /**
     * @dev Add a new chain and token pair for swapping.
     * @param _srcToken Token on the local chain.
     * @param _dstChainId Destination chain ID.
     * @param _dstToken Token on the destination chain.
     * @param _name Name of the associated LP token.
     * @param _symbol Symbol of the associated LP token.
     */
    function addChainPath(address _srcToken, uint16 _dstChainId, address _dstToken, string memory _name, string memory _symbol) external onlyOwner {
        for (uint256 i = 0; i < chainPaths.length; ++i) {
            ChainPath memory cp = chainPaths[i];
            bool exists = cp.dstChainId == _dstChainId && cp.dstToken == _dstToken;
            require(!exists, "Altitude: cant createChainPath of existing _dstChainId and _dstToken");
        }
        chainPathIndexLookup[_dstChainId][_dstToken] = chainPaths.length;
        LPTOKEN lpToken = new LPTOKEN(_name, _symbol);
        chainPaths.push(ChainPath(false, _srcToken, _dstChainId, _dstToken, 0, 0, 0, lpToken));
    }

    /**
     * @dev Enable swapping for a chain and token pair.
     * @param _dstChainId Destination chain ID.
     * @param _dstToken Token on the destination chain.
     */
    function activateChainPath(uint16 _dstChainId, address _dstToken) external onlyOwner {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        require(cp.ready == false, "Altitude: chainPath is already active");
        // this func will only be called once
        cp.ready = true;
    }

    /**
     * @dev Set the Alititude contract for a destination chain.
     * @param _dstChainId Destination chain ID.
     * @param _bridgeAddress Address of the Altitude contract at the destination chain.
     */
    function setBridge(uint16 _dstChainId, bytes calldata _bridgeAddress) external onlyOwner {
        require(bridgeLookup[_dstChainId].length == 0, "Altitude: Bridge already set!");
        bridgeLookup[_dstChainId] = _bridgeAddress;
    }

    /**
     * @dev Set the gas limit for a function type at a destination chain.
     * @param _dstChainId Destination chain ID.
     * @param _functionType Target function (SWAP, ADD, REMOVE, REDEEM).
     * @param _gasAmount Gas limit used by the target function.
     */
    function setGasAmount(uint16 _dstChainId, uint8 _functionType, uint256 _gasAmount) external onlyOwner {
        require(_functionType >= 1 && _functionType <= 4, "Altitude: invalid _functionType");
        gasLookup[_dstChainId][_functionType] = _gasAmount;
    }

    /**
     * @dev Deposit into chain path's reward pool.
     * @param _dstChainId Destination chain ID.
     * @param _dstToken Token on the destination chain.
     * @param _amount Amount of reward tokens to deposit.
     */
    function depositRewardPool(uint16 _dstChainId, address _dstToken, uint256 _amount) external onlyOwner {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        IERC20(cp.srcToken).transferFrom(msg.sender, address(this), _amount);
        cp.rewardPoolSize += _amount;
    }

    /**
     * @dev Withdraw from chain path's reward pool.
     * @param _dstChainId Destination chain ID.
     * @param _dstToken Token on the destination chain.
     * @param _amount Amount of reward tokens to withdraw.
     */
    function withdrawRewardPool(uint16 _dstChainId, address _dstToken, uint256 _amount, address _to) external onlyOwner {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);  
        require(cp.rewardPoolSize >= _amount, "Altitude: not enough funds in reward pool.");
        IERC20(cp.srcToken).transferFrom(address(this), _to, _amount);
        cp.rewardPoolSize -= _amount;
    }

    /**
     * @dev Set the protocol fee receiving address.
     */
    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), "Altitude: recipient can't be zero address.");
        feeTo = _feeTo;
    }

    /**
     * @dev Set the rebalance fee (denominator 1e18).
     */
    function setFeeParameters(uint256 _protocolFee, uint256 _D1, uint256 _D2, uint256 _L1, uint256 _L2) external onlyOwner {
        P = _protocolFee;
        D1 = _D1;
        D2 = _D2;
        L1 = _L1;
        L2 = _L2;
    }

/******************************************/
/*           LOCAL starts here            */
/******************************************/

    /**
     * @dev Swap local tokens for tokens on another chain.
     * @param _dstChainId ID of destination chain.
     * @param _dstToken Address of token on the destination chain (in).
     * @param _amount Amount of tokens to swap.
     * @param _to Address of recipient on the destination chain.
     */
    function swap(uint16 _dstChainId, address _dstToken, uint256 _amount, bytes memory _to) public payable {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        require(cp.remoteLiquidity >= _amount, "Altitude: not enough liquidity");
        // PROTOCOL FEE: send to DAO, deduct from swap amount
        // REBALANCE FEE: add to reward pool, deduct from swap amount 
        // REBALANCE REWARD: remove from reward pool, add to swap amount
        uint256 swapAmount = _amount;
        (uint256 rebalanceFee, uint256 protocolFee) = getFees(_dstChainId, _dstToken, _amount);
        swapAmount -= protocolFee;
        if (rebalanceFee > 0) {
            swapAmount -= rebalanceFee;
            cp.rewardPoolSize += rebalanceFee;
        }

        // LOCAL: deposit tokens, remove liquidity for chain path
        // REMOTE: withdraw tokens, add liquidity for chain path
        IERC20(cp.srcToken).transferFrom(msg.sender, address(this), _amount - protocolFee);
        IERC20(cp.srcToken).transferFrom(msg.sender, feeTo, protocolFee);
        cp.localLiquidity += swapAmount;
        cp.remoteLiquidity -= swapAmount;

        bytes memory payload = abi.encode(TYPE_SWAP_REMOTE, abi.encodePacked(cp.srcToken), swapAmount, _to);
        bytes memory adapterParams = getAndCheckGasFee(TYPE_SWAP_REMOTE, _dstChainId, payload);
        layerZeroEndpoint.send{value: msg.value}(_dstChainId, bridgeLookup[_dstChainId], payload, payable(msg.sender), address(this), adapterParams);

        emit Swap(_dstChainId, _dstToken, swapAmount, _to);
    }

    /**
     * @dev Add liquidity for swaps.
     * @param _dstChainId ID of destination chain.
     * @param _dstToken Address of token on the destination chain.
     * @param _amount Amount of tokens to add as liquidity.
     */
    function addLiquidity(uint16 _dstChainId, address _dstToken, uint256 _amount) public payable {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        require(cp.ready == true, "Altitude: chainPath is not active");
        // LOCAL: deposit tokens, mint LP tokens
        // REMOTE: add liquidity for chain path
        IERC20(cp.srcToken).transferFrom(msg.sender, address(this), _amount);
        cp.lpToken.mint(msg.sender, _amount);
        cp.localLiquidity += _amount;

        bytes memory payload = abi.encode(TYPE_ADD_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount);
        bytes memory adapterParams = getAndCheckGasFee(TYPE_ADD_LIQUIDITY, _dstChainId, payload);
        layerZeroEndpoint.send{value: msg.value}(_dstChainId, bridgeLookup[_dstChainId], payload, payable(msg.sender), address(this), adapterParams);

        emit AddLiquidity(_dstChainId, _dstToken, _amount);
    }

    /**
     * @dev Remove local liquidity for swaps.
     * @param _dstChainId ID of destination chain.
     * @param _dstToken Address of token on the destination chain.
     * @param _amount Amount of tokens to remove from liquidity.
     */
    function removeLiquidityLocal(uint16 _dstChainId, address _dstToken, uint256 _amount) public payable {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        require(cp.localLiquidity >= _amount, "Altitude: not enough liquidity");
        // LOCAL: burn LP tokens, receive tokens
        // REMOTE: remove liquidity for chain path
        cp.lpToken.burn(msg.sender, _amount);
        cp.localLiquidity -= _amount;
        (, uint256 protocolFee) = getFees(_dstChainId, _dstToken, _amount);
        IERC20(cp.srcToken).transfer(msg.sender, _amount - protocolFee);
        IERC20(cp.srcToken).transfer(feeTo, protocolFee);
        
        bytes memory payload = abi.encode(TYPE_REMOVE_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount);
        bytes memory adapterParams = getAndCheckGasFee(TYPE_REMOVE_LIQUIDITY, _dstChainId, payload);
        layerZeroEndpoint.send{value: msg.value}(_dstChainId, bridgeLookup[_dstChainId], payload, payable(msg.sender), address(this), adapterParams);

        emit RemoveLiquidityLocal(_dstChainId, _dstToken, _amount);
    }

    /**
     * @dev Remove remote liquidity for swaps.
     * @param _dstChainId ID of destination chain.
     * @param _dstToken Address of token on the destination chain (in).
     * @param _amount Amount of tokens to remove from liquidity.
     */
    function removeLiquidityRemote(uint16 _dstChainId, address _dstToken, uint256 _amount, bytes memory _to) public payable {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstToken);
        require(cp.remoteLiquidity >= _amount, "Altitude: not enough liquidity");
        // LOCAL: burn LP tokens, remove liquidity for chain path
        // REMOTE: receive tokens
        cp.lpToken.burn(msg.sender, _amount);
        cp.remoteLiquidity -= _amount;

        bytes memory payload = abi.encode(TYPE_REDEEM_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount, _to);
        bytes memory adapterParams = getAndCheckGasFee(TYPE_REDEEM_LIQUIDITY, _dstChainId, payload);
        layerZeroEndpoint.send{value: msg.value}(_dstChainId, bridgeLookup[_dstChainId], payload, payable(msg.sender), address(this), adapterParams);

        emit RemoveLiquidityRemote(_dstChainId, _dstToken, _amount, _to);
    }

/******************************************/
/*           REMOTE starts here           */
/******************************************/

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 /*_nonce*/, bytes memory _payload) external override {
        require(msg.sender == address(layerZeroEndpoint));
        require(
            _srcAddress.length == bridgeLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(bridgeLookup[_srcChainId]),
            "Invalid source sender address. owner should call setTrustedSource() to enable source contract"
        );

        uint8 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }

        // SWAP 
        if (functionType == TYPE_SWAP_REMOTE) {
            (, bytes memory token, uint256 amount, bytes memory to) = abi.decode(_payload, (uint8, bytes, uint256, bytes));
            uint256 rebalanceReward;
            address toAddress;
            address srcTokenAddress;
            assembly {
                toAddress := mload(add(to, 20))
                srcTokenAddress := mload(add(token, 20))
            }
            ChainPath storage cp = getAndCheckCP(_srcChainId, srcTokenAddress);
            cp.remoteLiquidity += amount;
            cp.localLiquidity -= amount;
            rebalanceReward = getRebalanceReward(_srcChainId, srcTokenAddress, amount);
            cp.rewardPoolSize -= rebalanceReward;
            IERC20(cp.srcToken).transfer(toAddress, amount + rebalanceReward);

            emit Remote_Swap(_srcChainId, srcTokenAddress, amount, toAddress);

        // ADD_LIQUIDITY      
        } else if (functionType == TYPE_ADD_LIQUIDITY) {
            (, bytes memory token, uint256 amount) = abi.decode(_payload, (uint8, bytes, uint256));
            address srcTokenAddress;
            assembly {
                srcTokenAddress := mload(add(token, 20))
            }
            ChainPath storage cp = getAndCheckCP(_srcChainId, srcTokenAddress);
            cp.remoteLiquidity += amount;

            emit Remote_AddLiquidity(_srcChainId, srcTokenAddress, amount);

        // REMOVE_LIQUIDITY     
        } else if (functionType == TYPE_REMOVE_LIQUIDITY) {
            (, bytes memory token, uint256 amount) = abi.decode(_payload, (uint8, bytes, uint256));
            address srcTokenAddress;
            assembly {
                srcTokenAddress := mload(add(token, 20))
            }
            ChainPath storage cp = getAndCheckCP(_srcChainId, srcTokenAddress);
            cp.remoteLiquidity -= amount;

            emit Remote_RemoveLiquidityLocal(_srcChainId, srcTokenAddress, amount);

        // REDEEM_LIQUIDITY 
        } else if (functionType == TYPE_REDEEM_LIQUIDITY) {
            (, bytes memory token, uint256 amount, bytes memory to) = abi.decode(_payload, (uint8, bytes, uint256, bytes));
            address toAddress;
            address srcTokenAddress;
            assembly {
                toAddress := mload(add(to, 20))
                srcTokenAddress := mload(add(token, 20))
            }
            ChainPath storage cp = getAndCheckCP(_srcChainId, srcTokenAddress);
            cp.localLiquidity -= amount;
            (, uint256 protocolFee) = getFees(_srcChainId, srcTokenAddress, amount);
            IERC20(cp.srcToken).transfer(toAddress, amount - protocolFee);
            IERC20(cp.srcToken).transfer(feeTo, protocolFee);

            emit Remote_RemoveLiquidityRemote(_srcChainId, srcTokenAddress, amount, toAddress);
        }
    }

/******************************************/
/*             FEE starts here            */
/******************************************/

    // LOCAL
    function getFees(uint16 _dstChainId, address _dstToken, uint256 _amount) public view returns (uint256 rebalanceFee, uint256 protocolFee) {
        ChainPath memory cp = getAndCheckCP(_dstChainId, _dstToken);
        uint256 totalBalance = cp.localLiquidity + cp.remoteLiquidity;
        uint256 idealBalance = totalBalance / 2;
        rebalanceFee = _getRebalanceFee(idealBalance, cp.remoteLiquidity, _amount);
        protocolFee = _amount * P / 1e18;
    }

    // REMOTE
    function getRebalanceReward(uint16 _srcChainId, address _srcToken, uint256 _amount) public view returns (uint256 rebalanceReward) {
        ChainPath memory cp = getAndCheckCP(_srcChainId, _srcToken);
        uint256 idealBalance = (cp.localLiquidity + cp.remoteLiquidity) / 2;
        if (cp.remoteLiquidity < idealBalance) {
            uint256 remoteLiquidityDeficit = idealBalance - cp.remoteLiquidity;
            rebalanceReward = cp.rewardPoolSize * _amount / remoteLiquidityDeficit;
            if (rebalanceReward > cp.rewardPoolSize) {
                rebalanceReward = cp.rewardPoolSize;
            }
        } 
    }

    function _getRebalanceFee(uint256 idealBalance, uint256 preBalance, uint256 amount) internal view returns (uint256 rebalanceFee) {
        require(preBalance >= amount, "Altitude: not enough balance");
        uint256 postBalance = preBalance - amount;
        uint256 safeZoneMax = idealBalance * D1 / 1e18;
        uint256 safeZoneMin = idealBalance * D2 / 1e18;
        rebalanceFee = 0;
        if (postBalance >= safeZoneMax) {
        } else if (postBalance >= safeZoneMin) {
            uint256 proxyPreBalance = preBalance < safeZoneMax ? preBalance : safeZoneMax;
            rebalanceFee = _getTrapezoidArea(L1, 0, safeZoneMax, safeZoneMin, proxyPreBalance, postBalance);
        } else {
            if (preBalance >= safeZoneMin) {
                uint256 proxyPreBalance = preBalance < safeZoneMax ? preBalance : safeZoneMax;
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L1, 0, safeZoneMax, safeZoneMin, proxyPreBalance, safeZoneMin);
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L2, L1, safeZoneMin, 0, safeZoneMin, postBalance);
            } else {
                rebalanceFee = rebalanceFee + _getTrapezoidArea(L2, L1, safeZoneMin, 0, preBalance, postBalance);
            }
        }
        return rebalanceFee;
    }

    function _getTrapezoidArea(uint256 lambda, uint256 yOffset, uint256 xUpperBound, uint256 xLowerBound, uint256 xStart, uint256 xEnd) internal pure returns (uint256) {
        require(xEnd >= xLowerBound && xStart <= xUpperBound, "Altitude: balance out of bound");
        uint256 xBoundWidth = xUpperBound - xLowerBound;
        uint256 yStart = (xUpperBound - xStart) * lambda / xBoundWidth + yOffset;
        uint256 yEnd = (xUpperBound - xEnd) * lambda / xBoundWidth + yOffset;
        uint256 deltaX = xStart - xEnd;
        return (yStart + yEnd) * deltaX / 2 / 1e18;
    }

/******************************************/
/*            VIEW starts here            */
/******************************************/

    function getAndCheckCP(uint16 _dstChainId, address _dstToken) internal view returns (ChainPath storage) {
        require(chainPaths.length > 0, "Altitude: no chainpaths exist");
        ChainPath storage cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstToken]];
        require(cp.dstChainId == _dstChainId && cp.dstToken == _dstToken, "Altitude: local chainPath does not exist");
        return cp;
    }

    function getChainPath(uint16 _dstChainId, address _dstToken) external view returns (ChainPath memory) {
        ChainPath memory cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstToken]];
        require(cp.dstChainId == _dstChainId && cp.dstToken == _dstToken, "Altitude: local chainPath does not exist");
        return cp;
    }

    function getAndCheckGasFee(uint8 _type, uint16 _dstChainId, bytes memory _payload) internal view returns (bytes memory adapterParams) {
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = gasLookup[_dstChainId][_type];
        adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        // get the fees we need to pay to LayerZero for message delivery
        (uint256 nativeFee, ) = layerZeroEndpoint.estimateFees(_dstChainId, address(this), _payload, false, adapterParams);
        require(msg.value >= nativeFee, "Altitude: insufficient msg.value to pay to LayerZero for message delivery.");
    }

    function getGasFee(uint8 _type, uint16 _dstChainId, address _dstToken, uint256 _amount, bytes memory _to) external view returns (uint256) {
        ChainPath memory cp = getAndCheckCP(_dstChainId, _dstToken);
        bytes memory payload;
        if(_type == 1) {
        payload = abi.encode(TYPE_SWAP_REMOTE, abi.encodePacked(cp.srcToken), _amount, _to);
        } else if (_type == 2) {
        payload = abi.encode(TYPE_ADD_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount);
        } else if (_type == 3) {
        payload = abi.encode(TYPE_REMOVE_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount);
        } else if (_type == 4) {
        payload = abi.encode(TYPE_REDEEM_LIQUIDITY, abi.encodePacked(cp.srcToken), _amount, _to);
        }
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = gasLookup[_dstChainId][_type];
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        // get the fees we need to pay to LayerZero for message delivery
        (uint256 nativeFee, ) = layerZeroEndpoint.estimateFees(_dstChainId, address(this), payload, false, adapterParams);
        return (nativeFee);
    }

    function getFeeParameters() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (P, D1, D2, L1, L2);
    }

/******************************************/
/*           CONFIG starts here           */
/******************************************/

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        layerZeroEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function getConfig(
        uint16, /*_dstChainId*/
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        return layerZeroEndpoint.getConfig(layerZeroEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    function getSendVersion() external view returns (uint16) {
        return layerZeroEndpoint.getSendVersion(address(this));
    }

    function getReceiveVersion() external view returns (uint16) {
        return layerZeroEndpoint.getReceiveVersion(address(this));
    }

    function setInboundConfirmations(uint16 sourceChainId, uint16 confirmations) external {
        layerZeroEndpoint.setConfig(
            layerZeroEndpoint.getSendVersion(address(this)),
            sourceChainId,
            2, // CONFIG_TYPE_INBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }

    function setOutboundConfirmations(uint16 sourceChainId, uint16 confirmations) external {
        layerZeroEndpoint.setConfig(
            layerZeroEndpoint.getSendVersion(address(this)),
            sourceChainId,
            5, // CONFIG_TYPE_OUTBOUND_BLOCK_CONFIRMATIONS
            abi.encode(confirmations)
        );
    }

    fallback() external payable {}
    receive() external payable {}
}