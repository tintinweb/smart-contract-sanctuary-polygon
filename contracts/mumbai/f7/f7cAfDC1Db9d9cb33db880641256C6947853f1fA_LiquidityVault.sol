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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function addAddressToTrustedSources(address _address, string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

	//Router02

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Vault.sol";
import "../interfaces/IERC20Extended.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";

contract LiquidityVault is Vault {
    //Storage Variables
    uint256 public liquidityShare = 60_000_000 ether; //Includes CEX and DEX
    uint256 public tokenAmountForInitialLiquidityOnDEX = 100_000 ether; //TODO: confirm amount //Just for setting price, will be added more later
    uint256 public amountUsedForLiquidityOnDEX;
    uint256 public marketMakerShare = 57_000_000 ether;
    uint256 public initialPriceForDEX;
    uint256 public balanceAddedLiquidityOnDex;
    uint256 public remainingTokensUnlockTime;
    uint256 public marketMakerShareWithdrawDeadline;
    uint256 public marketMakerShareWithdrawnAmount;

    address public DEXPairAddress;
    address stableTokenAddress;
    address factoryAddress;
    address routerAddress;

    //Custom Errors
    error StableBalanceIsNotEnoughOnLiquidityVault();
    error InsufficientTokenBalanceInLiquidityVault();
    error Use_withdrawRemainingTokens_function();
    error ReceiversAndAmountsMustBeSameLength();
    error RemainingTokensAreStillLocked();
    error AmountExceedsTheLimits();
    error NotEnoughSOULSToken();
    error IdenticalAddresses();
    error InvalidAmount();
    error LateRequest();
    error ZeroAddress();

    //Events
    event InitialLiquidityAdded(
        address soulsTokenAddress,
        address stableTokenAddress,
        uint256 tokenAmountForInitialLiquidityOnDEX,
        uint256 stableAmountForLiquidty
    );
    event AddLiquidityOnDEX(
        address soulsTokenAddress,
        address stableTokenAddress,
        uint256 tokenAmountToAdd,
        uint256 stableAmountToAdd,
        bool isApproved
    );
    event WithdrawMarketMakerShare(address receiver, uint256 amount, bool isApproved);
    event WithdrawRemainingTokens(address[] receivers, uint256[] amounts, bool isApproved);

    constructor(
        address _mainVaultAddress,
        address _soulsTokenAddress,
        address _managersAddress,
        address _dexRouterAddress,
        address _dexFactoryAddress,
        address _stableTokenAddress
    ) Vault("Liquidity Vault", _mainVaultAddress, _soulsTokenAddress, _managersAddress) {
        routerAddress = _dexRouterAddress;
        factoryAddress = _dexFactoryAddress;
        stableTokenAddress = _stableTokenAddress;
        initialPriceForDEX = (9 * (10 ** IERC20Extended(_stableTokenAddress).decimals())) / 1000;
        marketMakerShareWithdrawDeadline = block.timestamp + 5 days;
    }

    //Write Functions

    //Managers Function
    /** TEST INFO
	 **** Managers can add extra liquidity on DEX
	 * Öncelikle bot prevention üstünde enableTrading() fonksiyonu 3 yönetici olarak çağırılarak trade işlemleri başlatılmıştır.
	 * 10.000 souls token ile likidite eklemek için gerekli olan Stable token miktarı 
	 getRequiredStableAmountForLiquidity() fonksiyonu ile contracttan alınmıştır.
	 * Gerekli olan miktarda Stable token Main Vault contracta transfer edilmiştir.
	 * 3 yönetici tarafından fonksiyon çağırıldığında Main Vault contracttaki LP balansının arttığı gözlemlenmiştir.
	 */
    function addLiquidityOnDEX(uint256 _tokenAmountToAdd) external onlyManager {
        if (_tokenAmountToAdd == 0) {
            revert ZeroAmount();
        }

        if (_tokenAmountToAdd > IERC20(soulsTokenAddress).balanceOf(address(this))) {
            revert NotEnoughSOULSToken();
        }

        IPancakeRouter02 _router = IPancakeRouter02(routerAddress);
        uint256 _stableAmountToAdd = getRequiredStableAmountForLiquidity(_tokenAmountToAdd); // _router.quote(_tokenAmountToAdd, soulsReserve, stableReserve);
        IERC20 stableToken = IERC20(stableTokenAddress);

        if (_stableAmountToAdd > stableToken.balanceOf(address(this))) {
            revert StableBalanceIsNotEnoughOnLiquidityVault();
        }

        string memory _title = "Add Liquidity On DEX";
        bytes memory _encodedValues = abi.encode(_tokenAmountToAdd);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            balanceAddedLiquidityOnDex += _tokenAmountToAdd;
            if (tokenVestings[0].amount >= _tokenAmountToAdd) {
                tokenVestings[0].amount -= _tokenAmountToAdd;
            } else {
                tokenVestings[0].amount = 0;
            }
            _router.addLiquidity(
                soulsTokenAddress,
                stableTokenAddress,
                _tokenAmountToAdd,
                _stableAmountToAdd,
                0,
                0,
                mainVaultAddress,
                block.timestamp + 1 hours
            );
            if (stableToken.balanceOf(address(this)) > 0) {
                stableToken.transfer(msg.sender, stableToken.balanceOf(address(this)));
            }
            managers.deleteTopic(_title);
        }

        emit AddLiquidityOnDEX(soulsTokenAddress, stableTokenAddress, _tokenAmountToAdd, 0, _isApproved);
    }

    //Managers Function
    /** TEST INFO
	 **** Can be withdrwan by managers before deadline
	 * 3 manager hesap tarafından istenilen adrese transferin başarılı olduğu gözlemlenmiştir.
	
	**** Cannot withdraw after deadline
	* Blok zamanı deadline zamanına simüle edildikten sonra denendiğinde 'LateRequest()' hatasının döndüğü gözlemlenmiştir.
	 */
    function withdrawMarketMakerShare(address _receiver, uint256 _amount) external onlyManager {
        if (block.timestamp > marketMakerShareWithdrawDeadline) {
            revert LateRequest();
        }

        if (marketMakerShareWithdrawnAmount + _amount > marketMakerShare) {
            revert AmountExceedsTheLimits();
        }
        string memory _title = "Withdraw Market Maker Share";
        bytes memory _encodedValues = abi.encode(_receiver, _amount);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            marketMakerShareWithdrawnAmount += _amount;
            if (tokenVestings[0].amount >= _amount) {
                tokenVestings[0].amount -= _amount;
            } else {
                tokenVestings[0].amount = 0;
            }
            IERC20 soulsToken = IERC20(soulsTokenAddress);
            if (!soulsToken.transfer(_receiver, _amount)) {
                revert TransferError();
            }

            managers.deleteTopic(_title);
        }

        emit WithdrawMarketMakerShare(_receiver, _amount, _isApproved);
    }

    /** TEST INFO
	 **** Cannot init more than once
	 * Liquidity vault ikinci kez init edilmek istendiğinde 'AlreadyInitialized()' hatasının döndüğü gözlemlenmiştir.

	 **** Creates liquidity on DEX and transfers LP tokens to Main Vault contract
	 * Init işlemi sonrasında contract üzerinde DEXPairAddress değişkeninin değiştiği gözlemlenmiştir.
	 * Oluşturulan LP tokenların Main Vault contracta aktarıldığı gözlemlenmiştir.
	 * Oluşan loglar aşağıdaki gibidir.
		- Pair contract address:  0x60f7e83EaeCb2CE1849387d4014ECaeCCF0c77a4
		- LP token balance of Main Vault contract:  284604.9894151541398789

	 **** Contract token balance must increase with amount of locked tokens 
	 * Contract init edildikten sonra contract balansının (liquidiytShare - tokenAmountForInitialLiquidityOnDEX) miktarına eşit olduğu gözlemlenmiştir.
	 
	 **** Total of vestings must be equal to locked tokens
	 * Liquidity Vault'ta 57.000.000 token için kullanıma hazır durumda tek vesting olduğu gözlemlenmiştir.
	 */

    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _lockDurationInDays,
        uint256 _countOfVestings,
        uint256 _releaseFrequencyInDays
    ) public override onlyOnce onlyMainVault {
        if (_totalAmount != liquidityShare) {
            revert InvalidAmount();
        }
        super.createVestings(
            _totalAmount,
            _initialRelease,
            _initialReleaseDate,
            _lockDurationInDays,
            _countOfVestings,
            _releaseFrequencyInDays
        );
        IERC20Extended(soulsTokenAddress).transferFrom(msg.sender, address(this), liquidityShare);
        remainingTokensUnlockTime = _initialReleaseDate + 365 days;
        _createLiquidityOnDex();
    }

    /** TEST INFO
     * Fonksiyon çağırıldığında gerekli şekilde hata döndürdüğü gözlemlenmiştir.
     */
    function withdrawTokens(address[] calldata, uint256[] calldata) external view override onlyManager {
        revert Use_withdrawRemainingTokens_function();
    }

    /** TEST INFO
     **** Managers can withdraw tokens from liquidity vault using withdrawRemainingTokens after unlock time
     * Contract'ta kalan miktarın bir adrese transfer edilmesi denendiğinde 'RemainingTokensAreStillLocked()' hatasının döndüğü gözlemlenmiştir.
     * Blok zamanı kilit açılma süresine simüle edildikten sonra denendiğinde işlemin başarılı şekilde gerçekleştiği gözlemlenmiştir.
     */
    //Managers Function
    function withdrawRemainingTokens(address[] calldata _receivers, uint256[] calldata _amounts) external onlyManager {
        if (block.timestamp <= remainingTokensUnlockTime) {
            revert RemainingTokensAreStillLocked();
        }

        if (_receivers.length != _amounts.length) {
            revert ReceiversAndAmountsMustBeSameLength();
        }
        uint256 _totalAmount;
        for (uint i = 0; i < _amounts.length; i++) {
            _totalAmount += _amounts[i];
        }

        if (_totalAmount > IERC20(soulsTokenAddress).balanceOf(address(this))) {
            revert InsufficientTokenBalanceInLiquidityVault();
        }

        string memory _title = "Withdraw remaining tokens from Liquidity Vault";
        bytes memory _encodedValues = abi.encode(_receivers, _amounts);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            for (uint i = 0; i < _amounts.length; i++) {
                require(IERC20(soulsTokenAddress).transfer(_receivers[i], _amounts[i]));
            }
            managers.deleteTopic(_title);
        }
        emit WithdrawRemainingTokens(_receivers, _amounts, _isApproved);
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function _createLiquidityOnDex() private {
        uint256 _stableAmountForLiquidty = stableAmountForInitialLiquidity();
        balanceAddedLiquidityOnDex += tokenAmountForInitialLiquidityOnDEX;
        IERC20(soulsTokenAddress).approve(address(routerAddress), type(uint256).max);
        IERC20(stableTokenAddress).approve(address(routerAddress), type(uint256).max);
        IPancakeRouter02 _router = IPancakeRouter02(routerAddress);

        _router.addLiquidity(
            soulsTokenAddress,
            stableTokenAddress,
            tokenAmountForInitialLiquidityOnDEX,
            _stableAmountForLiquidty,
            tokenAmountForInitialLiquidityOnDEX,
            _stableAmountForLiquidty,
            mainVaultAddress,
            block.timestamp + 5 minutes
        );
        IPancakeFactory _factory = IPancakeFactory(factoryAddress);
        DEXPairAddress = _factory.getPair(soulsTokenAddress, stableTokenAddress);
        amountUsedForLiquidityOnDEX += tokenAmountForInitialLiquidityOnDEX;
        tokenVestings[0].amount -= tokenAmountForInitialLiquidityOnDEX;

        emit InitialLiquidityAdded(
            soulsTokenAddress,
            stableTokenAddress,
            tokenAmountForInitialLiquidityOnDEX,
            _stableAmountForLiquidty
        );
    }

    // Read Functions
    function stableAmountForInitialLiquidity() public view returns (uint256 _stableAmount) {
        _stableAmount = ((tokenAmountForInitialLiquidityOnDEX / 1 ether) * initialPriceForDEX);
    }

    function getSoulsBalance() public view returns (uint256 _soulsBalance) {
        _soulsBalance = IERC20(soulsTokenAddress).balanceOf(address(this));
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function getRequiredStableAmountForLiquidity(
        uint256 _tokenAmountToAdd
    ) public view returns (uint256 _stableAmountForLiquidty) {
        (uint256 stableReserve, uint256 soulsReserve) = _getReserves(stableTokenAddress, soulsTokenAddress);
        IPancakeRouter02 _router = IPancakeRouter02(routerAddress);
        _stableAmountForLiquidty = _router.quote(_tokenAmountToAdd, soulsReserve, stableReserve);
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        //require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) {
            revert ZeroAddress();
        }
    }

    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function _getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = _sortTokens(tokenA, tokenB);
        IPancakeFactory _factory = IPancakeFactory(factoryAddress);
        address _pairAddress = _factory.getPair(stableTokenAddress, soulsTokenAddress);
        IPancakePair pair = IPancakePair(_pairAddress);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IManagers.sol";


