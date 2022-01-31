/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File @openzeppelin/contracts-0.8/utils/[email protected]

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;


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


// File @openzeppelin/contracts-0.8/access/[email protected]

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
    constructor () {
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


// File src/solc_0.8/common/BaseWithStorage/ERC20/extensions/ERC20Internal.sol




abstract contract ERC20Internal {
    function _approveFor(
        address owner,
        address target,
        uint256 amount
    ) internal virtual;

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual;
}


// File src/solc_0.8/common/BaseWithStorage/ERC20/extensions/ERC20ExecuteExtension.sol





abstract contract ERC20ExecuteExtension is ERC20Internal {
    /// @dev _executionAdmin != _admin so that this super power can be disabled independently
    address internal _executionAdmin;

    event ExecutionAdminAdminChanged(address oldAdmin, address newAdmin);

    /// @notice give the address responsible for adding execution rights.
    /// @return address of the execution administrator.
    function getExecutionAdmin() external view returns (address) {
        return _executionAdmin;
    }

    /// @notice change the execution adminstrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeExecutionAdmin(address newAdmin) external {
        require(msg.sender == _executionAdmin, "only executionAdmin can change executionAdmin");
        emit ExecutionAdminAdminChanged(_executionAdmin, newAdmin);
        _executionAdmin = newAdmin;
    }

    mapping(address => bool) internal _executionOperators;
    event ExecutionOperator(address executionOperator, bool enabled);

    /// @notice set `executionOperator` as executionOperator: `enabled`.
    /// @param executionOperator address that will be given/removed executionOperator right.
    /// @param enabled set whether the executionOperator is enabled or disabled.
    function setExecutionOperator(address executionOperator, bool enabled) external {
        require(msg.sender == _executionAdmin, "only execution admin is allowed to add execution operators");
        _executionOperators[executionOperator] = enabled;
        emit ExecutionOperator(executionOperator, enabled);
    }

    /// @notice check whether address `who` is given executionOperator rights.
    /// @param who The address to query.
    /// @return whether the address has executionOperator rights.
    function isExecutionOperator(address who) public view returns (bool) {
        return _executionOperators[who];
    }

    /// @notice execute on behalf of the contract.
    /// @param to destination address fo the call.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function executeWithSpecificGas(
        address to,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        // solhint-disable-next-line avoid-low-level-calls
        (success, returnData) = to.call{gas: gasLimit}(data);
        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930
    }

    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function approveAndExecuteWithSpecificGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        return _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);
    }

    /// @dev the reason for this function is that charging for gas here is more gas-efficient than doing it in the caller.
    /// @notice approve a specific amount of token for `from` and execute on behalf of the contract. Plus charge the gas required to perform it.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param tokenGasPrice price in token for the gas to be charged.
    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.
    /// @param tokenReceiver recipient address of the token charged for the gas used.
    /// @param data the bytes sent to the destination address.
    /// @return success whether the execution was successful.
    /// @return returnData data resulting from the execution.
    function approveAndExecuteWithSpecificGasAndChargeForIt(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData) {
        uint256 initialGas = gasleft();
        require(_executionOperators[msg.sender], "only execution operators allowed to execute on SAND behalf");
        (success, returnData) = _approveAndExecuteWithSpecificGas(from, to, amount, gasLimit, data);
        if (tokenGasPrice > 0) {
            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
    }

    /// @notice transfer 1amount1 token from `from` to `to` and charge the gas required to perform that transfer.
    /// @param from address of which token will be transfered.
    /// @param to destination address fo the call.
    /// @param amount number of tokens allowed that can be transfer by the code at `to`.
    /// @param gasLimit exact amount of gas to be passed to the call.
    /// @param tokenGasPrice price in token for the gas to be charged.
    /// @param baseGasCharge amount of gas charged on top of the gas used for the call.
    /// @param tokenReceiver recipient address of the token charged for the gas used.
    /// @return whether the transfer was successful.
    function transferAndChargeForGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver
    ) external returns (bool) {
        uint256 initialGas = gasleft();
        require(_executionOperators[msg.sender], "only execution operators allowed to perfrom transfer and charge");
        _transfer(from, to, amount);
        if (tokenGasPrice > 0) {
            _charge(from, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
        return true;
    }

    function _charge(
        address from,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 initialGas,
        uint256 baseGasCharge,
        address tokenReceiver
    ) internal {
        uint256 gasCharge = initialGas - gasleft();
        if (gasCharge > gasLimit) {
            gasCharge = gasLimit;
        }
        gasCharge += baseGasCharge;
        uint256 tokensToCharge = gasCharge * tokenGasPrice;
        require(tokensToCharge / gasCharge == tokenGasPrice, "overflow");
        _transfer(from, tokenReceiver, tokensToCharge);
    }

    function _approveAndExecuteWithSpecificGas(
        address from,
        address to,
        uint256 amount,
        uint256 gasLimit,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        if (amount > 0) {
            _addAllowanceIfNeeded(from, to, amount);
        }
        // solhint-disable-next-line avoid-low-level-calls
        (success, returnData) = to.call{gas: gasLimit}(data);
        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930
    }
}


// File src/solc_0.8/common/Libraries/BytesUtil.sol




library BytesUtil {
    /// @dev Check if the data == _address.
    /// @param data The bytes passed to the function.
    /// @param _address The address to compare to.
    /// @return Whether the first param == _address.
    function doFirstParamEqualsAddress(bytes memory data, address _address) internal pure returns (bool) {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(uint160(_address));
    }
}


// File src/solc_0.8/common/BaseWithStorage/ERC20/extensions/ERC20BasicApproveExtension.sol






abstract contract ERC20BasicApproveExtension is ERC20Internal {
    /// @notice Approve `target` to spend `amount` and call it with data.
    /// @param target The address to be given rights to transfer and destination of the call.
    /// @param amount The number of tokens allowed.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function approveAndCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, msg.sender), "FIRST_PARAM_NOT_SENDER");

        _approveFor(msg.sender, target, amount);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));
        return returnData;
    }

    /// @notice Temporarily approve `target` to spend `amount` and call it with data.
    /// Previous approvals remains unchanged.
    /// @param target The destination of the call, allowed to spend the amount specified
    /// @param amount The number of tokens allowed to spend.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function paidCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, msg.sender), "FIRST_PARAM_NOT_SENDER");

        if (amount > 0) {
            _addAllowanceIfNeeded(msg.sender, target, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));

        return returnData;
    }
}


