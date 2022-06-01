// SPDX-License-Identifier: ---DG---

pragma solidity ^0.8.13;

import "./AccessController.sol";
import "./TransferHelper.sol";
import "./CleanEvents.sol";

interface RegistrantContract {

    function getHash(
        address _tokenAddress,
        uint256 _tokenId
    )
        external
        pure
        returns (bytes32);
}

contract IceCleaner is AccessController, TransferHelper, CleanEvents {

    address public immutable tokenAddressDG;
    address public immutable tokenAddressICE;

    RegistrantContract public immutable registrantContract;

    uint256 public costPerPointDG;
    uint256 public costPerPointICE;

    address public depositAddressDG;
    address public depositAddressICE;

    mapping(address => uint256) public totalSpent;
    mapping(address => mapping(bytes32 => uint256)) public pointLevel;
    mapping(address => mapping(bytes32 => uint256)) public spentPerNFT;

    mapping(uint256 => uint256) public pointsBulksDG;
    mapping(uint256 => uint256) public pointsBulksICE;

    constructor(
        address _tokenAddressDG,
        address _tokenAddressICE,
        address _registrantContract
    ) {
        tokenAddressDG = _tokenAddressDG;
        tokenAddressICE = _tokenAddressICE;

        registrantContract = RegistrantContract(
            _registrantContract
        );
    }

    function buyAndSpendBulk(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _bulkPriceDG,
        uint256 _bulkPriceICE
    )
        external
        onlyWorker
    {
        uint256 totalPointsForDG = pointsBulksDG[_bulkPriceDG];
        uint256 totalPointsForICE = pointsBulksICE[_bulkPriceICE];

        uint256 totalPoints = totalPointsForDG + totalPointsForICE;

        require(
            totalPoints > 0,
            "IceCleaner: NO_POINTS"
        );

        _buyAndSpend(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            totalPoints,
            _bulkPriceDG,
            _bulkPriceICE
        );
    }

    function buyAndSpend(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        _buyAndSpend(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount,
            totalPriceDG,
            totalPriceICE
        );
    }

    function _buyAndSpend(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount,
        uint256 _totalPriceDG,
        uint256 _totalPriceICE
    )
        internal
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        totalSpent[_playerAddress] =
        totalSpent[_playerAddress] + _pointsAmount;

        spentPerNFT[_playerAddress][tokenHash] =
        spentPerNFT[_playerAddress][tokenHash] + _pointsAmount;

        _takePayment(
            _totalPriceDG,
            _totalPriceICE,
            _playerAddress
        );

        emit Cleaning(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function buyPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        _buyPoints(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount,
            totalPriceDG,
            totalPriceICE
        );
    }

    function buyPointsBulk(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _bulkPriceDG,
        uint256 _bulkPriceICE
    )
        external
        onlyWorker
    {
        uint256 totalPointsForDG = pointsBulksDG[_bulkPriceDG];
        uint256 totalPointsForICE = pointsBulksICE[_bulkPriceICE];

        uint256 totalPoints = totalPointsForDG + totalPointsForICE;

        require(
            totalPoints > 0,
            "IceCleaner: NO_POINTS"
        );

        _buyPoints(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            totalPoints,
            _bulkPriceDG,
            _bulkPriceICE
        );
    }

    function _buyPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount,
        uint256 _totalPriceDG,
        uint256 _totalPriceICE
    )
        internal
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        pointLevel[_playerAddress][tokenHash] =
        pointLevel[_playerAddress][tokenHash] + _pointsAmount;

        _takePayment(
            _totalPriceDG,
            _totalPriceICE,
            _playerAddress
        );

        emit Purchased(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function spendPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        totalSpent[_playerAddress] =
        totalSpent[_playerAddress] + _pointsAmount;

        spentPerNFT[_playerAddress][tokenHash] =
        spentPerNFT[_playerAddress][tokenHash] + _pointsAmount;

        pointLevel[_playerAddress][tokenHash] =
        pointLevel[_playerAddress][tokenHash] - _pointsAmount;

        emit Cleaning(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function _takePayment(
        uint256 _dgAmount,
        uint256 _iceAmount,
        address _playerAddress
    )
        internal
    {
        if (_dgAmount > 0) {
            safeTransferFrom(
                tokenAddressDG,
                _playerAddress,
                depositAddressDG,
                _dgAmount
            );
        }

        if (_iceAmount > 0) {
            safeTransferFrom(
                tokenAddressICE,
                _playerAddress,
                depositAddressICE,
                _iceAmount
            );
        }
    }

    function setCostPerPointDG(
        uint256 _costPerPointDG
    )
        external
        onlyCEO
    {
        costPerPointDG = _costPerPointDG;
    }

    function setCostPerPointICE(
        uint256 _costPerPointICE
    )
        external
        onlyCEO
    {
        costPerPointICE = _costPerPointICE;
    }

    function setDepositAddressDG(
        address _depositAddressDG
    )
        external
        onlyCEO
    {
        depositAddressDG = _depositAddressDG;
    }

    function setDepositAddressICE(
        address _depositAddressICE
    )
        external
        onlyCEO
    {
        depositAddressICE = _depositAddressICE;
    }

    function setPointsBulkDG(
        uint256 _bulkPrice,
        uint256 _bulkPoints
    )
        external
        onlyCEO
    {
        pointsBulksDG[_bulkPrice] = _bulkPoints;
    }

    function setPointsBulkICE(
        uint256 _bulkPrice,
        uint256 _bulkPoints
    )
        external
        onlyCEO
    {
        pointsBulksICE[_bulkPrice] = _bulkPoints;
    }
}