// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFSetting.sol";
import "./IFDFERC20.sol";
import "./IRouter.sol";
import "./IPool.sol";

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function pairCodeHash() external pure returns (bytes32);
    function bytecodeHash() external view returns(bytes32);

    function poolsCount(address token0, address token1) external view returns (uint256 count);
    function getPools(
        address token0,
        address token1,
        uint256 startIndex,
        uint256 count
    ) external view returns (address[] memory pairPools);
}

contract FSetting is Ownable,IFSetting {

    address public marketReceiver = 0x06E8Df028fC8c26e3f7db492f9b8692E9DB53bB4;

    //ido usdt in
    address public usdtInAddr = 0x67aC00e936305f3ceCb3276D8dA66947752ceE05;
    //ido default addr
    address public defaultRefer = 0x1646d2F3096919400DFE7067EA62B3abC989D3e9;

    //fdf mint to this
    address public safeAdmin = defaultRefer;

    //nft mint to this
    address public mintOwner = defaultRefer;

    //v3
    address public bento = 0x0319000133d3AdA02600f0875d2cf03D442C3367;

    address public usdt;

    address public fnft;
    address public fdf;
    address public FDFStaking;
    address public FNFTPool;

    address private feeReceiver;
    address private ecoSystemAccount;

    address public routerAddr = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address public pairAddr;

    address[] private pools;

    address[] private path2;

    // fee compound
    mapping(address => bool) public isExcluded;

    // tax fee
    mapping(address => bool) public isTaxExcluded;

    constructor() {
        isTaxExcluded[msg.sender] = true;
        isTaxExcluded[address(this)] = true;
        isExcluded[address(this)] = true;

        if (safeAdmin != address(0)) {
            isTaxExcluded[safeAdmin] = true;
        }
        if (usdtInAddr != address(0)) {
            isTaxExcluded[usdtInAddr] = true;
        }
        if (defaultRefer != address(0)) {
            isTaxExcluded[defaultRefer] = true;
        }
        if (mintOwner != address(0)) {
            isTaxExcluded[mintOwner] = true;
        }
        if (marketReceiver != address(0)) {
            isTaxExcluded[marketReceiver] = true;
        }
        calculatePair();
    }

    function setInit(uint256 index,address addr) external {
        require(addr != address(0),"addr is zero");
        if(index == 4) {
            if(fnft == address(0)){
                fnft = addr;
            }
            return;
        }
        if (index == 5) {
            if (fdf == address(0)) {
                fdf = addr;
                calculatePair();
            }
            return;
        }
        if (index == 6) {
            if (FDFStaking == address(0)) {
                FDFStaking = addr;
                isTaxExcluded[addr] = true;
                isExcluded[addr] = true;
            }
            return;
        }
        if (index == 7) {
            if(FNFTPool == address(0)) {
                FNFTPool = addr;
                isTaxExcluded[addr] = true;
                isExcluded[addr] = true;
            }
            return;
        }
        if (index == 8) {
            if(feeReceiver == address(0)) {
                feeReceiver = addr;
                isTaxExcluded[addr] = true;
                isExcluded[addr] = true;
            }
            return;
        }
        if (index == 9) {
            if(ecoSystemAccount == address(0)) {
                ecoSystemAccount = addr;
                isTaxExcluded[addr] = true;
                isExcluded[addr] = true;
            }
            return;
        }
    }

    function setDefaultRefer(address default_) external onlyOwner {
        require(default_ != address(0),"default is zero");
        defaultRefer = default_;
        isTaxExcluded[default_] = true;
    }

    function setFeeReceiver(address _fee) external onlyOwner {
        require(_fee != address(0),"_fee is zero");
        if (feeReceiver != address(0)) {
            isTaxExcluded[feeReceiver] = false;
        }
        feeReceiver = _fee;
        isTaxExcluded[_fee] = true;
        isExcluded[_fee] = true;
    }

    function setEcoSystemAccount(address _eco) external onlyOwner {
        require(_eco != address(0),"_eco is zero");
        if (ecoSystemAccount != address(0)) {
            isTaxExcluded[ecoSystemAccount] = false;
        }
        ecoSystemAccount = _eco;
        isTaxExcluded[_eco] = true;
        isExcluded[_eco] = true;
    }

    function setSafeAdmin(address _safeAdmin) external onlyOwner {
        require(_safeAdmin != address(0),"_safeAdmin is zero");
        if (safeAdmin != address(0)) {
            isTaxExcluded[safeAdmin] = false;
        }
        safeAdmin = _safeAdmin;
        isTaxExcluded[_safeAdmin] = true;
    }

    function setMintOwner(address _mintOwner) external onlyOwner {
        require(_mintOwner != address(0),"_safeAdmin is zero");
        if (mintOwner != address(0)) {
            isTaxExcluded[mintOwner] = false;
        }
        mintOwner = _mintOwner;
        isTaxExcluded[_mintOwner] = true;
    }

    function setRouter(address _router) external onlyOwner {
        routerAddr = _router;
        calculatePair();
    }
    function setUSDT(address _usdt) external onlyOwner {
        require(_usdt != address(0),"usdt is zero");
        usdt = _usdt;
        calculatePair();
    }

    //setting tax
    function setTaxExcluded(address tax_, bool is_) external onlyOwner {
        isTaxExcluded[tax_] = is_;
    }

    //setting fee
    function setExcluded(address ex_, bool is_) external onlyOwner {
        isExcluded[ex_] = is_;
    }

    function setFNFT(address _nft) external onlyOwner {
        require(_nft != address(0),"_nft is zero");
        fnft = _nft;
    }

    function setFDF(address _fdf) external onlyOwner {
        require(_fdf != address(0),"_fdf is zero");
        fdf = _fdf;
        calculatePair();
    }

    function setFDFStaking(address _staking) external onlyOwner {
        require(_staking != address(0),"_staking is zero");
        FDFStaking = _staking;
        isTaxExcluded[_staking] = true;
        isExcluded[_staking] = true;
    }

    function setFNFTPool(address _nftPool) external onlyOwner {
        require(_nftPool != address(0),"_nftPool is zero");
        FNFTPool = _nftPool;
    }

    function getFeeReceiver() external view returns(address){
        return feeReceiver;
    }

    function getEcoSystemAccount() external view returns(address) {
        return ecoSystemAccount;
    }

    function calculatePair() private {
        if(routerAddr == address(0) ||
            usdt == address(0) ||
            fdf == address(0)) {
            return;
        }

        (address token0, address token1) = usdt < fdf ? (usdt, fdf) : (fdf, usdt);
        address factory = IRouter(routerAddr).factory();
        bytes32 pairCodeHASH = IFactory(factory).pairCodeHash();
        pairAddr = address(uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        pairCodeHASH// init code hash
                    )
                )
            ))
        );
        if (path2.length >0) {
            delete path2;
        }
        path2.push(fdf);
        path2.push(usdt);
    }

    function FDFToUSDTAmount(uint256 _amount) external view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = fdf;
        path[1] = usdt;
        return IRouter(routerAddr).getAmountsOut(_amount,path)[1];
    }

    function USDTToFDFAmount(uint256 _amount) external view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = fdf;
        return IRouter(routerAddr).getAmountsOut(_amount,path)[1];
    }

    function getPath2() external view returns(address[] memory) {
        return path2;
    }

    function getLPPool() external view returns(address) {
        if (pools.length >0) {
            return pools[0];
        }
        return address(0);
    }
    
    function getPools() external view returns(address[] memory) {
        return pools;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function updatePools() external onlyOwner {
        address[] memory mem;
        pools = mem;
        calculatePair();
    }
    function setPools(uint256 index,address _pool) external onlyOwner {
        if (pools.length >0) {
            pools[index] = _pool;
        }else{
            pools.push(_pool);
        }
    }
    function setBento(address _bento) external onlyOwner {
        bento = _bento;
    }
    function setPairAddr(address _pair) external onlyOwner {
        pairAddr = _pair;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFDFERC20 is IERC20{
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFSetting {
    function setInit(uint256 index,address addr) external;
    function usdt() external view returns(address);
    function fnft() external view returns(address);
    function fdf() external view returns(address);
    function pairAddr() external view returns(address);
    function bento() external view returns(address);
    function getLPPool() external view returns(address);
    function getPath2() external view returns(address[] memory);
    function routerAddr() external view returns(address);
    function FDFStaking() external view returns(address);
    function FNFTPool() external view returns(address);
    function mintOwner() external view returns(address);
    function safeAdmin() external view returns(address);
    function defaultRefer() external view returns(address);
    function usdtInAddr() external view returns(address);
    function marketReceiver() external view returns(address);
    function isExcluded(address ex_) external view returns(bool);
    function isTaxExcluded(address tax_) external view returns(bool);
    function getFeeReceiver() external view returns(address);
    function getEcoSystemAccount() external view returns(address);
    function USDTToFDFAmount(uint256 _amount) external view returns(uint256);
    function FDFToUSDTAmount(uint256 _amount) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}