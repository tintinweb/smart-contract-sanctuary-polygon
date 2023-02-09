// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/IInstantRouter.sol";
import "../connectors/interfaces/IExchangeConnector.sol";
import "../pools/interfaces/IInstantPool.sol";
import "../pools/interfaces/ICollateralPool.sol";
import "../pools/interfaces/ICollateralPoolFactory.sol";
import "../erc20/interfaces/ITeleBTC.sol";
import "../oracle/interfaces/IPriceOracle.sol";
import "../relay/interfaces/IBitcoinRelay.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract InstantRouter is IInstantRouter, Ownable, ReentrancyGuard, Pausable {
     using SafeERC20 for IERC20;
     using SafeCast for uint;
     
    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "InstantRouter: zero address");
        _;
    }

    // Constants
    uint constant MAX_SLASHER_PERCENTAGE_REWARD = 10000;
    uint constant ONE_HUNDRED_PERCENT = 10000;
    uint constant MAX_INSTANT_LOAN_NUMBER = 10;

    // Public variables
    mapping(address => instantRequest[]) public instantRequests; // Mapping from user address to user's unpaid instant requests
    mapping(address => uint256) public instantRequestCounter;
    uint public override slasherPercentageReward;
    uint public override paybackDeadline;
    uint public override maxPriceDifferencePercent;
    address public override treasuaryAddress;

    address public override teleBTC;
    address public override teleBTCInstantPool;
    address public override relay;
    address public override priceOracle;
    address public override collateralPoolFactory;
    address public override defaultExchangeConnector;

    /// @notice                             This contract handles instant transfer and instant exchange requests
    /// @dev                                It manages instant pool contract to give loan to users
    /// @param _teleBTC                     Address of teleBTC contract
    /// @param _relay                       Address of relay contract
    /// @param _priceOracle                 Address of price oracle contract
    /// @param _collateralPoolFactory       Address of collateral pool factory contract
    /// @param _slasherPercentageReward     Percentage of total collateral that goes to slasher
    /// @param _paybackDeadline             Deadline of paying back the borrowed tokens
    /// @param _defaultExchangeConnector    Exchange connector that is used for exchanging user's collateral to teleBTC (in the case of slashing)
    /// @param _maxPriceDifferencePercent   Maximum acceptable price different between chainlink price oracle and dex price
    /// @param _treasuaryAddress            Treasury address to which the extra TeleBTCs will go 
    constructor(
        address _teleBTC,
        address _relay,
        address _priceOracle,
        address _collateralPoolFactory,
        uint _slasherPercentageReward,
        uint _paybackDeadline,
        address _defaultExchangeConnector,
        uint _maxPriceDifferencePercent,
        address _treasuaryAddress
    ) {
        _setTeleBTC(_teleBTC);
        _setRelay(_relay);
        _setPriceOracle(_priceOracle);
        _setCollateralPoolFactory(_collateralPoolFactory);
        _setSlasherPercentageReward(_slasherPercentageReward);
        _setPaybackDeadline(_paybackDeadline);
        _setDefaultExchangeConnector(_defaultExchangeConnector);
        _setMaxPriceDifferencePercent(_maxPriceDifferencePercent);
        _setTreasuaryAddress(_treasuaryAddress);
    }

    receive() external payable {}

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice       Pause the contract
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice       Unpause the contract
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice                  Gives the locked collateral pool token corresponding to a request
    /// @param _user             Address of the user
    /// @param _index            Index of the request in user's request list
    /// @return                  Amount of locked collateral pool token (not collateral token)
    function getLockedCollateralPoolTokenAmount(
        address _user,
        uint _index
    ) external view override returns (uint) {
        require(_index < instantRequests[_user].length, "InstantRouter: wrong index");
        return instantRequests[_user][_index].lockedCollateralPoolTokenAmount;
    }

    /// @notice                   Gives the total number of user's unpaid loans
    /// @param _user              Address of the user
    /// @return                   The total number of user's requests
    function getUserRequestsLength(address _user) external view override returns (uint) {
        return instantRequests[_user].length;
    }

    /// @notice                   Gives deadline of a specefic request
    /// @param _user              Address of the user
    /// @param _index             Index of the request in user's request list
    /// @return                   Deadline of that request
    function getUserRequestDeadline(address _user, uint _index) external view override returns (uint) {
        require(_index < instantRequests[_user].length, "InstantRouter: wrong index");
        return instantRequests[_user][_index].deadline;
    }

    /// @notice                   Setter for payback deadline
    /// @dev                      Only owner can call this. It should be greater than relay finalization parameter so user has enough time to payback loan
    /// @param _paybackDeadline   The new payback deadline
    function setPaybackDeadline(uint _paybackDeadline) external override onlyOwner {
        _setPaybackDeadline(_paybackDeadline);
    }

    /// @notice                   Fixing payback deadline after changing finalization parameter
    function fixPaybackDeadline() external {
        uint _finalizationParameter = IBitcoinRelay(relay).finalizationParameter();
        require(_finalizationParameter <= paybackDeadline, "InstantRouter: finalization parameter is not greater than payback deadline");
        uint _paybackDeadline = 2 * _finalizationParameter + 1;
        _setPaybackDeadline(_paybackDeadline);
    }

    /// @notice                             Setter for slasher percentage reward
    /// @dev                                Only owner can call this
    /// @param _slasherPercentageReward     The new slasher reward
    function setSlasherPercentageReward(uint _slasherPercentageReward) external override onlyOwner {
        _setSlasherPercentageReward(_slasherPercentageReward);
    }

    /// @notice                                 Setter for teleBTC
    /// @dev                                    Only owner can call this
    /// @param _teleBTC                         The new teleBTC address
    function setTeleBTC(
        address _teleBTC
    ) external override onlyOwner {
        _setTeleBTC(_teleBTC);
    }

    /// @notice                                 Setter for relay
    /// @dev                                    Only owner can call this
    /// @param _relay                           The new relay address
    function setRelay(
        address _relay
    ) external override onlyOwner {
        _setRelay(_relay);
    }

    /// @notice                                 Setter for collateral pool factory
    /// @dev                                    Only owner can call this
    /// @param _collateralPoolFactory           The new collateral pool factory address
    function setCollateralPoolFactory(
        address _collateralPoolFactory
    ) external override onlyOwner {
        _setCollateralPoolFactory(_collateralPoolFactory);
    }

    /// @notice                                 Setter for price oracle
    /// @dev                                    Only owner can call this
    /// @param _priceOracle                     The new price oracle address
    function setPriceOracle(
        address _priceOracle
    ) external override onlyOwner {
        _setPriceOracle(_priceOracle);
    }

    /// @notice                                 Setter for teleBTC instant pool
    /// @dev                                    Only owner can call this
    /// @param _teleBTCInstantPool              The new teleBTC instant pool address
    function setTeleBTCInstantPool(
        address _teleBTCInstantPool
    ) external override onlyOwner {
        _setTeleBTCInstantPool(_teleBTCInstantPool);
    }

    /// @notice                                 Setter for default exchange connector
    /// @dev                                    Only owner can call this
    /// @param _defaultExchangeConnector        The new defaultExchangeConnector address
    function setDefaultExchangeConnector(
        address _defaultExchangeConnector
    ) external override onlyOwner {
        _setDefaultExchangeConnector(_defaultExchangeConnector);
    }

    /// @notice                                 Setter for treasury address
    /// @dev                                    Only owner can call this
    /// @param _treasuaryAddress                The new treasury address
    function setTreasuaryAddress(
        address _treasuaryAddress
    ) external override onlyOwner {
        _setTreasuaryAddress(_treasuaryAddress);
    }

    /// @notice                                 Setter for max price differnce in percent 
    /// @dev                                    Only owner can call this
    /// @param _maxPriceDifferencePercent       The new maxPriceDifferencePercent 
    function setMaxPriceDifferencePercent(
        uint _maxPriceDifferencePercent
    ) external override onlyOwner {
        _setMaxPriceDifferencePercent(_maxPriceDifferencePercent);
    }

    /// @notice                   Internal setter for payback deadline
    /// @dev                      Only owner can call this. It should be greater than relay finalization parameter so user has enough time to payback loan
    /// @param _paybackDeadline   The new payback deadline
    function _setPaybackDeadline(uint _paybackDeadline) private {
        uint _finalizationParameter = IBitcoinRelay(relay).finalizationParameter();
        // Gives users enough time to pay back loans
        require(_paybackDeadline > _finalizationParameter, "InstantRouter: wrong payback deadline");
        emit NewPaybackDeadline(paybackDeadline, _paybackDeadline);
        paybackDeadline = _paybackDeadline;
    }

    /// @notice                             Internal setter for slasher percentage reward
    /// @dev                                Only owner can call this
    /// @param _slasherPercentageReward     The new slasher reward
    function _setSlasherPercentageReward(uint _slasherPercentageReward) private {
        require(
            _slasherPercentageReward <= MAX_SLASHER_PERCENTAGE_REWARD,
            "InstantRouter: wrong slasher percentage reward"
        );
        emit NewSlasherPercentageReward(slasherPercentageReward, _slasherPercentageReward);
        slasherPercentageReward = _slasherPercentageReward;
    }

    /// @notice                                 Internal setter for teleBTC instant
    /// @param _teleBTC                         The new teleBTC instant address
    function _setTeleBTC(
        address _teleBTC
    ) private nonZeroAddress(_teleBTC) {
        emit NewTeleBTC(teleBTC, _teleBTC);
        teleBTC = _teleBTC;
    }

    /// @notice                                 Internal setter for relay
    /// @param _relay                           The new relay address
    function _setRelay(
        address _relay
    ) private nonZeroAddress(_relay) {
        emit NewRelay(relay, _relay);
        relay = _relay;
    }

    /// @notice                                 Internal setter for collateral pool factory
    /// @param _collateralPoolFactory           The new collateral pool factory address
    function _setCollateralPoolFactory(
        address _collateralPoolFactory
    ) private nonZeroAddress(_collateralPoolFactory) {
        emit NewCollateralPoolFactory(collateralPoolFactory, _collateralPoolFactory);
        collateralPoolFactory = _collateralPoolFactory;
    }

    /// @notice                                 Internal setter for price oracle
    /// @param _priceOracle                     The new price oracle address
    function _setPriceOracle(
        address _priceOracle
    ) private nonZeroAddress(_priceOracle) {
        emit NewPriceOracle(priceOracle, _priceOracle);
        priceOracle = _priceOracle;
    }

    /// @notice                                 Internal setter for teleBTC instant pool
    /// @param _teleBTCInstantPool              The new teleBTC instant pool address
    function _setTeleBTCInstantPool(
        address _teleBTCInstantPool
    ) private nonZeroAddress(_teleBTCInstantPool) {
        emit NewTeleBTCInstantPool(teleBTCInstantPool, _teleBTCInstantPool);
        teleBTCInstantPool = _teleBTCInstantPool;
    }

    /// @notice                                 Internal setter for default exchange connector
    /// @param _defaultExchangeConnector        The new defaultExchangeConnector address
    function _setDefaultExchangeConnector(
        address _defaultExchangeConnector
    ) private nonZeroAddress(_defaultExchangeConnector) {
        emit NewDefaultExchangeConnector(defaultExchangeConnector, _defaultExchangeConnector);
        defaultExchangeConnector = _defaultExchangeConnector;
    }

    /// @notice                                 Internal setter for treasury address
    /// @param _treasuaryAddress                The new treasuaryAddress 
    function _setTreasuaryAddress(
        address _treasuaryAddress
    ) private nonZeroAddress(_treasuaryAddress) {
        emit NewTreasuaryAddress(treasuaryAddress, _treasuaryAddress);
        treasuaryAddress = _treasuaryAddress;
    }

    /// @notice                                 Internal setter for max price differnce in percent  
    /// @param _maxPriceDifferencePercent        The new maxPriceDifferencePercent 
    function _setMaxPriceDifferencePercent(
        uint _maxPriceDifferencePercent
    ) private {
        emit NewMaxPriceDifferencePercent(maxPriceDifferencePercent, _maxPriceDifferencePercent);
        maxPriceDifferencePercent = _maxPriceDifferencePercent;
    }

    /// @notice                   Transfers the loan amount (in teleBTC) to the user
    /// @dev                      Transfers required collateral pool token of user to itself. Only works when contract is not paused.
    /// @param _receiver          Address of the loan receiver
    /// @param _loanAmount        Amount of the loan
    /// @param _deadline          Deadline for getting the loan
    /// @param _collateralToken   Address of the collateral token
    /// @return                   True if getting loan was successful
    function instantCCTransfer(
        address _receiver,
        uint _loanAmount,
        uint _deadline,
        address _collateralToken
    ) external nonReentrant nonZeroAddress(_receiver) nonZeroAddress(_collateralToken)
    whenNotPaused override returns (bool) {
        // Checks that deadline for getting loan has not passed
        require(_deadline >= block.timestamp, "InstantRouter: deadline has passed");

        // Gets the instant fee
        uint instantFee = IInstantPool(teleBTCInstantPool).getFee(_loanAmount);

        // Locks the required amount of user's collateral
        _lockCollateral(_msgSender(), _loanAmount + instantFee, _collateralToken);

        // Gets loan from instant pool for receiver
        IInstantPool(teleBTCInstantPool).getLoan(_receiver, _loanAmount);

        emit InstantTransfer(
            _msgSender(),
            _receiver,
            _loanAmount,
            instantFee,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].deadline,
            _collateralToken,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].lockedCollateralPoolTokenAmount,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].requestCounterOfUser
        );

        return true;
    }

    /// @notice                   Exchanges the loan amount (in teleBTC) for the user
    /// @dev                      Locks the required collateral amount of the user. Only works when contract is not paused.
    /// @param _exchangeConnector Address of exchange connector that user wants to exchange the borrowed teleBTC in it
    /// @param _receiver          Address of the loan receiver
    /// @param _loanAmount        Amount of the loan
    /// @param _amountOut         Amount of the output token
    /// @param _path              Path of exchanging tokens
    /// @param _deadline          Deadline for getting the loan
    /// @param _collateralToken   Address of collateral token
    /// @param _isFixedToken      Shows whether input or output is fixed in exchange
    /// @return _amounts          Amounts of tokens involved in the exchange
    function instantCCExchange(
        address _exchangeConnector,
        address _receiver,
        uint _loanAmount,
        uint _amountOut,
        address[] memory _path,
        uint _deadline,
        address _collateralToken,
        bool _isFixedToken
    ) external nonReentrant nonZeroAddress(_exchangeConnector)
    whenNotPaused override returns(uint[] memory _amounts) {
        // Checks that deadline for exchanging has not passed
        require(_deadline >= block.timestamp, "InstantRouter: deadline has passed");

        // Checks that the first token of path is teleBTC and its length is greater than one
        require(_path[0] == teleBTC && _path.length > 1, "InstantRouter: path is invalid");

        // Calculates the instant fee
        uint instantFee = IInstantPool(teleBTCInstantPool).getFee(_loanAmount);

        // Locks the required amount of user's collateral
        _lockCollateral(_msgSender(), _loanAmount + instantFee, _collateralToken);

        // Gets loan from instant pool
        IInstantPool(teleBTCInstantPool).getLoan(address(this), _loanAmount);

        // Gives allowance to exchange connector
        ITeleBTC(teleBTC).approve(_exchangeConnector, _loanAmount);

        // Exchanges teleBTC for output token
        bool result;
        (result, _amounts) = IExchangeConnector(_exchangeConnector).swap(
            _loanAmount,
            _amountOut,
            _path,
            _receiver,
            _deadline,
            _isFixedToken
        );

        /*
            Reverts if exchanging was not successful since
            user doesn't want to lock collateral without exchanging
        */
        require(result == true, "InstantRouter: exchange was not successful");

        emit InstantExchange(
            _msgSender(),
            _receiver,
            _loanAmount,
            instantFee,
            _amountOut,
            _path,
            _isFixedToken,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].deadline, // payback deadline
            _collateralToken,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].lockedCollateralPoolTokenAmount,
            instantRequests[_msgSender()][instantRequests[_msgSender()].length - 1].requestCounterOfUser
        );
    }

    /// @notice                             Settles loans of the user
    /// @dev                                Caller should give allowance for teleBTC to instant router
    /// @param _user                        Address of user who wants to pay back loans
    /// @param _teleBTCAmount               Amount of available teleBTC to pay back loans
    /// @return                             True if paying back is successful
    function payBackLoan(
        address _user,
        uint _teleBTCAmount
    ) external nonReentrant nonZeroAddress(_user) override returns (bool) {
        uint remainedAmount = _teleBTCAmount;
        uint lastSubmittedHeight = IBitcoinRelay(relay).lastSubmittedHeight();

        uint amountToTransfer = 0;

        for (uint i = 1; i <= instantRequests[_user].length; i++) {

            // Checks that remained teleBTC is enough to pay back the loan and payback deadline has not passed
            if (
                remainedAmount >= instantRequests[_user][i-1].paybackAmount &&
                instantRequests[_user][i-1].deadline >= lastSubmittedHeight
            ) {
                remainedAmount = remainedAmount - instantRequests[_user][i-1].paybackAmount;

                // Pays back the loan to instant pool
                amountToTransfer += instantRequests[_user][i-1].paybackAmount;

                // Unlocks the locked collateral pool token after paying the loan
                IERC20(instantRequests[_user][i-1].collateralPool).safeTransfer(
                    _user,
                    instantRequests[_user][i-1].lockedCollateralPoolTokenAmount
                );

                emit PaybackLoan(
                    _user,
                    instantRequests[_user][i-1].paybackAmount,
                    instantRequests[_user][i-1].collateralToken,
                    instantRequests[_user][i-1].lockedCollateralPoolTokenAmount,
                    instantRequests[_user][i-1].requestCounterOfUser
                );

                // Deletes the request after paying it
                _removeElement(_user, i-1);
                i--;
            }

            if (remainedAmount == 0) {
                break;
            }
        }

        ITeleBTC(teleBTC).transferFrom(
            _msgSender(),
            teleBTCInstantPool,
            amountToTransfer
        );

        // Transfers remained teleBTC to user
        if (remainedAmount > 0) {
            ITeleBTC(teleBTC).transferFrom(_msgSender(), _user, remainedAmount);
        }

        return true;
    }

    /// @notice                           Slashes collateral of user who did not pay back loan before its deadline
    /// @dev                              Buys teleBTC using the collateral and sends it to instant pool
    /// @param _user                      Address of the slashed user
    /// @param _requestIndex              Index of the request that have not been paid back before deadline
    /// @return                           True if slashing is successful
    function slashUser(
        address _user,
        uint _requestIndex
    ) override nonReentrant nonZeroAddress(_user) external returns (bool) {

        require(instantRequests[_user].length > _requestIndex, "InstantRouter: request index does not exist");

        // Checks that deadline has passed
        require(
            instantRequests[_user][_requestIndex].deadline < IBitcoinRelay(relay).lastSubmittedHeight(),
            "InstantRouter: deadline has not passed yet"
        );

        // Gets loan information
        instantRequest memory theRequest = instantRequests[_user][_requestIndex];

        // modifiedPayBackAmount is the maximum payback amount that can be get from the user 
        // it's used to calculate maximum equivalent collateral amount
        uint modifiedPayBackAmount = theRequest.paybackAmount * 
            (ONE_HUNDRED_PERCENT + maxPriceDifferencePercent) / ONE_HUNDRED_PERCENT;

        // Finds needed collateral token to pay back loan
        (, uint requiredCollateralToken) = IExchangeConnector(defaultExchangeConnector).getInputAmount(
            modifiedPayBackAmount, // Output amount
            theRequest.collateralToken, // Input token
            teleBTC // Output token
        );

        // 0 means that the result is false
        require(requiredCollateralToken != 0, "InstantRouter: liquidity pool doesn't exist or liquidity is not sufficient");

        // Gets the equivalent amount of collateral token
        uint requiredCollateralTokenFromOracle = IPriceOracle(priceOracle).equivalentOutputAmount(
            modifiedPayBackAmount, // input amount
            IERC20Metadata(teleBTC).decimals(),
            IERC20Metadata(theRequest.collateralToken).decimals(),
            teleBTC, // input token
            theRequest.collateralToken // output token
        );

        // check the price diferences between two sources and compare with the maximum acceptable price difference
        uint absPriceDiff = _abs(requiredCollateralTokenFromOracle.toInt256() - requiredCollateralToken.toInt256());
        require(
            absPriceDiff <= (requiredCollateralToken * maxPriceDifferencePercent)/ONE_HUNDRED_PERCENT,
            "InstantRouter: big gap between oracle and AMM price"
        );

        // update the modifiedPayBackAmount again
        if (requiredCollateralToken >= requiredCollateralTokenFromOracle) {
            modifiedPayBackAmount = theRequest.paybackAmount;
        } else {
            modifiedPayBackAmount = theRequest.paybackAmount * requiredCollateralTokenFromOracle / requiredCollateralToken;
        }

        uint totalCollateralToken = ICollateralPool(theRequest.collateralPool).equivalentCollateralToken(
            theRequest.lockedCollateralPoolTokenAmount
        );

        // Path of exchanging
        address[] memory path = new address[](2);
        path[0] = theRequest.collateralToken;
        path[1] = teleBTC;

        // Gets collateral token from collateral pool
        ICollateralPool(theRequest.collateralPool).removeCollateral(theRequest.lockedCollateralPoolTokenAmount);

        uint[] memory resultAmounts;

        // Checks that locked collateral is enough to pay back loan
        if (totalCollateralToken >= requiredCollateralToken) {
            // Approves exchange connector to use collateral token
            IERC20(theRequest.collateralToken).approve(defaultExchangeConnector, requiredCollateralToken);

            // Exchanges collateral token for teleBTC
            (, resultAmounts) = IExchangeConnector(defaultExchangeConnector).swap(
                requiredCollateralToken,
                modifiedPayBackAmount, // Output amount
                path,
                address(this),
                block.timestamp + 1,
                false // Output amount is fixed
            );

            // send the laon amount to the instant pool and the excess amount to the treasury
            IERC20(teleBTC).safeTransfer(teleBTCInstantPool, theRequest.paybackAmount);
            if (modifiedPayBackAmount > theRequest.paybackAmount) {
                IERC20(teleBTC).safeTransfer(treasuaryAddress, modifiedPayBackAmount - theRequest.paybackAmount);
            }

            // Sends reward to slasher
            uint slasherReward = (totalCollateralToken - resultAmounts[0])
                *slasherPercentageReward/MAX_SLASHER_PERCENTAGE_REWARD;
            IERC20(theRequest.collateralToken).safeTransfer(_msgSender(), slasherReward);

            if ((totalCollateralToken - resultAmounts[0] - slasherReward) > 0) {
                // Deposits rest of the tokens to collateral pool on behalf of the user
                IERC20(theRequest.collateralToken).approve(
                    theRequest.collateralPool, 
                    totalCollateralToken - resultAmounts[0] - slasherReward
                );
                
                ICollateralPool(theRequest.collateralPool).addCollateral(
                    _user,
                    totalCollateralToken - resultAmounts[0] - slasherReward
                );
            }

            emit SlashUser(
                _user,
                theRequest.collateralToken,
                resultAmounts[0] + slasherReward, // total slashed collateral
                modifiedPayBackAmount,
                _msgSender(),
                slasherReward,
                theRequest.requestCounterOfUser
            );
        } else { // Handles situations where locked collateral is not enough to pay back the loan

            // Approves exchange connector to use collateral token
            IERC20(theRequest.collateralToken).approve(defaultExchangeConnector, totalCollateralToken);

            // Buys teleBTC as much as possible and sends it to instant pool
            (, resultAmounts) = IExchangeConnector(defaultExchangeConnector).swap(
                totalCollateralToken,
                0,
                path,
                address(this),
                block.timestamp + 1,
                true // Input amount is fixed
            );

            if (resultAmounts[resultAmounts.length - 1] > theRequest.paybackAmount) {
                // send the laon amount to the instant pool and the excess amount to the treasury
                IERC20(teleBTC).safeTransfer(teleBTCInstantPool, theRequest.paybackAmount);
                IERC20(teleBTC).safeTransfer(
                    treasuaryAddress, resultAmounts[resultAmounts.length - 1] - theRequest.paybackAmount
                );
            } else {
                IERC20(teleBTC).safeTransfer(teleBTCInstantPool, resultAmounts[resultAmounts.length - 1]);
            }

            emit SlashUser(
                _user,
                theRequest.collateralToken,
                totalCollateralToken,
                resultAmounts[resultAmounts.length - 1],
                _msgSender(),
                0, // Slasher reward is zero,
                theRequest.requestCounterOfUser
            );
        }

        // Deletes the request after slashing user
        _removeElement(_user, _requestIndex);

        return true;
    }

    /// @notice             Removes an element of array of user's instant requests
    /// @dev                Deletes and shifts the array
    /// @param _user        Address of the user whose instant requests array is considered
    /// @param _index       Index of the element that will be deleted
    function _removeElement(address _user, uint _index) private {
        require(_index < instantRequests[_user].length, "InstantRouter: index is out of bound");
        for (uint i = _index; i < instantRequests[_user].length - 1; i++) {
            instantRequests[_user][i] = instantRequests[_user][i+1];
        }
        instantRequests[_user].pop();
    }

    /// @notice                   Locks the required amount of user's collateral
    /// @dev                      Records the instant request to be used in future
    /// @param _user              Address of the loan receiver
    /// @param _paybackAmount     Amount of the (loan + fee) that should be paid back by user
    /// @param _collateralToken   Address of the collateral token
    function _lockCollateral(
        address _user,
        uint _paybackAmount,
        address _collateralToken
    ) private nonZeroAddress(_collateralToken) {
        // Checks that collateral token is acceptable
        require(
            ICollateralPoolFactory(collateralPoolFactory).isCollateral(_collateralToken),
            "InstantRouter: collateral token is not acceptable"
        );

        require(
            instantRequests[_user].length < MAX_INSTANT_LOAN_NUMBER,
            "InstantRouter: reached max loan number"
        );

        // Gets the collateral pool address
        address collateralPool = ICollateralPoolFactory(collateralPoolFactory).getCollateralPoolByToken(
            _collateralToken
        );

        // Gets collateralization ratio
        uint collateralizationRatio = ICollateralPool(collateralPool).collateralizationRatio();

        // Gets the equivalent amount of collateral token
        uint equivalentCollateralToken = IPriceOracle(priceOracle).equivalentOutputAmount(
            _paybackAmount, // input amount
            IERC20Metadata(teleBTC).decimals(),
            IERC20Metadata(_collateralToken).decimals(),
            teleBTC, // input token
            _collateralToken // output token
        );

        // Finds needed collateral token for getting loan
        uint requiredCollateralToken = equivalentCollateralToken*collateralizationRatio/ONE_HUNDRED_PERCENT;

        // Finds needed collateral pool token for getting loan
        uint requiredCollateralPoolToken = ICollateralPool(collateralPool).equivalentCollateralPoolToken(
            requiredCollateralToken
        );

        // Transfers collateral pool token from user to itself
        IERC20(collateralPool).safeTransferFrom(_user, address(this), requiredCollateralPoolToken);

        // Records the instant request for user
        instantRequest memory request;
        request.user = _user;
        request.paybackAmount = _paybackAmount;
        request.lockedCollateralPoolTokenAmount = requiredCollateralPoolToken;
        request.collateralPool = collateralPool;
        request.collateralToken = _collateralToken;
        request.deadline = IBitcoinRelay(relay).lastSubmittedHeight() + paybackDeadline;
        request.requestCounterOfUser = instantRequestCounter[_user];
        instantRequestCounter[_user] = instantRequestCounter[_user] + 1;
        instantRequests[_user].push(request);

    }

    /// @notice             Returns absolute value
    function _abs(int _value) private pure returns (uint) {
        return _value >= 0 ? uint(_value) : uint(-_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IInstantRouter {
    // Structures

    /// @notice                                 Structure for recording instant requests
    /// @param user                             Address of user who recieves loan
    /// @param collateralPool                   Address of collateral pool
    /// @param collateralToken                  Address of underlying collateral token
    /// @param paybackAmount                    Amount of (loan + instant fee)
    /// @param lockedCollateralPoolTokenAmount  Amount of locked collateral pool token for getting loan
    /// @param deadline                         Deadline for paying back the loan
    /// @param requestCounterOfUser             The index of the request for a specific user
    struct instantRequest {
        address user;
        address collateralPool;
		address collateralToken;
        uint paybackAmount;
        uint lockedCollateralPoolTokenAmount;
        uint deadline;
        uint requestCounterOfUser;
    }

    // Events

    /// @notice                             Emits when a user gets loan for transfer
    /// @param user                         Address of the user who made the request
    /// @param receiver                     Address of the loan receiver
    /// @param loanAmount                   Amount of the loan
    /// @param instantFee                   Amount of the instant loan fee
    /// @param deadline                     Deadline of paying back the loan
    /// @param collateralToken              Address of the collateral token
    /// @param lockedCollateralPoolToken    Amount of collateral pool token that got locked
    event InstantTransfer(
        address indexed user, 
        address receiver, 
        uint loanAmount, 
        uint instantFee, 
        uint indexed deadline, 
        address indexed collateralToken,
        uint lockedCollateralPoolToken,
        uint requestCounterOfUser
    );

    /// @notice                             Emits when a user gets loan for exchange
    /// @param user                         Address of the user who made the request
    /// @param receiver                     Address of the loan receiver
    /// @param loanAmount                   Amount of the loan
    /// @param instantFee                   Amount of the instant loan fee
    /// @param amountOut                    Amount of the output token
    /// @param path                         Path of exchanging tokens
    /// @param isFixed                      Shows whether input or output is fixed in exchange
    /// @param deadline                     Deadline of getting the loan
    /// @param collateralToken              Address of the collateral token
    /// @param lockedCollateralPoolToken    Amount of collateral pool token that got locked
    event InstantExchange(
        address indexed user, 
        address receiver, 
        uint loanAmount, 
        uint instantFee,
        uint amountOut,
        address[] path,
        bool isFixed,
        uint indexed deadline, 
        address indexed collateralToken,
        uint lockedCollateralPoolToken,
        uint requestCounterOfUser
    );

    /// @notice                            Emits when a loan gets paid back
    /// @param user                        Address of user who recieves loan
    /// @param paybackAmount               Amount of (loan + fee) that should be paid back
    /// @param collateralToken             Address of underlying collateral token
    /// @param lockedCollateralPoolToken   Amount of locked collateral pool token for getting loan
    event PaybackLoan(
		address indexed user, 
		uint paybackAmount, 
		address indexed collateralToken, 
		uint lockedCollateralPoolToken,
        uint requestCounterOfUser
	);

    /// @notice                         Emits when a user gets slashed
    /// @param user                     Address of user who recieves loan
    /// @param collateralToken          Address of collateral underlying token
	/// @param slashedAmount            How much user got slashed
	/// @param paybackAmount            Amount of teleBTC paid back to the protocol
	/// @param slasher                  Address of slasher
	/// @param slasherReward            Slasher reward (in collateral token)
    event SlashUser(
		address indexed user, 
		address indexed collateralToken, 
		uint slashedAmount, 
		uint paybackAmount,
        address indexed slasher,
        uint slasherReward,
        uint requestCounterOfUser
	);

    /// @notice                     	Emits when changes made to payback deadline
    event NewPaybackDeadline(
        uint oldPaybackDeadline, 
        uint newPaybackDeadline
    );

    /// @notice                     	Emits when changes made to slasher percentage reward
    event NewSlasherPercentageReward(
        uint oldSlasherPercentageReward, 
        uint newSlasherPercentageReward
    );

    /// @notice                     	Emits when changes made to treasuray overhead percnet
    event NewTreasuaryAddress(
        address oldTreasuaryAddress, 
        address newTreasuaryAddress
    );

    /// @notice                     	Emits when changes made to max price difference percent
    event NewMaxPriceDifferencePercent(
        uint oldMaxPriceDifferencePercent, 
        uint newMaxPriceDifferencePercent
    );

    /// @notice                     	Emits when changes made to TeleBTC address
    event NewTeleBTC(
        address oldTeleBTC, 
        address newTeleBTC
    );

    /// @notice                     	Emits when changes made to relay address
    event NewRelay(
        address oldRelay, 
        address newRelay
    );

    /// @notice                     	Emits when changes made to collateral pool factory address
    event NewCollateralPoolFactory(
        address oldCollateralPoolFactory, 
        address newCollateralPoolFactory
    );

    /// @notice                     	Emits when changes made to price oracle address
    event NewPriceOracle(
        address oldPriceOracle, 
        address newPriceOracle
    );

    /// @notice                     	Emits when changes made to TeleBTC instant pool address
    event NewTeleBTCInstantPool(
        address oldTeleBTCInstantPool, 
        address newTeleBTCInstantPool
    );

    /// @notice                     	Emits when changes made to default exchange connector address
    event NewDefaultExchangeConnector(
        address oldDefaultExchangeConnector, 
        address newDefaultExchangeConnector
    );


    // Read-only functions

    function pause() external;

    function unpause() external;

    function teleBTCInstantPool() external view returns (address);

    function teleBTC() external view returns (address);

    function relay() external view returns (address);

	function collateralPoolFactory() external view returns (address);

	function priceOracle() external view returns (address);

    function slasherPercentageReward() external view returns (uint);

    function paybackDeadline() external view returns (uint);

    function defaultExchangeConnector() external view returns (address);
    
    function getLockedCollateralPoolTokenAmount(address _user, uint _index) external view returns (uint);

    function getUserRequestsLength(address _user) external view returns (uint);

    function getUserRequestDeadline(address _user, uint _index) external view returns (uint);

    function maxPriceDifferencePercent() external view returns (uint);

    function treasuaryAddress() external view returns (address);

    // State-changing functions

    function setPaybackDeadline(uint _paybackDeadline) external;

    function setSlasherPercentageReward(uint _slasherPercentageReward) external;

    function setPriceOracle(address _priceOracle) external;

    function setCollateralPoolFactory(address _collateralPoolFactory) external;

    function setRelay(address _relay) external;

    function setTeleBTC(address _teleBTC) external;

    function setTeleBTCInstantPool(address _teleBTCInstantPool) external;

    function setDefaultExchangeConnector(address _defaultExchangeConnector) external;

    function setTreasuaryAddress(address _treasuaryAddres) external;
    
    function setMaxPriceDifferencePercent(uint _maxPriceDifferencePercent) external;

    function instantCCTransfer(
        address _receiver,
        uint _loanAmount,
        uint _deadline,
        address _collateralPool
    ) external returns (bool);

    function instantCCExchange(
		address _exchangeConnector,
        address _receiver,
        uint _loanAmount, 
        uint _amountOut, 
        address[] memory _path, 
        uint _deadline,
        address _collateralToken,
        bool _isFixedToken
    ) external returns (uint[] memory);

    function payBackLoan(address _user, uint _teleBTCAmount) external returns (bool);

    function slashUser(
		address _user, 
		uint _requestIndex
	) external returns (bool);

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

interface IInstantPool is IERC20 {

	// Events

	/// @notice 							emits when an instant pool is created 
	/// @param instantToken 				The instant token of this instant pool
	event CreatedInstantPool(address indexed instantToken);

	/// @notice                             emits when some liquidity gets added to the pool               
	/// @param user                         User who added the liquidity
	/// @param teleBTCAmount                Amount of teleBTC added to the pool
	/// @param instantPoolTokenAmount       User's share from the pool
	event AddLiquidity(address indexed user, uint teleBTCAmount, uint instantPoolTokenAmount); 

	/// @notice                             Emits when some liquidity gets removed from the pool
	/// @param user                         User who removed the liquidity
	/// @param teleBTCAmount                Amount of teleBTC removed from the pool
	/// @param instantPoolTokenAmount       User's share from the pool
	event RemoveLiquidity(address indexed user, uint teleBTCAmount, uint instantPoolTokenAmount);

	/// @notice                       		Gets an instant loan from the contract
	/// @param user                   		User who wants to get the loan
	/// @param requestedAmount        		Amount of loan requested and sent to the user
	/// @param instantFee             		Amount of fee that the user should pay back later with the loan
	event InstantLoan(address indexed user, uint256 requestedAmount, uint instantFee);

	/// @notice                       		Emits when changes made to instant router address
	event NewInstantRouter(address oldInstantRouter, address newInstaneRouter);

	/// @notice                       		Emits when changes made to instant percentage fee
	event NewInstantPercentageFee(uint oldInstantPercentageFee, uint newInstantPercentageFee);

	/// @notice                       		Emits when changes made to TeleBTC address
	event NewTeleBTC(address oldTeleBTC, address newTeleBTC);

	// Read-only functions

	function teleBTC() external view returns (address);

	function instantRouter() external view returns (address);

	function totalAddedTeleBTC() external view returns (uint);

	function availableTeleBTC() external view returns (uint);

	function totalUnpaidLoan() external view returns (uint);

	function instantPercentageFee() external view returns (uint);

	function getFee(uint _loanAmount) external view returns (uint);

	// State-changing functions

	function setInstantRouter(address _instantRouter) external;

	function setInstantPercentageFee(uint _instantPercentageFee) external;

	function setTeleBTC(address _teleBTC) external;

	function addLiquidity(address _user, uint _amount) external returns (uint);

	function addLiquidityWithoutMint(uint _amount) external returns (bool);

	function removeLiquidity(address _user, uint _instantPoolTokenAmount) external returns (uint);

	function getLoan(address _user, uint _amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICollateralPool is IERC20 {

	// Events

	event AddCollateral(address indexed doer, address indexed user, uint amount, uint collateralPoolTokenAmount);

	event RemoveCollateral(address indexed doer, address indexed user, uint amount, uint collateralPoolTokenAmount);

	event NewCollateralizationRatio(uint oldCollateralizationRatio, uint newCollateralizationRatio);

	// Read-only functions

	function collateralToken() external view returns (address);

	function collateralizationRatio() external view returns(uint);

	function totalAddedCollateral() external view returns (uint);

	function equivalentCollateralToken(uint _collateralPoolTokenAmount) external view returns (uint);

	function equivalentCollateralPoolToken(uint _collateralTokenAmount) external view returns (uint);

	// State-changing functions

	function setCollateralizationRatio(uint _collateralizationRatio) external;

	function addCollateral(address _user, uint _amount) external returns (bool);

	function removeCollateral(uint _collateralPoolTokenAmount) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface ICollateralPoolFactory {

    // Events

    /// @notice                             Emits when a collateral pool is created
    /// @param name                         Name of the collateral token
    /// @param collateralToken              Collateral token address
    /// @param collateralizationRatio       At most (collateral value)/(collateralization ratio) can be moved instantly by the user
    /// @param collateralPool               Collateral pool contract address
    event CreateCollateralPool(
        string name,
        address indexed collateralToken,
        uint collateralizationRatio,
        address indexed collateralPool
    );

    /// @notice                 Emits when a collateral pool is removed
    /// @param collateralToken  Collateral token address
    /// @param collateralPool   Collateral pool contract address
    event RemoveCollateralPool(
        address indexed collateralToken,
        address indexed collateralPool
    );

    // Read-only functions

    function getCollateralPoolByToken(address _collateralToken) external view returns (address);

    function allCollateralPools(uint _index) external view returns (address);

    function allCollateralPoolsLength() external view returns (uint);

    function isCollateral(address _collateralToken) external view returns (bool);

    // State-changing functions

    function createCollateralPool(address _collateralToken, uint _collateralizationRatio) external returns (address);

    function removeCollateralPool(address _collateralToken, uint _index) external returns (bool);
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

interface IBitcoinRelay {
    // Structures

    /// @notice                 	Structure for recording block header
    /// @param selfHash             Hash of block header
    /// @param parentHash          	Hash of parent block header
    /// @param merkleRoot       	Merkle root of transactions in the block
    /// @param relayer              Address of relayer who submitted the block header
    /// @param gasPrice             Gas price of tx that relayer submitted the block header
    struct blockHeader {
        bytes32 selfHash;
        bytes32 parentHash;
        bytes32 merkleRoot;
        address relayer;
        uint gasPrice;
    }

    // Events

    /// @notice                     Emits when a block header is added
    /// @param height               Height of submitted header
    /// @param selfHash             Hash of submitted header
    /// @param parentHash           Parent hash of submitted header
    /// @param relayer              Address of relayer who submitted the block header
    event BlockAdded(
        uint indexed height,
        bytes32 selfHash,
        bytes32 indexed parentHash,
        address indexed relayer
    );

    /// @notice                     Emits when a block header gets finalized
    /// @param height               Height of the header
    /// @param selfHash             Hash of the header
    /// @param parentHash           Parent hash of the header
    /// @param relayer              Address of relayer who submitted the block header
    /// @param rewardAmountTNT      Amount of reward that the relayer receives in target native token
    /// @param rewardAmountTDT      Amount of reward that the relayer receives in TDT
    event BlockFinalized(
        uint indexed height,
        bytes32 selfHash,
        bytes32 parentHash,
        address indexed relayer,
        uint rewardAmountTNT,
        uint rewardAmountTDT
    );
         

    /// @notice                     Emits when changes made to reward amount in TDT
    event NewRewardAmountInTDT (
        uint oldRewardAmountInTDT, 
        uint newRewardAmountInTDT
    );

    /// @notice                     Emits when changes made to finalization parameter
    event NewFinalizationParameter (
        uint oldFinalizationParameter, 
        uint newFinalizationParameter
    );

    /// @notice                     Emits when changes made to relayer percentage fee
    event NewRelayerPercentageFee (
        uint oldRelayerPercentageFee, 
        uint newRelayerPercentageFee
    );

    /// @notice                     Emits when changes made to teleportDAO token
    event NewTeleportDAOToken (
        address oldTeleportDAOToken, 
        address newTeleportDAOToken
    );

    /// @notice                     Emits when changes made to epoch length
    event NewEpochLength(
        uint oldEpochLength, 
        uint newEpochLength
    );

    /// @notice                     Emits when changes made to base queries
    event NewBaseQueries(
        uint oldBaseQueries, 
        uint newBaseQueries
    );

    /// @notice                     Emits when changes made to submission gas used
    event NewSubmissionGasUsed(
        uint oldSubmissionGasUsed, 
        uint newSubmissionGasUsed
    );

    // Read-only functions

    function relayGenesisHash() external view returns (bytes32);

    function initialHeight() external view returns(uint);

    function lastSubmittedHeight() external view returns(uint);

    function finalizationParameter() external view returns(uint);

    function TeleportDAOToken() external view returns(address);

    function relayerPercentageFee() external view returns(uint);

    function epochLength() external view returns(uint);

    function lastEpochQueries() external view returns(uint);

    function currentEpochQueries() external view returns(uint);

    function baseQueries() external view returns(uint);

    function submissionGasUsed() external view returns(uint);

    function getBlockHeaderHash(uint height, uint index) external view returns(bytes32);

    function getBlockHeaderFee(uint _height, uint _index) external view returns(uint);

    function getNumberOfSubmittedHeaders(uint height) external view returns (uint);

    function availableTDT() external view returns(uint);

    function availableTNT() external view returns(uint);

    function findHeight(bytes32 _hash) external view returns (uint256);

    function findAncestor(bytes32 _hash, uint256 _offset) external view returns (bytes32); 

    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool); 

    function rewardAmountInTDT() external view returns (uint);

    // State-changing functions

    function pauseRelay() external;

    function unpauseRelay() external;

    function setRewardAmountInTDT(uint _rewardAmountInTDT) external;

    function setFinalizationParameter(uint _finalizationParameter) external;

    function setRelayerPercentageFee(uint _relayerPercentageFee) external;

    function setTeleportDAOToken(address _TeleportDAOToken) external;

    function setEpochLength(uint _epochLength) external;

    function setBaseQueries(uint _baseQueries) external;

    function setSubmissionGasUsed(uint _submissionGasUsed) external;

    function checkTxProof(
        bytes32 txid,
        uint blockHeight,
        bytes calldata intermediateNodes,
        uint index
    ) external payable returns (bool);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function ownerAddHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function ownerAddHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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