// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "./StrategyBase.sol";


/**
* @title Corn Finance Simple Holding Strategy
* @author C.W.B.
*/
contract SimpleStrategy is StrategyBase {
    using SafeERC20 for IERC20;

    /**
    * @dev Set the deposit fee to 0.4% and transaction fee to 0.1%
    * @param _controller: Corn Finance Controller contract 
    */
    constructor(
        IController _controller,
        address _rebalancer
    ) StrategyBase(_controller, 4, 1000, 1, 1000, _rebalancer, 0, 0) {}

    // --------------------------------------------------------------------------------

    /**
    * @dev Only currently active vaults can deposits tokens into this holding strategy.
    * This function can only be called from one of the approved vaults added to the
    * Controller contract. Tokens are deposited into holding strategies when calling
    * 'createTrade()' and 'fillOrder()' in the Controller contract.
    * @param _from: Vault token owner
    * @param _token: ERC20 token address
    * @param _amount: Amount of '_token' to deposit
    */
    function deposit(address _from, address _token, uint256 _amount) external onlyActiveVault {
        _deposit(_from, _token, _amount);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Any vault that has deposited tokens into this strategy can withdraw their
    * tokens even after a vault is deactivated. This function can only be called from 
    * one of the approved vaults added to the Controller contract. Users are only able
    * to withdraw tokens from a holding strategy through withdrawing their vault token
    * by calling 'withdraw()' in the Controller contract.
    * @param _from: Vault token owner
    * @param _token: ERC20 token address
    * @param _amount: Amount of '_token' to withdraw
    */
    function withdraw(address _from, address _token, uint256 _amount) external onlyVault {
        _withdrawTransfer(_from, _token, _amount);
        require(
            IERC20(_token).balanceOf(address(this)) >= totalDeposits[_token],
            "CornFi Simple Strategy: Balance Error"
        );  
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Rebalance an ERC20 token held within this strategy. Claims the difference
    * between the token balance of the contract and the total deposits of the token.
    * @param _token: ERC20 token address to rebalance
    */
    function rebalanceToken(address _token) external onlyRebalancer {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if(balance > totalDeposits[_token]) {
            uint256 interest = balance - totalDeposits[_token]; 
            IERC20(_token).safeTransfer(feeAddress, interest);
            require(
                IERC20(_token).balanceOf(address(this)) >= totalDeposits[_token],
                "CornFi Simple Strategy: Balance Error"
            ); 
        }
        else {
            revert("CornFi Simple Strategy: Token is Balanced");
        }
    }
}

// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "../interfaces/IController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


pragma experimental ABIEncoderV2;

/**
* @title Corn Finance Strategy Base
* @author C.W.B.
*/
abstract contract StrategyBase is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Controller contract
    IController public immutable controller;
    
    // totalDeposits[ERC20] --> Amount deposited into this contract
    mapping(address => uint256) public totalDeposits;

    // vaultDeposits[vault][ERC20] --> Amount 'vault' has deposited into this contract
    mapping(address => mapping(address => uint256)) public vaultDeposits;

    // Fee wallet
    address public constant feeAddress = 0x93F835b9a2eec7D2E289c1E0D50Ad4dEd88b253f;

    // Address that can call 'onlyRebalancer' functions
    address public Rebalancer;

    // Numerator of unstaked/staked ratio
    uint256 public rebalancePoints;

    // Denominator of unstaked/staked ratio
    uint256 public rebalanceBasePoints;

    // Deposit fee
    // Fee = points / base points
    uint256 public immutable DEPOSIT_FEE_POINTS;
    uint256 public immutable DEPOSIT_FEE_BASE_POINTS;

    // Transaction fee
    // Fee = points / base points
    uint256 public immutable TX_FEE_POINTS;
    uint256 public immutable TX_FEE_BASE_POINTS;


    // --------------------------------------------------------------------------------
    // //////////////////////////////////// Events ////////////////////////////////////
    // --------------------------------------------------------------------------------
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event Claim(address indexed token, uint256 amount);


    // --------------------------------------------------------------------------------
    // ////////////////////////////////// Modifiers ///////////////////////////////////
    // --------------------------------------------------------------------------------

    /**
    * @dev Allows access to only currently active vaults and deactivated vaults. Vaults
    * that have not been added to the controller contract are restricted.
    */
    modifier onlyVault {
        require(
            controller.vault(msg.sender) != controller.NOT_A_VAULT(), 
            "CornFi Strategy Base: Vault Only Function"
        );
      _;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Allows access to only currently active vaults. Vaults that have not been 
    * added to the controller contract and deactivated vaults are restricted.
    */
    modifier onlyActiveVault {
        require(
            controller.vault(msg.sender) == controller.ACTIVE_VAULT(), 
            "CornFi Strategy Base: Active Vault Only Function"
        );
      _;
    }

    // --------------------------------------------------------------------------------

    modifier onlyRebalancer {
        require(msg.sender == Rebalancer, "CornFi Strategy Base: Invalid Caller");
        _;
    }


    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------

    /**
    * @param _controller: Corn Finance Controller contract 
    */
    constructor(
        IController _controller, 
        uint256 _depositFeePoints, 
        uint256 _depositFeeBasePoints, 
        uint256 _txFeePoints, 
        uint256 _txFeeBasePoints,
        address _rebalancer,
        uint256 _rebalancePoints,
        uint256 _rebalanceBasePoints
    ) {
        controller = _controller;
        DEPOSIT_FEE_POINTS = _depositFeePoints;
        DEPOSIT_FEE_BASE_POINTS = _depositFeeBasePoints;
        TX_FEE_POINTS = _txFeePoints;
        TX_FEE_BASE_POINTS = _txFeeBasePoints;
        _rebalanceSettings(_rebalancer, _rebalancePoints, _rebalanceBasePoints);
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _amountIn: Amount of an ERC20 token
    * @return The corresponding deposit fee amount 
    */
    function depositFee(uint256 _amountIn) external view returns (uint256) {
        if(DEPOSIT_FEE_POINTS > 0) {
            return _amountIn.mul(DEPOSIT_FEE_POINTS).div(DEPOSIT_FEE_BASE_POINTS);
        }
        else {
            return 0;
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _amountIn: Amount of an ERC20 token
    * @return The corresponding transaction fee amount 
    */
    function txFee(uint256 _amountIn) external view returns (uint256) {
        if(TX_FEE_POINTS > 0) {
            return _amountIn.mul(TX_FEE_POINTS).div(TX_FEE_BASE_POINTS);
        }
        else {
            return 0;
        }
    }

    // --------------------------------------------------------------------------------

    function rebalanceSettings(
        address _rebalancer, 
        uint256 _rebalancePoints, 
        uint256 _rebalanceBasePoints
    ) external onlyOwner {
        _rebalanceSettings(_rebalancer, _rebalancePoints, _rebalanceBasePoints);
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _rebalancer: Caller approved to rebalance
    */
    function _rebalanceSettings(
        address _rebalancer, 
        uint256 _rebalancePoints, 
        uint256 _rebalanceBasePoints
    ) internal {
        Rebalancer = _rebalancer;
        require(
            _rebalancePoints <= _rebalanceBasePoints, 
            "CornFi Strategy Base: Invalid Rebalance Ratio"
        );
        rebalancePoints = _rebalancePoints;
        rebalanceBasePoints = _rebalanceBasePoints;
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Only currently active vaults can deposits tokens into this holding strategy.
    * This function can only be called from one of the approved vaults added to the
    * Controller contract. Tokens are deposited into holding strategies when calling
    * 'createTrade()' and 'fillOrder()' in the Controller contract.
    * @param _from: Vault token owner
    * @param _token: ERC20 token address
    * @param _amount: Amount of '_token' to deposit
    */
    function _deposit(address _from, address _token, uint256 _amount) internal {
        if(_amount > 0) {
            IERC20 depositToken = IERC20(_token);

            // For a security check after transfer
            uint256 balanceBefore = depositToken.balanceOf(address(this));

            // Transfer deposit amount from user
            depositToken.safeTransferFrom(_from, address(this), _amount);

            // Ensure full amount is transferred
            require(
                depositToken.balanceOf(address(this)).sub(balanceBefore) == _amount, 
                "CornFi Strategy Base: Deposit Error"
            );

            // Increase the total deposits
            totalDeposits[_token] = totalDeposits[_token].add(_amount);

            // Increase the vault deposits
            vaultDeposits[msg.sender][_token] = vaultDeposits[msg.sender][_token].add(_amount);

            emit Deposit(msg.sender, _token, _amount);
        }
        else {
            revert("CornFi Strategy Base: Deposit Amount '0'");
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Any vault that has deposited tokens into this strategy can withdraw their
    * tokens even after a vault is deactivated. This function can only be called from 
    * one of the approved vaults added to the Controller contract. Users are only able
    * to withdraw tokens from a holding strategy through withdrawing their vault token
    * by calling 'withdraw()' in the Controller contract.
    * @param _from: Vault token owner
    * @param _token: ERC20 token address
    * @param _amount: Amount of '_token' to withdraw
    */
    function _withdrawTransfer(address _from, address _token, uint256 _amount) internal {
        // This prevents the owner from creating a malicious vault that could withdraw all tokens
        require(
            _amount <= vaultDeposits[msg.sender][_token], 
            "CornFi Strategy Base: Vault Withdraw Amount Exceeded"
        );
        
        if(_amount > 0) {
            // Transfer tokens from this contract to the owner
            IERC20(_token).safeTransfer(_from, _amount);

            // Subtract withdrawn amount from total deposited amount
            totalDeposits[_token] = totalDeposits[_token].sub(_amount);

            // Subtract withdrawn amount from the vault deposited amount
            vaultDeposits[msg.sender][_token] = vaultDeposits[msg.sender][_token].sub(_amount);

            emit Withdraw(msg.sender, _token, _amount);
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Any vault that has deposited tokens into this strategy can withdraw their
    * tokens even after a vault is deactivated. This function can only be called from 
    * one of the approved vaults added to the Controller contract. Users are only able
    * to withdraw tokens from a holding strategy through withdrawing their vault token
    * by calling 'withdraw()' in the Controller contract.
    * @param _token: ERC20 token address
    * @param _amount: Amount of '_token' to withdraw
    */
    function _withdraw(address _token, uint256 _amount) internal {
        // This prevents the owner from creating a malicious vault that could withdraw all tokens
        require(
            _amount <= vaultDeposits[msg.sender][_token], 
            "CornFi Strategy Base: Vault Withdraw Amount Exceeded"
        );
        
        if(_amount > 0) {
            // Subtract withdrawn amount from total deposited amount
            totalDeposits[_token] = totalDeposits[_token].sub(_amount);

            // Subtract withdrawn amount from the vault deposited amount
            vaultDeposits[msg.sender][_token] = vaultDeposits[msg.sender][_token].sub(_amount);

            emit Withdraw(msg.sender, _token, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IVaultBase.sol";
import "./IUniswapV2Router02.sol";
import "./IPokeMe.sol";
import "./IResolver.sol";
import "./IStrategy.sol";
import "./IGasTank.sol";


pragma experimental ABIEncoderV2;

interface IController {
    
    struct UserTokens {
        address vault;
        uint256 tokenId;
    }

    // --------------------------------------------------------------------------------
    // ///////////////////////////// Only Owner Functions /////////////////////////////
    // --------------------------------------------------------------------------------

    function pause() external;
    function unpause() external;
    function setVaultURI(uint256 _vaultId, string memory _URI) external;
    function deactivateRouter(IUniswapV2Router02 _router) external;
    function addVault(address _vault) external;
    function deactivateVault(address _vault) external;
    function setSlippage(uint256 _slippagePoints, uint256 _slippageBasePoints) external;
    function gelatoSettings(IPokeMe _pokeMe, IResolver _resolver, bool _gelato) external;
    function deactivateToken(uint256 _vaultId, address _token) external;
    function setTokenStrategy(uint256 _vaultId, address _token, address _strategy, uint256 _minDeposit) external;
    function changeTokenMinimumDeposit(uint256 _vaultId, address _token, uint256 _minDeposit) external;

    // --------------------------------------------------------------------------------
    // ///////////////////////////// Read-Only Functions //////////////////////////////
    // --------------------------------------------------------------------------------

    function NOT_A_VAULT() external view returns (uint8);
    function ACTIVE_VAULT() external view returns (uint8);
    function DEACTIVATED_VAULT() external view returns (uint8);
    function gelato() external view returns (address);
    function ETH() external view returns (address);
    function PokeMe() external view returns (IPokeMe);
    function Resolver() external view returns (IResolver);
    function GasToken() external view returns (address);
    function Gelato() external view returns (bool);
    function taskIds(uint256 _vaultId, uint256 _orderId) external view returns (bytes32);
    function tokenMaxGas(uint256 _vaultId, uint256 _tokenId) external view returns (uint256);
    function GasTank() external view returns (IGasTank);

    function routers(uint256 _index) external view returns (IUniswapV2Router02);
    function activeRouters(IUniswapV2Router02 _router) external view returns (bool);
    function vaults(uint256 _index) external view returns (IVaultBase);
    function Fees() external view returns (address);
    function DepositFees() external view returns (address);
    function SLIPPAGE_POINTS() external view returns (uint256);
    function SLIPPAGE_BASE_POINTS() external view returns (uint256);
    function holdingStrategies(uint256 _index) external view returns (address);
    function priceMultiplier(uint256 _vaultId) external view returns (uint256);
    
    function tokenStrategy(uint256 _vaultId, address _token) external view returns (IStrategy);
    function tokenMinimumDeposit(uint256 _vaultId, address _token) external view returns (uint256);
    function tokens(uint256 _vaultId, uint256 _index) external view returns (address);
    function activeTokens(uint256 _vaultId, address _token) external view returns (bool);
    function tokensLength(uint256 _vaultId) external view returns (uint256);
    function slippage(uint256 _amountIn) external view returns (uint256);
    function vaultURI(uint256 _vaultId) external view returns (string memory);
    function vault(address _vault) external view returns (uint8);
    function vaultId(address _vault) external view returns (uint256);
    function vaultsLength() external view returns (uint256);
    
    function viewTrades(
        uint256 _vaultId, 
        uint256 _tokenId, 
        uint256[] memory _tradeIds
    ) external view returns (IVaultBase.Order[][] memory);
    
    function viewOrder(
        uint256 _vaultId, 
        uint256 _orderId
    ) external view returns (IVaultBase.Order memory);
    
    function viewOrders(
        uint256 _vaultId, 
        uint256[] memory _orderIds
    ) external view returns (IVaultBase.Order[] memory);
    
    function viewOpenOrdersByToken(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (IVaultBase.Order[] memory);
    
    function viewOpenOrdersInRange(
        uint256 _vaultId, 
        uint256 _start, 
        uint256 _end
    ) external view returns (IVaultBase.Order[] memory);
    
    function ordersLength(uint256 _vaultId) external view returns (uint256);
    function openOrdersLength(uint256 _vaultId) external view returns (uint256);
    
    function tokenOpenOrdersLength(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (uint256);
    
    function tokenLength(uint256 _vaultId) external view returns (uint256);

    function tokenTradeLength(
        uint256 _vaultId, 
        uint256 _tokenId
    ) external view returns (uint256);

    function vaultTokensByOwner(address _owner) external view returns (UserTokens[] memory);


    // --------------------------------------------------------------------------------
    // /////////////////////////////// Vault Functions ////////////////////////////////
    // --------------------------------------------------------------------------------

    function createTrade(
        uint256 _vaultId, 
        address[] memory _tokens, 
        uint256[] memory _amounts, 
        uint[] memory _times, 
        uint256 _maxGas
    ) external;

    function fillOrderGelato(
        uint256 _vaultId, 
        uint256 _orderId, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) external;

    function withdraw(uint256 _vaultId, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";
import "./IStrategy.sol";

pragma experimental ABIEncoderV2;

interface IVaultBase {
    struct Order {
        uint256 tokenId;
        uint256 tradeId;
        uint256 orderId;
        uint timestamp;
        address[2] tokens;
        uint256[3] amounts;
        uint[] times;
    }

    struct Strategy {
        address[] tokens;
        uint256[] amounts;
        uint[] times;
    }

    struct Token {
        address token;
        uint256 amount;
    }

    function tokenCounter() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function owner() external view returns (address);
    function _tokenTradeLength(uint256 _tokenId) external view returns (uint256);
    function setStrategy(address _token, address _strategy, uint256 _minDeposit) external;
    function changeMinimumDeposit(address _token, uint256 _minDeposit) external;
    function strategy(address _token) external view returns (IStrategy);
    function minimumDeposit(address _token) external view returns (uint256);

    function trade(uint256 _tokenId, uint256 _tradeId) external view returns (uint256[] memory);
    function order(uint256 _orderId) external view returns (Order memory);
    function ordersLength() external view returns (uint256);
    function openOrdersLength() external view returns (uint256);
    function openOrderId(uint256 _index) external view returns (uint256);
    function tokenOpenOrdersLength(uint256 _tokenId) external view returns (uint256);
    function tokenOpenOrderId(uint256 _tokenId, uint256 _index) external view returns (uint256);
    function viewTokenAmounts(uint256 _tokenId) external view returns (Token[] memory);
    function viewStrategy(uint256 _tokenId) external view returns (Strategy memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function createTrade(address _from, address[] memory _tokens, uint256[] memory _amounts, uint[] memory _times) external returns (uint256[] memory);
    function fillOrder(uint256 _orderId, IUniswapV2Router02 _router, address[] memory _path) external returns (Order[] memory, uint256[] memory);
    function withdraw(address _from, uint256 _tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokens(uint256 _index) external view returns (address);
    function tokensLength() external view returns (uint256);
    function deactivateToken(address _token) external;
    function activeTokens(address _token) external view returns (bool);

    function setBaseURI(string memory) external;
    function BASE_URI() external view returns (string memory);
    function PRICE_MULTIPLIER() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


interface IPokeMe {
    function gelato() external view returns (address payable);
    
    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 task);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    function cancelTask(bytes32 _taskId) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external ;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function getSelector(string calldata _func) external pure returns (bytes4);
    
    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function getFeeDetails() external view returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";


interface IResolver {
    function checker(
        uint256 _vaultId, 
        uint256 _orderId, 
        address _fromToken, 
        address _toToken, 
        uint256 _fromAmount
    ) external view returns (bool, bytes memory);

    function findBestPathExactIn(
        address _fromToken, 
        address _toToken, 
        uint256 _amountIn
    ) external view returns (address, address[] memory, uint256);

    function findBestPathExactOut(
        address _fromToken, 
        address _toToken, 
        uint256 _amountOut
    ) external view returns (address, address[] memory, uint256);

    function getAmountOut(
        IUniswapV2Router02 _router, 
        uint256 _amountIn, 
        address _fromToken, 
        address _connectorToken, 
        address _toToken
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


pragma experimental ABIEncoderV2;

interface IStrategy {
    struct Tokens {
        address token;
        address amToken;
    }

    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event TokenAdded(address token, address amToken);


    function depositFee(uint256 _amountIn) external view returns (uint256);
    function txFee(uint256 _amountIn) external view returns (uint256);
    function fillerFee(uint256 _amountIn) external view returns (uint256);
    function deposit(address _from, address _token, uint256 _amount) external;
    function withdraw(address _from, address _token, uint256 _amount) external;
    function vaultDeposits(address _vault, address _token) external view returns (uint256);

    function DEPOSIT_FEE_POINTS() external view returns (uint256);
    function DEPOSIT_FEE_BASE_POINTS() external view returns (uint256);
    function TX_FEE_POINTS() external view returns (uint256);
    function TX_FEE_BASE_POINTS() external view returns (uint256);
    function rebalanceToken(address _token) external;
    function claim() external;
    function balanceRatio(address _token) external view returns (uint256, uint256);
    function rebalancePoints() external view returns (uint256);
    function rebalanceBasePoints() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IGasTank {
    event DepositGas(address indexed user, uint256 amount);
    event WithdrawGas(address indexed user, uint256 amount);
    event Pay(address indexed payer, address indexed payee, uint256 amount);
    event Approved(address indexed payer, address indexed payee, bool approved);

    // View
    function userGasAmounts(address _user) external view returns (uint256);
    function approvedPayees(uint256 _index) external view returns (address);
    function _approvedPayees(address _payee) external view returns (bool);
    function userPayeeApprovals(address _payer, address _payee) external view returns (bool);
    function txFee() external view returns (uint256);
    function feeAddress() external view returns (address);
    
    // Users
    function depositGas(address _receiver) external payable;
    function withdrawGas(uint256 _amount) external;
    function approve(address _payee, bool _approve) external;
    
    // Approved payees
    function pay(address _payer, address _payee, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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