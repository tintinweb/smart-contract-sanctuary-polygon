// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

// Changes v2

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IMortgageInterest.sol";

contract MortgageControl is AccessControl, IMortgageInterest {
    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

    uint256 private mortgageId = 319; // 319 en testnet --- // **** 226 mortages en mainnet ****
    uint64 private interest = 27; //27 is equal to 0.027% (0.027 times 1000)
    bool public flag = false;

    struct LocalVars {
        uint256 _mortgageId;
        address _user;
        address _collection;
        uint256 _nftId;
        uint256 _loan;
        uint256 _downPay;
        uint256 _capitalPay;
        uint256 _startDate;
        uint256 _period;
        uint256 _payCounter;
        bool _isPay;
        address _wrapContract;
        bool _mortgageAgain;
        uint256 _linkId;
        uint256 _price;
    }

    /// @dev Mapping to save the contracts allowed to use the function of this contract.
    mapping(address => bool) public mortgage;

    ///@dev address user wallet
    ///@dev uint256 Mortgage ID
    mapping(address => mapping(uint256 => Information)) private usermortgage;

    /// @dev Wallet => Mortgage ID => Mortgage Interest Struct: to save the data of the user's mortgage
    mapping(address => mapping(uint256 => MortgageInterest)) private userToMortgageInterest;

    ///@dev wallet => collection => No. of delayed mortgages in this collection for this user.
    mapping(address => mapping(address => uint256)) private delayedMortgages;
    /// @dev wallet => Collection => MortgageID => Rent Retained Amount for being delayed in the Mortgage Payment
    mapping(address => mapping(address => mapping(uint256 => uint256))) private rentsRetained;

    ///@dev use Mortgage ID to return user wallet
    mapping(uint256 => address) private idInfo;

    ///@dev address Colection
    ///@dev uint256 NFT ID
    ///@dev uint256 Mortgage ID
    mapping(address => mapping(uint256 => uint256)) private dataID;

    ///@dev Constructor for seting the roles for the multisign and the relayer
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(DEV_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470); // multisign
        _setupRole(DEV_ROLE, 0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23); // relay testnet
        setMortgageContract(0x1921a154365A82b8d54a3Cb6e2Fd7488cD0FFd23, true); // set relayer testnet as strategy
    }

    modifier onlymortgage() {
        if (!mortgage[msg.sender]) {
            revert("you can not modify");
        }
        _;
    }

    modifier onlyDev() {
        if (!hasRole(DEV_ROLE, msg.sender)) {
            revert("You're not a Dev");
        }
        _;
    }

    // ********************** GETTERS FUNCTIONS ************************ //

    ///@dev Function to get the Number of delayed mortgages a user has in the collection.
    function getDelayedMortgages(address _wallet, address _collection)
        external
        view
        returns (uint256 numMortgageDelayed)
    {
        numMortgageDelayed = delayedMortgages[_wallet][_collection];
    }

    /// @dev Function to get the user's Rents Retained per Mortgage ID.
    /// @param _user - the user's wallet address.
    /// @param _collection - the address of the NFT Collection.
    /// @param _mortgageID - the Mortgage ID to Query.
    /// @return _userRetainedRents - the Struct that holds all the information save for the user's Rents.
    function getRetainedRent(address _user, address _collection, uint256 _mortgageID)
        external
        view
        returns (uint256 _userRetainedRents)
    {
        _userRetainedRents = rentsRetained[_user][_collection][_mortgageID];
    }

    function getCollection(address _wallet, uint256 _mortgageID) external view returns (address _collection) {
        _collection = usermortgage[_wallet][_mortgageID].collection;
    }

    /// @dev Function to get the amount of interest paid with the retained rents.
    function getInterestPaid(address _user, uint256 _mortgageID)
        external
        view
        returns (uint256 LendersInterest, uint256 PanoramInterest)
    {
        LendersInterest = userToMortgageInterest[_user][_mortgageID].interestLendersPaid;
        PanoramInterest = userToMortgageInterest[_user][_mortgageID].interestPanoramPaid;
    }

    function getStartDate(address _wallet, uint256 _mortgageID) external view returns (uint256) {
        return usermortgage[_wallet][_mortgageID].startDate;
    }

    function getMortgageId(address _collection, uint256 _nftId) external view returns (uint256 _mortgageId) {
        return dataID[_collection][_nftId];
    }

    function getIdInfo(uint256 id) external view returns (address _user) {
        return idInfo[id];
    }

    function getUserInfo(address _user, uint256 _mortgageId)
        public
        view
        returns (address, uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool, uint256)
    {
        LocalVars memory vars;
        vars._user = _user;
        vars._mortgageId = _mortgageId;
        return (
            vars._collection = usermortgage[vars._user][vars._mortgageId].collection,
            vars._nftId = usermortgage[vars._user][vars._mortgageId].nftId,
            vars._wrapContract = usermortgage[vars._user][vars._mortgageId].wrapContract,
            vars._loan = usermortgage[vars._user][vars._mortgageId].loan,
            vars._downPay = usermortgage[vars._user][vars._mortgageId].downPay,
            vars._price = usermortgage[vars._user][vars._mortgageId].price,
            vars._startDate = usermortgage[vars._user][vars._mortgageId].startDate,
            vars._period = usermortgage[vars._user][vars._mortgageId].period,
            vars._payCounter = usermortgage[vars._user][vars._mortgageId].payCounter,
            vars._isPay = usermortgage[vars._user][vars._mortgageId].isPay,
            vars._mortgageAgain = usermortgage[vars._user][vars._mortgageId].mortgageAgain,
            vars._linkId = usermortgage[vars._user][vars._mortgageId].linkId
        );
    }

    function getInterestRate() external view returns (uint64 _interest) {
        return interest;
    }
    /// @dev Function to return  the amount the user has to pay daily  as capital pay for the loan.

    function getCapitalPay(address _user, uint256 _mortgageId) external view returns (uint256 _capitalPay) {
        return (usermortgage[_user][_mortgageId].capitalPay);
    }

    function getMortgageStatus(address _user, uint256 _mortgageId) external view returns (bool _status) {
        return (usermortgage[_user][_mortgageId].isPay);
    }

    function getMortgageLiquidationStatus(address _user, uint256 _mortgageId) external view returns (bool _status) {
        return (userToMortgageInterest[_user][_mortgageId].liquidate);
    }

    function getDebtInfo(address _user, uint256 _mortgageId) external view returns (uint256, uint256, uint256) {
        LocalVars memory vars;
        return (
            vars._loan = usermortgage[_user][_mortgageId].loan,
            vars._period = usermortgage[_user][_mortgageId].period,
            vars._payCounter = usermortgage[_user][_mortgageId].payCounter
        );
    }

    function mortgageLink(address _user, uint256 _mortgageId)
        external
        view
        returns (bool _mortgageAgain, uint256 _linkId)
    {
        return (
            _mortgageAgain = usermortgage[_user][_mortgageId].mortgageAgain,
            _linkId = usermortgage[_user][_mortgageId].linkId
        );
    }

    function getTotalMortgages() external view returns (uint256) {
        return mortgageId;
    }

    // Changes v2
    // Return if a mortgage is Delayed, 30 days without a payment.
    /*   function IsDelayed(address _wallet, uint256 _IdMortage) external view returns (bool isDelayed) {
        isDelayed = userToMortgageInterest[_wallet][_IdMortage].isMonthlyPaymentDelayed;
    } */

    // Changes v2
    function IsPaidOrLiquidated(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (bool IsPaid, bool IsLiquidated)
    {
        IsPaid = usermortgage[_wallet][_IdMortgage].isPay;
        IsLiquidated = userToMortgageInterest[_wallet][_IdMortgage].liquidate;
    }

    // Changes v2
    function getFrontMortgageData(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (
            uint256 totalDebt,
            uint256 lastTimePayment,
            uint8 strikes,
            bool isMonthlyPaymentDelayed,
            bool liquidate
        )
    {
        totalDebt = userToMortgageInterest[_wallet][_IdMortgage].totalDebt;
        lastTimePayment = userToMortgageInterest[_wallet][_IdMortgage].lastTimePayment;
        strikes = userToMortgageInterest[_wallet][_IdMortgage].strikes;
        isMonthlyPaymentDelayed = userToMortgageInterest[_wallet][_IdMortgage].isMonthlyPaymentDelayed;
        liquidate = userToMortgageInterest[_wallet][_IdMortgage].liquidate;
    }

    function getuserToMortgageInterest(address _wallet, uint256 _IdMortgage)
        external
        view
        returns (MortgageInterest memory mortgageInterest)
    {
        mortgageInterest = userToMortgageInterest[_wallet][_IdMortgage];
    }

    /// @dev Function to get the Id Mortgages opens for a wallet
    function getMortgagesForWallet(address _wallet, address _collection)
        external
        view
        returns (uint256[] memory _idMortgagesForCollection)
    {
        uint24 counter = 0;
        for (uint24 i = 1; i <= mortgageId;) {
            if (idInfo[i] == _wallet) {
                ++counter;
            }
            unchecked {
                ++i;
            }
        }
        uint256 _index = 0;
        _idMortgagesForCollection = new uint256[](counter);
        for (uint256 f = 1; f <= mortgageId;) {
            if (idInfo[f] == _wallet) {
                (address collection,,,,,,,,,,,) = getUserInfo(_wallet, f);
                if (_collection == collection) {
                    _idMortgagesForCollection[_index] = f;
                    ++_index;
                }
            }
            unchecked {
                ++f;
            }
        }
        return _idMortgagesForCollection;
    }

    // ********************** SETTERS FUNCTIONS ************************ //

    function addIdInfo(uint256 id, address wallet) external onlymortgage {
        idInfo[id] = wallet;
        ++mortgageId;
    }

    function addMortgageId(address _collection, uint256 _nftId, uint256 _loanId) external onlymortgage {
        dataID[_collection][_nftId] = _loanId;
    }

    function eraseMortgageId(address _collection, uint256 _nftId) external onlymortgage {
        dataID[_collection][_nftId] = 0;
    }

    function addRegistry(
        uint256 id,
        address wallet,
        address _collection,
        address _wrapContract,
        uint256 _nftId,
        uint256 _loan,
        uint256 _downPay,
        uint256 _price,
        uint256 _startDate,
        uint256 _period
    ) external onlymortgage {
        uint256 _capitalPay = _loan / (_period * 30);
        usermortgage[wallet][id].collection = _collection;
        usermortgage[wallet][id].nftId = _nftId;
        usermortgage[wallet][id].wrapContract = _wrapContract;
        usermortgage[wallet][id].loan = _loan;
        usermortgage[wallet][id].downPay = _downPay;
        usermortgage[wallet][id].capitalPay = _capitalPay;
        usermortgage[wallet][id].price = _price;
        usermortgage[wallet][id].startDate = _startDate;
        usermortgage[wallet][id].period = _period;

        // Changes v2
        userToMortgageInterest[wallet][id].totalDebt = _loan;
        userToMortgageInterest[wallet][id].capitalDailyPay = _capitalPay;
    }

    /// @dev Function to save the initial data for Mortgages Interest Struct whe the user open a Mortgage.
    /// @param _id - The user Mortgage ID.
    // Changes v2
    function saveMortgageInterestData(
        uint256 _id,
        address _wallet,
        uint256 _DailyInt,
        uint256 _DailyPanoramInt,
        uint256 _DayRewardLenderInt,
        uint256 _DelayedIntDaily,
        uint256 _DelayedIntPanoramDaily,
        uint256 _DelayedIntRewLender
    ) external onlymortgage {
        // Changes v2
        userToMortgageInterest[_wallet][_id].interestDailyPay = _DailyInt;
        userToMortgageInterest[_wallet][_id].interestPanoramDaily = _DailyPanoramInt;
        userToMortgageInterest[_wallet][_id].interestRewardLender = _DayRewardLenderInt;
        userToMortgageInterest[_wallet][_id].lateInterestDaily = _DelayedIntDaily;
        userToMortgageInterest[_wallet][_id].lateInterestPanoramDaily = _DelayedIntPanoramDaily;
        userToMortgageInterest[_wallet][_id].lateInterestRewardLender = _DelayedIntRewLender;
    }

    function updateCapitalPay(uint256 id, address wallet, uint256 _newDebt) external onlymortgage {
        usermortgage[wallet][id].capitalPay = _newDebt;
        userToMortgageInterest[wallet][id].capitalDailyPay = _newDebt;
    }

    function updateMortgageState(uint256 id, address wallet, bool _state) external onlymortgage {
        usermortgage[wallet][id].isPay = _state;
    }

    function updateMortgagePayment(uint256 id, address wallet) external onlymortgage {
        usermortgage[wallet][id].payCounter = usermortgage[wallet][id].payCounter + 1;
    }

    function updateSoldAtAuction(uint256 id, address wallet, bool _state) external onlymortgage {
        userToMortgageInterest[wallet][id].soldAtAuction = _state;
    }

    /// @dev Function to update the amount of delayed mortgages for the user: _wallet in the collection: _collection
    function reduceDelayedMortgages(address _wallet, address _collection) external onlymortgage {
        if (delayedMortgages[_wallet][_collection] > 0) {
            // solo si es mayor a cero lo restamos
            delayedMortgages[_wallet][_collection] -= 1;
        }
    }

    function resetRentRetained(address _user, address _collection, uint256 _mortgageID) external onlymortgage {
        rentsRetained[_user][_collection][_mortgageID] = 0;
    }

    // Changes v2
    /// @dev Function to reset the strikes when the user make a mortgage payment.
    /// @param _id - the user's mortgage ID.
    /// @param _user - the user's address wallet.
    function resetStrikes(uint256 _id, address _user) external onlymortgage {
        userToMortgageInterest[_user][_id].strikes = 0;
    }

    /// @dev Function to update the Mortgage's strikes and the payment status from the Relayer.
    /// @param _idMortgage - the user's mortgage ID.
    /// @param _user - the user's address wallet.
    /// @return liquidated - true if the Mortgage has been liquidated.
    /// @return amountLiquidated - the Retained rent amount of the mortgage Liquidate.
    function updateStrikes(uint256 _idMortgage, address _user, uint256 _payPerNFT, address collection)
        external
        onlymortgage
        returns (bool liquidated, uint256 amountLiquidated)
    {
        userToMortgageInterest[_user][_idMortgage].strikes += 1;

        uint8 strikes = userToMortgageInterest[_user][_idMortgage].strikes;

        if (strikes == 30) {
            // ya que es necesario que el autotask de rentas se ejecute antes que el de update strikes para obtener el PPnft, se debe subir a delayed las hipotecas que
            // vayan en el dia 30 para asi cuando se calculen las rentas del 31 ya se tenga actualizado que esa hipoteca cayo en mora el dia de hoy a las 0hrs pero los
            // strikes se actualizan despues del calculo de rentas.
            // Cuando el usuario paga una hipoteca se resta  del mapping de los delayedMortgages que cuenta las hipotecas en mora.
            delayedMortgages[_user][collection] += 1;
        } else if (strikes == 31) {
            userToMortgageInterest[_user][_idMortgage].isMonthlyPaymentDelayed = true;
            rentsRetained[_user][collection][_idMortgage] += _payPerNFT;
        } else if (strikes > 31 && strikes < 61) {
            rentsRetained[_user][collection][_idMortgage] += _payPerNFT;
        } else if (strikes == 61) {
            delayedMortgages[_user][collection] -= 1;
            rentsRetained[_user][collection][_idMortgage] += _payPerNFT; // como ya se calculo la renta de este dia, se agrega a rents retained
            liquidated = userToMortgageInterest[_user][_idMortgage].liquidate = true;
            amountLiquidated = rentsRetained[_user][collection][_idMortgage];
        }
    }

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestLendersPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountLenders)
        external
        onlymortgage
    {
        userToMortgageInterest[_user][_idMortgage].interestLendersPaid = _amountLenders;
    }

    /// @dev Function to set the interest amount paid to Lenders with the retained rents when the user is liquidated.
    function setInterestPanoramPaidOnLiquidation(uint256 _idMortgage, address _user, uint256 _amountPanoram)
        external
        onlymortgage
    {
        userToMortgageInterest[_user][_idMortgage].interestPanoramPaid = _amountPanoram;
    }

    function resetDebt(address _wallet, uint256 _idMortgage) external onlymortgage {
        userToMortgageInterest[_wallet][_idMortgage].totalDebt = 0;
    }

    function updateTotalDebt(address _wallet, uint256 _idMortgage, uint256 _totalDebt) external onlymortgage {
        userToMortgageInterest[_wallet][_idMortgage].totalDebt = _totalDebt;
    }

    function updateMonthlyPaymentDelayed(address _wallet, uint256 _idMortgage, bool _state) external onlymortgage {
        userToMortgageInterest[_wallet][_idMortgage].isMonthlyPaymentDelayed = _state;
    }

    function updateLastTimePayment(address _wallet, uint256 _idMortgage, uint256 _lastPayment) external onlymortgage {
        userToMortgageInterest[_wallet][_idMortgage].lastTimePayment = _lastPayment;
    }

    function updateMortgageLink(
        uint256 oldId,
        uint256 newId,
        address wallet,
        uint256 _loan,
        uint256 _downPay,
        uint256 _startDate,
        uint256 _period,
        bool _mortageState
    ) external onlymortgage {
        LocalVars memory vars;
        usermortgage[wallet][oldId].mortgageAgain = _mortageState;
        usermortgage[wallet][oldId].linkId = newId;
        (vars._collection, vars._nftId, vars._wrapContract,,,,,,,,,) = getUserInfo(wallet, oldId);
        usermortgage[wallet][newId].collection = vars._collection;
        usermortgage[wallet][newId].nftId = vars._nftId;
        usermortgage[wallet][newId].wrapContract = vars._wrapContract;
        usermortgage[wallet][newId].loan = _loan;
        usermortgage[wallet][newId].downPay = _downPay;
        usermortgage[wallet][newId].startDate = _startDate;
        usermortgage[wallet][newId].period = _period;
        usermortgage[wallet][newId].linkId = oldId;
    }

    function setInterestRate(uint64 _interest) external onlyDev {
        interest = _interest;
    }

    function setMortgageContract(address _mortgage, bool _state) public onlyDev {
        mortgage[_mortgage] = _state;
    }

    /// **************  @dev Functions to migrate the data from an old mortgage control contract **************

    modifier onlyMigrate() {
        if (flag == true) {
            revert("Function disable");
        }
        _;
    }

    function updateFlag() external onlyDev {
        flag = true;
    }

    // enviar los nuevos campos calculador en el contrato de migracion.
    function migrateMortgateInterest(address _wallet, uint256 _IdMortgage, MortgageInterest calldata mort)
        external
        onlyMigrate
        onlymortgage
    {
        userToMortgageInterest[_wallet][_IdMortgage] = mort;
    }

    function migrateMortgateDebt(address _wallet, uint256 _IdMortgage, Information calldata _debt)
        external
        onlyMigrate
        onlymortgage
    {
        usermortgage[_wallet][_IdMortgage] = _debt;
    }
}