contract Vault {
    //Structs
    struct VestingInfo {
        uint256 amount;
        uint256 unlockTime;
        bool released;
    }

    //Storage Variables
    IManagers managers;
    address public soulsTokenAddress;
    address public mainVaultAddress;

    uint256 public currentVestingIndex;
    /**
	@dev must be assigned in constructor on of these: 
	"Marketing", "Advisor", "Airdrop", "Exchanges", "Treasury" or "Team"
	 */
    string public vaultName;

    VestingInfo[] public tokenVestings;

    //Custom Errors
    error OnlyOnceFunctionWasCalledBefore();
    error WaitForNextVestingReleaseDate();
    error NotAuthorized_ONLY_MAINVAULT();
    error NotAuthorized_ONLY_MANAGERS();
    error DifferentParametersLength();
    error InvalidFrequency();
    error NotEnoughAmount();
    error NoMoreVesting();
    error TransferError();
    error ZeroAmount();

    //Events
    event Withdraw(uint256 date, uint256 amount, bool isApproved);
    event ReleaseVesting(uint256 date, uint256 vestingIndex);

    constructor(
        string memory _vaultName,
        address _mainVaultAddress,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        vaultName = _vaultName;
        mainVaultAddress = _mainVaultAddress;
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
    }

	//Modifiers
    modifier onlyOnce() {
        if (tokenVestings.length > 0) {
            revert OnlyOnceFunctionWasCalledBefore();
        }
        _;
    }

    modifier onlyMainVault() {
        if (msg.sender != mainVaultAddress) {
            revert NotAuthorized_ONLY_MAINVAULT();
        }
        _;
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized_ONLY_MANAGERS();
        }
        _;
    }

    // Write Functions
    /** TEST INFO
	 (Calling by Main Vault)
	 **** Cannot init more than one for each vault
	 * Vault init edildikten sonra yeniden init edilmesi denendiğinde 'Already Inited' hatası döndüğü gözlemlenmiştir.

	 **** Total of vestings must be equal to locked tokens
	 Init işlemi sırasında contracta kilitlenen token miktarının vault share miktarına eşit olduğu gözlemlenmiştir.
┌─────────┬─────────────┬───────────────────┐
│ (index) │   amount    │    releaseDate    │
├─────────┼─────────────┼───────────────────┤
│    0    │ '6250000.0' │ 'Fri Feb 23 2024' │
│    1    │ '6250000.0' │ 'Sun Mar 24 2024' │
│    2    │ '6250000.0' │ 'Tue Apr 23 2024' │
│    3    │ '6250000.0' │ 'Thu May 23 2024' │
│    4    │ '6250000.0' │ 'Sat Jun 22 2024' │
│    5    │ '6250000.0' │ 'Mon Jul 22 2024' │
│    6    │ '6250000.0' │ 'Wed Aug 21 2024' │
│    7    │ '6250000.0' │ 'Fri Sep 20 2024' │
│    8    │ '6250000.0' │ 'Sun Oct 20 2024' │
│    9    │ '6250000.0' │ 'Tue Nov 19 2024' │
│   10    │ '6250000.0' │ 'Thu Dec 19 2024' │
│   11    │ '6250000.0' │ 'Sat Jan 18 2025' │
│   12    │ '6250000.0' │ 'Mon Feb 17 2025' │
│   13    │ '6250000.0' │ 'Wed Mar 19 2025' │
│   14    │ '6250000.0' │ 'Fri Apr 18 2025' │
│   15    │ '6250000.0' │ 'Sun May 18 2025' │
│   16    │ '6250000.0' │ 'Tue Jun 17 2025' │
│   17    │ '6250000.0' │ 'Thu Jul 17 2025' │
│   18    │ '6250000.0' │ 'Sat Aug 16 2025' │
│   19    │ '6250000.0' │ 'Mon Sep 15 2025' │
│   20    │ '6250000.0' │ 'Wed Oct 15 2025' │
│   21    │ '6250000.0' │ 'Fri Nov 14 2025' │
│   22    │ '6250000.0' │ 'Sun Dec 14 2025' │
│   23    │ '6250000.0' │ 'Tue Jan 13 2026' │
└─────────┴─────────────┴───────────────────┘
Vault share:  150000000.0
Total amount of vestings:  150000000.0


	 **** 
	 */
    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _countOfVestings,
        uint256 _vestingStartDate,
        uint256 _releaseFrequencyInDays
    ) public virtual onlyOnce onlyMainVault {
        if (_totalAmount == 0) {
            revert ZeroAmount();
        }

        if (_countOfVestings > 0 && _releaseFrequencyInDays == 0) {
            revert InvalidFrequency();
        }

        uint256 _amountUsed = 0;

        if (_initialRelease > 0) {
            tokenVestings.push(
                VestingInfo({amount: _initialRelease, unlockTime: _initialReleaseDate, released: false})
            );
            _amountUsed += _initialRelease;
        }
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;

        if (_countOfVestings > 0) {
            uint256 _vestingAmount = (_totalAmount - _initialRelease) / _countOfVestings;

            for (uint256 i = 0; i < _countOfVestings; i++) {
                if (i == _countOfVestings - 1) {
                    _vestingAmount = _totalAmount - _amountUsed; //use remaining dusts from division
                }
                tokenVestings.push(
                    VestingInfo({
                        amount: _vestingAmount,
                        unlockTime: _vestingStartDate + (i * releaseFrequency),
                        released: false
                    })
                );
                _amountUsed += _vestingAmount;
            }
        }
    }

    //Managers function
    /** TEST INFO
     * Internal fonksiyona gözat
     */
    function withdrawTokens(address[] calldata _receivers, uint256[] calldata _amounts) external virtual onlyManager {
        _withdrawTokens(_receivers, _amounts);
    }

    /** TEST INFO
	 **** Cannot withdraw before unlock time
	 * Init işleminden sonra token çekilmesi denendiğinde 'WaitForNextVestingReleaseDate()' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Relases next vesting automatically after unlockTime if released amount is not enough
	 * Blok zamanı ilk vestingin açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * Contract üstünde ilk vesting'in released parametresinin true olduğu gözlemlenmiştir.
	 * Alıcı adresin balansının çekilen miktar kadar arttığı gözlemlenmiştir.
	 * Blok zamanı bir sonraki vesting'in açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * Contract üstünde bir sonraki vesting'in released parametresinin true olduğu gözlemlenmiştir.
	 * 
	 **** Can work many times if there is enough relased amount
	 * Blok zamanı ilk vestingin açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * 3 manager tarafından ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 3 manager tarafından bir kez daha ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 3 manager tarafından bir kez daha ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 1 Manager tarafından yeniden çekme isteği oluşturulmak istendiğinde 'WaitForNextVestingReleaseDate()' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Can withdraw all vestings when unlocked
	 * Vestinglerin tamamının döngü ile blok zamanı vesting açılma zamanına simüle edilerek çekilmesinin başarılı olduğu gözlemlenmiştir.
	*/
    function _withdrawTokens(
        address[] memory _receivers,
        uint256[] memory _amounts
    ) internal returns (bool _isApproved) {
        if (_receivers.length != _amounts.length) {
            revert DifferentParametersLength();
        }

        uint256 _totalAmount = 0;
        for (uint256 a = 0; a < _amounts.length; a++) {
            if (_amounts[a] == 0) {
                revert ZeroAmount();
            }

            _totalAmount += _amounts[a];
        }

        uint256 _balance = IERC20(soulsTokenAddress).balanceOf(address(this));
        uint256 _amountWillBeReleased = 0;
        if (_totalAmount > _balance) {
            if (currentVestingIndex >= tokenVestings.length) {
                revert NoMoreVesting();
            }

            if (block.timestamp < tokenVestings[currentVestingIndex].unlockTime) {
                revert WaitForNextVestingReleaseDate();
            }

            for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                if (tokenVestings[v].unlockTime > block.timestamp) break;
                _amountWillBeReleased += tokenVestings[v].amount;
            }

            if (_amountWillBeReleased + _balance < _totalAmount) {
                revert NotEnoughAmount();
            }
        }

        string memory _title = string.concat("Withdraw Tokens From ", vaultName);

        bytes memory _encodedValues = abi.encode(_receivers, _amounts);
        managers.approveTopic(_title, _encodedValues);
        _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            if (_totalAmount > _balance) {
                //Needs to release new vesting

                for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                    if (tokenVestings[v].unlockTime < block.timestamp) {
                        tokenVestings[v].released = true;
                        emit ReleaseVesting(block.timestamp, v);
                        currentVestingIndex++;
                    }
                }

                if (_amountWillBeReleased > 0) {
                    if (!_soulsToken.transferFrom(mainVaultAddress, address(this), _amountWillBeReleased)) {
                        revert TransferError();
                    }
                }
            }

            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];

                if (!_soulsToken.transfer(_receiver, _amount)) {
                    revert TransferError();
                }
            }
            managers.deleteTopic(_title);
        }

        emit Withdraw(block.timestamp, _totalAmount, _isApproved);
    }

	//Read Functions
    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function getVestingData() public view returns (VestingInfo[] memory) {
        return tokenVestings;
    }

    /** TEST INFO
     * Blok zamanı ilk vesting zamanına gidecek şekilde simüle edilmiştir.
     * Fonksiyonun ilk vestinge ait amount bilgisinin döndüğü gözlemlenmiştir.
     * 1 Token çekilmiş ve fonksiyon tekrar çağırıldığında ilk vesting amount bilgisinin bir eksiği döndüğü gözlemlenmiştir.
     * Blok zamanı bir sonraki vesting zamanına gidecek şekilde simüle edilmiştir.
     * Fonksiyonun ilk iki vestingin amount bilgilerinin toplamının 1 eksiğini döndürdüğü gözlemlenmiştir.
     */
    function getAvailableAmountForWithdraw() public view returns (uint256 _amount) {
        _amount = IERC20(soulsTokenAddress).balanceOf(address(this));
        for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
            if (tokenVestings[v].unlockTime > block.timestamp) break;
            _amount += tokenVestings[v].amount;
        }
    }
}