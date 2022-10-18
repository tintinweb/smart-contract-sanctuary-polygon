// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./LandingToken.sol";

contract Protocol is AccessControl {
    bytes32 public constant CONTROLLER = keccak256("CONTROLLER");
    LandingToken private _landingToken;

    address private _masterAccount;

    struct Claim {
        uint256 amountPerHour;
        uint256 hoursClaimed;
        bool claimSet;
        uint16 hoursClaimable;
    }

    struct TotalClaim {
        uint16 hoursInMonth;
        uint256 eachClaimablePerHour;
        uint256 totalClaimedSet;
    }

    // address => timestamp => claimable amount
    mapping(address => mapping(uint256 => Claim)) totalLandcAllocated;
    uint256 private _totalClaimable;
    mapping(uint256 => TotalClaim) private totalClaimDetails;

    uint256 private _maintenanceVaultAmount;

    // The timestamp of 12:00 am of the first day of the month
    uint256 private _lastTimestampRentDistributed;

    constructor(
        address _oracleAddress,
        uint256 _intialTimestamp,
        address __masterAccount,
        address _baseStableCoin,
        address _swapRouter
    ) {
        _landingToken = new LandingToken(_oracleAddress, address(this), __masterAccount, _baseStableCoin, _swapRouter);
        _masterAccount = __masterAccount;
        _lastTimestampRentDistributed = _intialTimestamp; // !!! IMPORTANT TO SET THIS RIGHT
        _grantRole(DEFAULT_ADMIN_ROLE, __masterAccount);
        _grantRole(CONTROLLER, __masterAccount);
    }

    function getLandingTokenAddress() public view returns (address) {
        return address(_landingToken);
    }

    function getHours(uint256 timestamp) internal view returns (uint16) {
        uint256 timeDif = timestamp - _lastTimestampRentDistributed;
        // seconds in a day: 86400 => 86400*31 = 2678400
        if (timeDif == 2592000) {
            return 720; // 30*24
        } else if (timeDif == 2678400) {
            return 744; // 31*24
        } else if (timeDif == 2419200) {
            return 672; // 28*24
        } else if (timeDif == 2505600) {
            return 696; // 29*24
        }
        return 0;
    }

    // !!! Timestamp should be 12 am first day of the Month
    function distributePayment(
        uint256 rentToDistribute,
        uint256 maintainiaceAmount,
        uint256 timestamp
    ) external onlyRole(CONTROLLER) {
        require(
            _landingToken.balanceOf(address(this)) >= _totalClaimable + rentToDistribute + maintainiaceAmount,
            "Not enough balance in protocol contract"
        );
        require(block.timestamp > timestamp, "Month have not past");
        uint256 totalAddress = _landingToken.getTotalBuyers();
        uint16 hoursInMonths = getHours(timestamp);
        require(hoursInMonths != 0, "Timestamp given is incorrect");
        _lastTimestampRentDistributed = timestamp;
        if (rentToDistribute != 0 && totalAddress != 0) {
            uint256 eachClaimablePerHour = (rentToDistribute / totalAddress) / uint256(hoursInMonths);

            totalClaimDetails[timestamp].eachClaimablePerHour = eachClaimablePerHour;
            totalClaimDetails[timestamp].hoursInMonth = hoursInMonths;
            totalClaimDetails[timestamp].totalClaimedSet = block.timestamp;

            _totalClaimable += rentToDistribute;
            _maintenanceVaultAmount += maintainiaceAmount;
        }
    }

    function reset(uint256 timestamp) public {
        totalClaimDetails[timestamp].eachClaimablePerHour = 0;
        totalClaimDetails[timestamp].hoursInMonth = 0;
        totalClaimDetails[timestamp].totalClaimedSet = 0;
        address[] memory allBuyers = _landingToken.getAllBuyersAddress();
        for (uint256 index = 0; index < allBuyers.length; index++) {
            address buyer = allBuyers[index];
            totalLandcAllocated[buyer][timestamp].hoursClaimable = 0;
            totalLandcAllocated[buyer][timestamp].amountPerHour = 0;
            totalLandcAllocated[buyer][timestamp].hoursClaimed = 0;
            totalLandcAllocated[buyer][timestamp].claimSet = false;
        }
        _totalClaimable = 0;
        _maintenanceVaultAmount = 0;
    }

    function claimMaintenanceFee(uint256 amount) external onlyRole(CONTROLLER) {
        require(amount <= _maintenanceVaultAmount, "Not enough maintenance fee to collect");
        require(
            _landingToken.balanceOf(address(this)) >= _totalClaimable + _maintenanceVaultAmount,
            "Not enough balance in protocol contract"
        );
        _maintenanceVaultAmount -= amount;
        _landingToken.transfer(msg.sender, amount);
    }

    function getMaintenanceFee() external view onlyRole(CONTROLLER) returns (uint256) {
        return _maintenanceVaultAmount;
    }

    function getClaimableAllocated(uint256 timestamp) internal view returns (uint256) {
        return totalClaimDetails[timestamp].eachClaimablePerHour * totalClaimDetails[timestamp].hoursInMonth;
    }

    function getTotalClaimableInMonth(uint256 timestamp) external view returns (uint256) {
        if (totalClaimDetails[timestamp].totalClaimedSet == 0) {
            return 0;
        }
        if (_landingToken.getBuyer(msg.sender) > totalClaimDetails[timestamp].totalClaimedSet) {
            return 0;
        }
        if (totalLandcAllocated[msg.sender][timestamp].claimSet) {
            return
                totalLandcAllocated[msg.sender][timestamp].hoursClaimable *
                totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        }
        return getClaimableAllocated(timestamp);
    }

    function getClaimable(uint256 timestamp) public view returns (uint256) {
        if (totalClaimDetails[timestamp].totalClaimedSet == 0) {
            return 0;
        }
        if (_landingToken.getBuyer(msg.sender) > totalClaimDetails[timestamp].totalClaimedSet) {
            return 0;
        }
        uint256 claimablePerHour;
        uint256 hoursClaimable;
        uint256 claimedSeconds;
        uint256 hoursPassed;
        if (totalLandcAllocated[msg.sender][timestamp].claimSet) {
            claimablePerHour = totalLandcAllocated[msg.sender][timestamp].amountPerHour;
            hoursClaimable = uint256(totalLandcAllocated[msg.sender][timestamp].hoursClaimable);
            claimedSeconds = totalLandcAllocated[msg.sender][timestamp].hoursClaimed * 3600;
            if (claimablePerHour == 0 || hoursClaimable == 0 || block.timestamp < timestamp + claimedSeconds) {
                return 0;
            }
            hoursPassed = (block.timestamp - timestamp - claimedSeconds) / 3600;
            uint256 totalClaimable = 0;
            if (hoursPassed >= hoursClaimable) {
                totalClaimable = hoursClaimable * claimablePerHour;
            } else {
                totalClaimable = hoursPassed * claimablePerHour;
            }
            return totalClaimable;
        } else {
            claimablePerHour = totalClaimDetails[timestamp].eachClaimablePerHour;
            hoursPassed = (block.timestamp - timestamp) / 3600;
            return hoursPassed * claimablePerHour;
        }

    }

    function getTotalSaving() external view onlyRole(CONTROLLER) returns (uint256) {
        return _landingToken.balanceOf(address(this)) - _totalClaimable;
    }

    function claimLANDC(uint256 timestamp) external {
        TotalClaim memory totalClaimDetail = totalClaimDetails[timestamp];
        require(totalClaimDetail.totalClaimedSet > 0, "Invalid timestamp");
        require(_landingToken.getBuyer(msg.sender) < totalClaimDetail.totalClaimedSet, "Not eligible to claim");
        if (!totalLandcAllocated[msg.sender][timestamp].claimSet) {
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable = totalClaimDetail.hoursInMonth;
            totalLandcAllocated[msg.sender][timestamp].amountPerHour = totalClaimDetail.eachClaimablePerHour;
            totalLandcAllocated[msg.sender][timestamp].claimSet = true;
        }
        uint256 claimablePerHour = totalLandcAllocated[msg.sender][timestamp].amountPerHour;
        require(claimablePerHour != 0, "No claimable landc");
        uint256 claimedSeconds = totalLandcAllocated[msg.sender][timestamp].hoursClaimed * 3600;
        uint256 hoursClaimable = uint256(totalLandcAllocated[msg.sender][timestamp].hoursClaimable);
        require(hoursClaimable != 0, "No claimable currently");
        require(block.timestamp > timestamp + claimedSeconds, "Month have not past");
        uint256 hoursPassed = (block.timestamp - timestamp - claimedSeconds) / 3600;
        uint256 totalClaimable;
        if (hoursPassed >= hoursClaimable) {
            totalClaimable = hoursClaimable * claimablePerHour;
            totalLandcAllocated[msg.sender][timestamp].amountPerHour = 0;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimed += hoursClaimable;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable = 0;
        } else {
            totalClaimable = hoursPassed * claimablePerHour;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimed += hoursPassed;
            totalLandcAllocated[msg.sender][timestamp].hoursClaimable -= uint16(hoursPassed);
        }
        _totalClaimable -= totalClaimable;
        _landingToken.transfer(msg.sender, totalClaimable);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOracle.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract LandingToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant CONTROLLER = keccak256("CONTROLLER");

    uint256 intialMint = 1000000000000;
    uint256 decimalAdjMltp = 1;
    address public baseStableCoin;
    address public swapRouterAddress;
    ISwapRouter public immutable swapRouter;

    mapping(address => uint256) private _buyers;
    uint256 numberOfBuyers;
    address[] allBuyers;

    IOracle private _oracle;

    event BuyLANDC(address buyer, uint256 amount, uint256 timestamp, uint256 usdPaid);

    event SellLANDC(address seller, uint256 amount, uint256 timestamp, uint256 usdPaid);

    struct PropertyDetail {
        bytes imageCID;
        bytes legalDocCID;
    }

    mapping(string => PropertyDetail) private _properties;

    event PayRentLANDC(address rentPayer, string propertyID, uint256 amount, uint256 date, uint256 timestamp);

    address public _protocolAddress;

    constructor(
        address _oracleAddress,
        address __protocolAddress,
        address ownerAddress,
        address _baseStableCoin,
        address _swapRouterAddress
    ) ERC20("Landing Token", "LANDC") {
        intialMint = 1000000000000;
        _oracle = IOracle(_oracleAddress);
        _protocolAddress = __protocolAddress;
        baseStableCoin = _baseStableCoin;
        swapRouter = ISwapRouter(_swapRouterAddress);
        _oracle.initialize(address(this));
        _mint(address(this), intialMint * (10**decimals()));
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(CONTROLLER, ownerAddress);

        uint8 baseStabecoinDecimals = IERC20Metadata(_baseStableCoin).decimals();
        decimalAdjMltp = 10 ** (decimals() - baseStabecoinDecimals);
        // _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
    }

    function setProtocolAddress(address newProtocolAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _protocolAddress = newProtocolAddress;
    }

    function pause() public onlyRole(CONTROLLER) {
        _pause();
    }

    function unpause() public onlyRole(CONTROLLER) {
        _unpause();
    }

    function mint(uint256 amount) internal {
        intialMint += amount;
        // _approve(address(this), msg.sender, intialMint * (10 ** decimals()));
        _mint(address(this), amount);
    }

    //  function burn(uint256 amount) public virtual onlyRole(CONTROLLER) override {
    //     _burn(address(this), amount);
    // }

    function approve(address spender, uint256 amount) public virtual override whenNotPaused returns (bool) {
        require(spender != address(this), "Can not change allowance for landing token");
        return super.approve(spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (from != address(0) && to != address(0) && to != address(this) && to != _protocolAddress) {
            if (this.balanceOf(to) == 0) {
                _buyers[to] = block.timestamp;
                numberOfBuyers++;
                allBuyers.push(to);
            }
        }

        // if(from != address(0) && to != address(0)){
        //      if (from != address(this)) {
        //     _approve(from, address(this), this.allowance(from, address(this))-amount);
        //     }
        //     if(to != address(this)){
        //         _approve(to, address(this), this.allowance(to, address(this))+amount);
        //     }
        // }

        super._beforeTokenTransfer(from, to, amount);
    }

    function getBuyer(address addressToCheck) public view returns (uint256) {
        return _buyers[addressToCheck];
    }

    function getAllBuyersAddress() public view returns (address[] memory) {
        return allBuyers;
    }

    function getTotalBuyers() public view returns (uint256) {
        return numberOfBuyers;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (from != address(0) && to != address(0)) {
            if (from == address(this)) {
                _approve(to, address(this), this.balanceOf(to));
            } else if (to == address(this)) {
                _approve(from, address(this), this.balanceOf(from));
            } else {
                if (from != _protocolAddress && this.balanceOf(from) == 0) {
                    numberOfBuyers--;
                    _buyers[from] = 0;
                }
                _approve(to, address(this), this.balanceOf(to));
                _approve(from, address(this), this.balanceOf(from));
            }
        }

        super._afterTokenTransfer(from, to, amount);
    }

    function buyLANDCWithOtherToken(address _tokenIn, uint256 _amountIn) external {
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
        uint256 amount = 0;
        if (_tokenIn == baseStableCoin) {
            amount = _amountIn;
        } else {
            TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: baseStableCoin,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 100000,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amount = swapRouter.exactInputSingle(params);
        }

        amount = decimalAdjMltp * amount;
        uint256 burnAmount = ((amount * 4) / 100);
        uint256 amountTransferred = amount - burnAmount;
        _burn(address(this), burnAmount);

        emit BuyLANDC(msg.sender, amountTransferred, block.timestamp, amount);
        // _approve(msg.sender, this(address), this.allowance(buyer, msg.sender)+amount);
        this.transfer(msg.sender, amountTransferred);
    }

    function buyLANDC(uint256 usdAmount, string memory txID) external {
        uint256 amount = ((usdAmount * 10**36) / (this.getPrice()));
        require(this.balanceOf(address(this)) >= amount, "Not enough balance");

        bool usdPaid = _oracle.checkBuyTx(txID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 burnAmount = ((amount * 4) / 100);
        uint256 amountTransferred = amount - burnAmount;
        _burn(address(this), burnAmount);

        emit BuyLANDC(msg.sender, amountTransferred, block.timestamp, usdAmount);
        // _approve(msg.sender, this(address), this.allowance(buyer, msg.sender)+amount);
        this.transfer(msg.sender, amountTransferred);
    }

    // function sellLANDC(uint256 usdAmount, string memory txID) external {
    //     uint256 amount = ((usdAmount * 10**36) / (this.getPrice()));
    //     require(this.balanceOf(msg.sender) >= amount, "Not enough balance");

    //     bool usdPaid = _oracle.checkSellTx(txID, usdAmount);
    //     require(usdPaid, "USD not paid");

    //     this.transferFrom(msg.sender, address(this), amount);
    //     emit SellLANDC(msg.sender, amount, block.timestamp, usdAmount);
    // }

    function sellLANDC(uint256 _amount) external {
        require(this.balanceOf(msg.sender) >= _amount, "Not enough balance");
        // _burn(msg.sender, _amount);
        _transfer(msg.sender, address(this), _amount);
        TransferHelper.safeTransfer(baseStableCoin, msg.sender, _amount);
    }

    function addProperty(
        string memory _propertyID,
        bytes memory imageCID,
        bytes memory legalDocCID
    ) external onlyRole(CONTROLLER) {
        require(_properties[_propertyID].imageCID.length == 0, "Property already exist");
        _properties[_propertyID].imageCID = imageCID;
        _properties[_propertyID].legalDocCID = legalDocCID;
    }

    function getProperty(string memory propertyID) external view returns (PropertyDetail memory) {
        return _properties[propertyID];
    }

    // _date => first timestamp of start of the month
    function payRentLandc(
        uint256 amount,
        uint256 _date,
        string memory _propertyID
    ) external {
        require(_properties[_propertyID].imageCID.length != 0, "Property do not exist");
        require(this.balanceOf(msg.sender) >= amount, "Not enogh balance");
        this.transferFrom(msg.sender, _protocolAddress, amount);

        emit PayRentLANDC(msg.sender, _propertyID, amount, _date, block.timestamp);
    }

    function convertUSDRentToLandc(uint256 usdAmount, string memory rentTxID) external onlyRole(CONTROLLER) {
        uint256 mainWaletBalance = this.balanceOf(address(this));

        bool usdPaid = _oracle.checkRentTx(rentTxID, usdAmount);
        require(usdPaid, "USD not paid");
        uint256 amount = ((usdAmount * 10**36) / (this.getPrice()));
        if (mainWaletBalance < amount) {
            mint(amount - mainWaletBalance);
        }
        this.transfer(_protocolAddress, amount);
    }

    function getPrice() external view returns (uint256) {
        return (intialMint * 10**decimals()) / (totalSupply() / 10**decimals());
    }

    // try this.uniswapV2_executeSwap(
    //     transactions[index].pool,
    //     transactions[index].amount0Out,
    //     transactions[index].amount1Out,
    //     index == transactions.length - 1 ? address(this) : transactions[index+1].pool
    // ) {
    // } catch Error(string memory reason) {
    //     require(false, string(abi.encodePacked("Swapper: EFE - ", reason)));
    // } catch {
    //     require(false, "Swapper: EFA");
    // }

    function multicall(address[] memory targets, bytes[] memory datas) onlyRole(CONTROLLER) public {
        for (uint8 i; i < targets.length; i++) {
            (bool _success, bytes memory _response) = targets[i].call(datas[i]);
            require(_success == true, string(abi.encodePacked("REVERT: ", string(_response))));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IOracle {
    function initialize(address _erc20Address) external;
    function checkBuyTx(string memory buyUSDTx, uint256 amount) external returns(bool);
    function checkSellTx(string memory sellUSDTx, uint256 amount) external returns(bool); 
    function checkRentTx(string memory rentUSDTx, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}