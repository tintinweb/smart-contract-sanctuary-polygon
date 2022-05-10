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

    mapping(bytes32 => uint256) public totalSpent;
    mapping(bytes32 => uint256) public pointLevel;

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

    function buyAndSpend(
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

        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        totalSpent[tokenHash] =
        totalSpent[tokenHash] + _pointsAmount;

        _takePayment(
            totalPriceDG,
            totalPriceICE,
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
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        pointLevel[tokenHash] =
        pointLevel[tokenHash] - _pointsAmount;

        _takePayment(
            totalPriceDG,
            totalPriceICE,
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

        totalSpent[tokenHash] =
        totalSpent[tokenHash] + _pointsAmount;

        pointLevel[tokenHash] =
        pointLevel[tokenHash] - _pointsAmount;

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

    function setcCstPerPointDG(
        uint256 _costPerPointDG
    )
        external
        onlyCEO
    {
        costPerPointDG = _costPerPointDG;
    }

    function setcCstPerPointICE(
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
}