/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

pragma solidity ^0.8.2;
 
 
interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface Structs {
	struct Provider {uint16 chainId;uint16 governanceChainId;bytes32 governanceContract;}
	struct GuardianSet {address[] keys;uint32 expirationTime;}
	struct Signature {bytes32 r; bytes32 s; uint8 v; uint8 guardianIndex;}
	struct VM {uint8 version;uint32 timestamp;uint32 nonce;uint16 emitterChainId;bytes32 emitterAddress;uint64 sequence;
                uint8 consistencyLevel; bytes payload; uint32 guardianSetIndex; Signature[] signatures; bytes32 hash;}
}

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);
    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);
    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);
    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;
    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);
    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;
    function getCurrentGuardianSetIndex() external view returns (uint32) ;
    function getGuardianSetExpiry() external view returns (uint32) ;
    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;
    function isInitialized(address impl) external view returns (bool) ;
    function chainId() external view returns (uint16) ;
    function governanceChainId() external view returns (uint16);
    function governanceContract() external view returns (bytes32);
    function messageFee() external view returns (uint256) ;
}

contract BridgeStorage {
    struct Provider {uint16 chainId; uint16 governanceChainId; bytes32 governanceContract; address WETH;}
    struct Asset {uint16 chainId; bytes32 assetAddress;}
    struct State {address payable wormhole; address tokenImplementation; Provider provider;
                  mapping(bytes32 => bool) consumedGovernanceActions;
                  mapping(bytes32 => bool) completedTransfers;
                  mapping(address => bool) initializedImplementations;
                  mapping(uint16 => mapping(bytes32 => address)) wrappedAssets;
                  mapping(address => bool) isWrappedAsset;
                  mapping(address => uint256) outstandingBridged;
                  mapping(uint16 => bytes32) bridgeImplementations;}
}

contract BridgeState is BridgeStorage{
    BridgeStorage.State _state;
}

contract BridgeGetters is BridgeState {
    function governanceActionIsConsumed(bytes32 hash) public view returns (bool) {
        return _state.consumedGovernanceActions[hash];
    }

    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    function isTransferCompleted(bytes32 hash) public view returns (bool) {
        return _state.completedTransfers[hash];
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    function chainId() public view returns (uint16){
        return _state.provider.chainId;
    }

    function governanceChainId() public view returns (uint16){
        return _state.provider.governanceChainId;
    }

    function governanceContract() public view returns (bytes32){
        return _state.provider.governanceContract;
    }

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) public view returns (address){
        return _state.wrappedAssets[tokenChainId][tokenAddress];
    }

    function bridgeContracts(uint16 chainId_) public view returns (bytes32){
        return _state.bridgeImplementations[chainId_];
    }

    function tokenImplementation() public view returns (address){
        return _state.tokenImplementation;
    }

    function WETH() public view returns (IWETH){
        return IWETH(_state.provider.WETH);
    }

    function outstandingBridged(address token) public view returns (uint256){
        return _state.outstandingBridged[token];
    }

    function isWrappedAsset(address token) public view returns (bool){
        return _state.isWrappedAsset[token];
    }
}