// SPDX-License-Identifier: Panoram Finance LLC. All Rights Reserved.

// Smart Contract v2.0.0 - (May 9, 2023).

// Changes v2

pragma solidity 0.8.16;

interface IMortgageInterest {
    struct MortgageInterest {
        uint256 totalDebt; // para guardar lo que adeuda el cliente despues de cada pago
        uint256 capitalDailyPay; // pago de capital diario
        uint256 interestDailyPay; // pago total de intereses diarios.
        uint256 interestPanoramDaily; // intereses diarios a pagar a panoram.
        uint256 interestRewardLender; // intereses diarios a pagar al vault de Rewards Lenders.
        uint256 lateInterestDaily; // pago total de intereses moratorios diarios.
        uint256 lateInterestPanoramDaily; // intereses moratorios diarios a pagar a panoram.
        uint256 lateInterestRewardLender; // intereses moratorios diarios a pagar al vault de Rewards Lenders.
        uint256 lastTimePayment; // guardamos la fecha de su ultimo pago para calcular el siguiente pago desde esta fecha
        uint256 interestLendersPaid; // cantidad pagada con las rentas retenidas de los intereses para lenders, al momento de la liquidacion.
        uint256 interestPanoramPaid; // cantidad pagada con las rentas retenidas de los intereses de Panoram, al momento de la liquidacion.
        uint8 strikes; // cuando sean 2 se pasa a liquidacion. Resetear estas variables cuando se haga el pago
        bool isMonthlyPaymentDelayed; // validar si el pago es moratorio
        bool liquidate; // true si el credito se liquido, se liquida cuando el user tiene 3 meses sin pagar
        bool soldAtAuction; // true cuando la hipoteca se vendio y pago en una Subasta por liquidacion.
    }

    ///@notice structure and mapping that keeps track of mortgage
    struct Information {
        address collection;
        uint256 nftId;
        address wrapContract;
        uint256 loan; // total prestado
        uint256 downPay;
        uint256 capitalPay;
        uint256 price;
        uint256 startDate;
        uint256 period; //months
        uint256 payCounter; //Start in zero
        bool isPay; //default is false
        bool mortgageAgain; //default is false
        uint256 linkId; //link to the new mortgage
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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