// File src/solc_0.8/common/interfaces/IERC20.sol





/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}


// File src/solc_0.8/common/interfaces/IERC20Extended.sol





interface IERC20Extended is IERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}


// File src/solc_0.8/common/BaseWithStorage/WithAdmin.sol


// solhint-disable-next-line compiler-version


contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}


// File src/solc_0.8/common/BaseWithStorage/WithSuperOperators.sol


// solhint-disable-next-line compiler-version


contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}


// File src/solc_0.8/common/BaseWithStorage/ERC20/ERC20BaseToken.sol






abstract contract ERC20BaseToken is WithSuperOperators, IERC20, IERC20Extended, ERC20Internal {
    bytes32 internal immutable _name; // works only for string that can fit into 32 bytes
    bytes32 internal immutable _symbol; // works only for string that can fit into 32 bytes
    address internal immutable _operator;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address admin,
        address operator
    ) {
        require(bytes(tokenName).length > 0, "INVALID_NAME_REQUIRED");
        require(bytes(tokenName).length <= 32, "INVALID_NAME_TOO_LONG");
        _name = _firstBytes32(bytes(tokenName));
        require(bytes(tokenSymbol).length > 0, "INVALID_SYMBOL_REQUIRED");
        require(bytes(tokenSymbol).length <= 32, "INVALID_SYMBOL_TOO_LONG");
        _symbol = _firstBytes32(bytes(tokenSymbol));
        _admin = admin;
        _operator = operator;
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to The recipient address of the tokens being transfered.
    /// @param amount The number of tokens being transfered.
    /// @return success Whether or not the transfer succeeded.
    function transfer(address to, uint256 amount) external override returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from The origin address  of the tokens being transferred.
    /// @param to The recipient address of the tokensbeing  transfered.
    /// @param amount The number of tokens transfered.
    /// @return success Whether or not the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        if (msg.sender != from && !_superOperators[msg.sender] && msg.sender != _operator) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "NOT_AUTHORIZED_ALLOWANCE");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Burn `amount` tokens.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /// @notice Burn `amount` tokens from `owner`.
    /// @param from The address whose token to burn.
    /// @param amount The number of tokens to burn.
    function burnFor(address from, uint256 amount) external override {
        if (msg.sender != from && !_superOperators[msg.sender] && msg.sender != _operator) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            if (currentAllowance != ~uint256(0)) {
                require(currentAllowance >= amount, "NOT_AUTHORIZED_ALLOWANCE");
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }
        _burn(from, amount);
    }

    /// @notice Approve `spender` to transfer `amount` tokens.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approve(address spender, uint256 amount) external override returns (bool success) {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    /// @notice Get the name of the token collection.
    /// @return The name of the token collection.
    function name() external view virtual returns (string memory) {
        //added virtual
        return string(abi.encodePacked(_name));
    }

    /// @notice Get the symbol for the token collection.
    /// @return The symbol of the token collection.
    function symbol() external view virtual returns (string memory) {
        //added virtual
        return string(abi.encodePacked(_symbol));
    }

    /// @notice Get the total number of tokens in existence.
    /// @return The total number of tokens in existence.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[owner];
    }

    /// @notice Get the allowance of `spender` for `owner`'s tokens.
    /// @param owner The address whose token is allowed.
    /// @param spender The address allowed to transfer.
    /// @return remaining The amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external view override returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    /// @notice Get the number of decimals for the token collection.
    /// @return The number of decimals.
    function decimals() external pure virtual returns (uint8) {
        return uint8(18);
    }

    /// @notice Approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner The address whose token is allowed.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) public override returns (bool success) {
        require(msg.sender == owner || _superOperators[msg.sender] || msg.sender == _operator, "NOT_AUTHORIZED");
        _approveFor(owner, spender, amount);
        return true;
    }

    /// @notice Increase the allowance for the spender if needed
    /// @param owner The address of the owner of the tokens
    /// @param spender The address wanting to spend tokens
    /// @param amountNeeded The amount requested to spend
    /// @return success Whether or not the call succeeded.
    function addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) public returns (bool success) {
        require(msg.sender == owner || _superOperators[msg.sender] || msg.sender == _operator, "INVALID_SENDER");
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    /// @notice Get the first 32 bytes of input `src`.
    /// @param src The input data
    /// @return output The first 32 bytes of `src`.
    function _firstBytes32(bytes memory src) public pure returns (bytes32 output) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            output := mload(add(src, 32))
        }
    }

    /// @dev See addAllowanceIfNeeded.
    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded /*(ERC20Internal, ERC20ExecuteExtension, ERC20BasicApproveExtension)*/
    ) internal virtual override {
        if (amountNeeded > 0 && !isSuperOperator(spender) && spender != _operator) {
            uint256 currentAllowance = _allowances[owner][spender];
            if (currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    /// @dev See approveFor.
    function _approveFor(
        address owner,
        address spender,
        uint256 amount /*(ERC20BasicApproveExtension, ERC20Internal)*/
    ) internal virtual override {
        require(owner != address(0) && spender != address(0), "INVALID_OWNER_||_SPENDER");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev See transfer.
    function _transfer(
        address from,
        address to,
        uint256 amount /*(ERC20Internal, ERC20ExecuteExtension)*/
    ) internal virtual override {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Mint tokens for a recipient.
    /// @param to The recipient address.
    /// @param amount The number of token to mint.
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(amount > 0, "MINT_O_TOKENS");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "OVERFLOW");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Burn tokens from an address.
    /// @param from The address whose tokens to burn.
    /// @param amount The number of token to burn.
    function _burn(address from, uint256 amount) internal {
        require(amount > 0, "BURN_O_TOKENS");
        if (msg.sender != from && !_superOperators[msg.sender] && msg.sender != _operator) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                _allowances[from][msg.sender] = currentAllowance - amount;
            }
        }

        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}


// File src/solc_0.8/Sand/SandBaseToken.sol







contract SandBaseToken is ERC20BaseToken, ERC20ExecuteExtension, ERC20BasicApproveExtension {
    constructor(
        address sandAdmin,
        address executionAdmin,
        address beneficiary,
        uint256 amount
    ) ERC20BaseToken("SAND", "SAND", sandAdmin, executionAdmin) {
        _admin = sandAdmin;
        _executionAdmin = executionAdmin;
        if (beneficiary != address(0)) {
            uint256 initialSupply = amount * (1 ether);
            _mint(beneficiary, initialSupply);
        }
    }
}


// File src/solc_0.8/polygon/child/sand/PolygonSand.sol


// solhint-disable-next-line compiler-version



contract PolygonSand is SandBaseToken, Ownable {
    address public childChainManagerProxy;

    constructor(
        address _childChainManagerProxy,
        address sandAdmin,
        address executionAdmin
    ) SandBaseToken(sandAdmin, executionAdmin, address(0), 0) {
        require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = _childChainManagerProxy;
    }

    /// @notice update the ChildChainManager Proxy address
    /// @param newChildChainManagerProxy address of the new childChainManagerProxy
    function updateChildChainManager(address newChildChainManagerProxy) external onlyOwner {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = newChildChainManagerProxy;
    }

    /// @notice called when tokens are deposited on root chain
    /// @param user user address for whom deposit is being done
    /// @param depositData abi encoded amount
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == childChainManagerProxy, "You're not allowed to deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /// @notice called when user wants to withdraw tokens back to root chain
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param amount amount to withdraw
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}