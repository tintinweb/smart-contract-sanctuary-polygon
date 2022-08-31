// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IPlanetVault.sol";
import "../interfaces/IPlanetAccessControl.sol";

/**
 * @title PlanetRegistry
 *
 * @dev A contract for handling the XPLUS planet creation flow.
 * Register - Register planet with deposit requirement
 * Deposit - deposit the specified token amount
 * Create - once the deposit fulfilled the requirment, NFT can be mint and distribute
 *          to depositers wallet addresses
 *
 * The deposit will be temporary held in this contract and transfer to the vault
 * once planet is created and NFT is distributed.
 *
 */
contract PlanetRegistry {
    
    enum PlanetStatus { REGISTERED, CREATED }

    struct ShareholderData {
        address shareholder;
        uint256 shares;
        uint256 depositedAmount;
    }

    struct PlanetData {
        bytes32 planetCode;
        address applicant;
        address token;
        uint256 tokenTypeId;
        uint256 tokenSupply;
        address depositToken;
        uint256 depositRequirement;
        uint256 chargeShares;
        PlanetStatus status;
    }

    address public sharesCollector;
    IPlanetAccessControl public accessControl;
    mapping(address => bool) public registers;
    mapping(address => bool) public allowedDepositTokens;
    mapping(address => bool) public allowedTokens;

    mapping(bytes32 => PlanetData) public planetInfo;
    mapping(bytes32 => ShareholderData[]) public shareholdersInfo;

    event SharesCollectorChanged(address oldCollector, address newCollector);

    event AllowedTokensUpdated(address _token, bool _isAllowed);

    event AllowedDepositTokenUpdated(address _token, bool _isAllowed);

    event AdminUpdated(address _admin, bool isAllowed);

    event PlanetRegistered(
        bytes32 indexed planetCode,
        address applicant,
        address token,
        uint256 tokenSupply,
        address depositToken,
        uint256 depositRequirement,
        uint256 chargedShares
    );

    event PlanetCreated(bytes32 indexed planetCode);

    event PlanetUnregistered(bytes32 indexed planetCode);

    event DepositToPlanet(
        bytes32 indexed planetCode,
        address shareholder,
        uint256 amount
    );

    event PlanetShareholderAdded(
        bytes32 indexed planetCode,
        address shareholder,
        uint256 shares
    );

    event PlanetShareholderRemoved(
        bytes32 indexed planetCode,
        address shareholder
    );

    event RegisterUpdated(address register, bool isAllowed);

    modifier onlyPlanetStatus(bytes32 _code, PlanetStatus _status) {
        require(
            planetInfo[_code].status == _status,
            "incorrect status"
        );
        _;
    }

    modifier onlyPlanetShareholders(bytes32 _code) {
        require(
            _shareholderExists(_code, msg.sender),
            "unauthorized"
        );
        _;
    }

    modifier onlyApplicant(bytes32 _code) {
        require(
            planetInfo[_code].applicant == msg.sender || accessControl.hasRole(accessControl.defaultAdminRole(), msg.sender),
            "unauthorized"
        );
        _;
    }

    modifier onlyShareHoldersAndAdmin(bytes32 _code) {
        require(
            _shareholderExists(_code, msg.sender) || accessControl.hasRole(accessControl.defaultAdminRole(), msg.sender),
            "unauthorized"
        );
        _;
    }

    // For remove sharesholder
    modifier onlyShareHolderAndAdmin(bytes32 _code, address account) {
        require(
            (_shareholderExists(_code, msg.sender) && account == msg.sender) ||
            planetInfo[_code].applicant == msg.sender ||
            accessControl.hasRole(accessControl.defaultAdminRole(), msg.sender),
            "unauthorized"
        );
        _;
    }

    modifier onlyAdmin {
        require(accessControl.isAdmin(accessControl.defaultAdminRole(), msg.sender), "unauthorized");
        _;
    }

    modifier onlyOperator {
        require(accessControl.hasRole(accessControl.defaultAdminRole(), msg.sender), "unauthorized");
        _;
    }

    constructor(address _accessControl) {
        accessControl = IPlanetAccessControl(_accessControl);
    }
    
    /*********************************
     * Admin Functions               *
     *********************************/
    function setSharesCollector(address _collector) public onlyAdmin {
        require( _collector != address(0), "zero address");
        address previousCollector = sharesCollector;
        sharesCollector = _collector;
        emit SharesCollectorChanged(previousCollector, sharesCollector);
    }

    function setRegister(address _register, bool _isAllowed) public onlyAdmin {
        require( _register != address(0), "zero address");
        registers[_register] = _isAllowed;
        emit RegisterUpdated(_register, _isAllowed);
    }

    function setAllowedToken(address _token, bool isAllowed) public onlyOperator {
        require(_token != address(0), "zero address");
        allowedTokens[_token] = isAllowed;
        emit AllowedTokensUpdated(_token, isAllowed);
    }

    function setAllowedDepositToken(address _token, bool isAllowed) public onlyOperator {
        allowedDepositTokens[_token] = isAllowed;
        emit AllowedDepositTokenUpdated(_token, isAllowed);
    }

    /*********************************
     * Planet Operation Functions    *
     *********************************/

    function registerPlanet(
        bytes32 _planetCode,
        address _applicant,
        address _token,
        uint256 _tokenSupply,
        address _depositToken,
        uint256 _depositRequirement,
        uint256 _chargeShares
    ) public {
        require(registers[msg.sender], "unauthorized");
        require(
            planetInfo[_planetCode].applicant == address(0),
            "code is taken"
        );
        require(_planetCode != "", "empty code");
        require(
            _applicant != address(0),
            "applicant is zero address"
        );
        require(allowedTokens[_token], "planet not supported");
        require(
            (_tokenSupply % 100) == 0,
            "shares not multiple of 100"
        );
        require(_tokenSupply >= 1000, "shares less than 1000");
        require(
            allowedDepositTokens[_depositToken],
            "depositToken not supported"
        );
        require(_depositRequirement > 0, "zero deposit requirement");
        require(_chargeShares <= 20, "charge shares exceeds" );

        PlanetData storage newPlanet = planetInfo[_planetCode];
        newPlanet.planetCode = _planetCode;
        newPlanet.applicant = _applicant;
        newPlanet.token = _token;
        newPlanet.tokenSupply = _tokenSupply;
        newPlanet.depositToken = _depositToken;
        newPlanet.depositRequirement = _depositRequirement;
        newPlanet.chargeShares = _chargeShares;
        newPlanet.status = PlanetStatus.REGISTERED;

        // By default, the applicant is the planet owner
        // controller.createRole(_planetCode, _applicant);

        // By default, the applicant owns 100% shares
        // index 0 will always be the appplicant
        shareholdersInfo[_planetCode].push(
            ShareholderData({
                shareholder: _applicant,
                shares: 100,
                depositedAmount: 0
            })
        );

        emit PlanetRegistered(
            _planetCode,
            _applicant,
            _token,
            _tokenSupply,
            _depositToken,
            _depositRequirement,
            _chargeShares
        );
    }

    function unregisterPlanet(bytes32 _code)
        public
        onlyApplicant(_code)
        onlyPlanetStatus(_code, PlanetStatus.REGISTERED)
    {
        PlanetData storage planetData = planetInfo[_code];
        ShareholderData[] storage shareholders = shareholdersInfo[_code];

        for (uint256 i = 0; i < shareholders.length; i++) {
            ShareholderData storage holder = shareholders[i];
            if (holder.depositedAmount > 0) {
                _refund(planetData.depositToken, holder.depositedAmount, holder.shareholder);
            }

        }

        // Delete Planet Data
        delete shareholdersInfo[_code];
        delete planetInfo[_code];
        emit PlanetUnregistered(_code);
    }

    function deposit(
        bytes32 _code,
        address _token,
        uint256 _payAmount
    )
        public
        payable
        onlyPlanetShareholders(_code)
        onlyPlanetStatus(_code, PlanetStatus.REGISTERED)
    {
        require(
            planetInfo[_code].depositToken == _token,
            "depositToken mismatch"
        );

        bool isNativeToken = _token == address(0);

        if (isNativeToken) {
            _payAmount = msg.value;
        }
        
        _updateDepositRecord(_code, msg.sender, _payAmount);

        if (!isNativeToken) {
            SafeERC20.safeTransferFrom(
                IERC20(_token),
                msg.sender,
                address(this),
                _payAmount
            );
        }
    }

    function createPlanet(bytes32 _code)
        public
        onlyShareHoldersAndAdmin(_code)
        onlyPlanetStatus(_code, PlanetStatus.REGISTERED)
    {
        uint256 planetDepositAmount = _getDepositAmount(_code);

        require(
            planetDepositAmount >= planetInfo[_code].depositRequirement,
            "insufficient deposit"
        );

        uint256 planetId = _createPlanet(_code);
        _depositToPlanetVault(_code, planetDepositAmount);
        accessControl.createRole(_code, planetInfo[_code].applicant, planetInfo[_code].token, planetId);

        emit PlanetCreated(_code);
    }

    function addShareholder(
        bytes32 _code,
        address _shareholder,
        uint256 _shares
    ) 
        public
        onlyPlanetStatus(_code, PlanetStatus.REGISTERED)
        onlyApplicant(_code)
    {
        require(_shares > 0 && _shares <= 100, "invalid shares");
        
        PlanetData storage planetData = planetInfo[_code];
        ShareholderData[] storage shareholders = shareholdersInfo[_code];
        ShareholderData storage applicant = shareholders[0];

        require(!_shareholderExists(_code, _shareholder), "shareholder exists");

        shareholders.push(
            ShareholderData({
                shareholder: _shareholder,
                shares: _shares,
                depositedAmount: 0
            })
        );

        applicant.shares -= _shares;

        // if applicant has deposit, check if deposit exceeds updated shares
        if (applicant.depositedAmount > 0) {
            uint256 newDepositRquired = 
                (planetData.depositRequirement * applicant.shares) / 100;
            
            require(
                applicant.depositedAmount <= newDepositRquired,
                "applicant deposit exceeds shares"
            );
        }

        emit PlanetShareholderAdded(_code, _shareholder, _shares);
    }

    function removeShareholder(
        bytes32 _code,
        address _shareholder
    )
        public
        onlyPlanetStatus(_code, PlanetStatus.REGISTERED)
        onlyShareHolderAndAdmin(_code, _shareholder)
    {
        ShareholderData[] storage shareholders = shareholdersInfo[_code];
        ShareholderData storage applicant =  shareholders[0];

        require(_shareholder != applicant.shareholder, "applicant removal not allowed");

        for (uint256 i = 1; i < shareholders.length; i++) {
            if (shareholders[i].shareholder == _shareholder) {
                applicant.shares += shareholders[i].shares;
                if (shareholders[i].depositedAmount > 0) {
                    _refund(
                        planetInfo[_code].depositToken,
                        shareholders[i].depositedAmount,
                        _shareholder
                    );
                }

                shareholders[i] = shareholders[shareholders.length - 1];
                shareholders.pop();
                emit PlanetShareholderRemoved(_code, _shareholder);
                return;
            }
        }
        revert("shareholder not found");
    }

    /*********************************
     * Internal Functions            *
     *********************************/

    function _shareholderExists(bytes32 _code, address _shareholder)
        internal
        view
        returns (bool)
    {
        ShareholderData[] storage shareholders = shareholdersInfo[_code];

        for (uint256 i = 0; i < shareholders.length; i++) {
            if (shareholders[i].shareholder == _shareholder) {
                return true;
            }
        }

        return false;
    }

    function _getDepositAmount(bytes32 _code)
        internal
        view
        returns (uint256)
    {
        ShareholderData[] storage shareholders = shareholdersInfo[_code];
        uint256 totalDeposit = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            totalDeposit += shareholders[i].depositedAmount;
        }
        return totalDeposit;
    }

    function _updateDepositRecord(
        bytes32 _code,
        address _shareholder,
        uint256 payAmount
    ) internal {
        uint256 precision = 100;

        ShareholderData[] storage shareholders = shareholdersInfo[_code];
        
        for (uint256 i = 0; i < shareholders.length; i++) {
            if (shareholders[i].shareholder == _shareholder) {
                ShareholderData storage thisholder = shareholders[i];

                uint256 requiredAmount = (planetInfo[_code].depositRequirement * thisholder.shares) / precision;
                thisholder.depositedAmount += payAmount;
                
                require(
                    thisholder.depositedAmount <= requiredAmount,
                    "deposit exceeds required"
                );

                emit DepositToPlanet(
                    _code,
                    _shareholder,
                    payAmount
                );
                return;
            }
        }

        revert("shareholder not found");
    }

    function _refund(address depositToken, uint256 amount, address to) internal {
        if (depositToken == address(0)) {
            payable(to).transfer(amount);
        } else {
            SafeERC20.safeTransfer(
                IERC20(depositToken),
                to,
                amount
            );
        }
    }

    function _createPlanet(bytes32 _code) internal returns (uint256){
        PlanetData storage planetData = planetInfo[_code];
        IPlanets planets = IPlanets(planetData.token);

        uint256 _tokenTypeId = planets.create(planetData.applicant);
        planetData.tokenTypeId = _tokenTypeId;
        planetData.status = PlanetStatus.CREATED;

        ShareholderData[] storage sharholders = shareholdersInfo[_code];
        uint256 platformShares = (planetData.tokenSupply * planetData.chargeShares) / 100;

        planets.mint(
            _tokenTypeId,
            sharesCollector,
            platformShares
        );

        uint256 remainSupply = planetData.tokenSupply - platformShares;
        for (uint256 i = 0; i < sharholders.length; i++) {
            ShareholderData storage thisholder = sharholders[i];
            planets.mint(
                _tokenTypeId,
                thisholder.shareholder,
                (remainSupply * thisholder.shares) / 100
            );
        }
        return _tokenTypeId;
    }

    function _depositToPlanetVault(bytes32 _code, uint256 _amount) internal {
        PlanetData storage planetData = planetInfo[_code];
        address vaultAddr = IPlanets(planetData.token).getPlanetVaultAddress();
        address _depositToken = planetData.depositToken;
        uint256 tokenTypeId = planetData.tokenTypeId;

        IPlanetVault planetVault = IPlanetVault(vaultAddr);
        planetVault.setDepositToken(tokenTypeId, _depositToken);

        if (_depositToken == address(0)) {
            planetVault.deposit{value: _amount}(tokenTypeId, _depositToken, 0);
        } else {
            IERC20(_depositToken).approve(vaultAddr, _amount);
            planetVault.deposit(tokenTypeId, _depositToken, _amount);
        }
    }


    /*********************************
     * View Functions                *
     *********************************/

    function getPlanetData(bytes32 _code)
        public
        view
        returns (PlanetData memory)
    {
        return planetInfo[_code];
    }

    function getPlanetShareholders(bytes32 _code)
        public
        view
        returns (ShareholderData[] memory)
    {
        return shareholdersInfo[_code];
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPlanets is IERC1155{
    function pausePlanet(uint256 _typeId) external;

    function unpausePlanet(uint256 _typeId) external;

    function dissolvePlanet(uint256 _typeId) external;

    function create(
        address _to
    ) external returns (uint256);

    function mint(
        uint256 _typeId,
        address _shareholder,
        uint256 _shareAmount
    ) external;

    function redeemDeposit(uint256 _typeId, address from) external;

    function getSupplyInfo(uint256 _typeId)
        external
        view
        returns (uint256, uint256);

    function getPlanetVaultAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPlanetVault {
    function setDepositToken(uint256 _planetId, address tokenAddress) external;

    function deposit(
        uint256 _planetId,
        address tokenAddress,
        uint256 amount
    ) external payable;

    function withdrawDeposit(uint256 _planetId, address _to, uint256 amount) external;

    function getPlanetDeposit(uint256 _planetId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// Modified based on OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

/**
 * @dev External interface of PlanetAccessControl declared to support ERC165 detection.
 */
interface IPlanetAccessControl is IAccessControlEnumerableUpgradeable {

    function isAdmin(bytes32 role, address account) external returns (bool);

    function setAllowedToken(address token, bool isAllowed) external;

    function isAllowedToken(address token) external returns (bool);

    function createRole(bytes32 role, address admin, address token, uint256 id) external;

    function setAdmin(bytes32 role, address admin) external;

    function getAdmin(bytes32 role) external returns (address);

    function renounceRoleOwnership(bytes32 role) external;

    function renounceRoleDefaultOwnership(bytes32 role) external;

    function defaultAdminRole() external returns (bytes32);

    function getRoleById(address token, uint256 id) external returns (bytes32);

    function getIdByRole(bytes32 role) external returns (address, uint256);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}