interface IERC20 {
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

contract BridgeSetters is BridgeState {
    function setInitialized(address implementatiom) internal {
        _state.initializedImplementations[implementatiom] = true;
    }

    function setGovernanceActionConsumed(bytes32 hash) internal {
        _state.consumedGovernanceActions[hash] = true;
    }

    function setTransferCompleted(bytes32 hash) internal {
        _state.completedTransfers[hash] = true;
    }

    function setChainId(uint16 chainId) internal {
        _state.provider.chainId = chainId;
    }

    function setGovernanceChainId(uint16 chainId) internal {
        _state.provider.governanceChainId = chainId;
    }

    function setGovernanceContract(bytes32 governanceContract) internal {
        _state.provider.governanceContract = governanceContract;
    }

    function setBridgeImplementation(uint16 chainId, bytes32 bridgeContract) internal {
        _state.bridgeImplementations[chainId] = bridgeContract;
    }

    function setTokenImplementation(address impl) internal {
        _state.tokenImplementation = impl;
    }

    function setWETH(address weth) internal {
        _state.provider.WETH = weth;
    }

    function setWormhole(address wh) internal {
        _state.wormhole = payable(wh);
    }

    function setWrappedAsset(uint16 tokenChainId, bytes32 tokenAddress, address wrapper) internal {
        _state.wrappedAssets[tokenChainId][tokenAddress] = wrapper;
        _state.isWrappedAsset[wrapper] = true;
    }

    function setOutstandingBridged(address token, uint256 outstanding) internal {
        _state.outstandingBridged[token] = outstanding;
    }
}

contract BridgeStructs {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        bytes32 newContract;
    }
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TokenStorage {
    struct State {
        string name;
        string symbol;

        uint64 metaLastUpdatedSequence;

        uint256 totalSupply;
        uint8 decimals;

        mapping(address => uint256) balances;

        mapping(address => mapping(address => uint256)) allowances;

        address owner;

        bool initialized;

        uint16 chainId;
        bytes32 nativeContract;
    }
}

contract TokenState {
    TokenStorage.State _state;
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

contract TokenImplementation is TokenState, Context {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint64 sequence_,

        address owner_,

        uint16 chainId_,
        bytes32 nativeContract_
    ) initializer public {
        _state.name = name_;
        _state.symbol = symbol_;
        _state.decimals = decimals_;
        _state.metaLastUpdatedSequence = sequence_;

        _state.owner = owner_;

        _state.chainId = chainId_;
        _state.nativeContract = nativeContract_;
    }

    function name() public view returns (string memory) {
        return string(abi.encodePacked(_state.name, " (Wormhole)"));
    }

    function symbol() public view returns (string memory) {
        return _state.symbol;
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function decimals() public view returns (uint8) {
        return _state.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _state.totalSupply;
    }

    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    function nativeContract() public view returns (bytes32) {
        return _state.nativeContract;
    }

    function balanceOf(address account_) public view returns (uint256) {
        return _state.balances[account_];
    }

    function transfer(address recipient_, uint256 amount_) public returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _state.allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 currentAllowance = _state.allowances[sender_][_msgSender()];
        require(currentAllowance >= amount_, "ERC20: transfer amount exceeds allowance");
        _approve(sender_, _msgSender(), currentAllowance - amount_);

        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(_msgSender(), spender_, _state.allowances[_msgSender()][spender_] + addedValue_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        uint256 currentAllowance = _state.allowances[_msgSender()][spender_];
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender_, currentAllowance - subtractedValue_);

        return true;
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _state.balances[sender_];
        require(senderBalance >= amount_, "ERC20: transfer amount exceeds balance");
        _state.balances[sender_] = senderBalance - amount_;
        _state.balances[recipient_] += amount_;

        emit Transfer(sender_, recipient_, amount_);
    }

    function mint(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }

    function _mint(address account_, uint256 amount_) internal {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _state.totalSupply += amount_;
        _state.balances[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    function burn(address account_, uint256 amount_) public onlyOwner {
        _burn(account_, amount_);
    }

    function _burn(address account_, uint256 amount_) internal {
        require(account_ != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _state.balances[account_];
        require(accountBalance >= amount_, "ERC20: burn amount exceeds balance");
        _state.balances[account_] = accountBalance - amount_;
        _state.totalSupply -= amount_;

        emit Transfer(account_, address(0), amount_);
    }

    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _state.allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function updateDetails(string memory name_, string memory symbol_, uint64 sequence_) public onlyOwner {
        require(_state.metaLastUpdatedSequence < sequence_, "current metadata is up to date");

        _state.name = name_;
        _state.symbol = symbol_;
        _state.metaLastUpdatedSequence = sequence_;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller is not the owner");
        _;
    }

    modifier initializer() {
        require(
            !_state.initialized,
            "Already initialized"
        );

        _state.initialized = true;

        _;
    }
}

contract Bridge is ReentrancyGuard, BridgeGetters, BridgeSetters, BridgeStructs{
    function bridgeOut(address token, uint normalizedAmount) internal {
        uint outstanding = outstandingBridged(token);
        require(outstanding + normalizedAmount <= type(uint64).max, "transfer exceeds max outstanding bridged token amount");
        setOutstandingBridged(token, outstanding + normalizedAmount);
    }
 
    function logTransfer(uint16 tokenChain, bytes32 tokenAddress, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 fee, uint256 callValue, uint32 nonce) internal returns (uint64 sequence) {
        require(fee <= amount, "fee exceeds amount");
 
        BridgeStructs.Transfer memory transfer = BridgeStructs.Transfer({
            payloadID : 1,
            amount : amount,
            tokenAddress : tokenAddress,
            tokenChain : tokenChain,
            to : recipient,
            toChain : recipientChain,
            fee : fee
        });
 
        bytes memory encoded = encodeTransfer(transfer);
 
        sequence = wormhole().publishMessage{
            value : callValue
        }(nonce, encoded, 15);
    }
 
    function encodeTransfer(BridgeStructs.Transfer memory transfer) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            transfer.payloadID,
            transfer.amount,
            transfer.tokenAddress,
            transfer.tokenChain,
            transfer.to,
            transfer.toChain,
            transfer.fee
        );
    }


 
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public payable /*nonReentrant*/ returns (uint64 sequence) {
        // determine token parameters
        uint16 tokenChain;
        bytes32 tokenAddress;
        if (isWrappedAsset(token)) {
            tokenChain = TokenImplementation(token).chainId();
            tokenAddress = TokenImplementation(token).nativeContract();
        } else {
            tokenChain = chainId();
            tokenAddress = bytes32(uint256(uint160(token)));
        }
 
        // query tokens decimals
        (,bytes memory queriedDecimals) = token.staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));
 
        // don't deposit dust that can not be bridged due to the decimal shift
        amount = deNormalizeAmount(normalizeAmount(amount, decimals), decimals);
 
        if (tokenChain == chainId()) {
            // query own token balance before transfer
            (,bytes memory queriedBalanceBefore) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));
 
            // transfer tokens
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
 
            // query own token balance after transfer
            (,bytes memory queriedBalanceAfter) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));
 
            // correct amount for potential transfer fees
            amount = balanceAfter - balanceBefore;
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
 
            TokenImplementation(token).burn(address(this), amount);
        }
 
        // normalize amounts decimals
        uint256 normalizedAmount = normalizeAmount(amount, decimals);
        uint256 normalizedArbiterFee = normalizeAmount(arbiterFee, decimals);
 
        // track and check outstanding token amounts
        if (tokenChain == chainId()) {
            bridgeOut(token, normalizedAmount);
        }
 
        sequence = logTransfer(tokenChain, tokenAddress, normalizedAmount, recipientChain, recipient, normalizedArbiterFee, msg.value, nonce);
    }
 
    function normalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }
 
    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }
}
 
 
 
 
contract MyDefi is Bridge{
 
    IUniswap uniswap;
 
    constructor(address _uniswap) public {
        uniswap = IUniswap(_uniswap);
    }
 
    function tastSwapExactETHForTokens(
        uint amountOut,
        address token,
        uint deadline,
        address swappedTokenAddress,
        uint16 recipientChain, 
        bytes32 recipient, 
        uint256 arbiterFee, 
        uint32 nonce
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
        transferTokens(swappedTokenAddress, amountOut, recipientChain, recipient, arbiterFee, nonce);

    }
 
 
    
 
}