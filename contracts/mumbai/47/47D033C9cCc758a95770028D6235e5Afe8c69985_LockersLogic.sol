// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "../oracle/interfaces/IPriceOracle.sol";
import "../connectors/interfaces/IExchangeConnector.sol";
import "../erc20/interfaces/ITeleBTC.sol";
import "../routers/interfaces/ICCBurnRouter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILockers.sol";
import "../libraries/LockersLib.sol";
import "./LockersStorageStructure.sol";

contract LockersLogic is LockersStorageStructure, ILockers, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    using LockersLib for *;
    using SafeERC20 for IERC20;
   
    function initialize(
        address _teleBTC,
        address _TeleportDAOToken,
        address _exchangeConnector,
        address _priceOracle,
        address _ccBurnRouter,
        uint _minRequiredTDTLockedAmount,
        uint _minRequiredTNTLockedAmount,
        uint _collateralRatio,
        uint _liquidationRatio,
        uint _lockerPercentageFee,
        uint _priceWithDiscountRatio
    ) public initializer {

        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();

        require(
            _minRequiredTNTLockedAmount != 0,
            "Lockers: amount is zero"
        );

        _setTeleportDAOToken(_TeleportDAOToken);
        _setTeleBTC(_teleBTC);
        _setCCBurnRouter(_ccBurnRouter);
        _setExchangeConnector(_exchangeConnector);
        _setPriceOracle(_priceOracle);
        _setMinRequiredTDTLockedAmount(_minRequiredTDTLockedAmount);
        _setMinRequiredTNTLockedAmount(_minRequiredTNTLockedAmount);
        _setCollateralRatio(_collateralRatio);
        _setLiquidationRatio(_liquidationRatio);
        _setLockerPercentageFee(_lockerPercentageFee);
        _setPriceWithDiscountRatio(_priceWithDiscountRatio);

        libConstants.OneHundredPercent = ONE_HUNDRED_PERCENT;
        libConstants.HealthFactor = HEALTH_FACTOR;
        libConstants.UpperHealthFactor = UPPER_HEALTH_FACTOR;
        libConstants.MaxLockerFee = MAX_LOCKER_FEE;
        libConstants.NativeTokenDecimal = NATIVE_TOKEN_DECIMAL;
        libConstants.NativeToken = NATIVE_TOKEN;

    }

    // *************** Modifiers ***************

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Lockers: address is zero");
        _;
    }

    modifier nonZeroValue(uint _value) {
        require(_value > 0, "Lockers: value is zero");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "Lockers: only minters can mint");
        _;
    }

    // *************** External functions ***************

    /**
     * @dev Give an account access to mint.
     */
    function addMinter(address _account) external override nonZeroAddress(_account) onlyOwner {
        require(!isMinter(_account), "Lockers: account already has role");
        minters[_account] = true;
        emit MinterAdded(_account);
    }

    /**
     * @dev Remove an account's access to mint.
     */
    function removeMinter(address _account) external override nonZeroAddress(_account) onlyOwner {
        require(isMinter(_account), "Lockers: account does not have role");
        minters[_account] = false;
        emit MinterRemoved(_account);
    }

    modifier onlyBurner() {
        require(isBurner(_msgSender()), "Lockers: only burners can burn");
        _;
    }

    /**
     * @dev Give an account access to burn.
     */
    function addBurner(address _account) external override nonZeroAddress(_account) onlyOwner {
        require(!isBurner(_account), "Lockers: account already has role");
        burners[_account] = true;
        emit BurnerAdded(_account);
    }

    /**
     * @dev Remove an account's access to burn.
     */
    function removeBurner(address _account) external override nonZeroAddress(_account) onlyOwner {
        require(isBurner(_account), "Lockers: account does not have role");
        burners[_account] = false;
        emit BurnerRemoved(_account);
    }

    /// @notice                 Pause the locker, so only the functions can be called which are whenPaused
    /// @dev                    Only owner can pause 
    function pauseLocker() external override onlyOwner {
        _pause();
    }

    /// @notice                 Un-pause the locker, so only the functions can be called which are whenNotPaused
    /// @dev                    Only owner can pause
    function unPauseLocker() external override onlyOwner {
        _unpause();
    }

    function getLockerTargetAddress(bytes calldata  _lockerLockingScript) external view override returns (address) {
        return lockerTargetAddress[_lockerLockingScript];
    }

    /// @notice                           Checks whether a locking script is locker
    /// @param _lockerLockingScript       Locking script of locker on the target chain
    /// @return                           True if a locking script is locker
    function isLocker(bytes calldata _lockerLockingScript) external override view returns(bool) {
        return lockersMapping[lockerTargetAddress[_lockerLockingScript]].isLocker;
    }

    /// @notice                           Give number of lockers
    /// @return                           Number of lockers
    function getNumberOfLockers() external override view returns (uint) {
        return totalNumberOfLockers;
    }

    /// @notice                             Give Bitcoin public key of locker
    /// @param _lockerTargetAddress         Address of locker on the target chain
    /// @return                             Bitcoin public key of locker
    function getLockerLockingScript(
        address _lockerTargetAddress
    ) external override view nonZeroAddress(_lockerTargetAddress) returns (bytes memory) {
        return lockersMapping[_lockerTargetAddress].lockerLockingScript;
    }

    /// @notice                       Changes teleportDAO token in lockers 
    /// @dev                          Only current owner can call this
    /// @param _tdtTokenAddress       The new teleportDAO token address
    function setTeleportDAOToken(address _tdtTokenAddress) external override onlyOwner {
        _setTeleportDAOToken(_tdtTokenAddress);
    }

    /// @notice                       Changes percentage fee of locker
    /// @dev                          Only current owner can call this
    /// @param _lockerPercentageFee   The new locker percentage fee
    function setLockerPercentageFee(uint _lockerPercentageFee) external override onlyOwner {
        _setLockerPercentageFee(_lockerPercentageFee);
    }

    /// @notice                          Changes price with discount ratio
    /// @dev                             Only current owner can call this
    /// @param _priceWithDiscountRatio   The new price with discount ratioo
    function setPriceWithDiscountRatio(uint _priceWithDiscountRatio) external override onlyOwner {
        _setPriceWithDiscountRatio(_priceWithDiscountRatio);
    }

    /// @notice         Changes the required TDT token bond amount to become locker
    /// @dev            Only current owner can call this
    /// @param _minRequiredTDTLockedAmount   The new required TDT token bond amount
    function setMinRequiredTDTLockedAmount(uint _minRequiredTDTLockedAmount) external override onlyOwner {
        _setMinRequiredTDTLockedAmount(_minRequiredTDTLockedAmount);
    }

    /// @notice         Changes the required native token bond amount to become locker
    /// @dev            Only current owner can call this
    ///                 It should be a non-zero value
    /// @param _minRequiredTNTLockedAmount   The new required native token bond amount
    function setMinRequiredTNTLockedAmount(uint _minRequiredTNTLockedAmount) external override onlyOwner {
        _setMinRequiredTNTLockedAmount(_minRequiredTNTLockedAmount);
    }

    /// @notice                 Changes the price oracle
    /// @dev                    Only current owner can call this
    /// @param _priceOracle     The new price oracle
    function setPriceOracle(address _priceOracle) external override nonZeroAddress(_priceOracle) onlyOwner {
        _setPriceOracle(_priceOracle);
    }

    /// @notice                Changes cc burn router contract
    /// @dev                   Only current owner can call this
    /// @param _ccBurnRouter   The new cc burn router contract address
    function setCCBurnRouter(address _ccBurnRouter) external override nonZeroAddress(_ccBurnRouter) onlyOwner {
        _setCCBurnRouter(_ccBurnRouter);
    }

    /// @notice                    Changes exchange connector contract address
    /// @dev                       Only owner can call this
    /// @param _exchangeConnector  The new exchange router contract address
    function setExchangeConnector(address _exchangeConnector) external override nonZeroAddress(_exchangeConnector) onlyOwner {
        _setExchangeConnector(_exchangeConnector);
    }

    /// @notice                 Changes wrapped token contract address
    /// @dev                    Only owner can call this
    /// @param _teleBTC         The new wrapped token contract address
    function setTeleBTC(address _teleBTC) external override nonZeroAddress(_teleBTC) onlyOwner {
        _setTeleBTC(_teleBTC);
    }

    /// @notice                     Changes collateral ratio
    /// @dev                        Only owner can call this
    /// @param _collateralRatio     The new collateral ratio
    function setCollateralRatio(uint _collateralRatio) external override onlyOwner {
        _setCollateralRatio(_collateralRatio);
    }

    /// @notice                     Changes liquidation ratio
    /// @dev                        Only owner can call this
    /// @param _liquidationRatio    The new liquidation ratio
    function setLiquidationRatio(uint _liquidationRatio) external override onlyOwner { 
        _setLiquidationRatio(_liquidationRatio);
    }

    /// @notice                                 Adds user to candidates list
    /// @dev                                    Users mint TeleBTC by sending BTC to locker's locking script
    ///                                         In case of liqudation of locker's bond, the burn TeleBTC is sent to
    ///                                         locker's rescue script
    ///                                         A user should lock enough TDT and TNT to become candidate
    /// @param _candidateLockingScript          Locking script of the candidate
    /// @param _lockedTDTAmount                 Bond amount of locker in TDT
    /// @param _lockedNativeTokenAmount         Bond amount of locker in native token of the target chain
    /// @param _lockerRescueType                Type of locker's rescue script (e.g. P2SH)
    /// @param _lockerRescueScript              Rescue script of the locker
    /// @return                                 True if candidate is added successfully
    function requestToBecomeLocker(
        bytes calldata _candidateLockingScript,
        uint _lockedTDTAmount,
        uint _lockedNativeTokenAmount,
        ScriptTypes _lockerRescueType,
        bytes calldata _lockerRescueScript
    ) external override payable nonReentrant returns (bool) {

        LockersLib.requestToBecomeLockerValidation(
                lockersMapping,
                libParams,
                lockerTargetAddress[_candidateLockingScript],
                _lockedTDTAmount,
                _lockedNativeTokenAmount
            );
        
        IERC20(libParams.teleportDAOToken).safeTransferFrom(_msgSender(), address(this), _lockedTDTAmount);

        totalNumberOfCandidates = totalNumberOfCandidates + 1;

        LockersLib.requestToBecomeLocker(
                lockersMapping,
                _candidateLockingScript,
                _lockedTDTAmount,
                _lockedNativeTokenAmount,
                _lockerRescueType,
                _lockerRescueScript
            );

        emit RequestAddLocker(
            _msgSender(),
            _candidateLockingScript,
            _lockedTDTAmount,
            _lockedNativeTokenAmount
        );

        return true;
    }

    /// @notice                       Removes a candidate from candidates list
    /// @dev                          A user who is still a candidate can revoke his/her request
    /// @return                       True if candidate is removed successfully
    function revokeRequest() external override nonReentrant returns (bool) {

        require(
            lockersMapping[_msgSender()].isCandidate,
            "Lockers: no req"
        );

        // Loads locker's information
        DataTypes.locker memory lockerRequest = lockersMapping[_msgSender()];

        // Removes candidate from lockersMapping
        delete lockersMapping[_msgSender()];
        totalNumberOfCandidates = totalNumberOfCandidates -1;

        // Sends back TDT and TNT collateral
        IERC20(TeleportDAOToken).safeTransfer(_msgSender(), lockerRequest.TDTLockedAmount);
        Address.sendValue(payable(_msgSender()), lockerRequest.nativeTokenLockedAmount);

        emit RevokeAddLockerRequest(
            _msgSender(),
            lockersMapping[_msgSender()].lockerLockingScript,
            lockersMapping[_msgSender()].TDTLockedAmount,
            lockersMapping[_msgSender()].nativeTokenLockedAmount
        );

        return true;
    }

    /// @notice                               Approves a candidate request to become locker
    /// @dev                                  Only owner can call this
    ///                                       When a candidate becomes locker, isCandidate is set to false
    /// @param _lockerTargetAddress           Locker's target chain address
    /// @return                               True if candidate is added successfully
    function addLocker(
        address _lockerTargetAddress
    ) external override nonZeroAddress(_lockerTargetAddress) nonReentrant onlyOwner returns (bool) {

        require(
            lockersMapping[_lockerTargetAddress].isCandidate,
            "Lockers: no request"
        );

        // Updates locker's status
        lockersMapping[_lockerTargetAddress].isCandidate = false;
        lockersMapping[_lockerTargetAddress].isLocker = true;

        // Updates number of candidates and lockers
        totalNumberOfCandidates = totalNumberOfCandidates -1;
        totalNumberOfLockers = totalNumberOfLockers + 1;

        lockerTargetAddress[lockersMapping[_lockerTargetAddress].lockerLockingScript] = _lockerTargetAddress;

        emit LockerAdded(
            _lockerTargetAddress,
            lockersMapping[_lockerTargetAddress].lockerLockingScript,
            lockersMapping[_lockerTargetAddress].TDTLockedAmount,
            lockersMapping[_lockerTargetAddress].nativeTokenLockedAmount,
            block.timestamp
        );
        return true;
    }

    /// @notice                Requests to inactivate a locker
    /// @dev                   Deactivates the locker so that no one can mint by this locker:
    ///                        1. Locker can be removed after inactivation
    ///                        2. Locker can withdraw extra collateral after inactivation
    /// @return                True if deactivated successfully
    function requestInactivation() external override nonReentrant returns (bool) {
        require(
            lockersMapping[_msgSender()].isLocker,
            "Lockers: input address is not a valid locker"
        );

        require(
            lockerInactivationTimestamp[_msgSender()] == 0,
            "Lockers: locker has already requested"
        );

        lockerInactivationTimestamp[_msgSender()] = block.timestamp + INACTIVATION_DELAY;

        emit RequestInactivateLocker(
            _msgSender(),
            lockerInactivationTimestamp[_msgSender()],
            lockersMapping[_msgSender()].lockerLockingScript,
            lockersMapping[_msgSender()].TDTLockedAmount,
            lockersMapping[_msgSender()].nativeTokenLockedAmount,
            lockersMapping[_msgSender()].netMinted
        );

        return true;
    }

    /// @notice                Requests to activate a locker
    /// @dev                   Activates the locker so users can mint by this locker
    ///                        note: lockerInactivationTimestamp == 0 means that the locker is active
    /// @return                True if activated successfully
    function requestActivation() external override nonReentrant returns (bool) {
        require(
            lockersMapping[_msgSender()].isLocker,
            "Lockers: input address is not a valid locker"
        );

        lockerInactivationTimestamp[_msgSender()] = 0;

        emit ActivateLocker(
            _msgSender(),
            lockersMapping[_msgSender()].lockerLockingScript,
            lockersMapping[_msgSender()].TDTLockedAmount,
            lockersMapping[_msgSender()].nativeTokenLockedAmount,
            lockersMapping[_msgSender()].netMinted
        );

        return true;
    }

    /// @notice                       Removes a locker from lockers list
    /// @dev                          Only locker can call this function
    /// @return                       True if locker is removed successfully
    function selfRemoveLocker() external override nonReentrant returns (bool) {
        _removeLocker(_msgSender());
        return true;
    }

    /// @notice                           Slashes lockers for not executing a cc burn req
    /// @dev                              Only cc burn router can call this
    ///                                   Locker is slashed since doesn't provide burn proof
    ///                                   before a cc burn request deadline.
    ///                                   User who made the cc burn request will receive the slashed bond
    /// @param _lockerTargetAddress       Locker's target chain address
    /// @param _rewardAmount              Amount of TeleBTC that slasher receives
    /// @param _rewardRecipient           Address of slasher who receives reward
    /// @param _amount                    Amount of TeleBTC that is slashed from lockers
    /// @param _recipient                 Address of user who receives the slashed amount
    /// @return                           True if the locker is slashed successfully
    function slashIdleLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount,
        address _recipient
    ) external override nonReentrant whenNotPaused returns (bool) {
        require(
            _msgSender() == ccBurnRouter,
            "Lockers: message sender is not ccBurn"
        );

        uint equivalentNativeToken = LockersLib.slashIdleLocker(
            lockersMapping[_lockerTargetAddress],
            libConstants,
            libParams,
            _rewardAmount,
            _amount
        );

        // Transfers TNT to user
        payable(_recipient).transfer(equivalentNativeToken*_amount/(_amount + _rewardAmount));
        // Transfers TNT to slasher
        uint rewardAmountInNativeToken = equivalentNativeToken - (equivalentNativeToken*_amount/(_amount + _rewardAmount));
        payable(_rewardRecipient).transfer(rewardAmountInNativeToken);

        emit LockerSlashed(
            _lockerTargetAddress,
            rewardAmountInNativeToken,
            _rewardRecipient,
            _amount,
            _recipient,
            equivalentNativeToken,
            block.timestamp,
            true
        );

        return true;
    }


    /// @notice                           Slashes lockers for moving BTC without a good reason
    /// @dev                              Only cc burn router can call this
    ///                                   Locker is slashed because he/she moved BTC from 
    ///                                   locker's Bitcoin address without any corresponding burn req
    ///                                   The slashed bond will be sold with discount
    /// @param _lockerTargetAddress       Locker's target chain address
    /// @param _rewardAmount              Value of slashed reward (in TeleBTC)
    /// @param _rewardRecipient           Address of slasher who receives reward
    /// @param _amount                    Value of slashed collateral (in TeleBTC)
    /// @return                           True if the locker is slashed successfully
    function slashThiefLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount
    ) external override nonReentrant whenNotPaused returns (bool) {
        require(
            _msgSender() == ccBurnRouter,
            "Lockers: message sender is not ccBurn"
        );

        (uint rewardInNativeToken, uint neededNativeTokenForSlash) = LockersLib.slashThiefLocker(
            lockersMapping[_lockerTargetAddress],
            libConstants,
            libParams,
            _rewardAmount,
            _amount
        );

        payable(_rewardRecipient).transfer(rewardInNativeToken);

        emit LockerSlashed(
            _lockerTargetAddress,
            rewardInNativeToken,
            _rewardRecipient,
            _amount,
            address(this),
            neededNativeTokenForSlash + rewardInNativeToken,
            block.timestamp,
            false
        );

        return true;
    }

    /// @notice                           Liquidates the locker whose collateral is unhealthy
    /// @dev                              Anyone can liquidate a locker whose health factor
    ///                                   is less than 10000 (100%) by providing a sufficient amount of teleBTC
    /// @param _lockerTargetAddress       Locker's target chain address
    /// @param _collateralAmount          Amount of collateral (TNT) that someone intends to buy with discount
    /// @return                           True if liquidation was successful
    function liquidateLocker(
        address _lockerTargetAddress,
        uint _collateralAmount
    ) external override nonZeroAddress(_lockerTargetAddress) nonZeroValue(_collateralAmount)
    nonReentrant whenNotPaused returns (bool) {

        uint neededTeleBTC = LockersLib.liquidateLocker(
            lockersMapping[_lockerTargetAddress],
            libConstants,
            libParams,
            _collateralAmount
        );

        DataTypes.locker memory theLiquidatingLocker = lockersMapping[_lockerTargetAddress];

        // Updates TNT bond of locker
        lockersMapping[_lockerTargetAddress].nativeTokenLockedAmount = 
            lockersMapping[_lockerTargetAddress].nativeTokenLockedAmount - _collateralAmount;

        // transfer teleBTC from user
        IERC20(teleBTC).safeTransferFrom(msg.sender, address(this), neededTeleBTC);

        // Burns TeleBTC for locker rescue script
        IERC20(teleBTC).approve(ccBurnRouter, neededTeleBTC);
        ICCBurnRouter(ccBurnRouter).ccBurn(
            neededTeleBTC,
            theLiquidatingLocker.lockerRescueScript,
            theLiquidatingLocker.lockerRescueType,
            theLiquidatingLocker.lockerLockingScript
        );

        Address.sendValue(payable(_msgSender()), _collateralAmount);

        emit LockerLiquidated(
            _lockerTargetAddress,
            _msgSender(),
            _collateralAmount,
            neededTeleBTC,
            block.timestamp
        );

        return true;
    }

    /// @notice                           Sells lockers slashed collateral
    /// @dev                              Users buy the slashed collateral using TeleBTC with discount
    ///                                   The paid TeleBTC will be burnt to keep the system safe
    ///                                   If all the needed TeleBTC is collected and burnt,
    ///                                   the rest of slashed collateral is sent back to locker 
    /// @param _lockerTargetAddress       Locker's target chain address
    /// @param _collateralAmount          Amount of collateral (TNT) that someone intends to buy with discount
    /// @return                           True if buying was successful
    function buySlashedCollateralOfLocker(
        address _lockerTargetAddress,
        uint _collateralAmount
    ) external nonZeroAddress(_lockerTargetAddress)
        nonReentrant whenNotPaused override returns (bool) {

        uint neededTeleBTC = LockersLib.buySlashedCollateralOfLocker(
            lockersMapping[_lockerTargetAddress],
            libConstants,
            libParams,
            _collateralAmount
        );

        // Burns user's TeleBTC
        ITeleBTC(teleBTC).transferFrom(_msgSender(), address(this), neededTeleBTC);
        ITeleBTC(teleBTC).burn(neededTeleBTC);
        
        // Sends bought collateral to user
        Address.sendValue(payable(_msgSender()), _collateralAmount);

        emit LockerSlashedCollateralSold(
            _lockerTargetAddress,
            _msgSender(),
            _collateralAmount,
            neededTeleBTC,
            block.timestamp
        );

        return true;
    }


    /// @notice                                 Increases TNT collateral of the locker
    /// @param _lockerTargetAddress             Locker's target chain address
    /// @param _addingNativeTokenAmount         Amount of added collateral
    /// @return                                 True if collateral is added successfully
    function addCollateral(
        address _lockerTargetAddress,
        uint _addingNativeTokenAmount
    ) external override payable nonReentrant returns (bool) {

        require(
            msg.value == _addingNativeTokenAmount,
            "Lockers: msg value"
        );

        LockersLib.addToCollateral(
            lockersMapping[_lockerTargetAddress],
            _addingNativeTokenAmount
        );

        emit CollateralAdded(
            _lockerTargetAddress,
            _addingNativeTokenAmount,
            lockersMapping[_lockerTargetAddress].nativeTokenLockedAmount,
            block.timestamp
        );

        return true;
    }

    /// @notice                                 Decreases TNT collateral of the locker
    /// @param _removingNativeTokenAmount       Amount of removed collateral
    /// @return                                 True if collateral is removed successfully
    function removeCollateral(
        uint _removingNativeTokenAmount
    ) external override payable nonReentrant returns (bool) {

        require(
            lockersMapping[_msgSender()].isLocker,
            "Lockers: no locker"
        );

        require(
            !isLockerActive(_msgSender()),
            "Lockers: still active"
        );

        uint priceOfOnUnitOfCollateral = LockersLib.priceOfOneUnitOfCollateralInBTC(
            libConstants,
            libParams
        );

        LockersLib.removeFromCollateral(
            lockersMapping[_msgSender()],
            libConstants,
            libParams,
            priceOfOnUnitOfCollateral,
            _removingNativeTokenAmount
        );

        Address.sendValue(payable(_msgSender()), _removingNativeTokenAmount);

        emit CollateralRemoved(
            _msgSender(),
            _removingNativeTokenAmount,
            lockersMapping[_msgSender()].nativeTokenLockedAmount,
            block.timestamp
        );

        return true;
    }

    /// @notice                       Mint teleBTC for an account
    /// @dev                          Mint teleBTC for an account and the locker fee as well
    /// @param _lockerLockingScript   Locking script of a locker
    /// @param _receiver              Address of the receiver of the minted teleBTCs
    /// @param _amount                Amount of the teleBTC which is minted, including the locker's fee
    /// @return uint                  The amount of teleBTC minted for the receiver
    function mint(
        bytes calldata _lockerLockingScript,
        address _receiver,
        uint _amount
    ) external override nonZeroAddress(_receiver)
    nonZeroValue(_amount) nonReentrant whenNotPaused onlyMinter returns (uint) {

        address _lockerTargetAddress = lockerTargetAddress[_lockerLockingScript];

        uint theLockerCapacity = getLockerCapacity(_lockerTargetAddress);

        require(
            theLockerCapacity >= _amount,
            "Lockers: insufficient capacity"
        );

        require(
            isLockerActive(_lockerTargetAddress),
            "Lockers: not active"
        );

        lockersMapping[_lockerTargetAddress].netMinted = 
            lockersMapping[_lockerTargetAddress].netMinted + _amount;

        // Mints locker fee
        uint lockerFee = _amount*lockerPercentageFee/MAX_LOCKER_FEE;
        if (lockerFee > 0) {
            ITeleBTC(teleBTC).mint(_lockerTargetAddress, lockerFee);
        }

        // Mints tokens for receiver
        ITeleBTC(teleBTC).mint(_receiver, _amount - lockerFee);

        emit MintByLocker(
            _lockerTargetAddress,
            _receiver,
            _amount,
            lockerFee,
            block.timestamp
        );

        return _amount - lockerFee;
    }

    /// @notice                       Burn teleBTC of an account
    /// @dev                          Burn teleBTC and also get the locker's fee
    /// @param _lockerLockingScript   Locking script of a locker
    /// @param _amount                Amount of the teleBTC which is minted, including the locker's fee
    /// @return uint                  The amount of teleBTC burnt
    function burn(
        bytes calldata _lockerLockingScript,
        uint _amount
    ) external override nonZeroValue(_amount)
    nonReentrant whenNotPaused onlyBurner returns (uint) {

        address _lockerTargetAddress = lockerTargetAddress[_lockerLockingScript];

        // Transfers teleBTC from user
        ITeleBTC(teleBTC).transferFrom(_msgSender(), address(this), _amount);

        uint lockerFee = _amount*lockerPercentageFee/MAX_LOCKER_FEE;
        uint remainedAmount = _amount - lockerFee;
        uint netMinted = lockersMapping[_lockerTargetAddress].netMinted;

        require(
            netMinted >= remainedAmount,
            "Lockers: insufficient funds"
        );

        lockersMapping[_lockerTargetAddress].netMinted = netMinted - remainedAmount;

        // Burns teleBTC and sends rest of it to locker
        ITeleBTC(teleBTC).burn(remainedAmount);
        ITeleBTC(teleBTC).transfer(_lockerTargetAddress, lockerFee);

        emit BurnByLocker(
            _lockerTargetAddress,
            _amount,
            lockerFee,
            block.timestamp
        );

        return remainedAmount;
    }

    // *************** Public functions ***************
    
    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice                             Returns the Locker status
    /// @dev                                We check a locker status in below cases:
    ///                                     1. Minting TeleBTC
    ///                                     2. Removing locker's collateral
    ///                                     3. Removing locker 
    /// @param _lockerTargetAddress         Address of locker on the target chain
    /// @return                             True if the locker is active
    function isLockerActive(
        address _lockerTargetAddress
    ) public override view nonZeroAddress(_lockerTargetAddress) returns (bool) {
        if (lockerInactivationTimestamp[_lockerTargetAddress] == 0) {
            return true;
        } else if (lockerInactivationTimestamp[_lockerTargetAddress] > block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice                             Get how much the locker can mint
    /// @dev                                Net minted amount is total minted minus total burnt for the locker
    /// @param _lockerTargetAddress         Address of locker on the target chain
    /// @return                             The net minted of the locker
    function getLockerCapacity(
        address _lockerTargetAddress
    ) public override view nonZeroAddress(_lockerTargetAddress) returns (uint) {
        uint _lockerCollateralInTeleBTC = LockersLib.lockerCollateralInTeleBTC(
            lockersMapping[_lockerTargetAddress],
            libConstants,
            libParams
        )*ONE_HUNDRED_PERCENT/collateralRatio;

        if (_lockerCollateralInTeleBTC > lockersMapping[_lockerTargetAddress].netMinted) {
            return _lockerCollateralInTeleBTC - lockersMapping[_lockerTargetAddress].netMinted;
        } else {
            return 0;
        }
    }

    /**
     * @dev         Returns the price of one native token (1*10^18) in teleBTC
     * @return uint The price of one unit of collateral token (native token in teleBTC)
     */
    function priceOfOneUnitOfCollateralInBTC() public override view returns (uint) {

        return LockersLib.priceOfOneUnitOfCollateralInBTC(
            libConstants,
            libParams
        );

    }

    /// @notice                Check if an account is minter    
    /// @param  account        The account which intended to be checked
    /// @return bool
    function isMinter(address account) public override view nonZeroAddress(account) returns (bool) {
        return minters[account];
    }

    /// @notice                Check if an account is burner    
    /// @param  account        The account which intended to be checked
    /// @return bool
    function isBurner(address account) public override view nonZeroAddress(account) returns (bool) {
        return burners[account];
    }

    // *************** Private functions ***************

    /// @notice                       Removes a locker from lockers list
    /// @dev                          Checks that net minted TeleBTC of locker is zero
    ///                               Sends back available bond of locker (in TDT and TNT)
    /// @param _lockerTargetAddress   Target address of locker to be removed
    function _removeLocker(address _lockerTargetAddress) private {

        require(
            lockersMapping[_lockerTargetAddress].isLocker,
            "Lockers: no locker"
        );

        require(
            !isLockerActive(_lockerTargetAddress),
            "Lockers: still active"
        );

        require(
            lockersMapping[_lockerTargetAddress].netMinted == 0,
            "Lockers: 0 net minted"
        );

        require(
            lockersMapping[_lockerTargetAddress].slashingTeleBTCAmount == 0,
            "Lockers: 0 slashing TBTC"
        );

        DataTypes.locker memory _removingLocker = lockersMapping[_lockerTargetAddress];

        // Removes locker from lockersMapping

        delete lockerTargetAddress[lockersMapping[_lockerTargetAddress].lockerLockingScript];
        delete lockersMapping[_lockerTargetAddress];
        totalNumberOfLockers = totalNumberOfLockers - 1;

        // Sends back TDT and TNT collateral
        IERC20(TeleportDAOToken).safeTransfer(_lockerTargetAddress, _removingLocker.TDTLockedAmount);
        Address.sendValue(payable(_lockerTargetAddress), _removingLocker.nativeTokenLockedAmount);

        emit LockerRemoved(
            _lockerTargetAddress,
            _removingLocker.lockerLockingScript,
            _removingLocker.TDTLockedAmount,
            _removingLocker.nativeTokenLockedAmount
        );

    }

    /// @notice                     Internal setter for teleportDAO token of lockers
    /// @param _tdtTokenAddress     The new teleportDAO token address
    function _setTeleportDAOToken(address _tdtTokenAddress) private nonZeroAddress(_tdtTokenAddress) {
        emit NewTeleportDAOToken(TeleportDAOToken, _tdtTokenAddress);
        TeleportDAOToken = _tdtTokenAddress;
        libParams.teleportDAOToken = TeleportDAOToken;
    }

    /// @notice                       Internal setter for percentage fee of locker
    /// @param _lockerPercentageFee   The new locker percentage fee
    function _setLockerPercentageFee(uint _lockerPercentageFee) private {
        require(_lockerPercentageFee <= MAX_LOCKER_FEE, "Lockers: invalid locker fee");
        emit NewLockerPercentageFee(lockerPercentageFee, _lockerPercentageFee);
        lockerPercentageFee = _lockerPercentageFee;
        libParams.lockerPercentageFee = lockerPercentageFee;
    }

    function _setPriceWithDiscountRatio(uint _priceWithDiscountRatio) private {
        require(
            _priceWithDiscountRatio <= ONE_HUNDRED_PERCENT,
            "Lockers: less than 100%"
        );
        emit NewPriceWithDiscountRatio(priceWithDiscountRatio, _priceWithDiscountRatio);
        
        priceWithDiscountRatio= _priceWithDiscountRatio;
        libParams.priceWithDiscountRatio = priceWithDiscountRatio;
    }

    /// @notice         Internal setter for the required bond amount to become locker
    /// @param _minRequiredTDTLockedAmount   The new required bond amount
    function _setMinRequiredTDTLockedAmount(uint _minRequiredTDTLockedAmount) private {
        emit NewMinRequiredTDTLockedAmount(minRequiredTDTLockedAmount, _minRequiredTDTLockedAmount);
        minRequiredTDTLockedAmount = _minRequiredTDTLockedAmount;
        libParams.minRequiredTDTLockedAmount = minRequiredTDTLockedAmount;
    }

    /// @notice         Internal setter for the required bond amount to become locker
    /// @param _minRequiredTNTLockedAmount   The new required bond amount
    function _setMinRequiredTNTLockedAmount(uint _minRequiredTNTLockedAmount) private {
        require(
            _minRequiredTNTLockedAmount != 0,
            "Lockers: amount is zero"
        );
        emit NewMinRequiredTNTLockedAmount(minRequiredTNTLockedAmount, _minRequiredTNTLockedAmount);
        minRequiredTNTLockedAmount = _minRequiredTNTLockedAmount;
        libParams.minRequiredTNTLockedAmount = minRequiredTNTLockedAmount;
    }

    /// @notice                 Internal setter for the price oracle
    /// @param _priceOracle     The new price oracle
    function _setPriceOracle(address _priceOracle) private nonZeroAddress(_priceOracle) {
        emit NewPriceOracle(priceOracle, _priceOracle);
        priceOracle = _priceOracle;
        libParams.priceOracle = priceOracle;
    }

    /// @notice                Internal setter for cc burn router contract
    /// @param _ccBurnRouter   The new cc burn router contract address
    function _setCCBurnRouter(address _ccBurnRouter) private nonZeroAddress(_ccBurnRouter) {
        emit NewCCBurnRouter(ccBurnRouter, _ccBurnRouter);
        emit BurnerRemoved(ccBurnRouter);
        burners[ccBurnRouter] = false;
        ccBurnRouter = _ccBurnRouter;
        libParams.ccBurnRouter = ccBurnRouter;
        emit BurnerAdded(ccBurnRouter);
        burners[ccBurnRouter] = true;
    }

    /// @notice                 Internal setter for exchange router contract address and updates wrapped avax addresses
    /// @param _exchangeConnector  The new exchange router contract address
    function _setExchangeConnector(address _exchangeConnector) private nonZeroAddress(_exchangeConnector) {
        emit NewExchangeConnector(exchangeConnector, _exchangeConnector);
        exchangeConnector = _exchangeConnector;
        libParams.exchangeConnector = exchangeConnector;
    }

    /// @notice                 Internal setter for wrapped token contract address
    /// @param _teleBTC         The new wrapped token contract address
    function _setTeleBTC(address _teleBTC) private nonZeroAddress(_teleBTC) {
        emit NewTeleBTC(teleBTC, _teleBTC);
        teleBTC = _teleBTC;
        libParams.teleBTC = teleBTC;
    }

    /// @notice                     Internal setter for collateral ratio
    /// @param _collateralRatio     The new collateral ratio
    function _setCollateralRatio(uint _collateralRatio) private {
        require(_collateralRatio > liquidationRatio, "Lockers: must CR > LR");
        emit NewCollateralRatio(collateralRatio, _collateralRatio);
        collateralRatio = _collateralRatio;
        libParams.collateralRatio = collateralRatio;
    }

    /// @notice                     Internal setter for liquidation ratio
    /// @param _liquidationRatio    The new liquidation ratio
    function _setLiquidationRatio(uint _liquidationRatio) private {
        require(
            _liquidationRatio >= ONE_HUNDRED_PERCENT,
            "Lockers: problem in CR and LR"
        );
        require(
            collateralRatio > _liquidationRatio,
            "Lockers: must CR > LR"
        );
        emit NewLiquidationRatio(liquidationRatio, _liquidationRatio);
        liquidationRatio = _liquidationRatio;
        libParams.liquidationRatio = liquidationRatio;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IPriceOracle {

    /// @notice                     Emits when new exchange router is added
    /// @param exchangeRouter       Address of new exchange router
    /// @param exchangeConnector    Address of exchange connector
    event ExchangeConnectorAdded(address indexed exchangeRouter, address indexed exchangeConnector);

    /// @notice                     Emits when an exchange router is removed
    /// @param exchangeRouter       Address of removed exchange router
    event ExchangeConnectorRemoved(address indexed exchangeRouter);

    /// @notice                     Emits when a price proxy is set
    /// @param _token               Address of the token
    /// @param _priceProxyAddress   Address of price proxy contract
    event SetPriceProxy(address indexed _token, address indexed _priceProxyAddress);

    /// @notice                     Emits when changes made to acceptable delay
	event NewAcceptableDelay(uint oldAcceptableDelay, uint newAcceptableDelay);

    /// @notice                     Emits when changes made to oracle native token
	event NewOracleNativeToken(address indexed oldOracleNativeToken, address indexed newOracleNativeToken);

    // Read-only functions
    
    /// @notice                     Gives USD price proxy address for a token
    /// @param _token          Address of the token
    /// @return                     Address of price proxy contract
    function ChainlinkPriceProxy(address _token) external view returns (address);

    /// @notice                     Gives exchange connector address for an exchange router
    /// @param _exchangeRouter      Address of exchange router
    /// @return                     Address of exchange connector
    function exchangeConnector(address _exchangeRouter) external view returns (address);

    /// @notice                     Gives address of an exchange router from exchange routers list
    /// @param _index               Index of exchange router
    /// @return                     Address of exchange router
    function exchangeRoutersList(uint _index) external view returns (address);

    function getExchangeRoutersListLength() external view returns (uint);

    function acceptableDelay() external view returns (uint);

    function oracleNativeToken() external view returns (address);

    function equivalentOutputAmountByAverage(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmount(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmountFromOracle(
        uint _inputAmount,
        uint _inputDecimals,
        uint _outputDecimals,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);

    function equivalentOutputAmountFromExchange(
        address _exchangeRouter,
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (uint);
    
    // State-changing functions
    
    function addExchangeConnector(address _exchangeRouter, address _exchangeConnector) external;

    function removeExchangeConnector(uint _exchangeRouterIndex) external;

    function setPriceProxy(address _token, address _priceProxyAddress) external;

    function setAcceptableDelay(uint _acceptableDelay) external;

    function setOracleNativeToken(address _oracleNativeToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IExchangeConnector {

    // Events
    
    event Swap(address[] path, uint[] amounts, address receiver);

    // Read-only functions

    function name() external view returns (string memory);

    function exchangeRouter() external view returns (address);

    function liquidityPoolFactory() external view returns (address);

    function wrappedNativeToken() external view returns (address);

    function getInputAmount(
        uint _outputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    function getOutputAmount(
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    // State-changing functions

    function setExchangeRouter(address _exchangeRouter) external;

    function setLiquidityPoolFactory() external;

    function setWrappedNativeToken() external;

    function swap(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        address _to,
        uint256 _deadline,
        bool _isFixedToken
    ) external returns (bool, uint[] memory);

    function isPathValid(address[] memory _path) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITeleBTC is IERC20 {

    // Events
    event Mint(address indexed doer, address indexed receiver, uint value);

    event Burn(address indexed doer, address indexed burner, uint value);

    event MinterAdded(address indexed newMinter);

    event MinterRemoved(address indexed minter);

    event BurnerAdded(address indexed newBurner);

    event BurnerRemoved(address indexed burner);

    event NewMintLimit(uint oldMintLimit, uint newMintLimit);

    event NewEpochLength(uint oldEpochLength, uint newEpochLength);

    // read functions

    function decimals() external view returns (uint8);

    // state-changing functions

    function addMinter(address account) external;

    function removeMinter(address account) external;

    function addBurner(address account) external;

    function removeBurner(address account) external;

    function mint(address receiver, uint amount) external returns(bool);

    function burn(uint256 amount) external returns(bool);

    function setMaxMintLimit(uint _mintLimit) external;

    function setEpochLength(uint _length) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "../../types/ScriptTypesEnum.sol";

interface ICCBurnRouter {

	// Structures

    /// @notice                 	Structure for recording cc burn requests
    /// @param amount         		Amount of tokens that user wants to burn
    /// @param burntAmount   	    Amount that user will receive (after reducing fees from amount)
    /// @param sender       		Address of user who requests burning
    /// @param userScript    		Locking script of the user on Bitcoin
    /// @param deadline         	Deadline of locker for executing the request
    /// @param isTransferred    	True if the request has been executed
    /// @param scriptType    		The script type of the user (for bitcoin address)
    /// @param requestIdOfLocker    The index of the request for a specific locker
	struct burnRequest {
		uint amount;
		uint burntAmount;
		address sender;
		bytes userScript;
		uint deadline;
		bool isTransferred;
		ScriptTypes scriptType;
		uint requestIdOfLocker;
  	}

  	// Events

	/// @notice                 		Emits when a burn request gets submitted
    /// @param userTargetAddress        Target address of the user
    /// @param userScript        		Locking script of user on Bitcoin
    /// @param scriptType        		The script type of the user (for bitcoin address)
    /// @param amount         			Total requested amount
    /// @param burntAmount   		    Amount that user will receive (after reducing fees)
	/// @param lockerTargetAddress		Locker's address on the target chain
	/// @param lockerLockingScript		Locker's locking script on Bitcoin blockchain
    /// @param requestIdOfLocker        The index of a request for a locker
    /// @param deadline         		Deadline of locker for executing the request
  	event CCBurn(
		address indexed userTargetAddress,
		bytes userScript,
		ScriptTypes scriptType,
		uint amount, 
		uint burntAmount, 
		address indexed lockerTargetAddress,
		bytes lockerLockingScript,
		uint requestIdOfLocker,
		uint indexed deadline
	);

	/// @notice                 		Emits when a burn proof is provided
    /// @param lockerTargetAddress      Target address of the locker
    /// @param requestIdOfLocker        The index of a request of a locker
    /// @param bitcoinTxId   		    The bitcoin transaction hash
	/// @param bitcoinTxOutputIndex		The output index in the transaction
	event PaidCCBurn(
		address indexed lockerTargetAddress,
		uint requestIdOfLocker,
		bytes32 bitcoinTxId,
		uint bitcoinTxOutputIndex
	);

	/// @notice                 		Emits when a locker gets slashed for withdrawing BTC without proper reason
	/// @param _lockerTargetAddress		Locker's address on the target chain
	/// @param _blockNumber				Block number of the malicious tx
	/// @param txId						Transaction ID of the malicious tx
	/// @param amount					Slashed amount
	event LockerDispute(
        address _lockerTargetAddress,
		bytes lockerLockingScript,
    	uint _blockNumber,
        bytes32 txId,
		uint amount
    );

	event BurnDispute(
		address indexed userTargetAddress,
		address indexed _lockerTargetAddress,
		bytes lockerLockingScript,
		uint requestIdOfLocker
	);

	/// @notice                     	Emits when changes made to relay address
    event NewRelay(
        address oldRelay, 
        address newRelay
    );

	/// @notice                     	Emits when changes made to treasury address
    event NewTreasury(
        address oldTreasury, 
        address newTreasury
    );

	/// @notice                     	Emits when changes made to lockers address
    event NewLockers(
        address oldLockers, 
        address newLockers
    );

	/// @notice                     	Emits when changes made to TeleBTC address
    event NewTeleBTC(
        address oldTeleBTC, 
        address newTeleBTC
    );

	/// @notice                     	Emits when changes made to transfer deadline
    event NewTransferDeadline(
        uint oldTransferDeadline, 
        uint newTransferDeadline
    );

	/// @notice                     	Emits when changes made to percentage fee
    event NewProtocolPercentageFee(
        uint oldProtocolPercentageFee, 
        uint newProtocolPercentageFee
    );

	/// @notice                     	Emits when changes made to slasher percentage fee
    event NewSlasherPercentageFee(
        uint oldSlasherPercentageFee, 
        uint newSlasherPercentageFee
    );

	/// @notice                     	Emits when changes made to bitcoin fee
    event NewBitcoinFee(
        uint oldBitcoinFee, 
        uint newBitcoinFee
    );


	// Read-only functions

    function startingBlockNumber() external view returns (uint);
	
	function relay() external view returns (address);

	function lockers() external view returns (address);

	function teleBTC() external view returns (address);

	function treasury() external view returns (address);

	function transferDeadline() external view returns (uint);

	function protocolPercentageFee() external view returns (uint);

	function slasherPercentageReward() external view returns (uint);

	function bitcoinFee() external view returns (uint); // Bitcoin transaction fee

	function isTransferred(address _lockerTargetAddress, uint _index) external view returns (bool);

	function isUsedAsBurnProof(bytes32 _txId) external view returns (bool);

	// State-changing functions

	function setRelay(address _relay) external;

	function setLockers(address _lockers) external;

	function setTeleBTC(address _teleBTC) external;

	function setTreasury(address _treasury) external;

	function setTransferDeadline(uint _transferDeadline) external;

	function setProtocolPercentageFee(uint _protocolPercentageFee) external;

	function setSlasherPercentageReward(uint _slasherPercentageReward) external;

	function setBitcoinFee(uint _bitcoinFee) external;

	function ccBurn(
		uint _amount, 
		bytes calldata _userScript,
		ScriptTypes _scriptType,
		bytes calldata _lockerLockingScript
	) external returns (uint);

	function burnProof(
		bytes4 _version,
		bytes memory _vin,
		bytes memory _vout,
		bytes4 _locktime,
		uint256 _blockNumber,
		bytes memory _intermediateNodes,
		uint _index,
		bytes memory _lockerLockingScript,
        uint[] memory _burnReqIndexes,
        uint[] memory _voutIndexes
	) external payable returns (bool);

	function disputeBurn(
		bytes calldata _lockerLockingScript,
		uint[] memory _indices
	) external returns (bool);

    function disputeLocker(
        bytes memory _lockerLockingScript,
        bytes4[] memory _versions, // [inputTxVersion, outputTxVersion]
        bytes memory _inputVin,
        bytes memory _inputVout,
        bytes memory _outputVin,
        bytes memory _outputVout,
        bytes4[] memory _locktimes, // [inputTxLocktime, outputTxLocktime]
        bytes memory _inputIntermediateNodes,
        uint[] memory _indexesAndBlockNumbers // [inputIndex, inputTxIndex, outputTxIndex, inputTxBlockNumber, outputTxBlockNumber]
    ) external payable returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.8.0 <0.8.4;

import "./ILockersStorage.sol";

interface ILockers is ILockersStorage {

     // Events

    event RequestAddLocker(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount
    );

    event RevokeAddLockerRequest(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount
    );

    event RequestInactivateLocker(
        address indexed lockerTargetAddress,
        uint indexed inactivationTimestamp,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint netMinted
    );

    event ActivateLocker(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint netMinted
    );

    event LockerAdded(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTLockedAmount,
        uint nativeTokenLockedAmount,
        uint addingTime
    );

    event LockerRemoved(
        address indexed lockerTargetAddress,
        bytes lockerLockingScript,
        uint TDTUnlockedAmount,
        uint nativeTokenUnlockedAmount
    );

    event LockerSlashed(
        address indexed lockerTargetAddress,
        uint rewardAmount,
        address indexed rewardRecipient,
        uint amount,
        address indexed recipient,
        uint slashedCollateralAmount,
        uint slashTime,
        bool isForCCBurn
    );

    event LockerLiquidated(
        address indexed lockerTargetAddress,
        address indexed liquidatorAddress,
        uint collateralAmount,
        uint teleBTCAmount,
        uint liquidateTime
    );

    event LockerSlashedCollateralSold(
        address indexed lockerTargetAddress,
        address indexed buyerAddress,
        uint slashingAmount,
        uint teleBTCAmount,
        uint slashingTime
    );

    event CollateralAdded(
        address indexed lockerTargetAddress,
        uint addedCollateral,
        uint totalCollateral,
        uint addingTime
    );

    event CollateralRemoved(
        address indexed lockerTargetAddress,
        uint removedCollateral,
        uint totalCollateral,
        uint removingTime
    );

    event MintByLocker(
        address indexed lockerTargetAddress,
        address indexed receiver,
        uint mintedAmount,
        uint lockerFee,
        uint mintingTime
    );

    event BurnByLocker(
        address indexed lockerTargetAddress,
        uint burntAmount,
        uint lockerFee,
        uint burningTime
    );

    event MinterAdded(
        address indexed account
    );

    event MinterRemoved(
        address indexed account
    );

    event BurnerAdded(
        address indexed account
    );
    
    event BurnerRemoved(
        address indexed account
    );

    event NewLockerPercentageFee(
        uint oldLockerPercentageFee,
        uint newLockerPercentageFee
    );

    event NewPriceWithDiscountRatio(
        uint oldPriceWithDiscountRatio,
        uint newPriceWithDiscountRatio
    );

    event NewMinRequiredTDTLockedAmount(
        uint oldMinRequiredTDTLockedAmount,
        uint newMinRequiredTDTLockedAmount
    );

    event NewMinRequiredTNTLockedAmount(
        uint oldMinRequiredTNTLockedAmount,
        uint newMinRequiredTNTLockedAmount
    );

    event NewPriceOracle(
        address oldPriceOracle,
        address newPriceOracle
    );

    event NewCCBurnRouter(
        address oldCCBurnRouter,
        address newCCBurnRouter
    );

    event NewExchangeConnector(
        address oldExchangeConnector,
        address newExchangeConnector
    );

    event NewTeleportDAOToken(
        address oldTDTToken,
        address newTDTToken
    ); 

    event NewTeleBTC(
        address oldTeleBTC,
        address newTeleBTC
    );   

    event NewCollateralRatio(
        uint oldCollateralRatio,
        uint newCollateralRatio
    );  

    event NewLiquidationRatio(
        uint oldLiquidationRatio,
        uint newLiquidationRatio
    );   

    // Read-only functions

    function getLockerTargetAddress(bytes calldata _lockerLockingScript) external view returns (address);

    function isLocker(bytes calldata _lockerLockingScript) external view returns (bool);

    function getNumberOfLockers() external view returns (uint);

    function getLockerLockingScript(address _lockerTargetAddress) external view returns (bytes memory);

    function isLockerActive(address _lockerTargetAddress) external view returns (bool);

    function getLockerCapacity(address _lockerTargetAddress) external view returns (uint);

    function priceOfOneUnitOfCollateralInBTC() external view returns (uint);

    function isMinter(address account) external view returns(bool);

    function isBurner(address account) external view returns(bool);

    // State-changing functions

    function pauseLocker() external;

    function unPauseLocker() external;

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function addBurner(address _account) external;

    function removeBurner(address _account) external;

    function mint(bytes calldata _lockerLockingScript, address _receiver, uint _amount) external returns(uint);

    function burn(bytes calldata _lockerLockingScript, uint256 _amount) external returns(uint);

    function setTeleportDAOToken(address _tdtTokenAddress) external;

    function setLockerPercentageFee(uint _lockerPercentageFee) external;

    function setPriceWithDiscountRatio(uint _priceWithDiscountRatio) external;

    function setMinRequiredTDTLockedAmount(uint _minRequiredTDTLockedAmount) external;

    function setMinRequiredTNTLockedAmount(uint _minRequiredTNTLockedAmount) external;

    function setPriceOracle(address _priceOracle) external;

    function setCCBurnRouter(address _ccBurnRouter) external;

    function setExchangeConnector(address _exchangeConnector) external;

    function setTeleBTC(address _teleBTC) external;

    function setCollateralRatio(uint _collateralRatio) external;

    function setLiquidationRatio(uint _liquidationRatio) external;

    function liquidateLocker(
        address _lockerTargetAddress,
        uint _btcAmount
    ) external returns (bool);

    function addCollateral(
        address _lockerTargetAddress,
        uint _addingNativeTokenAmount
    ) external payable returns (bool);

    function removeCollateral(
        uint _removingNativeTokenAmount
    ) external payable returns (bool);

    function requestToBecomeLocker(
        bytes calldata _lockerLockingScript,
        uint _lockedTDTAmount,
        uint _lockedNativeTokenAmount,
        ScriptTypes _lockerRescueType,
        bytes calldata _lockerRescueScript
    ) external payable returns (bool);

    function revokeRequest() external returns (bool);

    function addLocker(address _lockerTargetAddress) external returns (bool);

    function requestInactivation() external returns (bool);

    function requestActivation() external returns (bool);

    function selfRemoveLocker() external returns (bool);

    function slashIdleLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount,
        address _recipient
    ) external returns(bool);

    function slashThiefLocker(
        address _lockerTargetAddress,
        uint _rewardAmount,
        address _rewardRecipient,
        uint _amount
    ) external returns(bool);

    function buySlashedCollateralOfLocker(
        address _lockerTargetAddress,
        uint _collateralAmount
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../oracle/interfaces/IPriceOracle.sol";
import "../erc20/interfaces/ITeleBTC.sol";
import "../types/ScriptTypesEnum.sol";
import "../types/DataTypes.sol";

library LockersLib {

    function requestToBecomeLockerValidation(
        mapping(address => DataTypes.locker) storage lockersMapping,
        DataTypes.lockersLibParam memory libParams,
        address theLockerTargetAddress,
        uint _lockedTDTAmount,
        uint _lockedNativeTokenAmount
    ) external {

        require(
            !lockersMapping[msg.sender].isCandidate,
            "Lockers: is candidate"
        );

        require(
            !lockersMapping[msg.sender].isLocker,
            "Lockers: is locker"
        );

        require(
            _lockedTDTAmount >= libParams.minRequiredTDTLockedAmount,
            "Lockers: low TDT"
        );

        require(
            _lockedNativeTokenAmount >= libParams.minRequiredTNTLockedAmount && msg.value == _lockedNativeTokenAmount,
            "Lockers: low TNT"
        );

        require(
            theLockerTargetAddress == address(0),
            "Lockers: used locking script"
        );

    }

    function requestToBecomeLocker(
        mapping(address => DataTypes.locker) storage lockersMapping,
        bytes calldata _candidateLockingScript,
        uint _lockedTDTAmount,
        uint _lockedNativeTokenAmount,
        ScriptTypes _lockerRescueType,
        bytes calldata _lockerRescueScript
    ) external {

        DataTypes.locker memory locker_;
        locker_.lockerLockingScript = _candidateLockingScript;
        locker_.TDTLockedAmount = _lockedTDTAmount;
        locker_.nativeTokenLockedAmount = _lockedNativeTokenAmount;
        locker_.isCandidate = true;
        locker_.lockerRescueType = _lockerRescueType;
        locker_.lockerRescueScript = _lockerRescueScript;

        lockersMapping[msg.sender] = locker_;

    }

    function buySlashedCollateralOfLocker(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _collateralAmount
    ) external returns (uint neededTeleBTC) {

        require(
            theLocker.isLocker,
            "Lockers: input address is not a valid locker"
        );

        require(
            _collateralAmount <= theLocker.reservedNativeTokenForSlash,
            "Lockers: not enough slashed collateral to buy"
        );

        // Finds needed amount of TeleBTC to buy collateral with discount
        uint priceOfCollateral = priceOfOneUnitOfCollateralInBTC(
            libConstants,
            libParams
        );

        neededTeleBTC = neededTeleBTCToBuyCollateral(
            libConstants,
            libParams,
            _collateralAmount,
            priceOfCollateral
        );

        if (
            _collateralAmount == theLocker.reservedNativeTokenForSlash || 
                neededTeleBTC >= theLocker.slashingTeleBTCAmount // Users cannot buy more than total slashed TeleBTC
        ) {
            // we ensure that all the slashing TeleBTC is provided by users 
            neededTeleBTC = theLocker.slashingTeleBTCAmount;
        } else {
            neededTeleBTC = neededTeleBTC + 1; // to avoid precision loss (so buyer cannot profit bcz of that)
        }

        // Updates locker's slashing info 
        theLocker.slashingTeleBTCAmount =
            theLocker.slashingTeleBTCAmount - neededTeleBTC;

        theLocker.reservedNativeTokenForSlash =
            theLocker.reservedNativeTokenForSlash - _collateralAmount;

    }

    function liquidateLocker(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _collateralAmount
    ) external view returns (uint neededTeleBTC) {

        require(
            theLocker.isLocker,
            "Lockers: input address is not a valid locker"
        );

        // DataTypes.locker memory theLiquidatingLocker = lockersMapping[_lockerTargetAddress];
        uint priceOfCollateral = priceOfOneUnitOfCollateralInBTC(
            libConstants,
            libParams
        );

        // Checks that the collateral has become unhealthy
        require(
            calculateHealthFactor(
                theLocker,
                libConstants,
                libParams,
                priceOfCollateral
            ) < libConstants.HealthFactor,
            "Lockers: is healthy"
        );

        uint _maxBuyableCollateral = maximumBuyableCollateral(
            theLocker,
            libConstants,
            libParams,
            priceOfCollateral
        );

        if (_maxBuyableCollateral > theLocker.nativeTokenLockedAmount) {
            _maxBuyableCollateral = theLocker.nativeTokenLockedAmount;
        }

        require(
            _collateralAmount <= _maxBuyableCollateral,
            "Lockers: not enough collateral to buy"
        );

        // Needed amount of TeleBTC to buy collateralAmount
        neededTeleBTC = neededTeleBTCToBuyCollateral(
            libConstants,
            libParams,
            _collateralAmount,
            priceOfCollateral
        );

        neededTeleBTC = neededTeleBTC + 1; // to prevent precision loss

    }

    function slashThiefLocker(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _rewardAmount,
        uint _amount
    ) external returns (uint rewardInNativeToken, uint neededNativeTokenForSlash) {

        require(
            theLocker.isLocker,
            "Lockers: input address is not a valid locker"
        );

        uint equivalentNativeToken = IPriceOracle(libParams.priceOracle).equivalentOutputAmount(
            _amount, // Total amount of TeleBTC that is slashed
            ITeleBTC(libParams.teleBTC).decimals(), // Decimal of teleBTC
            libConstants.NativeTokenDecimal, // Decimal of TNT
            libParams.teleBTC, // Input token
            libConstants.NativeToken // Output token
        );

        rewardInNativeToken = equivalentNativeToken*_rewardAmount/_amount;
        neededNativeTokenForSlash = equivalentNativeToken*libParams.liquidationRatio/libConstants.OneHundredPercent;

        if ((rewardInNativeToken + neededNativeTokenForSlash) > theLocker.nativeTokenLockedAmount) {
            // Divides total locker's collateral proportional to reward amount and slash amount
            rewardInNativeToken = rewardInNativeToken*theLocker.nativeTokenLockedAmount/
                (rewardInNativeToken + neededNativeTokenForSlash);
            neededNativeTokenForSlash = theLocker.nativeTokenLockedAmount - rewardInNativeToken;
        }

        // Updates locker's bond (in TNT)
        theLocker.nativeTokenLockedAmount
            = theLocker.nativeTokenLockedAmount - (rewardInNativeToken + neededNativeTokenForSlash);

        if (_amount > theLocker.netMinted) {
            _amount = theLocker.netMinted;
        }
        
        theLocker.netMinted
            = theLocker.netMinted - _amount;

        theLocker.slashingTeleBTCAmount
            = theLocker.slashingTeleBTCAmount + _amount; 

        theLocker.reservedNativeTokenForSlash
            = theLocker.reservedNativeTokenForSlash + neededNativeTokenForSlash;
    }

    function slashIdleLocker(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _rewardAmount,
        uint _amount
    ) external returns (uint equivalentNativeToken) {

        require(
            theLocker.isLocker,
            "Lockers: input address is not a valid locker"
        );

        equivalentNativeToken = IPriceOracle(libParams.priceOracle).equivalentOutputAmount(
            _rewardAmount + _amount, // Total amount of TeleBTC that is slashed
            ITeleBTC(libParams.teleBTC).decimals(), // Decimal of teleBTC
            libConstants.NativeTokenDecimal, // Decimal of TNT
            libParams.teleBTC, // Input token
            libConstants.NativeToken // Output token
        );

        if (equivalentNativeToken > theLocker.nativeTokenLockedAmount) {
            equivalentNativeToken = theLocker.nativeTokenLockedAmount;
        }

        // Updates locker's bond (in TNT)
        theLocker.nativeTokenLockedAmount
        = theLocker.nativeTokenLockedAmount - equivalentNativeToken;
    }

    function maximumBuyableCollateral(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral
    ) public view returns (uint) {

        // maxBuyable <= (upperHealthFactor*netMinted*liquidationRatio/10000 - nativeTokenLockedAmount*nativeTokenPrice)/(upperHealthFactor*liquidationRatio*discountedPrice - nativeTokenPrice)
        //  => maxBuyable <= (upperHealthFactor*netMinted*liquidationRatio * 10^18  - nativeTokenLockedAmount*nativeTokenPrice * 10^8)/(upperHealthFactor*liquidationRatio*discountedPrice - nativeTokenPrice * 10^8)

        uint teleBTCDecimal = ERC20(libParams.teleBTC).decimals();

        uint antecedent = (libConstants.UpperHealthFactor * theLocker.netMinted * libParams.liquidationRatio * (10 ** libConstants.NativeTokenDecimal)) -
        (theLocker.nativeTokenLockedAmount * _priceOfOneUnitOfCollateral * (10 ** teleBTCDecimal));

        uint consequent = ((libConstants.UpperHealthFactor * libParams.liquidationRatio * _priceOfOneUnitOfCollateral * libParams.priceWithDiscountRatio)/libConstants.OneHundredPercent) -
        (_priceOfOneUnitOfCollateral * (10 ** teleBTCDecimal));

        return antecedent/consequent;
    }

    function calculateHealthFactor(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral
    ) public view returns (uint) {
        return (_priceOfOneUnitOfCollateral * theLocker.nativeTokenLockedAmount * 
            (10 ** (1 + ERC20(libParams.teleBTC).decimals())))/
                (theLocker.netMinted * libParams.liquidationRatio * (10 ** (1 + libConstants.NativeTokenDecimal)));
    }

    function neededTeleBTCToBuyCollateral(
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _collateralAmount,
        uint _priceOfCollateral
    ) public pure returns (uint) {
        return (_collateralAmount * _priceOfCollateral * libParams.priceWithDiscountRatio)/
            (libConstants.OneHundredPercent*(10 ** libConstants.NativeTokenDecimal));
    }

    function addToCollateral(
        DataTypes.locker storage theLocker,
        uint _addingNativeTokenAmount
    ) external {

        require(
            theLocker.isLocker,
            "Lockers: no locker"
        );

        theLocker.nativeTokenLockedAmount =
        theLocker.nativeTokenLockedAmount + _addingNativeTokenAmount;
    }

    function removeFromCollateral(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral,
        uint _removingNativeTokenAmount
    ) internal {

        require(
            theLocker.isLocker,
            "Lockers: account is not a locker"
        );

        // Capacity of locker = (locker's collateral value in TeleBTC) * (collateral ratio) - (minted TeleBTC) 
        uint lockerCapacity = (theLocker.nativeTokenLockedAmount * _priceOfOneUnitOfCollateral * 
            libConstants.OneHundredPercent)/
                (libParams.collateralRatio * (10 ** libConstants.NativeTokenDecimal)) - theLocker.netMinted;

        uint maxRemovableCollateral = (lockerCapacity * (10 ** libConstants.NativeTokenDecimal))/_priceOfOneUnitOfCollateral;

        require(
            _removingNativeTokenAmount <= maxRemovableCollateral,
            "Lockers: more than max removable collateral"
        );

        require(
            theLocker.nativeTokenLockedAmount - _removingNativeTokenAmount >= libParams.minRequiredTNTLockedAmount,
            "Lockers: less than min collateral"
        );

        theLocker.nativeTokenLockedAmount =
        theLocker.nativeTokenLockedAmount - _removingNativeTokenAmount;
    }

    function priceOfOneUnitOfCollateralInBTC(
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams
    ) public view returns (uint) {

        return IPriceOracle(libParams.priceOracle).equivalentOutputAmount(
            (10**libConstants.NativeTokenDecimal), // 1 Ether is 10^18 wei
            libConstants.NativeTokenDecimal,
            ITeleBTC(libParams.teleBTC).decimals(),
            libConstants.NativeToken,
            libParams.teleBTC
        );

    }


    function lockerCollateralInTeleBTC(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams
    ) public view returns (uint) {

        return IPriceOracle(libParams.priceOracle).equivalentOutputAmount(
            theLocker.nativeTokenLockedAmount,
            libConstants.NativeTokenDecimal,
            ITeleBTC(libParams.teleBTC).decimals(),
            libConstants.NativeToken,
            libParams.teleBTC
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/ILockersStorage.sol";

contract LockersStorageStructure is ILockersStorage {

    // Constants
    uint public constant ONE_HUNDRED_PERCENT = 10000;
    uint public constant HEALTH_FACTOR = 10000;
    uint public constant UPPER_HEALTH_FACTOR = 12500;
    uint public constant MAX_LOCKER_FEE = 10000;
    uint public constant INACTIVATION_DELAY = 345600; // 4 days (it should be greater than MAX_FINALIZATION_PARAMETER)
    uint public constant NATIVE_TOKEN_DECIMAL = 18;
    address public constant NATIVE_TOKEN = address(1);

    // Public variables
    address public override TeleportDAOToken;
    address public override teleBTC;
    address public override ccBurnRouter;
    address public override exchangeConnector;
    address public override priceOracle;

    uint public override minRequiredTDTLockedAmount;
    uint public override minRequiredTNTLockedAmount;
    uint public override lockerPercentageFee;
    uint public override collateralRatio;
    uint public override liquidationRatio;
    uint public override priceWithDiscountRatio;
    uint public override totalNumberOfCandidates;
    uint public override totalNumberOfLockers;

    mapping(address => DataTypes.locker) public lockersMapping; // locker's target address -> locker structure
    mapping(address => uint) public lockerInactivationTimestamp;
    mapping(address => bool) public lockerLeavingAcceptance;
    mapping(bytes => address) public lockerTargetAddress; // locker's locking script -> locker's target address
    mapping(address => bool) minters;
    mapping(address => bool) burners;

    DataTypes.lockersLibConstants public libConstants;
    DataTypes.lockersLibParam public libParams;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

    enum ScriptTypes {
        P2PK, // 32 bytes
        P2PKH, // 20 bytes        
        P2SH, // 20 bytes          
        P2WPKH, // 20 bytes          
        P2WSH // 32 bytes               
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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
pragma solidity >=0.8.0 <0.8.4;

import "../../types/DataTypes.sol";

interface ILockersStorage {
    // Read-only functions

    function TeleportDAOToken() external view returns(address);

    function teleBTC() external view returns(address);

    function ccBurnRouter() external view returns(address);

    function exchangeConnector() external view returns(address);

    function priceOracle() external view returns(address);

    function minRequiredTDTLockedAmount() external view returns(uint);

    function minRequiredTNTLockedAmount() external view returns(uint);

    function lockerPercentageFee() external view returns(uint);

    function collateralRatio() external view returns(uint);

    function liquidationRatio() external view returns(uint);

    function priceWithDiscountRatio() external view returns(uint);

    function totalNumberOfCandidates() external view returns(uint);

    function totalNumberOfLockers() external view returns(uint);
  
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./ScriptTypesEnum.sol";

library DataTypes {

    /// @notice                             Structure for registering lockers
    /// @dev
    /// @param lockerLockingScript          Locker redeem script
    /// @param lockerRescueType             Locker script type in case of getting BTCs back
    /// @param lockerRescueScript           Locker script in case of getting BTCs back
    /// @param TDTLockedAmount              Bond amount of locker in TDT
    /// @param nativeTokenLockedAmount      Bond amount of locker in native token of the target chain
    /// @param netMinted                    Total minted - total burnt
    /// @param slashingTeleBTCAmount        Total amount of teleBTC a locker must be slashed
    /// @param reservedNativeTokenForSlash  Total native token reserved to support slashing teleBTC
    /// @param isLocker                     Indicates that is already a locker or not
    /// @param isCandidate                  Indicates that is a candidate or not
    /// @param isScriptHash                 Shows if it's script hash
    ///                                     has enough collateral to accept more minting requests)
    struct locker {
        bytes lockerLockingScript;
        ScriptTypes lockerRescueType;
        bytes lockerRescueScript;
        uint TDTLockedAmount;
        uint nativeTokenLockedAmount;
        uint netMinted;
        uint slashingTeleBTCAmount;
        uint reservedNativeTokenForSlash;
        bool isLocker;
        bool isCandidate;
        bool isScriptHash;
    }

    struct lockersLibConstants {
        uint OneHundredPercent;
        uint HealthFactor;
        uint UpperHealthFactor;
        uint MaxLockerFee;
        uint NativeTokenDecimal;
        address NativeToken;
    }

    struct lockersLibParam {
        address teleportDAOToken;
        address teleBTC;
        address ccBurnRouter;
        address exchangeConnector;
        address priceOracle;

        uint minRequiredTDTLockedAmount;
        uint minRequiredTNTLockedAmount;
        uint lockerPercentageFee;
        uint collateralRatio;
        uint liquidationRatio;
        uint priceWithDiscountRatio;
        uint inactivationDelay;
    }
}

// SPDX-License-Identifier: MIT

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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