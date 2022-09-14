pragma solidity 0.7.6;
pragma abicoder v2;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint a, uint b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        return a / b;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}


contract ConverterV3 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable platformToken;

    address public immutable WNATIVE;

    address[] public receivers;

    uint256[] public feeShare;

    address public router;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountPT
    );

    event ReceiverChanged(
        address newReceiver,
        address oldReceiver,
        uint256 indexed index
    );

    event FeeShareChanged(
        uint256[] oldFeeShare,
        uint256[] newFeeShare
    );

    constructor(
        address _platformToken,
        address _WNATIVE,
        address _router,
        address[] memory _receivers,
        uint256[] memory _feeShare
    ) public {
        platformToken = _platformToken;
        WNATIVE = _WNATIVE;
        router = _router;

        require(_receivers.length == _feeShare.length, "Invalid data");
        receivers = _receivers;

        uint256 totalFee = 0;

        for (uint256 i = 0; i < _feeShare.length; i++) {
            totalFee = totalFee + _feeShare[i];
        }

        require(totalFee == 10000, "Invalid fee params");

        feeShare = _feeShare;
    }

    function changeRouter(address _router) external onlyOwner {
        require(_router != address(0), "Invalid router");
        router = _router;
    }
    
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = WNATIVE;
        }
    }

    
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != platformToken && token != WNATIVE && token != bridge,
            "QuickConverter: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    function changeReceiver(address _receiver, uint256 index) external onlyOwner {
        require(_receiver != address(0), "Inavlid receiver");
        address oldReceiver = receivers[index];
        receivers[index] = _receiver;

        emit ReceiverChanged(
            _receiver,
            oldReceiver,
            index
        );
    }

    function changeFeeShareConfig(uint256[] memory _feeShare) external onlyOwner {
        require(receivers.length == _feeShare.length, "Invalid data");

        uint256 totalFee = 0;

        for (uint256 i = 0; i < _feeShare.length; i++) {
            totalFee = totalFee + _feeShare[i];
        }

        require(totalFee == 10000, "Invalid fee params");

        emit FeeShareChanged(
            feeShare,
            _feeShare
        );

        feeShare = _feeShare;

    }

    
    // It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "QuickConverter: must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of QUICK to the dragonLair, run convert, then remove the QUICK again.
    //     As the size of the DragonLair has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token) external onlyEOA() {
        _convert(token);
        distribute();
    }


    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata tokens
    ) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(tokens[i]);
        }

        distribute();
    }

    function _convert(address token) internal {
        
        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount > 0) {
            _convertStep(token, amount);
        }    
        
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All _swap, _toPlatformToken, _convertStep: X1 - X5: OK
    function _convertStep(
        address token,
        uint256 amount
    ) internal returns (uint256 platformTokenOut) {
        // Interactions
        if (token == platformToken) {
            // eg. QUICK - ETH
            platformTokenOut = amount;
        } else if (token == WNATIVE) {
            // eg. ETH - USDC
            platformTokenOut = _toPlatformToken(
                WNATIVE,
                amount
            );
        } else {
            // eg. MIC - USDT
            address bridge = bridgeFor(token);
            platformTokenOut = _convertStep(
                bridge,
                _swap(token, bridge, amount, address(this))
            );
            
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            recipient: to,
            deadline: block.timestamp + 100,
            amountIn: amountIn,
            amountOutMinimum: 1,
            limitSqrtPrice: 0
        });

        amountOut = ISwapRouter(router).exactInputSingle(params);
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toPlatformToken(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        // X1 - X5: OK
        amountOut = _swap(token, platformToken, amountIn, address(this));
    }

    function distribute() public {
        uint256 amountPT = IERC20(platformToken).balanceOf(address(this));

        for (uint256 i = 0; i < receivers.length; i++) {
            address receiverAddress = receivers[i];
            uint256 receiverShare = feeShare[i];

            uint256 amount = amountPT.mul(receiverShare).div(10000);

            if (i == receivers.length - 1) {
                amount = IERC20(platformToken).balanceOf(address(this));
            }

            IERC20(platformToken).safeTransfer(receiverAddress, amount);

        }
    }
}