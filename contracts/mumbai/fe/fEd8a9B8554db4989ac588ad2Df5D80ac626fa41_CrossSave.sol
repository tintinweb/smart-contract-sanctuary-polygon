// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IAxelarExecutable} from "IAxelarExecutable.sol";
import {IAxelarGasService} from "IAxelarGasService.sol";

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";

import {IERC20} from "IERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

contract CrossSave is IAxelarExecutable, ReentrancyGuard {
    /// @notice chainlink price feed interfaces for real time prices
    AggregatorV3Interface public ftmPriceFeed;
    AggregatorV3Interface public maticPriceFeed;

    /// @notice Axelars gas service interface for gmp gas
    IAxelarGasService public gasService;

    /// @notice minimum amount of time a user must save
    uint256 public minimumSavingTime;
    /// @notice the minimum saving amount for a user
    uint256 public minimumSavingAmount;

    /// @notice the total time currently being saved by all users accross chains
    uint256 public totalCrossChainSavingTime;

    /// @notice the current total savers
    uint256 public totalCurrentSavers;

    /// @notice keeps track of updated chain contract addresses
    bool public initialized;

    /// @notice the deployer of the contract
    address public deployer;

    /// @notice The interest pool created by savers who defaulted on  their time of savings
    struct TotalCrossChainDefaultBalance {
        uint256 FTM;
        uint256 MATIC;
    }
    /// @notice keeps track of the default pool
    TotalCrossChainDefaultBalance public totalCrossChainDefaultBalance;

    /// @notice saving processs created for axelar to have different execution paths based on function calls
    uint256 public constant savingprocess = 1;
    uint256 public constant breakSaveEarlyprocess = 2;
    uint256 public constant unlockSavingsprocess = 3;
    uint256 public constant setChainConfirmationProcess = 4;

    /// @notice the penalty percentage imposed on savers who withdraw their funds before their set expected date
    uint256 public penaltyPercent = 25;

    // CHAIN DETAILS

    // FANTOM
    /// @notice fantom chain id
    uint256 public fantomChainId = 4002;
    /// @notice fantom chain name for cross chain messaging
    string public fantomChain = "Fantom";
    /// @notice this contract's deployment address on Fantom
    string public fantomDestinationContractAddress;

    // POLYGON
    /// @notice Polygon chain id
    uint256 public polygonChainId = 80001;
    /// @notice Polygon chain name for cross chain messaging
    string public polygonChain = "Polygon";
    /// @notice this contract's deployment address on Polygon
    string public polygonDestinationContractAddress;

    /**
     * @notice information on each user savings
     * @param balance the user's balance in the native asset of the blockchain
     * @param startTime the time the user begins to save
     * @param stoptime the time period during which the user is free to withdraw savings without penalty
     * @param interval the amount of time in seconds that the user wishes to save
     * @param exist the existence of the savings
     * @param locked specifies whether the savings are fixed or flexible
     * @param chainConfirmation a call back from the second chain approving the withdrawal of savings
     */
    struct Savings {
        uint256 balance;
        uint256 startTime;
        uint256 stopTime;
        uint256 interval;
        bool exist;
        bool locked;
        bool chainConfirmation;
    }

    /// @notice keeps a record of every user's savings
    mapping(address => Savings) public savings;

    // EVENTS

    // emits when a new saver saves
    event SavingsCreated(
        address indexed saver,
        uint256 indexed amount,
        uint256 indexed interval,
        uint256 startTime,
        uint256 stopTime,
        bool savingOption
    );

    // emit when a user updates saving
    event SavingsUpdated(
        address indexed saver,
        uint256 indexed updatedBalance,
        uint256 indexed updatedInterval,
        uint256 updatedStopTime
    );

    // emit when a save is broken
    event SavingsBroken(address indexedsaver, uint256 indexed defaultPenalty);

    // emit when a user unlocks saving
    event SavingsUnlocked(address indexed saver, uint256 indexed savingPeriod);

    // eit when a user withdraws savings
    event SavingsWithdrawn(
        address indexed saver,
        uint256 indexed balancePlusInterest
    );

    /**
     * @notice constructor
     * @param _gateway axelar's official gateway contract address for the deployment chain
     * @param _gasService axelar's official gas service contract address for the deployment chain
     * @param _ftmPriceFeedAddress Fantom/USD price feed contract address form chainlink
     * @param _maticPriceFeedAddress Matic/USD price feed contract address form chainlink
     * @param _minSavingTime the minimum amount of seconds that a user could save
     * @param _minSavingAmount the minimum amount of native asset that a user could save
     */
    constructor(
        address _gateway,
        address _gasService,
        address _ftmPriceFeedAddress,
        address _maticPriceFeedAddress,
        uint256 _minSavingTime,
        uint256 _minSavingAmount
    ) IAxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasService);

        minimumSavingTime = _minSavingTime;
        minimumSavingAmount = _minSavingAmount;

        ftmPriceFeed = AggregatorV3Interface(_ftmPriceFeedAddress);
        maticPriceFeed = AggregatorV3Interface(_maticPriceFeedAddress);

        deployer = msg.sender;
    }

    /// @notice save an amout of native asset for a set period of time to be elligible for flexible possible interests by defaulters
    /// @dev Keeps track of all users who are saving data and relays the message across the chain if neccessary
    /// @param _savingTime The amount of seconds a user wishes to save for
    /// @param _option True for locked savings and False for flexible savings
    /// @param _estimateGasCostForFtm The estimated gas cost from the client when sending a message from Polygon using axelars SDK.
    /// @param _estimateGasCostForPolygon The estimated gas cost from the client when  sending a message from Fantom using axelars SDK.
    function save(
        uint256 _savingTime,
        bool _option,
        uint256 _estimateGasCostForFtm,
        uint256 _estimateGasCostForPolygon
    ) public payable nonReentrant {
        // If the user doesn't have an existing saving
        if (!savings[msg.sender].exist) {
            if (_savingTime < minimumSavingTime) {
                revert("CS#2");
            }

            if (msg.value == 0) {
                revert("CS#3");
            }
            // If the option is true - Locked
            if (_option) {
                uint256 stopTime = block.timestamp + _savingTime;

                // create a savinngs data with users information and store
                Savings memory savingsData = Savings({
                    balance: msg.value,
                    interval: _savingTime,
                    startTime: block.timestamp,
                    stopTime: stopTime,
                    locked: _option,
                    chainConfirmation: true,
                    exist: true
                });
                savings[msg.sender] = savingsData;

                // emit event
                emit SavingsCreated(
                    msg.sender,
                    msg.value,
                    _savingTime,
                    block.timestamp,
                    block.timestamp + _savingTime,
                    _option
                );
            }

            // If the option is false - Flexible
            if (!_option) {
                Savings memory savingsData = Savings({
                    balance: msg.value,
                    interval: _savingTime,
                    startTime: block.timestamp,
                    stopTime: block.timestamp + _savingTime,
                    locked: _option,
                    chainConfirmation: false,
                    exist: true
                });
                savings[msg.sender] = savingsData;

                if (msg.value == 0) {
                    revert("CS#3");
                }
                // increase total cross chain saving time
                totalCrossChainSavingTime += _savingTime;

                bytes memory innerPayload = abi.encode(_savingTime);
                bytes memory payload = abi.encode(savingprocess, innerPayload);

                if (block.chainid == fantomChainId)
                    _handleFantomMessaging(payload, _estimateGasCostForPolygon);

                if (block.chainid == polygonChainId)
                    _handlePolygonMessaging(payload, _estimateGasCostForFtm);

                totalCurrentSavers++;

                // emit event
                emit SavingsCreated(
                    msg.sender,
                    msg.value,
                    _savingTime,
                    block.timestamp,
                    block.timestamp + _savingTime,
                    _option
                );
            }

            // ELSE - If the user already has an existing saving going on
        } else {
            // Topping up balance only
            if (_savingTime == 0) {
                savings[msg.sender].balance += msg.value;

                emit SavingsUpdated(
                    msg.sender,
                    savings[msg.sender].balance,
                    savings[msg.sender].interval,
                    savings[msg.sender].stopTime
                );
            }

            // Topping up balance and time
            if (_savingTime > 0 && msg.value > 0) {
                // Flexible savings
                if (!savings[msg.sender].locked) {
                    totalCrossChainSavingTime += _savingTime;

                    savings[msg.sender].stopTime += _savingTime;
                    savings[msg.sender].stopTime += _savingTime;
                    savings[msg.sender].interval += _savingTime;

                    bytes memory innerPayload = abi.encode(_savingTime);
                    bytes memory payload = abi.encode(
                        savingprocess,
                        innerPayload
                    );

                    if (block.chainid == fantomChainId) {
                        _handleFantomMessaging(
                            payload,
                            _estimateGasCostForPolygon
                        );
                    }

                    if (block.chainid == polygonChainId) {
                        _handlePolygonMessaging(
                            payload,
                            _estimateGasCostForFtm
                        );
                    }

                    savings[msg.sender].balance += msg.value;

                    emit SavingsUpdated(
                        msg.sender,
                        savings[msg.sender].balance,
                        savings[msg.sender].interval,
                        savings[msg.sender].stopTime
                    );
                }
                //ELSE - LOcked savings
                else {
                    savings[msg.sender].stopTime += _savingTime;
                    savings[msg.sender].stopTime += _savingTime;
                    savings[msg.sender].interval += _savingTime;

                    savings[msg.sender].balance += msg.value;

                    emit SavingsUpdated(
                        msg.sender,
                        savings[msg.sender].balance,
                        savings[msg.sender].interval,
                        savings[msg.sender].stopTime
                    );
                }
            }
        }
    }

    /// @notice Allow saver to withdraw their savings before expected withdrawal date
    /// @param _estimateGasCostForFtm The estimated gas cost from the client when sending a message from Polygon using axelars SDK.
    /// @param _estimateGasCostForPolygon The estimated gas cost from the client when  sending a message from Fantom using axelars SDK.
    function breakSaveEarly(
        uint256 _estimateGasCostForPolygon,
        uint256 _estimateGasCostForFtm
    ) external payable nonReentrant {
        // Savings has to exist
        if (savings[msg.sender].exist) {
            // The stop time hasn't been reached yet
            if (block.timestamp < savings[msg.sender].stopTime) {
                if (!savings[msg.sender].locked) {
                    uint256 userAmount = savings[msg.sender].balance;
                    uint256 userTime = savings[msg.sender].interval;
                    // return 90%
                    uint256 returnAmount = ((100 - penaltyPercent) *
                        userAmount) / 100;
                    // add 10% to pool
                    uint256 defaultBalanceIncrease = (penaltyPercent *
                        userAmount) / 100;

                    if (block.chainid == fantomChainId) {
                        totalCrossChainDefaultBalance
                            .FTM += defaultBalanceIncrease;

                        bytes memory innerPayload = abi.encode(
                            defaultBalanceIncrease,
                            userTime
                        );
                        bytes memory payload = abi.encode(
                            breakSaveEarlyprocess,
                            innerPayload
                        );
                        _handleFantomMessaging(
                            payload,
                            _estimateGasCostForPolygon
                        );
                    }

                    if (block.chainid == polygonChainId) {
                        totalCrossChainDefaultBalance
                            .MATIC += defaultBalanceIncrease;

                        bytes memory innerPayload = abi.encode(
                            defaultBalanceIncrease,
                            userTime
                        );

                        bytes memory payload = abi.encode(
                            breakSaveEarlyprocess,
                            innerPayload
                        );
                        _handlePolygonMessaging(
                            payload,
                            _estimateGasCostForFtm
                        );
                    }

                    totalCrossChainSavingTime -= userTime;

                    savings[msg.sender] = Savings({
                        balance: 0,
                        startTime: 0,
                        interval: 0,
                        stopTime: 0,
                        exist: false,
                        locked: false,
                        chainConfirmation: false
                    });

                    (bool ok, ) = msg.sender.call{value: returnAmount}("");
                    require(ok, "!ok");

                    emit SavingsBroken(msg.sender, defaultBalanceIncrease);
                } else {
                    revert("CS#6");
                }
            } else {
                revert("CS#5");
            }

            totalCurrentSavers--;
        } else {
            revert("CS#4");
        }
    }

    /// @notice enables flexible savers to access their full savings after the predetermined stop period has passed.
    /// @param _estimateGasCostForFtm The estimated gas cost from the client when sending a message from Polygon using axelars SDK.
    /// @param _estimateGasCostForPolygon The estimated gas cost from the client when  sending a message from Fantom using axelars SDK.
    function unlockSavingsAccrossChains(
        uint256 _estimateGasCostForFtm,
        uint256 _estimateGasCostForPolygon // uint256 _estimateGasCostBnb
    ) external payable nonReentrant {
        // checks for
        // 1 - saving stop time exceeded?
        // 2 - savings locked?
        // 3 - savings exist?
        if (
            block.timestamp > savings[msg.sender].stopTime &&
            !savings[msg.sender].locked &&
            savings[msg.sender].exist
        ) {
            if (block.chainid == fantomChainId) {
                bytes memory innerPayload = abi.encode(
                    getNativeAssetPriceFtm(),
                    msg.sender,
                    savings[msg.sender].interval
                );

                bytes memory payload = abi.encode(
                    unlockSavingsprocess,
                    innerPayload
                );

                _handleFantomMessaging(payload, _estimateGasCostForPolygon);
            }

            if (block.chainid == polygonChainId) {
                bytes memory innerPayload = abi.encode(
                    getNativeAssetPriceMatic(),
                    msg.sender,
                    savings[msg.sender].interval
                );

                bytes memory payload = abi.encode(
                    unlockSavingsprocess,
                    innerPayload
                );

                _handlePolygonMessaging(payload, _estimateGasCostForFtm);
            }

            savings[msg.sender].interval = 0;
            savings[msg.sender].startTime = 0;
            savings[msg.sender].stopTime = 0;

            emit SavingsUnlocked(msg.sender, savings[msg.sender].interval);
        }
    }

    /// @notice allows users to withdraw their savings
    /// @dev if locked - withdraw straight, if flexible - unlock before withdrawal
    function withdrawSavings() external nonReentrant {
        Savings memory savingsData = Savings({
            balance: 0,
            startTime: 0,
            interval: 0,
            stopTime: 0,
            exist: false,
            locked: false,
            chainConfirmation: false
        });

        if (savings[msg.sender].locked) {
            uint256 userAmount = savings[msg.sender].balance;
            savings[msg.sender] = savingsData;

            (bool ok, ) = msg.sender.call{value: userAmount}("");
            require(ok, "!ok");
            emit SavingsWithdrawn(msg.sender, userAmount);
        } else {
            if (savings[msg.sender].chainConfirmation) {
                uint256 userBalancePlusInterest = savings[msg.sender].balance;

                savings[msg.sender] = savingsData;

                (bool sucess, ) = msg.sender.call{
                    value: userBalancePlusInterest
                }("");
                require(sucess, "!sucess");
                emit SavingsWithdrawn(msg.sender, userBalancePlusInterest);
            }
        }
        totalCurrentSavers--;
    }

    // INTERNAL AND PRIVATE FUNCTIONS - PLEASE CHNAGE THE FUNCTIONS TO INTERNAL

    /// @notice gets the real time price of ftm in usd
    /// @return the price of ftm in usd with 8 decimals
    function getNativeAssetPriceFtm() private view returns (uint256) {
        (, int price, , , ) = ftmPriceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice gets the real time price of matic in usd
    /// @return the price of matic in usd with 8 decimals
    function getNativeAssetPriceMatic() private view returns (uint256) {
        (, int price, , , ) = maticPriceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice routes all the messages to fantom chain along with the different payload for different executions
    /// @param _payload the bytes encoded parameters sent to the destination contract on the fantom chain
    /// @param _estimateGasCostFtm The amount of matic required to send the message to fantom chain
    function _handlePolygonMessaging(
        bytes memory _payload,
        uint256 _estimateGasCostFtm
    ) private {
        gasService.payNativeGasForContractCall{value: _estimateGasCostFtm}(
            address(this),
            fantomChain,
            fantomDestinationContractAddress,
            _payload,
            address(this)
        );

        gateway.callContract(
            fantomChain,
            fantomDestinationContractAddress,
            _payload
        );
    }

    /// @notice routes all the messages to polygon chain along with the different payload for different executions
    /// @param _payload the bytes encoded parameters sent to the destination contract on the polygon chain chain
    /// @param _estimateGasCostPolygon The amount of matic required to send the message to polygon chain chain
    function _handleFantomMessaging(
        bytes memory _payload,
        uint256 _estimateGasCostPolygon
    ) private {
        gasService.payNativeGasForContractCall{value: _estimateGasCostPolygon}(
            address(this),
            polygonChain,
            polygonDestinationContractAddress,
            _payload,
            address(this)
        );

        gateway.callContract(
            polygonChain,
            polygonDestinationContractAddress,
            _payload
        );
    }

    /// @notice the various cross-chain messages are executed based on the chain and encoded payload.
    /// @dev Each payload contains a process that determines the action that was done on the source chain and the action that has to be taken on the destination chain.
    /// @param payload the encoded parameters that decide what action should be taken
    function _execute(
        string memory,
        string memory,
        bytes calldata payload
    ) internal override {
        // processS

        // 4 = UNLOCK THE SAVINGS FOR WITHDRAWAL FROM THE TWO CHAINS ON THE SOURCE CHAIN

        (uint256 process, bytes memory innerPayload) = abi.decode(
            payload,
            (uint256, bytes)
        );
        // 1 = saving process = the save() function was invoked on source chain
        if (process == savingprocess) {
            uint256 userSavingTime = abi.decode(innerPayload, (uint256));
            totalCrossChainSavingTime += userSavingTime;
        }
        // 2 = break save early process = breakSaveEarly() function was invoked on source chain
        if (process == 2) {
            (uint256 defaultBalanceIncrease, uint256 userTime) = abi.decode(
                innerPayload,
                (uint256, uint256)
            );
            if (block.chainid == polygonChainId) {
                totalCrossChainDefaultBalance.FTM += defaultBalanceIncrease;
            }
            if (block.chainid == fantomChainId) {
                totalCrossChainDefaultBalance.MATIC += defaultBalanceIncrease;
            }

            totalCrossChainSavingTime -= userTime;
        }
        // 3 = unlock chain savings process = when unlockSavingsAccrossChains() is invoked
        if (process == unlockSavingsprocess) {
            // price in usd for the source chain and sender
            (uint256 priceInUsd, address sender, uint256 userInterval) = abi
                .decode(innerPayload, (uint256, address, uint256));

            // meaning polygon sent the message
            if (block.chainid == fantomChainId) {
                uint256 ftmBalanceInUsd;
                uint256 maticBalanceInUsd;

                if (totalCrossChainDefaultBalance.FTM > 0) {
                    ftmBalanceInUsd =
                        (getNativeAssetPriceFtm() *
                            totalCrossChainDefaultBalance.FTM) /
                        1e18;
                }

                if (totalCrossChainDefaultBalance.MATIC > 0) {
                    maticBalanceInUsd =
                        (priceInUsd * totalCrossChainDefaultBalance.MATIC) /
                        1e18;
                }

                uint256 totalBalinUsd = maticBalanceInUsd + ftmBalanceInUsd;

                uint256 interestInNativeAsset;
                if (totalBalinUsd > 0) {
                    // the total balance of the asset for the source chain e.g 5 ftm and 2 matic in MATIC
                    uint256 totalBalInNativeAssset = (totalBalinUsd * 1e18) /
                        priceInUsd;

                    // calculate the interest of the user
                    interestInNativeAsset =
                        (userInterval * totalBalInNativeAssset) /
                        totalCrossChainSavingTime;

                    totalCrossChainDefaultBalance
                        .MATIC -= interestInNativeAsset;
                }

                bytes memory processFourPayload = abi.encode(
                    sender,
                    interestInNativeAsset //We will deduct the total cross chain bal and increase the senders balance
                );

                bytes memory payloadFour = abi.encode(
                    setChainConfirmationProcess, // method 4
                    processFourPayload
                );

                gateway.callContract(
                    polygonChain,
                    polygonDestinationContractAddress,
                    payloadFour
                );
            }
            if (block.chainid == polygonChainId) {
                // calculate the total price of the default balance in Usd

                uint256 ftmBalanceInUsd;
                uint256 maticBalanceInUsd;

                if (totalCrossChainDefaultBalance.FTM > 0) {
                    ftmBalanceInUsd =
                        (priceInUsd * totalCrossChainDefaultBalance.FTM) /
                        1e18;
                }

                if (totalCrossChainDefaultBalance.MATIC > 0) {
                    maticBalanceInUsd =
                        (getNativeAssetPriceMatic() *
                            totalCrossChainDefaultBalance.MATIC) /
                        1e18;
                }

                uint256 totalBalinUsd = maticBalanceInUsd + ftmBalanceInUsd;

                // the total balance of the asset for the source chain e.g 5 ftm and 2 matic in MATIC
                uint256 interestInNativeAsset;
                if (totalBalinUsd > 0) {
                    uint256 totalBalInNativeAssset = (totalBalinUsd * 1e18) /
                        priceInUsd;

                    // calculate the interest of the user
                    interestInNativeAsset =
                        (userInterval * totalBalInNativeAssset) /
                        totalCrossChainSavingTime;

                    totalCrossChainDefaultBalance.FTM -= interestInNativeAsset;
                }

                bytes memory processFourPayload = abi.encode(
                    sender,
                    interestInNativeAsset //We will deduct the total cross chain bal and increase the senders balance
                );

                bytes memory payloadFour = abi.encode(
                    setChainConfirmationProcess, // method 4
                    processFourPayload
                );

                gateway.callContract(
                    fantomChain,
                    fantomDestinationContractAddress,
                    payloadFour
                );
            }
        }
        // 4 = set chain confirmation = when process three is executed in the _execute() function
        if (process == setChainConfirmationProcess) {
            (address user, uint256 interestInNativeAsset) = abi.decode(
                innerPayload,
                (address, uint256)
            );

            savings[user].chainConfirmation = true;
            savings[user].balance += interestInNativeAsset;

            if (block.chainid == fantomChainId)
                totalCrossChainDefaultBalance.FTM -= interestInNativeAsset;

            if (block.chainid == polygonChainId)
                totalCrossChainDefaultBalance.MATIC -= interestInNativeAsset;
        }
    }

    /// @notice sets the contract address for the two contracts on both chains1
    function updateDestinationAddresses(
        // string memory _bnbaddr,
        string memory _polygonaddr,
        string memory _ftmaddr
    ) public {
        require(!initialized, "intialized");
        require(msg.sender == deployer, "!deployer");

        polygonDestinationContractAddress = _polygonaddr;
        fantomDestinationContractAddress = _ftmaddr;
    }

    function updatePenalyPercent(uint256 _newPenaltyPercent) public {
        require(msg.sender == deployer, "!deployer");
        penaltyPercent = _newPenaltyPercent;
    }

    receive() external payable {}

    // GETTER FUNCTIONS
    function getUserSavingsDetails(address user)
        external
        view
        returns (Savings memory)
    {
        return savings[user];
    }

    /// @return the total time saved by all users
    function getTotalCrossChainSavingTime() external view returns (uint256) {
        return totalCrossChainSavingTime;
    }

    /// @return the total current savers
    function getTotalCurrentSavers() external view returns (uint256) {
        return totalCurrentSavers;
    }

    /// @return the total default balance/pool for complete savers to earn from
    function getTotalCrossChainDefaultBalance()
        public
        view
        returns (TotalCrossChainDefaultBalance memory)
    {
        return totalCrossChainDefaultBalance;
    }

    /// @return totalBalinUsd the current default pool balance in USD
    function getTotalCrossChainDefaultBalanceInUsd()
        external
        view
        returns (uint256 totalBalinUsd)
    {
        uint256 ftmBalanceInUsd = (getNativeAssetPriceMatic() *
            totalCrossChainDefaultBalance.FTM) / 1e18;

        uint256 maticBalanceInUsd = (getNativeAssetPriceFtm() *
            totalCrossChainDefaultBalance.MATIC) / 1e18;

        totalBalinUsd = maticBalanceInUsd + ftmBalanceInUsd;
    }

    /// @return gets the total current penalty percent
    function getCurrentPenaltyPercent() external view returns (uint256) {
        return penaltyPercent;
    }

    // TESTING PURPOSES
    function returnTimeStamp() external view returns (uint256) {
        return block.timestamp;
    }

    function withdraw() external {
        (bool ok, ) = msg.sender.call{value: address(this).balance}("");
        require(ok, "!ok");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAxelarGateway } from "IAxelarGateway.sol";

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "IUpgradable.sol";

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService is IUpgradable {
    error NothingReceived();
    error TransferFailed();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
}