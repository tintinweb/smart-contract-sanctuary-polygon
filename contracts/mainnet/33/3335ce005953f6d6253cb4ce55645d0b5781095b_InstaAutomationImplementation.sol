/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

interface AavePoolProviderInterface {
    function getPool() external view returns (address);
}

interface AaveInterface {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

abstract contract Events {
    event LogSubmitAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogCancelAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogExecuteAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 finalHf,
        uint256 initialHf
    );

    event LogExecuteAutomationParams(
        address indexed user,
        uint256 indexed anonce,
        address collateralToken,
        address debtToken,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 collateralAmtWithTotalFee
    );

    event LogExecuteNextAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogSystemCancelAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogUpdateAutomation(
        address indexed user,
        uint256 indexed anonce,
        uint256 newAnonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogFlipExecutors(address[] executors, bool[] status);

    event LogUpdateBufferHf(uint256 oldBufferHf, uint256 newBufferHf);

    event LogUpdateMinHf(uint256 oldMinHf, uint256 newMinHf);

    event LogUpdateAutomationFee(
        uint256 oldAutomationFee,
        uint256 newAutomationFee
    );
}

contract InstaAutomationImplementation is Events {
    enum Status {
        AUTOMATED,
        SUCCESS,
        DROPPED,
        USER_CANCELLED
    }

    function getHealthFactor(address user)
        public
        view
        returns (uint256 healthFactor)
    {
        (, , , , , healthFactor) = aave.getUserAccountData(user);
    }

    struct Automation {
        address user;
        uint256 safeHF;
        uint256 thresholdHF;
        uint256 anonce;
        Status status;
    }

    uint256 public _anonce;

    mapping(uint256 => Automation) public _userAutomationConfigs;

    mapping(address => uint256) public _userLatestANonce;

    mapping(uint256 => uint256) public _executionCount;

    AaveInterface internal immutable aave =
        AaveInterface(
            AavePoolProviderInterface(
                0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
            ).getPool()
        );

    function submitAutomationRequest(
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) public {
        uint256 currentHf_ = getHealthFactor(msg.sender);

        emit LogSubmitAutomation(
            msg.sender,
            _anonce,
            safeHealthFactor_,
            thresholdHealthFactor_,
            currentHf_
        );

        _userAutomationConfigs[_anonce] = Automation({
            user: msg.sender,
            anonce: _anonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor_,
            thresholdHF: thresholdHealthFactor_
        });

        _userLatestANonce[msg.sender] = _anonce;
        _anonce++;
    }

    function submitAutomationRequestMock(
        address user_,
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) public {
        uint256 currentHf_ = getHealthFactor(user_);

        emit LogSubmitAutomation(
            user_,
            _anonce,
            safeHealthFactor_,
            thresholdHealthFactor_,
            currentHf_
        );

        _userAutomationConfigs[_anonce] = Automation({
            user: user_,
            anonce: _anonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor_,
            thresholdHF: thresholdHealthFactor_
        });

        _userLatestANonce[user_] = _anonce;
        _anonce++;
    }

    function cancelAutomationRequest() external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestANonce[msg.sender]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.user == msg.sender,
            "not-authorized-to-make-this-call"
        );

        require(
            _executionCount[_userAutomationConfig.anonce] == 0,
            "automation-already-executed"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        _userAutomationConfig.status = Status.USER_CANCELLED;

        emit LogCancelAutomation(
            msg.sender,
            _userAutomationConfig.anonce,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF
        );
    }

    function executeAutomation(
        address user_,
        address collateralToken_,
        address debtToken_,
        uint256 collateralAmount_,
        uint256 debtAmount_,
        uint256 collateralAmtWithTotalFee_,
        uint256 rateMode_,
        uint256 route_
    ) external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestANonce[user_]
        ];

        uint256 initialHf_ = getHealthFactor(user_);

        _executionCount[_userAutomationConfig.anonce]++;

        _userAutomationConfig.status = Status.SUCCESS;

        emit LogExecuteAutomation(
            user_,
            _userAutomationConfig.anonce,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            initialHf_,
            initialHf_
        );

        emit LogExecuteAutomationParams(
            user_,
            _userAutomationConfig.anonce,
            collateralToken_,
            debtToken_,
            collateralAmount_,
            debtAmount_,
            collateralAmtWithTotalFee_
        );
    }

    function systemRevert(address user_) external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestANonce[user_]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        emit LogSystemCancelAutomation(
            user_,
            _userAutomationConfig.anonce,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF
        );

        _userAutomationConfig.status = Status.DROPPED;
    }

    function updateAutomation(
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestANonce[msg.sender]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        require(thresholdHealthFactor_ < safeHealthFactor_, "invalid-inputs");

        uint256 currentHf_ = getHealthFactor(msg.sender);

        _userAutomationConfig.status = Status.DROPPED;

        _userLatestANonce[msg.sender] = _anonce;
        _anonce++;

        emit LogUpdateAutomation(
            msg.sender,
            _userAutomationConfig.anonce,
            _anonce,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            currentHf_
        );

        _userAutomationConfigs[_anonce] = Automation({
            user: msg.sender,
            anonce: _anonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor_,
            thresholdHF: thresholdHealthFactor_
        });
    }
}