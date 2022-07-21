/**
 *Submitted for verification at polygonscan.com on 2022-07-21
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
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogCancelAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 executionCount
    );

    event LogExecuteAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 finalHf,
        uint256 initialHf
    );

    event LogExecuteAutomationParams(
        address indexed user,
        uint256 indexed id,
        address collateralToken,
        address debtToken,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 collateralAmtWithTotalFee,
        uint256 executionCount,
        uint256 finalHf,
        uint256 initialHf
    );

    event LogExecuteNextAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogSystemCancelAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 executionCount
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
        NOT_INITIATED, // no automation enabled for user
        AUTOMATED, // User enabled automation
        SUCCESS, // Automation executed
        DROPPED, // Automation dropped by system
        USER_CANCELLED // user cancelled the automation
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
        uint256 id;
        Status status;
    }
    
    uint256 public _id;

    mapping(uint256 => Automation) public _userAutomationConfigs; // user automation config

    mapping(address => uint256) public _userLatestId; // user latest automation id

    mapping(uint256 => uint256) public _executionCount; // execution count for user automation

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
        require(thresholdHealthFactor_ < safeHealthFactor_, "invalid-inputs");

        uint256 currentHf_ = getHealthFactor(msg.sender);

        emit LogSubmitAutomation(
            msg.sender,
            _id,
            safeHealthFactor_,
            thresholdHealthFactor_,
            currentHf_
        );

        _userAutomationConfigs[_id] = Automation({
            user: msg.sender,
            id: _id,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor_,
            thresholdHF: thresholdHealthFactor_
        });

        _userLatestId[msg.sender] = _id;
        _id++;
    }

    function cancelAutomationRequest() external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestId[msg.sender]
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
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        emit LogCancelAutomation(
            msg.sender,
            _userAutomationConfig.id,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            _executionCount[_userAutomationConfig.id]
        );

        _userAutomationConfig.status = Status.USER_CANCELLED;
        _userLatestId[msg.sender] = 0;
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
            _userLatestId[user_]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        uint256 finalHf_ = getHealthFactor(user_);

        _executionCount[_userAutomationConfig.id]++;

        if (finalHf_ < (_userAutomationConfig.safeHF)) {
            emit LogExecuteNextAutomation(
                user_,
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                finalHf_
            );
        } else {
            _userAutomationConfig.status = Status.SUCCESS;

            emit LogExecuteAutomation(
                user_,
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                finalHf_,
                finalHf_
            );
        }

        emit LogExecuteAutomationParams(
            user_,
            _userAutomationConfig.id,
            collateralToken_,
            debtToken_,
            collateralAmount_,
            debtAmount_,
            collateralAmtWithTotalFee_,
            _executionCount[_userAutomationConfig.id],
            finalHf_,
            finalHf_
        );
    }

    function systemCancel(address user_) external {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestId[user_]
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
            _userAutomationConfig.id,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            _executionCount[_userAutomationConfig.id]
        );

        _userAutomationConfig.status = Status.DROPPED;
        _userLatestId[user_] = 0;
    }

    function updateAutomationStatus(address[] memory users_)
        public
    {
        uint256 length_ = users_.length;
        for (uint256 i; i < length_; i++) {
            Automation storage _userAutomationConfig = _userAutomationConfigs[
                _userLatestId[users_[i]]
            ];

            require(
                _executionCount[_userAutomationConfig.id] >= 1,
                "can-update-status: use CancelAutomation"
            );
            require(
                _userAutomationConfig.status == Status.AUTOMATED,
                "already-executed-or-canceled"
            );

            uint256 healthFactor = getHealthFactor(users_[i]);

            emit LogExecuteAutomation(
                users_[i],
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                healthFactor,
                healthFactor
            );

            _userAutomationConfig.status = Status.SUCCESS;
        }
    }
}