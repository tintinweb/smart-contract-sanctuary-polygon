// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IuaedFinanceProtocol {
    function owner() external returns (address);

    function changeCollateralFactor(
        uint8 _assetId,
        uint8 _collateralFactor
    ) external;

    function addAssetAsCollateral(
        address _tokenAddress,
        uint8 _tokenDecimals,
        uint8 _collateralFactor
    ) external;

    function changeInterestRate(uint _interestRatePerHour) external;

    function changeLiquidationParams(
        uint _liquidatorBonusPercentage,
        uint _liquidatorMinBounus
    ) external;
}

interface IuaedFinancePrices {
    function changePriceFeed(address _priceFeed, uint8 _assetId) external;

    function addPriceFeed(address _priceFeed) external;
}

contract UAEDProtocolRequestor {
    IuaedFinanceProtocol public immutable uaedProtocol;
    uint public constant changeCollateralFactorD = 30 days;
    uint public constant changePriceFeedD = 30 days;
    uint public constant addAssetAsCollateralD = 15 days;
    uint public constant changeInterestRateD = 30 days;
    uint public constant changeLiquidationParamsD = 15 days;
    uint public constant expirationTime = 5 days;
    IuaedFinancePrices public uaedFinancePrices;

    mapping(bytes32 => uint) public requests; // timestamp of each request

    constructor() {
        uaedProtocol = IuaedFinanceProtocol(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == uaedProtocol.owner(), "onlyOwner");
        _;
    }

    function setUAEDfinancePrices(address _uaedFinancePrices) public {
        require(address(uaedFinancePrices) == address(0));
        uaedFinancePrices = IuaedFinancePrices(_uaedFinancePrices);
    }

    //////////////// change financial parameters and manage requests ////////////////////////////

    function _submitRequest(bytes32 _request) private {
        require(requests[_request] == 0, "request already submitted"); // collision resistance
        requests[_request] = block.timestamp;
    }

    function _checkRequestTime(
        bytes32 _request,
        uint _delayedTime
    ) private view {
        require(
            requests[_request] + _delayedTime <= block.timestamp,
            "wait more"
        );
        require(
            block.timestamp <=
                requests[_request] + _delayedTime + expirationTime,
            "Request has expired"
        );
    }

    event requestCanceled(bytes32 request);

    function cancelRequest(bytes32 _request) external onlyOwner {
        delete requests[_request];
        emit requestCanceled(_request);
    }

    //--------1----------
    event requestCollateralFactorChange(
        uint8 indexed assetId,
        uint8 newCollateralFactor,
        uint timeStamp,
        bytes32 indexed request
    );
    event collateralFactorChanged(
        uint8 assetId,
        uint8 newCollateralFactor,
        bytes32 indexed request
    );

    function requestChangeCollateralFactor(
        uint8 _assetId,
        uint8 _collateralFactor
    ) external onlyOwner {
        require(_collateralFactor < 100, "invalid collateralFactor");
        require(_assetId != 0, "wrong assetId");
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changeCollateralFactor,
                (_assetId, _collateralFactor, block.timestamp)
            )
        );
        _submitRequest(request);
        emit requestCollateralFactorChange(
            _assetId,
            _collateralFactor,
            block.timestamp,
            request
        );
    }

    function changeCollateralFactor(
        uint8 _assetId,
        uint8 _collateralFactor,
        uint _timeStamp
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changeCollateralFactor,
                (_assetId, _collateralFactor, _timeStamp)
            )
        );
        _checkRequestTime(request, changeCollateralFactorD);
        uaedProtocol.changeCollateralFactor(_assetId, _collateralFactor);
        emit collateralFactorChanged(_assetId, _collateralFactor, request);
    }

    //--------2----------
    event requestPriceFeedChange(
        address priceFeed,
        uint8 indexed assetId,
        uint timeStamp,
        bytes32 indexed request
    );
    event priceFeedChanged(
        address priceFeed,
        uint8 assetId,
        bytes32 indexed request
    );

    function requestChangePriceFeed(
        address _priceFeed,
        uint8 _assetId
    ) external onlyOwner {
        require(_priceFeed != address(0), "invalid address");
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changePriceFeed,
                (_priceFeed, _assetId, block.timestamp)
            )
        );
        _submitRequest(request);
        emit requestPriceFeedChange(
            _priceFeed,
            _assetId,
            block.timestamp,
            request
        );
    }

    function changePriceFeed(
        address _priceFeed,
        uint8 _assetId,
        uint _timeStamp
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changePriceFeed,
                (_priceFeed, _assetId, _timeStamp)
            )
        );
        _checkRequestTime(request, changePriceFeedD);
        uaedFinancePrices.changePriceFeed(_priceFeed, _assetId);
        emit priceFeedChanged(_priceFeed, _assetId, request);
    }

    //--------3----------
    event requestAssetAddAsCollateral(
        address indexed tokenAddress,
        address priceFeed,
        uint8 collateralFactor,
        uint timeStamp,
        bytes32 indexed request
    );
    event assetAddedAsCollateral(
        address indexed tokenAddress,
        address priceFeed,
        uint8 collateralFactor,
        bytes32 indexed request
    );

    function requestAddAssetAsCollateral(
        address _tokenAddress,
        address _priceFeed,
        uint8 _tokenDecimals,
        uint8 _collateralFactor
    ) external onlyOwner {
        require(
            _tokenAddress != address(0) && _priceFeed != address(0),
            "invalid address"
        );
        require(_collateralFactor < 100, "invalid collateralFactor");
        bytes32 request = keccak256(
            abi.encodeCall(
                this.addAssetAsCollateral,
                (
                    _tokenAddress,
                    _priceFeed,
                    _tokenDecimals,
                    _collateralFactor,
                    block.timestamp
                )
            )
        );
        _submitRequest(request);
        emit requestAssetAddAsCollateral(
            _tokenAddress,
            _priceFeed,
            _collateralFactor,
            block.timestamp,
            request
        );
    }

    function addAssetAsCollateral(
        address _tokenAddress,
        address _priceFeed,
        uint8 _tokenDecimals,
        uint8 _collateralFactor,
        uint _timeStamp
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(
                this.addAssetAsCollateral,
                (
                    _tokenAddress,
                    _priceFeed,
                    _tokenDecimals,
                    _collateralFactor,
                    _timeStamp
                )
            )
        );
        _checkRequestTime(request, addAssetAsCollateralD);
        uaedProtocol.addAssetAsCollateral(
            _tokenAddress,
            _tokenDecimals,
            _collateralFactor
        );
        uaedFinancePrices.addPriceFeed(_priceFeed);
        emit assetAddedAsCollateral(
            _tokenAddress,
            _priceFeed,
            _collateralFactor,
            request
        );
    }

    // --------4----------
    event requestInterestRateChange(
        uint interestRate,
        uint timeStamp,
        bytes32 indexed request
    );
    event interestRateChanged(uint interestRate, bytes32 indexed request);

    function requestChangeInterestRate(uint _interestRate) external onlyOwner {
        uint y = 365 days + 6 hours;
        uint d = block.timestamp % y;
        require(
            d > y - changeInterestRateD &&
                d < y + expirationTime - changeInterestRateD,
            "incorrect request time"
        );
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changeInterestRate,
                (_interestRate, block.timestamp)
            )
        );
        _submitRequest(request);
        emit requestInterestRateChange(_interestRate, block.timestamp, request);
    }

    function changeInterestRate(
        uint _interestRate,
        uint _timeStamp
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(this.changeInterestRate, (_interestRate, _timeStamp))
        );
        _checkRequestTime(request, changeInterestRateD);
        uaedProtocol.changeInterestRate(_interestRate);
        emit interestRateChanged(_interestRate, request);
    }

    // --------5----------
    event requestLiquidationParamsChange(
        uint indexed liquidatorBonusPercentage,
        uint liquidatorMinBounus,
        uint timeStamp,
        bytes32 indexed request
    );
    event liquidationParamsChanged(
        uint liquidatorBonusPercentage,
        uint liquidatorMinBounus,
        bytes32 indexed request
    );

    function requestChangeLiquidationParams(
        uint _liquidatorBonusPercentage,
        uint _liquidatorMinBounus
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changeLiquidationParams,
                (
                    _liquidatorBonusPercentage,
                    _liquidatorMinBounus,
                    block.timestamp
                )
            )
        );
        _submitRequest(request);
        emit requestLiquidationParamsChange(
            _liquidatorBonusPercentage,
            _liquidatorMinBounus,
            block.timestamp,
            request
        );
    }

    function changeLiquidationParams(
        uint _liquidatorBonusPercentage,
        uint _liquidatorMinBounus,
        uint _timeStamp
    ) external onlyOwner {
        bytes32 request = keccak256(
            abi.encodeCall(
                this.changeLiquidationParams,
                (_liquidatorBonusPercentage, _liquidatorMinBounus, _timeStamp)
            )
        );
        _checkRequestTime(request, changeLiquidationParamsD);
        uaedProtocol.changeLiquidationParams(
            _liquidatorBonusPercentage,
            _liquidatorMinBounus
        );
        emit liquidationParamsChanged(
            _liquidatorBonusPercentage,
            _liquidatorMinBounus,
            request
        );
    }
}